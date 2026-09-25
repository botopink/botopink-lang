//! The wat comptime runtime's term library — compiled to `wasm32-freestanding`
//! at `zig build` (root `build.zig`, `wat-rt`) and embedded in the compiler as
//! bytes (`bp_wat_rt.wasm`). A comptime body lowered by `lower.zig` is linked
//! into these bytes (`link.zig`) and the result runs on wasm3 natively or on
//! `WebAssembly.instantiate` in the browser build — one module, no host round
//! trip: every Erlang value the body touches lives on this module's linear
//! memory, and every BIF the lowering calls is an export of this file.
//!
//! A term is an `i32` pointer to a `Hdr`-prefixed cell (`Tag`). The shapes are
//! the Erlang ones the generated modules use: small integers (i64 — a bignum
//! raises `{bp_wat_runtime, bignum}`), floats, interned atoms, binaries (a
//! slice, never copied when it is a literal), cons cells and `[]`, tuples,
//! maps (keys kept in BEAM iteration order, see `atomRank`) and funs (a table
//! index into the linked module, its arity and an environment tuple).
//!
//! Errors are Erlang exceptions: a BIF that raises records `{Class, Reason}`
//! in `pending` and returns `[]`; the lowered code tests `rt_pending()` after
//! every call and unwinds to its `catch` or out of `main`. The reasons are the
//! ones the BEAM gives (`badarg`, `{badkey, K}`, `badarith`, `function_clause`,
//! `{case_clause, V}`, …) so the reply a body produces does not depend on the
//! runtime that ran it.
//!
//! Memory is one bump arena per evaluation (`rt_init`), grown with
//! `memory.grow`; nothing is ever freed — a module is instantiated fresh for
//! every evaluation.
const std = @import("std");
const builtin = @import("builtin");

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

const Int = extern struct { hdr: Hdr, value: i64 };
const Float = extern struct { hdr: Hdr, value: f64 };
const Atom = extern struct { hdr: Hdr, len: u32, ptr: [*]const u8, next: ?*Atom, rank: u32 };
const Bin = extern struct { hdr: Hdr, len: u32, ptr: [*]const u8 };
const Cons = extern struct { hdr: Hdr, head: T, tail: T };
const Tuple = extern struct { hdr: Hdr, arity: u32, items: [*]T };
const Map = extern struct { hdr: Hdr, count: u32, keys: [*]T, vals: [*]T };
const Fun = extern struct { hdr: Hdr, arity: u32, index: u32, env: T };
const Builder = extern struct { hdr: Hdr, len: u32, cap: u32, ptr: [*]u8 };

fn tagOf(t: T) Tag {
    return t.tag;
}

fn as(comptime S: type, t: T) *S {
    return @ptrCast(@alignCast(t));
}

// ── the arena ────────────────────────────────────────────────────────────────

var heap: usize = 0;
var heap_end: usize = 0;

fn alloc(n: usize) [*]u8 {
    const size = std.mem.alignForward(usize, n, 8);
    if (heap + size > heap_end) {
        const need = heap + size - heap_end;
        const pages = (need + 65535) / 65536;
        if (builtin.cpu.arch.isWasm()) {
            if (@wasmMemoryGrow(0, pages) < 0) @trap();
        }
        heap_end += pages * 65536;
    }
    const p: [*]u8 = @ptrFromInt(heap);
    heap += size;
    return p;
}

fn create(comptime S: type) *S {
    return @ptrCast(@alignCast(alloc(@sizeOf(S))));
}

fn allocTerms(n: usize) [*]T {
    return @ptrCast(@alignCast(alloc(@max(n, 1) * @sizeOf(T))));
}

/// Start an evaluation: the arena begins at `start` (past the linked module's
/// literal data), the atom table, the process dictionary and any pending
/// exception are cleared.
export fn rt_init(start: usize) void {
    heap = std.mem.alignForward(usize, start, 8);
    if (builtin.cpu.arch.isWasm()) {
        heap_end = @wasmMemorySize(0) * 65536;
    } else {
        heap_end = heap;
    }
    atoms = .{null} ** atom_buckets;
    atom_count = 0;
    pdict = nil_cell_ptr();
    pending = false;
    nil_cell = .{ .tag = .nil };
    printed = null;
    initCommonAtoms();
}

/// Room for `len` bytes the host writes (the ETF argument).
export fn rt_alloc(len: usize) usize {
    return @intFromPtr(alloc(len));
}

// ── constants ────────────────────────────────────────────────────────────────

var nil_cell: Hdr = .{ .tag = .nil };

fn nil_cell_ptr() T {
    return &nil_cell;
}

export fn rt_nil() T {
    return &nil_cell;
}

// ── atoms ────────────────────────────────────────────────────────────────────

const atom_buckets = 256;
var atoms: [atom_buckets]?*Atom = .{null} ** atom_buckets;
var atom_count: u32 = 0;

var a_true: T = undefined;
var a_false: T = undefined;
var a_undefined: T = undefined;
var a_ok: T = undefined;
var a_error: T = undefined;
var a_throw: T = undefined;
var a_exit: T = undefined;
var a_badarg: T = undefined;
var a_badarith: T = undefined;
var a_badkey: T = undefined;
var a_badmatch: T = undefined;
var a_case_clause: T = undefined;
var a_if_clause: T = undefined;
var a_function_clause: T = undefined;
var a_try_clause: T = undefined;
var a_badfun: T = undefined;
var a_badarity: T = undefined;
var a_null: T = undefined;
var a_nomatch: T = undefined;
var a_leading: T = undefined;
var a_trailing: T = undefined;
var a_both: T = undefined;
var a_all: T = undefined;
var a_global: T = undefined;
var a_short: T = undefined;
var a_utf8: T = undefined;
var a_latin1: T = undefined;
var a_unicode: T = undefined;
var a_unsupported_type: T = undefined;
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

fn atomOf(s: []const u8) T {
    return internAtom(s.ptr, s.len);
}

fn internAtom(ptr: [*]const u8, len: usize) T {
    const bytes = ptr[0..len];
    const b = hashBytes(bytes) % atom_buckets;
    var it = atoms[b];
    while (it) |a| : (it = a.next) {
        if (a.len == len and std.mem.eql(u8, a.ptr[0..a.len], bytes)) return @ptrCast(a);
    }
    const a = create(Atom);
    a.* = .{ .hdr = .{ .tag = .atom }, .len = @intCast(len), .ptr = ptr, .next = atoms[b], .rank = atomRank(bytes) };
    atoms[b] = a;
    atom_count += 1;
    return @ptrCast(a);
}

/// The atom `ptr[0..len]` (interned — `=:=` on atoms is pointer equality).
export fn rt_atom(ptr: [*]const u8, len: usize) T {
    return internAtom(ptr, len);
}

fn atomBytes(t: T) []const u8 {
    const a = as(Atom, t);
    return a.ptr[0..a.len];
}

/// The order a BEAM map iterates atom keys in is the atom-table index: atoms
/// the OTP release had at boot first, in their index order, then the ones
/// created afterwards in creation order. `boot_atoms` is the boot order of the
/// atoms a comptime reply is known to carry as keys (measured on OTP 28 and 29,
/// identical); every other atom ranks after them, in creation order.
fn atomRank(bytes: []const u8) u32 {
    for (boot_atoms, 0..) |name, i| {
        if (std.mem.eql(u8, name, bytes)) return @intCast(i);
    }
    return @as(u32, boot_atoms.len) + atom_count;
}

const boot_atoms = [_][]const u8{
    "error",   "value", "type", "name", "text",   "line",  "start",   "end",      "source",
    "message", "span",  "code", "args", "fields", "label", "context", "bindings", "capture",
};

// ── numbers, binaries, lists, tuples ─────────────────────────────────────────

fn mkInt(v: i64) T {
    const c = create(Int);
    c.* = .{ .hdr = .{ .tag = .int }, .value = v };
    return @ptrCast(c);
}

fn mkFloat(v: f64) T {
    const c = create(Float);
    c.* = .{ .hdr = .{ .tag = .float }, .value = v };
    return @ptrCast(c);
}

export fn rt_int(v: i64) T {
    return mkInt(v);
}

export fn rt_float(v: f64) T {
    return mkFloat(v);
}

fn mkBin(ptr: [*]const u8, len: usize) T {
    const c = create(Bin);
    c.* = .{ .hdr = .{ .tag = .binary }, .len = @intCast(len), .ptr = ptr };
    return @ptrCast(c);
}

fn binOf(bytes: []const u8) T {
    return mkBin(bytes.ptr, bytes.len);
}

/// A copy of `bytes` as a binary.
fn binCopy(bytes: []const u8) T {
    const p = alloc(bytes.len);
    @memcpy(p[0..bytes.len], bytes);
    return mkBin(p, bytes.len);
}

/// The binary `ptr[0..len]`, not copied (a literal of the linked module).
export fn rt_bin(ptr: [*]const u8, len: usize) T {
    return mkBin(ptr, len);
}

fn binBytes(t: T) []const u8 {
    const b = as(Bin, t);
    return b.ptr[0..b.len];
}

export fn rt_bin_ptr(t: T) usize {
    return @intFromPtr(as(Bin, t).ptr);
}

export fn rt_bin_len(t: T) usize {
    return as(Bin, t).len;
}

fn cons(h: T, t: T) T {
    const c = create(Cons);
    c.* = .{ .hdr = .{ .tag = .cons }, .head = h, .tail = t };
    return @ptrCast(c);
}

export fn rt_cons(h: T, t: T) T {
    return cons(h, t);
}

export fn rt_hd(t: T) T {
    return as(Cons, t).head;
}

export fn rt_tl(t: T) T {
    return as(Cons, t).tail;
}

fn mkTuple(n: usize) *Tuple {
    const c = create(Tuple);
    c.* = .{ .hdr = .{ .tag = .tuple }, .arity = @intCast(n), .items = allocTerms(n) };
    return c;
}

fn tuple(items: []const T) T {
    const t = mkTuple(items.len);
    for (items, 0..) |it, i| t.items[i] = it;
    return @ptrCast(t);
}

/// A tuple of `n` elements; fill it with `rt_tset`.
export fn rt_tuple(n: usize) T {
    return @ptrCast(mkTuple(n));
}

export fn rt_tset(t: T, i: usize, v: T) T {
    as(Tuple, t).items[i] = v;
    return t;
}

/// `i`th element (0-based), unchecked — the lowering tests the arity first.
export fn rt_elem(t: T, i: usize) T {
    return as(Tuple, t).items[i];
}

/// The tuple's arity, or -1 for a term that is not a tuple.
export fn rt_tuple_arity(t: T) i32 {
    if (tagOf(t) != .tuple) return -1;
    return @intCast(as(Tuple, t).arity);
}

