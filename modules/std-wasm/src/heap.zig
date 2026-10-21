//! The heap of a wasm program, as erlang's (decisions 448, 449): a heap per
//! process (a `@Async`; a BEAM process in translated code), allocation on the
//! current process's heap, collection by copying the live values, a value
//! copied between heaps as an erlang message is, a heap released whole when
//! its process ends, and a run that exhausts memory trapping — never
//! answering with damaged data (448 (4), 67).
//!
//! In std-wasm's `program` table (`heap.*`, decision 449 (4)): no `std:` cell
//! binds it and it has no comptime face — the comptime keeps its arena.
//!
//! **Memory.** Every heap takes its memory from one pool over the program's
//! linear memory: free regions in address order, coalesced when freed, the
//! memory grown (`memory.grow`) when none fits. A process's heap is a list of
//! *chunks* taken from the pool; a released heap gives every chunk back, so
//! the next process reuses it.
//!
//! **A block** is what one `alloc` answers: an 8-byte header — the payload's
//! size (a multiple of 8; bit 0 the remembered flag below) and its *layout* —
//! then the payload, 8-aligned. The payload's address is what `alloc`
//! answers; a value may point anywhere inside it (a record's value is its
//! address plus four, behind which its header sits; a binary's bytes may be
//! another's), so each chunk keeps a bitmap of where its blocks start and an
//! address is resolved to its block through it.
//!
//! **A layout** says which payload words are pointers — the collection
//! knows both value representations (decision 450 (4)) through it, never by
//! guessing: `raw` none (a string, a box, a `bigint` block, a binary's
//! bytes); `bitmap(b)` word `i` when bit `i` of `b` is set, for the first 31
//! words (a record, a term cell: a cons `0b110`, a tuple's `0b100`);
//! `pointersFrom(k)` every word from `k` on (an array of values `[n][p…]` is
//! `pointersFrom(1)`, a term tuple's items `pointersFrom(0)`). A word in a
//! pointer slot that is no address of this heap (`0`, an ordinal, a literal in
//! the data, an atom) is left as it is.
//!
//! **Generations** (448 (2)). A heap has a young generation (the nursery,
//! where `alloc` bumps) and an old one. Values are immutable, so an old
//! value never points at a younger one — except through a mutable cell (a
//! `var`'s, a task's record), which is written through `write`, the one
//! write barrier: it remembers an old block written with a young value, and
//! a cell outside the heap (a module's data) for good. A *minor* collection
//! copies what the roots, the remembered blocks and those cells reach in the
//! young generation into the old one (every survivor promoted at once) and
//! empties the nursery; a *major* one, when the old generation passes its
//! limit, copies everything live into fresh chunks and frees the rest. Both
//! are Cheney's: iterative, no recursion and no stack of their own — the
//! copied blocks are the work list (decision 447: std-wasm's frames stay on
//! the one stack, and this module takes none it cannot bound).
//!
//! **Collection points.** `alloc` never collects and never moves a value: it
//! takes another nursery chunk when the current one is full. A collection
//! runs only where the caller names its roots — `reserve(need, roots, n)` (a
//! collection when the nursery has fewer than `need` free bytes) or `collect`
//! — the address of `n` words, each a value the collection may move and
//! rewrites in place. Every value the caller holds across a collection point
//! is among them (449 (3): beam-to-wasm's `test_heap` / `allocate`, their
//! live registers; the codegen's task frames, scheduler queues and cells).
//!
//! **Messages** (448 (3), decision 522). `copy(dst, v)` copies what `v`
//! reaches in the current heap into `dst`'s nursery, as erlang copies a
//! message: the sharing inside the value is not kept (a value reached twice
//! is copied twice) and nothing of `dst` points into the sender's heap after
//! it. A value is acyclic but through a mutable cell (`allocCell`: a `var`'s, a
//! task's record), so before copying anything the copy walks what `v`
//! reaches, marking each mutable cell while the walk is below it: reaching a
//! marked cell again is a cycle, answered `error.Cycle` with nothing written
//! — the caller raises it, located at the send (`message contains a cycle`),
//! never an exhausted memory and a trap (522 5′). A cell reached twice on
//! two paths (shared, no cycle) is no cycle: it is copied twice.
//!
//! **Exhaustion** (448 (4)). When the pool cannot grow (the host refuses
//! `memory.grow`, or memory would pass 4 GiB) the operation answers
//! `error.OutOfMemory` before writing anything it answers; the program's face
//! (`wasm.zig`) traps on it. A collection that cannot get its to-space
//! traps too: the run ends, it never continues over a half-copied heap.
const std = @import("std");
const builtin = @import("builtin");

pub const Error = error{OutOfMemory};

/// What a message copy answers besides `Error`: the value holds a cycle
/// (decision 522 5′).
pub const CopyError = error{ OutOfMemory, Cycle };

const is_wasm = builtin.cpu.arch.isWasm();
const page: u32 = 65536;

// ── layouts ──────────────────────────────────────────────────────────────────

/// A block with no pointer word.
pub const raw: u32 = 0;

/// Payload word `i` is a pointer when bit `i` of `bits` is set (31 words).
pub fn bitmap(bits: u32) u32 {
    std.debug.assert(bits < 0x8000_0000);
    return bits;
}

/// Every payload word from word `k` on is a pointer.
pub fn pointersFrom(k: u32) u32 {
    std.debug.assert(k < 0x7FFF_FFFF);
    return 0x8000_0000 | k;
}

/// A header whose layout word is this has been copied: its size word holds
/// the copy's payload address.
const forwarded: u32 = 0xFFFF_FFFF;

/// Whether payload word `i` of a block of layout `layout` is a pointer.
fn isPointer(layout: u32, i: u32) bool {
    if (layout & 0x8000_0000 != 0) return i >= (layout & 0x7FFF_FFFF);
    return i < 31 and (layout >> @intCast(i)) & 1 != 0;
}

// ── linear memory ────────────────────────────────────────────────────────────

/// Natively (the unit tests) the managed memory is a buffer standing for the
/// program's linear memory: an address is an offset into it.
var native_base: usize = 0;
var native_size: u32 = 0;
var native_cap: u32 = 0;

fn ptr(a: u32) [*]u8 {
    if (is_wasm) return @ptrFromInt(a);
    return @ptrFromInt(native_base + a);
}

fn word(a: u32) *u32 {
    return @ptrCast(@alignCast(ptr(a)));
}

fn memoryEnd() u32 {
    if (is_wasm) return @intCast(@wasmMemorySize(0) * page);
    return native_size;
}

/// Grows the memory by `pages`; answers the new region's first address.
fn grow(pages: u32) Error!u32 {
    const end = memoryEnd();
    // Past 65535 pages the end is no `u32`.
    if (@as(u64, end) + @as(u64, pages) * page > 0xFFFF_0000) return error.OutOfMemory;
    if (is_wasm) {
        if (@wasmMemoryGrow(0, pages) < 0) return error.OutOfMemory;
    } else {
        if (end + pages * page > native_cap) return error.OutOfMemory;
        native_size = end + pages * page;
    }
    return end;
}

