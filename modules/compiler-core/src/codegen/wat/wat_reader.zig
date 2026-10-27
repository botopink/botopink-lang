//! Front 164 s3 — a `.wat` file read into the code model (`wat_ast.zig`).
//!
//! The compiler's own reader of WebAssembly text: s-expressions, no external
//! tool. It reads what a hand-written leaf of std-wasm is
//! (`modules/std-wasm/wat/`, `std_leaves.zig`): a sequence of `(func …)` forms,
//! each with named parameters, an optional result, named locals and a body of
//! instructions — flat (`local.get $s`), folded (`(i32.add (local.get $a)
//! (i32.const 1))`) or structured (`(block $l (result i32) …)`, `(loop …)`,
//! `(if (result i32) (then …) (else …))`), the text `wat_emitter.zig` writes.
//!
//! A leaf names the codegen's GC types and never declares one (decision 549):
//! `$str`, `$arr_any`, … are resolved through `Names.typeIndex` against the
//! module's type table, and a `(type …)` or `(rec …)` form is refused at the
//! declaration. A `call` names its callee through `Names.callee`, which answers
//! the symbol the program knows it by.
//!
//! Every refusal is located: `Diag` holds the file, the line and the column
//! of the token it is about, and the message. Nothing is guessed (decision 67):
//! an instruction the model has no node for, a numeral the binary format cannot
//! encode, an index where a name is required — each is a located error.

const std = @import("std");
const ast = @import("wat_ast.zig");
const hostBinding = @import("host_binding.zig");
const wasmBinary = @import("wasm_binary_emitter.zig");

const ValType = ast.ValType;

pub const Error = std.mem.Allocator.Error || error{
    /// The text does not read; `Diag` locates why.
    Unreadable,
};

/// Why a read failed: the file, the token's position and the message.
pub const Diag = struct {
    path: []const u8 = "",
    line: u32 = 0,
    col: u32 = 0,
    message: []const u8 = "",

    /// `path:line:col: message`, owned by `ar`.
    pub fn text(d: Diag, ar: std.mem.Allocator) ![]u8 {
        return std.fmt.allocPrint(ar, "{s}:{d}:{d}: {s}", .{ d.path, d.line, d.col, d.message });
    }
};

/// What a leaf names outside itself: the GC types of the module it is read
/// into (decision 549), and the functions it calls.
pub const Names = struct {
    ctx: *anyopaque,
    /// The index of the module type named `name` (`str`, without `$`), or
    /// null when the codegen has no type of that name.
    typeIndex: *const fn (ctx: *anyopaque, name: []const u8) ?u16,
    /// The symbol a `call $name` calls, or null when nothing of that name
    /// can be called from the file.
    callee: *const fn (ctx: *anyopaque, name: []const u8) ?[]const u8,
    /// The symbol a `global.get` / `global.set` names, or null when the
    /// codegen declares no global of that name (decision 585 (i): a leaf
    /// names a global the prelude declares, as it names a type).
    global: *const fn (ctx: *anyopaque, name: []const u8) ?[]const u8,
};

// ── tokens ───────────────────────────────────────────────────────────────────

pub const Pos = struct { line: u32 = 1, col: u32 = 1 };

pub const Tok = struct {
    kind: Kind,
    text: []const u8,
    pos: Pos,

    pub const Kind = enum { open, close, atom, string, eof };
};

/// The tokens of a `.wat` text: `(`, `)`, atoms, strings; `;; …` and
/// `(; … ;)` comments skipped. It allocates nothing.
pub const Tokenizer = struct {
    src: []const u8,
    i: usize = 0,
    pos: Pos = .{},
    /// Set when the text holds a construct that is no token (an unclosed
    /// string or block comment): its position.
    bad: ?Pos = null,

    fn advance(t: *Tokenizer) void {
        if (t.src[t.i] == '\n') {
            t.pos.line += 1;
            t.pos.col = 1;
        } else t.pos.col += 1;
        t.i += 1;
    }

    pub fn next(t: *Tokenizer) Tok {
        while (t.i < t.src.len) {
            const c = t.src[t.i];
            if (c == ' ' or c == '\t' or c == '\n' or c == '\r') {
                t.advance();
            } else if (c == ';' and t.i + 1 < t.src.len and t.src[t.i + 1] == ';') {
                while (t.i < t.src.len and t.src[t.i] != '\n') t.advance();
            } else if (c == '(' and t.i + 1 < t.src.len and t.src[t.i + 1] == ';') {
                const at = t.pos;
                var depth: usize = 0;
                while (t.i < t.src.len) {
                    if (t.src[t.i] == '(' and t.i + 1 < t.src.len and t.src[t.i + 1] == ';') {
                        depth += 1;
                        t.advance();
                        t.advance();
                    } else if (t.src[t.i] == ';' and t.i + 1 < t.src.len and t.src[t.i + 1] == ')') {
                        depth -= 1;
                        t.advance();
                        t.advance();
                        if (depth == 0) break;
                    } else t.advance();
                }
                if (depth != 0) {
                    t.bad = at;
                    return .{ .kind = .eof, .text = "", .pos = at };
                }
            } else break;
        }
        const at = t.pos;
        if (t.i >= t.src.len) return .{ .kind = .eof, .text = "", .pos = at };
        const start = t.i;
        switch (t.src[t.i]) {
            '(' => {
                t.advance();
                return .{ .kind = .open, .text = t.src[start..t.i], .pos = at };
            },
            ')' => {
                t.advance();
                return .{ .kind = .close, .text = t.src[start..t.i], .pos = at };
            },
            '"' => {
                t.advance();
                while (t.i < t.src.len and t.src[t.i] != '"') {
                    if (t.src[t.i] == '\\' and t.i + 1 < t.src.len) t.advance();
                    t.advance();
                }
                if (t.i >= t.src.len) {
                    t.bad = at;
                    return .{ .kind = .eof, .text = "", .pos = at };
                }
                t.advance();
                return .{ .kind = .string, .text = t.src[start..t.i], .pos = at };
            },
            else => {
                while (t.i < t.src.len) {
                    const c = t.src[t.i];
                    if (c == ' ' or c == '\t' or c == '\n' or c == '\r' or c == '(' or c == ')' or c == '"' or c == ';') break;
                    t.advance();
                }
                return .{ .kind = .atom, .text = t.src[start..t.i], .pos = at };
            },
        }
    }
};

