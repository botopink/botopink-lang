//! A host function's Erlang cell — and any set of `.beam` modules — run at
//! comptime through beam-to-wasm (decisions 434 (3), 438; 144 B-00b).
//!
//! An `@External.Erlang("…")` template — or an `@External.Erlang("m", "f")`
//! pair, read as the template `m:f($0, …)` — is
//! compiled to a `.beam` the way the beam target compiles every Erlang
//! template (`codegen/beam/erl_template.zig` `templateBody` → `templateModuleText` →
//! `lowerTemplateText`, then `beam/beam_file.zig` `assemble`: the compiler's
//! own BEAM assembler, no `erlc`), and that `.beam` is translated by
//! `modules/beam-to-wasm` into wasm functions over this runtime's terms, its
//! BIF calls bound to `rt.zig`'s exports (`lower.zig` `bifs`). A cell whose
//! `t/N` reaches something beam-to-wasm does not convert is refused, naming
//! it (`bw.refusalReaching`).
//!
//! The one-function module is `bp_cell_<hash>` (the hash of the arity and the
//! template text): a comptime module calls it `bp_cell_<hash>:t(…)`. A set of
//! `.beam` files — whatever compiled them — is translated whole by `ofModules`
//! and each module kept by its own name, a call from one to another followed
//! (decision 438). `program.zig` hands the lowering every translated module
//! the generated text calls, and every one those call (`modulesIn`). Cached
//! process-wide by module name.
const std = @import("std");
const bw = @import("beam_to_wasm");
const erlTemplate = @import("../../../codegen/beam/erl_template.zig");
const beamFile = @import("../../../codegen/beam/beam_file.zig");
const lower = @import("lower.zig");

pub const Error = std.mem.Allocator.Error;

/// The prefix of every cell module's name.
pub const module_prefix = "bp_cell_";

pub const Cell = union(enum) {
    /// The cell module's name: call `<name>:t/<arity>`.
    ok: []const u8,
    /// What beam-to-wasm (or the template's reading) did not convert.
    refused: []const u8,
};

const Entry = union(enum) {
    ok: bw.ir.Module,
    refused: []const u8,
};

const cache_alloc = std.heap.page_allocator;
var cache_lock: std.atomic.Value(u8) = .init(0);
var cache: std.StringArrayHashMapUnmanaged(Entry) = .empty;

fn lock() void {
    while (cache_lock.cmpxchgWeak(0, 1, .acquire, .monotonic)) |_| std.atomic.spinLoopHint();
}

fn unlock() void {
    cache_lock.store(0, .release);
}

/// The cell module serving template `template_raw` (as written in the
/// annotation) called with `arity` arguments, translated once per process.
pub fn ofTemplate(template_raw: []const u8, arity: usize) Error!Cell {
    var h = std.hash.Wyhash.init(0x434);
    h.update(std.mem.asBytes(&arity));
    h.update(template_raw);
    var name_buf: [module_prefix.len + 16]u8 = undefined;
    const name = std.fmt.bufPrint(&name_buf, module_prefix ++ "{x:0>16}", .{h.final()}) catch unreachable;

    lock();
    defer unlock();
    if (cache.get(name)) |hit| return switch (hit) {
        .ok => |m| .{ .ok = m.name },
        .refused => |why| .{ .refused = why },
    };
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    const ar = arena_state.allocator();
    const owned = try ar.dupe(u8, name);
    const entry = try translate(ar, template_raw, arity, owned);
    try cache.put(cache_alloc, owned, entry);
    return switch (entry) {
        .ok => .{ .ok = owned },
        .refused => |why| .{ .refused = why },
    };
}

pub const Modules = union(enum) {
    /// The modules' names, in the order of the files.
    ok: []const []const u8,
    /// Why the set was not translated (a file that is not BEAM, two files of
    /// one module, a module of that name translated from other bytes).
    refused: []const u8,
};

