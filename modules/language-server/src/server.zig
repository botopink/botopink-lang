/// LSP server — handshake, message loop, and request dispatch.
///
/// Protocol: JSON-RPC 2.0 over stdin/stdout.
/// Phase 1: initialize, shutdown, textDocument/didOpen, didChange, didClose,
///          textDocument/formatting, textDocument/publishDiagnostics.
/// Phase 2: textDocument/hover, textDocument/definition, textDocument/documentSymbol.
const std = @import("std");
const bp = @import("botopink");
const proto = @import("./protocol.zig");
const messages = @import("./messages.zig");
const engine = @import("./engine.zig");
const files_mod = @import("./files.zig");
const feedback_mod = @import("./feedback.zig");
const lsp_types = @import("./lsp_types.zig");

const Lexer = bp.Lexer;

pub const Server = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    files: files_mod.FileCache,
    feedback: feedback_mod.FeedbackBookkeeper,
    initialized: bool,
    shutdown_requested: bool,

    pub fn init(gpa: std.mem.Allocator, io: std.Io) Server {
        return .{
            .gpa = gpa,
            .io = io,
            .files = files_mod.FileCache.init(gpa),
            .feedback = feedback_mod.FeedbackBookkeeper.init(gpa),
            .initialized = false,
            .shutdown_requested = false,
        };
    }

    pub fn deinit(self: *Server) void {
        self.files.deinit();
        self.feedback.deinit();
    }

    /// Main loop: reads messages from stdin and dispatches until shutdown.
    pub fn run(self: *Server) !void {
        var buf: [65536]u8 = undefined;
        var file_reader = std.Io.File.stdin().reader(self.io, &buf);

        while (true) {
            const msg = messages.readMessage(&file_reader.interface, self.gpa) catch |err| {
                std.log.err("error reading message: {}", .{err});
                continue;
            } orelse break; // EOF

            var m = msg;
            defer m.deinit(self.gpa);

            self.dispatch(&m) catch |err| {
                std.log.err("error dispatching message: {}", .{err});
            };

            if (self.shutdown_requested) break;
        }
    }

    // ── Dispatch ──────────────────────────────────────────────────────────────

    fn dispatch(self: *Server, msg: *messages.Message) !void {
        const method = msg.method();

        if (std.mem.eql(u8, method, "initialize")) {
            try self.handleInitialize(msg);
        } else if (std.mem.eql(u8, method, "initialized")) {
            // notification — no response needed
        } else if (std.mem.eql(u8, method, "shutdown")) {
            try self.handleShutdown(msg);
        } else if (std.mem.eql(u8, method, "exit")) {
            self.shutdown_requested = true;
        } else if (std.mem.eql(u8, method, "textDocument/didOpen")) {
            try self.handleDidOpen(msg);
        } else if (std.mem.eql(u8, method, "textDocument/didChange")) {
            try self.handleDidChange(msg);
        } else if (std.mem.eql(u8, method, "textDocument/didClose")) {
            try self.handleDidClose(msg);
        } else if (std.mem.eql(u8, method, "textDocument/formatting")) {
            try self.handleFormatting(msg);
        } else if (std.mem.eql(u8, method, "textDocument/hover")) {
            try self.handleHover(msg);
        } else if (std.mem.eql(u8, method, "textDocument/definition")) {
            try self.handleDefinition(msg);
        } else if (std.mem.eql(u8, method, "textDocument/documentSymbol")) {
            try self.handleDocumentSymbol(msg);
        } else if (std.mem.eql(u8, method, "textDocument/completion")) {
            try self.handleCompletion(msg);
        } else if (std.mem.eql(u8, method, "textDocument/references")) {
            try self.handleReferences(msg);
        } else if (std.mem.eql(u8, method, "textDocument/rename")) {
            try self.handleRename(msg);
        } else if (std.mem.eql(u8, method, "textDocument/signatureHelp")) {
            try self.handleSignatureHelp(msg);
        } else if (std.mem.eql(u8, method, "textDocument/inlayHint")) {
            try self.handleInlayHint(msg);
        } else if (msg.kind == .request) {
            try messages.writeError(self.io, self.gpa, msg.id(), -32601, "Method not found");
        }
        // Unknown notifications are silently ignored.
    }

    // ── initialize ────────────────────────────────────────────────────────────

    fn handleInitialize(self: *Server, msg: *messages.Message) !void {
        self.initialized = true;

        const result = proto.InitializeResult{
            .capabilities = .{
                .textDocumentSync = .{
                    .openClose = true,
                    .change = proto.TextDocumentSyncKind.Full,
                    .save = true,
                },
                .hoverProvider = true,
                .definitionProvider = true,
                .documentFormattingProvider = true,
                .documentSymbolProvider = true,
                .completionProvider = .{ .triggerCharacters = null, .resolveProvider = false },
                .referencesProvider = true,
                .renameProvider = true,
                .diagnosticProvider = null,
                .signatureHelpProvider = .{
                    .triggerCharacters = &.{"("},
                    .retriggerCharacters = &.{","},
                },
                .inlayHintProvider = true,
            },
            .serverInfo = .{ .name = "botopink-lsp", .version = "0.1.0" },
        };

        try messages.writeResponse(self.io, self.gpa, msg.id(), result);
    }

    // ── shutdown ──────────────────────────────────────────────────────────────

    fn handleShutdown(self: *Server, msg: *messages.Message) !void {
        self.shutdown_requested = true;
        try messages.writeResponse(self.io, self.gpa, msg.id(), null);
    }

    // ── textDocument/didOpen ──────────────────────────────────────────────────

    fn handleDidOpen(self: *Server, msg: *messages.Message) !void {
        const params = msg.params();
        if (params == .null) return;
        const td = params.object.get("textDocument") orelse return;
        const uri = jsonStr(td, "uri") orelse return;
        const text = jsonStr(td, "text") orelse return;
        try self.files.open(uri, text);
        try self.publishDiagnostics(uri, text);
    }

    // ── textDocument/didChange ────────────────────────────────────────────────

    fn handleDidChange(self: *Server, msg: *messages.Message) !void {
        const params = msg.params();
        if (params == .null) return;
        const td = params.object.get("textDocument") orelse return;
        const uri = jsonStr(td, "uri") orelse return;
        const changes = params.object.get("contentChanges") orelse return;
        if (changes != .array or changes.array.items.len == 0) return;
        const text = jsonStr(changes.array.items[0], "text") orelse return;
        try self.files.change(uri, text);
        try self.publishDiagnostics(uri, text);
    }

    // ── textDocument/didClose ─────────────────────────────────────────────────

    fn handleDidClose(self: *Server, msg: *messages.Message) !void {
        const params = msg.params();
        if (params == .null) return;
        const td = params.object.get("textDocument") orelse return;
        const uri = jsonStr(td, "uri") orelse return;
        self.files.close(uri);
        if (self.feedback.has(uri)) {
            try self.sendDiagnostics(uri, &.{});
            self.feedback.clear(uri);
        }
    }

    // ── textDocument/formatting ───────────────────────────────────────────────

    fn handleFormatting(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        if (try engine.formatting(arena.allocator(), source)) |edit| {
            const edits = [_]proto.TextEdit{edit};
            try messages.writeResponse(self.io, self.gpa, msg.id(), edits);
        } else {
            try messages.writeResponse(self.io, self.gpa, msg.id(), null);
        }
    }

    // ── textDocument/hover ────────────────────────────────────────────────────

    fn handleHover(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        const pos = positionFromParams(msg.params()) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        // Compile to get typed bindings
        var lsp_compiler = @import("./compiler.zig").LspCompiler.init(self.gpa);
        const entries = [_]@import("./compiler.zig").ModuleEntry{.{ .uri = uri, .source = source }};
        var result = lsp_compiler.compile(&entries) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer result.deinit(self.gpa);

        const bindings = blk: {
            for (result.session.outputs.items) |output| {
                if (!std.mem.eql(u8, output.name, lsp_types.uriToPath(uri))) continue;
                if (output.outcome == .ok) break :blk output.outcome.ok.bindings;
            }
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        if (try engine.hover(self.gpa, source, pos, bindings)) |h| {
            defer self.gpa.free(h.contents.value);
            try messages.writeResponse(self.io, self.gpa, msg.id(), h);
        } else {
            try messages.writeResponse(self.io, self.gpa, msg.id(), null);
        }
    }

    // ── textDocument/definition ───────────────────────────────────────────────

    fn handleDefinition(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        const pos = positionFromParams(msg.params()) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        var lexer = Lexer.init(source);
        const tokens = lexer.scanAll(arena.allocator()) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        if (try engine.definition(self.gpa, uri, source, pos, tokens)) |loc| {
            defer self.gpa.free(loc.uri);
            try messages.writeResponse(self.io, self.gpa, msg.id(), loc);
        } else {
            try messages.writeResponse(self.io, self.gpa, msg.id(), null);
        }
    }

    // ── textDocument/documentSymbol ───────────────────────────────────────────

    fn handleDocumentSymbol(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        var lexer = Lexer.init(source);
        const tokens = lexer.scanAll(arena.allocator()) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const syms = try engine.documentSymbols(self.gpa, tokens);
        defer {
            for (syms) |s| self.gpa.free(s.name);
            self.gpa.free(syms);
        }

        try messages.writeResponse(self.io, self.gpa, msg.id(), syms);
    }

    // ── textDocument/completion ───────────────────────────────────────────────

    fn handleCompletion(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        const pos = positionFromParams(msg.params()) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var lsp_compiler = @import("./compiler.zig").LspCompiler.init(self.gpa);
        const entries = [_]@import("./compiler.zig").ModuleEntry{.{ .uri = uri, .source = source }};
        var result = lsp_compiler.compile(&entries) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer result.deinit(self.gpa);

        const bindings = blk: {
            for (result.session.outputs.items) |output| {
                if (!std.mem.eql(u8, output.name, lsp_types.uriToPath(uri))) continue;
                if (output.outcome == .ok) break :blk output.outcome.ok.bindings;
            }
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const items = try engine.completion(self.gpa, source, pos, bindings);
        defer {
            for (items) |it| {
                self.gpa.free(it.label);
                if (it.detail) |d| self.gpa.free(d);
            }
            self.gpa.free(items);
        }

        const list = proto.CompletionList{ .isIncomplete = false, .items = items };
        try messages.writeResponse(self.io, self.gpa, msg.id(), list);
    }

    // ── textDocument/references ───────────────────────────────────────────────

    fn handleReferences(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        const pos = positionFromParams(msg.params()) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        // include_declaration from context params
        const include_decl = blk: {
            const p = msg.params();
            if (p == .null) break :blk false;
            const ctx = p.object.get("context") orelse break :blk false;
            break :blk switch (ctx.object.get("includeDeclaration") orelse .null) {
                .bool => |b| b,
                else => false,
            };
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        var lexer = Lexer.init(source);
        const tokens = lexer.scanAll(arena.allocator()) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const locs = try engine.references(self.gpa, uri, source, pos, tokens, include_decl);
        defer {
            for (locs) |l| self.gpa.free(l.uri);
            self.gpa.free(locs);
        }

        try messages.writeResponse(self.io, self.gpa, msg.id(), locs);
    }

    // ── textDocument/rename ───────────────────────────────────────────────────

    fn handleRename(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        const pos = positionFromParams(msg.params()) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        const new_name = blk: {
            const p = msg.params();
            if (p == .null) return messages.writeResponse(self.io, self.gpa, msg.id(), null);
            break :blk switch (p.object.get("newName") orelse .null) {
                .string => |s| s,
                else => return messages.writeResponse(self.io, self.gpa, msg.id(), null),
            };
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        var lexer = Lexer.init(source);
        const tokens = lexer.scanAll(arena.allocator()) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const edits = try engine.rename(self.gpa, source, pos, new_name, tokens);
        defer self.gpa.free(edits);

        // Serialize WorkspaceEdit manually: {"changes":{"<uri>":[TextEdit,…]}}
        // We build the JSON body directly to avoid std.json.ObjectMap vtable issues.
        try writeRenameResponse(self.io, self.gpa, msg.id(), uri, edits);
    }

    // ── textDocument/signatureHelp ────────────────────────────────────────────

    fn handleSignatureHelp(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        const pos = positionFromParams(msg.params()) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var lsp_compiler = @import("./compiler.zig").LspCompiler.init(self.gpa);
        const entries = [_]@import("./compiler.zig").ModuleEntry{.{ .uri = uri, .source = source }};
        var result = lsp_compiler.compile(&entries) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer result.deinit(self.gpa);

        const bindings = blk: {
            for (result.session.outputs.items) |output| {
                if (!std.mem.eql(u8, output.name, lsp_types.uriToPath(uri))) continue;
                if (output.outcome == .ok) break :blk output.outcome.ok.bindings;
            }
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        if (try engine.signatureHelp(arena.allocator(), source, pos, bindings)) |sh| {
            try messages.writeResponse(self.io, self.gpa, msg.id(), sh);
        } else {
            try messages.writeResponse(self.io, self.gpa, msg.id(), null);
        }
    }

    // ── textDocument/inlayHint ────────────────────────────────────────────────

    fn handleInlayHint(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        // Extract the requested range (required by LSP spec).
        const range = rangeFromParams(msg.params()) orelse proto.Range{
            .start = .{ .line = 0, .character = 0 },
            .end = .{ .line = std.math.maxInt(u32), .character = 0 },
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var lsp_compiler = @import("./compiler.zig").LspCompiler.init(self.gpa);
        const entries = [_]@import("./compiler.zig").ModuleEntry{.{ .uri = uri, .source = source }};
        var result = lsp_compiler.compile(&entries) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), &.{});
        };
        defer result.deinit(self.gpa);

        const bindings = blk: {
            for (result.session.outputs.items) |output| {
                if (!std.mem.eql(u8, output.name, lsp_types.uriToPath(uri))) continue;
                if (output.outcome == .ok) break :blk output.outcome.ok.bindings;
            }
            return messages.writeResponse(self.io, self.gpa, msg.id(), &.{});
        };

        var lex_arena = std.heap.ArenaAllocator.init(self.gpa);
        defer lex_arena.deinit();

        var lexer = Lexer.init(source);
        const tokens = lexer.scanAll(lex_arena.allocator()) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), &.{});
        };

        var hint_arena = std.heap.ArenaAllocator.init(self.gpa);
        defer hint_arena.deinit();

        const hints = try engine.inlayHints(hint_arena.allocator(), tokens, bindings, range);
        try messages.writeResponse(self.io, self.gpa, msg.id(), hints);
    }

    // ── Diagnostic helpers ────────────────────────────────────────────────────

    fn publishDiagnostics(self: *Server, uri: []const u8, source: []const u8) !void {
        var result = try engine.diagnose(self.gpa, self.io, uri, source);
        defer result.deinit(self.gpa);

        try self.sendDiagnostics(uri, result.diagnostics);

        if (result.diagnostics.len > 0) {
            try self.feedback.mark(uri);
        } else {
            self.feedback.clear(uri);
        }
    }

    fn sendDiagnostics(self: *Server, uri: []const u8, diags: []const proto.Diagnostic) !void {
        const params = proto.PublishDiagnosticsParams{ .uri = uri, .diagnostics = diags };
        try messages.writeNotification(self.io, self.gpa, "textDocument/publishDiagnostics", params);
    }

    // ── Param extraction helpers ──────────────────────────────────────────────

    fn uriFromTextDocument(self: *const Server, msg: *messages.Message) ?[]const u8 {
        _ = self;
        const params = msg.params();
        if (params == .null) return null;
        const td = params.object.get("textDocument") orelse return null;
        return jsonStr(td, "uri");
    }
};

