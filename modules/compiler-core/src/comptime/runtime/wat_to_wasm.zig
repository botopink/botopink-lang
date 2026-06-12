//! Pure-Zig WebAssembly Text (WAT) → binary WebAssembly compiler.
//!
//! Scope: the subset emitted by `comptime/runtime/wasm.zig:buildScript` plus
//! the user-codegen WAT shape (`comptime/runtime/wasm.zig` round-trip + the
//! tiny RUN-LOG smoke programs that exit through `wasi_snapshot_preview1.fd_write`).
//!
//! Why pure-Zig instead of vendoring wabt: the subset is intentionally small
//! and mechanical (per the [WebAssembly binary spec](https://webassembly.github.io/spec/core/binary/));
//! pure-Zig keeps the toolchain at Zig+C and the binary tiny.
//!
//! Unsupported features (SIMD, GC, reference types, multi-value beyond a
//! single result, table ops, exception handling, threading, …) return
//! `error.UnsupportedWatFeature`. The set is closed by design — we control
//! both ends.
const std = @import("std");

// ── Public API ────────────────────────────────────────────────────────────────

pub const Error = error{
    UnexpectedToken,
    UnexpectedEof,
    UnterminatedString,
    BadInteger,
    BadFloat,
    UnsupportedWatFeature,
    UnknownIdentifier,
    DuplicateIdentifier,
    BadOpcode,
    BadModuleStructure,
    OutOfMemory,
};

/// Compile a WAT source buffer to a binary WebAssembly module.
/// Caller owns the returned slice (allocated from `allocator`).
pub fn compile(allocator: std.mem.Allocator, wat: []const u8) Error![]u8 {
    var tokens = try tokenize(allocator, wat);
    defer tokens.deinit(allocator);

    var parser = Parser{
        .allocator = allocator,
        .tokens = tokens.items,
        .index = 0,
    };
    var module = try parser.parseModule();
    defer module.deinit(allocator);

    return try emitBinary(allocator, &module);
}

// ── Tokenizer ─────────────────────────────────────────────────────────────────

const TokKind = enum { lparen, rparen, atom, string };

const Token = struct {
    kind: TokKind,
    /// For atoms/strings: the literal text (string is RAW, including escapes).
    text: []const u8,
};

const TokenList = std.ArrayListUnmanaged(Token);

fn tokenize(allocator: std.mem.Allocator, src: []const u8) Error!TokenList {
    var out: TokenList = .empty;
    errdefer out.deinit(allocator);

    var i: usize = 0;
    while (i < src.len) {
        const c = src[i];
        if (c == ' ' or c == '\t' or c == '\r' or c == '\n') {
            i += 1;
            continue;
        }
        // Line comment ;;
        if (c == ';' and i + 1 < src.len and src[i + 1] == ';') {
            while (i < src.len and src[i] != '\n') i += 1;
            continue;
        }
        // Block comment (; … ;) — supports nesting.
        if (c == '(' and i + 1 < src.len and src[i + 1] == ';') {
            i += 2;
            var depth: usize = 1;
            while (i < src.len and depth > 0) {
                if (src[i] == '(' and i + 1 < src.len and src[i + 1] == ';') {
                    depth += 1;
                    i += 2;
                } else if (src[i] == ';' and i + 1 < src.len and src[i + 1] == ')') {
                    depth -= 1;
                    i += 2;
                } else {
                    i += 1;
                }
            }
            continue;
        }
        if (c == '(') {
            try out.append(allocator, .{ .kind = .lparen, .text = src[i .. i + 1] });
            i += 1;
            continue;
        }
        if (c == ')') {
            try out.append(allocator, .{ .kind = .rparen, .text = src[i .. i + 1] });
            i += 1;
            continue;
        }
        if (c == '"') {
            const start = i;
            i += 1;
            while (i < src.len and src[i] != '"') {
                if (src[i] == '\\' and i + 1 < src.len) i += 2 else i += 1;
            }
            if (i >= src.len) return error.UnterminatedString;
            i += 1; // consume closing quote
            try out.append(allocator, .{ .kind = .string, .text = src[start..i] });
            continue;
        }
        // Atom: everything until whitespace or paren or string quote.
        const start = i;
        while (i < src.len) : (i += 1) {
            const ch = src[i];
            if (ch == ' ' or ch == '\t' or ch == '\r' or ch == '\n' or
                ch == '(' or ch == ')' or ch == '"') break;
        }
        try out.append(allocator, .{ .kind = .atom, .text = src[start..i] });
    }
    return out;
}

// ── AST ───────────────────────────────────────────────────────────────────────

const ValType = enum(u8) {
    i32 = 0x7F,
    i64 = 0x7E,
    f32 = 0x7D,
    f64 = 0x7C,
};

const FuncType = struct {
    params: []ValType,
    results: []ValType,
};

const Import = struct {
    module: []u8,
    name: []u8,
    type_idx: u32,
    /// Identifier ($name) for resolution. Empty means anonymous.
    id: []u8,
};

const Memory = struct {
    min: u32,
    max: ?u32,
    export_name: ?[]u8,
};

const Data = struct {
    /// Offset expression (always `i32.const N` for our subset).
    offset: u32,
    bytes: []u8,
};

const Local = struct {
    id: []u8,
    ty: ValType,
};

const Func = struct {
    id: []u8,
    type_idx: u32,
    /// Direct param names — distinct from `type_idx`-resolved param types because
    /// names map to local indices.
    params: []Local,
    locals: []Local,
    body: []const Token,
    export_name: ?[]u8,
};

const Export = struct {
    name: []u8,
    kind: enum { func, mem, table, global },
    /// Identifier ($name) or index.
    target: []u8,
};

const Global = struct {
    id: []u8,
    ty: ValType,
    mutable: bool,
    init_const: i64,
};

const Module = struct {
    types: std.ArrayListUnmanaged(FuncType),
    imports: std.ArrayListUnmanaged(Import),
    funcs: std.ArrayListUnmanaged(Func),
    memories: std.ArrayListUnmanaged(Memory),
    data: std.ArrayListUnmanaged(Data),
    exports: std.ArrayListUnmanaged(Export),
    globals: std.ArrayListUnmanaged(Global),
    func_extra_exports: std.ArrayListUnmanaged(struct { func_idx: u32, name: []u8 }),
    /// Arena holds string buffers for owned slices in the module above.
    arena: std.heap.ArenaAllocator,

    fn deinit(self: *Module, allocator: std.mem.Allocator) void {
        self.types.deinit(allocator);
        self.imports.deinit(allocator);
        self.funcs.deinit(allocator);
        self.memories.deinit(allocator);
        self.data.deinit(allocator);
        self.exports.deinit(allocator);
        self.globals.deinit(allocator);
        self.func_extra_exports.deinit(allocator);
        self.arena.deinit();
    }
};

// ── Parser ────────────────────────────────────────────────────────────────────

