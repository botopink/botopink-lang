//! WebAssembly-text code model — the nodes `wat_emitter.zig` renders.
//!
//! `codegen/wat.zig` lowers botopink into these nodes and never writes target
//! text; the s-expression layout, identifier spelling and data-segment escaping
//! all live in the emitter. The split mirrors `codegen/beam/erl_ast.zig` +
//! `erl_emitter.zig` on the Erlang side.
//!
//! The shape exists to make the five defects the previous wave had to fix as
//! *text* unrepresentable:
//!
//!   1. **`(local …)` in the middle of a body** — there is no local-declaration
//!      instruction. Locals belong to `Func.locals`, which the emitter writes
//!      between the signature and the first instruction.
//!   2. **A value left on the stack** — every `Seq` carries the `Stack` it
//!      leaves behind, and `Builder.func` refuses a body whose stack disagrees
//!      with the declared `(result …)`. The same check runs on every `If` arm.
//!   3. **`(param $ i32)`** — `Param.name` is checked non-empty when the node is
//!      built; an unnamed parameter cannot be constructed.
//!   4. **A `call` to a function the module never defines** — every `call` is
//!      checked against the module's own functions and imports before a single
//!      byte is written, and
//!      the runtime helpers can only be *named* through `Builder.helper`, which
//!      marks the helper for emission in the same act.
//!   5. **A specialised function with no result type** — same check as (2): a
//!      body whose stack is `.value` cannot go into a `Func` with `result` null.
//!
//! Layout is part of the model where the output depends on it (as in
//! `erl_ast.zig`): a `Line` carries the column it is written at, an `If.Arm`
//! chooses between the block and the one-line folded form, and `Func.locals` is
//! a list of *lines* so a hand-tuned helper can group several declarations.
//!
//! Nodes borrow their slices: build them in an arena that outlives rendering.

const std = @import("std");

// ── types ────────────────────────────────────────────────────────────────────

pub const ValType = enum {
    i32,
    i64,
    f32,
    f64,

    pub fn text(t: ValType) []const u8 {
        return @tagName(t);
    }

    /// The value type spelled `s` (`"i32"`, `"f64"`, …). `i32` for anything
    /// else — wat codegen is untyped and recovers types by best effort, and
    /// `i32` is its pointer/integer carrier.
    pub fn parse(s: []const u8) ValType {
        if (std.mem.eql(u8, s, "i64")) return .i64;
        if (std.mem.eql(u8, s, "f32")) return .f32;
        if (std.mem.eql(u8, s, "f64")) return .f64;
        return .i32;
    }
};

/// What an instruction sequence leaves on the operand stack.
///   * `.none`       — nothing was pushed (a void call, a store, a binding).
///   * `.value`      — exactly one value, of this type.
///   * `.terminated` — control left the block (`return` / `unreachable` / an
///                     unconditional `br`), so the stack is polymorphic.
pub const Stack = union(enum) {
    none,
    value: ValType,
    terminated,

    /// Whether a sequence with this stack can fill a `(result want)` — `null`
    /// meaning no result at all.
    pub fn fits(self: Stack, want: ?ValType) bool {
        return switch (self) {
            .terminated => true,
            .none => want == null,
            .value => |t| want != null and want.? == t,
        };
    }
};

// ── instructions ─────────────────────────────────────────────────────────────

/// The access width of a load/store. `.byte` is `…8_u` (load) / `…8` (store);
/// there is no signed byte load in this backend.
pub const Width = enum { full, byte };

/// The immediate of a memory access. `align=` is never spelled — every access
/// this backend emits uses the natural alignment.
pub const MemArg = struct {
    ty: ValType = .i32,
    width: Width = .full,
    offset: u32 = 0,
};

