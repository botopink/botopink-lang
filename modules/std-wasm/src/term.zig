//! The Erlang terms (decision 450): the value representation a comptime
//! module (and, later, BEAM code beam-to-wasm translates) computes over — the
//! second of std-wasm's two value representations; the first is the wasm
//! codegen's typed layout (`wasm.zig`). Compiled into `std_wasm.wasm`, where
//! every `rt_*` function of this file, `term_faces.zig` and `otp/*.zig` is an
//! export of the runtime ABI (`wasm.zig`), in std-wasm's `program` side
//! (decision 454: no `std:` cell binds them); the comptime runtime links them
//! (`compiler-core/src/comptime/runtime/wat/runtime_module.zig`).
//!
//! A term is an `i32` pointer to a `Hdr`-prefixed cell (`Tag`). The shapes are
//! the Erlang ones the generated modules use: small integers (i64 — a bignum
//! raises `{bp_wat_runtime, bignum}`), floats, interned atoms, binaries (a
//! slice, never copied when it is a literal), cons cells and `[]`, tuples,
//! maps (keys kept in BEAM iteration order, see `atomRank`) and funs (a table
//! index into the caller's module, its arity and an environment tuple).
//!
//! Errors are Erlang exceptions: a BIF that raises records `{Class, Reason}`
//! in `pending` and returns `[]`; the caller's code tests `rt_pending()` after
//! every call and unwinds to its `catch` or out of `main`. The reasons are the
//! ones the BEAM gives (`badarg`, `{badkey, K}`, `badarith`, `function_clause`,
//! `{case_clause, V}`, …) so the reply a body produces does not depend on the
//! runtime that ran it.
//!
//! Nothing here allocates on its own: every cell comes from `caller.bp_term_alloc`,
//! the caller's (decision 450 (5)), and a fun is called back through the
//! caller's table (`caller.bp_call0` … `bp_call4`). The module holds no function
//! table and no pointer in its data, so `std_wasm_link.zig` decodes it.
const std = @import("std");
const builtin = @import("builtin");
const stdWasm = @import("root.zig");
const erlang = @import("otp/erlang.zig");
const lists = @import("otp/lists.zig");
const maps = @import("otp/maps.zig");
const string = @import("otp/string.zig");
const binary = @import("otp/binary.zig");
const unicode = @import("otp/unicode.zig");
const math = @import("otp/math.zig");
const io_lib = @import("otp/io_lib.zig");
const json = @import("otp/json.zig");
const etf = @import("otp/etf.zig");
const caller = @import("env.zig");

// ── cells ────────────────────────────────────────────────────────────────────

pub const Tag = enum(u8) {
    int = 1,
    float = 2,
    atom = 3,
    fun = 4,
    tuple = 5,
    map = 6,
    nil = 7,
    cons = 8,
    binary = 9,
    /// A binary under construction (`<<…>>` with non-literal segments).
    builder = 10,
};

pub const Hdr = extern struct { tag: Tag };
pub const T = *Hdr;

pub const Int = extern struct { hdr: Hdr, value: i64 };
pub const Float = extern struct { hdr: Hdr, value: f64 };
const Atom = extern struct { hdr: Hdr, len: u32, ptr: [*]const u8, next: ?*Atom, rank: u32 };
pub const Bin = extern struct { hdr: Hdr, len: u32, ptr: [*]const u8 };
pub const Cons = extern struct { hdr: Hdr, head: T, tail: T };
pub const Tuple = extern struct { hdr: Hdr, arity: u32, items: [*]T };
pub const Map = extern struct { hdr: Hdr, count: u32, keys: [*]T, vals: [*]T };
pub const Fun = extern struct { hdr: Hdr, arity: u32, index: u32, env: T };
const Builder = extern struct { hdr: Hdr, len: u32, cap: u32, ptr: [*]u8 };

pub fn tagOf(t: T) Tag {
    return t.tag;
}

pub fn as(comptime S: type, t: T) *S {
    return @ptrCast(@alignCast(t));
}

// ── allocation: the caller's ────────────────────────────────────────────────

/// `n` fresh bytes, 8-aligned (a cell holds an `i64` or an `f64`), holding no
/// term (a binary's bytes, an index table). Allocation is the caller's
/// (decision 450 (5)): on wasm the term library imports
/// `caller.bp_term_alloc(n, layout)`, which the comptime runtime binds to its
/// arena (freed whole when the evaluation ends, 449 (4)) and translated code
/// binds to the current process's heap (`heap.alloc`, 449 (3)) — the layout
/// names the words a collection treats as terms (`cellLayout`); natively (the
/// unit tests) a page arena.
pub fn alloc(n: usize) [*]u8 {
    return allocAs(n, stdWasm.heap.raw);
}

/// `n` fresh bytes of `layout` (a `heap.zig` layout).
fn allocAs(n: usize, layout: u32) [*]u8 {
    const size = std.mem.alignForward(usize, n, 8);
    if (builtin.cpu.arch.isWasm()) return @ptrFromInt(caller.bp_term_alloc(@intCast(size), layout));
    return (native_arena.allocator().alignedAlloc(u8, .@"8", @max(size, 8)) catch @panic("term: out of memory")).ptr;
}

/// `n` bytes outside every process's heap, never moved or freed: an atom —
/// interned, so compared by its address, and shared by every process
/// (`caller.bp_term_static`: the comptime's arena, translated code's
/// `heap.static`).
fn allocStatic(n: usize) [*]u8 {
    const size = std.mem.alignForward(usize, n, 8);
    if (builtin.cpu.arch.isWasm()) return @ptrFromInt(caller.bp_term_static(@intCast(size)));
    return (native_arena.allocator().alignedAlloc(u8, .@"8", @max(size, 8)) catch @panic("term: out of memory")).ptr;
}

var native_arena: std.heap.ArenaAllocator = .init(std.heap.page_allocator);