fn listFrom(items: []const T) T {
    var l: T = &nil_cell;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        l = cons(items[i], l);
    }
    return l;
}

/// The elements of a proper list, or null for an improper one.
fn listItems(l: T) ?[]T {
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
export fn rt_make_fun(index: u32, arity: u32, env: T) T {
    const c = create(Fun);
    c.* = .{ .hdr = .{ .tag = .fun }, .arity = arity, .index = index, .env = env };
    return @ptrCast(c);
}

export fn rt_fun_env(f: T) T {
    return as(Fun, f).env;
}

/// The table index to call `f` with `arity` arguments through; raises
/// `{badfun, F}` / `{badarity, {F, Args}}` (the arguments are the caller's
/// problem: `args` is the list the BEAM would report).
export fn rt_fun_index(f: T, arity: u32, args: T) u32 {
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

const Fn0 = *const fn (T) callconv(.c) T;
const Fn1 = *const fn (T, T) callconv(.c) T;
const Fn2 = *const fn (T, T, T) callconv(.c) T;
const Fn3 = *const fn (T, T, T, T) callconv(.c) T;
const Fn4 = *const fn (T, T, T, T, T) callconv(.c) T;

/// Apply a fun value to `args` — what `lists:map`, `maps:fold` and `apply/2`
/// run. Raises like a call site would.
fn applyFun(f: T, args: []const T) T {
    const idx = rt_fun_index(f, @intCast(args.len), listFrom(args));
    if (pending) return &nil_cell;
    if (!builtin.cpu.arch.isWasm()) @panic("rt: funs only run on wasm");
    return switch (args.len) {
        0 => @as(Fn0, @ptrFromInt(idx))(f),
        1 => @as(Fn1, @ptrFromInt(idx))(f, args[0]),
        2 => @as(Fn2, @ptrFromInt(idx))(f, args[0], args[1]),
        3 => @as(Fn3, @ptrFromInt(idx))(f, args[0], args[1], args[2]),
        4 => @as(Fn4, @ptrFromInt(idx))(f, args[0], args[1], args[2], args[3]),
        else => blk: {
            raiseWat("apply of more than 4 arguments");
            break :blk &nil_cell;
        },
    };
}

// ── exceptions ───────────────────────────────────────────────────────────────

var pending: bool = false;
var p_class: T = &nil_cell;
var p_reason: T = &nil_cell;

fn raise(class: T, reason: T) void {
    if (pending) return;
    pending = true;
    p_class = class;
    p_reason = reason;
}

fn raiseError(reason: T) void {
    raise(a_error, reason);
}

fn badarg() T {
    raiseError(a_badarg);
    return &nil_cell;
}

/// A construct this runtime does not implement, met at run time — never a
/// silent answer: `{bp_wat_runtime, <<"what">>}`.
fn raiseWat(what: []const u8) void {
    raiseError(tuple(&.{ a_bp_wat_runtime, binOf(what) }));
}

export fn rt_pending() i32 {
    return @intFromBool(pending);
}

export fn rt_class() T {
    return p_class;
}

export fn rt_reason() T {
    return p_reason;
}

export fn rt_clear() void {
    pending = false;
}

export fn rt_raise(class: T, reason: T) T {
    raise(class, reason);
    return &nil_cell;
}

export fn rt_throw(r: T) T {
    raise(a_throw, r);
    return &nil_cell;
}

export fn rt_error(r: T) T {
    raiseError(r);
    return &nil_cell;
}

export fn rt_exit(r: T) T {
    raise(a_exit, r);
    return &nil_cell;
}

export fn rt_badmatch(v: T) T {
    raiseError(tuple(&.{ a_badmatch, v }));
    return &nil_cell;
}

export fn rt_case_clause(v: T) T {
    raiseError(tuple(&.{ a_case_clause, v }));
    return &nil_cell;
}

export fn rt_try_clause(v: T) T {
    raiseError(tuple(&.{ a_try_clause, v }));
    return &nil_cell;
}

export fn rt_if_clause() T {
    raiseError(a_if_clause);
    return &nil_cell;
}

export fn rt_function_clause() T {
    raiseError(a_function_clause);
    return &nil_cell;
}

export fn rt_badarg() T {
    return badarg();
}

/// `{badarg, V}` — what `andalso`/`orelse` raise on a non-boolean left side.
export fn rt_badarg_of(v: T) T {
    raiseError(tuple(&.{ a_badarg, v }));
    return &nil_cell;
}

// ── booleans and type tests ──────────────────────────────────────────────────

fn boolAtom(b: bool) T {
    return if (b) a_true else a_false;
}

export fn rt_bool(b: i32) T {
    return boolAtom(b != 0);
}

/// 1 for `true`, 0 for `false`, 2 for anything else.
export fn rt_truth(t: T) i32 {
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
export fn rt_is(t: T, kind: u32) i32 {
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
export fn rt_is_fun_arity(t: T, arity: T) i32 {
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

fn numAsFloat(t: T) f64 {
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

/// Erlang term order (`<`, `==`): numbers compare by value across int and
/// float. `exact` makes `1` and `1.0` differ (`=:=`), ordering the int first
/// — the order map keys are kept in.
fn compare(a: T, b: T, exact: bool) i32 {
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
            var x = a;
            var y = b;
            while (true) {
                const c = compare(as(Cons, x).head, as(Cons, y).head, exact);
                if (c != 0) return c;
                x = as(Cons, x).tail;
                y = as(Cons, y).tail;
                if (tagOf(x) != .cons or tagOf(y) != .cons) return compare(x, y, exact);
            }
        },
        .tuple => {
            const x = as(Tuple, a);
            const y = as(Tuple, b);
            if (x.arity != y.arity) return if (x.arity < y.arity) -1 else 1;
            for (0..x.arity) |i| {
                const c = compare(x.items[i], y.items[i], exact);
                if (c != 0) return c;
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
            for (0..x.count) |i| {
                const c = compare(x.keys[kx[i]], y.keys[ky[i]], true);
                if (c != 0) return c;
            }
            for (0..x.count) |i| {
                const c = compare(x.vals[kx[i]], y.vals[ky[i]], exact);
                if (c != 0) return c;
            }
            return 0;
        },
        .fun => {
            const x = as(Fun, a);
            const y = as(Fun, b);
            if (x.index != y.index) return if (x.index < y.index) -1 else 1;
            return compare(x.env, y.env, exact);
        },
        .builder => return 0,
    }
}

export fn rt_cmp(a: T, b: T) i32 {
    return compare(a, b, false);
}

/// `=:=` as an i32.
export fn rt_eqx(a: T, b: T) i32 {
    return @intFromBool(compare(a, b, true) == 0);
}

/// `==` as an i32.
export fn rt_eq(a: T, b: T) i32 {
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

fn sortedKeys(m: *Map) []usize {
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

fn mkMap(n: usize) *Map {
    const c = create(Map);
    c.* = .{ .hdr = .{ .tag = .map }, .count = @intCast(n), .keys = allocTerms(n), .vals = allocTerms(n) };
    return c;
}

export fn rt_map_empty() T {
    return @ptrCast(mkMap(0));
}

fn mapFind(m: *Map, k: T) ?usize {
    for (0..m.count) |i| {
        if (compare(m.keys[i], k, true) == 0) return i;
    }
    return null;
}

fn mapPut(mt: T, k: T, v: T) T {
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
export fn rt_map_put(m: T, k: T, v: T) T {
    if (tagOf(m) != .map) return badmap(m);
    return mapPut(m, k, v);
}

/// `M#{K := V}` — `{badkey, K}` when the key is absent.
export fn rt_map_update(m: T, k: T, v: T) T {
    if (tagOf(m) != .map) return badmap(m);
    if (mapFind(as(Map, m), k) == null) {
        raiseError(tuple(&.{ a_badkey, k }));
        return &nil_cell;
    }
    return mapPut(m, k, v);
}

fn badmap(m: T) T {
    raiseError(tuple(&.{ atomOf("badmap"), m }));
    return &nil_cell;
}

/// The value under `k`, or 0 (no term) when `m` is not a map or lacks the key
/// — the map-pattern test.
export fn rt_map_find(m: T, k: T) usize {
    if (tagOf(m) != .map) return 0;
    const mm = as(Map, m);
    const i = mapFind(mm, k) orelse return 0;
    return @intFromPtr(mm.vals[i]);
}

// ── arithmetic ───────────────────────────────────────────────────────────────

fn isNum(t: T) bool {
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

export fn rt_add(a: T, b: T) T {
    return arith(a, b, .add);
}

export fn rt_sub(a: T, b: T) T {
    return arith(a, b, .sub);
}

export fn rt_mul(a: T, b: T) T {
    return arith(a, b, .mul);
}

/// `/` — always a float; `badarith` on a zero divisor.
export fn rt_fdiv(a: T, b: T) T {
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

export fn rt_idiv(a: T, b: T) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] == 0) return rt_error(a_badarith);
    return mkInt(@divTrunc(v[0], v[1]));
}

export fn rt_rem(a: T, b: T) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] == 0) return rt_error(a_badarith);
    return mkInt(@rem(v[0], v[1]));
}

export fn rt_band(a: T, b: T) T {
    const v = ints(a, b) orelse return &nil_cell;
    return mkInt(v[0] & v[1]);
}

export fn rt_bor(a: T, b: T) T {
    const v = ints(a, b) orelse return &nil_cell;
    return mkInt(v[0] | v[1]);
}

export fn rt_bxor(a: T, b: T) T {
    const v = ints(a, b) orelse return &nil_cell;
    return mkInt(v[0] ^ v[1]);
}

export fn rt_bsl(a: T, b: T) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] < 0 or v[1] > 62) return rt_error(a_badarith);
    return mkInt(v[0] << @intCast(v[1]));
}

export fn rt_bsr(a: T, b: T) T {
    const v = ints(a, b) orelse return &nil_cell;
    if (v[1] < 0) return rt_error(a_badarith);
    return mkInt(v[0] >> @intCast(@min(v[1], 63)));
}

export fn rt_neg(a: T) T {
    return switch (tagOf(a)) {
        .int => mkInt(-as(Int, a).value),
        .float => mkFloat(-as(Float, a).value),
        else => rt_error(a_badarith),
    };
}

export fn rt_bnot(a: T) T {
    if (tagOf(a) != .int) return rt_error(a_badarith);
    return mkInt(~as(Int, a).value);
}

export fn rt_not(a: T) T {
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

export fn rt_and(a: T, b: T) T {
    const v = bools(a, b) orelse return &nil_cell;
    return boolAtom(v[0] and v[1]);
}

export fn rt_or(a: T, b: T) T {
    const v = bools(a, b) orelse return &nil_cell;
    return boolAtom(v[0] or v[1]);
}

export fn rt_xor(a: T, b: T) T {
    const v = bools(a, b) orelse return &nil_cell;
    return boolAtom(v[0] != v[1]);
}

/// `A ++ B`.
export fn rt_append(a: T, b: T) T {
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
export fn rt_subtract(a: T, b: T) T {
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

export fn rt_bb_new() T {
    const c = create(Builder);
    const cap: u32 = 64;
    c.* = .{ .hdr = .{ .tag = .builder }, .len = 0, .cap = cap, .ptr = alloc(cap) };
    return @ptrCast(c);
}

fn bbPush(bt: T, bytes: []const u8) void {
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
export fn rt_bb_bin(b: T, v: T) T {
    if (tagOf(v) != .binary) return badarg();
    bbPush(b, binBytes(v));
    return b;
}

/// An integer segment of `bits` bits (8, 16, 32 — big-endian, the default).
export fn rt_bb_int(b: T, v: T, bits: u32) T {
    if (tagOf(v) != .int or bits % 8 != 0 or bits == 0 or bits > 64) return badarg();
    const x: u64 = @bitCast(as(Int, v).value);
    var buf: [8]u8 = undefined;
    const n = bits / 8;
    for (0..n) |i| buf[i] = @truncate(x >> @intCast(8 * (n - 1 - i)));
    bbPush(b, buf[0..n]);
    return b;
}

/// A `/utf8` segment.
export fn rt_bb_utf8(b: T, v: T) T {
    if (tagOf(v) != .int) return badarg();
    const cp = as(Int, v).value;
    if (cp < 0 or cp > 0x10FFFF or (cp >= 0xD800 and cp <= 0xDFFF)) return badarg();
    var buf: [4]u8 = undefined;
    const n = std.unicode.utf8Encode(@intCast(cp), &buf) catch return badarg();
    bbPush(b, buf[0..n]);
    return b;
}

export fn rt_bb_end(bt: T) T {
    const b = as(Builder, bt);
    return mkBin(b.ptr, b.len);
}

/// `<<>>` matched against `t`, and a literal binary pattern: 1 when `t` is a
/// binary with exactly these bytes.
export fn rt_bin_is(t: T, ptr: [*]const u8, len: usize) i32 {
    if (tagOf(t) != .binary) return 0;
    return @intFromBool(std.mem.eql(u8, binBytes(t), ptr[0..len]));
}

/// `<<Prefix, Rest/binary>>` against `t` where `Prefix` is literal bytes:
/// the rest as a binary, or 0 when `t` does not start with them.
export fn rt_bin_rest(t: T, ptr: [*]const u8, len: usize) usize {
    if (tagOf(t) != .binary) return 0;
    const bytes = binBytes(t);
    if (!std.mem.startsWith(u8, bytes, ptr[0..len])) return 0;
    return @intFromPtr(binOf(bytes[len..]));
}

// ── the process dictionary ───────────────────────────────────────────────────

var pdict: T = &nil_cell; // list of {K, V}

export fn rt_erlang_put(k: T, v: T) T {
    var old: T = a_undefined;
    var l: T = &nil_cell;
    var it = pdict;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        const kv = as(Tuple, as(Cons, it).head);
        if (compare(kv.items[0], k, true) == 0) {
            old = kv.items[1];
        } else l = cons(as(Cons, it).head, l);
    }
    pdict = cons(tuple(&.{ k, v }), l);
    return old;
}

export fn rt_erlang_get(k: T) T {
    var it = pdict;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        const kv = as(Tuple, as(Cons, it).head);
        if (compare(kv.items[0], k, true) == 0) return kv.items[1];
    }
    return a_undefined;
}

export fn rt_erlang_erase(k: T) T {
    var old: T = a_undefined;
    var l: T = &nil_cell;
    var it = pdict;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        const kv = as(Tuple, as(Cons, it).head);
        if (compare(kv.items[0], k, true) == 0) {
            old = kv.items[1];
        } else l = cons(as(Cons, it).head, l);
    }
    pdict = l;
    return old;
}

// ── erlang: BIFs ─────────────────────────────────────────────────────────────

fn intArg(t: T) ?i64 {
    if (tagOf(t) != .int) {
        _ = badarg();
        return null;
    }
    return as(Int, t).value;
}

export fn rt_erlang_element(n: T, t: T) T {
    const i = intArg(n) orelse return &nil_cell;
    if (tagOf(t) != .tuple) return badarg();
    const tp = as(Tuple, t);
    if (i < 1 or i > tp.arity) return badarg();
    return tp.items[@intCast(i - 1)];
}

export fn rt_erlang_setelement(n: T, t: T, v: T) T {
    const i = intArg(n) orelse return &nil_cell;
    if (tagOf(t) != .tuple) return badarg();
    const tp = as(Tuple, t);
    if (i < 1 or i > tp.arity) return badarg();
    const out = mkTuple(tp.arity);
    for (0..tp.arity) |j| out.items[j] = tp.items[j];
    out.items[@intCast(i - 1)] = v;
    return @ptrCast(out);
}

export fn rt_erlang_tuple_size(t: T) T {
    if (tagOf(t) != .tuple) return badarg();
    return mkInt(as(Tuple, t).arity);
}

export fn rt_erlang_tuple_to_list(t: T) T {
    if (tagOf(t) != .tuple) return badarg();
    const tp = as(Tuple, t);
    return listFrom(tp.items[0..tp.arity]);
}

export fn rt_erlang_list_to_tuple(l: T) T {
    const items = listItems(l) orelse return badarg();
    return tuple(items);
}

export fn rt_erlang_length(l: T) T {
    const items = listItems(l) orelse return badarg();
    return mkInt(@intCast(items.len));
}

export fn rt_erlang_hd(l: T) T {
    if (tagOf(l) != .cons) return badarg();
    return as(Cons, l).head;
}

export fn rt_erlang_tl(l: T) T {
    if (tagOf(l) != .cons) return badarg();
    return as(Cons, l).tail;
}

export fn rt_erlang_byte_size(b: T) T {
    if (tagOf(b) != .binary) return badarg();
    return mkInt(as(Bin, b).len);
}

export fn rt_erlang_map_size(m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    return mkInt(as(Map, m).count);
}

export fn rt_erlang_abs(a: T) T {
    return switch (tagOf(a)) {
        .int => mkInt(if (as(Int, a).value < 0) -as(Int, a).value else as(Int, a).value),
        .float => mkFloat(@abs(as(Float, a).value)),
        else => badarg(),
    };
}

export fn rt_erlang_max(a: T, b: T) T {
    return if (compare(a, b, false) < 0) b else a;
}

export fn rt_erlang_min(a: T, b: T) T {
    return if (compare(a, b, false) > 0) b else a;
}

fn floatToInt(f: f64) T {
    if (!(f > -9.2e18 and f < 9.2e18)) {
        raiseWat("integer beyond 64 bits (a bignum)");
        return &nil_cell;
    }
    return mkInt(@intFromFloat(f));
}

export fn rt_erlang_round(a: T) T {
    return switch (tagOf(a)) {
        .int => a,
        .float => floatToInt(@round(as(Float, a).value)),
        else => badarg(),
    };
}

export fn rt_erlang_trunc(a: T) T {
    return switch (tagOf(a)) {
        .int => a,
        .float => floatToInt(@trunc(as(Float, a).value)),
        else => badarg(),
    };
}

export fn rt_erlang_floor(a: T) T {
    return switch (tagOf(a)) {
        .int => a,
        .float => floatToInt(@floor(as(Float, a).value)),
        else => badarg(),
    };
}

export fn rt_erlang_ceil(a: T) T {
    return switch (tagOf(a)) {
        .int => a,
        .float => floatToInt(@ceil(as(Float, a).value)),
        else => badarg(),
    };
}

export fn rt_erlang_float(a: T) T {
    return switch (tagOf(a)) {
        .int => mkFloat(@floatFromInt(as(Int, a).value)),
        .float => a,
        else => badarg(),
    };
}

fn intText(v: i64, buf: []u8) []const u8 {
    return std.fmt.bufPrint(buf, "{d}", .{v}) catch unreachable;
}

export fn rt_erlang_integer_to_binary(a: T) T {
    const v = intArg(a) orelse return &nil_cell;
    var buf: [24]u8 = undefined;
    return binCopy(intText(v, &buf));
}

export fn rt_erlang_integer_to_list(a: T) T {
    const v = intArg(a) orelse return &nil_cell;
    var buf: [24]u8 = undefined;
    return charsOf(intText(v, &buf));
}

fn parseInteger(bytes: []const u8) ?i64 {
    if (bytes.len == 0) return null;
    return std.fmt.parseInt(i64, bytes, 10) catch null;
}

export fn rt_erlang_binary_to_integer(b: T) T {
    if (tagOf(b) != .binary) return badarg();
    const v = parseInteger(binBytes(b)) orelse return badarg();
    return mkInt(v);
}

export fn rt_erlang_list_to_integer(l: T) T {
    const bytes = charsToBytes(l) orelse return badarg();
    const v = parseInteger(bytes) orelse return badarg();
    return mkInt(v);
}

export fn rt_erlang_atom_to_binary(a: T) T {
    if (tagOf(a) != .atom) return badarg();
    return binOf(atomBytes(a));
}

export fn rt_erlang_atom_to_binary2(a: T, _: T) T {
    return rt_erlang_atom_to_binary(a);
}

export fn rt_erlang_atom_to_list(a: T) T {
    if (tagOf(a) != .atom) return badarg();
    return utf8Chars(atomBytes(a));
}

export fn rt_erlang_binary_to_atom(b: T) T {
    if (tagOf(b) != .binary) return badarg();
    const bytes = binBytes(b);
    return internAtom(bytes.ptr, bytes.len);
}

export fn rt_erlang_binary_to_atom2(b: T, _: T) T {
    return rt_erlang_binary_to_atom(b);
}

export fn rt_erlang_list_to_atom(l: T) T {
    const bytes = charsToUtf8(l) orelse return badarg();
    return internAtom(bytes.ptr, bytes.len);
}

/// A list of the bytes of `bytes` (a Latin-1 char list).
fn charsOf(bytes: []const u8) T {
    var l: T = &nil_cell;
    var i = bytes.len;
    while (i > 0) {
        i -= 1;
        l = cons(mkInt(bytes[i]), l);
    }
    return l;
}

/// The code points of UTF-8 `bytes` as a list (invalid bytes as themselves).
fn utf8Chars(bytes: []const u8) T {
    const tmp = allocTerms(bytes.len);
    var n: usize = 0;
    var i: usize = 0;
    while (i < bytes.len) {
        const len = std.unicode.utf8ByteSequenceLength(bytes[i]) catch 1;
        const cp: u21 = if (i + len <= bytes.len)
            std.unicode.utf8Decode(bytes[i..][0..len]) catch bytes[i]
        else
            bytes[i];
        tmp[n] = mkInt(cp);
        n += 1;
        i += if (i + len <= bytes.len) len else 1;
    }
    return listFrom(tmp[0..n]);
}

/// A flat list of integers 0..255 as bytes, or null.
fn charsToBytes(l: T) ?[]const u8 {
    const items = listItems(l) orelse return null;
    const out = alloc(items.len);
    for (items, 0..) |it, i| {
        if (tagOf(it) != .int) return null;
        const v = as(Int, it).value;
        if (v < 0 or v > 255) return null;
        out[i] = @intCast(v);
    }
    return out[0..items.len];
}

/// A flat list of code points as UTF-8, or null.
fn charsToUtf8(l: T) ?[]const u8 {
    var bb = rt_bb_new();
    var it = l;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        const h = as(Cons, it).head;
        if (tagOf(h) != .int) return null;
        bb = rt_bb_utf8(bb, h);
        if (pending) return null;
    }
    if (tagOf(it) != .nil) return null;
    return binBytes(rt_bb_end(bb));
}

export fn rt_erlang_binary_to_list(b: T) T {
    if (tagOf(b) != .binary) return badarg();
    return charsOf(binBytes(b));
}

/// Flatten an iolist (bytes 0..255, binaries, nested lists) into `bb`.
fn ioFlatten(bb: T, t: T) bool {
    switch (tagOf(t)) {
        .binary => bbPush(bb, binBytes(t)),
        .nil => {},
        .cons => {
            var it = t;
            while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
                const h = as(Cons, it).head;
                if (tagOf(h) == .int) {
                    const v = as(Int, h).value;
                    if (v < 0 or v > 255) return false;
                    bbPush(bb, &.{@intCast(v)});
                } else if (!ioFlatten(bb, h)) return false;
            }
            if (tagOf(it) == .binary) {
                bbPush(bb, binBytes(it));
            } else if (tagOf(it) != .nil) return false;
        },
        else => return false,
    }
    return true;
}