const Parser = struct {
    allocator: std.mem.Allocator,
    tokens: []const Token,
    index: usize,

    fn peek(self: *Parser) ?Token {
        if (self.index >= self.tokens.len) return null;
        return self.tokens[self.index];
    }

    fn eat(self: *Parser) Error!Token {
        if (self.index >= self.tokens.len) return error.UnexpectedEof;
        const t = self.tokens[self.index];
        self.index += 1;
        return t;
    }

    fn expectLparen(self: *Parser) Error!void {
        const t = try self.eat();
        if (t.kind != .lparen) return error.UnexpectedToken;
    }

    fn expectRparen(self: *Parser) Error!void {
        const t = try self.eat();
        if (t.kind != .rparen) return error.UnexpectedToken;
    }

    fn expectAtom(self: *Parser, text: []const u8) Error!void {
        const t = try self.eat();
        if (t.kind != .atom or !std.mem.eql(u8, t.text, text)) return error.UnexpectedToken;
    }

    /// Skip from current position past one balanced S-expression (assumes a
    /// `(` is at the current index, or that we're inside a list and need to
    /// consume one element).
    fn skipBalanced(self: *Parser) Error!void {
        var depth: i32 = 0;
        while (self.index < self.tokens.len) : (self.index += 1) {
            const t = self.tokens[self.index];
            if (t.kind == .lparen) depth += 1;
            if (t.kind == .rparen) {
                depth -= 1;
                if (depth <= 0) {
                    self.index += 1;
                    return;
                }
            }
            if (depth == 0 and t.kind == .atom) {
                self.index += 1;
                return;
            }
        }
        return error.UnexpectedEof;
    }

    fn parseModule(self: *Parser) Error!Module {
        var module = Module{
            .types = .empty,
            .imports = .empty,
            .funcs = .empty,
            .memories = .empty,
            .data = .empty,
            .exports = .empty,
            .globals = .empty,
            .func_extra_exports = .empty,
            .arena = std.heap.ArenaAllocator.init(self.allocator),
        };
        errdefer module.deinit(self.allocator);

        try self.expectLparen();
        try self.expectAtom("module");

        while (self.peek()) |t| {
            if (t.kind == .rparen) break;
            try self.expectLparen();
            const head = try self.eat();
            if (head.kind != .atom) return error.UnexpectedToken;

            if (std.mem.eql(u8, head.text, "import")) {
                try self.parseImport(&module);
            } else if (std.mem.eql(u8, head.text, "memory")) {
                try self.parseMemory(&module);
            } else if (std.mem.eql(u8, head.text, "data")) {
                try self.parseData(&module);
            } else if (std.mem.eql(u8, head.text, "func")) {
                try self.parseFunc(&module);
            } else if (std.mem.eql(u8, head.text, "export")) {
                try self.parseExport(&module);
            } else if (std.mem.eql(u8, head.text, "type")) {
                // Bare (type (func ...)) form — supported but rare in our subset.
                try self.parseTopLevelType(&module);
            } else if (std.mem.eql(u8, head.text, "global")) {
                try self.parseGlobal(&module);
            } else {
                // Unknown top-level form — be strict.
                return error.UnsupportedWatFeature;
            }
        }
        try self.expectRparen();
        return module;
    }

    fn dupeArena(_: *Parser, module: *Module, s: []const u8) Error![]u8 {
        return module.arena.allocator().dupe(u8, s) catch error.OutOfMemory;
    }

    fn parseImport(self: *Parser, module: *Module) Error!void {
        // (import "mod" "name" (func $id (param ...) (result ...)))
        const mod_tok = try self.eat();
        if (mod_tok.kind != .string) return error.UnexpectedToken;
        const name_tok = try self.eat();
        if (name_tok.kind != .string) return error.UnexpectedToken;

        try self.expectLparen();
        const desc_head = try self.eat();
        if (desc_head.kind != .atom or !std.mem.eql(u8, desc_head.text, "func"))
            return error.UnsupportedWatFeature;

        var id: []const u8 = "";
        if (self.peek()) |t| {
            if (t.kind == .atom and t.text.len > 0 and t.text[0] == '$') {
                id = t.text;
                _ = try self.eat();
            }
        }

        const func_type = try self.parseFuncType(module);

        try self.expectRparen(); // close (func)
        try self.expectRparen(); // close (import)

        const type_idx = try internType(module, func_type);

        try module.imports.append(self.allocator, .{
            .module = try unquote(self, module, mod_tok.text),
            .name = try unquote(self, module, name_tok.text),
            .type_idx = type_idx,
            .id = try self.dupeArena(module, id),
        });
    }

    fn parseFuncType(self: *Parser, module: *Module) Error!FuncType {
        var params: std.ArrayListUnmanaged(ValType) = .empty;
        var results: std.ArrayListUnmanaged(ValType) = .empty;
        defer params.deinit(self.allocator);
        defer results.deinit(self.allocator);

        while (self.peek()) |t| {
            if (t.kind != .lparen) break;
            // Peek the head.
            const saved = self.index;
            _ = try self.eat();
            const head = self.peek() orelse return error.UnexpectedEof;
            if (head.kind != .atom or
                (!std.mem.eql(u8, head.text, "param") and
                !std.mem.eql(u8, head.text, "result")))
            {
                self.index = saved;
                break;
            }
            _ = try self.eat();
            const is_result = std.mem.eql(u8, head.text, "result");

            // Optional $name (param only; only one type follows when named).
            if (self.peek()) |nt| {
                if (!is_result and nt.kind == .atom and nt.text.len > 0 and nt.text[0] == '$') {
                    _ = try self.eat();
                    const ty_tok = try self.eat();
                    const ty = parseValType(ty_tok.text) orelse return error.UnsupportedWatFeature;
                    try params.append(self.allocator, ty);
                    try self.expectRparen();
                    continue;
                }
            }

            while (self.peek()) |nt| {
                if (nt.kind == .rparen) break;
                if (nt.kind != .atom) return error.UnexpectedToken;
                _ = try self.eat();
                const ty = parseValType(nt.text) orelse return error.UnsupportedWatFeature;
                if (is_result) try results.append(self.allocator, ty) else try params.append(self.allocator, ty);
            }
            try self.expectRparen();
        }

        const allocator = module.arena.allocator();
        return .{
            .params = try allocator.dupe(ValType, params.items),
            .results = try allocator.dupe(ValType, results.items),
        };
    }

    fn parseTopLevelType(self: *Parser, module: *Module) Error!void {
        // (type (func ...))
        if (self.peek()) |t| {
            if (t.kind == .atom and t.text.len > 0 and t.text[0] == '$') {
                _ = try self.eat();
            }
        }
        try self.expectLparen();
        try self.expectAtom("func");
        const ft = try self.parseFuncType(module);
        try self.expectRparen();
        try self.expectRparen();
        _ = try internType(module, ft);
    }

    fn parseMemory(self: *Parser, module: *Module) Error!void {
        // (memory $? (export "memory")? <min> <max?>)
        // Or: (memory $? <min> <max?>)
        if (self.peek()) |t| {
            if (t.kind == .atom and t.text.len > 0 and t.text[0] == '$') _ = try self.eat();
        }

        var export_name: ?[]u8 = null;
        if (self.peek()) |t| {
            if (t.kind == .lparen) {
                _ = try self.eat();
                const head = try self.eat();
                if (head.kind != .atom or !std.mem.eql(u8, head.text, "export"))
                    return error.UnsupportedWatFeature;
                const name_tok = try self.eat();
                if (name_tok.kind != .string) return error.UnexpectedToken;
                export_name = try unquote(self, module, name_tok.text);
                try self.expectRparen();
            }
        }

        const min_tok = try self.eat();
        const min = std.fmt.parseInt(u32, min_tok.text, 10) catch return error.BadInteger;
        var max: ?u32 = null;
        if (self.peek()) |t| {
            if (t.kind == .atom) {
                max = std.fmt.parseInt(u32, t.text, 10) catch return error.BadInteger;
                _ = try self.eat();
            }
        }
        try self.expectRparen();

        try module.memories.append(self.allocator, .{
            .min = min,
            .max = max,
            .export_name = export_name,
        });
    }

    fn parseData(self: *Parser, module: *Module) Error!void {
        // (data (i32.const N) "...")
        try self.expectLparen();
        try self.expectAtom("i32.const");
        const off_tok = try self.eat();
        const offset = std.fmt.parseInt(u32, off_tok.text, 10) catch return error.BadInteger;
        try self.expectRparen();

        const str_tok = try self.eat();
        if (str_tok.kind != .string) return error.UnexpectedToken;
        const bytes = try unquote(self, module, str_tok.text);

        try self.expectRparen();
        try module.data.append(self.allocator, .{ .offset = offset, .bytes = bytes });
    }

    fn parseGlobal(self: *Parser, module: *Module) Error!void {
        // (global $id? (mut <ty>)? <ty>? (<const-init>))
        // or:   (global $id <ty> (<const-init>))
        // or:   (global $id (mut <ty>) (<const-init>))
        var id: []const u8 = "";
        if (self.peek()) |t| {
            if (t.kind == .atom and t.text.len > 0 and t.text[0] == '$') {
                id = t.text;
                _ = try self.eat();
            }
        }

        var ty: ValType = .i32;
        var mutable = false;
        if (self.peek()) |t| {
            if (t.kind == .lparen) {
                _ = try self.eat();
                const head = try self.eat();
                if (head.kind == .atom and std.mem.eql(u8, head.text, "mut")) {
                    mutable = true;
                    const ty_tok = try self.eat();
                    ty = parseValType(ty_tok.text) orelse return error.UnsupportedWatFeature;
                    try self.expectRparen();
                } else if (head.kind == .atom) {
                    return error.UnsupportedWatFeature;
                }
            } else if (t.kind == .atom) {
                _ = try self.eat();
                ty = parseValType(t.text) orelse return error.UnsupportedWatFeature;
            }
        }

        // (i32.const N) init expression
        try self.expectLparen();
        const init_op = try self.eat();
        var init_val: i64 = 0;
        if (init_op.kind == .atom and std.mem.eql(u8, init_op.text, "i32.const")) {
            const v_tok = try self.eat();
            init_val = std.fmt.parseInt(i64, v_tok.text, 10) catch return error.BadInteger;
        } else if (init_op.kind == .atom and std.mem.eql(u8, init_op.text, "i64.const")) {
            const v_tok = try self.eat();
            init_val = std.fmt.parseInt(i64, v_tok.text, 10) catch return error.BadInteger;
        } else {
            return error.UnsupportedWatFeature;
        }
        try self.expectRparen();
        try self.expectRparen();

        try module.globals.append(self.allocator, .{
            .id = try self.dupeArena(module, id),
            .ty = ty,
            .mutable = mutable,
            .init_const = init_val,
        });
    }

    fn parseFunc(self: *Parser, module: *Module) Error!void {
        // (func $id? (export "name")* (param ...)* (result ...)* (local ...)* body)
        var id: []const u8 = "";
        if (self.peek()) |t| {
            if (t.kind == .atom and t.text.len > 0 and t.text[0] == '$') {
                id = t.text;
                _ = try self.eat();
            }
        }

        // Multiple (export "x") forms are allowed back-to-back; only the FIRST
        // lands on `func.export_name` (which is recorded in the export section
        // via the function's index path). Additional exports go to a sidecar
        // list resolved during emitExportSection — same target index, distinct
        // names.
        var export_name: ?[]u8 = null;
        var extra_exports: std.ArrayListUnmanaged([]u8) = .empty;
        defer extra_exports.deinit(self.allocator);
        while (self.peek()) |t| {
            if (t.kind != .lparen) break;
            const saved = self.index;
            _ = try self.eat();
            const head = self.peek() orelse return error.UnexpectedEof;
            if (head.kind == .atom and std.mem.eql(u8, head.text, "export")) {
                _ = try self.eat();
                const name_tok = try self.eat();
                if (name_tok.kind != .string) return error.UnexpectedToken;
                const name_owned = try unquote(self, module, name_tok.text);
                try self.expectRparen();
                if (export_name == null) {
                    export_name = name_owned;
                } else {
                    try extra_exports.append(self.allocator, name_owned);
                }
            } else {
                self.index = saved;
                break;
            }
        }

        // Parse params/results inline, attaching names to locals.
        var params: std.ArrayListUnmanaged(Local) = .empty;
        defer params.deinit(self.allocator);
        var results: std.ArrayListUnmanaged(ValType) = .empty;
        defer results.deinit(self.allocator);

        while (self.peek()) |t| {
            if (t.kind != .lparen) break;
            const saved = self.index;
            _ = try self.eat();
            const head = self.peek() orelse return error.UnexpectedEof;
            if (head.kind != .atom) {
                self.index = saved;
                break;
            }
            if (std.mem.eql(u8, head.text, "param")) {
                _ = try self.eat();
                if (self.peek()) |nt| {
                    if (nt.kind == .atom and nt.text.len > 0 and nt.text[0] == '$') {
                        _ = try self.eat();
                        const ty_tok = try self.eat();
                        const ty = parseValType(ty_tok.text) orelse return error.UnsupportedWatFeature;
                        try params.append(self.allocator, .{
                            .id = try self.dupeArena(module, nt.text),
                            .ty = ty,
                        });
                        try self.expectRparen();
                        continue;
                    }
                }
                while (self.peek()) |nt| {
                    if (nt.kind == .rparen) break;
                    if (nt.kind != .atom) return error.UnexpectedToken;
                    _ = try self.eat();
                    const ty = parseValType(nt.text) orelse return error.UnsupportedWatFeature;
                    try params.append(self.allocator, .{ .id = "", .ty = ty });
                }
                try self.expectRparen();
            } else if (std.mem.eql(u8, head.text, "result")) {
                _ = try self.eat();
                while (self.peek()) |nt| {
                    if (nt.kind == .rparen) break;
                    if (nt.kind != .atom) return error.UnexpectedToken;
                    _ = try self.eat();
                    const ty = parseValType(nt.text) orelse return error.UnsupportedWatFeature;
                    try results.append(self.allocator, ty);
                }
                try self.expectRparen();
            } else {
                self.index = saved;
                break;
            }
        }

        // Locals
        var locals: std.ArrayListUnmanaged(Local) = .empty;
        defer locals.deinit(self.allocator);
        while (self.peek()) |t| {
            if (t.kind != .lparen) break;
            const saved = self.index;
            _ = try self.eat();
            const head = self.peek() orelse return error.UnexpectedEof;
            if (head.kind == .atom and std.mem.eql(u8, head.text, "local")) {
                _ = try self.eat();
                if (self.peek()) |nt| {
                    if (nt.kind == .atom and nt.text.len > 0 and nt.text[0] == '$') {
                        _ = try self.eat();
                        const ty_tok = try self.eat();
                        const ty = parseValType(ty_tok.text) orelse return error.UnsupportedWatFeature;
                        try locals.append(self.allocator, .{
                            .id = try self.dupeArena(module, nt.text),
                            .ty = ty,
                        });
                        try self.expectRparen();
                        continue;
                    }
                }
                while (self.peek()) |nt| {
                    if (nt.kind == .rparen) break;
                    if (nt.kind != .atom) return error.UnexpectedToken;
                    _ = try self.eat();
                    const ty = parseValType(nt.text) orelse return error.UnsupportedWatFeature;
                    try locals.append(self.allocator, .{ .id = "", .ty = ty });
                }
                try self.expectRparen();
            } else {
                self.index = saved;
                break;
            }
        }

        const allocator = module.arena.allocator();
        const param_locals_owned = try allocator.dupe(Local, params.items);
        const locals_owned = try allocator.dupe(Local, locals.items);

        const params_ty = try allocator.alloc(ValType, params.items.len);
        for (params.items, 0..) |p, i| params_ty[i] = p.ty;
        const results_owned = try allocator.dupe(ValType, results.items);
        const type_idx = try internType(module, .{
            .params = params_ty,
            .results = results_owned,
        });

        // Capture body tokens up to the closing rparen of (func).
        const body_start = self.index;
        var depth: i32 = 1;
        while (self.index < self.tokens.len and depth > 0) : (self.index += 1) {
            const t = self.tokens[self.index];
            if (t.kind == .lparen) depth += 1;
            if (t.kind == .rparen) depth -= 1;
            if (depth == 0) break;
        }
        const body_end = self.index;
        const body = try allocator.dupe(Token, self.tokens[body_start..body_end]);
        try self.expectRparen();

        const this_func_idx_in_funcs: u32 = @intCast(module.funcs.items.len);
        try module.funcs.append(self.allocator, .{
            .id = try self.dupeArena(module, id),
            .type_idx = type_idx,
            .params = param_locals_owned,
            .locals = locals_owned,
            .body = body,
            .export_name = export_name,
        });

        // Park any extra `(export "x")` siblings — their func-index needs to
        // include the import-func offset, which is finalized at emit time.
        // Tracking the in-funcs-list index now means we don't have to walk the
        // funcs list at emit time.
        for (extra_exports.items) |n| {
            try module.func_extra_exports.append(self.allocator, .{
                .func_idx = this_func_idx_in_funcs,
                .name = n,
            });
        }
    }

    fn parseExport(self: *Parser, module: *Module) Error!void {
        // (export "name" (func $id))
        const name_tok = try self.eat();
        if (name_tok.kind != .string) return error.UnexpectedToken;
        try self.expectLparen();
        const kind_tok = try self.eat();
        if (kind_tok.kind != .atom) return error.UnexpectedToken;
        const id_tok = try self.eat();
        if (id_tok.kind != .atom) return error.UnexpectedToken;
        try self.expectRparen();
        try self.expectRparen();

        const kind: @TypeOf((Export{ .name = "", .kind = .func, .target = "" }).kind) =
            if (std.mem.eql(u8, kind_tok.text, "func")) .func else if (std.mem.eql(u8, kind_tok.text, "memory"))
            .mem
        else if (std.mem.eql(u8, kind_tok.text, "table"))
            .table
        else if (std.mem.eql(u8, kind_tok.text, "global"))
            .global
        else
            return error.UnsupportedWatFeature;

        try module.exports.append(self.allocator, .{
            .name = try unquote(self, module, name_tok.text),
            .kind = kind,
            .target = try self.dupeArena(module, id_tok.text),
        });
    }
};