/// Translate the `.beam` files `files` as one set (beam-to-wasm's
/// `translateSet`) and keep each module by its own name, so a comptime
/// module that calls `<module>:<function>(…)` reaches it. A function that
/// does not convert is refused only when a call reaches it (`program.zig`
/// asks `refusalOf` first). A module of a name already kept from other bytes
/// is refused: one name, one module, for the process.
pub fn ofModules(files: []const []const u8) Error!Modules {
    lock();
    defer unlock();
    var arena_state = std.heap.ArenaAllocator.init(cache_alloc);
    const ar = arena_state.allocator();
    const set = switch (try bw.translateSet(ar, files, lower.beam_to_wasm_bifs)) {
        .ok => |set| set,
        .refused => |r| return .{ .refused = try std.fmt.allocPrint(ar, "{f}", .{r}) },
    };
    const names = try ar.alloc([]const u8, set.len);
    for (set, files, names) |m, bytes, *n| {
        n.* = m.name;
        if (sources.get(m.name)) |had| if (!std.mem.eql(u8, had, bytes))
            return .{ .refused = try std.fmt.allocPrint(ar, "module `{s}` is translated already, from other bytes", .{m.name}) };
    }
    for (set, files) |m, bytes| {
        if (sources.contains(m.name)) continue;
        try sources.put(cache_alloc, m.name, try ar.dupe(u8, bytes));
        try cache.put(cache_alloc, m.name, .{ .ok = m });
    }
    return .{ .ok = names };
}

/// The `.beam` bytes each module `ofModules` kept was translated from.
var sources: std.StringHashMapUnmanaged([]const u8) = .empty;

/// What a call of `module:function` (`<name>/<arity>`) meets that
/// beam-to-wasm did not convert, among the modules kept — formatted, or null
/// when everything it reaches converted.
pub fn refusalOf(arena: std.mem.Allocator, module: []const u8, function: []const u8) Error!?[]const u8 {
    lock();
    defer unlock();
    var set: std.ArrayListUnmanaged(bw.ir.Module) = .empty;
    for (cache.values()) |e| switch (e) {
        .ok => |m| try set.append(arena, m),
        .refused => {},
    };
    const r = (try bw.refusalReaching(arena, set.items, module, function)) orelse return null;
    return try std.fmt.allocPrint(arena, "{f}", .{r});
}

/// The cell module serving `module:function` called with `arity` arguments
/// (an `@External.Erlang("m", "f")` pair).
pub fn ofCall(arena: std.mem.Allocator, module: []const u8, function: []const u8, arity: usize) Error!Cell {
    var text: std.ArrayListUnmanaged(u8) = .empty;
    try text.print(arena, "{s}:{s}(", .{ module, function });
    for (0..arity) |i| try text.print(arena, "{s}${d}", .{ if (i == 0) "" else ", ", i });
    try text.append(arena, ')');
    return ofTemplate(text.items, arity);
}

fn translate(ar: std.mem.Allocator, template_raw: []const u8, arity: usize, name: []const u8) Error!Entry {
    const body = erlTemplate.templateBody(ar, template_raw, arity) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the template does not read ({s})", .{@errorName(err)}) },
    };
    const text = try erlTemplate.templateModuleText(ar, body, false, arity);
    const lowered = switch (try erlTemplate.lowerTemplateText(ar, text, name)) {
        .ok => |o| o,
        .refused => |why| return .{ .refused = why },
    };
    const beam = beamFile.assemble(ar, lowered.module) catch |err| switch (err) {
        error.OutOfMemory => return error.OutOfMemory,
        else => return .{ .refused = try std.fmt.allocPrint(ar, "the template does not assemble ({s})", .{@errorName(err)}) },
    };
    const m = switch (try bw.translate(ar, beam, lower.beam_to_wasm_bifs)) {
        .ok => |m| m,
        .refused => |r| return .{ .refused = r.what },
    };
    // The cell is `t/<arity>`: what it reaches that does not convert is
    // named alone — the cell module's name is the compiler's, not the
    // reader's.
    const entry = try std.fmt.allocPrint(ar, "t/{d}", .{arity});
    if (try bw.refusalReaching(ar, &.{m}, m.name, entry)) |r| return .{ .refused = r.what };
    return .{ .ok = m };
}