export fn rt_erlang_iolist_to_binary(t: T) T {
    if (tagOf(t) == .binary) return t;
    const bb = rt_bb_new();
    if (!ioFlatten(bb, t)) return badarg();
    return rt_bb_end(bb);
}

export fn rt_erlang_list_to_binary(t: T) T {
    if (tagOf(t) != .cons and tagOf(t) != .nil) return badarg();
    return rt_erlang_iolist_to_binary(t);
}

export fn rt_erlang_iolist_size(t: T) T {
    const b = rt_erlang_iolist_to_binary(t);
    if (pending) return b;
    return mkInt(as(Bin, b).len);
}

export fn rt_erlang_float_to_binary(f: T) T {
    // `float_to_binary/1` is the 20-digit scientific form; the comptime
    // bodies only reach the `[short]` form (primitives' `toString`).
    _ = f;
    raiseWat("float_to_binary/1 (scientific form)");
    return &nil_cell;
}

export fn rt_erlang_float_to_binary2(f: T, opts: T) T {
    if (tagOf(f) != .float) return badarg();
    if (!(tagOf(opts) == .cons and as(Cons, opts).head == a_short and tagOf(as(Cons, opts).tail) == .nil)) {
        raiseWat("float_to_binary/2 with options other than [short]");
        return &nil_cell;
    }
    var buf: [64]u8 = undefined;
    return binCopy(shortFloat(as(Float, f).value, &buf));
}

