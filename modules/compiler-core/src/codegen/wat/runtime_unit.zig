//! Decisions 1021 (2), 1026 — the runtime core `std@__rt.wasm` and std's
//! units `std@<path>.wasm`: program-independent core modules, the same bytes
//! for every program a compiler build writes (so each is written once per
//! compiler source stamp), which a program composes with the ones it reaches.
//!
//! **The core** (`std@__rt`) holds what is no std module's: the linear memory
//! (`memory` — `0..256` the print helpers' scratch, then std-wasm's data and
//! its stack, then the units' data and the heap), `__heap_ptr` and `__alloc`,
//! the panic tag `__bp_panic (param anyref)`, the host's WASI functions
//! (`fd_write`, `random_get` forwarded, `__wasi_random_f64`: the one unit
//! importing them), std-wasm's stack (`__std_sp`, `__std_sp_check`) and the
//! decoded helpers several std units share (exported by their symbols).
//!
//! **A std unit** (`std@string`, `std@io@fs`, …) holds one std module's
//! functions (`root.units` of std-wasm names the module of each std-wasm
//! module): the program-face exports it declares (`std:<module>.<function>`),
//! its `.wat` leaves (`wat:<module>.<function>`, over the canonical prelude
//! rec group, decision 1021 (9)), and the decoded helpers only it reaches. It
//! imports the core's memory, globals and functions, the functions of the std
//! units it calls (by their symbols), and its own host functions (`std@io@fs`
//! imports `bp_fs`).
//!
//! Where each decoded function goes (`build`): an export to its module's unit;
//! a helper to the one unit that reaches it from its exports and leaves (a walk
//! that stops at another unit's export, which is an import of the walker's
//! unit), else — reached from several — to the core, with everything it calls.
//! The units then form a DAG (`Runtime.units` in dependency order).
//!
//! Not here yet: the scheduler's globals, the shared function table and the
//! type registry, which serve more than one program unit (P4).

const std = @import("std");
const ast = @import("wat_ast.zig");
const prelude = @import("wat_prelude.zig");
const link = @import("std_wasm_link.zig");
const leaves = @import("std_leaves.zig");
const reader = @import("wat_reader.zig");
const binary = @import("wasm_binary_emitter.zig");
const emitter = @import("wat_emitter.zig");
const stdWasm = @import("std_wasm");
const WasmNeed = @import("../../ast.zig").WasmNeed;

/// The import module every unit names the runtime core by.
pub const name = "std@__rt";

/// The file the core is written to, beside the program's units.
pub const file_name = name ++ ".wasm";

/// The first byte std-wasm's data may take: below it, the print helpers'
/// scratch (`wat_prelude.zig`'s header).
pub const scratch_end: u32 = 256;

pub const heap_ptr_export = "__heap_ptr";
pub const alloc_export = "__alloc";
pub const memory_export = "memory";
pub const panic_export = "__bp_panic";

/// The export prefix of a std unit's `.wat` leaf (its decoded functions are
/// `std:`): a leaf and a decoded function may share a name (`text.length`).
pub const leaf_prefix = "wat:";

/// One std unit.
pub const Unit = struct {
    /// `std@io@fs`.
    name: []const u8,
    /// `std@io@fs.wasm`.
    file_name: []const u8,
    module: ast.Module,
    /// The std units it imports (never the core), by name.
    deps: []const []const u8,
    /// Whether it imports `bp_fs` (the component's file system shim).
    host_fs: bool,
    text: []const u8,
    bytes: []const u8,
};

/// A function a program imports: the unit, the export's name, its type.
pub const Ref = struct { unit: []const u8, @"export": []const u8, type: ast.FuncType };

