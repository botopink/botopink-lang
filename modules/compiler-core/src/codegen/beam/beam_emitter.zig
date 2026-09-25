//! BEAM assembly (`.S`) emitter — operands *and* instructions.
//!
//! Renders the same `Term` model as `erl_emitter.zig`, but as instruction
//! operands: scalars get their typed wrapper (`{atom, ok}`, `{integer, 1}`,
//! `{float, 1.0}`, `nil`) and compound values become `{literal, <term>}`, whose
//! inner term syntax is exactly the Erlang source form — so it is delegated to
//! `erl_emitter`.
//!
//! Every `.S` line the BEAM backend writes goes through a `write…` function
//! here. `beam_asm.zig` decides *what* to emit (which register, which label,
//! which live count); this file decides how it is spelled. Nothing in the
//! backend formats target text by hand, so quoting, operand shape and
//! indentation have exactly one implementation.

const std = @import("std");
const Term = @import("term.zig").Term;
const erl = @import("erl_emitter.zig");
const erlAst = @import("erl_ast.zig");

const Writer = std.Io.Writer;

pub const Error = erl.Error;

// ── operands ─────────────────────────────────────────────────────────────────

/// An instruction operand. Registers and labels are structural; values go
/// through `Term` so quoting and literal wrapping stay in one place.
pub const Operand = union(enum) {
    /// `{x, N}` — an x-register (caller-saved; every call frees them).
    x: u32,
    /// `{y, N}` — a stack slot in the current frame.
    y: u32,
    /// `{f, N}` — a branch target.
    f: u32,
    /// A typed value operand.
    term: Term,
    /// A string literal's lexer content → `{literal, <<"…">>}`.
    lexeme: []const u8,
    /// A bare integer written with no wrapper — a tuple arity in
    /// `is_tagged_tuple`, an element index in `get_tuple_element`.
    untagged: i64,
    /// A numeric literal kept as its *source token*, so `1.70` and `1e3` reach
    /// the `.S` exactly as written instead of round-tripping through a float.
    /// `{integer, N}` unless the token carries a `.`/`e`/`E`.
    number: Number,

    /// Register/label constructors take `anytype` so a `usize` index computed
    /// by the backend needs no cast at the call site.
    pub fn xr(n: anytype) Operand {
        return .{ .x = @intCast(n) };
    }
    pub fn yr(n: anytype) Operand {
        return .{ .y = @intCast(n) };
    }
    pub fn lbl(n: anytype) Operand {
        return .{ .f = @intCast(n) };
    }
    pub fn atom(name: []const u8) Operand {
        return .{ .term = Term.atomOf(name) };
    }
    pub fn int(n: anytype) Operand {
        return .{ .term = Term.int(@intCast(n)) };
    }
    pub fn str(bytes: []const u8) Operand {
        return .{ .term = Term.str(bytes) };
    }
    pub const nil: Operand = .{ .term = .nil };

    pub fn num(token: []const u8) Operand {
        return .{ .number = .{ .token = token } };
    }

    /// The negation of a numeric literal (`-3` from unary minus on `3`).
    pub fn negNum(token: []const u8) Operand {
        return .{ .number = .{ .token = token, .negate = true } };
    }
};

pub const Number = struct {
    token: []const u8,
    negate: bool = false,

    fn isFloat(self: Number) bool {
        for (self.token) |c| {
            if (c == '.' or c == 'e' or c == 'E') return true;
        }
        return false;
    }
};

/// A register an instruction writes to.
pub const Dest = union(enum) {
    x: u32,
    y: u32,

    pub fn xr(n: anytype) Dest {
        return .{ .x = @intCast(n) };
    }
    pub fn yr(n: anytype) Dest {
        return .{ .y = @intCast(n) };
    }

    fn operand(self: Dest) Operand {
        return switch (self) {
            .x => |n| .{ .x = n },
            .y => |n| .{ .y = n },
        };
    }
};

