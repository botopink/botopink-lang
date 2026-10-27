//! Decision 518 (2) — what a lowered module REACHES: the call graph of its
//! functions from the roots a host can enter by (an exported function, the
//! start function, and every entry of the function table once a reached
//! function holds a `call_indirect`, which may pick any). `wat.zig` gathers the `needs` of the host
//! bindings the graph reaches, and drops the unreached callers of a binding it
//! leaves out.

const std = @import("std");
const wat = @import("./wat_ast.zig");

const Names = std.StringHashMapUnmanaged(void);

/// A function that starts a task (decision 392) and the step function the
/// task runs: `$__task_resume` dispatches over every step by the task's kind,
/// but only a task some reached function starts can run one.
pub const Edge = struct { from: []const u8, to: []const u8 };

/// The dispatcher over the task steps (`wat.zig` `taskResumeFunc`).
const task_dispatch = "__task_resume";

/// The names of the functions reachable from the module's roots. A call of the
/// task dispatcher to a step is no edge; `edges` are.
pub fn reached(alloc: std.mem.Allocator, items: []const wat.Item, edges: []const Edge) !Names {
    var funcs: std.StringHashMapUnmanaged(*const wat.Func) = .empty;
    defer funcs.deinit(alloc);
    for (items) |*it| switch (it.*) {
        .func => |*f| try funcs.put(alloc, f.name, f),
        else => {},
    };
    var seen: Names = .empty;
    errdefer seen.deinit(alloc);
    var work: std.ArrayListUnmanaged([]const u8) = .empty;
    defer work.deinit(alloc);
    for (items) |it| switch (it) {
        .func => |f| if (f.exports.len > 0) try work.append(alloc, f.name),
        .start => |n| try work.append(alloc, n),
        else => {},
    };
    var indirect = false;
    var table_in = false;
    while (true) {
        while (work.pop()) |name| {
            if ((try seen.fetchPut(alloc, name, {})) != null) continue;
            const f = funcs.get(name) orelse continue;
            const before = work.items.len;
            try collectCalls(alloc, f.body, &work, &indirect);
            if (std.mem.eql(u8, name, task_dispatch)) {
                var keep = before;
                for (work.items[before..]) |c| {
                    if (isStep(edges, c)) continue;
                    work.items[keep] = c;
                    keep += 1;
                }
                work.shrinkRetainingCapacity(keep);
            }
            for (edges) |e| if (std.mem.eql(u8, e.from, name)) try work.append(alloc, e.to);
        }
        if (!indirect or table_in) break;
        table_in = true;
        for (items) |it| switch (it) {
            .table => |names| for (names) |n| try work.append(alloc, n),
            else => {},
        };
    }
    return seen;
}

fn isStep(edges: []const Edge, name: []const u8) bool {
    for (edges) |e| if (std.mem.eql(u8, e.to, name)) return true;
    return false;
}

fn collectCalls(alloc: std.mem.Allocator, s: wat.Seq, out: *std.ArrayListUnmanaged([]const u8), indirect: *bool) !void {
    for (s.lines) |l| switch (l.instr) {
        // Decision 1055 (4) — a `ref.func` makes the function a value some
        // `call_ref` may call: an edge as a call is.
        .call, .ref_func => |n| try out.append(alloc, n),
        .call_indirect => indirect.* = true,
        .@"if" => |n| {
            try collectCalls(alloc, n.then.seq, out, indirect);
            if (n.@"else") |e| try collectCalls(alloc, e.seq, out, indirect);
        },
        .block => |b| try collectCalls(alloc, b.body, out, indirect),
        else => {},
    };
}

fn callsAny(s: wat.Seq, gone: *const Names) bool {
    for (s.lines) |l| switch (l.instr) {
        .call, .ref_func => |n| if (gone.contains(n)) return true,
        .@"if" => |n| {
            if (callsAny(n.then.seq, gone)) return true;
            if (n.@"else") |e| if (callsAny(e.seq, gone)) return true;
        },
        .block => |b| if (callsAny(b.body, gone)) return true,
        else => {},
    };
    return false;
}