/// The layout of a cell `S` on wasm32: each pointer field (a term, a term
/// array, a binary's bytes) a word a collection follows; every other field
/// (the header, an arity, a length, an `i64`, an `f64`) left as it is.
pub fn cellLayout(comptime S: type) u32 {
    var bits: u32 = 0;
    inline for (@typeInfo(S).@"struct".fields) |f| {
        const info = @typeInfo(f.type);
        const is_ptr = info == .pointer or (info == .optional and @typeInfo(info.optional.child) == .pointer);
        if (is_ptr) bits |= @as(u32, 1) << @intCast(@offsetOf(S, f.name) / @sizeOf(usize));
    }
    return stdWasm.heap.bitmap(bits);
}

comptime {
    // The word each pointer field sits at on wasm32, as `cellLayout` reads it.
    if (builtin.cpu.arch.isWasm()) {
        std.debug.assert(cellLayout(Cons) == 0b110);
        std.debug.assert(cellLayout(Bin) == 0b100);
        std.debug.assert(cellLayout(Tuple) == 0b100);
        std.debug.assert(cellLayout(Map) == 0b1100);
        std.debug.assert(cellLayout(Fun) == 0b1000);
        std.debug.assert(cellLayout(Builder) == 0b1000);
        std.debug.assert(cellLayout(Int) == 0 and cellLayout(Float) == 0);
    }
}

fn create(comptime S: type) *S {
    return @ptrCast(@alignCast(allocAs(@sizeOf(S), cellLayout(S))));
}

/// `n` term words (a tuple's items, a map's keys or values, a list's
/// elements gathered): every word a term.
pub fn allocTerms(n: usize) [*]T {
    return @ptrCast(@alignCast(allocAs(@max(n, 1) * @sizeOf(T), stdWasm.heap.pointersFrom(0))));
}

/// Start an evaluation's terms: the atom table, the process dictionary, the
/// printed text and any pending exception are cleared. Where its terms live
/// is the caller's (`caller.bp_term_alloc`): the comptime runtime's `rt_init(start)`
/// sets its arena, then calls this.
pub fn rt_reset() callconv(.c) void {
    atoms = .{null} ** atom_buckets;
    atom_count = 0;
    erlang.pdict = nil_cell_ptr();
    pending = false;
    p_class = nil_cell_ptr();
    p_reason = nil_cell_ptr();
    raised_line = 0;
    raised_col = 0;
    nil_cell = .{ .tag = .nil };
    io_lib.printed = null;
    initCommonAtoms();
}

// ── constants ────────────────────────────────────────────────────────────────

pub var nil_cell: Hdr = .{ .tag = .nil };

fn nil_cell_ptr() T {
    return &nil_cell;
}

pub fn rt_nil() callconv(.c) T {
    return &nil_cell;
}

// ── atoms ────────────────────────────────────────────────────────────────────

const atom_buckets = 256;
var atoms: [atom_buckets]?*Atom = .{null} ** atom_buckets;
var atom_count: u32 = 0;

pub var a_true: T = undefined;
pub var a_false: T = undefined;
pub var a_undefined: T = undefined;
pub var a_ok: T = undefined;
pub var a_error: T = undefined;
var a_throw: T = undefined;
var a_exit: T = undefined;
pub var a_badarg: T = undefined;
var a_badarith: T = undefined;
pub var a_badkey: T = undefined;
var a_badmatch: T = undefined;
var a_case_clause: T = undefined;
var a_if_clause: T = undefined;
var a_function_clause: T = undefined;
var a_try_clause: T = undefined;
var a_badfun: T = undefined;
var a_badarity: T = undefined;
pub var a_null: T = undefined;
pub var a_nomatch: T = undefined;
pub var a_leading: T = undefined;
pub var a_trailing: T = undefined;
pub var a_both: T = undefined;
pub var a_all: T = undefined;
pub var a_global: T = undefined;
pub var a_short: T = undefined;
var a_utf8: T = undefined;
var a_latin1: T = undefined;
var a_unicode: T = undefined;
pub var a_unsupported_type: T = undefined;
var a_bp_wat_runtime: T = undefined;

fn initCommonAtoms() void {
    a_true = atomOf("true");
    a_false = atomOf("false");
    a_undefined = atomOf("undefined");
    a_ok = atomOf("ok");
    a_error = atomOf("error");
    a_throw = atomOf("throw");
    a_exit = atomOf("exit");
    a_badarg = atomOf("badarg");
    a_badarith = atomOf("badarith");
    a_badkey = atomOf("badkey");
    a_badmatch = atomOf("badmatch");
    a_case_clause = atomOf("case_clause");
    a_if_clause = atomOf("if_clause");
    a_function_clause = atomOf("function_clause");
    a_try_clause = atomOf("try_clause");
    a_badfun = atomOf("badfun");
    a_badarity = atomOf("badarity");
    a_null = atomOf("null");
    a_nomatch = atomOf("nomatch");
    a_leading = atomOf("leading");
    a_trailing = atomOf("trailing");
    a_both = atomOf("both");
    a_all = atomOf("all");
    a_global = atomOf("global");
    a_short = atomOf("short");
    a_utf8 = atomOf("utf8");
    a_latin1 = atomOf("latin1");
    a_unicode = atomOf("unicode");
    a_unsupported_type = atomOf("unsupported_type");
    a_bp_wat_runtime = atomOf("bp_wat_runtime");
}

fn hashBytes(s: []const u8) u32 {
    var h: u32 = 2166136261;
    for (s) |c| h = (h ^ c) *% 16777619;
    return h;
}

pub fn atomOf(s: []const u8) T {
    return internAtom(s.ptr, s.len);
}