/// The `test` instruction's selector.
pub const TestOp = enum {
    is_eq,
    is_eq_exact,
    /// `{test, is_ne, …}` — unequal by VALUE (`2.0` and `2` are equal), the
    /// twin of `is_eq`; decision 8 §2.3's `!=` with an `unknown` operand.
    is_ne,
    is_ne_exact,
    is_map,
    is_tuple,
    is_nil,
    is_nonempty_list,
    is_list,
    is_binary,
    is_integer,
    is_float,
    /// Any number — decision 8 §4.1's `x is f64`.
    is_number,
    is_boolean,
    is_atom,
    is_ge,
    is_lt,
    is_tagged_tuple,
    /// `{test, is_pid, {f, F}, [Src]}` — the `Ets` owner wait loop
    /// (`beam_asm.zig`, front 17) asks whether its candidate is a process.
    is_pid,
    /// `{test, test_arity, {f, F}, [Src, N]}` — a tuple of exactly `N`
    /// elements. `is_tuple` alone leaves the arity unknown, which is what
    /// decision 8 §4.2's `x is #(i32, string)` has to answer about.
    test_arity,
};

/// The `gc_bif` selector. `add`/`sub`/… spell the quoted operator atoms.
pub const GcBif = enum {
    add,
    sub,
    mul,
    div_,
    /// `'/'` — float division (`div_` is integer division).
    fdiv,
    rem,
    length,
    /// `trunc/1` — an integral float's integer (decision 8 §4.1's conversion).
    trunc,
    /// `float/1` — a number's float.
    float,

    fn text(self: GcBif) []const u8 {
        return switch (self) {
            .add => "'+'",
            .sub => "'-'",
            .mul => "'*'",
            .div_ => "'div'",
            .fdiv => "'/'",
            .rem => "'rem'",
            .length => "length",
            .trunc => "trunc",
            .float => "float",
        };
    }
};

/// Where a call goes: a label in this module, or a remote `{extfunc, M, F, A}`.
pub const Callee = union(enum) {
    local: u32,
    ext: struct { module: []const u8, function: []const u8 },
};

/// How the call returns. `last` and `only` encode deallocate + return.
pub const CallKind = enum { normal, last, only };

fn writeReg(w: *Writer, tag: []const u8, n: u32) Writer.Error!void {
    try w.print("{{{s}, {d}}}", .{ tag, n });
}

/// Render an operand.
pub fn writeArg(w: *Writer, o: Operand) Error!void {
    switch (o) {
        .x => |n| try writeReg(w, "x", n),
        .y => |n| try writeReg(w, "y", n),
        .f => |n| try writeReg(w, "f", n),
        .term => |t| try writeOperand(w, t),
        .lexeme => |s| try writeLexemeBinaryOperand(w, s),
        .untagged => |n| try w.print("{d}", .{n}),
        .number => |n| try w.print("{{{s}, {s}{s}}}", .{
            if (n.isFloat()) "float" else "integer",
            if (n.negate) "-" else "",
            n.token,
        }),
    }
}

fn writeArgList(w: *Writer, args: []const Operand) Error!void {
    try w.writeAll("[");
    for (args, 0..) |a, i| {
        if (i > 0) try w.writeAll(", ");
        try writeArg(w, a);
    }
    try w.writeAll("]");
}

/// `{atom, Name}` with the shared quoting rule (`{atom, 'Record'}`).
pub fn writeAtomOperand(w: *Writer, name: []const u8) Writer.Error!void {
    try w.writeAll("{atom, ");
    try erl.writeAtom(w, name);
    try w.writeAll("}");
}

/// `{literal, <<"…">>}` from a botopink string literal's lexeme content.
pub fn writeLexemeBinaryOperand(w: *Writer, lexeme: []const u8) Writer.Error!void {
    try w.writeAll("{literal, ");
    try erl.writeBinaryFromLexeme(w, lexeme);
    try w.writeAll("}");
}

/// Render `t` as an instruction operand.
pub fn writeOperand(w: *Writer, t: Term) Error!void {
    switch (t) {
        .atom => |a| try writeAtomOperand(w, a),
        .boolean => |b| try writeAtomOperand(w, if (b) "true" else "false"),
        .integer => |n| try w.print("{{integer, {d}}}", .{n}),
        .float => |f| {
            try w.writeAll("{float, ");
            try erl.writeFloat(w, f);
            try w.writeAll("}");
        },
        .nil => try w.writeAll("nil"),
        .list => |items| if (items.len == 0) try w.writeAll("nil") else try writeLiteral(w, t),
        .binary, .tuple, .map => try writeLiteral(w, t),
    }
}