fn parseValType(s: []const u8) ?ValType {
    if (std.mem.eql(u8, s, "i32")) return .i32;
    if (std.mem.eql(u8, s, "i64")) return .i64;
    if (std.mem.eql(u8, s, "f32")) return .f32;
    if (std.mem.eql(u8, s, "f64")) return .f64;
    return null;
}

fn internType(module: *Module, ft: FuncType) Error!u32 {
    for (module.types.items, 0..) |existing, idx| {
        if (existing.params.len != ft.params.len) continue;
        if (existing.results.len != ft.results.len) continue;
        var ok = true;
        for (existing.params, ft.params) |a, b| if (a != b) {
            ok = false;
            break;
        };
        if (!ok) continue;
        for (existing.results, ft.results) |a, b| if (a != b) {
            ok = false;
            break;
        };
        if (!ok) continue;
        return @intCast(idx);
    }
    try module.types.append(module.arena.child_allocator, ft);
    return @intCast(module.types.items.len - 1);
}

/// Decode a WAT-quoted string. WAT strings use the same escape syntax as the
/// spec: `\<hex><hex>`, `\n`, `\t`, `\r`, `\\`, `\"`, `\'`.
fn unquote(parser: *Parser, module: *Module, raw: []const u8) Error![]u8 {
    _ = parser;
    if (raw.len < 2 or raw[0] != '"' or raw[raw.len - 1] != '"')
        return error.UnexpectedToken;
    const inner = raw[1 .. raw.len - 1];
    var out: std.ArrayListUnmanaged(u8) = .empty;
    defer out.deinit(module.arena.child_allocator);

    var i: usize = 0;
    while (i < inner.len) {
        const c = inner[i];
        if (c != '\\') {
            try out.append(module.arena.child_allocator, c);
            i += 1;
            continue;
        }
        if (i + 1 >= inner.len) return error.UnterminatedString;
        const esc = inner[i + 1];
        switch (esc) {
            'n' => {
                try out.append(module.arena.child_allocator, '\n');
                i += 2;
            },
            't' => {
                try out.append(module.arena.child_allocator, '\t');
                i += 2;
            },
            'r' => {
                try out.append(module.arena.child_allocator, '\r');
                i += 2;
            },
            '\\' => {
                try out.append(module.arena.child_allocator, '\\');
                i += 2;
            },
            '"' => {
                try out.append(module.arena.child_allocator, '"');
                i += 2;
            },
            '\'' => {
                try out.append(module.arena.child_allocator, '\'');
                i += 2;
            },
            else => {
                if (i + 2 >= inner.len) return error.UnterminatedString;
                const hi = hexDigit(esc) orelse return error.UnterminatedString;
                const lo = hexDigit(inner[i + 2]) orelse return error.UnterminatedString;
                try out.append(module.arena.child_allocator, @intCast(hi * 16 + lo));
                i += 3;
            },
        }
    }
    return try module.arena.allocator().dupe(u8, out.items);
}