/// The names of the top-level `(func $name …)` forms of `src`, in order —
/// what the leaf table answers a `std:` name by, with no allocation.
pub const FuncNames = struct {
    t: Tokenizer,

    pub fn init(src: []const u8) FuncNames {
        return .{ .t = .{ .src = src } };
    }

    pub fn next(it: *FuncNames) ?[]const u8 {
        var depth: usize = 0;
        while (true) {
            const tok = it.t.next();
            switch (tok.kind) {
                .eof => return null,
                .open => {
                    depth += 1;
                    if (depth != 1) continue;
                    const head = it.t.next();
                    if (head.kind == .close) {
                        depth -= 1;
                        continue;
                    }
                    if (head.kind == .open) {
                        depth += 1;
                        continue;
                    }
                    if (head.kind != .atom or !std.mem.eql(u8, head.text, "func")) continue;
                    const name = it.t.next();
                    if (name.kind == .close) {
                        depth -= 1;
                        continue;
                    }
                    if (name.kind == .open) {
                        depth += 1;
                        continue;
                    }
                    if (name.kind == .atom and name.text.len > 1 and name.text[0] == '$') return name.text[1..];
                },
                .close => depth -|= 1,
                else => {},
            }
        }
    }
};

// ── s-expressions ────────────────────────────────────────────────────────────

const Node = union(enum) {
    atom: Tok,
    list: List,

    const List = struct { open: Pos, items: []const Node };

    fn pos(n: Node) Pos {
        return switch (n) {
            .atom => |a| a.pos,
            .list => |l| l.open,
        };
    }

    /// The list's first atom (`func`, `block`, `i32.add`), or null.
    fn head(n: Node) ?[]const u8 {
        if (n != .list or n.list.items.len == 0) return null;
        const h = n.list.items[0];
        return if (h == .atom and h.atom.kind == .atom) h.atom.text else null;
    }
};