/// `{literal, <term>}` — valid for any term, including scalars.
pub fn writeLiteral(w: *Writer, t: Term) Error!void {
    try w.writeAll("{literal, ");
    try erl.writeTerm(w, t);
    try w.writeAll("}");
}

/// `{move, <operand>, {x, Dest}}.` as a full instruction line (4-space indent).
pub fn writeMove(w: *Writer, t: Term, dest: usize) Error!void {
    try w.writeAll("    {move, ");
    try writeOperand(w, t);
    try w.print(", {{x, {d}}}}}.\n", .{dest});
}

// ── instructions ─────────────────────────────────────────────────────────────
//
// One function per `.S` instruction the BEAM backend emits. Each takes typed
// operands (`Operand`/`Dest`/`TestOp`/`GcBif`/`Callee`), never preformatted
// text, and writes a whole line including its indentation and trailing `.`.
// Instruction bodies are indented four spaces; a `{label, …}` two; a
// `{function, …}` header none.

fn openInstr(w: *Writer, name: []const u8) Writer.Error!void {
    try w.print("    {{{s}", .{name});
}

fn closeInstr(w: *Writer) Writer.Error!void {
    try w.writeAll("}.\n");
}

fn writeField(w: *Writer, o: Operand) Error!void {
    try w.writeAll(", ");
    try writeArg(w, o);
}

// ── module preamble ──────────────────────────────────────────────────────────
//
// The four forms ahead of the first `{function, …}`: `{module, M}.`,
// `{exports, […]}.`, `{attributes, […]}.` and `{labels, N}.`. The backend
// decides the module atom, which functions are exported and the label count;
// these write them.

/// One `{Name, Arity}` entry of the `{exports, …}` form.
pub const Export = struct { name: []const u8, arity: usize };

/// `{module, Module}.`
pub fn writeModuleForm(w: *Writer, module: []const u8) Error!void {
    try w.writeAll("{module, ");
    try erl.writeAtom(w, module);
    try w.writeAll("}.\n");
}

/// `{exports, [{Name, Arity}, …]}.` — each name with the shared atom quoting.
pub fn writeExports(w: *Writer, exports: []const Export) Error!void {
    try w.writeAll("{exports, [");
    for (exports, 0..) |e, i| {
        if (i > 0) try w.writeAll(", ");
        try w.writeAll("{");
        try erl.writeAtom(w, e.name);
        try w.print(", {d}}}", .{e.arity});
    }
    try w.writeAll("]}.\n");
}

/// `{attributes, []}.` — the backend emits no module attributes.
pub fn writeAttributes(w: *Writer) Error!void {
    try w.writeAll("{attributes, []}.\n");
}

/// `{attributes, [{on_load, [{Name, Arity}]}]}.` — the one attribute the
/// backend emits: the function the loader runs once the module is loaded
/// (front 17 — where a `PersistentTerm` var is put).
pub fn writeOnLoadAttributes(w: *Writer, name: []const u8, arity: usize) Error!void {
    try w.writeAll("{attributes, [{on_load, [{");
    try erl.writeAtom(w, name);
    try w.print(", {d}}}]}}]}}.\n", .{arity});
}

/// `{labels, N}.` — one past the highest label the module uses.
pub fn writeLabels(w: *Writer, count: usize) Error!void {
    try w.print("{{labels, {d}}}.\n", .{count});
}

/// `  {label, N}.`
pub fn writeLabel(w: *Writer, n: usize) Error!void {
    try w.print("  {{label, {d}}}.\n", .{n});
}

/// `{function, Name, Arity, EntryLabel}.` — the un-indented form header.
pub fn writeFunctionHeader(w: *Writer, name: []const u8, arity: usize, entry: usize) Error!void {
    try w.writeAll("{function, ");
    try erl.writeAtom(w, name);
    try w.print(", {d}, {d}}}.\n", .{ arity, entry });
}

/// `{func_info, {atom, Module}, {atom, Name}, Arity}.`
pub fn writeFuncInfo(w: *Writer, module: []const u8, name: []const u8, arity: usize) Error!void {
    try openInstr(w, "func_info");
    try writeField(w, Operand.atom(module));
    try writeField(w, Operand.atom(name));
    try w.print(", {d}", .{arity});
    try closeInstr(w);
}