export fn rt_erlang_float_to_list2(f: T, opts: T) T {
    const b = rt_erlang_float_to_binary2(f, opts);
    if (pending) return b;
    return charsOf(binBytes(b));
}

export fn rt_erlang_is_atom(t: T) T {
    return boolAtom(tagOf(t) == .atom);
}
export fn rt_erlang_is_binary(t: T) T {
    return boolAtom(tagOf(t) == .binary);
}
export fn rt_erlang_is_integer(t: T) T {
    return boolAtom(tagOf(t) == .int);
}
export fn rt_erlang_is_float(t: T) T {
    return boolAtom(tagOf(t) == .float);
}
export fn rt_erlang_is_number(t: T) T {
    return boolAtom(isNum(t));
}
export fn rt_erlang_is_list(t: T) T {
    return boolAtom(tagOf(t) == .cons or tagOf(t) == .nil);
}
export fn rt_erlang_is_tuple(t: T) T {
    return boolAtom(tagOf(t) == .tuple);
}
export fn rt_erlang_is_map(t: T) T {
    return boolAtom(tagOf(t) == .map);
}
export fn rt_erlang_is_function(t: T) T {
    return boolAtom(tagOf(t) == .fun);
}
export fn rt_erlang_is_boolean(t: T) T {
    return boolAtom(t == a_true or t == a_false);
}

/// `apply(F, Args)`.
export fn rt_erlang_apply(f: T, args: T) T {
    const items = listItems(args) orelse return badarg();
    return applyFun(f, items);
}

// ── floats as text ───────────────────────────────────────────────────────────

/// `float_to_binary(F, [short])`: the shortest digits that round-trip, written
/// in fixed notation or as `D.DDDeE`, whichever is shorter (fixed on a tie);
/// always one digit after the point at least.
fn shortFloat(f: f64, buf: []u8) []const u8 {
    if (f == 0) return if (std.math.signbit(f)) "-0.0" else "0.0";
    var sci: [64]u8 = undefined;
    const e_text = std.fmt.bufPrint(&sci, "{e}", .{f}) catch unreachable;
    // e_text: [-]D[.DDD]e[-]X
    var neg = false;
    var s = e_text;
    if (s[0] == '-') {
        neg = true;
        s = s[1..];
    }
    const e_at = std.mem.indexOfScalar(u8, s, 'e').?;
    const mant = s[0..e_at];
    const exp = std.fmt.parseInt(i32, s[e_at + 1 ..], 10) catch 0;
    var digits: [32]u8 = undefined;
    var nd: usize = 0;
    for (mant) |c| if (c != '.') {
        digits[nd] = c;
        nd += 1;
    };
    while (nd > 1 and digits[nd - 1] == '0') nd -= 1;
    const d = digits[0..nd];

    // Scientific: D.DDDeX
    var sbuf: [64]u8 = undefined;
    var sl: usize = 0;
    if (neg) {
        sbuf[sl] = '-';
        sl += 1;
    }
    sbuf[sl] = d[0];
    sl += 1;
    sbuf[sl] = '.';
    sl += 1;
    if (nd > 1) {
        @memcpy(sbuf[sl..][0 .. nd - 1], d[1..]);
        sl += nd - 1;
    } else {
        sbuf[sl] = '0';
        sl += 1;
    }
    const et = std.fmt.bufPrint(sbuf[sl..], "e{d}", .{exp}) catch unreachable;
    sl += et.len;

    // Fixed.
    var fbuf: [400]u8 = undefined;
    var fl: usize = 0;
    if (neg) {
        fbuf[fl] = '-';
        fl += 1;
    }
    const point: i32 = exp + 1; // digits before the point
    if (point <= 0) {
        fbuf[fl] = '0';
        fbuf[fl + 1] = '.';
        fl += 2;
        var z: i32 = 0;
        while (z < -point) : (z += 1) {
            fbuf[fl] = '0';
            fl += 1;
        }
        @memcpy(fbuf[fl..][0..nd], d);
        fl += nd;
    } else {
        const p: usize = @intCast(point);
        if (p >= nd) {
            @memcpy(fbuf[fl..][0..nd], d);
            fl += nd;
            for (0..p - nd) |_| {
                fbuf[fl] = '0';
                fl += 1;
            }
            fbuf[fl] = '.';
            fbuf[fl + 1] = '0';
            fl += 2;
        } else {
            @memcpy(fbuf[fl..][0..p], d[0..p]);
            fl += p;
            fbuf[fl] = '.';
            fl += 1;
            @memcpy(fbuf[fl..][0 .. nd - p], d[p..]);
            fl += nd - p;
        }
    }
    const pick = if (fl <= sl) fbuf[0..fl] else sbuf[0..sl];
    @memcpy(buf[0..pick.len], pick);
    return buf[0..pick.len];
}

// ── lists ────────────────────────────────────────────────────────────────────

fn listArg(l: T) ?[]T {
    return listItems(l) orelse {
        _ = badarg();
        return null;
    };
}

fn funArg(f: T, arity: u32) bool {
    if (tagOf(f) != .fun or as(Fun, f).arity != arity) {
        _ = badarg();
        return false;
    }
    return true;
}

export fn rt_lists_map(f: T, l: T) T {
    if (!funArg(f, 1)) return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    const out = allocTerms(items.len);
    for (items, 0..) |it, i| {
        out[i] = applyFun(f, &.{it});
        if (pending) return &nil_cell;
    }
    return listFrom(out[0..items.len]);
}

export fn rt_lists_foreach(f: T, l: T) T {
    if (!funArg(f, 1)) return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    for (items) |it| {
        _ = applyFun(f, &.{it});
        if (pending) return &nil_cell;
    }
    return a_ok;
}

export fn rt_lists_filter(f: T, l: T) T {
    if (!funArg(f, 1)) return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    const out = allocTerms(items.len);
    var n: usize = 0;
    for (items) |it| {
        const keep = applyFun(f, &.{it});
        if (pending) return &nil_cell;
        switch (rt_truth(keep)) {
            1 => {
                out[n] = it;
                n += 1;
            },
            0 => {},
            else => return badarg(),
        }
    }
    return listFrom(out[0..n]);
}

export fn rt_lists_foldl(f: T, acc0: T, l: T) T {
    if (!funArg(f, 2)) return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    var acc = acc0;
    for (items) |it| {
        acc = applyFun(f, &.{ it, acc });
        if (pending) return &nil_cell;
    }
    return acc;
}

export fn rt_lists_foldr(f: T, acc0: T, l: T) T {
    if (!funArg(f, 2)) return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    var acc = acc0;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        acc = applyFun(f, &.{ items[i], acc });
        if (pending) return &nil_cell;
    }
    return acc;
}

export fn rt_lists_any(f: T, l: T) T {
    if (!funArg(f, 1)) return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    for (items) |it| {
        const r = applyFun(f, &.{it});
        if (pending) return &nil_cell;
        switch (rt_truth(r)) {
            1 => return a_true,
            0 => {},
            else => return badarg(),
        }
    }
    return a_false;
}