/// The core and std's units, built once per process.
pub const Runtime = struct {
    core: ast.Module,
    /// The first byte past std-wasm's data and stack: where the program's
    /// data starts, and the heap's first address.
    end: u32,
    /// The pages the core's memory starts with: `end`'s. A composition
    /// starts it with more when the program's data asks (`coreFor`).
    pages: u32,
    core_text: []const u8,
    core_bytes: []const u8,
    /// In dependency order: each after the units it imports.
    units: []const Unit,
    /// Each std-wasm function by its program-face name (`text.length`).
    std_refs: std.StringHashMapUnmanaged(Ref),
    /// Each `.wat` leaf by its name.
    leaf_refs: std.StringHashMapUnmanaged(Ref),
    /// `<unit> -> <unit>, …` lines, one per unit: the dependency graph.
    graph: []const u8,

    pub fn unit(r: *const Runtime, unit_name: []const u8) ?*const Unit {
        for (r.units) |*u| if (std.mem.eql(u8, u.name, unit_name)) return u;
        return null;
    }

    /// The std units `roots` names and every unit they import, in
    /// dependency order; a name that is no std unit (the core's, a host's)
    /// is skipped.
    pub fn closure(r: *const Runtime, ar: std.mem.Allocator, roots: []const []const u8) ![]const *const Unit {
        var want: std.StringHashMapUnmanaged(void) = .empty;
        var stack: std.ArrayListUnmanaged([]const u8) = .empty;
        try stack.appendSlice(ar, roots);
        while (stack.pop()) |n| {
            const u = r.unit(n) orelse continue;
            if ((try want.fetchPut(ar, u.name, {})) != null) continue;
            try stack.appendSlice(ar, u.deps);
        }
        var out: std.ArrayListUnmanaged(*const Unit) = .empty;
        for (r.units) |*u| if (want.contains(u.name)) try out.append(ar, u);
        return out.items;
    }

    /// The core as a composition instantiates it: its memory starting with
    /// `pages` pages when the program's data needs more than `Runtime.pages`
    /// (decision 1021's data reserve, sized at link time).
    pub fn coreFor(r: *const Runtime, ar: std.mem.Allocator, pages: u32) !struct { text: []const u8, bytes: []const u8 } {
        if (pages <= r.pages) return .{ .text = r.core_text, .bytes = r.core_bytes };
        const items = try ar.dupe(ast.Item, r.core.items);
        for (items) |*it| if (it.* == .memory) {
            it.memory.min_pages = pages;
        };
        const m: ast.Module = .{ .items = items };
        return .{ .text = try renderText(ar, m), .bytes = try binary.encodeModule(ar, m) };
    }
};

pub const Error = link.Error || binary.Error || reader.Error || error{
    /// The std units' imports make a cycle (`failure()` names it).
    UnitCycle,
};

var mutex: std.atomic.Mutex = .unlocked;
var arena_state: std.heap.ArenaAllocator = std.heap.ArenaAllocator.init(std.heap.page_allocator);
var built: ?Runtime = null;
var failed: ?Error = null;
var fail_diag: []const u8 = "";

fn lock() void {
    while (!mutex.tryLock()) std.atomic.spinLoopHint();
}

/// The core and std's units. Built on the first call and kept for the
/// process: they are the same for every program.
pub fn get() Error!*const Runtime {
    lock();
    defer mutex.unlock();
    if (built) |*r| return r;
    if (failed) |e| return e;
    var diag: link.Diag = .{};
    built = build(arena_state.allocator(), &diag) catch |e| {
        failed = e;
        fail_diag = diag.message;
        return e;
    };
    return &built.?;
}

/// Why `get` failed, for a refusal's text.
pub fn failure() []const u8 {
    return fail_diag;
}

/// The unit name of the std module `path` (`io/fs` → `std@io@fs`).
pub fn unitName(ar: std.mem.Allocator, path: []const u8) ![]const u8 {
    const out = try std.fmt.allocPrint(ar, "std@{s}", .{path});
    std.mem.replaceScalar(u8, out, '/', '@');
    return out;
}

// ── the build ────────────────────────────────────────────────────────────────

/// A function of the build: decoded from `std_wasm.wasm`, or a leaf.
const Node = struct {
    func: ast.Func,
    /// The program-face names (decoded) or the leaf's name.
    names: []const []const u8,
    leaf: bool,
    /// The unit it is a root of (an export or a leaf), else null.
    root_of: ?[]const u8,
    /// Where it goes: a unit's name, or `name` for the core.
    place: ?[]const u8 = null,
    label: []const u8 = "",
    hash: [12]u8 = undefined,
};