/// `{line, [{location, "<file>.erl", N}]}.`
pub fn writeLine(w: *Writer, module: []const u8, n: usize) Error!void {
    try w.print("    {{line, [{{location, \"{s}.erl\", {d}}}]}}.\n", .{ module, n });
}

/// `{move, Src, Dst}.`
pub fn writeMoveOp(w: *Writer, src: Operand, dst: Dest) Error!void {
    try openInstr(w, "move");
    try writeField(w, src);
    try writeField(w, dst.operand());
    try closeInstr(w);
}

/// `{jump, {f, N}}.`
pub fn writeJump(w: *Writer, label: usize) Error!void {
    try openInstr(w, "jump");
    try writeField(w, Operand.lbl(label));
    try closeInstr(w);
}

/// `return.` — the only instruction with no braces.
pub fn writeReturn(w: *Writer) Error!void {
    try w.writeAll("    return.\n");
}

/// `{allocate, NumY, Live}.`
pub fn writeAllocate(w: *Writer, num_y: usize, live: usize) Error!void {
    try w.print("    {{allocate, {d}, {d}}}.\n", .{ num_y, live });
}

/// `{deallocate, NumY}.`
pub fn writeDeallocate(w: *Writer, num_y: usize) Error!void {
    try w.print("    {{deallocate, {d}}}.\n", .{num_y});
}

/// `{init_yregs, {list, [{y, 0}, …]}}.` for slots `0..count-1`.
pub fn writeInitYregs(w: *Writer, count: usize) Error!void {
    try w.writeAll("    {init_yregs, {list, [");
    var i: usize = 0;
    while (i < count) : (i += 1) {
        if (i > 0) try w.writeAll(", ");
        try writeArg(w, Operand.yr(i));
    }
    try w.writeAll("]}}.\n");
}

/// `{test, Op, {f, Fail}, [Args…]}.`
pub fn writeTest(w: *Writer, op: TestOp, fail: usize, args: []const Operand) Error!void {
    try openInstr(w, "test");
    try w.print(", {s}", .{@tagName(op)});
    try writeField(w, Operand.lbl(fail));
    try w.writeAll(", ");
    try writeArgList(w, args);
    try closeInstr(w);
}

/// `{test_heap, Words, Live}.`
pub fn writeTestHeap(w: *Writer, words: usize, live: usize) Error!void {
    try w.print("    {{test_heap, {d}, {d}}}.\n", .{ words, live });
}

/// `{test_heap, {alloc, [{words, W}, {floats, 0}, {funs, F}]}, Live}.` — the
/// closure-allocating form `make_fun3` needs.
pub fn writeTestHeapAlloc(w: *Writer, words: usize, funs: usize, live: usize) Error!void {
    try w.print(
        "    {{test_heap, {{alloc, [{{words, {d}}}, {{floats, 0}}, {{funs, {d}}}]}}, {d}}}.\n",
        .{ words, funs, live },
    );
}

/// `{gc_bif, Bif, {f, 0}, Live, [Args…], Dst}.`
pub fn writeGcBif(w: *Writer, bif: GcBif, live: usize, args: []const Operand, dst: Dest) Error!void {
    try openInstr(w, "gc_bif");
    try w.print(", {s}, {{f, 0}}, {d}, ", .{ bif.text(), live });
    try writeArgList(w, args);
    try writeField(w, dst.operand());
    try closeInstr(w);
}

/// `{bif, Name, {f, Fail}, [Args…], Dst}.` — a guard BIF that neither
/// allocates nor frees any register (`element`, `tuple_size`, …). `fail` 0
/// raises on a bad argument instead of branching.
pub fn writeBif(w: *Writer, name: []const u8, fail: usize, args: []const Operand, dst: Dest) Error!void {
    try openInstr(w, "bif");
    try w.writeAll(", ");
    try erl.writeAtom(w, name);
    try writeField(w, Operand.lbl(fail));
    try w.writeAll(", ");
    try writeArgList(w, args);
    try writeField(w, dst.operand());
    try closeInstr(w);
}

fn callName(kind: CallKind, comptime base: []const u8) []const u8 {
    return switch (kind) {
        .normal => base,
        .last => base ++ "_last",
        .only => base ++ "_only",
    };
}