export fn rt_lists_all(f: T, l: T) T {
    if (!funArg(f, 1)) return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    for (items) |it| {
        const r = applyFun(f, &.{it});
        if (pending) return &nil_cell;
        switch (rt_truth(r)) {
            0 => return a_false,
            1 => {},
            else => return badarg(),
        }
    }
    return a_true;
}

export fn rt_lists_reverse(l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    var out: T = &nil_cell;
    for (items) |it| out = cons(it, out);
    return out;
}

export fn rt_lists_reverse2(l: T, tail: T) T {
    const items = listArg(l) orelse return &nil_cell;
    var out: T = tail;
    for (items) |it| out = cons(it, out);
    return out;
}

export fn rt_lists_append2(a: T, b: T) T {
    return rt_append(a, b);
}

export fn rt_lists_append1(ls: T) T {
    const items = listArg(ls) orelse return &nil_cell;
    var out: T = &nil_cell;
    var i = items.len;
    while (i > 0) {
        i -= 1;
        out = rt_append(items[i], out);
        if (pending) return &nil_cell;
    }
    return out;
}

export fn rt_lists_join(sep: T, l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    if (items.len == 0) return &nil_cell;
    const out = allocTerms(items.len * 2 - 1);
    for (items, 0..) |it, i| {
        if (i > 0) out[i * 2 - 1] = sep;
        out[i * 2] = it;
    }
    return listFrom(out[0 .. items.len * 2 - 1]);
}

export fn rt_lists_member(x: T, l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    for (items) |it| if (compare(it, x, true) == 0) return a_true;
    return a_false;
}

export fn rt_lists_nth(n: T, l: T) T {
    const i = intArg(n) orelse return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    if (i < 1 or i > items.len) return rt_function_clause();
    return items[@intCast(i - 1)];
}

export fn rt_lists_nthtail(n: T, l: T) T {
    var i = intArg(n) orelse return &nil_cell;
    var it = l;
    while (i > 0) : (i -= 1) {
        if (tagOf(it) != .cons) return rt_function_clause();
        it = as(Cons, it).tail;
    }
    return it;
}

export fn rt_lists_sublist2(l: T, n: T) T {
    const len = intArg(n) orelse return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    if (len < 0) return rt_function_clause();
    const k: usize = @min(items.len, @as(usize, @intCast(len)));
    return listFrom(items[0..k]);
}

export fn rt_lists_sublist3(l: T, s: T, n: T) T {
    const start = intArg(s) orelse return &nil_cell;
    const len = intArg(n) orelse return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    if (start < 1 or len < 0) return rt_function_clause();
    const from: usize = @intCast(start - 1);
    if (from >= items.len) return &nil_cell;
    const k: usize = @min(items.len - from, @as(usize, @intCast(len)));
    return listFrom(items[from..][0..k]);
}

/// `lists:enumerate(Index, List)`: `[{Index, E1}, {Index + 1, E2}, …]`.
export fn rt_lists_enumerate2(first: T, l: T) T {
    const start = intArg(first) orelse return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    const out = allocTerms(items.len);
    for (items, 0..) |it, i| out[i] = tuple(&.{ mkInt(start + @as(i64, @intCast(i))), it });
    return listFrom(out[0..items.len]);
}

export fn rt_lists_enumerate1(l: T) T {
    return rt_lists_enumerate2(mkInt(1), l);
}

export fn rt_lists_duplicate(n: T, x: T) T {
    const k = intArg(n) orelse return &nil_cell;
    if (k < 0) return rt_function_clause();
    var out: T = &nil_cell;
    var i: i64 = 0;
    while (i < k) : (i += 1) out = cons(x, out);
    return out;
}

export fn rt_lists_seq(a: T, b: T) T {
    const from = intArg(a) orelse return &nil_cell;
    const to = intArg(b) orelse return &nil_cell;
    if (to < from - 1) return rt_function_clause();
    var out: T = &nil_cell;
    var i = to;
    while (i >= from) : (i -= 1) out = cons(mkInt(i), out);
    return out;
}

export fn rt_lists_zipwith(f: T, a: T, b: T) T {
    if (!funArg(f, 2)) return &nil_cell;
    const xs = listArg(a) orelse return &nil_cell;
    const ys = listArg(b) orelse return &nil_cell;
    if (xs.len != ys.len) return rt_function_clause();
    const out = allocTerms(xs.len);
    for (xs, ys, 0..) |x, y, i| {
        out[i] = applyFun(f, &.{ x, y });
        if (pending) return &nil_cell;
    }
    return listFrom(out[0..xs.len]);
}

export fn rt_lists_last(l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    if (items.len == 0) return rt_function_clause();
    return items[items.len - 1];
}

fn flattenInto(out: *std.ArrayListUnmanaged(T), l: T) bool {
    var it = l;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        const h = as(Cons, it).head;
        if (tagOf(h) == .cons or tagOf(h) == .nil) {
            if (!flattenInto(out, h)) return false;
        } else out.append(arenaAllocator(), h) catch return false;
    }
    return tagOf(it) == .nil;
}

export fn rt_lists_flatten(l: T) T {
    var out: std.ArrayListUnmanaged(T) = .empty;
    if (!flattenInto(&out, l)) return badarg();
    return listFrom(out.items);
}

fn sortTerms(items: []T) void {
    var i: usize = 1;
    while (i < items.len) : (i += 1) {
        var j = i;
        while (j > 0 and compare(items[j - 1], items[j], false) > 0) : (j -= 1) {
            const tmp = items[j];
            items[j] = items[j - 1];
            items[j - 1] = tmp;
        }
    }
}

export fn rt_lists_sort(l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    const copy = allocTerms(items.len);
    @memcpy(copy[0..items.len], items);
    sortTerms(copy[0..items.len]);
    return listFrom(copy[0..items.len]);
}

export fn rt_lists_usort(l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    const copy = allocTerms(items.len);
    @memcpy(copy[0..items.len], items);
    sortTerms(copy[0..items.len]);
    var n: usize = 0;
    for (copy[0..items.len]) |it| {
        if (n > 0 and compare(copy[n - 1], it, true) == 0) continue;
        copy[n] = it;
        n += 1;
    }
    return listFrom(copy[0..n]);
}

export fn rt_lists_keyfind(k: T, n: T, l: T) T {
    const pos = intArg(n) orelse return &nil_cell;
    const items = listArg(l) orelse return &nil_cell;
    for (items) |it| {
        if (tagOf(it) != .tuple) continue;
        const tp = as(Tuple, it);
        if (pos >= 1 and pos <= tp.arity and compare(tp.items[@intCast(pos - 1)], k, false) == 0) return it;
    }
    return a_false;
}

export fn rt_lists_concat(l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    const bb = rt_bb_new();
    for (items) |it| {
        switch (tagOf(it)) {
            .atom => bbPush(bb, atomBytes(it)),
            .int => {
                var buf: [24]u8 = undefined;
                bbPush(bb, intText(as(Int, it).value, &buf));
            },
            .float => {
                var buf: [64]u8 = undefined;
                bbPush(bb, shortFloat(as(Float, it).value, &buf));
            },
            else => if (!ioFlatten(bb, it)) return badarg(),
        }
    }
    return utf8Chars(binBytes(rt_bb_end(bb)));
}

// A throwaway allocator over the arena, for the few helpers that grow a list.
fn arenaAlloc(_: *anyopaque, len: usize, _: std.mem.Alignment, _: usize) ?[*]u8 {
    return alloc(len);
}
fn arenaResize(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) bool {
    return false;
}
fn arenaRemap(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize, _: usize) ?[*]u8 {
    return null;
}
fn arenaFree(_: *anyopaque, _: []u8, _: std.mem.Alignment, _: usize) void {}
const arena_vtable: std.mem.Allocator.VTable = .{ .alloc = arenaAlloc, .resize = arenaResize, .remap = arenaRemap, .free = arenaFree };
fn arenaAllocator() std.mem.Allocator {
    return .{ .ptr = undefined, .vtable = &arena_vtable };
}

// ── maps: BIFs ───────────────────────────────────────────────────────────────

export fn rt_maps_get(k: T, m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    const i = mapFind(mm, k) orelse {
        raiseError(tuple(&.{ a_badkey, k }));
        return &nil_cell;
    };
    return mm.vals[i];
}

export fn rt_maps_get3(k: T, m: T, default: T) T {
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    const i = mapFind(mm, k) orelse return default;
    return mm.vals[i];
}

export fn rt_maps_find(k: T, m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    const i = mapFind(mm, k) orelse return atomOf("error");
    return tuple(&.{ a_ok, mm.vals[i] });
}

export fn rt_maps_is_key(k: T, m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    return boolAtom(mapFind(as(Map, m), k) != null);
}

export fn rt_maps_put(k: T, v: T, m: T) T {
    return rt_map_put(m, k, v);
}

export fn rt_maps_remove(k: T, m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    const i = mapFind(mm, k) orelse return m;
    const out = mkMap(mm.count - 1);
    var j: usize = 0;
    for (0..mm.count) |x| {
        if (x == i) continue;
        out.keys[j] = mm.keys[x];
        out.vals[j] = mm.vals[x];
        j += 1;
    }
    return @ptrCast(out);
}

export fn rt_maps_keys(m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    return listFrom(mm.keys[0..mm.count]);
}

export fn rt_maps_values(m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    return listFrom(mm.vals[0..mm.count]);
}

export fn rt_maps_size(m: T) T {
    return rt_erlang_map_size(m);
}

export fn rt_maps_to_list(m: T) T {
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    const out = allocTerms(mm.count);
    for (0..mm.count) |i| out[i] = tuple(&.{ mm.keys[i], mm.vals[i] });
    return listFrom(out[0..mm.count]);
}

export fn rt_maps_from_list(l: T) T {
    const items = listArg(l) orelse return &nil_cell;
    var m: T = @ptrCast(mkMap(0));
    for (items) |it| {
        if (tagOf(it) != .tuple or as(Tuple, it).arity != 2) return badarg();
        m = mapPut(m, as(Tuple, it).items[0], as(Tuple, it).items[1]);
    }
    return m;
}

export fn rt_maps_merge(a: T, b: T) T {
    if (tagOf(a) != .map) return badmap(a);
    if (tagOf(b) != .map) return badmap(b);
    var m = a;
    const mb = as(Map, b);
    for (0..mb.count) |i| m = mapPut(m, mb.keys[i], mb.vals[i]);
    return m;
}

export fn rt_maps_map(f: T, m: T) T {
    if (!funArg(f, 2)) return &nil_cell;
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    const out = mkMap(mm.count);
    for (0..mm.count) |i| {
        out.keys[i] = mm.keys[i];
        out.vals[i] = applyFun(f, &.{ mm.keys[i], mm.vals[i] });
        if (pending) return &nil_cell;
    }
    return @ptrCast(out);
}