pub fn internAtom(ptr: [*]const u8, len: usize) T {
    const bytes = ptr[0..len];
    const b = hashBytes(bytes) % atom_buckets;
    var it = atoms[b];
    while (it) |a| : (it = a.next) {
        if (a.len == len and std.mem.eql(u8, a.ptr[0..a.len], bytes)) return @ptrCast(a);
    }
    // The atom and a copy of its name, outside every process's heap: the
    // name may be a binary's bytes on one.
    const mem = allocStatic(@sizeOf(Atom) + len);
    const a: *Atom = @ptrCast(@alignCast(mem));
    const name = mem + @sizeOf(Atom);
    @memcpy(name[0..len], bytes);
    a.* = .{ .hdr = .{ .tag = .atom }, .len = @intCast(len), .ptr = name, .next = atoms[b], .rank = atomRank(bytes) };
    atoms[b] = a;
    atom_count += 1;
    return @ptrCast(a);
}

/// The atom `ptr[0..len]` (interned — `=:=` on atoms is pointer equality).
pub fn rt_atom(ptr: [*]const u8, len: usize) callconv(.c) T {
    return internAtom(ptr, len);
}

pub fn atomBytes(t: T) []const u8 {
    const a = as(Atom, t);
    return a.ptr[0..a.len];
}

/// The order a BEAM map iterates atom keys in is the atom-table index: atoms
/// the OTP release had at boot first, in their index order, then the ones
/// created afterwards in creation order. `boot_atoms` is the boot order of the
/// atoms a comptime reply is known to carry as keys (measured on OTP 28 and 29,
/// identical); every other atom ranks after them, in creation order.
fn atomRank(bytes: []const u8) u32 {
    return wordIndex(boot_atoms, bytes) orelse boot_atom_count + atom_count;
}

/// One string, each name between spaces, not a table of slices: a table
/// would put pointers in the module's data, which `std_wasm_link.zig`
/// refuses.
const boot_atoms = " error value type name text line start end source message span code args fields label context bindings capture ";
const boot_atom_count = 18;

/// The index of `word` among the space-separated words of `words` (which
/// starts and ends with a space), or null.
pub fn wordIndex(words: []const u8, word: []const u8) ?u32 {
    var i: u32 = 0;
    var at: usize = 1;
    while (at < words.len) : (i += 1) {
        const end = std.mem.indexOfScalarPos(u8, words, at, ' ') orelse return null;
        if (std.mem.eql(u8, words[at..end], word)) return i;
        at = end + 1;
    }
    return null;
}

// ── numbers, binaries, lists, tuples ─────────────────────────────────────────

pub fn mkInt(v: i64) T {
    const c = create(Int);
    c.* = .{ .hdr = .{ .tag = .int }, .value = v };
    return @ptrCast(c);
}

pub fn mkFloat(v: f64) T {
    const c = create(Float);
    c.* = .{ .hdr = .{ .tag = .float }, .value = v };
    return @ptrCast(c);
}

pub fn rt_int(v: i64) callconv(.c) T {
    return mkInt(v);
}

pub fn rt_float(v: f64) callconv(.c) T {
    return mkFloat(v);
}

pub fn mkBin(ptr: [*]const u8, len: usize) T {
    const c = create(Bin);
    c.* = .{ .hdr = .{ .tag = .binary }, .len = @intCast(len), .ptr = ptr };
    return @ptrCast(c);
}

pub fn binOf(bytes: []const u8) T {
    return mkBin(bytes.ptr, bytes.len);
}

/// A copy of `bytes` as a binary.
pub fn binCopy(bytes: []const u8) T {
    const p = alloc(bytes.len);
    @memcpy(p[0..bytes.len], bytes);
    return mkBin(p, bytes.len);
}

/// The binary `ptr[0..len]`, not copied (a literal of the linked module).
pub fn rt_bin(ptr: [*]const u8, len: usize) callconv(.c) T {
    return mkBin(ptr, len);
}

pub fn binBytes(t: T) []const u8 {
    const b = as(Bin, t);
    return b.ptr[0..b.len];
}

pub fn rt_bin_ptr(t: T) callconv(.c) usize {
    return @intFromPtr(as(Bin, t).ptr);
}

pub fn rt_bin_len(t: T) callconv(.c) usize {
    return as(Bin, t).len;
}

pub fn cons(h: T, t: T) T {
    const c = create(Cons);
    c.* = .{ .hdr = .{ .tag = .cons }, .head = h, .tail = t };
    return @ptrCast(c);
}

pub fn rt_cons(h: T, t: T) callconv(.c) T {
    return cons(h, t);
}

pub fn rt_hd(t: T) callconv(.c) T {
    return as(Cons, t).head;
}

pub fn rt_tl(t: T) callconv(.c) T {
    return as(Cons, t).tail;
}

pub fn mkTuple(n: usize) *Tuple {
    const c = create(Tuple);
    c.* = .{ .hdr = .{ .tag = .tuple }, .arity = @intCast(n), .items = allocTerms(n) };
    return c;
}

pub fn tuple(items: []const T) T {
    const t = mkTuple(items.len);
    for (items, 0..) |it, i| t.items[i] = it;
    return @ptrCast(t);
}

/// A tuple of `n` elements; fill it with `rt_tset`.
pub fn rt_tuple(n: usize) callconv(.c) T {
    return @ptrCast(mkTuple(n));
}

pub fn rt_tset(t: T, i: usize, v: T) callconv(.c) T {
    as(Tuple, t).items[i] = v;
    return t;
}

/// `i`th element (0-based), unchecked — the lowering tests the arity first.
pub fn rt_elem(t: T, i: usize) callconv(.c) T {
    return as(Tuple, t).items[i];
}

/// The tuple's arity, or -1 for a term that is not a tuple.
pub fn rt_tuple_arity(t: T) callconv(.c) i32 {
    if (tagOf(t) != .tuple) return -1;
    return @intCast(as(Tuple, t).arity);
}

pub fn listFrom(items: []const T) T {
    var l: T = &nil_cell;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        l = cons(items[i], l);
    }
    return l;
}