fn hexDigit(c: u8) ?u8 {
    return switch (c) {
        '0'...'9' => c - '0',
        'a'...'f' => c - 'a' + 10,
        'A'...'F' => c - 'A' + 10,
        else => null,
    };
}

// ── Binary emitter ────────────────────────────────────────────────────────────

/// Emit the final binary `.wasm` module. Caller owns the returned slice.
fn emitBinary(allocator: std.mem.Allocator, module: *Module) Error![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    defer buf.deinit(allocator);

    // Magic + version
    try buf.appendSlice(allocator, &.{ 0x00, 0x61, 0x73, 0x6D, 0x01, 0x00, 0x00, 0x00 });

    try emitTypeSection(allocator, module, &buf);
    try emitImportSection(allocator, module, &buf);
    try emitFunctionSection(allocator, module, &buf);
    try emitMemorySection(allocator, module, &buf);
    try emitGlobalSection(allocator, module, &buf);
    try emitExportSection(allocator, module, &buf);
    try emitCodeSection(allocator, module, &buf);
    try emitDataSection(allocator, module, &buf);

    return try buf.toOwnedSlice(allocator);
}

fn writeSection(allocator: std.mem.Allocator, dst: *std.ArrayListUnmanaged(u8), id: u8, payload: []const u8) Error!void {
    try dst.append(allocator, id);
    try writeULEB128(allocator, dst, payload.len);
    try dst.appendSlice(allocator, payload);
}

fn emitTypeSection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    if (module.types.items.len == 0) return;
    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, module.types.items.len);
    for (module.types.items) |ft| {
        try payload.append(allocator, 0x60); // functype marker
        try writeULEB128(allocator, &payload, ft.params.len);
        for (ft.params) |p| try payload.append(allocator, @intFromEnum(p));
        try writeULEB128(allocator, &payload, ft.results.len);
        for (ft.results) |r| try payload.append(allocator, @intFromEnum(r));
    }
    try writeSection(allocator, out, 0x01, payload.items);
}

fn emitImportSection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    if (module.imports.items.len == 0) return;
    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, module.imports.items.len);
    for (module.imports.items) |im| {
        try writeULEB128(allocator, &payload, im.module.len);
        try payload.appendSlice(allocator, im.module);
        try writeULEB128(allocator, &payload, im.name.len);
        try payload.appendSlice(allocator, im.name);
        try payload.append(allocator, 0x00); // import kind = func
        try writeULEB128(allocator, &payload, im.type_idx);
    }
    try writeSection(allocator, out, 0x02, payload.items);
}

fn emitFunctionSection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    if (module.funcs.items.len == 0) return;
    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, module.funcs.items.len);
    for (module.funcs.items) |f| {
        try writeULEB128(allocator, &payload, f.type_idx);
    }
    try writeSection(allocator, out, 0x03, payload.items);
}

fn emitGlobalSection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    if (module.globals.items.len == 0) return;
    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, module.globals.items.len);
    for (module.globals.items) |g| {
        try payload.append(allocator, @intFromEnum(g.ty));
        try payload.append(allocator, if (g.mutable) @as(u8, 0x01) else 0x00);
        // Init expr: <const opcode> <SLEB128 value> <end>
        const const_op: u8 = switch (g.ty) {
            .i32 => 0x41,
            .i64 => 0x42,
            else => return error.UnsupportedWatFeature,
        };
        try payload.append(allocator, const_op);
        try writeSLEB128(allocator, &payload, g.init_const);
        try payload.append(allocator, 0x0B);
    }
    try writeSection(allocator, out, 0x06, payload.items);
}

fn emitMemorySection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    if (module.memories.items.len == 0) return;
    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, module.memories.items.len);
    for (module.memories.items) |m| {
        if (m.max) |mx| {
            try payload.append(allocator, 0x01);
            try writeULEB128(allocator, &payload, m.min);
            try writeULEB128(allocator, &payload, mx);
        } else {
            try payload.append(allocator, 0x00);
            try writeULEB128(allocator, &payload, m.min);
        }
    }
    try writeSection(allocator, out, 0x05, payload.items);
}

fn emitExportSection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    // Combine explicit exports + inline (export "x") on memory/func.
    var exports: std.ArrayListUnmanaged(struct { name: []const u8, kind: u8, idx: u32 }) = .empty;
    defer exports.deinit(allocator);

    // Memory inline exports — memory indices come BEFORE explicit (export).
    for (module.memories.items, 0..) |m, idx| {
        if (m.export_name) |n| {
            try exports.append(allocator, .{ .name = n, .kind = 0x02, .idx = @intCast(idx) });
        }
    }

    // Function inline exports — func indices include imported funcs.
    const import_func_count: u32 = @intCast(module.imports.items.len);
    for (module.funcs.items, 0..) |f, i| {
        if (f.export_name) |n| {
            try exports.append(allocator, .{
                .name = n,
                .kind = 0x00,
                .idx = import_func_count + @as(u32, @intCast(i)),
            });
        }
    }

    // Sibling inline `(export "x")` forms (a single (func …) may carry several).
    for (module.func_extra_exports.items) |e| {
        try exports.append(allocator, .{
            .name = e.name,
            .kind = 0x00,
            .idx = import_func_count + e.func_idx,
        });
    }

    // Explicit (export "x" (func $id)) forms.
    for (module.exports.items) |e| {
        switch (e.kind) {
            .func => {
                const idx = try resolveFuncIndex(module, e.target);
                try exports.append(allocator, .{ .name = e.name, .kind = 0x00, .idx = idx });
            },
            .mem => {
                const idx = try resolveMemIndex(module, e.target);
                try exports.append(allocator, .{ .name = e.name, .kind = 0x02, .idx = idx });
            },
            else => return error.UnsupportedWatFeature,
        }
    }

    if (exports.items.len == 0) return;

    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, exports.items.len);
    for (exports.items) |e| {
        try writeULEB128(allocator, &payload, e.name.len);
        try payload.appendSlice(allocator, e.name);
        try payload.append(allocator, e.kind);
        try writeULEB128(allocator, &payload, e.idx);
    }
    try writeSection(allocator, out, 0x07, payload.items);
}