fn build(ar: std.mem.Allocator, diag: *link.Diag) Error!Runtime {
    const whole = try link.decodeWhole(ar, link.module_bytes, scratch_end, diag);
    const pages = @max(1, (whole.end + 65535) / 65536);

    var nodes: std.ArrayListUnmanaged(Node) = .empty;
    var by_symbol: std.StringHashMapUnmanaged(usize) = .empty;
    for (whole.funcs) |f| {
        var root: ?[]const u8 = null;
        for (f.exports) |x| {
            const path = stdWasm.unitPath(x) orelse {
                diag.message = try std.fmt.allocPrint(ar, "std-wasm's `{s}` belongs to no unit (`root.units`)", .{x});
                return error.Unsupported;
            };
            const u = try unitName(ar, path);
            // Folded functions of two modules: shared.
            root = if (root == null or std.mem.eql(u8, root.?, u)) u else name;
        }
        try by_symbol.put(ar, f.func.name, nodes.items.len);
        try nodes.append(ar, .{ .func = f.func, .names = f.exports, .leaf = false, .root_of = root, .label = f.label, .hash = f.hash });
    }
    // Every leaf, read against the prelude group, renamed `__wat_<m>_<f>`.
    var leaf_calls: std.StringHashMapUnmanaged([]const []const u8) = .empty;
    for (leaves.files, 0..) |file, fi| {
        var it = reader.FuncNames.init(file.text);
        while (it.next()) |n| {
            var calls: std.ArrayListUnmanaged([]const u8) = .empty;
            var rdiag: reader.Diag = .{};
            var func = leaves.read(ar, .{ .name = n, .file = fi }, .{ .ctx = undefined, .index = preludeIndex }, &calls, &rdiag) catch |err| {
                if (err == error.Unreadable) diag.message = try rdiag.text(ar);
                return err;
            };
            func.name = try leafSymbol(ar, n);
            renameLeafCalls(&func.body);
            const path = stdWasm.unitPath(n) orelse {
                diag.message = try std.fmt.allocPrint(ar, "std-wasm's leaf `{s}` belongs to no unit (`root.units`)", .{n});
                return error.Unsupported;
            };
            try leaf_calls.put(ar, func.name, calls.items);
            try by_symbol.put(ar, func.name, nodes.items.len);
            try nodes.append(ar, .{ .func = func, .names = try ar.dupe([]const u8, &.{n}), .leaf = true, .root_of = try unitName(ar, path) });
        }
    }

    // Each node's callees among the nodes.
    const callees = try ar.alloc([]const usize, nodes.items.len);
    for (nodes.items, callees) |n, *out| {
        var names: std.ArrayListUnmanaged([]const u8) = .empty;
        try collectCalls(ar, n.func.body, &names, null);
        var list: std.ArrayListUnmanaged(usize) = .empty;
        for (names.items) |c| if (by_symbol.get(c)) |k| try list.append(ar, k);
        out.* = list.items;
    }

    // Each helper's place: the one unit whose walk reaches it, else the core.
    const reached_by = try ar.alloc(std.StringArrayHashMapUnmanaged(void), nodes.items.len);
    for (reached_by) |*s| s.* = .empty;
    var unit_names: std.StringArrayHashMapUnmanaged(void) = .empty;
    for (nodes.items) |n| if (n.root_of) |u| if (!std.mem.eql(u8, u, name)) try unit_names.put(ar, u, {});
    for (unit_names.keys()) |u| {
        var stack: std.ArrayListUnmanaged(usize) = .empty;
        var seen = try ar.alloc(bool, nodes.items.len);
        @memset(seen, false);
        for (nodes.items, 0..) |n, k| if (n.root_of) |r| if (std.mem.eql(u8, r, u)) try stack.append(ar, k);
        while (stack.pop()) |k| {
            if (seen[k]) continue;
            seen[k] = true;
            if (nodes.items[k].root_of) |r| if (!std.mem.eql(u8, r, u)) continue;
            try reached_by[k].put(ar, u, {});
            try stack.appendSlice(ar, callees[k]);
        }
    }
    for (nodes.items, reached_by) |*n, set| {
        if (n.root_of) |r| {
            n.place = r;
        } else if (set.count() == 1) {
            n.place = set.keys()[0];
        } else if (set.count() > 1) n.place = name;
    }
    // What the core holds calls only the core: pull the callees in.
    var moved = true;
    while (moved) {
        moved = false;
        for (nodes.items, callees) |n, cs| {
            const p = n.place orelse continue;
            if (!std.mem.eql(u8, p, name)) continue;
            for (cs) |c| if (!std.mem.eql(u8, nodes.items[c].place.?, name)) {
                nodes.items[c].place = name;
                moved = true;
            };
        }
    }

    // The units' imports of each other, and their order.
    var deps: std.StringArrayHashMapUnmanaged(std.StringArrayHashMapUnmanaged(void)) = .empty;
    for (unit_names.keys()) |u| try deps.put(ar, u, .empty);
    for (nodes.items, callees) |n, cs| {
        const p = n.place orelse continue;
        if (std.mem.eql(u8, p, name)) continue;
        for (cs) |c| {
            const q = nodes.items[c].place.?;
            if (std.mem.eql(u8, q, name) or std.mem.eql(u8, q, p)) continue;
            try deps.getPtr(p).?.put(ar, q, {});
        }
    }
    const order = try topoOrder(ar, &deps, diag);

    // The core.
    var core: std.ArrayListUnmanaged(ast.Item) = .empty;
    try core.append(ar, .{ .import = prelude.fd_write_import });
    try core.append(ar, .{ .import = prelude.random_get_import });
    try core.append(ar, .{ .memory = .{ .@"export" = memory_export, .min_pages = pages } });
    try core.append(ar, .{ .tag = .{ .name = prelude.gc_panic_tag.name, .params = prelude.gc_panic_tag.params, .exports = &.{panic_export} } });
    try core.append(ar, .{ .global = .{ .name = "__heap_ptr", .exports = &.{heap_ptr_export}, .ty = .i32, .mutable = true, .init = try std.fmt.allocPrint(ar, "{d}", .{whole.end}) } });
    if (whole.stack_global) |g| {
        var sg = g;
        sg.exports = try ar.dupe([]const u8, &.{g.name});
        try core.append(ar, .{ .global = sg });
    }
    var alloc_fn = prelude.items(.alloc)[0].func;
    alloc_fn.exports = &.{alloc_export};
    try core.append(ar, .{ .func = alloc_fn });
    try core.append(ar, .{ .func = try forward(ar, prelude.fd_write_import) });
    try core.append(ar, .{ .func = try forward(ar, prelude.random_get_import) });
    var rnd = prelude.items(.wasi_random_f64)[0].func;
    rnd.exports = try ar.dupe([]const u8, &.{rnd.name});
    try core.append(ar, .{ .func = rnd });
    if (whole.stack_check) |f| {
        var sc = f;
        sc.exports = try ar.dupe([]const u8, &.{f.name});
        try core.append(ar, .{ .func = sc });
    }
    try core.appendSlice(ar, whole.data);
    var core_shared: usize = 0;
    for (nodes.items) |n| if (n.place) |p| if (std.mem.eql(u8, p, name)) {
        var f = n.func;
        f.exports = try exportsOf(ar, n, true);
        try core.append(ar, .{ .func = f });
        core_shared += 1;
    };
    try core.append(ar, .{ .custom = .{ .name = "botopink.needs", .bytes = try needsText(ar, &.{ .gc, .exceptions }) } });
    const core_module: ast.Module = .{ .items = core.items };

    // The units.
    var units: std.ArrayListUnmanaged(Unit) = .empty;
    var std_refs: std.StringHashMapUnmanaged(Ref) = .empty;
    var leaf_refs: std.StringHashMapUnmanaged(Ref) = .empty;
    for (nodes.items) |n| if (n.place) |p| for (n.names) |x| {
        const ref: Ref = .{ .unit = p, .@"export" = try std.fmt.allocPrint(ar, "{s}{s}", .{ if (n.leaf) leaf_prefix else link.export_prefix, x }), .type = funcType(ar, n.func) catch return error.OutOfMemory };
        try (if (n.leaf) &leaf_refs else &std_refs).put(ar, x, ref);
    };
    var graph: std.ArrayListUnmanaged(u8) = .empty;
    for (order) |u| {
        const unit_deps = deps.get(u).?.keys();
        const m = try unitModule(ar, u, nodes.items, callees, leaf_calls);
        try graph.print(ar, "{s} ({d} functions) -> {s}", .{ u, m.funcs, name });
        for (unit_deps) |d| try graph.print(ar, ", {s}", .{d});
        try graph.append(ar, '\n');
        try units.append(ar, .{
            .name = u,
            .file_name = try std.fmt.allocPrint(ar, "{s}.wasm", .{u}),
            .module = m.module,
            .deps = unit_deps,
            .host_fs = m.host_fs,
            .text = try renderText(ar, m.module),
            .bytes = try binary.encodeModule(ar, m.module),
        });
    }
    try graph.print(ar, "{s} ({d} shared functions)\n", .{ name, core_shared });

    return .{
        .core = core_module,
        .end = whole.end,
        .pages = pages,
        .core_text = try renderText(ar, core_module),
        .core_bytes = try binary.encodeModule(ar, core_module),
        .units = units.items,
        .std_refs = std_refs,
        .leaf_refs = leaf_refs,
        .graph = graph.items,
    };
}