const Reader = struct {
    ar: std.mem.Allocator,
    path: []const u8,
    names: Names,
    diag: *Diag,

    fn fail(r: *Reader, at: Pos, comptime f: []const u8, args: anytype) Error {
        r.diag.* = .{
            .path = r.path,
            .line = at.line,
            .col = at.col,
            .message = try std.fmt.allocPrint(r.ar, f, args),
        };
        return error.Unreadable;
    }

    /// Every top-level node of the text.
    fn parseAll(r: *Reader, src: []const u8) Error![]const Node {
        var t: Tokenizer = .{ .src = src };
        var out: std.ArrayListUnmanaged(Node) = .empty;
        while (true) {
            const tok = t.next();
            switch (tok.kind) {
                .eof => {
                    if (t.bad) |at| return r.fail(at, "an unclosed string or block comment", .{});
                    return out.items;
                },
                .close => return r.fail(tok.pos, "a `)` that closes nothing", .{}),
                .open => try out.append(r.ar, try r.parseList(&t, tok.pos)),
                else => try out.append(r.ar, .{ .atom = tok }),
            }
        }
    }

    fn parseList(r: *Reader, t: *Tokenizer, open: Pos) Error!Node {
        var items: std.ArrayListUnmanaged(Node) = .empty;
        while (true) {
            const tok = t.next();
            switch (tok.kind) {
                .eof => {
                    if (t.bad) |at| return r.fail(at, "an unclosed string or block comment", .{});
                    return r.fail(open, "a `(` that is never closed", .{});
                },
                .close => return .{ .list = .{ .open = open, .items = items.items } },
                .open => try items.append(r.ar, try r.parseList(t, tok.pos)),
                else => try items.append(r.ar, .{ .atom = tok }),
            }
        }
    }

    // ── forms ────────────────────────────────────────────────────────────────

    fn file(r: *Reader, nodes: []const Node) Error![]const ast.Func {
        var funcs: std.ArrayListUnmanaged(ast.Func) = .empty;
        for (nodes) |n| {
            const h = n.head() orelse return r.fail(n.pos(), "a leaf file holds `(func …)` forms only", .{});
            if (std.mem.eql(u8, h, "type") or std.mem.eql(u8, h, "rec"))
                return r.fail(n.pos(), "a leaf declares no type: it names the codegen's (`$str`, `$arr_any`, …) — decision 549", .{});
            if (!std.mem.eql(u8, h, "func"))
                return r.fail(n.pos(), "`({s} …)`: a leaf file holds `(func …)` forms only", .{h});
            try funcs.append(r.ar, try r.func(n.list));
        }
        return funcs.items;
    }

    fn symbolOf(r: *Reader, n: Node, what: []const u8) Error![]const u8 {
        if (n == .atom and n.atom.kind == .atom and n.atom.text.len > 1 and n.atom.text[0] == '$') return n.atom.text[1..];
        return r.fail(n.pos(), "{s} is written by its `$name`", .{what});
    }

    fn func(r: *Reader, l: Node.List) Error!ast.Func {
        if (l.items.len < 2) return r.fail(l.open, "a `(func …)` names itself: `(func $<module>.<function> …)`", .{});
        const name = try r.symbolOf(l.items[1], "a function");
        var params: std.ArrayListUnmanaged(ast.Param) = .empty;
        var locals: std.ArrayListUnmanaged([]const ast.Local) = .empty;
        var result: ?ValType = null;
        var i: usize = 2;
        while (i < l.items.len) : (i += 1) {
            const n = l.items[i];
            const h = n.head() orelse break;
            if (std.mem.eql(u8, h, "param") or std.mem.eql(u8, h, "local")) {
                const items = n.list.items;
                if (items.len != 3) return r.fail(n.pos(), "`({s} $name <type>)`: one named {s} per form", .{ h, h });
                const sym = try r.symbolOf(items[1], if (h[0] == 'p') "a parameter" else "a local");
                const ty = try r.valType(items[2]);
                if (h[0] == 'p') {
                    if (locals.items.len > 0) return r.fail(n.pos(), "a parameter comes before every local", .{});
                    try params.append(r.ar, .{ .name = sym, .ty = ty });
                } else {
                    const one = try r.ar.alloc(ast.Local, 1);
                    one[0] = .{ .name = sym, .ty = ty };
                    try locals.append(r.ar, one);
                }
            } else if (std.mem.eql(u8, h, "result")) {
                if (n.list.items.len != 2) return r.fail(n.pos(), "`(result <type>)`: one result", .{});
                if (result != null) return r.fail(n.pos(), "a function answers one result", .{});
                result = try r.valType(n.list.items[1]);
            } else if (std.mem.eql(u8, h, "export") or std.mem.eql(u8, h, "import")) {
                return r.fail(n.pos(), "a leaf is neither exported nor imported: the program calls it", .{});
            } else if (std.mem.eql(u8, h, "type")) {
                return r.fail(n.pos(), "a leaf writes its parameters and result, never a `(type …)`", .{});
            } else break;
        }
        const body = try r.seq(l.items[i..], result, 4);
        const f: ast.Func = .{
            .name = name,
            .params = params.items,
            .result = result,
            .locals = locals.items,
            .body = body,
        };
        ast.validateFunc(f) catch |err| return r.fail(l.open, "`${s}` is no valid function ({s})", .{ name, @errorName(err) });
        return f;
    }

    // ── types ────────────────────────────────────────────────────────────────

    const abstract = [_]struct { []const u8, []const u8, ValType }{
        .{ "anyref", "any", .anyref },
        .{ "eqref", "eq", .eqref },
        .{ "i31ref", "i31", .i31ref },
        .{ "structref", "struct", .structref },
        .{ "arrayref", "array", .arrayref },
        .{ "funcref", "func", .funcref },
        .{ "externref", "extern", .externref },
    };

    fn valType(r: *Reader, n: Node) Error!ValType {
        switch (n) {
            .atom => |a| {
                inline for (.{ "i32", "i64", "f32", "f64" }) |s| if (std.mem.eql(u8, a.text, s)) return @field(ValType, s);
                for (abstract) |x| if (std.mem.eql(u8, a.text, x[0])) return x[2];
                return r.fail(a.pos, "`{s}` is no value type a leaf writes (`i32`, `i64`, `f32`, `f64`, `anyref`, …, `(ref null $t)`)", .{a.text});
            },
            .list => |l| {
                const h = n.head() orelse return r.fail(l.open, "a value type is an atom or `(ref null <heap type>)`", .{});
                if (!std.mem.eql(u8, h, "ref")) return r.fail(l.open, "a value type is an atom or `(ref null <heap type>)`", .{});
                if (l.items.len != 3 or l.items[1] != .atom or !std.mem.eql(u8, l.items[1].atom.text, "null"))
                    return r.fail(l.open, "every reference a leaf writes is nullable: `(ref null <heap type>)`", .{});
                return r.heapType(l.items[2]);
            },
        }
    }

    /// `$t` (a type of the codegen's, decision 549) or an abstract heap type
    /// (`any`, `eq`, …) as the reference type that points into it.
    fn heapType(r: *Reader, n: Node) Error!ValType {
        if (n != .atom) return r.fail(n.pos(), "a heap type is `$<type>` or one of `any`, `eq`, `i31`, `struct`, `array`, `func`, `extern`", .{});
        const a = n.atom;
        if (a.text.len > 1 and a.text[0] == '$') return ValType.def(try r.typeIndex(n));
        for (abstract) |x| if (std.mem.eql(u8, a.text, x[1])) return x[2];
        return r.fail(a.pos, "`{s}` is no heap type: `$<type>` or one of `any`, `eq`, `i31`, `struct`, `array`, `func`, `extern`", .{a.text});
    }

    /// The codegen's type a `$name` names (decision 549).
    fn typeIndex(r: *Reader, n: Node) Error!u16 {
        const sym = try r.symbolOf(n, "a type");
        return r.names.typeIndex(r.names.ctx, sym) orelse
            return r.fail(n.pos(), "`${s}` names no type of the codegen's (a leaf names `$str`, `$arr_i32`, `$arr_f64`, `$arr_any`, `$box_i32`, `$box_i64`, `$box_f64`, `$result`)", .{sym});
    }

    // ── instructions ─────────────────────────────────────────────────────────

    const Out = std.ArrayListUnmanaged(ast.Line);

    fn seq(r: *Reader, nodes: []const Node, result: ?ValType, indent: u8) Error!ast.Seq {
        var out: Out = .empty;
        try r.instrs(&out, nodes, indent);
        return .{ .lines = out.items, .stack = if (result) |t| .{ .value = t } else .none };
    }

    /// Reads `nodes` as a run of instructions into `out`.
    fn instrs(r: *Reader, out: *Out, nodes: []const Node, indent: u8) Error!void {
        var i: usize = 0;
        while (i < nodes.len) {
            const n = nodes[i];
            switch (n) {
                .list => {
                    try r.folded(out, n.list, indent);
                    i += 1;
                },
                .atom => |a| {
                    if (a.kind != .atom) return r.fail(a.pos, "a string is no instruction", .{});
                    inline for (.{ "block", "loop", "if", "else", "end", "then" }) |kw| if (std.mem.eql(u8, a.text, kw))
                        return r.fail(a.pos, "`{s}`: a leaf writes a structured instruction folded — `(block $l …)`, `(loop $l …)`, `(if (then …) (else …))`", .{a.text});
                    const imm_at = i + 1;
                    var k = imm_at;
                    while (k < nodes.len and nodes[k] == .atom and isImmediate(nodes[k].atom.text)) k += 1;
                    const used = try r.plain(out, a, nodes[imm_at..k], nodes[imm_at..], indent);
                    i = imm_at + used;
                },
            }
        }
    }

    /// Whether `s` can be an immediate operand: a `$name`, a numeral, or a
    /// heap type's name.
    fn isImmediate(s: []const u8) bool {
        if (s.len == 0) return false;
        if (s[0] == '$' or s[0] == '-' or s[0] == '+' or std.ascii.isDigit(s[0])) return true;
        if (std.mem.startsWith(u8, s, "offset=")) return true;
        inline for (.{ "inf", "-inf", "nan", "any", "eq", "i31", "struct", "array", "func", "extern" }) |w| if (std.mem.eql(u8, s, w)) return true;
        return false;
    }

    /// A list in instruction position: a structured instruction, or a plain
    /// one folded — its immediates, then its operands, each folded too.
    fn folded(r: *Reader, out: *Out, l: Node.List, indent: u8) Error!void {
        const h = (Node{ .list = l }).head() orelse return r.fail(l.open, "a folded instruction starts with its name", .{});
        if (std.mem.eql(u8, h, "block") or std.mem.eql(u8, h, "loop")) return r.blockForm(out, l, h[0] == 'b', indent);
        if (std.mem.eql(u8, h, "if")) return r.ifForm(out, l, indent);
        if (std.mem.eql(u8, h, "then") or std.mem.eql(u8, h, "else"))
            return r.fail(l.open, "`({s} …)` belongs to an `(if …)`", .{h});
        const rest = l.items[1..];
        var k: usize = 0;
        while (k < rest.len and rest[k] == .atom) k += 1;
        // `ref.test` / `ref.cast` take a type written as a list.
        const typed = std.mem.eql(u8, h, "ref.test") or std.mem.eql(u8, h, "ref.cast");
        if (typed and k == 0 and rest.len > 0) k = 1;
        // Operands first, then the instruction over them.
        const operands = rest[k..];
        for (operands) |o| {
            if (o != .list) return r.fail(o.pos(), "a folded instruction's operands are folded instructions", .{});
            try r.folded(out, o.list, indent);
        }
        const used = try r.plain(out, l.items[0].atom, if (typed) &.{} else rest[0..k], rest[0..k], indent);
        if (used != k) return r.fail(rest[used].pos(), "`{s}` takes no further immediate", .{h});
    }

    fn label(n: []const Node) ?[]const u8 {
        if (n.len > 0 and n[0] == .atom and n[0].atom.text.len > 1 and n[0].atom.text[0] == '$') return n[0].atom.text[1..];
        return null;
    }

    /// `(result t)` at the front of `n`, or null; `used` how many nodes it took.
    fn blockResult(r: *Reader, n: []const Node, used: *usize) Error!?ValType {
        used.* = 0;
        if (n.len == 0) return null;
        const h = n[0].head() orelse return null;
        if (!std.mem.eql(u8, h, "result")) return null;
        if (n[0].list.items.len != 2) return r.fail(n[0].pos(), "`(result <type>)`: one result", .{});
        used.* = 1;
        return try r.valType(n[0].list.items[1]);
    }

    fn blockForm(r: *Reader, out: *Out, l: Node.List, is_block: bool, indent: u8) Error!void {
        var rest = l.items[1..];
        const lab = label(rest);
        if (lab != null) rest = rest[1..];
        var used: usize = 0;
        const result = try r.blockResult(rest, &used);
        rest = rest[used..];
        try out.append(r.ar, .{ .indent = indent, .instr = .{ .block = .{
            .kind = if (is_block) .block else .loop,
            .label = lab,
            .result = result,
            .body = try r.seq(rest, result, indent + 2),
        } } });
    }

    fn ifForm(r: *Reader, out: *Out, l: Node.List, indent: u8) Error!void {
        var rest = l.items[1..];
        const lab = label(rest);
        if (lab != null) rest = rest[1..];
        var used: usize = 0;
        const result = try r.blockResult(rest, &used);
        rest = rest[used..];
        // The condition, folded before the arms.
        var k: usize = 0;
        while (k < rest.len) : (k += 1) {
            const h = rest[k].head() orelse return r.fail(rest[k].pos(), "an `(if …)` holds its folded condition, then `(then …)` and an optional `(else …)`", .{});
            if (std.mem.eql(u8, h, "then")) break;
            try r.folded(out, rest[k].list, indent);
        }
        if (k == rest.len) return r.fail(l.open, "an `(if …)` has a `(then …)`", .{});
        const then_items = rest[k].list.items[1..];
        var else_arm: ?ast.If.Arm = null;
        if (k + 1 < rest.len) {
            const e = rest[k + 1];
            const h = e.head() orelse "";
            if (!std.mem.eql(u8, h, "else") or k + 2 != rest.len) return r.fail(e.pos(), "after `(then …)` an `(if …)` holds one `(else …)`", .{});
            else_arm = .{ .seq = try r.seq(e.list.items[1..], result, indent + 4) };
        }
        if (result != null and else_arm == null) return r.fail(l.open, "an `(if (result …))` has an `(else …)`", .{});
        try out.append(r.ar, .{ .indent = indent, .instr = .{ .@"if" = .{
            .label = lab,
            .result = result,
            .then = .{ .seq = try r.seq(then_items, result, indent + 4) },
            .@"else" = else_arm,
        } } });
    }

    fn expectSym(r: *Reader, op: Tok, imm: []const Node, k: usize, what: []const u8) Error![]const u8 {
        if (k >= imm.len) return r.fail(op.pos, "`{s}` takes {s} by its `$name`", .{ op.text, what });
        return r.symbolOf(imm[k], what);
    }

    fn expectNum(r: *Reader, op: Tok, imm: []const Node, k: usize, what: []const u8) Error!u32 {
        if (k >= imm.len) return r.fail(op.pos, "`{s}` takes {s}", .{ op.text, what });
        const a = imm[k].atom;
        return std.fmt.parseUnsigned(u32, a.text, 10) catch return r.fail(a.pos, "`{s}` is no {s}", .{ a.text, what });
    }

    fn expectType(r: *Reader, op: Tok, imm: []const Node, k: usize) Error!u16 {
        if (k >= imm.len) return r.fail(op.pos, "`{s}` names a type of the codegen's by its `$name`", .{op.text});
        return r.typeIndex(imm[k]);
    }

    /// One plain instruction `op` with its immediates read from `imm` (the
    /// atoms that may be immediates) — `after` is everything that follows it,
    /// for an immediate that is a list (`ref.test (ref null $t)`). Answers how
    /// many of `after` it took.
    fn plain(r: *Reader, out: *Out, op: Tok, imm: []const Node, after: []const Node, indent: u8) Error!usize {
        const s = op.text;
        var used: usize = 0;
        const instr: ast.Instr = blk: {
            if (std.mem.endsWith(u8, s, ".const") and s.len == "i32.const".len) {
                const ty: ValType = inline for (.{ "i32", "i64", "f32", "f64" }) |t| {
                    if (std.mem.eql(u8, s[0..3], t)) break @field(ValType, t);
                } else return r.fail(op.pos, "`{s}` is no instruction", .{s});
                if (imm.len == 0) return r.fail(op.pos, "`{s}` takes a numeral", .{s});
                const lit = imm[0].atom;
                var scratch: std.ArrayListUnmanaged(u8) = .empty;
                wasmBinary.constInstr(r.ar, &scratch, ty, lit.text) catch return r.fail(lit.pos, "`{s}` is no `{s}` numeral", .{ lit.text, @tagName(ty) });
                used = 1;
                break :blk .{ .@"const" = .{ .ty = ty, .text = lit.text } };
            }
            inline for (.{
                .{ "local.get", "local_get", "a local" },
                .{ "local.set", "local_set", "a local" },
                .{ "local.tee", "local_tee", "a local" },
                .{ "br", "br", "a label" },
                .{ "br_if", "br_if", "a label" },
                .{ "throw", "throw", "a tag" },
            }) |x| if (std.mem.eql(u8, s, x[0])) {
                used = 1;
                break :blk @unionInit(ast.Instr, x[1], try r.expectSym(op, imm, 0, x[2]));
            };
            inline for (.{ .{ "global.get", "global_get" }, .{ "global.set", "global_set" } }) |x| if (std.mem.eql(u8, s, x[0])) {
                const name = try r.expectSym(op, imm, 0, "a global");
                used = 1;
                const sym = r.names.global(r.names.ctx, name) orelse return r.fail(imm[0].pos(), "`{s} ${s}`: the codegen declares no global named `{s}` (a leaf names a global of the prelude's)", .{ s, name, name });
                break :blk @unionInit(ast.Instr, x[1], sym);
            };
            if (std.mem.eql(u8, s, "call")) {
                const name = try r.expectSym(op, imm, 0, "a function");
                used = 1;
                const sym = r.names.callee(r.names.ctx, name) orelse return r.fail(imm[0].pos(), "`call ${s}`: no leaf is named `{s}` and the prelude has no such function (a leaf calls another by its `$<module>.<function>`)", .{ name, name });
                break :blk .{ .call = sym };
            }
            if (std.mem.eql(u8, s, "br_table")) {
                var labels: std.ArrayListUnmanaged([]const u8) = .empty;
                while (used < imm.len) : (used += 1) try labels.append(r.ar, try r.symbolOf(imm[used], "a label"));
                if (labels.items.len == 0) return r.fail(op.pos, "`br_table` takes its labels and a default", .{});
                const default = labels.pop().?;
                break :blk .{ .br_table = .{ .labels = labels.items, .default = default } };
            }
            inline for (.{
                .{ "drop", ast.Instr.drop },
                .{ "return", ast.Instr.@"return" },
                .{ "unreachable", ast.Instr.@"unreachable" },
                .{ "select", ast.Instr.select },
                .{ "array.len", ast.Instr.array_len },
                .{ "ref.is_null", ast.Instr.ref_is_null },
                .{ "ref.eq", ast.Instr.ref_eq },
                .{ "ref.as_non_null", ast.Instr.ref_as_non_null },
                .{ "ref.i31", ast.Instr.ref_i31 },
            }) |x| if (std.mem.eql(u8, s, x[0])) break :blk x[1];
            if (std.mem.eql(u8, s, "i31.get_s") or std.mem.eql(u8, s, "i31.get_u")) break :blk .{ .i31_get = s[s.len - 1] == 's' };
            inline for (.{
                .{ "struct.new", "struct_new" },
                .{ "struct.new_default", "struct_new_default" },
                .{ "array.new", "array_new" },
                .{ "array.new_default", "array_new_default" },
                .{ "array.set", "array_set" },
                .{ "array.fill", "array_fill" },
            }) |x| if (std.mem.eql(u8, s, x[0])) {
                used = 1;
                break :blk @unionInit(ast.Instr, x[1], try r.expectType(op, imm, 0));
            };
            inline for (.{ .{ "struct.get", ast.Ext.none }, .{ "struct.get_s", ast.Ext.s }, .{ "struct.get_u", ast.Ext.u } }) |x| if (std.mem.eql(u8, s, x[0])) {
                used = 2;
                break :blk .{ .struct_get = .{ .ty = try r.expectType(op, imm, 0), .field = try r.expectNum(op, imm, 1, "a field's index"), .ext = x[1] } };
            };
            if (std.mem.eql(u8, s, "struct.set")) {
                used = 2;
                break :blk .{ .struct_set = .{ .ty = try r.expectType(op, imm, 0), .field = try r.expectNum(op, imm, 1, "a field's index") } };
            }
            inline for (.{ .{ "array.get", ast.Ext.none }, .{ "array.get_s", ast.Ext.s }, .{ "array.get_u", ast.Ext.u } }) |x| if (std.mem.eql(u8, s, x[0])) {
                used = 1;
                break :blk .{ .array_get = .{ .ty = try r.expectType(op, imm, 0), .ext = x[1] } };
            };
            if (std.mem.eql(u8, s, "array.new_fixed")) {
                used = 2;
                break :blk .{ .array_new_fixed = .{ .ty = try r.expectType(op, imm, 0), .n = try r.expectNum(op, imm, 1, "an element count") } };
            }
            if (std.mem.eql(u8, s, "array.copy")) {
                used = 2;
                break :blk .{ .array_copy = .{ .dst = try r.expectType(op, imm, 0), .src = try r.expectType(op, imm, 1) } };
            }
            if (std.mem.eql(u8, s, "ref.null")) {
                if (imm.len == 0) return r.fail(op.pos, "`ref.null` takes a heap type", .{});
                used = 1;
                break :blk .{ .ref_null = try r.heapType(imm[0]) };
            }
            if (std.mem.eql(u8, s, "ref.test") or std.mem.eql(u8, s, "ref.cast")) {
                if (after.len == 0 or after[0] != .list) return r.fail(op.pos, "`{s}` takes `(ref null <heap type>)`", .{s});
                const t = try r.valType(after[0]);
                if (!t.isRef()) return r.fail(after[0].pos(), "`{s}` takes `(ref null <heap type>)`", .{s});
                used = 1;
                break :blk if (s[4] == 't') .{ .ref_test = t } else .{ .ref_cast = t };
            }
            // Decision 992 — a leaf that reaches the host's file system moves bytes
            // between its GC strings and linear memory: the loads and stores of the
            // module's one memory, an optional `offset=N`, and the bulk operations.
            if (memAccess(s)) |access| {
                var arg = access.arg;
                if (imm.len > 0 and imm[0] == .atom and std.mem.startsWith(u8, imm[0].atom.text, "offset=")) {
                    const lit = imm[0].atom;
                    arg.offset = std.fmt.parseUnsigned(u32, lit.text["offset=".len..], 10) catch return r.fail(lit.pos, "`{s}` is no offset", .{lit.text});
                    used = 1;
                }
                break :blk if (access.is_load) .{ .load = arg } else .{ .store = arg };
            }
            inline for (.{
                .{ "memory.copy", ast.Instr.memory_copy },
                .{ "memory.fill", ast.Instr.memory_fill },
                .{ "memory.size", ast.Instr.memory_size },
                .{ "memory.grow", ast.Instr.memory_grow },
            }) |x| if (std.mem.eql(u8, s, x[0])) break :blk x[1];
            if (hostBinding.findOp(s)) |o| break :blk hostBinding.instrOf(o);
            return r.fail(op.pos, "`{s}` is no instruction a leaf reads", .{s});
        };
        try out.append(r.ar, .{ .indent = indent, .instr = instr });
        return used;
    }
};