export fn rt_maps_fold(f: T, acc0: T, m: T) T {
    if (!funArg(f, 3)) return &nil_cell;
    if (tagOf(m) != .map) return badmap(m);
    const mm = as(Map, m);
    var acc = acc0;
    for (0..mm.count) |i| {
        acc = applyFun(f, &.{ mm.keys[i], mm.vals[i], acc });
        if (pending) return &nil_cell;
    }
    return acc;
}

// ── strings (unicode:chardata as binaries or code-point lists) ───────────────

/// The UTF-8 bytes of chardata `t` (a binary, or a list of code points and
/// binaries), or null.
fn chardata(t: T) ?[]const u8 {
    if (tagOf(t) == .binary) return binBytes(t);
    if (tagOf(t) != .cons and tagOf(t) != .nil) return null;
    const bb = rt_bb_new();
    if (!chardataInto(bb, t)) return null;
    return binBytes(rt_bb_end(bb));
}

fn chardataInto(bb: T, t: T) bool {
    var it = t;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        const h = as(Cons, it).head;
        switch (tagOf(h)) {
            .int => {
                _ = rt_bb_utf8(bb, h);
                if (pending) return false;
            },
            .binary => bbPush(bb, binBytes(h)),
            .cons, .nil => if (!chardataInto(bb, h)) return false,
            else => return false,
        }
    }
    if (tagOf(it) == .binary) {
        bbPush(bb, binBytes(it));
        return true;
    }
    return tagOf(it) == .nil;
}

/// The result of a `string:` function whose input was `like`: a binary input
/// answers a binary, a list input a code-point list.
fn strResult(like: T, bytes: []const u8) T {
    if (tagOf(like) == .binary) return binOf(bytes);
    return utf8Chars(bytes);
}

fn strArg(t: T) ?[]const u8 {
    return chardata(t) orelse {
        raiseError(tuple(&.{ a_badarg, t }));
        return null;
    };
}

/// Code-point boundaries of UTF-8 `s`: `cps[i]` is the byte offset of the
/// i-th code point, `cps[n] = s.len`. A `\r\n` pair counts as one grapheme,
/// the only multi-code-point grapheme the comptime bodies meet.
fn graphemes(s: []const u8) []usize {
    const out: [*]usize = @ptrCast(@alignCast(alloc((s.len + 1) * @sizeOf(usize))));
    var n: usize = 0;
    var i: usize = 0;
    while (i < s.len) {
        out[n] = i;
        n += 1;
        if (s[i] == '\r' and i + 1 < s.len and s[i + 1] == '\n') {
            i += 2;
            continue;
        }
        const len = std.unicode.utf8ByteSequenceLength(s[i]) catch 1;
        i += if (i + len <= s.len) len else 1;
    }
    out[n] = s.len;
    return out[0 .. n + 1];
}

export fn rt_string_length(t: T) T {
    const s = strArg(t) orelse return &nil_cell;
    return mkInt(@intCast(graphemes(s).len - 1));
}

export fn rt_string_is_empty(t: T) T {
    const s = strArg(t) orelse return &nil_cell;
    return boolAtom(s.len == 0);
}

fn caseMap(t: T, upper: bool) T {
    const s = strArg(t) orelse return &nil_cell;
    const out = alloc(s.len);
    for (s, 0..) |c, i| out[i] = if (upper) std.ascii.toUpper(c) else std.ascii.toLower(c);
    // Non-ASCII letters keep their bytes: OTP maps them through the Unicode
    // tables, which this runtime does not carry.
    for (s) |c| if (c >= 0x80) {
        raiseWat("string case mapping of a non-ASCII character");
        return &nil_cell;
    };
    return strResult(t, out[0..s.len]);
}

export fn rt_string_uppercase(t: T) T {
    return caseMap(t, true);
}

export fn rt_string_lowercase(t: T) T {
    return caseMap(t, false);
}

fn isWhite(c: u8) bool {
    return c == ' ' or c == '\t' or c == '\n' or c == '\r' or c == 11 or c == 12;
}

fn trimBytes(s: []const u8, dir: T) []const u8 {
    var a: usize = 0;
    var b: usize = s.len;
    if (dir != a_trailing) while (a < b and isWhite(s[a])) : (a += 1) {};
    if (dir != a_leading) while (b > a and isWhite(s[b - 1])) : (b -= 1) {};
    return s[a..b];
}

export fn rt_string_trim(t: T) T {
    const s = strArg(t) orelse return &nil_cell;
    return strResult(t, trimBytes(s, a_both));
}

export fn rt_string_trim2(t: T, dir: T) T {
    const s = strArg(t) orelse return &nil_cell;
    if (dir != a_leading and dir != a_trailing and dir != a_both) return badarg();
    return strResult(t, trimBytes(s, dir));
}

export fn rt_string_find(t: T, p: T) T {
    const s = strArg(t) orelse return &nil_cell;
    const pat = strArg(p) orelse return &nil_cell;
    if (pat.len == 0) return t;
    const i = std.mem.indexOf(u8, s, pat) orelse return a_nomatch;
    return strResult(t, s[i..]);
}

export fn rt_string_prefix(t: T, p: T) T {
    const s = strArg(t) orelse return &nil_cell;
    const pat = strArg(p) orelse return &nil_cell;
    if (!std.mem.startsWith(u8, s, pat)) return a_nomatch;
    return strResult(t, s[pat.len..]);
}

export fn rt_string_equal(a: T, b: T) T {
    const x = strArg(a) orelse return &nil_cell;
    const y = strArg(b) orelse return &nil_cell;
    return boolAtom(std.mem.eql(u8, x, y));
}

fn sliceBytes(s: []const u8, start: i64, len: ?i64) []const u8 {
    const g = graphemes(s);
    const n = g.len - 1;
    const from: usize = @min(n, @as(usize, @intCast(@max(start, 0))));
    const to: usize = if (len) |l| @min(n, from + @as(usize, @intCast(@max(l, 0)))) else n;
    return s[g[from]..g[to]];
}

export fn rt_string_slice2(t: T, st: T) T {
    const s = strArg(t) orelse return &nil_cell;
    const start = intArg(st) orelse return &nil_cell;
    if (start < 0) return badarg();
    return strResult(t, sliceBytes(s, start, null));
}

export fn rt_string_slice3(t: T, st: T, ln: T) T {
    const s = strArg(t) orelse return &nil_cell;
    const start = intArg(st) orelse return &nil_cell;
    const len = intArg(ln) orelse return &nil_cell;
    if (start < 0 or len < 0) return badarg();
    return strResult(t, sliceBytes(s, start, len));
}

/// `string:split(S, Sep)` / `string:split(S, Sep, all)`.
fn split(t: T, p: T, all: bool) T {
    const s = strArg(t) orelse return &nil_cell;
    const sep = strArg(p) orelse return &nil_cell;
    if (sep.len == 0) return listFrom(&.{t});
    var parts: std.ArrayListUnmanaged(T) = .empty;
    var rest = s;
    while (std.mem.indexOf(u8, rest, sep)) |i| {
        parts.append(arenaAllocator(), strResult(t, rest[0..i])) catch return badarg();
        rest = rest[i + sep.len ..];
        if (!all) break;
    }
    parts.append(arenaAllocator(), strResult(t, rest)) catch return badarg();
    return listFrom(parts.items);
}

export fn rt_string_split(t: T, p: T) T {
    return split(t, p, false);
}

export fn rt_string_split3(t: T, p: T, where: T) T {
    if (where == a_all) return split(t, p, true);
    if (where == atomOf("leading")) return split(t, p, false);
    raiseWat("string:split/3 other than leading/all");
    return &nil_cell;
}

export fn rt_string_replace(t: T, p: T, r: T) T {
    // `string:replace/3` replaces the leading match and answers chardata
    // `[Before, Replacement, After]`.
    const s = strArg(t) orelse return &nil_cell;
    const pat = strArg(p) orelse return &nil_cell;
    const rep = strArg(r) orelse return &nil_cell;
    if (pat.len == 0) return listFrom(&.{t});
    const i = std.mem.indexOf(u8, s, pat) orelse return listFrom(&.{t});
    return listFrom(&.{ binOf(s[0..i]), binOf(rep), binOf(s[i + pat.len ..]) });
}

export fn rt_string_reverse(t: T) T {
    const s = strArg(t) orelse return &nil_cell;
    const g = graphemes(s);
    const out = alloc(s.len);
    var o: usize = 0;
    var i = g.len - 1;
    while (i > 0) {
        i -= 1;
        const part = s[g[i]..g[i + 1]];
        @memcpy(out[o..][0..part.len], part);
        o += part.len;
    }
    return strResult(t, out[0..s.len]);
}

export fn rt_string_to_integer(t: T) T {
    const s = strArg(t) orelse return &nil_cell;
    var i: usize = 0;
    if (i < s.len and (s[i] == '-' or s[i] == '+')) i += 1;
    const d0 = i;
    while (i < s.len and std.ascii.isDigit(s[i])) i += 1;
    if (i == d0) return tuple(&.{ a_error, atomOf("no_integer") });
    const v = std.fmt.parseInt(i64, s[0..i], 10) catch return tuple(&.{ a_error, atomOf("no_integer") });
    return tuple(&.{ mkInt(v), strResult(t, s[i..]) });
}

// ── binary: and unicode: ─────────────────────────────────────────────────────

fn binArg(t: T) ?[]const u8 {
    if (tagOf(t) != .binary) {
        _ = badarg();
        return null;
    }
    return binBytes(t);
}

export fn rt_binary_part(b: T, p: T, l: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const pos = intArg(p) orelse return &nil_cell;
    const len = intArg(l) orelse return &nil_cell;
    const a = if (len < 0) pos + len else pos;
    const z = if (len < 0) pos else pos + len;
    if (a < 0 or z > s.len or a > z) return badarg();
    return binOf(s[@intCast(a)..@intCast(z)]);
}

export fn rt_binary_first(b: T) T {
    const s = binArg(b) orelse return &nil_cell;
    if (s.len == 0) return badarg();
    return mkInt(s[0]);
}

export fn rt_binary_last(b: T) T {
    const s = binArg(b) orelse return &nil_cell;
    if (s.len == 0) return badarg();
    return mkInt(s[s.len - 1]);
}

export fn rt_binary_at(b: T, p: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const i = intArg(p) orelse return &nil_cell;
    if (i < 0 or i >= s.len) return badarg();
    return mkInt(s[@intCast(i)]);
}

export fn rt_binary_copy(b: T, n: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const k = intArg(n) orelse return &nil_cell;
    if (k < 0) return badarg();
    const count: usize = @intCast(k);
    const out = alloc(s.len * count);
    for (0..count) |i| @memcpy(out[i * s.len ..][0..s.len], s);
    return mkBin(out, s.len * count);
}