/// `items` without the functions in `gone` and, repeatedly, without any
/// function that calls one that went. The caller guarantees none of them is
/// reachable (`reached`), so the module still validates. `alloc` is the arena
/// `items` was built in.
pub fn dropCallers(alloc: std.mem.Allocator, items: *std.ArrayListUnmanaged(wat.Item), gone_in: Names, range: ?*[2]usize) !void {
    var gone = try gone_in.clone(alloc);
    var changed = true;
    while (changed) {
        changed = false;
        for (items.items) |it| switch (it) {
            .func => |f| if (!gone.contains(f.name) and !std.mem.eql(u8, f.name, task_dispatch) and callsAny(f.body, &gone)) {
                try gone.put(alloc, f.name, {});
                changed = true;
            },
            else => {},
        };
    }
    var keep: usize = 0;
    var dead_stub = false;
    // `range` is a span of `items` (the program's own); it follows the items
    // that stay, so an index into it is still in bounds after the removal.
    var new_range: [2]usize = .{ 0, 0 };
    for (items.items, 0..) |*it, at| {
        if (range) |r| {
            if (at == r[0]) new_range[0] = keep;
            if (at == r[1]) new_range[1] = keep;
        }
        if (it.* == .func and gone.contains(it.func.name)) continue;
        // The task dispatcher keeps standing: the step of a task nothing
        // starts is gone, and its dispatch arm drops the task instead.
        if (it.* == .func and std.mem.eql(u8, it.func.name, task_dispatch)) {
            var g = it.func;
            g.body = try dropCalls(alloc, g.body, &gone);
            it.* = .{ .func = g };
        }
        // A table keeps its indexes: an entry that went is a function that
        // only traps (no reached `call_indirect` can pick it).
        if (it.* == .table) {
            const names = try alloc.dupe([]const u8, it.table);
            for (names) |*n| if (gone.contains(n.*)) {
                n.* = dead_name;
                dead_stub = true;
            };
            it.* = .{ .table = names };
        }
        if (it.* == .elem_declare) {
            var names: std.ArrayListUnmanaged([]const u8) = .empty;
            for (it.elem_declare) |n| if (!gone.contains(n)) try names.append(alloc, n);
            if (names.items.len == 0) continue;
            it.* = .{ .elem_declare = names.items };
        }
        items.items[keep] = it.*;
        keep += 1;
    }
    if (range) |r| {
        if (r[1] >= items.items.len) new_range[1] = keep;
        if (r[0] >= items.items.len) new_range[0] = keep;
        r.* = new_range;
    }
    items.shrinkRetainingCapacity(keep);
    if (dead_stub) try items.append(alloc, .{ .func = .{
        .name = dead_name,
        .body = .{ .stack = .terminated, .lines = &.{.{ .instr = .@"unreachable" }} },
    } });
}

/// `s` with each call of a function in `gone` turned into a `drop` of its one
/// argument (the step functions take the task and answer nothing).
fn dropCalls(alloc: std.mem.Allocator, s: wat.Seq, gone: *const Names) !wat.Seq {
    const lines = try alloc.dupe(wat.Line, s.lines);
    for (lines) |*l| switch (l.instr) {
        .call => |n| if (gone.contains(n)) {
            l.instr = .drop;
        },
        .@"if" => |n| {
            var m = n;
            m.then.seq = try dropCalls(alloc, n.then.seq, gone);
            if (n.@"else") |e| {
                var e2 = e;
                e2.seq = try dropCalls(alloc, e.seq, gone);
                m.@"else" = e2;
            }
            l.instr = .{ .@"if" = m };
        },
        else => {},
    };
    return .{ .lines = lines, .stack = s.stack };
}

const dead_name = "__bp_dead";

test "dropCallers: the range follows the items that stay" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const ar = arena.allocator();
    const lines = try ar.dupe(wat.Line, &.{.{ .instr = .{ .call = "gone" } }});
    var items: std.ArrayListUnmanaged(wat.Item) = .empty;
    try items.append(ar, .{ .func = .{ .name = "before" } });
    try items.append(ar, .{ .func = .{ .name = "gone" } });
    try items.append(ar, .{ .func = .{ .name = "caller", .body = .{ .lines = lines } } });
    try items.append(ar, .{ .func = .{ .name = "kept" } });
    var skip: Names = .empty;
    try skip.put(ar, "gone", {});
    var range = [2]usize{ 1, 4 };
    try dropCallers(ar, &items, skip, &range);
    try std.testing.expectEqual(@as(usize, 2), items.items.len);
    try std.testing.expectEqual(@as(usize, 1), range[0]);
    try std.testing.expectEqual(@as(usize, 2), range[1]);
}