fn emitCodeSection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    if (module.funcs.items.len == 0) return;

    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, module.funcs.items.len);
    for (module.funcs.items) |f| {
        var body: std.ArrayListUnmanaged(u8) = .empty;
        defer body.deinit(allocator);

        // Locals: group runs of same type.
        var groups: std.ArrayListUnmanaged(struct { count: u32, ty: ValType }) = .empty;
        defer groups.deinit(allocator);
        for (f.locals) |l| {
            if (groups.items.len > 0 and groups.items[groups.items.len - 1].ty == l.ty) {
                groups.items[groups.items.len - 1].count += 1;
            } else {
                try groups.append(allocator, .{ .count = 1, .ty = l.ty });
            }
        }
        try writeULEB128(allocator, &body, groups.items.len);
        for (groups.items) |g| {
            try writeULEB128(allocator, &body, g.count);
            try body.append(allocator, @intFromEnum(g.ty));
        }

        try compileFuncBody(allocator, module, &f, &body);
        try body.append(allocator, 0x0B); // end

        try writeULEB128(allocator, &payload, body.items.len);
        try payload.appendSlice(allocator, body.items);
    }
    try writeSection(allocator, out, 0x0A, payload.items);
}

fn emitDataSection(allocator: std.mem.Allocator, module: *Module, out: *std.ArrayListUnmanaged(u8)) Error!void {
    if (module.data.items.len == 0) return;
    var payload: std.ArrayListUnmanaged(u8) = .empty;
    defer payload.deinit(allocator);
    try writeULEB128(allocator, &payload, module.data.items.len);
    for (module.data.items) |d| {
        try payload.append(allocator, 0x00); // active, memory 0
        try payload.append(allocator, 0x41); // i32.const
        try writeSLEB128(allocator, &payload, @intCast(d.offset));
        try payload.append(allocator, 0x0B); // end of init expr
        try writeULEB128(allocator, &payload, d.bytes.len);
        try payload.appendSlice(allocator, d.bytes);
    }
    try writeSection(allocator, out, 0x0B, payload.items);
}

fn resolveFuncIndex(module: *Module, id_or_idx: []const u8) Error!u32 {
    if (id_or_idx.len == 0) return error.UnknownIdentifier;
    if (id_or_idx[0] != '$') {
        return std.fmt.parseInt(u32, id_or_idx, 10) catch error.UnknownIdentifier;
    }
    var idx: u32 = 0;
    for (module.imports.items) |im| {
        if (std.mem.eql(u8, im.id, id_or_idx)) return idx;
        idx += 1;
    }
    for (module.funcs.items) |f| {
        if (std.mem.eql(u8, f.id, id_or_idx)) return idx;
        idx += 1;
    }
    return error.UnknownIdentifier;
}

fn resolveMemIndex(_: *Module, id_or_idx: []const u8) Error!u32 {
    if (id_or_idx.len == 0) return 0;
    if (id_or_idx[0] != '$') {
        return std.fmt.parseInt(u32, id_or_idx, 10) catch error.UnknownIdentifier;
    }
    return 0; // Only one memory in our subset.
}

// ── Function-body compiler ────────────────────────────────────────────────────