/// `{call, A, {f, L}}.` / `{call_last, A, {f, L}, NumY}.` /
/// `{call_only, A, {f, L}}.`, and the `call_ext…` forms for a remote callee.
/// `num_y` is only read for `.last`.
pub fn writeCall(w: *Writer, kind: CallKind, arity: usize, callee: Callee, num_y: usize) Error!void {
    switch (callee) {
        .local => |label| {
            try openInstr(w, callName(kind, "call"));
            try w.print(", {d}", .{arity});
            try writeField(w, Operand.lbl(label));
        },
        .ext => |e| {
            try openInstr(w, callName(kind, "call_ext"));
            try w.print(", {d}, {{extfunc, ", .{arity});
            try erl.writeAtom(w, e.module);
            try w.writeAll(", ");
            try erl.writeAtom(w, e.function);
            try w.print(", {d}}}", .{arity});
        },
    }
    if (kind == .last) try w.print(", {d}", .{num_y});
    try closeInstr(w);
}

/// `{'try', {y, Tag}, {f, Catch}}.` — open a catch section whose tag lives in
/// `{y, Tag}`; a raise inside it jumps to `Catch`.
pub fn writeTry(w: *Writer, tag_y: usize, catch_label: usize) Error!void {
    try w.print("    {{'try', {{y, {d}}}, {{f, {d}}}}}.\n", .{ tag_y, catch_label });
}

/// `{try_end, {y, Tag}}.` — the section completed without a raise.
pub fn writeTryEnd(w: *Writer, tag_y: usize) Error!void {
    try w.print("    {{try_end, {{y, {d}}}}}.\n", .{tag_y});
}

/// `{try_case, {y, Tag}}.` — first instruction at a catch label.
pub fn writeTryCase(w: *Writer, tag_y: usize) Error!void {
    try w.print("    {{try_case, {{y, {d}}}}}.\n", .{tag_y});
}

/// `{call_fun, Arity}.` — the fun sits in `{x, Arity}`.
pub fn writeCallFun(w: *Writer, arity: usize) Error!void {
    try w.print("    {{call_fun, {d}}}.\n", .{arity});
}

/// `{make_fun3, {f, L}, 0, 0, {x, 0}, {list, [Env…]}}.` — `make_fun2` is
/// rejected by `erlc +from_asm`. `env` is the captured free variables, passed
/// to the fun's function after its own parameters.
pub fn writeMakeFun3(w: *Writer, label: usize, env: []const Operand) Error!void {
    try w.print("    {{make_fun3, {{f, {d}}}, 0, 0, {{x, 0}}, {{list, ", .{label});
    try writeArgList(w, env);
    try w.writeAll("}}.\n");
}

/// `{put_list, Head, Tail, Dst}.`
pub fn writePutList(w: *Writer, head: Operand, tail: Operand, dst: Dest) Error!void {
    try openInstr(w, "put_list");
    try writeField(w, head);
    try writeField(w, tail);
    try writeField(w, dst.operand());
    try closeInstr(w);
}

/// `{put_tuple2, Dst, {list, [Elems…]}}.`
pub fn writePutTuple2(w: *Writer, dst: Dest, elems: []const Operand) Error!void {
    try openInstr(w, "put_tuple2");
    try writeField(w, dst.operand());
    try w.writeAll(", {list, ");
    try writeArgList(w, elems);
    try w.writeAll("}");
    try closeInstr(w);
}

/// `{get_tuple_element, Src, Index, Dst}.` — `Index` is 0-based.
pub fn writeGetTupleElement(w: *Writer, src: Operand, index: usize, dst: Dest) Error!void {
    try openInstr(w, "get_tuple_element");
    try writeField(w, src);
    try w.print(", {d}", .{index});
    try writeField(w, dst.operand());
    try closeInstr(w);
}

/// `{get_list, Src, Head, Tail}.`
pub fn writeGetList(w: *Writer, src: Operand, head: Dest, tail: Dest) Error!void {
    try openInstr(w, "get_list");
    try writeField(w, src);
    try writeField(w, head.operand());
    try writeField(w, tail.operand());
    try closeInstr(w);
}