// ── the pool ─────────────────────────────────────────────────────────────────
//
// A free region: word 0 its size, word 1 the next free region (address
// order), 0 at the end. Every size is a multiple of 16, so a split never
// leaves a remainder too small to hold a free region's two words.

var free_head: u32 = 0;

fn poolFree(a: u32, size: u32) void {
    std.debug.assert(a % 16 == 0 and size % 16 == 0 and size > 0);
    var prev: u32 = 0;
    var cur = free_head;
    while (cur != 0 and cur < a) : (cur = word(cur + 4).*) prev = cur;
    var start = a;
    var len = size;
    // Coalesce with the next region.
    if (cur != 0 and a + size == cur) {
        len += word(cur).*;
        cur = word(cur + 4).*;
    }
    // Coalesce with the previous one.
    if (prev != 0 and prev + word(prev).* == a) {
        start = prev;
        len += word(prev).*;
    } else if (prev != 0) {
        word(prev + 4).* = a;
    } else {
        free_head = a;
    }
    word(start).* = len;
    word(start + 4).* = cur;
}

fn poolAlloc(size0: u32) Error!u32 {
    if (size0 > 0x7FFF_0000) return error.OutOfMemory;
    const size = std.mem.alignForward(u32, @max(size0, 16), 16);
    while (true) {
        var prev: u32 = 0;
        var cur = free_head;
        var last: u32 = 0;
        while (cur != 0) : (cur = word(cur + 4).*) {
            const len = word(cur).*;
            if (len >= size) {
                const next = word(cur + 4).*;
                var rest = next;
                if (len > size) {
                    rest = cur + size;
                    word(rest).* = len - size;
                    word(rest + 4).* = next;
                }
                if (prev != 0) word(prev + 4).* = rest else free_head = rest;
                return cur;
            }
            prev = cur;
            last = cur;
        }
        // Nothing fits: grow, counting the last free region when it ends
        // where the memory does.
        const end = memoryEnd();
        var need = size;
        if (last != 0 and last + word(last).* == end) need -= word(last).*;
        const pages = (need + page - 1) / page;
        const at = try grow(pages);
        poolFree(at, pages * page);
    }
}

// ── chunks ───────────────────────────────────────────────────────────────────

/// A region of a heap: its header, the start bitmap (one bit per 8 bytes of
/// the block area, set at each block's header), the blocks from `first` to
/// `top`, free space up to `end`.
const Chunk = extern struct {
    next: u32,
    end: u32,
    top: u32,
    first: u32,
    bitmap: u32,
    _pad: u32,
};

fn chunk(c: u32) *Chunk {
    return @ptrCast(@alignCast(ptr(c)));
}

/// A zeroed chunk whose block area holds at least `area` bytes.
fn chunkNew(area0: u32) Error!u32 {
    if (area0 > 0x7000_0000) return error.OutOfMemory;
    const area = std.mem.alignForward(u32, area0, 8);
    const bm = std.mem.alignForward(u32, area / 64 + 1, 8);
    const total = std.mem.alignForward(u32, @sizeOf(Chunk) + bm + area, 16);
    const c = try poolAlloc(total);
    @memset(ptr(c)[0..total], 0);
    chunk(c).* = .{
        .next = 0,
        .end = c + total,
        .top = c + @sizeOf(Chunk) + bm,
        .first = c + @sizeOf(Chunk) + bm,
        .bitmap = c + @sizeOf(Chunk),
        ._pad = 0,
    };
    return c;
}

fn chunkFree(c: u32) void {
    poolFree(c, chunk(c).end - c);
}

/// A block of `total` bytes (header included) at the chunk's top, its start
/// bit set, or null when the chunk lacks the room.
fn bump(c: u32, total: u32) ?u32 {
    const k = chunk(c);
    if (k.end - k.top < total) return null;
    const h = k.top;
    k.top += total;
    const i = (h - k.first) / 8;
    word(k.bitmap + (i / 32) * 4).* |= @as(u32, 1) << @intCast(i % 32);
    return h;
}

/// The chunk of the list from `first` whose blocks hold `a`, or 0.
fn chunkOf(first: u32, a: u32) u32 {
    var c = first;
    while (c != 0) : (c = chunk(c).next) {
        const k = chunk(c);
        if (a >= k.first and a < k.top) return c;
    }
    return 0;
}

/// The header of the block of chunk `c` that holds `a`: the nearest start bit
/// at or below `a`.
fn blockOf(c: u32, a: u32) u32 {
    const k = chunk(c);
    const i = (a - k.first) / 8;
    var w = i / 32;
    const b: u5 = @intCast(i % 32);
    var bits = word(k.bitmap + w * 4).* & (@as(u32, 0xFFFF_FFFF) >> (31 - b));
    while (bits == 0) {
        w -= 1;
        bits = word(k.bitmap + w * 4).*;
    }
    return k.first + (w * 32 + (31 - @clz(bits))) * 8;
}

fn sizeOf(h: u32) u32 {
    return word(h).* & ~@as(u32, 7);
}

// ── heaps ────────────────────────────────────────────────────────────────────

/// A process's heap.
const Heap = extern struct {
    young_first: u32,
    young_last: u32,
    old_first: u32,
    old_last: u32,
    /// Bytes of blocks (headers included) in the old generation.
    old_bytes: u32,
    /// A major collection runs when `old_bytes` passes it.
    old_limit: u32,
    /// The area of the next nursery chunk.
    young_size: u32,
    /// The remembered blocks (old, written with a young value): `[cap][len][h…]`.
    remembered: u32,
    /// The cells outside every heap written with one of this heap's values —
    /// roots for good: `[cap][len][a…]`.
    statics: u32,
    minors: u32,
    majors: u32,
    _pad: u32,
};

fn heap(h: u32) *Heap {
    return @ptrCast(@alignCast(ptr(h)));
}

/// The nursery's first area, and the least an old generation's limit is.
pub const young_min: u32 = 64 * 1024;
pub const young_max: u32 = 8 * 1024 * 1024;
pub const old_min: u32 = 256 * 1024;

/// The current process's heap: what `alloc` allocates on.
var current: u32 = 0;

/// Starts the pool over `[start, memory's end)`: the memory a program leaves
/// past its data and its stack. Answers the first process's heap, current.
pub fn init(start: u32) Error!u32 {
    free_head = 0;
    current = 0;
    const s = std.mem.alignForward(u32, start, 16);
    const end = memoryEnd();
    if (end > s + 16) poolFree(s, (end - s) & ~@as(u32, 15));
    current = try spawn();
    return current;
}