export fn rt_binary_match(b: T, p: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const pat = binArg(p) orelse return &nil_cell;
    if (pat.len == 0) return badarg();
    const i = std.mem.indexOf(u8, s, pat) orelse return a_nomatch;
    return tuple(&.{ mkInt(@intCast(i)), mkInt(@intCast(pat.len)) });
}

fn replaceBytes(s: []const u8, pat: []const u8, rep: []const u8, all: bool) T {
    const bb = rt_bb_new();
    var rest = s;
    while (std.mem.indexOf(u8, rest, pat)) |i| {
        bbPush(bb, rest[0..i]);
        bbPush(bb, rep);
        rest = rest[i + pat.len ..];
        if (!all) break;
    }
    bbPush(bb, rest);
    return rt_bb_end(bb);
}

export fn rt_binary_replace3(b: T, p: T, r: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const pat = binArg(p) orelse return &nil_cell;
    const rep = binArg(r) orelse return &nil_cell;
    if (pat.len == 0) return badarg();
    return replaceBytes(s, pat, rep, false);
}

export fn rt_binary_replace4(b: T, p: T, r: T, opts: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const pat = binArg(p) orelse return &nil_cell;
    const rep = binArg(r) orelse return &nil_cell;
    if (pat.len == 0) return badarg();
    const items = listArg(opts) orelse return &nil_cell;
    var all = false;
    for (items) |o| {
        if (o == a_global) all = true else {
            raiseWat("binary:replace/4 with options other than [global]");
            return &nil_cell;
        }
    }
    return replaceBytes(s, pat, rep, all);
}

export fn rt_binary_split2(b: T, p: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const pat = binArg(p) orelse return &nil_cell;
    if (pat.len == 0) return badarg();
    const i = std.mem.indexOf(u8, s, pat) orelse return listFrom(&.{b});
    return listFrom(&.{ binOf(s[0..i]), binOf(s[i + pat.len ..]) });
}

export fn rt_binary_split3(b: T, p: T, opts: T) T {
    const s = binArg(b) orelse return &nil_cell;
    const pat = binArg(p) orelse return &nil_cell;
    if (pat.len == 0) return badarg();
    const items = listArg(opts) orelse return &nil_cell;
    var all = false;
    for (items) |o| {
        if (o == a_global) all = true else {
            raiseWat("binary:split/3 with options other than [global]");
            return &nil_cell;
        }
    }
    var parts: std.ArrayListUnmanaged(T) = .empty;
    var rest = s;
    while (std.mem.indexOf(u8, rest, pat)) |i| {
        parts.append(arenaAllocator(), binOf(rest[0..i])) catch return badarg();
        rest = rest[i + pat.len ..];
        if (!all) break;
    }
    parts.append(arenaAllocator(), binOf(rest)) catch return badarg();
    return listFrom(parts.items);
}

export fn rt_unicode_characters_to_list(t: T) T {
    const s = chardata(t) orelse return badarg();
    return utf8Chars(s);
}

export fn rt_unicode_characters_to_list2(t: T, _: T) T {
    return rt_unicode_characters_to_list(t);
}

export fn rt_unicode_characters_to_binary(t: T) T {
    const s = chardata(t) orelse return badarg();
    return binOf(s);
}

export fn rt_unicode_characters_to_binary2(t: T, _: T) T {
    return rt_unicode_characters_to_binary(t);
}

export fn rt_math_floor(a: T) T {
    if (!isNum(a)) return badarg();
    return mkFloat(@floor(numAsFloat(a)));
}

export fn rt_math_ceil(a: T) T {
    if (!isNum(a)) return badarg();
    return mkFloat(@ceil(numAsFloat(a)));
}

export fn rt_math_sqrt(a: T) T {
    if (!isNum(a) or numAsFloat(a) < 0) return badarg();
    return mkFloat(@sqrt(numAsFloat(a)));
}

export fn rt_math_pow(a: T, b: T) T {
    if (!isNum(a) or !isNum(b)) return badarg();
    return mkFloat(std.math.pow(f64, numAsFloat(a), numAsFloat(b)));
}

// ── io_lib:format ~p / ~w / ~s ──────────────────────────────────────────────

fn needsQuote(name: []const u8) bool {
    if (name.len == 0) return true;
    if (!(name[0] >= 'a' and name[0] <= 'z')) return true;
    for (name[1..]) |c| if (!(std.ascii.isAlphanumeric(c) or c == '_' or c == '@')) return true;
    const reserved = [_][]const u8{ "after", "and", "andalso", "band", "begin", "bnot", "bor", "bsl", "bsr", "bxor", "case", "catch", "cond", "div", "end", "fun", "if", "let", "maybe", "not", "of", "or", "orelse", "receive", "rem", "try", "when", "xor", "else" };
    for (reserved) |r| if (std.mem.eql(u8, r, name)) return true;
    return false;
}

fn writeAtomText(bb: T, name: []const u8) void {
    if (!needsQuote(name)) return bbPush(bb, name);
    bbPush(bb, "'");
    for (name) |c| {
        if (c == '\'' or c == '\\') bbPush(bb, "\\");
        bbPush(bb, &.{c});
    }
    bbPush(bb, "'");
}

fn printableLatin1(c: i64) bool {
    return (c >= 32 and c <= 126) or (c >= 160 and c <= 255) or c == '\n' or c == '\r' or c == '\t' or c == 11 or c == 8 or c == 12 or c == 27 or c == 7;
}

fn printableUnicode(c: i64) bool {
    return printableLatin1(c) or (c > 255 and c <= 0x10FFFF and !(c >= 0xD800 and c <= 0xDFFF) and c != 0xFFFE and c != 0xFFFF);
}

fn writeEscapedChar(bb: T, c: i64, quote: u8) void {
    switch (c) {
        '\n' => bbPush(bb, "\\n"),
        '\r' => bbPush(bb, "\\r"),
        '\t' => bbPush(bb, "\\t"),
        11 => bbPush(bb, "\\v"),
        8 => bbPush(bb, "\\b"),
        12 => bbPush(bb, "\\f"),
        27 => bbPush(bb, "\\e"),
        7 => bbPush(bb, "\\d"),
        '\\' => bbPush(bb, "\\\\"),
        else => {
            if (c == quote) {
                bbPush(bb, "\\");
                bbPush(bb, &.{quote});
            } else {
                var buf: [4]u8 = undefined;
                const n = std.unicode.utf8Encode(@intCast(c), &buf) catch 0;
                bbPush(bb, buf[0..n]);
            }
        },
    }
}

/// A printable char list (the `~p` "string" test, unicode range).
fn isPrintableList(t: T) bool {
    if (tagOf(t) != .cons) return false;
    var it = t;
    while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
        const h = as(Cons, it).head;
        if (tagOf(h) != .int or !printableUnicode(as(Int, h).value)) return false;
    }
    return tagOf(it) == .nil;
}

/// Write `t` as `~p` / `~w` do, without the line breaking `~p` applies past
/// 80 columns.
fn writeTerm(bb: T, t: T, pretty: bool) void {
    switch (tagOf(t)) {
        .int => {
            var buf: [24]u8 = undefined;
            bbPush(bb, intText(as(Int, t).value, &buf));
        },
        .float => {
            var buf: [64]u8 = undefined;
            bbPush(bb, shortFloat(as(Float, t).value, &buf));
        },
        .atom => writeAtomText(bb, atomBytes(t)),
        .binary => {
            const s = binBytes(t);
            var ascii = true;
            for (s) |c| if (!printableLatin1(c) or c >= 128) {
                ascii = false;
                break;
            };
            if (pretty and ascii) {
                bbPush(bb, "<<\"");
                for (s) |c| writeEscapedChar(bb, c, '"');
                bbPush(bb, "\">>");
                return;
            }
            if (pretty and std.unicode.utf8ValidateSlice(s)) {
                var ok = true;
                var view = std.unicode.Utf8View.initUnchecked(s).iterator();
                while (view.nextCodepoint()) |cp| if (!printableUnicode(cp)) {
                    ok = false;
                    break;
                };
                if (ok and s.len > 0) {
                    bbPush(bb, "<<\"");
                    view = std.unicode.Utf8View.initUnchecked(s).iterator();
                    while (view.nextCodepoint()) |cp| writeEscapedChar(bb, cp, '"');
                    bbPush(bb, "\"/utf8>>");
                    return;
                }
            }
            bbPush(bb, "<<");
            for (s, 0..) |c, i| {
                if (i > 0) bbPush(bb, ",");
                var buf: [4]u8 = undefined;
                bbPush(bb, intText(c, &buf));
            }
            bbPush(bb, ">>");
        },
        .nil => bbPush(bb, "[]"),
        .cons => {
            if (pretty and isPrintableList(t)) {
                bbPush(bb, "\"");
                var it = t;
                while (tagOf(it) == .cons) : (it = as(Cons, it).tail) writeEscapedChar(bb, as(Int, as(Cons, it).head).value, '"');
                bbPush(bb, "\"");
                return;
            }
            bbPush(bb, "[");
            var it = t;
            var first = true;
            while (tagOf(it) == .cons) : (it = as(Cons, it).tail) {
                if (!first) bbPush(bb, ",");
                first = false;
                writeTerm(bb, as(Cons, it).head, pretty);
            }
            if (tagOf(it) != .nil) {
                bbPush(bb, "|");
                writeTerm(bb, it, pretty);
            }
            bbPush(bb, "]");
        },
        .tuple => {
            const tp = as(Tuple, t);
            bbPush(bb, "{");
            for (0..tp.arity) |i| {
                if (i > 0) bbPush(bb, ",");
                writeTerm(bb, tp.items[i], pretty);
            }
            bbPush(bb, "}");
        },
        .map => {
            const m = as(Map, t);
            const order_idx = sortedKeys(m);
            bbPush(bb, "#{");
            for (order_idx, 0..) |k, i| {
                if (i > 0) bbPush(bb, ",");
                writeTerm(bb, m.keys[k], pretty);
                bbPush(bb, " => ");
                writeTerm(bb, m.vals[k], pretty);
            }
            bbPush(bb, "}");
        },
        .fun => bbPush(bb, "#Fun<bp_wat>"),
        .builder => bbPush(bb, "<<>>"),
    }
}