/// A memory access the text spells (`i32.load`, `i64.load32_u`, `i32.store8`):
/// its type, width and signedness, and whether it loads.
fn memAccess(s: []const u8) ?struct { arg: ast.MemArg, is_load: bool } {
    const dot = std.mem.indexOfScalar(u8, s, '.') orelse return null;
    const ty: ValType = inline for (.{ "i32", "i64", "f32", "f64" }) |t| {
        if (std.mem.eql(u8, s[0..dot], t)) break @field(ValType, t);
    } else return null;
    const op = s[dot + 1 ..];
    var arg: ast.MemArg = .{ .ty = ty };
    const is_load = std.mem.startsWith(u8, op, "load");
    if (!is_load and !std.mem.startsWith(u8, op, "store")) return null;
    const suffix = op[if (is_load) 4 else 5..];
    if (suffix.len == 0) return .{ .arg = arg, .is_load = is_load };
    var bits = suffix;
    if (is_load) {
        // `8_u`, `16_s`, `32_u`: the width, then the sign of the extension.
        if (bits.len < 3 or bits[bits.len - 2] != '_') return null;
        arg.signed = switch (bits[bits.len - 1]) {
            's' => true,
            'u' => false,
            else => return null,
        };
        bits = bits[0 .. bits.len - 2];
    }
    arg.width = if (std.mem.eql(u8, bits, "8")) .byte else if (std.mem.eql(u8, bits, "16")) .half else if (std.mem.eql(u8, bits, "32")) .word else return null;
    return .{ .arg = arg, .is_load = is_load };
}