const Compiler = struct {
    allocator: std.mem.Allocator,
    module: *Module,
    func: *const Func,
    body: []const Token,
    index: usize,
    out: *std.ArrayListUnmanaged(u8),
    /// Label stack — innermost (most-recently-pushed) at the end. `br $name` /
    /// `br_if $name` walk this from the back to compute the relative
    /// labelidx. `(func …)` doesn't push a label of its own — the function
    /// body is not br-targetable by name.
    labels: std.ArrayListUnmanaged([]const u8) = .empty,

    fn peek(self: *Compiler) ?Token {
        if (self.index >= self.body.len) return null;
        return self.body[self.index];
    }

    fn eat(self: *Compiler) Error!Token {
        if (self.index >= self.body.len) return error.UnexpectedEof;
        const t = self.body[self.index];
        self.index += 1;
        return t;
    }

    fn expect(self: *Compiler, kind: TokKind) Error!Token {
        const t = try self.eat();
        if (t.kind != kind) return error.UnexpectedToken;
        return t;
    }

    /// Compile a sequence of operations until we hit `rparen` at the current
    /// depth (in folded mode) or the natural end (in flat mode). Many opcodes
    /// allow either: `(i32.add (i32.const 1) (i32.const 2))` or
    /// `i32.const 1 i32.const 2 i32.add`.
    fn compileSeq(self: *Compiler) Error!void {
        while (self.peek()) |t| {
            if (t.kind == .rparen) return;
            try self.compileOne();
        }
    }

    fn compileOne(self: *Compiler) Error!void {
        const t = try self.eat();
        switch (t.kind) {
            .lparen => try self.compileFolded(),
            .atom => try self.compileFlat(t.text),
            else => return error.UnexpectedToken,
        }
    }

    /// Folded form: we already consumed `(`. Read the opcode atom, then the
    /// body, then close.
    fn compileFolded(self: *Compiler) Error!void {
        const op = try self.expect(.atom);
        // block/loop/if take an optional $label + optional blocktype, then a
        // body that runs until the closing rparen (instead of a fixed operand
        // count like a plain binop).
        if (std.mem.eql(u8, op.text, "block")) {
            try self.compileBlockOrLoop(0x02);
            _ = try self.expect(.rparen);
            return;
        }
        if (std.mem.eql(u8, op.text, "loop")) {
            try self.compileBlockOrLoop(0x03);
            _ = try self.expect(.rparen);
            return;
        }
        if (std.mem.eql(u8, op.text, "if")) {
            try self.compileIf();
            _ = try self.expect(.rparen);
            return;
        }

        try self.compileOpcode(op.text, true);
        _ = try self.expect(.rparen);
    }

    fn parseOptionalLabel(self: *Compiler) Error![]const u8 {
        if (self.peek()) |t| {
            if (t.kind == .atom and t.text.len > 0 and t.text[0] == '$') {
                _ = try self.eat();
                return t.text;
            }
        }
        return "";
    }

    /// Consume an optional `(result T)` blocktype. Bigger forms (param +
    /// result; multi-result type-idx) are intentionally not supported — every
    /// `codegen/wat.zig`-emitted block falls into "no result" or "single
    /// result".
    fn parseBlockType(self: *Compiler) Error!u8 {
        if (self.peek()) |t| {
            if (t.kind != .lparen) return 0x40; // empty type
            const saved = self.index;
            _ = try self.eat();
            const head = self.peek() orelse return error.UnexpectedEof;
            if (head.kind == .atom and std.mem.eql(u8, head.text, "result")) {
                _ = try self.eat();
                const ty_tok = try self.eat();
                const ty = parseValType(ty_tok.text) orelse return error.UnsupportedWatFeature;
                _ = try self.expect(.rparen);
                return @intFromEnum(ty);
            }
            self.index = saved;
        }
        return 0x40; // empty type
    }

    fn compileBlockOrLoop(self: *Compiler, opcode: u8) Error!void {
        const label = try self.parseOptionalLabel();
        const blocktype = try self.parseBlockType();
        try self.out.append(self.allocator, opcode);
        try self.out.append(self.allocator, blocktype);

        try self.labels.append(self.allocator, label);
        defer _ = self.labels.pop();

        while (self.peek()) |t| {
            if (t.kind == .rparen) break;
            try self.compileOne();
        }
        try self.out.append(self.allocator, 0x0B); // end
    }

    fn compileIf(self: *Compiler) Error!void {
        const label = try self.parseOptionalLabel();
        const blocktype = try self.parseBlockType();
        // Folded `if` accepts either:
        //   (if BT (cond) (then …) (else …)?)   ; condition inside the form
        //   (if BT (then …) (else …)?)          ; condition was left on the
        //                                       ; stack by prior instructions
        // We peek the next nested form: if it's `(then …)` we're in the
        // second shape and don't consume a condition; otherwise we treat the
        // first nested form as the condition.
        if (self.peek()) |t| {
            if (t.kind == .lparen and !nextHeadIs(self, "then") and !nextHeadIs(self, "else")) {
                try self.compileOne();
            }
        }
        try self.out.append(self.allocator, 0x04);
        try self.out.append(self.allocator, blocktype);

        try self.labels.append(self.allocator, label);
        defer _ = self.labels.pop();

        // Read (then …)
        if (self.peek()) |t| {
            if (t.kind == .lparen) {
                const saved = self.index;
                _ = try self.eat();
                const head = self.peek() orelse return error.UnexpectedEof;
                if (head.kind == .atom and std.mem.eql(u8, head.text, "then")) {
                    _ = try self.eat();
                    while (self.peek()) |inner| {
                        if (inner.kind == .rparen) break;
                        try self.compileOne();
                    }
                    _ = try self.expect(.rparen);
                } else {
                    self.index = saved;
                }
            }
        }
        // Optional (else …)
        if (self.peek()) |t| {
            if (t.kind == .lparen) {
                const saved = self.index;
                _ = try self.eat();
                const head = self.peek() orelse return error.UnexpectedEof;
                if (head.kind == .atom and std.mem.eql(u8, head.text, "else")) {
                    _ = try self.eat();
                    try self.out.append(self.allocator, 0x05); // else marker
                    while (self.peek()) |inner| {
                        if (inner.kind == .rparen) break;
                        try self.compileOne();
                    }
                    _ = try self.expect(.rparen);
                } else {
                    self.index = saved;
                }
            }
        }
        try self.out.append(self.allocator, 0x0B); // end
    }

    fn nextHeadIs(self: *Compiler, name: []const u8) bool {
        if (self.index + 1 >= self.body.len) return false;
        const a = self.body[self.index];
        const b = self.body[self.index + 1];
        if (a.kind != .lparen) return false;
        if (b.kind != .atom) return false;
        return std.mem.eql(u8, b.text, name);
    }

    fn resolveLabel(self: *Compiler, id: []const u8) Error!u32 {
        if (id.len > 0 and id[0] != '$') {
            return std.fmt.parseInt(u32, id, 10) catch error.UnknownIdentifier;
        }
        // Innermost label is the last pushed; relative index 0 = innermost.
        var i = self.labels.items.len;
        var depth: u32 = 0;
        while (i > 0) {
            i -= 1;
            if (std.mem.eql(u8, self.labels.items[i], id)) return depth;
            depth += 1;
        }
        return error.UnknownIdentifier;
    }

    fn compileFlat(self: *Compiler, op: []const u8) Error!void {
        try self.compileOpcode(op, false);
    }

    /// Emit the binary encoding for `op`, reading immediates and (in folded
    /// mode) operands as appropriate.
    fn compileOpcode(self: *Compiler, op: []const u8, folded: bool) Error!void {
        // Constants ───────────────────────────────────────────────────────────
        if (std.mem.eql(u8, op, "i32.const")) {
            const v_tok = try self.expect(.atom);
            const v = std.fmt.parseInt(i32, v_tok.text, 10) catch return error.BadInteger;
            try self.out.append(self.allocator, 0x41);
            try writeSLEB128(self.allocator, self.out, @intCast(v));
            return;
        }
        if (std.mem.eql(u8, op, "i64.const")) {
            const v_tok = try self.expect(.atom);
            const v = std.fmt.parseInt(i64, v_tok.text, 10) catch return error.BadInteger;
            try self.out.append(self.allocator, 0x42);
            try writeSLEB128(self.allocator, self.out, v);
            return;
        }
        if (std.mem.eql(u8, op, "f32.const")) {
            const v_tok = try self.expect(.atom);
            const v = std.fmt.parseFloat(f32, v_tok.text) catch return error.BadFloat;
            try self.out.append(self.allocator, 0x43);
            const bits: u32 = @bitCast(v);
            try self.out.appendSlice(self.allocator, std.mem.asBytes(&bits));
            return;
        }
        if (std.mem.eql(u8, op, "f64.const")) {
            const v_tok = try self.expect(.atom);
            const v = std.fmt.parseFloat(f64, v_tok.text) catch return error.BadFloat;
            try self.out.append(self.allocator, 0x44);
            const bits: u64 = @bitCast(v);
            try self.out.appendSlice(self.allocator, std.mem.asBytes(&bits));
            return;
        }

        // Variable refs ───────────────────────────────────────────────────────
        if (std.mem.eql(u8, op, "local.get") or std.mem.eql(u8, op, "local.set") or std.mem.eql(u8, op, "local.tee")) {
            const id_tok = try self.expect(.atom);
            const idx = try self.resolveLocal(id_tok.text);
            const opcode: u8 = if (std.mem.eql(u8, op, "local.get")) 0x20 else if (std.mem.eql(u8, op, "local.set")) 0x21 else 0x22;
            try self.out.append(self.allocator, opcode);
            try writeULEB128(self.allocator, self.out, idx);
            return;
        }
        if (std.mem.eql(u8, op, "global.get") or std.mem.eql(u8, op, "global.set")) {
            const id_tok = try self.expect(.atom);
            const idx = try self.resolveGlobal(id_tok.text);
            const opcode: u8 = if (std.mem.eql(u8, op, "global.get")) 0x23 else 0x24;
            try self.out.append(self.allocator, opcode);
            try writeULEB128(self.allocator, self.out, idx);
            return;
        }

        // Memory load/store ──────────────────────────────────────────────────
        const mem_op = lookupMemOp(op);
        if (mem_op) |mop| {
            // Optional immediates: offset=N, align=N
            var align_log2: u32 = mop.natural_align;
            var offset: u32 = 0;
            while (self.peek()) |nt| {
                if (nt.kind != .atom) break;
                if (std.mem.startsWith(u8, nt.text, "offset=")) {
                    offset = std.fmt.parseInt(u32, nt.text["offset=".len..], 10) catch return error.BadInteger;
                    _ = try self.eat();
                } else if (std.mem.startsWith(u8, nt.text, "align=")) {
                    const a = std.fmt.parseInt(u32, nt.text["align=".len..], 10) catch return error.BadInteger;
                    align_log2 = std.math.log2_int(u32, a);
                    _ = try self.eat();
                } else break;
            }
            if (folded) try self.compileNestedOperands(mop.operand_count);
            try self.out.append(self.allocator, mop.opcode);
            try writeULEB128(self.allocator, self.out, align_log2);
            try writeULEB128(self.allocator, self.out, offset);
            return;
        }

        // Misc bytecode-prefixed ops ─────────────────────────────────────────
        if (std.mem.eql(u8, op, "memory.copy")) {
            if (folded) try self.compileNestedOperands(3);
            try self.out.append(self.allocator, 0xFC);
            try writeULEB128(self.allocator, self.out, 10);
            try self.out.append(self.allocator, 0x00);
            try self.out.append(self.allocator, 0x00);
            return;
        }
        if (std.mem.eql(u8, op, "memory.fill")) {
            if (folded) try self.compileNestedOperands(3);
            try self.out.append(self.allocator, 0xFC);
            try writeULEB128(self.allocator, self.out, 11);
            try self.out.append(self.allocator, 0x00);
            return;
        }

        // Numeric binops / unops ─────────────────────────────────────────────
        if (lookupSimpleOp(op)) |simple| {
            if (folded) try self.compileNestedOperands(simple.operand_count);
            try self.out.append(self.allocator, simple.opcode);
            return;
        }

        // call ───────────────────────────────────────────────────────────────
        if (std.mem.eql(u8, op, "call")) {
            const id_tok = try self.expect(.atom);
            const idx = try resolveFuncIndex(self.module, id_tok.text);
            if (folded) {
                // Compile remaining nested operands.
                while (self.peek()) |nt| {
                    if (nt.kind == .rparen) break;
                    try self.compileOne();
                }
            }
            try self.out.append(self.allocator, 0x10);
            try writeULEB128(self.allocator, self.out, idx);
            return;
        }

        // drop ───────────────────────────────────────────────────────────────
        if (std.mem.eql(u8, op, "drop")) {
            if (folded) try self.compileNestedOperands(1);
            try self.out.append(self.allocator, 0x1A);
            return;
        }
        if (std.mem.eql(u8, op, "return")) {
            if (folded) {
                while (self.peek()) |nt| {
                    if (nt.kind == .rparen) break;
                    try self.compileOne();
                }
            }
            try self.out.append(self.allocator, 0x0F);
            return;
        }
        if (std.mem.eql(u8, op, "nop")) {
            try self.out.append(self.allocator, 0x01);
            return;
        }
        if (std.mem.eql(u8, op, "unreachable")) {
            try self.out.append(self.allocator, 0x00);
            return;
        }

        // Control-flow branches ──────────────────────────────────────────────
        if (std.mem.eql(u8, op, "br") or std.mem.eql(u8, op, "br_if")) {
            const id_tok = try self.expect(.atom);
            const idx = try self.resolveLabel(id_tok.text);
            const opcode: u8 = if (std.mem.eql(u8, op, "br")) 0x0C else 0x0D;
            try self.out.append(self.allocator, opcode);
            try writeULEB128(self.allocator, self.out, idx);
            return;
        }

        // Flat-form block / loop / if openers: consume optional $label +
        // (result T), push a label, and recurse over the body until the
        // matching `end` (handled by `compileOpcode("end", _)` below).
        if (std.mem.eql(u8, op, "block")) {
            try self.compileBlockOrLoopFlat(0x02);
            return;
        }
        if (std.mem.eql(u8, op, "loop")) {
            try self.compileBlockOrLoopFlat(0x03);
            return;
        }
        if (std.mem.eql(u8, op, "if")) {
            try self.compileBlockOrLoopFlat(0x04);
            return;
        }
        if (std.mem.eql(u8, op, "else")) {
            try self.out.append(self.allocator, 0x05);
            return;
        }
        if (std.mem.eql(u8, op, "end")) {
            try self.out.append(self.allocator, 0x0B);
            _ = self.labels.pop();
            return;
        }

        return error.BadOpcode;
    }

    fn compileBlockOrLoopFlat(self: *Compiler, opcode: u8) Error!void {
        const label = try self.parseOptionalLabel();
        const blocktype = try self.parseBlockType();
        try self.out.append(self.allocator, opcode);
        try self.out.append(self.allocator, blocktype);
        try self.labels.append(self.allocator, label);
        // The matching `end` token (later in the stream) is what pops `labels`
        // and emits 0x0B — see the "end" arm above.
    }

    fn compileNestedOperands(self: *Compiler, count: usize) Error!void {
        var i: usize = 0;
        while (i < count) : (i += 1) {
            if (self.peek()) |t| {
                if (t.kind == .rparen) return;
                try self.compileOne();
            } else return;
        }
    }

    fn resolveLocal(self: *Compiler, id: []const u8) Error!u32 {
        if (id.len > 0 and id[0] != '$') {
            return std.fmt.parseInt(u32, id, 10) catch error.UnknownIdentifier;
        }
        var idx: u32 = 0;
        for (self.func.params) |p| {
            if (std.mem.eql(u8, p.id, id)) return idx;
            idx += 1;
        }
        for (self.func.locals) |l| {
            if (std.mem.eql(u8, l.id, id)) return idx;
            idx += 1;
        }
        return error.UnknownIdentifier;
    }

    fn resolveGlobal(self: *Compiler, id: []const u8) Error!u32 {
        if (id.len > 0 and id[0] != '$') {
            return std.fmt.parseInt(u32, id, 10) catch error.UnknownIdentifier;
        }
        for (self.module.globals.items, 0..) |g, i| {
            if (std.mem.eql(u8, g.id, id)) return @intCast(i);
        }
        return error.UnknownIdentifier;
    }
};