/// The translated modules the generated module text `code` calls — a cell
/// (`bp_cell_<hash>:t(…)`) or a module `ofModules` kept — and every kept
/// module those call in turn.
pub fn modulesIn(arena: std.mem.Allocator, code: []const u8) Error![]const bw.ir.Module {
    lock();
    defer unlock();
    var out: std.ArrayListUnmanaged(bw.ir.Module) = .empty;
    var have: std.StringHashMapUnmanaged(void) = .empty;
    for (cache.keys(), cache.values()) |name, entry| switch (entry) {
        .ok => |m| if (callsModule(code, name)) {
            try have.put(arena, name, {});
            try out.append(arena, m);
        },
        .refused => {},
    };
    // The modules those call, closed.
    var i: usize = 0;
    while (i < out.items.len) : (i += 1) {
        for (out.items[i].functions) |f| try calleesOf(arena, f.body, &have, &out);
    }
    return out.toOwnedSlice(arena);
}

fn calleesOf(arena: std.mem.Allocator, body: []const bw.ir.Instr, have: *std.StringHashMapUnmanaged(void), out: *std.ArrayListUnmanaged(bw.ir.Module)) Error!void {
    for (body) |ins| switch (ins) {
        .call => |c| {
            if (have.contains(c.module)) continue;
            const e = cache.get(c.module) orelse continue;
            if (e != .ok) continue;
            try have.put(arena, c.module, {});
            try out.append(arena, e.ok);
        },
        .block => |b| try calleesOf(arena, b.body, have, out),
        else => {},
    };
}

/// Whether Erlang text `code` calls module `name` — `name:` or `'name':`,
/// not as the tail of a longer atom.
fn callsModule(code: []const u8, name: []const u8) bool {
    var at: usize = 0;
    while (std.mem.indexOfPos(u8, code, at, name)) |i| : (at = i + 1) {
        const end = i + name.len;
        if (i > 0 and (std.ascii.isAlphanumeric(code[i - 1]) or code[i - 1] == '_' or code[i - 1] == '@')) continue;
        const after = if (end < code.len and code[end] == '\'' and i > 0 and code[i - 1] == '\'') end + 1 else end;
        if (after < code.len and code[after] == ':') return true;
    }
    return false;
}

test "a template cell translates; the same text is one module" {
    const a = try ofTemplate("<<($0)/binary, \"!\">>", 1);
    const b = try ofTemplate("<<($0)/binary, \"!\">>", 1);
    try std.testing.expect(a == .ok);
    try std.testing.expectEqualStrings(a.ok, b.ok);
    try std.testing.expect(std.mem.startsWith(u8, a.ok, module_prefix));
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const in = try modulesIn(arena_state.allocator(), try std.fmt.allocPrint(arena_state.allocator(), "main(_) -> {s}:t(<<\"x\">>).", .{a.ok}));
    try std.testing.expectEqual(@as(usize, 1), in.len);
    try std.testing.expectEqualStrings("t/1", in[0].functions[0].name);
}

test "a call outside the runtime's BIFs is refused, named" {
    const c = try ofTemplate("[re:run($0, <<\"a\">>)]", 1);
    try std.testing.expectEqualStrings("`re:run/2`", c.refused);
}

test "a tail call converts: an OTP function the runtime serves, called last" {
    var arena_state = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena_state.deinit();
    const c = try ofCall(arena_state.allocator(), "string", "uppercase", 1);
    try std.testing.expect(c == .ok);
}

test "an opcode beam-to-wasm does not convert is refused, named: a fun" {
    const c = try ofTemplate("fun() -> $0 end", 1);
    try std.testing.expectEqualStrings("opcode 171 (make_fun3)", c.refused);
}

test "callsModule: a call of the module, never a longer atom's tail" {
    try std.testing.expect(callsModule("main(_) -> greeting:hello(<<\"x\">>).", "greeting"));
    try std.testing.expect(callsModule("main(_) -> 'greeting':hello(1).", "greeting"));
    try std.testing.expect(!callsModule("main(_) -> my_greeting:hello(1).", "greeting"));
    try std.testing.expect(!callsModule("main(_) -> greeting_text:title(1).", "greeting"));
    try std.testing.expect(!callsModule("main(_) -> greeting.", "greeting"));
}