/// Writes a WorkspaceEdit response for a single-file rename.
/// Builds the JSON body manually to avoid vtable-in-json issues.
fn writeRenameResponse(
    io: std.Io,
    gpa: std.mem.Allocator,
    id: std.json.Value,
    uri: []const u8,
    edits: []const proto.TextEdit,
) !void {
    const id_json = try std.json.Stringify.valueAlloc(gpa, id, .{});
    defer gpa.free(id_json);

    // Build edits array JSON
    var edit_buf: std.ArrayList(u8) = .empty;
    defer edit_buf.deinit(gpa);

    try edit_buf.append(gpa, '[');
    for (edits, 0..) |edit, i| {
        if (i > 0) try edit_buf.append(gpa, ',');
        const new_text_json = try std.json.Stringify.valueAlloc(gpa, edit.newText, .{});
        defer gpa.free(new_text_json);
        const piece = try std.fmt.allocPrint(gpa,
            \\{{"range":{{"start":{{"line":{d},"character":{d}}},"end":{{"line":{d},"character":{d}}}}},"newText":{s}}}
        , .{
            edit.range.start.line, edit.range.start.character,
            edit.range.end.line,   edit.range.end.character,
            new_text_json,
        });
        defer gpa.free(piece);
        try edit_buf.appendSlice(gpa, piece);
    }
    try edit_buf.append(gpa, ']');

    const uri_json = try std.json.Stringify.valueAlloc(gpa, uri, .{});
    defer gpa.free(uri_json);

    const body = try std.fmt.allocPrint(gpa,
        \\{{"jsonrpc":"2.0","id":{s},"result":{{"changes":{{{s}:{s}}}}}}}
    , .{ id_json, uri_json, edit_buf.items });
    defer gpa.free(body);

    const header = try std.fmt.allocPrint(gpa, "Content-Length: {d}\r\n\r\n", .{body.len});
    defer gpa.free(header);

    const frame = try std.mem.concat(gpa, u8, &.{ header, body });
    defer gpa.free(frame);

    try std.Io.File.stdout().writeStreamingAll(io, frame);
}