/// A new process's heap, empty.
pub fn spawn() Error!u32 {
    const h = try poolAlloc(@sizeOf(Heap));
    const c = chunkNew(young_min) catch |e| {
        poolFree(h, std.mem.alignForward(u32, @sizeOf(Heap), 16));
        return e;
    };
    heap(h).* = .{
        .young_first = c,
        .young_last = c,
        .old_first = 0,
        .old_last = 0,
        .old_bytes = 0,
        .old_limit = old_min,
        .young_size = young_min,
        .remembered = 0,
        .statics = 0,
        .minors = 0,
        .majors = 0,
        ._pad = 0,
    };
    return h;
}

/// Makes `h` the current heap; answers the one it replaces.
pub fn enter(h: u32) u32 {
    const was = current;
    current = h;
    return was;
}

pub fn currentHeap() u32 {
    return current;
}

/// Releases `h` whole — its process ended (448 (3)). Every value on it is
/// gone; the memory returns to the pool.
pub fn release(h: u32) void {
    const p = heap(h);
    freeList(p.young_first);
    freeList(p.old_first);
    if (p.remembered != 0) arrFree(p.remembered);
    if (p.statics != 0) arrFree(p.statics);
    poolFree(h, std.mem.alignForward(u32, @sizeOf(Heap), 16));
    if (current == h) current = 0;
}

fn freeList(first: u32) void {
    var c = first;
    while (c != 0) {
        const next = chunk(c).next;
        chunkFree(c);
        c = next;
    }
}

// The header's size word: the payload's size, a multiple of 8, and three
// flags below it.
/// An old block written with a young value, scanned at the next minor
/// collection (the write barrier).
const remembered_flag: u32 = 1;
/// A mutable cell (`allocCell`): what a message copy marks while it is below it.
const mutable_flag: u32 = 2;
/// The mark itself, set only while a message copy's walk is below the cell.
const walking_flag: u32 = 4;

/// `n` fresh, zeroed bytes of layout `layout` on heap `h`'s nursery. Never
/// collects, never moves a value.
pub fn allocOn(h: u32, n: u32, layout: u32) Error!u32 {
    if (n > 0x7000_0000) return error.OutOfMemory;
    const total = 8 + std.mem.alignForward(u32, n, 8);
    const p = heap(h);
    const b = bump(p.young_last, total) orelse blk: {
        const c = try chunkNew(@max(p.young_size, total));
        chunk(p.young_last).next = c;
        p.young_last = c;
        break :blk bump(c, total).?;
    };
    word(b).* = total - 8;
    word(b + 4).* = layout;
    return b + 8;
}

/// `alloc` on the current heap.
pub fn alloc(n: u32, layout: u32) Error!u32 {
    return allocOn(current, n, layout);
}

/// A mutable cell of `n` bytes, layout `layout`, on heap `h`: a block the
/// program writes after making it (a `var`'s cell, a task's record) — through
/// `write`, the barrier — and the only kind of block a cycle can pass
/// through, so a message copy marks it (decision 522 5′).
pub fn allocCellOn(h: u32, n: u32, layout: u32) Error!u32 {
    const p = try allocOn(h, n, layout);
    word(p - 8).* |= mutable_flag;
    return p;
}

pub fn allocCell(n: u32, layout: u32) Error!u32 {
    return allocCellOn(current, n, layout);
}

/// `n` zeroed bytes outside every heap, never moved or freed: what every
/// process shares by address (an interned atom, decision 449 (3)). Nothing
/// a collection reaches through it: it holds no value of a heap.
pub fn allocStatic(n: u32) Error!u32 {
    if (n > 0x7000_0000) return error.OutOfMemory;
    const size = std.mem.alignForward(u32, @max(n, 16), 16);
    const a = try poolAlloc(size);
    @memset(ptr(a)[0..size], 0);
    return a;
}

/// The layout of the block that holds `v` on `h`, or `raw` when `v` is no
/// value of `h` — what a function answering a block like its argument's
/// (`array.reverse`) allocates with.
pub fn layoutOf(h: u32, v: u32) u32 {
    const p = heap(h);
    const c = chunkOf(p.young_first, v) | chunkOf(p.old_first, v);
    if (c == 0) return raw;
    return word(blockOf(c, v) + 4).*;
}

/// Bytes of blocks, headers included, on `h`.
pub fn used(h: u32) u32 {
    const p = heap(h);
    var n = p.old_bytes;
    var c = p.young_first;
    while (c != 0) : (c = chunk(c).next) n += chunk(c).top - chunk(c).first;
    return n;
}

pub fn collections(h: u32) struct { minor: u32, major: u32 } {
    return .{ .minor = heap(h).minors, .major = heap(h).majors };
}

// ── the write barrier ────────────────────────────────────────────────────────

/// Stores `v` into the mutable cell at `field` (a `var`'s cell, a task's
/// record) on the current heap — the one write that may make an old value
/// point at a younger one (448 (2)).
pub fn write(field: u32, v: u32) Error!void {
    return writeOn(current, field, v);
}

pub fn writeOn(h: u32, field: u32, v: u32) Error!void {
    const p = heap(h);
    if (chunkOf(p.young_first, field) != 0) {
        word(field).* = v;
        return;
    }
    const c = chunkOf(p.old_first, field);
    if (c != 0) {
        if (chunkOf(p.young_first, v) != 0) {
            const b = blockOf(c, field);
            if (word(b).* & remembered_flag == 0) {
                try arrPush(&p.remembered, b);
                word(b).* |= remembered_flag;
            }
        }
        word(field).* = v;
        return;
    }
    // A cell outside the heap: a root for good, once.
    if (!arrHas(p.statics, field)) try arrPush(&p.statics, field);
    word(field).* = v;
}

// ── growable word arrays `[cap][len][w…]` on the pool ───────────────────────

fn arrBytes(cap: u32) u32 {
    return std.mem.alignForward(u32, 8 + cap * 4, 16);
}

fn arrFree(a: u32) void {
    poolFree(a, arrBytes(word(a).*));
}

fn arrPush(slot: *u32, v: u32) Error!void {
    var a = slot.*;
    if (a == 0 or word(a + 4).* == word(a).*) {
        const cap: u32 = if (a == 0) 16 else word(a).* * 2;
        const b = try poolAlloc(arrBytes(cap));
        word(b).* = cap;
        word(b + 4).* = 0;
        if (a != 0) {
            const len = word(a + 4).*;
            @memcpy(ptr(b + 8)[0 .. len * 4], ptr(a + 8)[0 .. len * 4]);
            word(b + 4).* = len;
            arrFree(a);
        }
        a = b;
        slot.* = a;
    }
    const len = word(a + 4).*;
    word(a + 8 + len * 4).* = v;
    word(a + 4).* = len + 1;
}