/// Reads every `(func …)` of `src` (the file at `path`). `ar` is an arena:
/// the functions borrow from it and from `src`. A text that does not read
/// fails with `error.Unreadable`, `diag` locating why.
pub fn read(ar: std.mem.Allocator, src: []const u8, path: []const u8, names: Names, diag: *Diag) Error![]const ast.Func {
    var r: Reader = .{ .ar = ar, .path = path, .names = names, .diag = diag };
    return r.file(try r.parseAll(src));
}

// ── tests ────────────────────────────────────────────────────────────────────

const TestNames = struct {
    const types = [_][]const u8{ "str", "arr_any" };

    fn typeIndex(_: *anyopaque, name: []const u8) ?u16 {
        for (types, 0..) |t, i| if (std.mem.eql(u8, t, name)) return @intCast(i);
        return null;
    }

    fn callee(_: *anyopaque, name: []const u8) ?[]const u8 {
        if (std.mem.eql(u8, name, "text.length")) return "__std_text_length";
        return null;
    }

    fn global(_: *anyopaque, name: []const u8) ?[]const u8 {
        if (std.mem.eql(u8, name, "__state")) return "__state";
        return null;
    }

    var dummy: u8 = 0;
    const names: Names = .{ .ctx = &dummy, .typeIndex = typeIndex, .callee = callee, .global = global };
};