/// The elements of a proper list, or null for an improper one.
pub fn listItems(l: T) ?[]T {
    var n: usize = 0;
    var it = l;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) n += 1;
    if (tagOf(it) != .nil) return null;
    const out = allocTerms(n);
    it = l;
    var i: usize = 0;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        out[i] = as(Cons, it).head;
        i += 1;
    }
    return out[0..n];
}

// ── funs ─────────────────────────────────────────────────────────────────────

/// A closure: `index` is the lifted function's slot in the table, which takes
/// the fun itself first and then its `arity` arguments.
pub fn rt_make_fun(index: u32, arity: u32, env: T) callconv(.c) T {
    const c = create(Fun);
    c.* = .{ .hdr = .{ .tag = .fun }, .arity = arity, .index = index, .env = env };
    return @ptrCast(c);
}

pub fn rt_fun_env(f: T) callconv(.c) T {
    return as(Fun, f).env;
}

/// The table index to call `f` with `arity` arguments through; raises
/// `{badfun, F}` / `{badarity, {F, Args}}` (the arguments are the caller's
/// problem: `args` is the list the BEAM would report).
pub fn rt_fun_index(f: T, arity: u32, args: T) callconv(.c) u32 {
    if (tagOf(f) != .fun) {
        raiseError(tuple(&.{ a_badfun, f }));
        return 0;
    }
    const fun = as(Fun, f);
    if (fun.arity != arity) {
        raiseError(tuple(&.{ a_badarity, tuple(&.{ f, args }) }));
        return 0;
    }
    return fun.index;
}

/// Apply a fun value to `args` — what `lists:map`, `maps:fold` and `apply/2`
/// run. Raises like a call site would. The call goes through the caller's
/// function table (`caller.bp_call<N>`, the fun's table index first).
pub fn applyFun(f: T, args: []const T) T {
    const idx = rt_fun_index(f, @intCast(args.len), listFrom(args));
    if (pending) return &nil_cell;
    if (!builtin.cpu.arch.isWasm()) @panic("term: funs only run on wasm");
    return switch (args.len) {
        0 => caller.bp_call0(idx, f),
        1 => caller.bp_call1(idx, f, args[0]),
        2 => caller.bp_call2(idx, f, args[0], args[1]),
        3 => caller.bp_call3(idx, f, args[0], args[1], args[2]),
        4 => caller.bp_call4(idx, f, args[0], args[1], args[2], args[3]),
        else => blk: {
            raiseWat("apply of more than 4 arguments");
            break :blk &nil_cell;
        },
    };
}

// ── exceptions ───────────────────────────────────────────────────────────────

pub var pending: bool = false;
// Set by `rt_reset`: a pointer in a `var`'s initial value would be a
// relocation in the module's data, which `std_wasm_link.zig` refuses.
var p_class: T = undefined;
var p_reason: T = undefined;

/// The addresses of the term library's statics that hold a term — the
/// process dictionary, the pending exception, the printed text: in
/// translated code the roots a process's heap keeps for good
/// (`heap.termRoots`, decision 449 (3)). An atom lives outside every heap
/// (`allocStatic`), so the atom table is none of them.
pub fn rootCells() [4]usize {
    return .{ @intFromPtr(&erlang.pdict), @intFromPtr(&p_class), @intFromPtr(&p_reason), @intFromPtr(&io_lib.printed) };
}

fn raise(class: T, reason: T) void {
    if (pending) return;
    pending = true;
    p_class = class;
    p_reason = reason;
    raised_line = 0;
    raised_col = 0;
}

// Decision 451 (3) — where the pending (or the last caught) exception was
// raised: the source location of the innermost located call it left. The
// comptime lowering wraps each call of the module being compiled in
// `'__bp_at'(Line, Col, Call)` (`compiler-core/src/comptime/runtime/wat/
// lower.zig`), which calls `rt_raised_at` when the call raised; 0 is "none".
// A new raise forgets the previous location; catching keeps it, so the
// evaluator's `catch` reads it back (`rt_raised_at_term`).
var raised_line: i32 = 0;
var raised_col: i32 = 0;

/// Record `line:col` as where the pending exception was raised, unless a
/// call it left earlier — an inner one — already did.
pub fn rt_raised_at(line: i32, col: i32) callconv(.c) void {
    if (!pending or raised_line != 0) return;
    raised_line = line;
    raised_col = col;
}

/// `[Line, Col]` of the last raise's innermost located call, `[]` when no
/// located call recorded one.
pub fn rt_raised_at_term() callconv(.c) T {
    if (raised_line == 0) return nil_cell_ptr();
    return cons(mkInt(raised_line), cons(mkInt(raised_col), nil_cell_ptr()));
}

pub fn raiseError(reason: T) void {
    raise(a_error, reason);
}

pub fn badarg() T {
    raiseError(a_badarg);
    return &nil_cell;
}

/// A construct this runtime does not implement, met at run time — never a
/// silent answer: `{bp_wat_runtime, <<"what">>}`.
pub fn raiseWat(what: []const u8) void {
    raiseError(tuple(&.{ a_bp_wat_runtime, binOf(what) }));
}

pub fn rt_pending() callconv(.c) i32 {
    return @intFromBool(pending);
}

pub fn rt_class() callconv(.c) T {
    return p_class;
}

pub fn rt_reason() callconv(.c) T {
    return p_reason;
}

pub fn rt_clear() callconv(.c) void {
    pending = false;
}

pub fn rt_raise(class: T, reason: T) callconv(.c) T {
    raise(class, reason);
    return &nil_cell;
}

pub fn rt_throw(r: T) callconv(.c) T {
    raise(a_throw, r);
    return &nil_cell;
}

pub fn rt_error(r: T) callconv(.c) T {
    raiseError(r);
    return &nil_cell;
}

pub fn rt_exit(r: T) callconv(.c) T {
    raise(a_exit, r);
    return &nil_cell;
}