fn arrHas(a: u32, v: u32) bool {
    if (a == 0) return false;
    const len = word(a + 4).*;
    var i: u32 = 0;
    while (i < len) : (i += 1) if (word(a + 8 + i * 4).* == v) return true;
    return false;
}

// ── collection ───────────────────────────────────────────────────────────────

/// One collection: what is copied (the young list, and for a major one the
/// old list too) and where the copies go.
const Gc = struct {
    young: u32,
    old: u32,
    to_first: u32,
    to_last: u32,
    to_area: u32,
    copied: u32 = 0,

    fn from(g: *const Gc, v: u32) u32 {
        const c = chunkOf(g.young, v);
        if (c != 0 or g.old == 0) return c;
        return chunkOf(g.old, v);
    }

    fn place(g: *Gc, total: u32) Error!u32 {
        if (g.to_last != 0) if (bump(g.to_last, total)) |b| return b;
        const c = try chunkNew(@max(g.to_area, total));
        if (g.to_last != 0) chunk(g.to_last).next = c else g.to_first = c;
        g.to_last = c;
        return bump(c, total).?;
    }

    /// `v`'s new address: its block copied once (later reaches answer the
    /// copy), the offset inside it kept; `v` itself when it is no value
    /// being collected.
    fn evacuate(g: *Gc, v: u32) Error!u32 {
        const c = g.from(v);
        if (c == 0) return v;
        const b = blockOf(c, v);
        const off = v -% (b + 8);
        if (word(b + 4).* == forwarded) return word(b).* +% off;
        const size = sizeOf(b);
        const nb = try g.place(8 + size);
        @memcpy(ptr(nb)[0 .. 8 + size], ptr(b)[0 .. 8 + size]);
        // The copy is not remembered (it is scanned as a copy); a cell stays one.
        word(nb).* = size | (word(b).* & mutable_flag);
        word(b).* = nb + 8;
        word(b + 4).* = forwarded;
        g.copied += 8 + size;
        return nb + 8 +% off;
    }

    /// Every pointer word of the block at `b`, evacuated in place.
    fn scanBlock(g: *Gc, b: u32) Error!void {
        const layout = word(b + 4).*;
        if (layout == raw) return;
        const words = sizeOf(b) / 4;
        var i: u32 = if (layout & 0x8000_0000 != 0) layout & 0x7FFF_FFFF else 0;
        while (i < words) : (i += 1) {
            if (!isPointer(layout, i)) continue;
            const f = b + 8 + i * 4;
            word(f).* = try g.evacuate(word(f).*);
        }
    }

    /// Cheney's scan: every block copied from the cursor on — the copies are
    /// the work list, so there is no recursion and no stack.
    fn scan(g: *Gc, start_c: u32, start_a: u32) Error!void {
        var c = start_c;
        var a = start_a;
        while (true) {
            if (c == 0) {
                if (g.to_first == 0) return;
                c = g.to_first;
                a = chunk(c).first;
            }
            if (a < chunk(c).top) {
                try g.scanBlock(a);
                a += 8 + sizeOf(a);
                continue;
            }
            const next = chunk(c).next;
            if (next == 0) return;
            c = next;
            a = chunk(c).first;
        }
    }

    fn roots(g: *Gc, at: u32, n: u32) Error!void {
        var i: u32 = 0;
        while (i < n) : (i += 1) {
            const r = at + i * 4;
            word(r).* = try g.evacuate(word(r).*);
        }
    }

    /// Each cell outside the heap the barrier recorded: its value evacuated.
    fn cells(g: *Gc, statics: u32) Error!void {
        if (statics == 0) return;
        const len = word(statics + 4).*;
        var i: u32 = 0;
        while (i < len) : (i += 1) {
            const f = word(statics + 8 + i * 4).*;
            word(f).* = try g.evacuate(word(f).*);
        }
    }
};

/// A collection point: collects `h` when its nursery has fewer than `need`
/// free bytes. `roots` is the address of `n` words — every value the caller
/// keeps across the point — rewritten to the values' new addresses.
pub fn reserveOn(h: u32, need: u32, roots: u32, n: u32) Error!void {
    const k = chunk(heap(h).young_last);
    if (k.end - k.top >= 8 + std.mem.alignForward(u32, need, 8)) return;
    try collectOn(h, roots, n, false);
}

pub fn reserve(need: u32, roots: u32, n: u32) Error!void {
    return reserveOn(current, need, roots, n);
}

/// A collection of `h` now: minor, then major when the old generation passed
/// its limit or `full` asks for it.
pub fn collectOn(h: u32, roots: u32, n: u32, full: bool) Error!void {
    try minor(h, roots, n);
    const p = heap(h);
    if (full or p.old_bytes > p.old_limit) try major(h, roots, n);
}

pub fn collect(roots: u32, n: u32, full: bool) Error!void {
    return collectOn(current, roots, n, full);
}

fn minor(h: u32, roots: u32, n: u32) Error!void {
    const p = heap(h);
    var g: Gc = .{
        .young = p.young_first,
        .old = 0,
        .to_first = p.old_first,
        .to_last = p.old_last,
        .to_area = @max(p.young_size, p.old_bytes / 2),
    };
    const start_c = p.old_last;
    const start_a = if (start_c != 0) chunk(start_c).top else 0;
    try g.roots(roots, n);
    try g.cells(p.statics);
    if (p.remembered != 0) {
        const len = word(p.remembered + 4).*;
        var i: u32 = 0;
        while (i < len) : (i += 1) {
            const b = word(p.remembered + 8 + i * 4).*;
            word(b).* &= ~remembered_flag;
            try g.scanBlock(b);
        }
        word(p.remembered + 4).* = 0;
    }
    try g.scan(start_c, start_a);
    p.old_first = g.to_first;
    p.old_last = g.to_last;
    p.old_bytes += g.copied;
    // The nursery grows while much of it survives.
    if (g.copied * 2 > p.young_size and p.young_size < young_max) p.young_size *= 2;
    try freshNursery(p);
    p.minors += 1;
}

fn major(h: u32, roots: u32, n: u32) Error!void {
    const p = heap(h);
    var g: Gc = .{
        .young = p.young_first,
        .old = p.old_first,
        .to_first = 0,
        .to_last = 0,
        .to_area = @max(young_min, p.old_bytes / 2),
    };
    try g.roots(roots, n);
    try g.cells(p.statics);
    // A remembered block is old: a major collection reaches it, or not, as
    // any other value.
    if (p.remembered != 0) word(p.remembered + 4).* = 0;
    try g.scan(0, 0);
    freeList(p.old_first);
    p.old_first = g.to_first;
    p.old_last = g.to_last;
    p.old_bytes = g.copied;
    p.old_limit = @max(old_min, g.copied *| 2);
    try freshNursery(p);
    p.majors += 1;
}