pub const Instr = union(enum) {
    /// `<ty>.const <text>` — the literal keeps the spelling the source used, so
    /// `3.14` stays `3.14` rather than round-tripping through a float.
    @"const": Const,
    local_get: []const u8,
    local_set: []const u8,
    local_tee: []const u8,
    global_get: []const u8,
    global_set: []const u8,
    /// `<ty>.<name>` — `add`, `sub`, `div_s`, `eq`, `eqz`, `ge_u`, `neg`, …
    op: Op,
    /// A conversion opcode, already fully spelled (`f64.promote_f32`). It names
    /// both types, so it is not an `op`.
    convert: []const u8,
    load: MemArg,
    store: MemArg,
    /// `call $<func>` — the symbol must be one the module declares (see
    /// `Module.validate`).
    call: []const u8,
    /// `call_indirect (param …) (result …)` — a call through the module's
    /// function table. The table index is the last operand.
    call_indirect: FuncType,
    br: []const u8,
    br_if: []const u8,
    drop,
    @"return",
    @"unreachable",
    memory_copy,
    @"if": If,
    /// `block` / `loop`.
    block: Block,
    /// A `;; text` line of its own.
    comment: []const u8,

    pub const Const = struct { ty: ValType, text: []const u8 };
    pub const Op = struct { ty: ValType, name: []const u8 };
};

/// `(if [(result t)] (then …) [(else …)])`.
///
/// `result` is the value type both arms must leave (null for the statement
/// form). A value-form `if` must have an `else`: wasm has no implicit
/// zero-arm, and an arm that pushes nothing under a `(result …)` is exactly
/// the "values left on the stack" class of defect.
pub const If = struct {
    result: ?ValType = null,
    then: Arm,
    @"else": ?Arm = null,

    pub const Arm = struct {
        seq: Seq,
        layout: Layout = .block,

        /// `.block` — `(then` newline, the sequence's lines, `)` on its own
        /// line. `.inline_` — `(then i32.const 0 return)`, the whole arm on one
        /// line (used by the hand-tuned runtime helpers).
        pub const Layout = enum { block, inline_ };
    };
};

/// `(block $label …)` / `(loop $label …)`.
pub const Block = struct {
    kind: Kind,
    label: ?[]const u8 = null,
    result: ?ValType = null,
    body: Seq,

    pub const Kind = enum { block, loop };
};

/// One output line: an instruction, the column it is written at, and an
/// optional trailing `;; …`.
pub const Line = struct {
    instr: Instr,
    /// Column of the first character. Bodies of the runtime helpers indent
    /// their nested arms; lowered bodies keep the flat function column.
    indent: u8 = 4,
    comment: ?[]const u8 = null,
    /// Write the instruction wrapped in parentheses (`(call $main)`) — the
    /// folded s-expression form, for an instruction with no operands of its own.
    folded: bool = false,
};

/// A run of instructions plus what it leaves on the operand stack. The stack is
/// declared, not inferred: every context that consumes a sequence (a function
/// body, an `if` arm) checks it against what it can accept.
pub const Seq = struct {
    lines: []const Line = &.{},
    stack: Stack = .none,
};

// ── module items ─────────────────────────────────────────────────────────────

/// `(param $name ty)` — the name is never empty (`Builder.param` checks it, and
/// so does `Func.validate`). An anonymous parameter is a WAT parse error.
pub const Param = struct {
    name: []const u8,
    ty: ValType = .i32,
};

pub const Local = struct {
    name: []const u8,
    ty: ValType = .i32,
};

pub const Func = struct {
    /// The WAT symbol, without the leading `$`.
    name: []const u8,
    /// `(export "…")` clauses, in order. `_start` carries two.
    exports: []const []const u8 = &.{},
    params: []const Param = &.{},
    result: ?ValType = null,
    /// `(local …)` declarations, grouped into output lines. They are written
    /// between the signature and the body — there is nowhere else to put them.
    locals: []const []const Local = &.{},
    body: Seq = .{},
};

pub const Global = struct {
    name: []const u8,
    exports: []const []const u8 = &.{},
    ty: ValType,
    mutable: bool = false,
    /// The constant initialiser's numeral, as spelled: rendered
    /// `(<ty>.const <init>)`.
    init: []const u8,
};

/// `(func (param i32 i32) (result i32))` — the *type* of an imported function.
/// Its parameters have no names, which is why it is not a `Func`.
pub const FuncType = struct {
    params: []const ValType = &.{},
    result: ?ValType = null,
};

pub const Import = struct {
    module: []const u8,
    name: []const u8,
    /// Local symbol the import is bound to, without `$`.
    func: []const u8,
    type: FuncType = .{},
};

pub const Memory = struct {
    /// `(export "…")` on the memory itself.
    @"export": ?[]const u8 = null,
    min_pages: u32 = 1,
};

