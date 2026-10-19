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

pub const ValType = enum(u16) {
    i32,
    i64,
    f32,
    f64,
    /// Packed storage types — a GC struct field or array element only
    /// (`(array (mut i8))`, a string's bytes); never a local, a parameter or
    /// a stack value (front 164 s2, decision 544).
    i8,
    i16,
    /// The abstract reference types (WasmGC, decision 544), every one
    /// nullable: `anyref` (an `unknown`), `eqref`, `i31ref`, `structref`,
    /// `arrayref`, `funcref`, `externref`.
    anyref,
    eqref,
    i31ref,
    structref,
    arrayref,
    funcref,
    externref,
    /// `(ref null $t)` — a nullable reference to the module's type `t`
    /// (`def(k)`: the `k`-th type of the module's `(rec …)` group, `Item.types`).
    _,

    /// The first value a `def(k)` takes.
    pub const def_base: u16 = 64;

    /// `(ref null $t)` for the `k`-th type the module declares.
    pub fn def(k: u16) ValType {
        return @enumFromInt(def_base + k);
    }

    /// The index of the module type a `(ref null $t)` names, null for every
    /// other value type.
    pub fn defIndex(t: ValType) ?u16 {
        const n = @intFromEnum(t);
        return if (n >= def_base) n - def_base else null;
    }

    /// Whether `t` is a reference (abstract or to a module type).
    pub fn isRef(t: ValType) bool {
        return switch (t) {
            .i32, .i64, .f32, .f64, .i8, .i16 => false,
            else => true,
        };
    }

    /// Whether `t` is a packed storage type (`i8` / `i16`).
    pub fn isPacked(t: ValType) bool {
        return t == .i8 or t == .i16;
    }

    /// The spelling of a value type that names no module type. A
    /// `(ref null $t)` needs the module's type names: `wat_emitter.zig`
    /// spells it with them (`typeText`).
    pub fn text(t: ValType) []const u8 {
        return switch (t) {
            .i32 => "i32",
            .i64 => "i64",
            .f32 => "f32",
            .f64 => "f64",
            .i8 => "i8",
            .i16 => "i16",
            .anyref => "anyref",
            .eqref => "eqref",
            .i31ref => "i31ref",
            .structref => "structref",
            .arrayref => "arrayref",
            .funcref => "funcref",
            .externref => "externref",
            _ => "ref",
        };
    }

    /// The heap type a reference type points into, spelled for `ref.null`
    /// / `ref.test` (`any`, `eq`, …); null for a module type and a number.
    pub fn heapText(t: ValType) ?[]const u8 {
        return switch (t) {
            .anyref => "any",
            .eqref => "eq",
            .i31ref => "i31",
            .structref => "struct",
            .arrayref => "array",
            .funcref => "func",
            .externref => "extern",
            else => null,
        };
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

// ── GC types (WasmGC, decision 544) ──────────────────────────────────────────

/// One field of a GC struct, or the element of a GC array: its storage type
/// (a value type, or packed `i8` / `i16`) and whether it can be set.
pub const Field = struct {
    /// `(field $name …)` — a struct field's name, for the text; the binary
    /// addresses it by index.
    name: ?[]const u8 = null,
    ty: ValType,
    mutable: bool = false,
};

/// `(type $name (struct …))` / `(type $name (array …))` — a type of the
/// module's one `(rec …)` group (`Item.types`). Every type is final and
/// declares no supertype; the group makes two types of the same structure
/// two distinct types (`ref.test` tells them apart).
pub const TypeDef = struct {
    name: []const u8,
    kind: Kind,
    /// The type this one is a subtype of (`(sub $super …)`): an earlier
    /// type of the group.
    super: ?u16 = null,
    /// Whether no type may name this one its supertype; a type declared
    /// without `sub` is final.
    final: bool = true,

    pub const Kind = union(enum) {
        @"struct": []const Field,
        array: Field,
    };
};

/// A struct field addressed by an instruction: the struct type and the
/// field's index; `ext` the sign extension a packed field's read takes.
pub const FieldRef = struct {
    ty: u16,
    field: u32,
    ext: Ext = .none,
};

/// A packed read's extension: `none` for an unpacked field (`struct.get`),
/// `s` / `u` for `…_s` / `…_u`.
pub const Ext = enum { none, s, u };

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

/// The access width of a load/store: the value type's own, or 8 / 16 / 32
/// bits (`…8_u` / `…16_u` / `…32_u` on a load, `…8` / `…16` / `…32` on a
/// store). The lowering only writes `.full` and `.byte`; the narrower ones
/// and a signed load are std-wasm's code, decoded (decision 440 (2)).
pub const Width = enum {
    full,
    byte,
    half,
    word,

    /// The bits a narrow access moves, null for `.full`.
    pub fn bits(w: Width) ?u8 {
        return switch (w) {
            .full => null,
            .byte => 8,
            .half => 16,
            .word => 32,
        };
    }
};

/// The immediate of a memory access. `align=` is never spelled — every access
/// takes the natural alignment of its width (an alignment is a hint; a
/// narrower one is never needed for the access to be valid).
pub const MemArg = struct {
    ty: ValType = .i32,
    width: Width = .full,
    /// A narrow load that sign-extends (`…_s`); `…_u` otherwise.
    signed: bool = false,
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
    /// `memory.fill` — `dst`, `byte`, `len` (bulk memory, as `memory_copy`).
    memory_fill,
    /// `select` — the first operand if the third is non-zero, else the second.
    select,
    /// `br_table` — the label the popped index picks, `default` past the end.
    br_table: BrTable,
    /// `memory.size` — the memory's size in 64 KiB pages (decision 261).
    memory_size,
    /// `memory.grow` — grow by the popped page count; answers the old size,
    /// or `-1` when the host refuses (decision 261).
    memory_grow,
    /// `throw $<tag>` — raise the module's exception tag with the operands
    /// its parameters take (wasm exception handling, decision 518).
    throw: []const u8,
    @"if": If,
    /// `block` / `loop` / `try_table`.
    block: Block,
    /// A `;; text` line of its own.
    comment: []const u8,

    // ── GC (WasmGC, decision 544) — every type an index into `Item.types` ──
    /// `struct.new $t` — the fields from the stack, in order.
    struct_new: u16,
    /// `struct.new_default $t` — every field zero / null.
    struct_new_default: u16,
    /// `struct.get[_s|_u] $t $f`.
    struct_get: FieldRef,
    /// `struct.set $t $f`.
    struct_set: FieldRef,
    /// `array.new $t` — `(init, len)`.
    array_new: u16,
    /// `array.new_default $t` — `(len)`.
    array_new_default: u16,
    /// `array.new_fixed $t n` — the `n` elements from the stack.
    array_new_fixed: ArrayFixed,
    /// `array.new_data $t $seg` — `(offset, len)` into a passive segment.
    array_new_data: ArrayData,
    /// `array.get[_s|_u] $t` — `(array, index)`.
    array_get: ArrayGet,
    /// `array.set $t` — `(array, index, value)`.
    array_set: u16,
    /// `array.len` — `(array)`.
    array_len,
    /// `array.copy $dst $src` — `(dst, dst_off, src, src_off, len)`.
    array_copy: ArrayCopy,
    /// `array.fill $t` — `(array, offset, value, len)`.
    array_fill: u16,
    /// `ref.null <heap>` — `heap` an abstract reference type or `def(k)`.
    ref_null: ValType,
    ref_is_null,
    /// `ref.eq` — two `eqref`s, the same object (or both null).
    ref_eq,
    ref_as_non_null,
    /// `ref.test (ref null <heap>)` — `1` when the reference is of the type
    /// (a null passes).
    ref_test: ValType,
    /// `ref.cast (ref null <heap>)` — the reference as the type, a trap
    /// when it is of another.
    ref_cast: ValType,
    /// `ref.i31` — an `i32`'s low 31 bits as an `i31ref`.
    ref_i31,
    /// `i31.get_s` (true) / `i31.get_u` (false).
    i31_get: bool,

    pub const ArrayFixed = struct { ty: u16, n: u32 };
    pub const ArrayData = struct { ty: u16, data: []const u8 };
    pub const ArrayGet = struct { ty: u16, ext: Ext = .none };
    pub const ArrayCopy = struct { dst: u16, src: u16 };

    pub const Const = struct { ty: ValType, text: []const u8 };
    pub const Op = struct { ty: ValType, name: []const u8 };
    pub const BrTable = struct { labels: []const []const u8, default: []const u8 };
};

/// `(if [(result t)] (then …) [(else …)])`.
///
/// `result` is the value type both arms must leave (null for the statement
/// form). A value-form `if` must have an `else`: wasm has no implicit
/// zero-arm, and an arm that pushes nothing under a `(result …)` is exactly
/// the "values left on the stack" class of defect.
pub const If = struct {
    /// `(if $label …)` — the name a branch out of the `if` uses. The lowering
    /// never branches out of an `if`; decoded code may.
    label: ?[]const u8 = null,
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

/// `(block $label …)` / `(loop $label …)` / `(try_table … (catch $tag $l) …)`.
pub const Block = struct {
    kind: Kind,
    label: ?[]const u8 = null,
    result: ?ValType = null,
    /// A `try_table`'s catch clauses (decision 518): an exception of `tag`
    /// raised in the body branches to `label` with the tag's values. Their
    /// labels are the try_table's surroundings', never its own.
    catches: []const Catch = &.{},
    body: Seq,

    pub const Kind = enum { block, loop, try_table };
    pub const Catch = struct { tag: []const u8, label: []const u8 };
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
    /// The most pages it may grow to (`memory.grow` past it answers `-1`);
    /// none, the engine's limit.
    max_pages: ?u32 = null,
};

/// `(data (i32.const offset) "…")`. The emitter writes `len_prefix` as four
/// escaped little-endian bytes and then escapes `bytes` — the length-prefixed
/// string layout the whole backend assumes. A segment with no prefix (`null`)
/// is raw bytes: std-wasm's data, placed where its code reads it (decision
/// 440 (2)).
pub const DataSegment = struct {
    offset: u32,
    len_prefix: ?u32,
    bytes: []const u8,
    /// A passive segment's name (`(data $name "…")`): no offset, never in
    /// memory — the bytes an `array.new_data` reads (a string literal, WasmGC).
    passive: ?[]const u8 = null,
};

/// A top-level form. The module renders its items in order, so the backend
/// owns the layout of the module (imports, memory, start, data, globals, the
/// lowered functions, the runtime helpers) and the emitter owns the text.
pub const Item = union(enum) {
    /// `(rec (type $a …) (type $b …) …)` — the module's GC types, one group
    /// (decision 544); at most one per module, before any other item that
    /// names one. `ValType.def(k)` and every GC instruction's type is an
    /// index into it.
    types: []const TypeDef,
    import: Import,
    memory: Memory,
    /// `(tag $name (param …))` — an exception tag (decision 518).
    tag: Tag,
    /// `(@custom "name" "…")` — a custom section; the binary writes it after
    /// every other section (decision 518's `botopink.needs`).
    custom: Custom,
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

/// An exception tag: its symbol, without `$`, and the values it carries.
pub const Tag = struct {
    name: []const u8,
    params: []const ValType = &.{},
};

/// A custom section: its name and its bytes.
pub const Custom = struct {
    name: []const u8,
    bytes: []const u8,
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
    /// A `throw` or a `catch` naming a tag the module does not declare.
    UndefinedTag,
    /// A GC instruction or a value type naming a type index past the
    /// module's `(rec …)` group, or a struct field past its type's fields; a
    /// struct instruction on an array type or the reverse.
    UndefinedType,
    /// An `array.new_data` naming no passive data segment.
    UndefinedData,
    /// A packed storage type (`i8` / `i16`) outside a field.
    PackedValue,
};

/// The export name a host calls a module's start function by (decision 334).
pub const host_init_export = "__bp_init";

/// Decision 334 — the module as a host runs it: its `(start …)` dropped and
/// the start function exported as `host_init_export`. A start function runs
/// while the module is instantiated, before the host can hand its imports
/// the module's memory (the `wasi` component's preview 1 adapter, the
/// `browser` loader's `fd_write`); the host calls it once the instance
/// exists, then `_start`. A module with no start comes back unchanged.
/// `items` is allocated in `alloc` (an arena: the exports list too).
pub fn startAsExport(alloc: std.mem.Allocator, m: Module) std.mem.Allocator.Error!Module {
    var start: ?[]const u8 = null;
    for (m.items) |it| if (it == .start) {
        start = it.start;
    };
    const name = start orelse return m;
    var items: std.ArrayListUnmanaged(Item) = .empty;
    for (m.items) |it| switch (it) {
        .start => {},
        .func => |f| if (std.mem.eql(u8, f.name, name)) {
            var named = f;
            named.exports = try std.mem.concat(alloc, []const u8, &.{ f.exports, &.{host_init_export} });
            try items.append(alloc, .{ .func = named });
        } else try items.append(alloc, it),
        else => try items.append(alloc, it),
    };
    return .{ .items = try items.toOwnedSlice(alloc) };
}

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
    const defs = typesOf(m);
    for (defs, 0..) |d, i| {
        switch (d.kind) {
            .@"struct" => |fields| for (fields) |f| try checkStorage(defs, f.ty),
            .array => |f| try checkStorage(defs, f.ty),
        }
        // A supertype is an earlier type of the group, and not final.
        if (d.super) |k| if (k >= i or defs[k].final) return error.UndefinedType;
    }
    for (m.items) |it| switch (it) {
        .func => |f| {
            try validateFunc(f);
            try checkCalls(m, f.body);
            for (f.params) |p| try checkValue(defs, p.ty);
            if (f.result) |r| try checkValue(defs, r);
            for (f.locals) |group| for (group) |l| try checkValue(defs, l.ty);
            try checkGc(m, defs, f.body);
        },
        .table => |names| for (names) |n| {
            if (!declaresCall(m, n)) return error.UndefinedCall;
        },
        .global => |g| try checkValue(defs, g.ty),
        .import => |im| {
            for (im.type.params) |p| try checkValue(defs, p);
            if (im.type.result) |r| try checkValue(defs, r);
        },
        else => {},
    };
}

/// The module's GC types — its `(rec …)` group — or none.
pub fn typesOf(m: Module) []const TypeDef {
    for (m.items) |it| switch (it) {
        .types => |t| return t,
        else => {},
    };
    return &.{};
}

/// A value a local, a parameter, a result, a global or a block holds: no
/// packed type, and a module type the group declares.
fn checkValue(defs: []const TypeDef, t: ValType) Invalid!void {
    if (t.isPacked()) return error.PackedValue;
    try checkStorage(defs, t);
}

fn checkStorage(defs: []const TypeDef, t: ValType) Invalid!void {
    if (t.defIndex()) |k| if (k >= defs.len) return error.UndefinedType;
}

fn structFields(defs: []const TypeDef, k: u16) Invalid![]const Field {
    if (k >= defs.len) return error.UndefinedType;
    return switch (defs[k].kind) {
        .@"struct" => |f| f,
        .array => error.UndefinedType,
    };
}

fn arrayElem(defs: []const TypeDef, k: u16) Invalid!Field {
    if (k >= defs.len) return error.UndefinedType;
    return switch (defs[k].kind) {
        .array => |f| f,
        .@"struct" => error.UndefinedType,
    };
}

/// Whether the module declares a passive data segment `name`.
pub fn declaresData(m: Module, name: []const u8) bool {
    for (m.items) |it| switch (it) {
        .data => |d| if (d.passive) |n| if (std.mem.eql(u8, n, name)) return true,
        else => {},
    };
    return false;
}

fn checkGc(m: Module, defs: []const TypeDef, s: Seq) Invalid!void {
    for (s.lines) |l| switch (l.instr) {
        .struct_new, .struct_new_default => |k| _ = try structFields(defs, k),
        .struct_get, .struct_set => |r| {
            const fields = try structFields(defs, r.ty);
            if (r.field >= fields.len) return error.UndefinedType;
        },
        .array_new, .array_new_default, .array_set, .array_fill => |k| _ = try arrayElem(defs, k),
        .array_new_fixed => |a| _ = try arrayElem(defs, a.ty),
        .array_get => |a| _ = try arrayElem(defs, a.ty),
        .array_copy => |a| {
            _ = try arrayElem(defs, a.dst);
            _ = try arrayElem(defs, a.src);
        },
        .array_new_data => |a| {
            _ = try arrayElem(defs, a.ty);
            if (!declaresData(m, a.data)) return error.UndefinedData;
        },
        .ref_null, .ref_test, .ref_cast => |t| try checkValue(defs, t),
        .@"if" => |n| {
            if (n.result) |r| try checkValue(defs, r);
            try checkGc(m, defs, n.then.seq);
            if (n.@"else") |e| try checkGc(m, defs, e.seq);
        },
        .block => |b| {
            if (b.result) |r| try checkValue(defs, r);
            try checkGc(m, defs, b.body);
        },
        .call_indirect => |t| {
            for (t.params) |p| try checkValue(defs, p);
            if (t.result) |r| try checkValue(defs, r);
        },
        else => {},
    };
}

/// Whether the module declares the exception tag `name`.
pub fn declaresTag(m: Module, name: []const u8) bool {
    for (m.items) |it| switch (it) {
        .tag => |t| if (std.mem.eql(u8, t.name, name)) return true,
        else => {},
    };
    return false;
}

fn checkCalls(m: Module, s: Seq) Invalid!void {
    for (s.lines) |l| switch (l.instr) {
        .call => |name| if (!declaresCall(m, name)) return error.UndefinedCall,
        .throw => |name| if (!declaresTag(m, name)) return error.UndefinedTag,
        .@"if" => |n| {
            try checkCalls(m, n.then.seq);
            if (n.@"else") |e| try checkCalls(m, e.seq);
        },
        .block => |b| {
            for (b.catches) |c| if (!declaresTag(m, c.tag)) return error.UndefinedTag;
            try checkCalls(m, b.body);
        },
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
    // ── one helper per group from here on: the group is named after it ──
    alloc,
    i32_abs,
    i32_min,
    i32_max,
    arr_new,
    arr_push,
    /// `$__print_arr_i32` `$__print_arr_i32_raw`.
    print_arr_i32,
    /// `$__print_arr_f64` `$__print_arr_f64_raw`.
    print_arr_f64,
    box_i32,
    arr_at_box,
    /// `$__print_null`, and `$__print_opt_{i32,bool,str}` (+`_raw`).
    print_opt,
    /// `$__print_opt_f64` (+`_raw`) — a `?f64`, the address of an `f64` cell.
    /// Its own group and not part of `print_opt`, so a module that prints a
    /// plain optional renders exactly as it did before this existed.
    print_opt_f64,
    /// `$__write_err` `$__assert_fail`.
    assert_fail,
    /// `$__panic_fail`: a `@panic`'s message on stderr (needs `assert_fail`'s `$__write_err`).
    panic_fail,
    /// `$__print_quoted_raw` `$__print_shaped_raw` `$__print_tagged_raw`
    /// `$__print_tagged` — arrays of strings, tuples and arrays of tuples
    /// (semantics decision 1a), and the value that carries its own declaration
    /// (decision 8 §7, 13-module-identity half 3). One group: the shape walker
    /// has a `T` arm that calls the tagged printer, and the tagged printer
    /// prints each field by its shape, so neither is complete without the
    /// other.
    print_shaped,
    /// `$__print_opt_tagged` (+`_raw`) — a `?T` whose `T` is a record. The
    /// tagged printer reads a header four bytes behind the value, so absence
    /// has to be answered before it is called. Last in declaration order, so
    /// every module that does not call it renders exactly as before it existed.
    print_opt_tagged,
    /// `$__display_of(v) -> i32` — the hook `$__print_tagged_raw` asks first:
    /// the string a value's own `display(self) -> string` answers, or `0`. The
    /// prelude's form answers `0` for every value; `wat.zig` substitutes the
    /// module's own dispatch (one descriptor compare per type declaring
    /// `display`), so the group renders alone and a module gets its answer.
    display_of,
    /// The readers of decision 8 §11's box — a value in an `unknown` or union
    /// slot: `$__unknown_kind`, `$__unknown_int_in`, `$__unknown_as_i32`,
    /// `$__unknown_as_f64`, `$__unknown_eq`.
    unknown,
    /// `$__print_unknown` (+`_raw`) — such a value printed by what it holds.
    print_unknown,
    /// `$__wasi_random_f64()` — decision 238's `wasi:random_f64`, plus the
    /// `random_get` import.
    wasi_random_f64,
    /// `$__box_f64(x)` — a float's 8-byte cell, the word a float slot holds.
    box_f64,
    /// `$__print_i64` (+`_raw`) — an `i64` in all its digits (std-wasm's
    /// `number.i64Text`).
    print_i64,
    /// `$__box_i64(v)` — an `i64`'s 8-byte cell, the word an `i64` slot holds.
    box_i64,
    /// `$__print_opt_i64` (+`_raw`) — a `?i64`, the address of its cell.
    print_opt_i64,
    /// `$__i32_{add,sub,mul}_chk` / `$__i64_…_chk` — integer arithmetic that
    /// traps where the result does not fit its type, instead of wrapping.
    int_chk,
    /// `$__i32_range_chk(v, lo, hi)` / `$__i64_range_chk` — decision 264's
    /// check of a type narrower than its carrier (`i8` in an `i32`, `u32` in
    /// an `i64`): `v` inside `lo..=hi`, a trap outside. Groups of their own,
    /// so a module that never asks for one renders as before.
    i32_range_chk,
    i64_range_chk,
    /// Decision 319 — a `u64` / `usize` is `0 … 2^64 − 1` in its `i64`
    /// carrier: `$__print_u64` (+`_raw`) writes the carrier's bits as
    /// unsigned digits (std-wasm's `number.u64Text`), and
    /// `$__u64_{add,sub,mul}_chk` trap where the unsigned result leaves the
    /// range.
    print_u64,
    u64_chk,
    /// `$__print_opt_u64` (+`_raw`) — a `?u64`, the address of its cell,
    /// written through `$__print_u64_raw`. Appended, as the `u64` groups.
    print_opt_u64,
    /// Decision 392 — the scheduler a `@Task<T>` runs on: the task record
    /// (`$__task_new`, `$__task_start`, `$__task_pending`, `$__task_listen`,
    /// `$__task_wait`), settling once and waking what waits
    /// (`$__task_settle_{i32,i64,f64}`, `$__task_wake`), the ready queue
    /// (`$__task_enqueue`, `$__task_drain`), an `await` outside a state
    /// machine (`$__task_block_on`) and the end of `_start` (`$__task_finish`).
    task,
    /// `$__task_resume(t)` — the step of the asynchronous function a task
    /// runs. The prelude's form traps; `wat.zig` substitutes the module's own
    /// dispatch over its state machines (one `kind` per function).
    task_resume,
    /// `$__task_host_poll() -> i32` — waits for the host tasks pending and
    /// settles the ready ones, `1` when it waited. The prelude's form answers
    /// `0` (nothing to wait on — the `browser` host waits in its loader);
    /// `wat.zig` substitutes `wasi:io/poll`'s when the module has host tasks.
    task_poll,
    /// The host tasks pending (`$__task_host_add`, `$__task_host_settle`).
    task_host,
    /// `$__task_delay(ms, v)` — decision 393's `wasi:delay`.
    task_delay,
    /// `$__task_race(xs)` — `wasi:race`, the first task to settle.
    task_race,
    /// `$__task_race_of(fs)` — `wasi:race_of`, each thunk started, then raced.
    task_race_of,
    /// `$__task_spawn_all(fs)` — `wasi:spawn_all`, the answers in input order.
    task_spawn_all,
    /// Decision 332 — `bigint`, an integer of any size: a pointer to an
    /// immutable `[L][limb0][limb1]…` block, `L` the limbs' byte count
    /// negated for a negative value (`0` is zero) — a positive literal is a
    /// data segment of the string layout. Its arithmetic is std-wasm's
    /// (`bigint.*`, decision 442 (2)), called by the codegen with the blocks'
    /// addresses; this group holds no function: it marks a module that prints
    /// a `bigint` inside a container, which gets `print_shaped_raw_bigint` and
    /// links `bigint.toString` (`stdCalls`).
    bigint,
    /// Decision 150 — marks a module that prints a union (or `unknown`)
    /// inside a container by the `U` shape code: it gets a
    /// `$__print_shaped_raw` with the `U` arm (`print_shaped_raw_unknown`).
    /// It holds no function of its own.
    print_shaped_unknown,
    /// Decision 334 — std's `async` gates as pending tasks:
    /// `$__task_gate_new`, `$__task_gate_open`, `$__task_gate_await` and
    /// `$__task_host_cancel` (a wait's timer dropped when its gate opens).
    task_gate,
    /// A value's text as a string (docs § What `@print` writes): `$__cap_begin`
    /// points `$__write_bytes` at a fresh string, the value is printed, and
    /// `$__cap_end` answers what was written — a template hole of an enum.
    /// A module holding it gets the capturing `$__write_bytes`
    /// (`print_items_capture`).
    text_capture,
    /// Decision 518 — `$__panic_raise(msg, print)`: an abort raised as the
    /// module's exception tag `$__bp_panic` (`wat_prelude.panic_tag`) when
    /// the program reaches a binding that `needs: [.Exceptions]`, so
    /// `attempt` can catch it; uncaught, the entry writes what `@panic`
    /// writes and traps.
    panic_raise,
    /// Decision 518 — `wasi:attempt`, `$__wasi_attempt(f)`: the thunk `f`
    /// called inside a `try_table` catching `$__bp_panic` — `Ok` of its value
    /// or `Error` of the abort's message.
    wasi_attempt,
    /// Front 164 s2 (decision 544) — a WasmGC module's strings across the
    /// std-wasm boundary: `$__gc_to_lin_str(s)` copies a GC string into the
    /// linear memory std-wasm reads (the marshal arena, `$__alloc`'s), and
    /// `$__lin_to_gc_str(p)` a string std-wasm answered into a GC one.
    std_marshal,
    /// Decision 527 (3) — `$__chk_fail(site)`: the abort of a checked integer
    /// operation (an overflow, a division by zero), `site` the message the
    /// call site names (the operator, the type, `file:line:col`). Raised as
    /// `$__bp_panic` when the program reaches `attempt` (`panic_raise`), else
    /// written as `panic: <message>` and trapped (`panic_fail`); the emitter
    /// requires the one the module's `exceptions` asks for.
    chk_fail,
    /// `$__i32_nz(b, site)` / `$__i64_nz` — an integer divisor, answered back
    /// when it is not zero and `$__chk_fail(site)` when it is; `$__i32_divs(a, b,
    /// site, osite)` / `$__i64_divs` a signed quotient, `osite` the abort of `MIN / -1`.
    nz_chk,
    /// Front 164 s3 P2-e (decision 585 (i)) — `$__random_state`, the mutable
    /// `i64` global the seeded stream of std-wasm's `random.*` leaves keeps its
    /// word in. It holds no function: a leaf names the global as it names a
    /// type, and a module that calls such a leaf gets it declared.
    random_state,

    /// The groups `g`'s functions call into.
    pub fn deps(g: HelperGroup) []const HelperGroup {
        return switch (g) {
            .print_str, .print_bool => &.{.print},
            .str_concat => &.{.alloc},
            .print_f64 => &.{.print},
            .box_f64 => &.{.alloc},
            .print_i64 => &.{.print},
            .box_i64 => &.{.alloc},
            .print_opt_i64 => &.{ .print, .print_opt, .print_i64 },
            .print_arr_i32 => &.{.print},
            .print_arr_f64 => &.{ .print, .print_f64 },
            .box_i32 => &.{.alloc},
            .arr_at_box => &.{.box_i32},
            .print_opt => &.{ .print, .print_bool, .print_str },
            .print_opt_f64 => &.{ .print, .print_f64, .print_opt },
            .print_opt_tagged => &.{ .print, .print_opt, .print_shaped },
            .assert_fail => &.{.print},
            .panic_fail => &.{.assert_fail},
            .print_shaped => &.{ .print, .print_bool, .print_f64, .print_i64, .print_u64, .display_of },
            .arr_new => &.{.alloc},
            .arr_push => &.{.arr_new},
            .unknown => &.{.str_eq},
            .print_unknown => &.{ .print, .print_bool, .print_f64, .print_str, .print_opt, .print_shaped, .unknown },
            .print_shaped_unknown => &.{.print_unknown},
            .print_u64 => &.{.print},
            .print_opt_u64 => &.{ .print, .print_opt, .print_u64 },
            .task => &.{ .alloc, .task_resume, .task_poll },
            .task_host => &.{.task},
            .task_delay => &.{.task_host},
            .task_race => &.{.task},
            .task_race_of => &.{ .task_race, .arr_new },
            .task_spawn_all => &.{ .task, .arr_new },
            .task_gate => &.{.task_delay},
            .text_capture => &.{ .print, .alloc },
            .panic_raise => &.{.alloc},
            .wasi_attempt => &.{.alloc},
            .std_marshal => &.{.alloc},
            .int_chk, .u64_chk, .i32_range_chk, .i64_range_chk, .nz_chk => &.{.chk_fail},
            .chk_fail => &.{.panic_fail},
            else => &.{},
        };
    }

    /// The std-wasm functions `g`'s functions call (decision 442 (1)): the
    /// text of a number a print helper writes is std-wasm's, the I/O is the
    /// prelude's. A module that holds `g` links each (`std_wasm_link.zig`).
    pub fn stdCalls(g: HelperGroup) []const []const u8 {
        return switch (g) {
            .print_f64 => &.{"number.floatToString"},
            .print_i64 => &.{"number.i64Text"},
            .print_u64 => &.{"number.u64Text"},
            .bigint => &.{"bigint.toString"},
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
    alloc,
    i32_abs,
    i32_min,
    i32_max,
    arr_new,
    arr_push,
    print_arr_i32,
    print_arr_i32_raw,
    print_arr_f64,
    print_arr_f64_raw,
    box_i32,
    arr_at_box,
    print_null,
    print_opt_i32,
    print_opt_i32_raw,
    print_opt_bool,
    print_opt_bool_raw,
    print_opt_str,
    print_opt_str_raw,
    print_opt_f64,
    print_opt_f64_raw,
    write_err,
    assert_fail,
    panic_fail,
    print_quoted_raw,
    print_shaped_raw,
    print_tagged_raw,
    print_tagged,
    print_opt_tagged,
    print_opt_tagged_raw,
    display_of,
    unknown_kind,
    unknown_int_in,
    unknown_as_i32,
    unknown_as_f64,
    unknown_eq,
    print_unknown,
    print_unknown_raw,
    wasi_random_f64,
    box_f64,
    print_i64,
    print_i64_raw,
    box_i64,
    print_opt_i64,
    print_opt_i64_raw,
    i32_add_chk,
    i32_sub_chk,
    i32_mul_chk,
    i64_add_chk,
    i64_sub_chk,
    i64_mul_chk,
    i32_range_chk,
    i64_range_chk,
    print_u64,
    print_u64_raw,
    u64_add_chk,
    u64_sub_chk,
    u64_mul_chk,
    print_opt_u64,
    print_opt_u64_raw,
    task_new,
    task_start,
    task_pending,
    task_listen,
    task_wait,
    task_settle_i32,
    task_settle_i64,
    task_settle_f64,
    task_wake,
    task_enqueue,
    task_drain,
    task_block_on,
    task_finish,
    task_resume,
    task_host_poll,
    task_host_add,
    task_host_settle,
    task_delay,
    task_race,
    task_race_of,
    task_spawn_all,
    task_gate_new,
    task_gate_open,
    task_gate_await,
    task_host_cancel,
    cap_begin,
    cap_end,
    panic_raise,
    wasi_attempt,
    gc_to_lin_str,
    lin_to_gc_str,
    chk_fail,
    i32_nz,
    i64_nz,
    i32_divs,
    i64_divs,

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
            .print_arr_f64, .print_arr_f64_raw => .print_arr_f64,
            .write_err, .assert_fail => .assert_fail,
            .panic_fail => .panic_fail,
            .print_quoted_raw, .print_shaped_raw => .print_shaped,
            .print_null, .print_opt_i32, .print_opt_i32_raw, .print_opt_bool, .print_opt_bool_raw, .print_opt_str, .print_opt_str_raw => .print_opt,
            .print_opt_f64, .print_opt_f64_raw => .print_opt_f64,
            .print_i64, .print_i64_raw => .print_i64,
            .print_opt_i64, .print_opt_i64_raw => .print_opt_i64,
            .i32_add_chk, .i32_sub_chk, .i32_mul_chk, .i64_add_chk, .i64_sub_chk, .i64_mul_chk => .int_chk,
            .print_u64, .print_u64_raw => .print_u64,
            .print_opt_u64, .print_opt_u64_raw => .print_opt_u64,
            .u64_add_chk, .u64_sub_chk, .u64_mul_chk => .u64_chk,
            .print_tagged_raw, .print_tagged => .print_shaped,
            .print_opt_tagged, .print_opt_tagged_raw => .print_opt_tagged,
            .unknown_kind, .unknown_int_in, .unknown_as_i32, .unknown_as_f64, .unknown_eq => .unknown,
            .print_unknown, .print_unknown_raw => .print_unknown,
            .task_new, .task_start, .task_pending, .task_listen, .task_wait, .task_settle_i32, .task_settle_i64, .task_settle_f64, .task_wake, .task_enqueue, .task_drain, .task_block_on, .task_finish => .task,
            .task_host_poll => .task_poll,
            .task_host_add, .task_host_settle => .task_host,
            .task_gate_new, .task_gate_open, .task_gate_await, .task_host_cancel => .task_gate,
            .cap_begin, .cap_end => .text_capture,
            .gc_to_lin_str, .lin_to_gc_str => .std_marshal,
            .i32_nz, .i64_nz, .i32_divs, .i64_divs => .nz_chk,
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