const MemOp = struct {
    opcode: u8,
    natural_align: u32,
    /// Operands consumed in folded form before emitting the opcode (load=1,
    /// store=2).
    operand_count: usize,
};

/// Opcode → MemOp table — `StaticStringMap` builds a comptime perfect-hash so
/// lookup is O(1) (vs the previous linear `std.mem.eql` scan over ~14 entries).
/// `compileOpcode` calls this once per memory-op token in every WAT module the
/// comptime evaluator handles, plus once per token in user-codegen WAT, so the
/// dispatch ran into the seven-figure call-count range across a full test cycle.
const mem_ops = std.StaticStringMap(MemOp).initComptime(.{
    .{ "i32.load", MemOp{ .opcode = 0x28, .natural_align = 2, .operand_count = 1 } },
    .{ "i64.load", MemOp{ .opcode = 0x29, .natural_align = 3, .operand_count = 1 } },
    .{ "f32.load", MemOp{ .opcode = 0x2A, .natural_align = 2, .operand_count = 1 } },
    .{ "f64.load", MemOp{ .opcode = 0x2B, .natural_align = 3, .operand_count = 1 } },
    .{ "i32.load8_s", MemOp{ .opcode = 0x2C, .natural_align = 0, .operand_count = 1 } },
    .{ "i32.load8_u", MemOp{ .opcode = 0x2D, .natural_align = 0, .operand_count = 1 } },
    .{ "i32.load16_s", MemOp{ .opcode = 0x2E, .natural_align = 1, .operand_count = 1 } },
    .{ "i32.load16_u", MemOp{ .opcode = 0x2F, .natural_align = 1, .operand_count = 1 } },
    .{ "i32.store", MemOp{ .opcode = 0x36, .natural_align = 2, .operand_count = 2 } },
    .{ "i64.store", MemOp{ .opcode = 0x37, .natural_align = 3, .operand_count = 2 } },
    .{ "f32.store", MemOp{ .opcode = 0x38, .natural_align = 2, .operand_count = 2 } },
    .{ "f64.store", MemOp{ .opcode = 0x39, .natural_align = 3, .operand_count = 2 } },
    .{ "i32.store8", MemOp{ .opcode = 0x3A, .natural_align = 0, .operand_count = 2 } },
    .{ "i32.store16", MemOp{ .opcode = 0x3B, .natural_align = 1, .operand_count = 2 } },
});

fn lookupMemOp(op: []const u8) ?MemOp {
    return mem_ops.get(op);
}

const SimpleOp = struct {
    opcode: u8,
    operand_count: usize,
};

/// Opcode → SimpleOp table — see `mem_ops` for the rationale. ~40 entries,
/// linear-scan-eql was the dominant single cost per opcode in earlier profiles.
const simple_ops = std.StaticStringMap(SimpleOp).initComptime(.{
    // i32 binops
    .{ "i32.add", SimpleOp{ .opcode = 0x6A, .operand_count = 2 } },
    .{ "i32.sub", SimpleOp{ .opcode = 0x6B, .operand_count = 2 } },
    .{ "i32.mul", SimpleOp{ .opcode = 0x6C, .operand_count = 2 } },
    .{ "i32.div_s", SimpleOp{ .opcode = 0x6D, .operand_count = 2 } },
    .{ "i32.div_u", SimpleOp{ .opcode = 0x6E, .operand_count = 2 } },
    .{ "i32.rem_s", SimpleOp{ .opcode = 0x6F, .operand_count = 2 } },
    .{ "i32.rem_u", SimpleOp{ .opcode = 0x70, .operand_count = 2 } },
    .{ "i32.and", SimpleOp{ .opcode = 0x71, .operand_count = 2 } },
    .{ "i32.or", SimpleOp{ .opcode = 0x72, .operand_count = 2 } },
    .{ "i32.xor", SimpleOp{ .opcode = 0x73, .operand_count = 2 } },
    .{ "i32.shl", SimpleOp{ .opcode = 0x74, .operand_count = 2 } },
    .{ "i32.shr_s", SimpleOp{ .opcode = 0x75, .operand_count = 2 } },
    .{ "i32.shr_u", SimpleOp{ .opcode = 0x76, .operand_count = 2 } },
    // i32 cmp
    .{ "i32.eq", SimpleOp{ .opcode = 0x46, .operand_count = 2 } },
    .{ "i32.ne", SimpleOp{ .opcode = 0x47, .operand_count = 2 } },
    .{ "i32.lt_s", SimpleOp{ .opcode = 0x48, .operand_count = 2 } },
    .{ "i32.lt_u", SimpleOp{ .opcode = 0x49, .operand_count = 2 } },
    .{ "i32.gt_s", SimpleOp{ .opcode = 0x4A, .operand_count = 2 } },
    .{ "i32.gt_u", SimpleOp{ .opcode = 0x4B, .operand_count = 2 } },
    .{ "i32.le_s", SimpleOp{ .opcode = 0x4C, .operand_count = 2 } },
    .{ "i32.le_u", SimpleOp{ .opcode = 0x4D, .operand_count = 2 } },
    .{ "i32.ge_s", SimpleOp{ .opcode = 0x4E, .operand_count = 2 } },
    .{ "i32.ge_u", SimpleOp{ .opcode = 0x4F, .operand_count = 2 } },
    // i32 unops
    .{ "i32.eqz", SimpleOp{ .opcode = 0x45, .operand_count = 1 } },
    .{ "i32.clz", SimpleOp{ .opcode = 0x67, .operand_count = 1 } },
    .{ "i32.ctz", SimpleOp{ .opcode = 0x68, .operand_count = 1 } },
    .{ "i32.popcnt", SimpleOp{ .opcode = 0x69, .operand_count = 1 } },
    // i64
    .{ "i64.add", SimpleOp{ .opcode = 0x7C, .operand_count = 2 } },
    .{ "i64.sub", SimpleOp{ .opcode = 0x7D, .operand_count = 2 } },
    .{ "i64.mul", SimpleOp{ .opcode = 0x7E, .operand_count = 2 } },
    .{ "i64.div_s", SimpleOp{ .opcode = 0x7F, .operand_count = 2 } },
    .{ "i64.div_u", SimpleOp{ .opcode = 0x80, .operand_count = 2 } },
    .{ "i64.rem_s", SimpleOp{ .opcode = 0x81, .operand_count = 2 } },
    .{ "i64.rem_u", SimpleOp{ .opcode = 0x82, .operand_count = 2 } },
    // f64
    .{ "f64.add", SimpleOp{ .opcode = 0xA0, .operand_count = 2 } },
    .{ "f64.sub", SimpleOp{ .opcode = 0xA1, .operand_count = 2 } },
    .{ "f64.mul", SimpleOp{ .opcode = 0xA2, .operand_count = 2 } },
    .{ "f64.div", SimpleOp{ .opcode = 0xA3, .operand_count = 2 } },
    // f32
    .{ "f32.add", SimpleOp{ .opcode = 0x92, .operand_count = 2 } },
    .{ "f32.sub", SimpleOp{ .opcode = 0x93, .operand_count = 2 } },
    .{ "f32.mul", SimpleOp{ .opcode = 0x94, .operand_count = 2 } },
    .{ "f32.div", SimpleOp{ .opcode = 0x95, .operand_count = 2 } },
});

