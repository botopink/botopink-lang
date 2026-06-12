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
const index_mod = @import("./project_index.zig");
const graph_mod = @import("./project_graph.zig");
const compiler_mod = @import("./compiler.zig");

const Lexer = bp.Lexer;

/// Best-effort scratch root for the template evaluator. Prefers the user cache
/// dir (`$XDG_CACHE_HOME` / `$HOME/.cache`), falling back to a cwd-relative
/// `.botopinkbuild/lsp` (also used when there is no process environment, e.g.
/// tests). Returns null only if every allocation fails. The returned slice is
/// owned by the caller (freed in `Server.deinit`).
fn computeTemplateRoot(gpa: std.mem.Allocator, environ_map: ?*std.process.Environ.Map) ?[]const u8 {
    if (environ_map) |env| {
        if (env.get("XDG_CACHE_HOME")) |xdg|
            return std.fmt.allocPrint(gpa, "{s}/botopink-lsp/template", .{xdg}) catch null;
        if (env.get("HOME")) |home|
            return std.fmt.allocPrint(gpa, "{s}/.cache/botopink-lsp/template", .{home}) catch null;
    }
    return gpa.dupe(u8, ".botopinkbuild/lsp") catch null;
}

pub const Server = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    /// Process environment (from `std.process.Init`) — null in tests.
    environ_map: ?*std.process.Environ.Map,
    files: files_mod.FileCache,
    feedback: feedback_mod.FeedbackBookkeeper,
    index: index_mod.ProjectIndex,
    /// Per-project dependency graph (lib `from "<lib>"` + `mod` siblings),
    /// resolved from `botopink.json` and cached so a keystroke reuses it.
    graph: graph_mod.ProjectGraph,
    initialized: bool,
    shutdown_requested: bool,
    /// Monotonic id for server→client requests (e.g. inlay-hint refresh).
    next_request_id: i64,
    /// Scratch root for the node-backed template evaluator (`<cache>/botopink-lsp`
    /// or `.botopinkbuild/lsp`). Computed once, owned by the server. When the
    /// compiler runs with it, `@ExprCustom` sub-languages expand and their
    /// `CustomNode` trees light up inside the literal (sublanguage-lsp).
    template_root: ?[]const u8,

    pub fn init(gpa: std.mem.Allocator, io: std.Io, environ_map: ?*std.process.Environ.Map) Server {
        return .{
            .gpa = gpa,
            .io = io,
            .environ_map = environ_map,
            .files = files_mod.FileCache.init(gpa),
            .feedback = feedback_mod.FeedbackBookkeeper.init(gpa),
            .index = index_mod.ProjectIndex.init(gpa, io),
            .graph = graph_mod.ProjectGraph.init(gpa, io),
            .initialized = false,
            .shutdown_requested = false,
            .next_request_id = 1,
            .template_root = computeTemplateRoot(gpa, environ_map),
        };
    }

    pub fn deinit(self: *Server) void {
        self.files.deinit();
        self.feedback.deinit();
        self.index.deinit();
        self.graph.deinit();
        if (self.template_root) |r| self.gpa.free(r);
    }

    /// Build an LSP compiler bound to this server's io + template-eval root, so
    /// every compile can expand sub-language templates for tooling.
    fn makeCompiler(self: *Server) compiler_mod.LspCompiler {
        return compiler_mod.LspCompiler.init(self.gpa, self.io, self.template_root);
    }

    /// Build the module list to compile for `uri`: its project dependencies
    /// (`from "<lib>"` packages + `mod` siblings, resolved from `botopink.json`)
    /// followed by the active document LAST, so it can import from every dep.
    /// Declaration-only `.d.bp` modules are excluded from the compile (they carry
    /// no bodies). When the file is not inside a project, falls back to the
    /// single active document. Entries are arena-allocated; their sources are
    /// borrowed (graph cache + the in-memory `source`), valid for this call.
    fn buildModuleEntries(
        self: *Server,
        arena: std.mem.Allocator,
        uri: []const u8,
        source: []const u8,
    ) ![]compiler_mod.ModuleEntry {
        const active_path = lsp_types.uriToPath(uri);
        const resolved = (self.graph.resolve(uri) catch null) orelse {
            const one = try arena.alloc(compiler_mod.ModuleEntry, 1);
            one[0] = .{ .uri = uri, .source = source };
            return one;
        };

        var list: std.ArrayListUnmanaged(compiler_mod.ModuleEntry) = .empty;
        for (resolved.deps) |dep| {
            if (dep.declaration) continue; // mirror the CLI: `.d.bp` not compiled
            if (samePath(lsp_types.uriToPath(dep.uri), active_path)) continue; // the active doc
            // Overlay an open buffer so unsaved edits to a dependency are seen.
            const src = self.files.get(dep.uri) orelse dep.source;
            try list.append(arena, .{ .uri = dep.uri, .source = src });
        }
        try list.append(arena, .{ .uri = uri, .source = source }); // active doc LAST
        return list.toOwnedSlice(arena);
    }

    /// The project dependency sources (libs + siblings, INCLUDING `.d.bp`
    /// declaration surfaces) as `engine.ModuleSource` for cross-module
    /// go-to-def. Empty when the file is not inside a project.
    fn graphOthers(
        self: *Server,
        arena: std.mem.Allocator,
        uri: []const u8,
    ) ![]engine.ModuleSource {
        const active_path = lsp_types.uriToPath(uri);
        const resolved = (self.graph.resolve(uri) catch null) orelse return &.{};
        var list: std.ArrayListUnmanaged(engine.ModuleSource) = .empty;
        for (resolved.deps) |dep| {
            if (samePath(lsp_types.uriToPath(dep.uri), active_path)) continue;
            const src = self.files.get(dep.uri) orelse dep.source;
            try list.append(arena, .{ .uri = dep.uri, .source = src });
        }
        return list.toOwnedSlice(arena);
    }

    /// Compile `uri`'s document together with its project module graph. The
    /// returned `CompileResult` borrows the active `source`/`uri` and the graph
    /// cache (both outlive the call); only the entry array is temporary.
    fn compileWithGraph(self: *Server, uri: []const u8, source: []const u8) !compiler_mod.CompileResult {
        var ea = std.heap.ArenaAllocator.init(self.gpa);
        defer ea.deinit();
        const entries = try self.buildModuleEntries(ea.allocator(), uri, source);
        var lsp_compiler = self.makeCompiler();
        return lsp_compiler.compile(entries);
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
        } else if (std.mem.eql(u8, method, "textDocument/typeDefinition")) {
            try self.handleTypeDefinition(msg);
        } else if (std.mem.eql(u8, method, "textDocument/foldingRange")) {
            try self.handleFoldingRange(msg);
        } else if (std.mem.eql(u8, method, "textDocument/prepareRename")) {
            try self.handlePrepareRename(msg);
        } else if (std.mem.eql(u8, method, "textDocument/codeAction")) {
            try self.handleCodeAction(msg);
        } else if (std.mem.eql(u8, method, "textDocument/semanticTokens/full")) {
            try self.handleSemanticTokens(msg, null);
        } else if (std.mem.eql(u8, method, "textDocument/semanticTokens/range")) {
            try self.handleSemanticTokens(msg, rangeFromParams(msg.params()));
        } else if (msg.kind == .request) {
            try messages.writeError(self.io, self.gpa, msg.id(), -32601, "Method not found");
        }
        // Unknown notifications are silently ignored.
    }

    // ── initialize ────────────────────────────────────────────────────────────

    fn handleInitialize(self: *Server, msg: *messages.Message) !void {
        self.initialized = true;

        // Extract rootUri for project indexing.
        const params = msg.params();
        if (params != .null) {
            if (jsonStr(params, "rootUri")) |root_uri| {
                self.index.setRoot(root_uri) catch {};
            }
        }

        const result = proto.InitializeResult{
            .capabilities = .{
                .textDocumentSync = .{
                    .openClose = true,
                    .change = proto.TextDocumentSyncKind.Full,
                    .save = true,
                },
                .hoverProvider = true,
                .definitionProvider = true,
                .typeDefinitionProvider = true,
                .documentFormattingProvider = true,
                .documentSymbolProvider = true,
                .completionProvider = .{ .triggerCharacters = &.{"."}, .resolveProvider = false },
                .referencesProvider = true,
                .renameProvider = .{ .prepareProvider = true },
                .diagnosticProvider = null,
                .signatureHelpProvider = .{
                    .triggerCharacters = &.{"("},
                    .retriggerCharacters = &.{ ",", ":" },
                },
                .inlayHintProvider = true,
                .codeActionProvider = true,
                .foldingRangeProvider = true,
                .semanticTokensProvider = .{
                    .legend = .{
                        .tokenTypes = &proto.SemanticTokenTypes.legend,
                        .tokenModifiers = &proto.SemanticTokenModifiers.legend,
                    },
                    .range = true,
                    .full = true,
                },
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
        // A newly opened file may be (or join) a project dependency; re-resolve
        // the graph so its `src` tree is current. A keystroke (didChange) does
        // NOT invalidate — open buffers are overlaid, so cached deps stay valid.
        self.graph.invalidateAll();
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
        self.index.invalidate();
        try self.publishDiagnostics(uri, text);

        // Inferred-type / parameter inlay hints can change on every edit; ask
        // the client to re-query them. Harmless if unsupported (ignored reply).
        messages.writeRequest(self.io, self.gpa, self.next_request_id, "workspace/inlayHint/refresh", null) catch {};
        self.next_request_id += 1;
    }

    // ── textDocument/didClose ─────────────────────────────────────────────────

    fn handleDidClose(self: *Server, msg: *messages.Message) !void {
        const params = msg.params();
        if (params == .null) return;
        const td = params.object.get("textDocument") orelse return;
        const uri = jsonStr(td, "uri") orelse return;
        self.files.close(uri);
        // The closed buffer's on-disk content is now authoritative again; drop the
        // cached graph so the next compile re-reads it from disk (save/watch).
        self.graph.invalidateAll();
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
        var result = self.compileWithGraph(uri, source) catch {
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

        // Cursor inside a sub-language literal (`erika "…"`): hover the symbol
        // the `CustomNode.ref` resolves to (sublanguage-lsp F3). Tried first
        // because the bound symbol (e.g. a struct) differs from the word under
        // the cursor (e.g. a column name).
        if (try engine.hoverCustomRef(self.gpa, source, pos, bindings, result.customAstFor(uri))) |h| {
            defer self.gpa.free(h.contents.value);
            return messages.writeResponse(self.io, self.gpa, msg.id(), h);
        }

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

        // Cursor inside a sub-language literal (`erika "…"`): jump to the
        // declaration of the symbol its `CustomNode.ref` binds (sublanguage-lsp
        // F3). Gated on being inside a string so the common path skips the extra
        // template-expanding compile.
        if (engine.cursorInString(source, lsp_types.positionToOffset(source, pos))) {
            if (self.compileWithGraph(uri, source)) |res| {
                var result = res;
                defer result.deinit(self.gpa);
                if (try engine.definitionCustomRef(self.gpa, uri, source, pos, tokens, result.customAstFor(uri))) |loc| {
                    defer self.gpa.free(loc.uri);
                    return messages.writeResponse(self.io, self.gpa, msg.id(), loc);
                }
            } else |_| {}
        }

        // Type-aware resolution for member access (`recv.field` / `recv.method`),
        // builtin methods, `self.field`, `Name(label:)` constructor labels and
        // `mod` references — these need the receiver's type, so they run before
        // (and override) the name-scan `definition` below. Gated on a cheap
        // syntactic pre-check so a plain symbol jump stays compile-free.
        if (engine.needsTypedDefinition(source, pos, tokens)) {
            var ga = std.heap.ArenaAllocator.init(self.gpa);
            defer ga.deinit();
            const g_others = self.graphOthers(ga.allocator(), uri) catch &.{};
            if (self.compileWithGraph(uri, source)) |res| {
                var result = res;
                defer result.deinit(self.gpa);
                const bindings = result.bindingsFor(uri);
                if (try engine.definitionMember(self.gpa, uri, source, pos, tokens, bindings, g_others)) |td| {
                    switch (td) {
                        .location => |loc| {
                            defer self.gpa.free(loc.uri);
                            return messages.writeResponse(self.io, self.gpa, msg.id(), loc);
                        },
                        .builtin => |bj| {
                            // The method lives in the embedded primitives source;
                            // materialize it to the cache so the editor can open it.
                            if (self.materializeStdModule(.{ .name = "primitives", .source = bj.source })) |path| {
                                defer self.gpa.free(path);
                                const std_uri = try lsp_types.pathToUri(self.gpa, path);
                                defer self.gpa.free(std_uri);
                                const loc = proto.Location{ .uri = std_uri, .range = bj.range };
                                return messages.writeResponse(self.io, self.gpa, msg.id(), loc);
                            }
                        },
                    }
                }
            } else |_| {}
        }

        // First try a declaration in the current file.
        if (try engine.definition(self.gpa, uri, source, pos, tokens)) |loc| {
            defer self.gpa.free(loc.uri);
            return messages.writeResponse(self.io, self.gpa, msg.id(), loc);
        }

        // Project graph (resolved from `botopink.json`) is the source of truth for
        // `from "<lib>"` symbols (incl. member access like `Response.created`) —
        // search the lib `src` + `files` surface before the workspace-scanned
        // index. The dep sources are borrowed from the graph cache.
        {
            var ga = std.heap.ArenaAllocator.init(self.gpa);
            defer ga.deinit();
            const g_others = self.graphOthers(ga.allocator(), uri) catch &.{};
            if (g_others.len > 0) {
                if (try engine.definitionInModules(self.gpa, uri, source, pos, tokens, g_others)) |loc| {
                    defer self.gpa.free(loc.uri);
                    return messages.writeResponse(self.io, self.gpa, msg.id(), loc);
                }
            }
        }

        // On a local miss, resolve imported symbols against other modules.
        self.index.ensureIndexed();
        const syms = self.index.getAllSymbols();
        var others: std.ArrayList(engine.ModuleSource) = .empty;
        defer {
            for (others.items) |m| self.gpa.free(m.source);
            others.deinit(self.gpa);
        }
        for (syms) |sym| {
            if (std.mem.eql(u8, sym.uri, uri)) continue;
            var dup = false;
            for (others.items) |o| {
                if (std.mem.eql(u8, o.uri, sym.uri)) {
                    dup = true;
                    break;
                }
            }
            if (dup) continue;
            const msrc = self.files.read(self.gpa, self.io, sym.uri) catch continue;
            others.append(self.gpa, .{ .uri = sym.uri, .source = msrc }) catch {
                self.gpa.free(msrc);
                continue;
            };
        }

        if (try engine.definitionInModules(self.gpa, uri, source, pos, tokens, others.items)) |loc| {
            defer self.gpa.free(loc.uri);
            return messages.writeResponse(self.io, self.gpa, msg.id(), loc);
        }

        // Still unresolved — try the embedded "std" package modules
        // (`import {list} from "std"; … list.map(…)`). The module source is
        // materialized into a cache dir so the editor can open it.
        if (try engine.definitionInStdModules(self.gpa, source, pos)) |sd| {
            if (self.materializeStdModule(sd.module)) |path| {
                defer self.gpa.free(path);
                const std_uri = try lsp_types.pathToUri(self.gpa, path);
                defer self.gpa.free(std_uri);
                const loc = proto.Location{ .uri = std_uri, .range = sd.range };
                return messages.writeResponse(self.io, self.gpa, msg.id(), loc);
            }
        }

        try messages.writeResponse(self.io, self.gpa, msg.id(), null);
    }

    /// Writes one embedded std module to `<cache>/botopink-lsp/std/<name>.bp`
    /// so go-to-definition can jump into it. Returns the absolute path (owned
    /// by the caller), or null when the cache dir cannot be resolved/written.
    fn materializeStdModule(self: *Server, mod: engine.StdModule) ?[]u8 {
        const env = self.environ_map orelse return null;
        const dir_path = if (env.get("XDG_CACHE_HOME")) |xdg|
            std.fmt.allocPrint(self.gpa, "{s}/botopink-lsp/std", .{xdg}) catch return null
        else if (env.get("HOME")) |home|
            std.fmt.allocPrint(self.gpa, "{s}/.cache/botopink-lsp/std", .{home}) catch return null
        else
            return null;
        defer self.gpa.free(dir_path);

        const cwd = std.Io.Dir.cwd();
        cwd.createDirPath(self.io, dir_path) catch |err| switch (err) {
            error.PathAlreadyExists => {},
            else => return null,
        };

        const file_path = std.fmt.allocPrint(self.gpa, "{s}/{s}.bp", .{ dir_path, mod.name }) catch return null;
        // Always overwrite — the content tracks this binary's stdlib version.
        cwd.writeFile(self.io, .{ .sub_path = file_path, .data = mod.source }) catch {
            self.gpa.free(file_path);
            return null;
        };
        return file_path;
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
            for (syms) |s| engine.freeSymbol(self.gpa, s);
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

        var result = self.compileWithGraph(uri, source) catch {
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

        // Try module completion first (inside `from "..."`).
        if (try engine.moduleCompletion(self.gpa, source, pos, &self.index)) |mod_items| {
            defer {
                for (mod_items) |it| self.gpa.free(it.label);
                self.gpa.free(mod_items);
            }
            const list = proto.CompletionList{ .isIncomplete = false, .items = mod_items };
            return messages.writeResponse(self.io, self.gpa, msg.id(), list);
        }

        const items = try engine.completion(self.gpa, source, pos, bindings);
        defer {
            for (items) |it| {
                self.gpa.free(it.label);
                if (it.detail) |d| self.gpa.free(d);
                if (it.insertText) |t| self.gpa.free(t);
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

        const locs = if (self.index.root_uri != null)
            try engine.crossModuleReferences(self.gpa, self.io, source, pos, uri, tokens, include_decl, &self.index)
        else
            try engine.references(self.gpa, uri, source, pos, tokens, include_decl);
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

        if (self.index.root_uri != null) {
            const result = try engine.crossModuleRename(self.gpa, self.io, source, pos, new_name, uri, tokens, &self.index);
            defer {
                for (result.entries) |e| {
                    self.gpa.free(e.uri);
                    self.gpa.free(e.edits);
                }
                self.gpa.free(result.entries);
            }
            try writeMultiFileRenameResponse(self.io, self.gpa, msg.id(), result.entries);
        } else {
            const edits = try engine.rename(self.gpa, source, pos, new_name, tokens);
            defer self.gpa.free(edits);
            try writeRenameResponse(self.io, self.gpa, msg.id(), uri, edits);
        }
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

        var result = self.compileWithGraph(uri, source) catch {
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

        var result = self.compileWithGraph(uri, source) catch {
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

    // ── textDocument/semanticTokens/{full,range} ──────────────────────────────

    fn handleSemanticTokens(self: *Server, msg: *messages.Message, range: ?proto.Range) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        // Semantic tokens are token-driven, so they survive type errors: the
        // lexer always runs, and `bindings` is best-effort (empty on failure).
        var lexer = Lexer.init(source);
        const tokens = lexer.scanAll(arena.allocator()) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), proto.SemanticTokens{ .data = &.{} });
        };

        var bindings: []const @import("botopink").comptime_pipeline.TypedBinding = &.{};
        var result = self.compileWithGraph(uri, source) catch null;
        defer if (result) |*r| r.deinit(self.gpa);
        if (result) |r| {
            for (r.session.outputs.items) |output| {
                if (!std.mem.eql(u8, output.name, lsp_types.uriToPath(uri))) continue;
                if (output.outcome == .ok) bindings = output.outcome.ok.bindings;
            }
        }

        const lexed = try engine.semanticTokens(arena.allocator(), tokens, bindings);

        // Overlay sub-language tokens (`@ExprCustom` Custom AST) inside string
        // literals, then re-sort into one stream (sublanguage-lsp F1).
        const custom = if (result) |*r|
            try engine.customSemanticTokens(arena.allocator(), source, r.customAstFor(uri))
        else
            &.{};
        var toks = try engine.mergeSemanticTokens(arena.allocator(), lexed, custom);

        // `/range` requests: keep only tokens whose line falls in the range.
        if (range) |rng| {
            var kept: std.ArrayList(engine.SemToken) = .empty;
            for (toks) |t| {
                if (t.line >= rng.start.line and t.line <= rng.end.line)
                    try kept.append(arena.allocator(), t);
            }
            toks = try kept.toOwnedSlice(arena.allocator());
        }

        const data = try engine.encodeSemanticTokens(arena.allocator(), toks);
        try messages.writeResponse(self.io, self.gpa, msg.id(), proto.SemanticTokens{ .data = data });
    }

    // ── textDocument/typeDefinition ─────────────────────────────────────────

    fn handleTypeDefinition(self: *Server, msg: *messages.Message) !void {
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

        var result = self.compileWithGraph(uri, source) catch {
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

        if (try engine.typeDefinition(self.gpa, uri, source, pos, tokens, bindings)) |loc| {
            defer self.gpa.free(loc.uri);
            try messages.writeResponse(self.io, self.gpa, msg.id(), loc);
        } else {
            try messages.writeResponse(self.io, self.gpa, msg.id(), null);
        }
    }

    // ── textDocument/foldingRange ─────────────────────────────────────────────

    fn handleFoldingRange(self: *Server, msg: *messages.Message) !void {
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

        const ranges = try engine.foldingRanges(self.gpa, source, tokens);
        defer self.gpa.free(ranges);

        try messages.writeResponse(self.io, self.gpa, msg.id(), ranges);
    }

    // ── textDocument/prepareRename ────────────────────────────────────────────

    fn handlePrepareRename(self: *Server, msg: *messages.Message) !void {
        const pos = positionFromParams(msg.params()) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const source = self.files.read(self.gpa, self.io, uri) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer self.gpa.free(source);

        if (engine.prepareRename(source, pos)) |result| {
            try messages.writeResponse(self.io, self.gpa, msg.id(), result);
        } else {
            try messages.writeResponse(self.io, self.gpa, msg.id(), null);
        }
    }

    // ── textDocument/codeAction ───────────────────────────────────────────────

    fn handleCodeAction(self: *Server, msg: *messages.Message) !void {
        const uri = self.uriFromTextDocument(msg) orelse {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };

        const range = rangeFromParams(msg.params()) orelse proto.Range{
            .start = .{ .line = 0, .character = 0 },
            .end = .{ .line = std.math.maxInt(u32), .character = 0 },
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

        var result = self.compileWithGraph(uri, source) catch {
            return messages.writeResponse(self.io, self.gpa, msg.id(), null);
        };
        defer result.deinit(self.gpa);

        const bindings = blk: {
            for (result.session.outputs.items) |output| {
                if (!std.mem.eql(u8, output.name, lsp_types.uriToPath(uri))) continue;
                if (output.outcome == .ok) break :blk output.outcome.ok.bindings;
            }
            return messages.writeResponse(self.io, self.gpa, msg.id(), &.{});
        };

        const actions = try engine.codeActions(self.gpa, uri, source, range, tokens, bindings, &self.index);
        defer {
            for (actions) |a| {
                self.gpa.free(a.title);
                if (a.edit) |edit| {
                    if (edit.documentChanges) |dcs| {
                        for (dcs) |dc| {
                            for (dc.edits) |e| {
                                self.gpa.free(e.newText);
                            }
                            self.gpa.free(dc.edits);
                        }
                        self.gpa.free(dcs);
                    }
                }
            }
            self.gpa.free(actions);
        }

        try messages.writeResponse(self.io, self.gpa, msg.id(), actions);
    }

    // ── Diagnostic helpers ────────────────────────────────────────────────────

    fn publishDiagnostics(self: *Server, uri: []const u8, source: []const u8) !void {
        try self.sendProgress("begin", "Compiling...");

        // Compile the document together with its project graph so a file importing
        // across `mod` siblings / `from "<lib>"` doesn't report false "unbound"
        // errors. Diagnostics are still filtered to `uri`.
        var ea = std.heap.ArenaAllocator.init(self.gpa);
        defer ea.deinit();
        const entries = self.buildModuleEntries(ea.allocator(), uri, source) catch &.{};

        var result = try engine.diagnose(self.gpa, self.io, uri, source, self.template_root, entries);
        defer result.deinit(self.gpa);

        try self.sendDiagnostics(uri, result.diagnostics);

        if (result.diagnostics.len > 0) {
            try self.feedback.mark(uri);
        } else {
            self.feedback.clear(uri);
        }

        try self.sendProgress("end", null);
    }

    fn sendDiagnostics(self: *Server, uri: []const u8, diags: []const proto.Diagnostic) !void {
        const params = proto.PublishDiagnosticsParams{ .uri = uri, .diagnostics = diags };
        try messages.writeNotification(self.io, self.gpa, "textDocument/publishDiagnostics", params);
    }

    fn sendProgress(self: *Server, kind: []const u8, msg: ?[]const u8) !void {
        const params = .{
            .token = "botopink-compile",
            .value = .{
                .kind = kind,
                .title = if (msg) |m| m else "botopink",
                .message = msg,
            },
        };
        try messages.writeNotification(self.io, self.gpa, "$/progress", params);
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

/// Compare two filesystem paths for equality, treating any run of `/` as a
/// single separator and ignoring a trailing slash (so `a/src//x` == `a/src/x`).
fn samePath(a: []const u8, b: []const u8) bool {
    var i: usize = 0;
    var j: usize = 0;
    while (i < a.len and j < b.len) {
        if (a[i] == '/' and b[j] == '/') {
            while (i < a.len and a[i] == '/') i += 1;
            while (j < b.len and b[j] == '/') j += 1;
            continue;
        }
        if (a[i] != b[j]) return false;
        i += 1;
        j += 1;
    }
    while (i < a.len and a[i] == '/') i += 1;
    while (j < b.len and b[j] == '/') j += 1;
    return i == a.len and j == b.len;
}

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

fn writeMultiFileRenameResponse(
    io: std.Io,
    gpa: std.mem.Allocator,
    id: std.json.Value,
    entries: []const engine.RenameFileEntry,
) !void {
    const id_json = try std.json.Stringify.valueAlloc(gpa, id, .{});
    defer gpa.free(id_json);

    // Build {"changes": {"uri1": [...], "uri2": [...]}}
    var changes_buf: std.ArrayList(u8) = .empty;
    defer changes_buf.deinit(gpa);

    try changes_buf.append(gpa, '{');
    for (entries, 0..) |entry, ei| {
        if (ei > 0) try changes_buf.append(gpa, ',');

        const uri_json = try std.json.Stringify.valueAlloc(gpa, entry.uri, .{});
        defer gpa.free(uri_json);
        try changes_buf.appendSlice(gpa, uri_json);
        try changes_buf.append(gpa, ':');
        try changes_buf.append(gpa, '[');

        for (entry.edits, 0..) |edit, i| {
            if (i > 0) try changes_buf.append(gpa, ',');
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
            try changes_buf.appendSlice(gpa, piece);
        }
        try changes_buf.append(gpa, ']');
    }
    try changes_buf.append(gpa, '}');

    const body = try std.fmt.allocPrint(gpa,
        \\{{"jsonrpc":"2.0","id":{s},"result":{{"changes":{s}}}}}
    , .{ id_json, changes_buf.items });
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