/// A node's exports: its program-face names (`std:` / `wat:`), and its symbol
/// when another unit may call it (`by_symbol`).
fn exportsOf(ar: std.mem.Allocator, n: Node, by_symbol: bool) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (n.names) |x| try out.append(ar, try std.fmt.allocPrint(ar, "{s}{s}", .{ if (n.leaf) leaf_prefix else link.export_prefix, x }));
    if (by_symbol) try out.append(ar, n.func.name);
    return out.items;
}

const UnitModule = struct { module: ast.Module, host_fs: bool, funcs: usize };

/// The module of the unit `u`: its imports (the core's, the other units',
/// the host's), the prelude group when it holds a leaf, and its functions.
fn unitModule(
    ar: std.mem.Allocator,
    u: []const u8,
    nodes: []const Node,
    callees: []const []const usize,
    leaf_calls: std.StringHashMapUnmanaged([]const []const u8),
) !UnitModule {
    var own: std.ArrayListUnmanaged(usize) = .empty;
    for (nodes, 0..) |n, k| if (n.place) |p| if (std.mem.eql(u8, p, u)) try own.append(ar, k);
    var has_leaf = false;
    var host_fs = false;
    var marshal = false;
    var random_state = false;
    var uses_heap = false;
    var uses_sp = false;
    var core_funcs: std.StringArrayHashMapUnmanaged(void) = .empty;
    var foreign: std.AutoArrayHashMapUnmanaged(usize, void) = .empty;
    for (own.items) |k| {
        const n = nodes[k];
        if (n.leaf) has_leaf = true;
        for (callees[k]) |c| {
            const q = nodes[c].place.?;
            if (std.mem.eql(u8, q, u)) continue;
            try foreign.put(ar, c, {});
        }
        var calls: std.ArrayListUnmanaged([]const u8) = .empty;
        var globals: std.ArrayListUnmanaged([]const u8) = .empty;
        try collectCalls(ar, n.func.body, &calls, &globals);
        for (globals.items) |g| {
            if (std.mem.eql(u8, g, "__heap_ptr")) uses_heap = true;
            if (std.mem.eql(u8, g, link.stack_global)) uses_sp = true;
            if (std.mem.eql(u8, g, prelude.random_state_global.name)) random_state = true;
        }
        for (calls.items) |c| {
            if (std.mem.eql(u8, c, "__alloc") or std.mem.eql(u8, c, link.stack_check) or std.mem.eql(u8, c, link.random_import)) try core_funcs.put(ar, c, {});
            if (std.mem.startsWith(u8, c, "__fs_")) host_fs = true;
            if (std.mem.eql(u8, c, "__gc_to_lin_str") or std.mem.eql(u8, c, "__lin_to_gc_str")) marshal = true;
        }
        _ = leaf_calls;
    }
    if (marshal) {
        // The marshal helpers allocate.
        try core_funcs.put(ar, "__alloc", {});
    }

    var items: std.ArrayListUnmanaged(ast.Item) = .empty;
    if (has_leaf) try items.append(ar, .{ .types = &prelude.gc_prelude_defs });
    const core_types = [_]struct { []const u8, ast.FuncType }{
        .{ "__alloc", .{ .params = &.{.i32}, .result = .i32 } },
        .{ link.stack_check, .{ .params = &.{.i32}, .result = .i32 } },
        .{ link.random_import, .{ .result = .f64 } },
    };
    for (core_types) |ct| if (core_funcs.contains(ct[0])) try items.append(ar, .{ .import = .{ .module = name, .name = if (std.mem.eql(u8, ct[0], "__alloc")) alloc_export else ct[0], .func = ct[0], .type = ct[1] } });
    for (foreign.keys()) |c| {
        const f = nodes[c].func;
        try items.append(ar, .{ .import = .{ .module = nodes[c].place.?, .name = f.name, .func = f.name, .type = try funcType(ar, f) } });
    }
    if (host_fs) for (prelude.fs_imports) |im| try items.append(ar, .{ .import = im });
    try items.append(ar, .{ .memory = .{ .min_pages = 1, .import = .{ .module = name, .name = memory_export } } });
    if (uses_heap or marshal or core_funcs.contains("__alloc")) try items.append(ar, .{ .global = .{ .name = "__heap_ptr", .ty = .i32, .mutable = true, .import = .{ .module = name, .name = heap_ptr_export } } });
    if (uses_sp) try items.append(ar, .{ .global = .{ .name = link.stack_global, .ty = .i32, .mutable = true, .import = .{ .module = name, .name = link.stack_global } } });
    if (random_state) try items.append(ar, .{ .global = prelude.random_state_global });
    if (marshal) for (prelude.items(.std_marshal)) |it| try items.append(ar, it);
    // Called by another unit: exported by symbol too.
    var called_from_outside: std.AutoHashMapUnmanaged(usize, void) = .empty;
    for (nodes, callees) |n, cs| {
        const p = n.place orelse continue;
        if (std.mem.eql(u8, p, u)) continue;
        for (cs) |c| if (std.mem.eql(u8, nodes[c].place.?, u)) try called_from_outside.put(ar, c, {});
    }
    for (own.items) |k| {
        var f = nodes[k].func;
        f.exports = try exportsOf(ar, nodes[k], called_from_outside.contains(k));
        try items.append(ar, .{ .func = f });
    }
    if (has_leaf) try items.append(ar, .{ .custom = .{ .name = "botopink.needs", .bytes = try needsText(ar, &.{.gc}) } });
    return .{ .module = .{ .items = items.items }, .host_fs = host_fs, .funcs = own.items.len };
}