fn lookupSimpleOp(op: []const u8) ?SimpleOp {
    return simple_ops.get(op);
}

fn compileFuncBody(allocator: std.mem.Allocator, module: *Module, func: *const Func, out: *std.ArrayListUnmanaged(u8)) Error!void {
    var c = Compiler{
        .allocator = allocator,
        .module = module,
        .func = func,
        .body = func.body,
        .index = 0,
        .out = out,
    };
    defer c.labels.deinit(allocator);
    try c.compileSeq();
}

// ── LEB128 ────────────────────────────────────────────────────────────────────

fn writeULEB128(allocator: std.mem.Allocator, dst: *std.ArrayListUnmanaged(u8), v_in: anytype) Error!void {
    var v: u64 = @intCast(v_in);
    while (true) {
        var byte: u8 = @intCast(v & 0x7F);
        v >>= 7;
        if (v != 0) byte |= 0x80;
        try dst.append(allocator, byte);
        if (v == 0) return;
    }
}

fn writeSLEB128(allocator: std.mem.Allocator, dst: *std.ArrayListUnmanaged(u8), v_in: i64) Error!void {
    var v = v_in;
    while (true) {
        const byte: u8 = @as(u8, @truncate(@as(u64, @bitCast(v)))) & 0x7F;
        v >>= 7;
        const sign_bit_set = (byte & 0x40) != 0;
        if ((v == 0 and !sign_bit_set) or (v == -1 and sign_bit_set)) {
            try dst.append(allocator, byte);
            return;
        }
        try dst.append(allocator, byte | 0x80);
    }
}

// ── Tests ─────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "tokenize: paren + atoms + strings" {
    var toks = try tokenize(testing.allocator, "(module (func $a))");
    defer toks.deinit(testing.allocator);
    try testing.expectEqual(@as(usize, 7), toks.items.len);
    try testing.expect(toks.items[0].kind == .lparen);
    try testing.expect(toks.items[1].kind == .atom);
    try testing.expectEqualStrings("module", toks.items[1].text);
    try testing.expectEqualStrings("$a", toks.items[4].text);
}

test "tokenize: line comment ;; and block (; ;)" {
    var toks = try tokenize(testing.allocator, "(a ;; line\n b (; block ;) c)");
    defer toks.deinit(testing.allocator);
    var atoms: usize = 0;
    for (toks.items) |t| if (t.kind == .atom) {
        atoms += 1;
    };
    try testing.expectEqual(@as(usize, 3), atoms);
}

test "ULEB128 / SLEB128 round-trip basics" {
    var dst: std.ArrayListUnmanaged(u8) = .empty;
    defer dst.deinit(testing.allocator);

    try writeULEB128(testing.allocator, &dst, @as(u64, 624485));
    try testing.expectEqualSlices(u8, &.{ 0xE5, 0x8E, 0x26 }, dst.items);

    dst.clearRetainingCapacity();
    try writeSLEB128(testing.allocator, &dst, -123456);
    try testing.expectEqualSlices(u8, &.{ 0xC0, 0xBB, 0x78 }, dst.items);

    dst.clearRetainingCapacity();
    try writeSLEB128(testing.allocator, &dst, 0);
    try testing.expectEqualSlices(u8, &.{0x00}, dst.items);
}

test "compile: trivial module with one exported empty func" {
    const wat =
        \\(module
        \\  (func (export "_botopink_main"))
        \\)
    ;
    const wasm = try compile(testing.allocator, wat);
    defer testing.allocator.free(wasm);

    // Magic + version
    try testing.expectEqualSlices(u8, &.{ 0, 0x61, 0x73, 0x6D, 1, 0, 0, 0 }, wasm[0..8]);
    // Should at least contain "_botopink_main" in the export section.
    try testing.expect(std.mem.indexOf(u8, wasm, "_botopink_main") != null);
}

test "compile: i32.const arithmetic in folded form" {
    const wat =
        \\(module
        \\  (func (export "main") (result i32)
        \\    (i32.add (i32.const 1) (i32.const 2))))
    ;
    const wasm = try compile(testing.allocator, wat);
    defer testing.allocator.free(wasm);

    // Code section: 0x41 0x01 0x41 0x02 0x6A
    try testing.expect(std.mem.indexOf(u8, wasm, &.{ 0x41, 0x01, 0x41, 0x02, 0x6A }) != null);
}

test "compile: buildScript shape — wasi fd_write + memory + data + func" {
    const wat =
        \\(module
        \\  (import "wasi_snapshot_preview1" "fd_write"
        \\    (func $fd_write (param i32 i32 i32 i32) (result i32)))
        \\  (memory (export "memory") 1)
        \\  (data (i32.const 8) "hi")
        \\  (func (export "_start")
        \\    (i32.store (i32.const 0) (i32.const 8))
        \\    (i32.store (i32.const 4) (i32.const 2))
        \\    (drop (call $fd_write (i32.const 1) (i32.const 0) (i32.const 1) (i32.const 200)))))
    ;
    const wasm = try compile(testing.allocator, wat);
    defer testing.allocator.free(wasm);

    // Module header
    try testing.expectEqualSlices(u8, &.{ 0, 0x61, 0x73, 0x6D, 1, 0, 0, 0 }, wasm[0..8]);
    // Should contain the import strings.
    try testing.expect(std.mem.indexOf(u8, wasm, "wasi_snapshot_preview1") != null);
    try testing.expect(std.mem.indexOf(u8, wasm, "fd_write") != null);
    try testing.expect(std.mem.indexOf(u8, wasm, "memory") != null);
    try testing.expect(std.mem.indexOf(u8, wasm, "_start") != null);
    try testing.expect(std.mem.indexOf(u8, wasm, "hi") != null);
}

test "compile: block + br_if + loop round-trip" {
    // Tightly mimics the shape codegen/wat.zig emits: a `(block $done (loop
    // $loop … br_if $done … br $loop))` countdown. The binary stream should
    // contain a 0x02 block opener with empty blocktype (0x40), a 0x03 loop
    // opener, and 0x0D br_if + 0x0C br with the right relative indices.
    const wat =
        \\(module
        \\  (func (export "main")
        \\    (block $done
        \\      (loop $loop
        \\        i32.const 0
        \\        br_if $done
        \\        br $loop))))
    ;
    const wasm = try compile(testing.allocator, wat);
    defer testing.allocator.free(wasm);
    // 0x02 0x40 (block empty) 0x03 0x40 (loop empty) 0x41 0x00 (i32.const 0)
    // 0x0D 0x01 (br_if depth=1) 0x0C 0x00 (br depth=0)
    try testing.expect(std.mem.indexOf(u8, wasm, &.{ 0x02, 0x40, 0x03, 0x40, 0x41, 0x00, 0x0D, 0x01, 0x0C, 0x00 }) != null);
}

test "compile: rejects truly unsupported opcode" {
    const wat =
        \\(module
        \\  (func (export "main")
        \\    (v128.const i32x4 0 0 0 0)))
    ;
    try testing.expectError(error.BadOpcode, compile(testing.allocator, wat));
}

test "compile: locals with $name resolve correctly" {
    const wat =
        \\(module
        \\  (func (export "main") (param $a i32) (param $b i32) (result i32)
        \\    (i32.add (local.get $a) (local.get $b))))
    ;
    const wasm = try compile(testing.allocator, wat);
    defer testing.allocator.free(wasm);
    // 0x20 = local.get; 0x20 0x00, 0x20 0x01, 0x6A
    try testing.expect(std.mem.indexOf(u8, wasm, &.{ 0x20, 0x00, 0x20, 0x01, 0x6A }) != null);
}

test "compile: data segment with hex escapes" {
    const wat =
        \\(module
        \\  (memory (export "memory") 1)
        \\  (data (i32.const 0) "\68\69"))
    ;
    const wasm = try compile(testing.allocator, wat);
    defer testing.allocator.free(wasm);
    // The data section should literally contain "hi" (0x68, 0x69) bytes.
    try testing.expect(std.mem.indexOf(u8, wasm, "hi") != null);
}