fn rangeFromParams(params: std.json.Value) ?proto.Range {
    if (params == .null) return null;
    const r = params.object.get("range") orelse return null;
    const start = positionFromObject(r.object.get("start") orelse return null) orelse return null;
    const end = positionFromObject(r.object.get("end") orelse return null) orelse return null;
    return .{ .start = start, .end = end };
}

fn positionFromObject(val: std.json.Value) ?proto.Position {
    const line = switch (val.object.get("line") orelse .null) {
        .integer => |n| @as(u32, @intCast(n)),
        else => return null,
    };
    const character = switch (val.object.get("character") orelse .null) {
        .integer => |n| @as(u32, @intCast(n)),
        else => return null,
    };
    return .{ .line = line, .character = character };
}

fn positionFromParams(params: std.json.Value) ?proto.Position {
    if (params == .null) return null;
    const pos_val = params.object.get("position") orelse return null;
    const line = switch (pos_val.object.get("line") orelse .null) {
        .integer => |n| @as(u32, @intCast(n)),
        else => return null,
    };
    const character = switch (pos_val.object.get("character") orelse .null) {
        .integer => |n| @as(u32, @intCast(n)),
        else => return null,
    };
    return .{ .line = line, .character = character };
}

fn jsonStr(val: std.json.Value, key: []const u8) ?[]const u8 {
    return switch (val.object.get(key) orelse .null) {
        .string => |s| s,
        else => null,
    };
}