fn topoOrder(ar: std.mem.Allocator, deps: *std.StringArrayHashMapUnmanaged(std.StringArrayHashMapUnmanaged(void)), diag: *link.Diag) Error![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    var state: std.StringHashMapUnmanaged(u8) = .empty; // 1 visiting, 2 done
    const Visit = struct {
        fn go(a: std.mem.Allocator, d: *std.StringArrayHashMapUnmanaged(std.StringArrayHashMapUnmanaged(void)), st: *std.StringHashMapUnmanaged(u8), o: *std.ArrayListUnmanaged([]const u8), u: []const u8, dg: *link.Diag) Error!void {
            if (st.get(u)) |s| {
                if (s == 2) return;
                dg.message = try std.fmt.allocPrint(a, "the std units import each other through `{s}`", .{u});
                return error.UnitCycle;
            }
            try st.put(a, u, 1);
            for (d.get(u).?.keys()) |v| try go(a, d, st, o, v, dg);
            try st.put(a, u, 2);
            try o.append(a, u);
        }
    };
    // Sorted by name, then each after what it imports.
    const keys = try ar.dupe([]const u8, deps.keys());
    std.mem.sort([]const u8, keys, {}, struct {
        fn lt(_: void, a: []const u8, b: []const u8) bool {
            return std.mem.lessThan(u8, a, b);
        }
    }.lt);
    for (keys) |u| try Visit.go(ar, deps, &state, &out, u, diag);
    return out.items;
}