pub fn rt_badmatch(v: T) callconv(.c) T {
    raiseError(tuple(&.{ a_badmatch, v }));
    return &nil_cell;
}

pub fn rt_case_clause(v: T) callconv(.c) T {
    raiseError(tuple(&.{ a_case_clause, v }));
    return &nil_cell;
}

pub fn rt_try_clause(v: T) callconv(.c) T {
    raiseError(tuple(&.{ a_try_clause, v }));
    return &nil_cell;
}

pub fn rt_if_clause() callconv(.c) T {
    raiseError(a_if_clause);
    return &nil_cell;
}

pub fn rt_function_clause() callconv(.c) T {
    raiseError(a_function_clause);
    return &nil_cell;
}

pub fn rt_badarg() callconv(.c) T {
    return badarg();
}

/// `{badarg, V}` — what `andalso`/`orelse` raise on a non-boolean left side.
pub fn rt_badarg_of(v: T) callconv(.c) T {
    raiseError(tuple(&.{ a_badarg, v }));
    return &nil_cell;
}

// ── booleans and type tests ──────────────────────────────────────────────────

pub fn boolAtom(b: bool) T {
    return if (b) a_true else a_false;
}

pub fn rt_bool(b: i32) callconv(.c) T {
    return boolAtom(b != 0);
}

/// 1 for `true`, 0 for `false`, 2 for anything else.
pub fn rt_truth(t: T) callconv(.c) i32 {
    if (t == a_true) return 1;
    if (t == a_false) return 0;
    return 2;
}

pub const Kind = enum(u32) {
    atom = 0,
    binary = 1,
    integer = 2,
    float = 3,
    number = 4,
    list = 5,
    tuple = 6,
    map = 7,
    function = 8,
    boolean = 9,
    bitstring = 10,
    nil = 11,
    cons = 12,
};

/// `is_<kind>(T)` as an i32 — the guard BIFs.
pub fn rt_is(t: T, kind: u32) callconv(.c) i32 {
    const tag = tagOf(t);
    const r = switch (@as(Kind, @enumFromInt(kind))) {
        .atom => tag == .atom,
        .binary, .bitstring => tag == .binary,
        .integer => tag == .int,
        .float => tag == .float,
        .number => tag == .int or tag == .float,
        .list => tag == .cons or tag == .nil,
        .tuple => tag == .tuple,
        .map => tag == .map,
        .function => tag == .fun,
        .boolean => t == a_true or t == a_false,
        .nil => tag == .nil,
        .cons => tag == .cons,
    };
    return @intFromBool(r);
}

/// `is_function(F, Arity)`.
pub fn rt_is_fun_arity(t: T, arity: T) callconv(.c) i32 {
    if (tagOf(t) != .fun or tagOf(arity) != .int) return 0;
    return @intFromBool(as(Fun, t).arity == as(Int, arity).value);
}

// ── term order and equality ──────────────────────────────────────────────────

fn rankOf(tag: Tag) u8 {
    return switch (tag) {
        .int, .float => 1,
        .atom => 2,
        .fun => 4,
        .tuple => 6,
        .map => 7,
        .nil => 8,
        .cons => 9,
        .binary, .builder => 10,
    };
}

pub fn numAsFloat(t: T) f64 {
    return switch (tagOf(t)) {
        .int => @floatFromInt(as(Int, t).value),
        .float => as(Float, t).value,
        else => 0,
    };
}

fn order(a: i64, b: i64) i32 {
    return if (a < b) -1 else if (a > b) 1 else 0;
}

fn orderBytes(a: []const u8, b: []const u8) i32 {
    return switch (std.mem.order(u8, a, b)) {
        .lt => -1,
        .eq => 0,
        .gt => 1,
    };
}

/// One pending comparison of the work list `compare` walks.
const Pair = struct { a: T, b: T, exact: bool };

/// The pending comparisons of one `compare`: a fixed array first, then the
/// heap — comparison never recurses, so a value's depth is bounded by memory
/// and never by the runtime's stack (decision 471).
const Work = struct {
    items: [*]Pair,
    len: usize,
    cap: usize,
    inline_items: [32]Pair,

    fn init(self: *Work) void {
        self.items = &self.inline_items;
        self.len = 0;
        self.cap = self.inline_items.len;
    }

    fn push(self: *Work, a: T, b: T, exact: bool) void {
        if (self.len == self.cap) {
            const cap = self.cap * 2;
            const bytes = alloc(cap * @sizeOf(Pair));
            const grown: [*]Pair = @ptrCast(@alignCast(bytes));
            @memcpy(grown[0..self.len], self.items[0..self.len]);
            self.items = grown;
            self.cap = cap;
        }
        self.items[self.len] = .{ .a = a, .b = b, .exact = exact };
        self.len += 1;
    }
};

/// Erlang term order (`<`, `==`): numbers compare by value across int and
/// float. `exact` makes `1` and `1.0` differ (`=:=`), ordering the int first
/// — the order map keys are kept in. Iterative (decision 471): the parts of a
/// compound value wait on an explicit work list, the first part in order on
/// top, and the first part that differs answers.
pub fn compare(a: T, b: T, exact: bool) i32 {
    var work: Work = undefined;
    work.init();
    work.push(a, b, exact);
    while (work.len > 0) {
        work.len -= 1;
        const p = work.items[work.len];
        const c = compareStep(&work, p.a, p.b, p.exact);
        if (c != 0) return c;
    }
    return 0;
}