fn testRead(ar: std.mem.Allocator, src: []const u8, diag: *Diag) Error![]const ast.Func {
    return read(ar, src, "leaf.wat", TestNames.names, diag);
}

test "wat_reader: a function, its parameters, result, locals and a structured body" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var diag: Diag = .{};
    const fs = try testRead(arena.allocator(),
        \\;; counts the bytes
        \\(func $text.count (param $s (ref null $str)) (param $k i32) (result i32)
        \\  (local $i i32) (; a block comment ;)
        \\  (block $done
        \\    (loop $next
        \\      (br_if $done (i32.ge_u (local.get $i) (array.len (local.get $s))))
        \\      local.get $i
        \\      i32.const 0x1
        \\      i32.add
        \\      local.set $i
        \\      br $next))
        \\  local.get $k
        \\  (if (result i32) (then local.get $i) (else i32.const -1)))
    , &diag);
    try std.testing.expectEqual(@as(usize, 1), fs.len);
    const f = fs[0];
    try std.testing.expectEqualStrings("text.count", f.name);
    try std.testing.expectEqual(@as(usize, 2), f.params.len);
    try std.testing.expectEqual(ValType.def(0), f.params[0].ty);
    try std.testing.expectEqualStrings("k", f.params[1].name);
    try std.testing.expectEqual(@as(?ValType, .i32), f.result);
    try std.testing.expectEqualStrings("i", f.locals[0][0].name);
    try std.testing.expectEqual(@as(usize, 3), f.body.lines.len);
    const blk = f.body.lines[0].instr.block;
    try std.testing.expectEqualStrings("done", blk.label.?);
    const loop = blk.body.lines[0].instr.block;
    try std.testing.expectEqual(ast.Block.Kind.loop, loop.kind);
    // The folded `br_if`: its operands first, innermost first.
    try std.testing.expectEqualStrings("i", loop.body.lines[0].instr.local_get);
    try std.testing.expectEqualStrings("s", loop.body.lines[1].instr.local_get);
    try std.testing.expect(loop.body.lines[2].instr == .array_len);
    try std.testing.expectEqualStrings("ge_u", loop.body.lines[3].instr.op.name);
    try std.testing.expectEqualStrings("done", loop.body.lines[4].instr.br_if);
    try std.testing.expectEqualStrings("0x1", loop.body.lines[6].instr.@"const".text);
    const iff = f.body.lines[2].instr.@"if";
    try std.testing.expectEqual(@as(?ValType, .i32), iff.result);
    try std.testing.expectEqualStrings("-1", iff.@"else".?.seq.lines[0].instr.@"const".text);
}