/// Frees every nursery chunk and starts an empty one.
fn freshNursery(p: *Heap) Error!void {
    freeList(p.young_first);
    p.young_first = 0;
    p.young_last = 0;
    const c = try chunkNew(p.young_size);
    p.young_first = c;
    p.young_last = c;
}

// ── messages ─────────────────────────────────────────────────────────────────

/// `v` copied from the current heap into `dst`'s nursery, as erlang copies a
/// message (448 (3)): every block `v` reaches on the current heap, the
/// sharing inside it not kept. A value that is no address of the current
/// heap is answered as it is. A value holding a cycle answers `error.Cycle`
/// before anything is written (decision 522 5′).
pub fn copy(dst: u32, v: u32) CopyError!u32 {
    return copyBetween(current, dst, v);
}

pub fn copyBetween(src: u32, dst: u32, v: u32) CopyError!u32 {
    if (src == dst) return v;
    if (try cyclic(src, v)) return error.Cycle;
    const d = heap(dst);
    const start_c = d.young_last;
    const start_a = chunk(start_c).top;
    const out = try dup(src, dst, v);
    // Cheney's scan over the copies, each pointer into `src` copied in turn.
    var c = start_c;
    var a = start_a;
    while (true) {
        if (a < chunk(c).top) {
            const layout = word(a + 4).*;
            if (layout != raw) {
                const words = sizeOf(a) / 4;
                var i: u32 = if (layout & 0x8000_0000 != 0) layout & 0x7FFF_FFFF else 0;
                while (i < words) : (i += 1) {
                    if (!isPointer(layout, i)) continue;
                    const f = a + 8 + i * 4;
                    word(f).* = try dup(src, dst, word(f).*);
                }
            }
            a += 8 + sizeOf(a);
            continue;
        }
        const next = chunk(c).next;
        if (next == 0) break;
        c = next;
        a = chunk(c).first;
    }
    return out;
}

/// The header of the block of `src` that holds `v`, or 0 when `v` is no
/// value of `src`.
fn blockIn(src: u32, v: u32) u32 {
    const s = heap(src);
    const c = chunkOf(s.young_first, v) | chunkOf(s.old_first, v);
    if (c == 0) return 0;
    return blockOf(c, v);
}

/// One block of `src` holding `v`, copied whole onto `dst`; `v`'s offset in
/// it kept. `v` itself when it is no value of `src`.
fn dup(src: u32, dst: u32, v: u32) Error!u32 {
    const b = blockIn(src, v);
    if (b == 0) return v;
    const size = sizeOf(b);
    const nv = try allocOn(dst, size, word(b + 4).*);
    @memcpy(ptr(nv)[0..size], ptr(b + 8)[0..size]);
    // The receiver's copy of a cell is a cell of its own.
    word(nv - 8).* |= word(b).* & mutable_flag;
    return nv +% (v -% (b + 8));
}

/// The next pointer word of block `b` at or past word `from` holding a value
/// of `src`: its index, or the block's word count when none is left.
fn nextPointer(src: u32, b: u32, from: u32) u32 {
    const layout = word(b + 4).*;
    const words = sizeOf(b) / 4;
    if (layout == raw) return words;
    var i = from;
    if (layout & 0x8000_0000 != 0) i = @max(i, layout & 0x7FFF_FFFF);
    while (i < words) : (i += 1) {
        if (isPointer(layout, i) and blockIn(src, word(b + 8 + i * 4).*) != 0) return i;
    }
    return words;
}

/// Whether what `v` reaches on `src` holds a cycle (decision 522 5′). A walk
/// in depth over the blocks the copy would copy, its path an explicit stack
/// of `(header, next word)` pairs on the pool — no recursion (447); each
/// mutable cell is marked while the walk is below it, and a marked cell
/// reached again is a cycle. Only a cell is marked: an immutable value points
/// only at older ones, so every cycle passes through a cell; a cell reached
/// again once the walk has left it (shared, no cycle) is walked again, as the
/// copy copies it again. Every mark is cleared before it answers.
fn cyclic(src: u32, v: u32) Error!bool {
    const first = blockIn(src, v);
    if (first == 0) return false;
    var path: u32 = 0;
    // Whatever ends the walk — its answer or the pool running out — the
    // cells still on the path lose their marks, and the path is freed.
    defer if (path != 0) {
        unmarkPath(path);
        arrFree(path);
    };
    var b = first;
    // Enter `b`; then, repeatedly, step to the next child of the top block or
    // leave it.
    enter: while (true) {
        const mark = word(b).* & mutable_flag != 0;
        if (mark and word(b).* & walking_flag != 0) return true;
        try arrPush(&path, b);
        try arrPush(&path, 0);
        if (mark) word(b).* |= walking_flag;
        while (true) {
            const len = word(path + 4).*;
            if (len == 0) return false;
            const top = word(path + 8 + (len - 2) * 4).*;
            const at = path + 8 + (len - 1) * 4;
            const i = nextPointer(src, top, word(at).*);
            if (i < sizeOf(top) / 4) {
                word(at).* = i + 1;
                b = blockIn(src, word(top + 8 + i * 4).*);
                continue :enter;
            }
            word(path + 4).* = len - 2;
            word(top).* &= ~walking_flag;
        }
    }
}

/// Clears the mark of every block on a walk's path (`(header, next word)`
/// pairs).
fn unmarkPath(path: u32) void {
    const len = word(path + 4).*;
    var k: u32 = 0;
    while (k + 1 < len) : (k += 2) word(word(path + 8 + k * 4).*).* &= ~walking_flag;
}

// ── tests ────────────────────────────────────────────────────────────────────
//
// Natively the managed memory is a buffer: addresses below one page are kept
// out of the pool, as a program's scratch and data are.

const testing = std.testing;

var test_buffer: []align(page) u8 = &.{};

fn testMemory(cap: u32) !void {
    if (test_buffer.len != cap) {
        if (test_buffer.len != 0) std.heap.page_allocator.free(test_buffer);
        test_buffer = try std.heap.page_allocator.alignedAlloc(u8, .fromByteUnits(page), cap);
    }
    native_base = @intFromPtr(test_buffer.ptr);
    native_cap = cap;
    native_size = 2 * page;
    @memset(test_buffer, 0xAA);
    _ = try init(page);
}

fn testDone() void {
    std.heap.page_allocator.free(test_buffer);
    test_buffer = &.{};
}

/// `n` root words on the pool.
fn testRoots(n: u32) !u32 {
    const r = try poolAlloc(n * 4);
    @memset(ptr(r)[0 .. n * 4], 0);
    return r;
}

fn testString(h: u32, s: []const u8) !u32 {
    const p = try allocOn(h, @intCast(4 + s.len), raw);
    word(p).* = @intCast(s.len);
    @memcpy(ptr(p + 4)[0..s.len], s);
    return p;
}

fn testText(p: u32) []const u8 {
    return ptr(p + 4)[0..word(p).*];
}