/// `{get_map_elements, {f, Fail}, Src, {list, [{atom, Key}, Dst]}}.`
pub fn writeGetMapElements(w: *Writer, fail: usize, src: Operand, key: []const u8, dst: Dest) Error!void {
    try openInstr(w, "get_map_elements");
    try writeField(w, Operand.lbl(fail));
    try writeField(w, src);
    try w.writeAll(", {list, ");
    try writeArgList(w, &.{ Operand.atom(key), dst.operand() });
    try w.writeAll("}");
    try closeInstr(w);
}

/// One `key => value` pair of a `put_map_*` instruction.
pub const MapPair = struct { key: Operand, value: Operand };

/// `{put_map_assoc, {f, 0}, Src, Dst, Live, {list, [K, V, …]}}.` (`assoc` adds
/// or replaces; `exact` requires the key to exist).
pub fn writePutMap(w: *Writer, exact: bool, src: Operand, dst: Dest, live: usize, pairs: []const MapPair) Error!void {
    try openInstr(w, if (exact) "put_map_exact" else "put_map_assoc");
    try w.writeAll(", {f, 0}");
    try writeField(w, src);
    try writeField(w, dst.operand());
    try w.print(", {d}, {{list, [", .{live});
    for (pairs, 0..) |p, i| {
        if (i > 0) try w.writeAll(", ");
        try writeArg(w, p.key);
        try w.writeAll(", ");
        try writeArg(w, p.value);
    }
    try w.writeAll("]}");
    try closeInstr(w);
}

/// `    %% <text>` — a codegen note (an unlowered shape, a decision trace).
/// Not an instruction, so it is the one place free text is expected; the
/// `fmt` is a compile-time literal in the backend, never target syntax.
pub fn writeComment(w: *Writer, comptime fmt: []const u8, args: anytype) Error!void {
    try w.writeAll("    %% ");
    try w.print(fmt, args);
    try w.writeAll("\n");
}

/// A source comment carried over from the botopink program, at column 0 with
/// the Erlang prefix for its level (`%` / `%%` / `%%%`) — the same spelling
/// `erl_emitter.writeComment` uses for the `.erl` backend.
pub fn writeSourceComment(w: *Writer, c: erlAst.Comment) Error!void {
    try erl.writeComment(w, c);
    try w.writeAll("\n");
}

/// A `%%` note at column 0 — used for the module-level lowering traces that
/// sit between function forms.
pub fn writeTopComment(w: *Writer, comptime fmt: []const u8, args: anytype) Error!void {
    try w.writeAll("%% ");
    try w.print(fmt, args);
    try w.writeAll("\n");
}

/// The blank line between two function forms.
pub fn writeBlankLine(w: *Writer) Error!void {
    try w.writeAll("\n");
}

// ── tests ────────────────────────────────────────────────────────────────────

fn expectOperand(expected: []const u8, t: Term) !void {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeOperand(&aw.writer, t);
    try std.testing.expectEqualStrings(expected, aw.written());
}

test "beam_emitter: scalar operands" {
    try expectOperand("{atom, ok}", Term.atomOf("ok"));
    try expectOperand("{atom, 'Record'}", Term.atomOf("Record"));
    try expectOperand("{atom, 'end'}", Term.atomOf("end"));
    try expectOperand("{atom, true}", .{ .boolean = true });
    try expectOperand("{integer, 42}", Term.int(42));
    try expectOperand("{float, 2.5}", .{ .float = 2.5 });
    try expectOperand("nil", .nil);
    try expectOperand("nil", Term.listOf(&.{}));
}

test "beam_emitter: compound operands share erl term syntax" {
    try expectOperand("{literal, <<\"hi\">>}", Term.str("hi"));
    const entries = [_]Term.MapEntry{Term.field("kind", Term.atomOf("Record"))};
    try expectOperand("{literal, #{kind => 'Record'}}", Term.mapOf(&entries));
    const items = [_]Term{ Term.int(1), Term.atomOf("a") };
    try expectOperand("{literal, [1, a]}", Term.listOf(&items));
    try expectOperand("{literal, {1, a}}", Term.tupleOf(&items));
}

test "beam_emitter: move instruction" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeMove(&aw.writer, Term.str("~p~n"), 0);
    try std.testing.expectEqualStrings("    {move, {literal, <<\"~p~n\">>}, {x, 0}}.\n", aw.written());
}