test "wat_reader: type names resolve against the codegen's table (decision 549)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var diag: Diag = .{};
    const fs = try testRead(arena.allocator(),
        \\(func $a.b (param $x (ref null $arr_any)) (result anyref)
        \\  local.get $x
        \\  i32.const 0
        \\  array.get $arr_any
        \\  ref.test (ref null $str)
        \\  drop
        \\  ref.null any
        \\  (call $text.length (array.new_default $str (i32.const 2)))
        \\  drop)
    , &diag);
    const f = fs[0];
    try std.testing.expectEqual(ValType.def(1), f.params[0].ty);
    try std.testing.expectEqual(@as(u16, 1), f.body.lines[2].instr.array_get.ty);
    try std.testing.expectEqual(ValType.def(0), f.body.lines[3].instr.ref_test);
    try std.testing.expectEqual(ValType.anyref, f.body.lines[5].instr.ref_null);
    try std.testing.expectEqual(@as(u16, 0), f.body.lines[7].instr.array_new_default);
    try std.testing.expectEqualStrings("__std_text_length", f.body.lines[8].instr.call);

    try std.testing.expectError(error.Unreadable, testRead(arena.allocator(),
        \\(func $a.b (param $x (ref null $rec_Point)))
    , &diag));
    try std.testing.expectEqual(@as(u32, 1), diag.line);
    try std.testing.expectEqual(@as(u32, 32), diag.col);
    try std.testing.expect(std.mem.indexOf(u8, diag.message, "`$rec_Point` names no type of the codegen's") != null);
}