/// `(data (i32.const offset) "…")`. The emitter writes `len_prefix` as four
/// escaped little-endian bytes and then escapes `bytes` — the length-prefixed
/// string layout the whole backend assumes.
pub const DataSegment = struct {
    offset: u32,
    len_prefix: u32,
    bytes: []const u8,
};

/// A top-level form. The module renders its items in order, so the backend
/// owns the layout of the module (imports, memory, start, data, globals, the
/// lowered functions, the runtime helpers) and the emitter owns the text.
pub const Item = union(enum) {
    import: Import,
    memory: Memory,
    /// `(start $name)`.
    start: []const u8,
    /// `(table funcref (elem $f0 $f1 …))` — the functions a `call_indirect`
    /// can reach, by table index.
    table: []const []const u8,
    data: DataSegment,
    global: Global,
    func: Func,
    /// A `;; text` line between forms.
    comment: []const u8,
};

pub const Module = struct {
    items: []const Item = &.{},
};

// ── invariants ───────────────────────────────────────────────────────────────

pub const Invalid = error{
    /// A parameter with an empty name — `(param $ i32)` does not parse.
    UnnamedParam,
    /// A body's stack does not match the declared `(result …)`: a value left
    /// behind by a void function, or a specialised function that returns a
    /// value without declaring a result.
    ResultMismatch,
    /// An `if` arm does not produce what the `(if (result …))` promised.
    BranchMismatch,
    /// A value-form `if` with no `(else …)`.
    MissingElse,
    /// `call $x` where `x` is neither defined nor imported, or a table entry
    /// naming a function the module does not define.
    UndefinedCall,
};

pub fn validateFunc(f: Func) Invalid!void {
    for (f.params) |p| {
        if (p.name.len == 0) return error.UnnamedParam;
    }
    if (!f.body.stack.fits(f.result)) return error.ResultMismatch;
    try validateSeq(f.body);
}

fn validateSeq(s: Seq) Invalid!void {
    for (s.lines) |l| try validateInstr(l.instr);
}

fn validateInstr(i: Instr) Invalid!void {
    switch (i) {
        .@"if" => |n| {
            if (!n.then.seq.stack.fits(n.result)) return error.BranchMismatch;
            try validateSeq(n.then.seq);
            if (n.@"else") |e| {
                if (!e.seq.stack.fits(n.result)) return error.BranchMismatch;
                try validateSeq(e.seq);
            } else if (n.result != null) return error.MissingElse;
        },
        .block => |b| {
            if (!b.body.stack.fits(b.result)) return error.BranchMismatch;
            try validateSeq(b.body);
        },
        else => {},
    }
}

/// Every symbol the module can legally `call`: its own functions and its
/// imports. There is no third category — a symbol nothing defines cannot be
/// called.
pub fn declaresCall(m: Module, name: []const u8) bool {
    for (m.items) |it| switch (it) {
        .func => |f| if (std.mem.eql(u8, f.name, name)) return true,
        .import => |im| if (std.mem.eql(u8, im.func, name)) return true,
        else => {},
    };
    return false;
}

/// Check every function in the module, and that every `call` names something
/// the module declares. `wat_emitter.renderModule` runs this before writing.
pub fn validateModule(m: Module) Invalid!void {
    for (m.items) |it| switch (it) {
        .func => |f| {
            try validateFunc(f);
            try checkCalls(m, f.body);
        },
        .table => |names| for (names) |n| {
            if (!declaresCall(m, n)) return error.UndefinedCall;
        },
        else => {},
    };
}

fn checkCalls(m: Module, s: Seq) Invalid!void {
    for (s.lines) |l| switch (l.instr) {
        .call => |name| if (!declaresCall(m, name)) return error.UndefinedCall,
        .@"if" => |n| {
            try checkCalls(m, n.then.seq);
            if (n.@"else") |e| try checkCalls(m, e.seq);
        },
        .block => |b| try checkCalls(m, b.body),
        else => {},
    };
}

// ── runtime helpers ──────────────────────────────────────────────────────────