test "heap: alloc answers zeroed, aligned blocks that never move without a collection" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const h = current;
    var prev: u32 = 0;
    var i: u32 = 0;
    while (i < 5000) : (i += 1) {
        const p = try alloc(i % 37 + 1, raw);
        try testing.expect(p % 8 == 0 and p > prev);
        for (ptr(p)[0 .. i % 37 + 1]) |byte| try testing.expectEqual(@as(u8, 0), byte);
        prev = p;
    }
    // More than one nursery chunk: a full nursery takes another, it never
    // collects on its own.
    try testing.expect(chunk(heap(h).young_first).next != 0);
    try testing.expectEqual(@as(u32, 0), heap(h).minors);
}

test "heap: a minor collection keeps what the roots reach, rewrites the roots, frees the rest" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const h = current;
    const roots = try testRoots(2);
    const s = try testString(h, "kept");
    // An array of two strings: `[2][p0][p1]`.
    const arr = try alloc(12, pointersFrom(1));
    word(arr).* = 2;
    word(arr + 4).* = try testString(h, "first");
    word(arr + 8).* = try testString(h, "second");
    var i: u32 = 0;
    while (i < 1000) : (i += 1) _ = try testString(h, "garbage garbage garbage");
    word(roots).* = s;
    word(roots + 4).* = arr;
    try collect(roots, 2, false);
    try testing.expectEqual(@as(u32, 1), heap(h).minors);
    const s2 = word(roots).*;
    const a2 = word(roots + 4).*;
    try testing.expect(s2 != s and a2 != arr);
    try testing.expectEqualStrings("kept", testText(s2));
    try testing.expectEqual(@as(u32, 2), word(a2).*);
    try testing.expectEqualStrings("first", testText(word(a2 + 4).*));
    try testing.expectEqualStrings("second", testText(word(a2 + 8).*));
    // Only the live blocks were promoted.
    try testing.expectEqual(@as(u32, 8 + 8 + 8 + 16 + 8 + 16 + 8 + 16), heap(h).old_bytes);
    try testing.expectEqual(@as(u32, 0), chunk(heap(h).young_first).top - chunk(heap(h).young_first).first);
}

test "heap: a value pointing inside a block keeps its offset; a pointer slot holding no address is left" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const h = current;
    const roots = try testRoots(1);
    // A record: its header word, then two fields; its value is the address
    // plus four (the codegen's tagged record).
    const rec = try alloc(12, bitmap(0b110));
    word(rec).* = 77;
    const inner = try testString(h, "abcdef");
    word(rec + 4).* = inner + 4; // into the string's bytes
    word(rec + 8).* = 3; // an ordinal in a pointer slot
    word(roots).* = rec + 4;
    try collect(roots, 1, true);
    const v = word(roots).*;
    try testing.expectEqual(@as(u32, 77), word(v - 4).*);
    try testing.expectEqual(@as(u32, 3), word(v + 4).*);
    const bytes = word(v).*;
    try testing.expectEqualStrings("abcdef", ptr(bytes)[0..6]);
    try testing.expectEqual(@as(u32, 6), word(bytes - 4).*);
}

test "heap: a cell written with a younger value is remembered; one outside the heap is a root for good" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const h = current;
    const roots = try testRoots(1);
    // A `var`'s cell, promoted to the old generation.
    const cell = try alloc(4, pointersFrom(0));
    word(roots).* = cell;
    try collect(roots, 1, false);
    const old_cell = word(roots).*;
    try testing.expect(chunkOf(heap(h).old_first, old_cell) != 0);
    // A young value written into it: only the barrier keeps it.
    try write(old_cell, try testString(h, "young"));
    // A static cell (the pool region stands for a module's data).
    const static_cell = try testRoots(1);
    try write(static_cell, try testString(h, "static"));
    try write(static_cell, word(static_cell).*); // remembered once
    try testing.expectEqual(@as(u32, 1), word(heap(h).statics + 4).*);
    var i: u32 = 0;
    while (i < 2000) : (i += 1) _ = try testString(h, "noise");
    try collect(roots, 1, false);
    try testing.expectEqualStrings("young", testText(word(word(roots).*).*));
    try testing.expectEqualStrings("static", testText(word(static_cell).*));
    // A major collection still reaches both.
    try collect(roots, 1, true);
    try testing.expectEqualStrings("young", testText(word(word(roots).*).*));
    try testing.expectEqualStrings("static", testText(word(static_cell).*));
}

test "heap: a message is copied whole onto the receiver's heap, nothing of the sender's left in it" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const a = current;
    const b = try spawn();
    const arr = try alloc(16, pointersFrom(1));
    word(arr).* = 3;
    const shared = try testString(a, "twice");
    word(arr + 4).* = shared;
    word(arr + 8).* = shared;
    word(arr + 12).* = try testString(a, "once");
    const got = try copy(b, arr);
    try testing.expect(chunkOf(heap(b).young_first, got) != 0);
    try testing.expectEqual(@as(u32, 3), word(got).*);
    var i: u32 = 1;
    while (i <= 3) : (i += 1) try testing.expect(chunkOf(heap(b).young_first, word(got + i * 4).*) != 0);
    // The sharing is not kept, as erlang's message copy.
    try testing.expect(word(got + 4).* != word(got + 8).*);
    try testing.expectEqualStrings("twice", testText(word(got + 8).*));
    // The sender ends: its heap is released whole; the message stays.
    release(a);
    _ = enter(b);
    try testing.expectEqualStrings("once", testText(word(got + 12).*));
    // A value that is no address of the sender is answered as it is.
    const c = try spawn();
    try testing.expectEqual(@as(u32, 5), try copyBetween(b, c, 5));
    try testing.expectEqual(@as(u32, 0), used(c));
}

test "heap: a message holding a cycle through a cell answers Cycle, writes nothing, leaves no mark" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const a = current;
    const b = try spawn();
    // A `var`'s cell holding a closure that captures the cell: `[desc][cell]`.
    const c = try allocCell(4, pointersFrom(0));
    const k = try alloc(8, bitmap(0b10));
    word(k + 4).* = c;
    try write(c, k);
    // Sent inside an array.
    const arr = try alloc(8, pointersFrom(1));
    word(arr).* = 1;
    word(arr + 4).* = k;
    try testing.expectError(error.Cycle, copy(b, arr));
    try testing.expectEqual(@as(u32, 0), used(b));
    try testing.expectEqual(@as(u32, 0), word(c - 8).* & walking_flag);
    // A cell holding itself.
    const self = try allocCell(4, pointersFrom(0));
    try write(self, self);
    try testing.expectError(error.Cycle, copyBetween(a, b, self));
    try testing.expectEqual(@as(u32, 0), used(b));
    // Broken, the same value copies.
    try write(c, 7);
    const got = try copy(b, arr);
    try testing.expect(chunkOf(heap(b).young_first, got) != 0);
    const k2 = word(got + 4).*;
    const c2 = word(k2 + 4).*;
    try testing.expect(c2 != c and chunkOf(heap(b).young_first, c2) != 0);
    try testing.expectEqual(@as(u32, 7), word(c2).*);
    // The receiver's copy of a cell is a cell.
    try testing.expect(word(c2 - 8).* & mutable_flag != 0);
}