fn expectLine(expected: []const u8, emit: anytype) !void {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try emit(&aw.writer);
    try std.testing.expectEqualStrings(expected, aw.written());
}

test "beam_emitter: register and control instructions" {
    try expectLine("    {move, {y, 2}, {x, 0}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeMoveOp(w, Operand.yr(2), Dest.xr(0));
        }
    }.f);
    try expectLine("  {label, 7}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeLabel(w, 7);
        }
    }.f);
    try expectLine("    {jump, {f, 7}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeJump(w, 7);
        }
    }.f);
    try expectLine("    return.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeReturn(w);
        }
    }.f);
    try expectLine("    {init_yregs, {list, [{y, 0}, {y, 1}]}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeInitYregs(w, 2);
        }
    }.f);
}

test "beam_emitter: tests, bifs and calls" {
    try expectLine("    {test, is_eq, {f, 3}, [{x, 0}, {atom, true}]}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeTest(w, .is_eq, 3, &.{ Operand.xr(0), Operand.atom("true") });
        }
    }.f);
    try expectLine("    {test, is_tagged_tuple, {f, 3}, [{x, 0}, 2, {atom, ok}]}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeTest(w, .is_tagged_tuple, 3, &.{ Operand.xr(0), .{ .untagged = 2 }, Operand.atom("ok") });
        }
    }.f);
    try expectLine("    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {integer, 1}], {x, 0}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeGcBif(w, .add, 2, &.{ Operand.xr(1), Operand.int(1) }, Dest.xr(0));
        }
    }.f);
    try expectLine("    {gc_bif, '/', {f, 0}, 0, [{y, 1}, {y, 2}], {x, 0}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeGcBif(w, .fdiv, 0, &.{ Operand.yr(1), Operand.yr(2) }, Dest.xr(0));
        }
    }.f);
    try expectLine("    {call_last, 2, {f, 5}, 3}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeCall(w, .last, 2, .{ .local = 5 }, 3);
        }
    }.f);
    try expectLine("    {call_ext, 2, {extfunc, io, format, 2}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeCall(w, .normal, 2, .{ .ext = .{ .module = "io", .function = "format" } }, 0);
        }
    }.f);
    // A mangled name arrives pre-quoted and passes straight through.
    try expectLine("    {call_ext, 1, {extfunc, http, 'Response_ok', 1}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeCall(w, .normal, 1, .{ .ext = .{ .module = "http", .function = "'Response_ok'" } }, 0);
        }
    }.f);
}

test "beam_emitter: module preamble" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeModuleForm(&aw.writer, "main");
    try writeExports(&aw.writer, &.{
        .{ .name = "'_botopink_main'", .arity = 0 },
        .{ .name = "main", .arity = 1 },
        .{ .name = "Counter_inc", .arity = 1 },
    });
    try writeAttributes(&aw.writer);
    try writeLabels(&aw.writer, 12);
    try std.testing.expectEqualStrings(
        \\{module, main}.
        \\{exports, [{'_botopink_main', 0}, {main, 1}, {'Counter_inc', 1}]}.
        \\{attributes, []}.
        \\{labels, 12}.
        \\
    , aw.written());
}

test "beam_emitter: aggregate instructions" {
    try expectLine("    {put_list, {x, 1}, nil, {x, 1}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writePutList(w, Operand.xr(1), Operand.nil, Dest.xr(1));
        }
    }.f);
    try expectLine("    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 2}]}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writePutTuple2(w, Dest.xr(0), &.{ Operand.atom("ok"), Operand.xr(2) });
        }
    }.f);
    try expectLine("    {get_map_elements, {f, 8}, {x, 0}, {list, [{atom, body}, {x, 0}]}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writeGetMapElements(w, 8, Operand.xr(0), "body", Dest.xr(0));
        }
    }.f);
    try expectLine("    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 3, {list, [{atom, x}, {x, 1}]}}.\n", struct {
        fn f(w: *Writer) Error!void {
            try writePutMap(w, false, .{ .term = Term.mapOf(&.{}) }, Dest.xr(0), 3, &.{
                .{ .key = Operand.atom("x"), .value = Operand.xr(1) },
            });
        }
    }.f);
}