/// The functions the backend synthesises into a module to serve constructs wasm
/// has no opcode for. They come in *groups*: a group is emitted whole or not at
/// all, because its members call each other. A group that calls into another
/// group names it in `deps`.
pub const HelperGroup = enum {
    /// `$__write_bytes` `$__print_nl` `$__print_sp` `$__print_i32`
    /// `$__print_i32_raw` `$__memmove`, plus the `fd_write` import.
    print,
    /// `$__print_str_raw` `$__print_str`.
    print_str,
    /// `$__print_bool` `$__print_bool_raw`.
    print_bool,
    /// `$__print_f64` `$__print_f64_raw`.
    print_f64,
    /// `$__arr_at`.
    arr_at,
    /// `$__str_concat`.
    str_concat,
    /// `$__str_eq`.
    str_eq,
    /// `$__str_slice`.
    str_slice,
    // ── one helper per group from here on: the group is named after it ──
    alloc,
    mem_eq,
    i32_abs,
    i32_min,
    i32_max,
    i32_to_str,
    f64_to_str,
    str_case,
    str_index_of,
    str_starts_with,
    str_ends_with,
    str_trim,
    str_split,
    str_repeat,
    arr_new,
    arr_slice,
    arr_reverse,
    arr_prepend,
    arr_push,
    arr_concat,
    arr_zip,
    arr_index_of_i32,
    arr_index_of_str,
    arr_join_str,
    arr_join_i32,
    /// `$__print_arr_i32` `$__print_arr_i32_raw`.
    print_arr_i32,
    /// `$__print_arr_f32` `$__print_arr_f32_raw`.
    print_arr_f32,
    box_i32,
    arr_at_box,
    /// `$__print_undefined`, and `$__print_opt_{i32,bool,str}` (+`_raw`).
    print_opt,

    /// The groups `g`'s functions call into.
    pub fn deps(g: HelperGroup) []const HelperGroup {
        return switch (g) {
            .print_str, .print_bool, .print_f64 => &.{.print},
            .print_arr_i32 => &.{.print},
            .print_arr_f32 => &.{ .print, .print_f64 },
            .box_i32 => &.{.alloc},
            .arr_at_box => &.{.box_i32},
            .print_opt => &.{ .print, .print_bool, .print_str },
            .i32_to_str, .str_case, .str_repeat, .arr_new => &.{.alloc},
            .f64_to_str => &.{ .i32_to_str, .alloc },
            .str_index_of, .str_starts_with, .str_ends_with => &.{.mem_eq},
            .str_trim => &.{.str_slice},
            .str_split => &.{ .arr_new, .mem_eq, .str_slice },
            .arr_slice, .arr_reverse, .arr_prepend, .arr_push, .arr_concat => &.{.arr_new},
            .arr_zip => &.{ .arr_new, .alloc },
            .arr_index_of_str => &.{.str_eq},
            .arr_join_str => &.{.alloc},
            .arr_join_i32 => &.{ .arr_new, .i32_to_str, .arr_join_str },
            else => &.{},
        };
    }
};

/// A callable runtime helper. A `call` to one is only obtainable through
/// `Builder.helper`, which marks its group for emission — so the module can
/// never call a helper it does not also define. Every symbol is `__<tag>`.
pub const Helper = enum {
    write_bytes,
    print_nl,
    print_sp,
    print_i32,
    print_i32_raw,
    memmove,
    print_str,
    print_str_raw,
    print_bool,
    print_bool_raw,
    print_f64,
    print_f64_raw,
    arr_at,
    str_concat,
    str_eq,
    str_slice,
    alloc,
    mem_eq,
    i32_abs,
    i32_min,
    i32_max,
    i32_to_str,
    f64_to_str,
    str_case,
    str_index_of,
    str_starts_with,
    str_ends_with,
    str_trim,
    str_split,
    str_repeat,
    arr_new,
    arr_slice,
    arr_reverse,
    arr_prepend,
    arr_push,
    arr_concat,
    arr_zip,
    arr_index_of_i32,
    arr_index_of_str,
    arr_join_str,
    arr_join_i32,
    print_arr_i32,
    print_arr_i32_raw,
    print_arr_f32,
    print_arr_f32_raw,
    box_i32,
    arr_at_box,
    print_undefined,
    print_opt_i32,
    print_opt_i32_raw,
    print_opt_bool,
    print_opt_bool_raw,
    print_opt_str,
    print_opt_str_raw,

    pub fn symbol(h: Helper) []const u8 {
        return switch (h) {
            inline else => |t| "__" ++ @tagName(t),
        };
    }

    pub fn group(h: Helper) HelperGroup {
        return switch (h) {
            .write_bytes, .print_nl, .print_sp, .print_i32, .print_i32_raw, .memmove => .print,
            .print_str, .print_str_raw => .print_str,
            .print_bool, .print_bool_raw => .print_bool,
            .print_f64, .print_f64_raw => .print_f64,
            .print_arr_i32, .print_arr_i32_raw => .print_arr_i32,
            .print_arr_f32, .print_arr_f32_raw => .print_arr_f32,
            .print_undefined, .print_opt_i32, .print_opt_i32_raw, .print_opt_bool, .print_opt_bool_raw, .print_opt_str, .print_opt_str_raw => .print_opt,
            inline else => |t| @field(HelperGroup, @tagName(t)),
        };
    }
};