/// Compare `a` and `b` one level: a leaf answers, a compound value answers on
/// its own header (arity, count, function index) or pushes its parts onto
/// `work` — last part first, so they pop in order — and answers 0.
fn compareStep(work: *Work, a: T, b: T, exact: bool) i32 {
    if (a == b) return 0;
    const ta = tagOf(a);
    const tb = tagOf(b);
    const ra = rankOf(ta);
    const rb = rankOf(tb);
    if (ra != rb) return if (ra < rb) -1 else 1;
    switch (ta) {
        .int, .float => {
            if (ta == .int and tb == .int) return order(as(Int, a).value, as(Int, b).value);
            const fa = numAsFloat(a);
            const fb = numAsFloat(b);
            if (fa < fb) return -1;
            if (fa > fb) return 1;
            if (exact and ta != tb) return if (ta == .int) -1 else 1;
            return 0;
        },
        .atom => return orderBytes(atomBytes(a), atomBytes(b)),
        .binary => return orderBytes(binBytes(a), binBytes(b)),
        .nil => return 0,
        .cons => {
            work.push(as(Cons, a).tail, as(Cons, b).tail, exact);
            work.push(as(Cons, a).head, as(Cons, b).head, exact);
            return 0;
        },
        .tuple => {
            const x = as(Tuple, a);
            const y = as(Tuple, b);
            if (x.arity != y.arity) return if (x.arity < y.arity) -1 else 1;
            var i: usize = x.arity;
            while (i > 0) {
                i -= 1;
                work.push(x.items[i], y.items[i], exact);
            }
            return 0;
        },
        .map => {
            const x = as(Map, a);
            const y = as(Map, b);
            if (x.count != y.count) return if (x.count < y.count) -1 else 1;
            // Keys in term order, then values in key order.
            const kx = sortedKeys(x);
            const ky = sortedKeys(y);
            var i: usize = x.count;
            while (i > 0) {
                i -= 1;
                work.push(x.vals[kx[i]], y.vals[ky[i]], exact);
            }
            i = x.count;
            while (i > 0) {
                i -= 1;
                work.push(x.keys[kx[i]], y.keys[ky[i]], true);
            }
            return 0;
        },
        .fun => {
            const x = as(Fun, a);
            const y = as(Fun, b);
            if (x.index != y.index) return if (x.index < y.index) -1 else 1;
            work.push(x.env, y.env, exact);
            return 0;
        },
        .builder => return 0,
    }
}

pub fn rt_cmp(a: T, b: T) callconv(.c) i32 {
    return compare(a, b, false);
}

/// `=:=` as an i32.
pub fn rt_eqx(a: T, b: T) callconv(.c) i32 {
    return @intFromBool(compare(a, b, true) == 0);
}

/// `==` as an i32.
pub fn rt_eq(a: T, b: T) callconv(.c) i32 {
    return @intFromBool(compare(a, b, false) == 0);
}

// ── maps ─────────────────────────────────────────────────────────────────────

/// Map key order: atoms by `rank` (the BEAM's atom-index order), every other
/// key by exact term order after them — the order `maps:to_list`, `maps:fold`
/// and `json:encode` iterate a map in.
fn keyOrder(a: T, b: T) i32 {
    const ta = tagOf(a);
    const tb = tagOf(b);
    if (ta == .atom and tb == .atom) {
        if (a == b) return 0;
        const x = as(Atom, a).rank;
        const y = as(Atom, b).rank;
        return if (x < y) -1 else if (x > y) 1 else orderBytes(atomBytes(a), atomBytes(b));
    }
    return compare(a, b, true);
}

pub fn sortedKeys(m: *Map) []usize {
    const idx: [*]usize = @ptrCast(@alignCast(alloc(@max(m.count, 1) * @sizeOf(usize))));
    for (0..m.count) |i| idx[i] = i;
    // insertion sort — maps here are small
    var i: usize = 1;
    while (i < m.count) : (i += 1) {
        var j = i;
        while (j > 0 and compare(m.keys[idx[j - 1]], m.keys[idx[j]], true) > 0) : (j -= 1) {
            const tmp = idx[j];
            idx[j] = idx[j - 1];
            idx[j - 1] = tmp;
        }
    }
    return idx[0..m.count];
}

pub fn mkMap(n: usize) *Map {
    const c = create(Map);
    c.* = .{ .hdr = .{ .tag = .map }, .count = @intCast(n), .keys = allocTerms(n), .vals = allocTerms(n) };
    return c;
}

pub fn rt_map_empty() callconv(.c) T {
    return @ptrCast(mkMap(0));
}

pub fn mapFind(m: *Map, k: T) ?usize {
    for (0..m.count) |i| {
        if (compare(m.keys[i], k, true) == 0) return i;
    }
    return null;
}

pub fn mapPut(mt: T, k: T, v: T) T {
    const m = as(Map, mt);
    if (mapFind(m, k)) |i| {
        const out = mkMap(m.count);
        for (0..m.count) |j| {
            out.keys[j] = m.keys[j];
            out.vals[j] = m.vals[j];
        }
        out.vals[i] = v;
        return @ptrCast(out);
    }
    const out = mkMap(m.count + 1);
    var j: usize = 0;
    var placed = false;
    for (0..m.count) |i| {
        if (!placed and keyOrder(k, m.keys[i]) < 0) {
            out.keys[j] = k;
            out.vals[j] = v;
            j += 1;
            placed = true;
        }
        out.keys[j] = m.keys[i];
        out.vals[j] = m.vals[i];
        j += 1;
    }
    if (!placed) {
        out.keys[j] = k;
        out.vals[j] = v;
    }
    return @ptrCast(out);
}

/// `M#{K => V}` / `maps:put(K, V, M)`; `{badmap, M}` when `m` is no map.
pub fn rt_map_put(m: T, k: T, v: T) callconv(.c) T {
    if (tagOf(m) != .map) return badmap(m);
    return mapPut(m, k, v);
}

/// `M#{K := V}` — `{badkey, K}` when the key is absent.
pub fn rt_map_update(m: T, k: T, v: T) callconv(.c) T {
    if (tagOf(m) != .map) return badmap(m);
    if (mapFind(as(Map, m), k) == null) {
        raiseError(tuple(&.{ a_badkey, k }));
        return &nil_cell;
    }
    return mapPut(m, k, v);
}