test "wat_reader: a global is read only where the codegen declares it (decision 585 (i))" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var diag: Diag = .{};
    const fs = try testRead(arena.allocator(),
        \\(func $random.peek (result i64)
        \\  global.get $__state)
    , &diag);
    try std.testing.expectEqualStrings("__state", fs[0].body.lines[0].instr.global_get);
    try std.testing.expectError(error.Unreadable, testRead(arena.allocator(),
        \\(func $random.peek (result i64)
        \\  global.get $__other)
    , &diag));
    try std.testing.expect(std.mem.indexOf(u8, diag.message, "declares no global named `__other`") != null);
}

test "wat_reader: a type declaration is refused at the declaration (decision 549)" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    var diag: Diag = .{};
    try std.testing.expectError(error.Unreadable, testRead(arena.allocator(),
        \\(func $a.b)
        \\  (type $mine (array (mut i8)))
    , &diag));
    try std.testing.expectEqual(@as(u32, 2), diag.line);
    try std.testing.expectEqual(@as(u32, 3), diag.col);
    try std.testing.expect(std.mem.indexOf(u8, diag.message, "a leaf declares no type") != null);
    const text = try diag.text(arena.allocator());
    try std.testing.expect(std.mem.startsWith(u8, text, "leaf.wat:2:3: "));

    try std.testing.expectError(error.Unreadable, testRead(arena.allocator(), "(rec (type $t (struct)))", &diag));
    try std.testing.expect(std.mem.indexOf(u8, diag.message, "a leaf declares no type") != null);
}

test "wat_reader: a text that does not read is a located error" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ar = arena.allocator();
    const Case = struct { src: []const u8, line: u32, col: u32, needle: []const u8 };
    const cases = [_]Case{
        .{ .src = "(func $a.b\n  local.get $x", .line = 1, .col = 1, .needle = "never closed" },
        .{ .src = "(func $a.b)\n)", .line = 2, .col = 1, .needle = "closes nothing" },
        .{ .src = "(func $a.b\n  i32.frob)", .line = 2, .col = 3, .needle = "`i32.frob` is no instruction" },
        .{ .src = "(func $a.b (result i32)\n  i32.const 9999999999)", .line = 2, .col = 13, .needle = "no `i32` numeral" },
        .{ .src = "(func $a.b (param $p (ref $str)))", .line = 1, .col = 22, .needle = "nullable" },
        .{ .src = "(func $a.b\n  block $l\n  end)", .line = 2, .col = 3, .needle = "folded" },
        .{ .src = "(func $a.b\n  (call $nowhere.at.all))", .line = 2, .col = 9, .needle = "no leaf is named `nowhere.at.all`" },
        .{ .src = "(memory 1)", .line = 1, .col = 1, .needle = "`(func …)` forms only" },
        .{ .src = "(func $a.b (export \"x\"))", .line = 1, .col = 12, .needle = "neither exported" },
        .{ .src = "(func $a.b\n  local.get 0)", .line = 2, .col = 13, .needle = "by its `$name`" },
        .{ .src = "(func $a.b) \"open", .line = 1, .col = 13, .needle = "unclosed string" },
    };
    for (cases) |c| {
        var diag: Diag = .{};
        if (testRead(ar, c.src, &diag)) |_| {
            std.debug.print("\nread, expected a refusal: {s}\n", .{c.src});
            return error.TestExpectedRefusal;
        } else |err| try std.testing.expectEqual(error.Unreadable, err);
        if (diag.line != c.line or diag.col != c.col or std.mem.indexOf(u8, diag.message, c.needle) == null) {
            std.debug.print("\ngot {d}:{d} {s}\nexpected {d}:{d} …{s}…\n", .{ diag.line, diag.col, diag.message, c.line, c.col, c.needle });
            return error.TestUnexpectedDiag;
        }
    }
}

test "wat_reader: the top-level function names, comments skipped" {
    var it = FuncNames.init(
        \\;; (func $commented.out)
        \\(func $text.length (param $s (ref null $str)) (result i32)
        \\  (block $b (func $not.top)))
        \\(; (func $block.comment) ;)
        \\(func $text.charCodeAt)
    );
    try std.testing.expectEqualStrings("text.length", it.next().?);
    try std.testing.expectEqualStrings("text.charCodeAt", it.next().?);
    try std.testing.expect(it.next() == null);
}