/// Which helper groups a module needs. Requiring a group requires its `deps`
/// too, so a module that calls a helper also defines everything it calls.
pub const HelperSet = struct {
    groups: std.EnumSet(HelperGroup) = .initEmpty(),

    pub fn require(self: *HelperSet, g: HelperGroup) void {
        if (self.groups.contains(g)) return;
        self.groups.insert(g);
        for (g.deps()) |d| self.require(d);
    }

    pub fn has(self: HelperSet, g: HelperGroup) bool {
        return self.groups.contains(g);
    }
};

// ── builder ──────────────────────────────────────────────────────────────────

/// Arena-backed construction: copies the slices a node borrows so a tree built
/// from runtime values outlives the frames that produced it, and enforces the
/// invariants at the moment a node is made.
pub const Builder = struct {
    arena: std.mem.Allocator,
    /// Helper groups requested so far — see `helper`.
    helpers: HelperSet = .{},

    pub const Error = std.mem.Allocator.Error;

    // ── lines ────────────────────────────────────────────────────────────

    pub fn line(instr: Instr) Line {
        return .{ .instr = instr };
    }

    pub fn lineC(instr: Instr, comment: []const u8) Line {
        return .{ .instr = instr, .comment = comment };
    }

    pub fn lineAt(indent: u8, instr: Instr) Line {
        return .{ .instr = instr, .indent = indent };
    }

    pub fn lineAtC(indent: u8, instr: Instr, comment: ?[]const u8) Line {
        return .{ .instr = instr, .indent = indent, .comment = comment };
    }

    pub fn seq(b: Builder, lines: []const Line, stack: Stack) Error!Seq {
        return .{ .lines = try b.arena.dupe(Line, lines), .stack = stack };
    }

    // ── signatures ───────────────────────────────────────────────────────

    /// `(param $name ty)`. Panics on an empty name: `(param $ i32)` is a parse
    /// error, and the caller is the one holding the fallback name.
    pub fn param(name: []const u8, ty: ValType) Param {
        std.debug.assert(name.len > 0);
        return .{ .name = name, .ty = ty };
    }

    /// One `(local …)` per output line — what lowered functions use.
    pub fn localLines(b: Builder, locals: []const Local) Error![]const []const Local {
        const lines = try b.arena.alloc([]const Local, locals.len);
        for (locals, 0..) |l, i| lines[i] = try b.arena.dupe(Local, &.{l});
        return lines;
    }

    /// Build a function, checking at the point of construction what the text
    /// never could: the parameters are named and the body leaves exactly what
    /// the signature promises.
    pub fn func(b: Builder, f: Func) (Error || Invalid)!Func {
        const out = Func{
            .name = f.name,
            .exports = try b.arena.dupe([]const u8, f.exports),
            .params = try b.arena.dupe(Param, f.params),
            .result = f.result,
            .locals = f.locals,
            .body = f.body,
        };
        try validateFunc(out);
        return out;
    }

    // ── calls ────────────────────────────────────────────────────────────

    /// `call $<helper>`, marking the helper's group for emission. This is the
    /// only way to name a runtime helper, so "used" and "defined" are one act.
    pub fn helper(b: *Builder, h: Helper) Instr {
        b.helpers.require(h.group());
        return .{ .call = h.symbol() };
    }
};