pub fn badmap(m: T) T {
    raiseError(tuple(&.{ atomOf("badmap"), m }));
    return &nil_cell;
}

/// The value under `k`, or 0 (no term) when `m` is not a map or lacks the key
/// — the map-pattern test.
pub fn rt_map_find(m: T, k: T) callconv(.c) usize {
    if (tagOf(m) != .map) return 0;
    const mm = as(Map, m);
    const i = mapFind(mm, k) orelse return 0;
    return @intFromPtr(mm.vals[i]);
}

// ── arithmetic ───────────────────────────────────────────────────────────────

pub fn isNum(t: T) bool {
    const tag = tagOf(t);
    return tag == .int or tag == .float;
}

fn arith(a: T, b: T, comptime op: enum { add, sub, mul }) T {
    if (!isNum(a) or !isNum(b)) {
        raiseError(a_badarith);
        return &nil_cell;
    }
    if (tagOf(a) == .int and tagOf(b) == .int) {
        const x = as(Int, a).value;
        const y = as(Int, b).value;
        const r = switch (op) {
            .add => @addWithOverflow(x, y),
            .sub => @subWithOverflow(x, y),
            .mul => @mulWithOverflow(x, y),
        };
        if (r[1] != 0) {
            raiseWat("integer beyond 64 bits (a bignum)");
            return &nil_cell;
        }
        return mkInt(r[0]);
    }
    const x = numAsFloat(a);
    const y = numAsFloat(b);
    return mkFloat(switch (op) {
        .add => x + y,
        .sub => x - y,
        .mul => x * y,
    });
}

pub fn rt_add(a: T, b: T) callconv(.c) T {
    return arith(a, b, .add);
}

pub fn rt_sub(a: T, b: T) callconv(.c) T {
    return arith(a, b, .sub);
}

pub fn rt_mul(a: T, b: T) callconv(.c) T {
    return arith(a, b, .mul);
}

/// `/` — always a float; `badarith` on a zero divisor.
pub fn rt_fdiv(a: T, b: T) callconv(.c) T {
    if (!isNum(a) or !isNum(b)) return rt_error(a_badarith);
    const y = numAsFloat(b);
    if (y == 0) return rt_error(a_badarith);
    return mkFloat(numAsFloat(a) / y);
}

fn ints(a: T, b: T) ?[2]i64 {
    if (tagOf(a) != .int or tagOf(b) != .int) {
        raiseError(a_badarith);
        return null;
    }
    return .{ as(Int, a).value, as(Int, b).value };
}

pub fn rt_idiv(a: T, b: T) callconv(.c) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] == 0) return rt_error(a_badarith);
    return mkInt(@divTrunc(v[0], v[1]));
}

pub fn rt_rem(a: T, b: T) callconv(.c) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] == 0) return rt_error(a_badarith);
    return mkInt(@rem(v[0], v[1]));
}

pub fn rt_band(a: T, b: T) callconv(.c) T {
    const v = ints(a, b) orelse return &nil_cell;
    return mkInt(v[0] & v[1]);
}

pub fn rt_bor(a: T, b: T) callconv(.c) T {
    const v = ints(a, b) orelse return &nil_cell;
    return mkInt(v[0] | v[1]);
}

pub fn rt_bxor(a: T, b: T) callconv(.c) T {
    const v = ints(a, b) orelse return &nil_cell;
    return mkInt(v[0] ^ v[1]);
}

pub fn rt_bsl(a: T, b: T) callconv(.c) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] < 0 or v[1] > 62) return rt_error(a_badarith);
    return mkInt(v[0] << @intCast(v[1]));
}

pub fn rt_bsr(a: T, b: T) callconv(.c) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] < 0) return rt_error(a_badarith);
    return mkInt(v[0] >> @intCast(@min(v[1], 63)));
}

pub fn rt_neg(a: T) callconv(.c) T {
    return switch (tagOf(a)) {
        .int => mkInt(-as(Int, a).value),
        .float => mkFloat(-as(Float, a).value),
        else => rt_error(a_badarith),
    };
}

pub fn rt_bnot(a: T) callconv(.c) T {
    if (tagOf(a) != .int) return rt_error(a_badarith);
    return mkInt(~as(Int, a).value);
}

pub fn rt_not(a: T) callconv(.c) T {
    if (a == a_true) return a_false;
    if (a == a_false) return a_true;
    return badarg();
}

fn bools(a: T, b: T) ?[2]bool {
    const x = rt_truth(a);
    const y = rt_truth(b);
    if (x == 2 or y == 2) {
        _ = badarg();
        return null;
    }
    return .{ x == 1, y == 1 };
}

pub fn rt_and(a: T, b: T) callconv(.c) T {
    const v = bools(a, b) orelse return &nil_cell;
    return boolAtom(v[0] and v[1]);
}

pub fn rt_or(a: T, b: T) callconv(.c) T {
    const v = bools(a, b) orelse return &nil_cell;
    return boolAtom(v[0] or v[1]);
}

pub fn rt_xor(a: T, b: T) callconv(.c) T {
    const v = bools(a, b) orelse return &nil_cell;
    return boolAtom(v[0] != v[1]);
}

/// `A ++ B`.
pub fn rt_append(a: T, b: T) callconv(.c) T {
    const items = listItems(a) orelse return badarg();
    var l = b;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        l = cons(items[i], l);
    }
    return l;
}

/// `A -- B`: each element of `b` removes its first occurrence from `a`.
pub fn rt_subtract(a: T, b: T) callconv(.c) T {
    const xs = listItems(a) orelse return badarg();
    const ys = listItems(b) orelse return badarg();
    var keep = alloc(xs.len);
    @memset(keep[0..xs.len], 1);
    for (ys) |y| {
        for (xs, 0..) |x, i| {
            if (keep[i] == 1 and compare(x, y, true) == 0) {
                keep[i] = 0;
                break;
            }
        }
    }
    var l: T = &nil_cell;
    var i = xs.len;
    while (i > 0) {
        i -= 1;
        if (keep[i] == 1) l = cons(xs[i], l);
    }
    return l;
}