/// A leaf's GC type name resolved against the prelude group (decision 1021
/// (9)): the same index in every unit.
fn preludeIndex(_: *anyopaque, n: []const u8) ?u16 {
    const p = std.meta.stringToEnum(prelude.GcPrelude, n) orelse return null;
    return @intFromEnum(p);
}

/// `text.length` → `__wat_text_length`: a leaf's symbol in its unit, apart
/// from the decoded function of the same name (`__std_text_length`).
fn leafSymbol(ar: std.mem.Allocator, n: []const u8) ![]const u8 {
    const out = try std.fmt.allocPrint(ar, "__wat_{s}", .{n});
    std.mem.replaceScalar(u8, out, '.', '_');
    return out;
}

/// A leaf's calls of other leaves (`__std_<m>_<f>`, `std_leaves.read`'s
/// spelling) renamed to their unit symbols (`__wat_<m>_<f>`).
fn renameLeafCalls(s: *ast.Seq) void {
    for (@constCast(s.lines)) |*l| switch (l.instr) {
        .call => |*c| if (leaves.isSymbol(c.*)) {
            c.* = std.fmt.allocPrint(arena_state.allocator(), "__wat_{s}", .{c.*["__std_".len..]}) catch c.*;
        },
        .block => |*b| renameLeafCalls(&b.body),
        .@"if" => |*n| {
            renameLeafCalls(&n.then.seq);
            if (n.@"else") |*e| renameLeafCalls(&e.seq);
        },
        else => {},
    };
}

