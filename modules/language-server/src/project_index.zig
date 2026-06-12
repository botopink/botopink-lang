/// Project-level index of `.bp` modules and their exported symbols.
///
/// Scans the workspace root for `.bp` files, lexes each one, and caches
/// the list of `pub` declarations (name + kind + file URI). The index is
/// rebuilt lazily: it is populated on first use and invalidated when a
/// file is saved or a watched file changes.
const std = @import("std");
const bp = @import("botopink");
const proto = @import("./protocol.zig");
const lsp_types = @import("./lsp_types.zig");

const Lexer = bp.Lexer;
const Token = bp.Token;
const TokenKind = bp.TokenKind;

pub const ExportedSymbol = struct {
    name: []const u8,
    kind: SymbolDeclKind,
    uri: []const u8,
    module_name: []const u8,
};

pub const SymbolDeclKind = enum {
    function,
    value,
    record,
    @"struct",
    @"enum",
    interface,
};

pub const ProjectIndex = struct {
    gpa: std.mem.Allocator,
    io: std.Io,
    root_uri: ?[]u8,
    symbols: std.ArrayList(ExportedSymbol),
    module_uris: std.ArrayList([]u8),
    dirty: bool,

    pub fn init(gpa: std.mem.Allocator, io: std.Io) ProjectIndex {
        return .{
            .gpa = gpa,
            .io = io,
            .root_uri = null,
            .symbols = .empty,
            .module_uris = .empty,
            .dirty = true,
        };
    }

    pub fn deinit(self: *ProjectIndex) void {
        self.clearSymbols();
        self.symbols.deinit(self.gpa);
        for (self.module_uris.items) |u| self.gpa.free(u);
        self.module_uris.deinit(self.gpa);
        if (self.root_uri) |r| self.gpa.free(r);
    }

    pub fn setRoot(self: *ProjectIndex, uri: []const u8) !void {
        if (self.root_uri) |old| self.gpa.free(old);
        self.root_uri = try self.gpa.dupe(u8, uri);
        self.dirty = true;
    }

    pub fn invalidate(self: *ProjectIndex) void {
        self.dirty = true;
    }

    pub fn ensureIndexed(self: *ProjectIndex) void {
        if (!self.dirty) return;
        self.rebuild();
        self.dirty = false;
    }

    pub fn getModuleNames(self: *ProjectIndex) []const []u8 {
        self.ensureIndexed();
        return self.module_uris.items;
    }

    pub fn getAllSymbols(self: *ProjectIndex) []const ExportedSymbol {
        self.ensureIndexed();
        return self.symbols.items;
    }

    pub fn findSymbol(self: *ProjectIndex, name: []const u8) ?ExportedSymbol {
        self.ensureIndexed();
        for (self.symbols.items) |sym| {
            if (std.mem.eql(u8, sym.name, name)) return sym;
        }
        return null;
    }

    pub fn findSymbolsInModule(self: *ProjectIndex, module_name: []const u8) []const ExportedSymbol {
        self.ensureIndexed();
        // Return a view — caller must not free.
        var start: usize = 0;
        var end: usize = 0;
        var found_start = false;
        for (self.symbols.items, 0..) |sym, i| {
            if (std.mem.eql(u8, sym.module_name, module_name)) {
                if (!found_start) {
                    start = i;
                    found_start = true;
                }
                end = i + 1;
            }
        }
        if (!found_start) return &.{};
        return self.symbols.items[start..end];
    }

    // ── Internal ─────────────────────────────────────────────────────────────

    fn clearSymbols(self: *ProjectIndex) void {
        for (self.symbols.items) |sym| {
            self.gpa.free(sym.name);
            self.gpa.free(sym.uri);
            self.gpa.free(sym.module_name);
        }
        self.symbols.clearRetainingCapacity();
        for (self.module_uris.items) |u| self.gpa.free(u);
        self.module_uris.clearRetainingCapacity();
    }

    fn rebuild(self: *ProjectIndex) void {
        self.clearSymbols();

        const root = self.root_uri orelse return;
        const root_path = lsp_types.uriToPath(root);

        self.scanDir(root_path) catch {};
    }

    fn scanDir(self: *ProjectIndex, dir_path: []const u8) !void {
        const cwd = std.Io.Dir.cwd();

        // `.iterate = true` is required: without it Linux opens an O_PATH fd,
        // and the first `iter.next()` panics with BADF inside the Io runtime.
        var dir = cwd.openDir(self.io, dir_path, .{ .iterate = true }) catch return;
        defer dir.close(self.io);

        var iter = dir.iterate();

        while (true) {
            const entry = iter.next(self.io) catch break;
            if (entry == null) break;
            const e = entry.?;

            const name = e.name;

            if (e.kind == .directory) {
                // Skip hidden dirs and common non-source dirs.
                if (name.len > 0 and name[0] == '.') continue;
                if (std.mem.eql(u8, name, "node_modules")) continue;
                if (std.mem.eql(u8, name, "zig-out")) continue;
                if (std.mem.eql(u8, name, "zig-cache")) continue;
                if (std.mem.eql(u8, name, ".zig-cache")) continue;

                const sub_path = std.fmt.allocPrint(self.gpa, "{s}/{s}", .{ dir_path, name }) catch continue;
                defer self.gpa.free(sub_path);
                self.scanDir(sub_path) catch {};
                continue;
            }

            if (!std.mem.endsWith(u8, name, ".bp")) continue;

            const file_path = std.fmt.allocPrint(self.gpa, "{s}/{s}", .{ dir_path, name }) catch continue;
            defer self.gpa.free(file_path);

            const file_uri = lsp_types.pathToUri(self.gpa, file_path) catch continue;
            defer self.gpa.free(file_uri);

            // Module name: filename without .d.bp or .bp extension.
            const module_name_end = if (std.mem.endsWith(u8, name, ".d.bp"))
                name.len - 5 // strip ".d.bp"
            else
                name.len - 3; // strip ".bp"
            const module_name = name[0..module_name_end];

            self.module_uris.append(self.gpa, self.gpa.dupe(u8, module_name) catch continue) catch {};

            // Read and lex the file.
            const source = cwd.readFileAlloc(self.io, file_path, self.gpa, .limited(10 * 1024 * 1024)) catch continue;
            defer self.gpa.free(source);

            self.indexFile(source, file_uri, module_name) catch {};
        }
    }

    fn indexFile(self: *ProjectIndex, source: []const u8, file_uri: []const u8, module_name: []const u8) !void {
        var arena = std.heap.ArenaAllocator.init(self.gpa);
        defer arena.deinit();

        var lexer = Lexer.init(source);
        const tokens = lexer.scanAll(arena.allocator()) catch return;

        var i: usize = 0;
        while (i < tokens.len) : (i += 1) {
            // Look for `pub` followed by a declaration keyword.
            if (tokens[i].kind != .@"pub") continue;

            var j = i + 1;
            while (j < tokens.len and tokens[j].kind == .endOfFile) : (j += 1) {}
            if (j >= tokens.len) break;

            const decl_tok = tokens[j];
            const kind: ?SymbolDeclKind = switch (decl_tok.kind) {
                .@"fn" => .function,
                .val => .value,
                .record => .record,
                .@"struct" => .@"struct",
                .@"enum" => .@"enum",
                .interface => .interface,
                else => null,
            };
            if (kind == null) continue;

            // Next token is the name.
            var k = j + 1;
            while (k < tokens.len and tokens[k].kind == .endOfFile) : (k += 1) {}
            if (k >= tokens.len) continue;

            const name_tok = tokens[k];
            if (name_tok.kind != .identifier) continue;

            try self.symbols.append(self.gpa, .{
                .name = try self.gpa.dupe(u8, name_tok.lexeme),
                .kind = kind.?,
                .uri = try self.gpa.dupe(u8, file_uri),
                .module_name = try self.gpa.dupe(u8, module_name),
            });

            i = k;
        }
    }
};