test "heap: a cell reached on two paths is shared, no cycle: copied twice" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const b = try spawn();
    const c = try allocCell(4, pointersFrom(0));
    try write(c, try testString(current, "inside"));
    const arr = try alloc(12, pointersFrom(1));
    word(arr).* = 2;
    word(arr + 4).* = c;
    word(arr + 8).* = c;
    const got = try copy(b, arr);
    try testing.expect(word(got + 4).* != word(got + 8).*);
    try testing.expectEqualStrings("inside", testText(word(word(got + 8).*).*));
    try testing.expectEqual(@as(u32, 0), word(c - 8).* & walking_flag);
}

test "heap: a cycle at the end of a long chain is found without recursion; a collection keeps a cell a cell" {
    try testMemory(16 * 1024 * 1024);
    defer testDone();
    const b = try spawn();
    const roots = try testRoots(2);
    // A cell, promoted by a collection: still a cell.
    const c = try allocCell(4, pointersFrom(0));
    word(roots).* = c;
    try collect(roots, 1, false);
    const old_c = word(roots).*;
    try testing.expect(word(old_c - 8).* & mutable_flag != 0);
    // Fifty thousand cons cells `[head][tail]` down to the cell.
    var list: u32 = old_c;
    var i: u32 = 0;
    while (i < 50_000) : (i += 1) {
        const n = try alloc(8, bitmap(0b11));
        word(n).* = try testString(current, "x");
        word(n + 4).* = list;
        list = n;
    }
    try testing.expect(!(try cyclic(current, list)));
    // The cell closes the loop onto the list's head.
    try write(old_c, list);
    try testing.expectError(error.Cycle, copy(b, list));
    try testing.expectEqual(@as(u32, 0), used(b));
    try testing.expectEqual(@as(u32, 0), word(old_c - 8).* & walking_flag);
}

test "heap: memory exhausted answers OutOfMemory before anything is written" {
    try testMemory(1024 * 1024);
    defer testDone();
    const h = current;
    // A list kept whole, every cell live, until the memory is gone.
    var list: u32 = 0;
    var n: u32 = 0;
    const err = while (true) : (n += 1) {
        const cell = allocOn(h, 8, bitmap(0b10)) catch |e| break e;
        word(cell).* = n;
        word(cell + 4).* = list;
        list = cell;
    };
    try testing.expectEqual(error.OutOfMemory, err);
    try testing.expectEqual(@as(u32, 1024 * 1024), memoryEnd());
    // What was answered before is intact: the whole list, in order.
    var count: u32 = 0;
    var k = list;
    while (k != 0) : (k = word(k + 4).*) {
        try testing.expectEqual(n - 1 - count, word(k).*);
        count += 1;
    }
    try testing.expectEqual(n, count);
    try testing.expect(count > 1000);
    // A collection that cannot find its to-space answers it too.
    const roots = poolAlloc(16) catch {
        return;
    };
    word(roots).* = list;
    try testing.expectError(error.OutOfMemory, collectOn(h, roots, 1, false));
}

test "heap: the pool coalesces what is freed and reuses it" {
    try testMemory(4 * 1024 * 1024);
    defer testDone();
    const before = memoryEnd();
    var round: u32 = 0;
    while (round < 200) : (round += 1) {
        const h = try spawn();
        var i: u32 = 0;
        while (i < 1000) : (i += 1) _ = try allocOn(h, 100, raw);
        release(h);
    }
    // Two hundred processes, each through more than one nursery chunk, in
    // the memory one of them needs.
    try testing.expect(memoryEnd() - before <= 4 * page);
}

// A property test: random graphs over random operations — allocation,
// garbage, cells written through the barrier, roots dropped and replaced,
// minor and major collections, messages to another heap — checked after each
// collection against a model of what the roots reach.
test "heap: property — every collection keeps exactly the graph the roots reach" {
    try testMemory(16 * 1024 * 1024);
    defer testDone();
    const gpa = testing.allocator;
    var prng = std.Random.DefaultPrng.init(0xB30);
    const rnd = prng.random();
    const h = current;
    const n_roots = 16;
    const roots = try testRoots(n_roots);
    // Model: a node `[id][nkids][kid…]` (pointersFrom(2)); a kid may point
    // four bytes inside its target. A cell `[id][slot]` (bitmap 0b10).
    const Kid = struct { id: u32, off: u32 };
    const Node = struct { kids: []const Kid, cell: bool };
    var model: std.ArrayList(Node) = .empty;
    defer {
        for (model.items) |m| gpa.free(m.kids);
        model.deinit(gpa);
    }
    var cell_slot: std.AutoHashMapUnmanaged(u32, Kid) = .empty;
    defer cell_slot.deinit(gpa);
    var root_ids: [n_roots]?u32 = .{null} ** n_roots;
    var cycles: u32 = 0;
    var sent: u32 = 0;

    var step: u32 = 0;
    while (step < 4000) : (step += 1) {
        const op = rnd.uintLessThan(u32, 100);
        if (op < 45) {
            // A node over kids the roots hold (older values only).
            var kids: std.ArrayList(Kid) = .empty;
            var addrs: std.ArrayList(u32) = .empty;
            defer addrs.deinit(gpa);
            const nk = rnd.uintLessThan(u32, 4);
            var j: u32 = 0;
            while (j < nk) : (j += 1) {
                const r = rnd.uintLessThan(u32, n_roots);
                const id = root_ids[r] orelse continue;
                // A node never holds a cell, so no value is a cycle.
                if (model.items[id].cell) continue;
                const off: u32 = if (rnd.boolean()) 4 else 0;
                try kids.append(gpa, .{ .id = id, .off = off });
                try addrs.append(gpa, word(roots + r * 4).* + off);
            }
            const id: u32 = @intCast(model.items.len);
            const p = try alloc(8 + 4 * @as(u32, @intCast(addrs.items.len)), pointersFrom(2));
            word(p).* = id;
            word(p + 4).* = @intCast(addrs.items.len);
            for (addrs.items, 0..) |a, k| word(p + 8 + @as(u32, @intCast(k)) * 4).* = a;
            try model.append(gpa, .{ .kids = try kids.toOwnedSlice(gpa), .cell = false });
            const r = rnd.uintLessThan(u32, n_roots);
            word(roots + r * 4).* = p;
            root_ids[r] = id;
        } else if (op < 60) {
            // Garbage.
            _ = try alloc(rnd.uintLessThan(u32, 200), raw);
        } else if (op < 66) {
            // A cell, rooted.
            const id: u32 = @intCast(model.items.len);
            const p = try allocCell(8, bitmap(0b10));
            word(p).* = id;
            try model.append(gpa, .{ .kids = &.{}, .cell = true });
            const r = rnd.uintLessThan(u32, n_roots);
            word(roots + r * 4).* = p;
            root_ids[r] = id;
        } else if (op < 80) {
            // A rooted cell written with any rooted value — younger ones too.
            const r = rnd.uintLessThan(u32, n_roots);
            const t = rnd.uintLessThan(u32, n_roots);
            const id = root_ids[r] orelse continue;
            if (!model.items[id].cell) continue;
            const tid = root_ids[t] orelse continue;
            try write(word(roots + r * 4).* + 4, word(roots + t * 4).*);
            try cell_slot.put(gpa, id, .{ .id = tid, .off = 0 });
        } else if (op < 86) {
            const r = rnd.uintLessThan(u32, n_roots);
            word(roots + r * 4).* = 0;
            root_ids[r] = null;
        } else if (op < 95) {
            try collect(roots, n_roots, false);
            try checkGraph(roots, n_roots, &root_ids, model.items, &cell_slot);
        } else if (op < 98) {
            try collect(roots, n_roots, true);
            try checkGraph(roots, n_roots, &root_ids, model.items, &cell_slot);
        } else {
            // A message: a rooted value copied to another heap and checked
            // there — or, when the model reaches a cycle from it (only a
            // cell can close one), refused with nothing written — the
            // receiver then released.
            const r = rnd.uintLessThan(u32, n_roots);
            const id = root_ids[r] orelse continue;
            const other = try spawn();
            if (try modelCyclic(id, model.items, &cell_slot)) {
                try testing.expectError(error.Cycle, copy(other, word(roots + r * 4).*));
                try testing.expectEqual(@as(u32, 0), used(other));
                cycles += 1;
            } else {
                const got = try copy(other, word(roots + r * 4).*);
                try checkNode(got, id, model.items, &cell_slot, other);
                sent += 1;
            }
            release(other);
        }
    }
    try testing.expect(heap(h).minors > 50 and heap(h).majors > 5);
    try testing.expect(cycles > 0 and sent > 0);
}