/// Every function `s` calls, and every global it reads or writes when
/// `globals` is given.
fn collectCalls(ar: std.mem.Allocator, s: ast.Seq, calls: *std.ArrayListUnmanaged([]const u8), globals: ?*std.ArrayListUnmanaged([]const u8)) !void {
    for (s.lines) |l| switch (l.instr) {
        .call => |c| try calls.append(ar, c),
        .global_get, .global_set => |g| if (globals) |gs| try gs.append(ar, g),
        .block => |b| try collectCalls(ar, b.body, calls, globals),
        .@"if" => |n| {
            try collectCalls(ar, n.then.seq, calls, globals);
            if (n.@"else") |e| try collectCalls(ar, e.seq, calls, globals);
        },
        else => {},
    };
}

fn funcType(ar: std.mem.Allocator, f: ast.Func) !ast.FuncType {
    const params = try ar.alloc(ast.ValType, f.params.len);
    for (params, f.params) |*p, q| p.* = q.ty;
    return .{ .params = params, .result = f.result };
}

fn needsText(ar: std.mem.Allocator, ns: []const WasmNeed) ![]const u8 {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    for (ns) |n| {
        try text.appendSlice(ar, @tagName(n));
        try text.append(ar, '\n');
    }
    return text.items;
}

fn renderText(ar: std.mem.Allocator, m: ast.Module) ![]const u8 {
    var w: std.Io.Writer.Allocating = .init(ar);
    emitter.renderItemsOf(&w.writer, m) catch |err| switch (err) {
        error.WriteFailed => return error.OutOfMemory,
        else => |e| return e,
    };
    return w.written();
}

/// `$__rt_<name>` exported as `<name>`: the host function `im` imports,
/// called with the caller's arguments.
fn forward(ar: std.mem.Allocator, im: ast.Import) !ast.Func {
    const params = try ar.alloc(ast.Param, im.type.params.len);
    const lines = try ar.alloc(ast.Line, im.type.params.len + 1);
    for (params, im.type.params, 0..) |*p, t, i| {
        p.* = .{ .name = try std.fmt.allocPrint(ar, "p{d}", .{i}), .ty = t };
        lines[i] = .{ .indent = 4, .instr = .{ .local_get = p.name } };
    }
    lines[params.len] = .{ .indent = 4, .instr = .{ .call = im.func } };
    return .{
        .name = try std.fmt.allocPrint(ar, "__rt_{s}", .{im.name}),
        .exports = try ar.dupe([]const u8, &.{im.name}),
        .params = params,
        .result = im.type.result,
        .body = .{ .lines = lines, .stack = if (im.type.result) |t| .{ .value = t } else .none },
    };
}

// ── what a binary module imports ─────────────────────────────────────────────