// ── binaries under construction ──────────────────────────────────────────────

pub fn rt_bb_new() callconv(.c) T {
    const c = create(Builder);
    const cap: u32 = 64;
    c.* = .{ .hdr = .{ .tag = .builder }, .len = 0, .cap = cap, .ptr = alloc(cap) };
    return @ptrCast(c);
}

pub fn bbPush(bt: T, bytes: []const u8) void {
    const b = as(Builder, bt);
    if (b.len + bytes.len > b.cap) {
        var cap = b.cap * 2;
        while (cap < b.len + bytes.len) cap *= 2;
        const p = alloc(cap);
        @memcpy(p[0..b.len], b.ptr[0..b.len]);
        b.ptr = p;
        b.cap = @intCast(cap);
    }
    @memcpy(b.ptr[b.len..][0..bytes.len], bytes);
    b.len += @intCast(bytes.len);
}

/// A `/binary` segment.
pub fn rt_bb_bin(b: T, v: T) callconv(.c) T {
    if (tagOf(v) != .binary) return badarg();
    bbPush(b, binBytes(v));
    return b;
}

/// An integer segment of `bits` bits (8, 16, 32 — big-endian, the default).
pub fn rt_bb_int(b: T, v: T, bits: u32) callconv(.c) T {
    if (tagOf(v) != .int or bits % 8 != 0 or bits == 0 or bits > 64) return badarg();
    const x: u64 = @bitCast(as(Int, v).value);
    var buf: [8]u8 = undefined;
    const n = bits / 8;
    for (0..n) |i| buf[i] = @truncate(x >> @intCast(8 * (n - 1 - i)));
    bbPush(b, buf[0..n]);
    return b;
}

/// A `/utf8` segment.
pub fn rt_bb_utf8(b: T, v: T) callconv(.c) T {
    if (tagOf(v) != .int) return badarg();
    const cp = as(Int, v).value;
    if (cp < 0 or cp > 0x10FFFF or (cp >= 0xD800 and cp <= 0xDFFF)) return badarg();
    var buf: [4]u8 = undefined;
    const n = std.unicode.utf8Encode(@intCast(cp), &buf) catch return badarg();
    bbPush(b, buf[0..n]);
    return b;
}

pub fn rt_bb_end(bt: T) callconv(.c) T {
    const b = as(Builder, bt);
    return mkBin(b.ptr, b.len);
}

/// `<<>>` matched against `t`, and a literal binary pattern: 1 when `t` is a
/// binary with exactly these bytes.
pub fn rt_bin_is(t: T, ptr: [*]const u8, len: usize) callconv(.c) i32 {
    if (tagOf(t) != .binary) return 0;
    return @intFromBool(std.mem.eql(u8, binBytes(t), ptr[0..len]));
}

/// `<<Prefix, Rest/binary>>` against `t` where `Prefix` is literal bytes:
/// the rest as a binary, or 0 when `t` does not start with them.
pub fn rt_bin_rest(t: T, ptr: [*]const u8, len: usize) callconv(.c) usize {
    if (tagOf(t) != .binary) return 0;
    const bytes = binBytes(t);
    if (!std.mem.startsWith(u8, bytes, ptr[0..len])) return 0;
    return @intFromPtr(binOf(bytes[len..]));
}

// ── floats as text ───────────────────────────────────────────────────────────

pub const shortFloat = stdWasm.number.shortFloat;
/// A list of terms collected on the caller's allocation, for a BIF that does
/// not know its length up front (no `std.mem.Allocator`: its vtable would be
/// a function table in the module).
pub const Terms = struct {
    items: []T = &.{},
    cap: usize = 0,

    pub fn append(l: *Terms, t: T) void {
        if (l.items.len == l.cap) {
            const cap = @max(8, l.cap * 2);
            const p = allocTerms(cap);
            @memcpy(p[0..l.items.len], l.items);
            l.items = p[0..l.items.len];
            l.cap = cap;
        }
        l.items.len += 1;
        l.items[l.items.len - 1] = t;
    }
};

pub fn listArg(l: T) ?[]T {
    return listItems(l) orelse {
        _ = badarg();
        return null;
    };
}

fn nested(depth: usize, leaf: i64) T {
    var t = mkInt(leaf);
    var i: usize = 0;
    while (i < depth) : (i += 1) t = tuple(&.{ mkInt(1), t });
    return t;
}

test "decision 471: term order and equality walk a work list, whatever the depth" {
    const depth = 2_000_000;
    // Two equal chains are equal; the one value that differs sits at the bottom.
    try std.testing.expectEqual(@as(i32, 0), compare(nested(depth, 7), nested(depth, 7), true));
    try std.testing.expectEqual(@as(i32, -1), compare(nested(depth, 7), nested(depth, 8), false));
    try std.testing.expectEqual(@as(i32, 1), compare(nested(depth, 9), nested(depth, 8), true));
    // A deep head of a list, then the order of its elements after it.
    const a = alloc(@sizeOf(Cons));
    const b = alloc(@sizeOf(Cons));
    const ca: *Cons = @ptrCast(@alignCast(a));
    const cb: *Cons = @ptrCast(@alignCast(b));
    ca.* = .{ .hdr = .{ .tag = .cons }, .head = nested(depth, 1), .tail = &nil_cell };
    cb.* = .{ .hdr = .{ .tag = .cons }, .head = nested(depth, 1), .tail = &nil_cell };
    try std.testing.expectEqual(@as(i32, 0), compare(@ptrCast(ca), @ptrCast(cb), true));
    // The first part in order decides: the head differs, so the tail is not read.
    cb.head = nested(depth, 2);
    try std.testing.expectEqual(@as(i32, -1), compare(@ptrCast(ca), @ptrCast(cb), true));
}