/// `io_lib:format(Format, Args)` for the directives the comptime bodies use:
/// `~p`, `~w`, `~s`, `~ts`, `~n`, `~~`. Answers a code-point list, as OTP does.
export fn rt_io_lib_format(fmt: T, args: T) T {
    const f = chardata(fmt) orelse return badarg();
    const items = listArg(args) orelse return &nil_cell;
    const bb = rt_bb_new();
    var ai: usize = 0;
    var i: usize = 0;
    while (i < f.len) : (i += 1) {
        const c = f[i];
        if (c != '~') {
            bbPush(bb, &.{c});
            continue;
        }
        i += 1;
        if (i >= f.len) return badarg();
        var d = f[i];
        if (d == 't' and i + 1 < f.len) {
            i += 1;
            d = f[i];
        }
        switch (d) {
            'n' => bbPush(bb, "\n"),
            '~' => bbPush(bb, "~"),
            'p', 'w' => {
                if (ai >= items.len) return badarg();
                writeTerm(bb, items[ai], d == 'p');
                ai += 1;
            },
            's' => {
                if (ai >= items.len) return badarg();
                const a = items[ai];
                ai += 1;
                if (tagOf(a) == .atom) bbPush(bb, atomBytes(a)) else {
                    const s = chardata(a) orelse return badarg();
                    bbPush(bb, s);
                }
            },
            else => {
                raiseWat("io_lib:format directive other than ~p ~w ~s ~n ~~");
                return &nil_cell;
            },
        }
    }
    if (ai != items.len) return badarg();
    return utf8Chars(binBytes(rt_bb_end(bb)));
}

/// What a body printed (`io:format`), kept in the module's memory — never on
/// the compiler's stdout. The BEAM runtime sends a body's prints to stderr;
/// here they are captured and dropped with the instance.
var printed: ?T = null;

fn printBuffer() T {
    if (printed) |b| return b;
    const b = rt_bb_new();
    printed = b;
    return b;
}

/// `io:format(Format, Args)`.
export fn rt_io_format(fmt: T, args: T) T {
    const chars = rt_io_lib_format(fmt, args);
    if (pending) return &nil_cell;
    const bytes = chardata(chars) orelse return badarg();
    bbPush(printBuffer(), bytes);
    return a_ok;
}

/// `io:format(Format)`.
export fn rt_io_format1(fmt: T) T {
    return rt_io_format(fmt, &nil_cell);
}

/// The captured prints (the host may read them for a diagnostic).
export fn rt_printed() T {
    return rt_bb_end(printBuffer());
}

// ── json:encode ──────────────────────────────────────────────────────────────

fn jsonString(bb: T, s: []const u8) bool {
    if (!std.unicode.utf8ValidateSlice(s)) return false;
    bbPush(bb, "\"");
    for (s) |c| switch (c) {
        '"' => bbPush(bb, "\\\""),
        '\\' => bbPush(bb, "\\\\"),
        '\n' => bbPush(bb, "\\n"),
        '\r' => bbPush(bb, "\\r"),
        '\t' => bbPush(bb, "\\t"),
        8 => bbPush(bb, "\\b"),
        12 => bbPush(bb, "\\f"),
        0...7, 11, 14...31 => {
            const hex = "0123456789ABCDEF";
            bbPush(bb, &.{ '\\', 'u', '0', '0', hex[c >> 4], hex[c & 15] });
        },
        else => bbPush(bb, &.{c}),
    };
    bbPush(bb, "\"");
    return true;
}

/// `json:encode/1` (OTP 27+): what it raises is `{unsupported_type, T}` and
/// `{invalid_byte, B}` — here `badarg` for an invalid UTF-8 string, which no
/// comptime reply carries.
fn jsonEncode(bb: T, t: T) bool {
    switch (tagOf(t)) {
        .int => {
            var buf: [24]u8 = undefined;
            bbPush(bb, intText(as(Int, t).value, &buf));
        },
        .float => {
            var buf: [64]u8 = undefined;
            bbPush(bb, shortFloat(as(Float, t).value, &buf));
        },
        .atom => {
            if (t == a_true or t == a_false or t == a_null) {
                bbPush(bb, atomBytes(t));
            } else if (!jsonString(bb, atomBytes(t))) return badJson(t);
        },
        .binary => if (!jsonString(bb, binBytes(t))) return badJson(t),
        .nil => bbPush(bb, "[]"),
        .cons => {
            const items = listItems(t) orelse return badJson(t);
            bbPush(bb, "[");
            for (items, 0..) |it, i| {
                if (i > 0) bbPush(bb, ",");
                if (!jsonEncode(bb, it)) return false;
            }
            bbPush(bb, "]");
        },
        .map => {
            const m = as(Map, t);
            bbPush(bb, "{");
            for (0..m.count) |i| {
                if (i > 0) bbPush(bb, ",");
                const k = m.keys[i];
                switch (tagOf(k)) {
                    .binary => if (!jsonString(bb, binBytes(k))) return badJson(k),
                    .atom => if (!jsonString(bb, atomBytes(k))) return badJson(k),
                    .int => {
                        var buf: [24]u8 = undefined;
                        _ = jsonString(bb, intText(as(Int, k).value, &buf));
                    },
                    else => return badJson(k),
                }
                bbPush(bb, ":");
                if (!jsonEncode(bb, m.vals[i])) return false;
            }
            bbPush(bb, "}");
        },
        else => return badJson(t),
    }
    return true;
}

fn badJson(t: T) bool {
    raiseError(tuple(&.{ a_unsupported_type, t }));
    return false;
}

export fn rt_json_encode(t: T) T {
    const bb = rt_bb_new();
    if (!jsonEncode(bb, t)) return &nil_cell;
    return rt_bb_end(bb);
}

// ── ETF (the argument) ───────────────────────────────────────────────────────

const Reader = struct {
    s: []const u8,
    i: usize = 0,
    fn u8_(r: *Reader) ?u8 {
        if (r.i >= r.s.len) return null;
        r.i += 1;
        return r.s[r.i - 1];
    }
    fn be(r: *Reader, comptime I: type) ?I {
        const n = @sizeOf(I);
        if (r.i + n > r.s.len) return null;
        const v = std.mem.readInt(I, r.s[r.i..][0..n], .big);
        r.i += n;
        return v;
    }
    fn bytes(r: *Reader, n: usize) ?[]const u8 {
        if (r.i + n > r.s.len) return null;
        r.i += n;
        return r.s[r.i - n .. r.i];
    }
};

fn etfTerm(r: *Reader) ?T {
    const tag = r.u8_() orelse return null;
    switch (tag) {
        97 => return mkInt(r.u8_() orelse return null), // SMALL_INTEGER
        98 => return mkInt(r.be(i32) orelse return null), // INTEGER
        110 => { // SMALL_BIG
            const n = r.u8_() orelse return null;
            const sign = r.u8_() orelse return null;
            const ds = r.bytes(n) orelse return null;
            if (n > 8) return null;
            var v: u64 = 0;
            var k: usize = n;
            while (k > 0) {
                k -= 1;
                v = (v << 8) | ds[k];
            }
            if (v > std.math.maxInt(i64)) return null;
            const iv: i64 = @intCast(v);
            return mkInt(if (sign == 1) -iv else iv);
        },
        70 => return mkFloat(@bitCast(r.be(u64) orelse return null)), // NEW_FLOAT
        106 => return &nil_cell, // NIL
        108 => { // LIST
            const n = r.be(u32) orelse return null;
            const items = allocTerms(n);
            for (0..n) |i| items[i] = etfTerm(r) orelse return null;
            var l = etfTerm(r) orelse return null;
            var i: usize = n;
            while (i > 0) {
                i -= 1;
                l = cons(items[i], l);
            }
            return l;
        },
        107 => { // STRING_EXT: a list of bytes
            const n = r.be(u16) orelse return null;
            return charsOf(r.bytes(n) orelse return null);
        },
        104 => { // SMALL_TUPLE
            const n = r.u8_() orelse return null;
            const t = mkTuple(n);
            for (0..n) |i| t.items[i] = etfTerm(r) orelse return null;
            return @ptrCast(t);
        },
        105 => { // LARGE_TUPLE
            const n = r.be(u32) orelse return null;
            const t = mkTuple(n);
            for (0..n) |i| t.items[i] = etfTerm(r) orelse return null;
            return @ptrCast(t);
        },
        116 => { // MAP
            const n = r.be(u32) orelse return null;
            var m: T = @ptrCast(mkMap(0));
            for (0..n) |_| {
                const k = etfTerm(r) orelse return null;
                const v = etfTerm(r) orelse return null;
                m = mapPut(m, k, v);
            }
            return m;
        },
        109 => { // BINARY
            const n = r.be(u32) orelse return null;
            return binOf(r.bytes(n) orelse return null);
        },
        118 => { // ATOM_UTF8
            const n = r.be(u16) orelse return null;
            const b = r.bytes(n) orelse return null;
            return internAtom(b.ptr, b.len);
        },
        119 => { // SMALL_ATOM_UTF8
            const n = r.u8_() orelse return null;
            const b = r.bytes(n) orelse return null;
            return internAtom(b.ptr, b.len);
        },
        else => return null,
    }
}

/// Decode `binary_to_term` bytes (the version byte 131 first). A tag
/// `etf.zig` does not write traps — the encoder and this decoder are a pair.
export fn rt_etf_decode(ptr: [*]const u8, len: usize) T {
    var r: Reader = .{ .s = ptr[0..len] };
    if ((r.u8_() orelse 0) != 131) @trap();
    return etfTerm(&r) orelse @trap();
}

/// `Class:Reason`, each as `~p` writes it — the first line of the text the
/// BEAM runtime's `safe_call` reports for an exception out of `main`.
export fn rt_describe(class: T, reason: T) T {
    const bb = rt_bb_new();
    writeTerm(bb, class, true);
    bbPush(bb, ":");
    writeTerm(bb, reason, true);
    return rt_bb_end(bb);
}

// ── tests (native: the pure helpers) ─────────────────────────────────────────

test "shortFloat: the shortest form, fixed on a tie" {
    const cases = [_]struct { f64, []const u8 }{
        .{ 0.1, "0.1" },                                     .{ 1.0e21, "1.0e21" },           .{ 1.0e20, "1.0e20" },
        .{ 123.0, "123.0" },                                 .{ 1.0e-5, "1.0e-5" },           .{ 0.0001, "0.0001" },
        .{ 1.0e15, "1.0e15" },                               .{ 123456789.0, "123456789.0" }, .{ 0.30000000000000004, "0.30000000000000004" },
        .{ 1.2345678901234567e19, "1.2345678901234567e19" }, .{ -0.0, "-0.0" },               .{ 2.0e-10, "2.0e-10" },
        .{ 1.5, "1.5" },                                     .{ 100.0, "100.0" },
    };
    for (cases) |c| {
        var buf: [64]u8 = undefined;
        try std.testing.expectEqualStrings(c[1], shortFloat(c[0], &buf));
    }
}