/// What a binary program module imports of the runtime: the modules it
/// names that start with `std@` (the core's included), and the pages its
/// memory import asks for.
pub const Imports = struct { units: []const []const u8, pages: u32 };

pub fn importsOf(ar: std.mem.Allocator, bytes: []const u8) !Imports {
    var units: std.ArrayListUnmanaged([]const u8) = .empty;
    var pages: u32 = 0;
    if (bytes.len < 8) return .{ .units = &.{}, .pages = 0 };
    var i: usize = 8;
    while (i < bytes.len) {
        const id = bytes[i];
        i += 1;
        const len = uleb(bytes, &i) orelse break;
        if (i + len > bytes.len) break;
        if (id == 2) {
            var j = i;
            const end = i + len;
            var n = uleb(bytes, &j) orelse break;
            while (n > 0 and j < end) : (n -= 1) {
                const ml = uleb(bytes, &j) orelse break;
                if (j + ml > end) break;
                const module = bytes[j .. j + ml];
                j += ml;
                const fl = uleb(bytes, &j) orelse break;
                j += fl;
                if (j >= end) break;
                const kind = bytes[j];
                j += 1;
                switch (kind) {
                    0 => _ = uleb(bytes, &j) orelse break,
                    2 => {
                        const flags = bytes[j];
                        j += 1;
                        const min = uleb(bytes, &j) orelse break;
                        if (flags & 1 != 0) _ = uleb(bytes, &j) orelse break;
                        if (std.mem.eql(u8, module, name)) pages = @intCast(min);
                    },
                    3 => {
                        const t = bytes[j];
                        j += 1;
                        if (t == 0x63 or t == 0x64) _ = uleb(bytes, &j) orelse break;
                        j += 1;
                    },
                    4 => {
                        j += 1;
                        _ = uleb(bytes, &j) orelse break;
                    },
                    else => break,
                }
                if (!std.mem.startsWith(u8, module, "std@")) continue;
                for (units.items) |u| {
                    if (std.mem.eql(u8, u, module)) break;
                } else try units.append(ar, try ar.dupe(u8, module));
            }
            break;
        }
        i += len;
    }
    return .{ .units = units.items, .pages = pages };
}

/// Whether the binary module `bytes` imports the runtime core.
pub fn importsRuntime(bytes: []const u8) bool {
    var buf: [4096]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    const im = importsOf(fba.allocator(), bytes) catch return true;
    for (im.units) |u| if (std.mem.eql(u8, u, name)) return true;
    return false;
}

fn uleb(b: []const u8, i: *usize) ?usize {
    var v: usize = 0;
    var shift: u6 = 0;
    while (i.* < b.len) {
        const x = b[i.*];
        i.* += 1;
        v |= @as(usize, x & 0x7f) << shift;
        if (x & 0x80 == 0) return v;
        shift +|= 7;
        if (shift >= 63) return null;
    }
    return null;
}

test "the core holds no std module's function; every std-wasm export and leaf is a unit's" {
    const r = try get();
    var diag: link.Diag = .{};
    var a = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer a.deinit();
    const ar = a.allocator();
    const wanted = try link.programExports(ar, link.module_bytes, &diag);
    for (wanted) |w| {
        const ref = r.std_refs.get(w) orelse return error.TestUnexpectedResult;
        try std.testing.expect(r.unit(ref.unit) != null);
    }
    for (r.core.items) |it| if (it == .func) for (it.func.exports) |x| {
        try std.testing.expect(!std.mem.startsWith(u8, x, link.export_prefix));
        try std.testing.expect(!std.mem.startsWith(u8, x, leaf_prefix));
    };
    // `io.fs` is a unit importing `bp_fs`; the closure of `std@io@fs` is in
    // dependency order.
    const fs = r.unit("std@io@fs") orelse return error.TestUnexpectedResult;
    try std.testing.expect(fs.host_fs);
    const cl = try r.closure(ar, &.{"std@io@fs"});
    try std.testing.expectEqualStrings("std@io@fs", cl[cl.len - 1].name);
    try std.testing.expect(!importsRuntime(r.core_bytes));
    try std.testing.expectEqual(r, try get());
}