/// Whether the model reaches a cycle from node `start` (a walk in depth with
/// the path's nodes marked).
fn modelCyclic(start: u32, model: anytype, cells: anytype) !bool {
    const gpa = testing.allocator;
    const State = enum { on_path, done };
    var state: std.AutoHashMapUnmanaged(u32, State) = .empty;
    defer state.deinit(gpa);
    var stack: std.ArrayList([2]u32) = .empty;
    defer stack.deinit(gpa);
    try stack.append(gpa, .{ start, 0 });
    try state.put(gpa, start, .on_path);
    while (stack.items.len > 0) {
        const top = &stack.items[stack.items.len - 1];
        const id = top[0];
        const m = model[id];
        const kid: ?u32 = if (m.cell)
            (if (top[1] == 0) (if (cells.get(id)) |k| k.id else null) else null)
        else if (top[1] < m.kids.len) m.kids[top[1]].id else null;
        if (kid) |k| {
            top[1] += 1;
            if (state.get(k)) |st| {
                if (st == .on_path) return true;
                continue;
            }
            try state.put(gpa, k, .on_path);
            try stack.append(gpa, .{ k, 0 });
            continue;
        }
        try state.put(gpa, id, .done);
        _ = stack.pop();
    }
    return false;
}

/// Walks the graph from the roots (iteratively) against the model.
fn checkGraph(roots: u32, n: u32, root_ids: []const ?u32, model: anytype, cells: anytype) !void {
    var i: u32 = 0;
    while (i < n) : (i += 1) {
        const id = root_ids[i] orelse continue;
        try checkNode(word(roots + i * 4).*, id, model, cells, current);
    }
}

fn checkNode(start: u32, start_id: u32, model: anytype, cells: anytype, on: u32) !void {
    var stack: std.ArrayList([2]u32) = .empty;
    defer stack.deinit(testing.allocator);
    try stack.append(testing.allocator, .{ start, start_id });
    var seen: std.AutoHashMapUnmanaged(u32, void) = .empty;
    defer seen.deinit(testing.allocator);
    while (stack.pop()) |top| {
        const p = top[0];
        const id = top[1];
        if ((try seen.getOrPut(testing.allocator, p)).found_existing) continue;
        const p_heap = heap(on);
        try testing.expect(chunkOf(p_heap.young_first, p) != 0 or chunkOf(p_heap.old_first, p) != 0);
        try testing.expectEqual(id, word(p).*);
        const m = model[id];
        if (m.cell) {
            if (cells.get(id)) |kid| {
                const v = word(p + 4).*;
                try stack.append(testing.allocator, .{ v - kid.off, kid.id });
            }
            continue;
        }
        try testing.expectEqual(@as(u32, @intCast(m.kids.len)), word(p + 4).*);
        for (m.kids, 0..) |kid, k| {
            const v = word(p + 8 + @as(u32, @intCast(k)) * 4).*;
            try stack.append(testing.allocator, .{ v - kid.off, kid.id });
        }
    }
}

// A stress test: a server's request loop on one process and a process per
// request, as long as the measured programs ran (codegen/wat/AGENTS.md § How
// far a program grows without collection) — memory stays bounded where the
// bump heap grew without limit.
test "heap: stress — a request loop's memory stays bounded while it allocates many times more" {
    try testMemory(32 * 1024 * 1024);
    defer testDone();
    var prng = std.Random.DefaultPrng.init(0x5EED);
    const rnd = prng.random();
    const h = current;
    const roots = try testRoots(8);
    var allocated: u64 = 0;
    var req: u32 = 0;
    while (req < 100_000) : (req += 1) {
        // The loop's collection point, its state the roots.
        try reserve(4096, roots, 8);
        // A request: a handful of strings and arrays, one of them kept.
        var k: u32 = 0;
        while (k < 8) : (k += 1) {
            const n = rnd.uintLessThan(u32, 120) + 4;
            const s = try alloc(n, raw);
            word(s).* = n - 4;
            allocated += n + 8;
        }
        const arr = try alloc(12, pointersFrom(1));
        word(arr).* = 2;
        word(arr + 4).* = try testString(h, "request");
        word(arr + 8).* = try testString(h, "response");
        allocated += 40 + 24;
        word(roots + (req % 8) * 4).* = arr;
        // Every thousandth request, a process for it: spawned, sent the
        // state, released.
        if (req % 1000 == 0) {
            const p = try spawn();
            _ = try copy(p, word(roots).*);
            release(p);
        }
    }
    try testing.expect(heap(h).minors > 100);
    try testing.expect(allocated > 20 * @as(u64, memoryEnd()));
    try testing.expect(memoryEnd() <= 2 * 1024 * 1024);
}
