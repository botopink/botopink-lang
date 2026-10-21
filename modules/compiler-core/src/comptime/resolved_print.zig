//! Decisions 798 (1), (2), (4) and 805 (5), (6) — the resolved program's
//! printer: botopink with no comptime left, from each module's
//! `OkData.resolved` (kept under `comptime.keep_resolved`).
//!
//! The tree is the compiler's after comptime ran: folded values spliced as
//! literals, template expansions and specialised copies in place, a
//! decorator's members and `compiler.init` executors merged, a top-level
//! `comptime` block's executors where it stood. What it still holds that a
//! program does not write is left out or spelled back here:
//!
//! - a top-level `comptime` block's marker (`#[__bp_comptime_<k>] val
//!   __bp_comptime_<k>_at`) and the block itself: it ran at build;
//! - an annotation naming a decorator: it ran; what the compiler reads at emit
//!   (`#[compiler.external(…)]`, `#[compiler.stage(…)]`,
//!   `#[compiler.beamMemory(…)]`, an `@`-annotation) is kept, so one printing
//!   serves every target (798 (4));
//! - a `comptime` / `syntax` parameter a kept function still declares: a
//!   plain parameter;
//! - std's `print` / `panic`, which the checker marks as builtins (606 (2)):
//!   called by name, their import written;
//! - a specialised copy's `name_$N`: between backticks (805 (5)).
const std = @import("std");
const ast = @import("../ast.zig");
const format = @import("../format.zig");
const comptimeMod = @import("../comptime.zig");
const implementations = @import("../parser/implementations.zig");
const mayHoldExpr = @import("std_namespace.zig").mayHoldExpr;

const ComptimeOutput = comptimeMod.ComptimeOutput;

pub const Error = error{
    /// A module of `paths` was not analysed, or was refused: it has no
    /// resolved program.
    NotResolved,
} || std.mem.Allocator.Error;

/// The resolved program of the modules named in `paths` (one package), in
/// the session's order, each opened by a `// module <path>` line.
pub fn print(allocator: std.mem.Allocator, outputs: []const ComptimeOutput, paths: []const []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    for (outputs) |o| {
        const wanted = for (paths) |p| {
            if (std.mem.eql(u8, p, o.name)) break true;
        } else false;
        if (!wanted) continue;
        const ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => return error.NotResolved,
        };
        const program = ok.resolved orelse return error.NotResolved;
        try out.print(allocator, "// module {s}\n", .{o.name});
        const text = try module(allocator, program, outputs, o.name);
        defer allocator.free(text);
        try out.appendSlice(allocator, text);
        try out.append(allocator, '\n');
    }
    return out.toOwnedSlice(allocator);
}

/// One module's resolved program as botopink text.
pub fn module(allocator: std.mem.Allocator, program: ast.Program, outputs: []const ComptimeOutput, self_name: []const u8) ![]u8 {
    var arena_state = std.heap.ArenaAllocator.init(allocator);
    defer arena_state.deinit();
    const arena = arena_state.allocator();

    var decls: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    var blank: std.ArrayListUnmanaged(bool) = .empty;
    for (program.decls, 0..) |d, i| {
        if (dropped(d)) continue;
        try decls.append(arena, d);
        try blank.append(arena, if (i < program.blankLineBefore.len) program.blankLineBefore[i] else false);
    }
    // The module's `////` comments open it, before the imports an expansion
    // added in front of them.
    var head: usize = 0;
    for (decls.items, 0..) |d, i| switch (d) {
        .use => {},
        .comment => |c| if (c.is_module) {
            if (i != head) {
                const moved = decls.orderedRemove(i);
                const moved_blank = blank.orderedRemove(i);
                try decls.insert(arena, head, moved);
                try blank.insert(arena, head, moved_blank);
            }
            head += 1;
        },
        else => break,
    };
    if (head > 0) {
        blank.items[0] = false;
        if (head < blank.items.len) blank.items[head] = true;
    }
    // A first printing tells which of std's `print` / `panic` the module calls.
    var probe: format.Formatter.Resolved = .{ .keepAnnotation = keepAnnotation };
    _ = try format.formatResolved(arena, .{ .decls = decls.items, .blankLineBefore = blank.items }, &probe);
    var items: std.ArrayListUnmanaged(ast.ImportPath) = .empty;
    if (probe.used_print and !binds(decls.items, "print")) try items.append(arena, try stdItem(arena, &.{ "io", "terminal", "print" }));
    if (probe.used_panic and !binds(decls.items, "panic")) try items.append(arena, try stdItem(arena, &.{ "failure", "panic" }));
    // A type a folded value or an expansion names that another module
    // declares (`Context` of `std/context`): imported from it.
    var names: Names = .{ .arena = arena };
    for (decls.items) |*d| try names.walk(ast.DeclKind, d);
    var nit = names.found.keyIterator();
    while (nit.next()) |n| {
        if (binds(decls.items, n.*) or declaresType(decls.items, n.*)) continue;
        const owner = typeOwner(outputs, self_name, n.*) orelse continue;
        if (std.mem.startsWith(u8, owner, "std/")) try items.append(arena, try pathItem(arena, owner["std/".len..], n.*));
    }
    if (items.items.len > 0) {
        // After the module's leading comments, where its imports stand.
        var at: usize = 0;
        while (at < decls.items.len and decls.items[at] == .comment) at += 1;
        try decls.insert(arena, at, .{ .use = .{ .imports = items.items, .source = .{ .module = "std" } } });
        try blank.insert(arena, at, at > 0);
        if (at + 1 < blank.items.len) blank.items[at + 1] = true;
    }
    var r: format.Formatter.Resolved = .{ .keepAnnotation = keepAnnotation };
    const body = try format.formatResolved(arena, .{ .decls = decls.items, .blankLineBefore = blank.items }, &r);
    return allocator.dupe(u8, body);
}

/// The import item naming `name` of the module at `path` (`context` →
/// `context.Context`).
fn pathItem(arena: std.mem.Allocator, path: []const u8, name: []const u8) !ast.ImportPath {
    var segs: std.ArrayListUnmanaged([]const u8) = .empty;
    var it = std.mem.splitScalar(u8, path, '/');
    while (it.next()) |seg| try segs.append(arena, seg);
    try segs.append(arena, name);
    return .{ .segments = segs.items };
}

/// The one module of the session other than `self_name` that declares a
/// public type `name`; null when none or more than one does.
fn typeOwner(outputs: []const ComptimeOutput, self_name: []const u8, name: []const u8) ?[]const u8 {
    var owner: ?[]const u8 = null;
    for (outputs) |o| {
        if (std.mem.eql(u8, o.name, self_name)) continue;
        const ok = switch (o.outcome) {
            .ok => |ok| ok,
            else => continue,
        };
        const program = ok.resolved orelse ok.transformed;
        for (program.decls) |d| switch (d) {
            .type_ => |t| if (t.isPub and std.mem.eql(u8, t.name, name)) {
                if (owner != null) return null;
                owner = o.name;
            },
            else => {},
        };
    }
    return owner;
}

fn declaresType(decls: []const ast.DeclKind, name: []const u8) bool {
    for (decls) |d| switch (d) {
        .type_ => |t| if (std.mem.eql(u8, t.name, name)) return true,
        .typeAlias => |t| if (std.mem.eql(u8, t.name, name)) return true,
        .behavior => |b| if (std.mem.eql(u8, b.name, name)) return true,
        else => {},
    };
    return false;
}

/// The capitalised names a module's expressions call or read bare — the
/// candidates for a type the module names but does not declare.
const Names = struct {
    arena: std.mem.Allocator,
    found: std.StringHashMapUnmanaged(void) = .empty,

    fn note(self: *Names, name: []const u8) !void {
        if (name.len == 0 or !std.ascii.isUpper(name[0])) return;
        try self.found.put(self.arena, name, {});
    }

    fn walk(self: *Names, comptime T: type, ptr: *const T) std.mem.Allocator.Error!void {
        if (T == ast.ImportDecl) return;
        switch (@typeInfo(T)) {
            .@"struct" => |st| {
                if (comptime hasField(st.fields, "callee") and hasField(st.fields, "receiver") and hasField(st.fields, "is_builtin")) {
                    if (ptr.receiver == null and !ptr.is_builtin) try self.note(ptr.callee);
                }
                inline for (st.fields) |f| {
                    if (f.is_comptime) continue;
                    if (comptime mayHoldExpr(f.type)) try self.walk(f.type, &@field(ptr.*, f.name));
                }
            },
            .@"union" => |u| if (u.tag_type != null) switch (ptr.*) {
                inline else => |*payload, tag| {
                    if (comptime std.mem.eql(u8, @tagName(tag), "ident") and @TypeOf(payload.*) == []const u8) {
                        try self.note(payload.*);
                    } else if (comptime mayHoldExpr(@TypeOf(payload.*))) {
                        try self.walk(@TypeOf(payload.*), payload);
                    }
                },
            },
            .optional => |o| if (ptr.*) |*inner| try self.walk(o.child, inner),
            .pointer => |p| switch (p.size) {
                .one => if (comptime mayHoldExpr(p.child)) try self.walk(p.child, ptr.*),
                .slice => if (comptime mayHoldExpr(p.child)) {
                    for (ptr.*) |*e| try self.walk(p.child, e);
                },
                else => {},
            },
            .array => |arr| if (comptime mayHoldExpr(arr.child)) {
                for (ptr) |*e| try self.walk(arr.child, e);
            },
            else => {},
        }
    }

    fn hasField(comptime fields: anytype, comptime name: []const u8) bool {
        inline for (fields) |f| if (comptime std.mem.eql(u8, f.name, name)) return true;
        return false;
    }
};

fn stdItem(arena: std.mem.Allocator, segments: []const []const u8) !ast.ImportPath {
    return .{ .segments = try arena.dupe([]const u8, segments) };
}

/// A declaration the resolved program does not hold: what ran at build.
fn dropped(d: ast.DeclKind) bool {
    return switch (d) {
        .comptimeBlock => true,
        .val => |v| for (v.annotations) |a| {
            if (std.mem.startsWith(u8, a.name, "__bp_comptime_")) break true;
        } else false,
        else => false,
    };
}

/// What the compiler reads at emit is printed; a decorator, which ran, is not.
fn keepAnnotation(a: ast.Annotation) bool {
    if (implementations.isSourceAnnotation(a)) return true;
    if (a.stageOf() != null or a.beamMemoryOf() != null) return true;
    return a.is_builtin;
}

/// Whether a top-level declaration or import of `decls` binds `name`.
fn binds(decls: []const ast.DeclKind, name: []const u8) bool {
    for (decls) |d| switch (d) {
        .@"fn" => |f| if (std.mem.eql(u8, f.name, name)) return true,
        .val => |v| if (std.mem.eql(u8, v.name, name)) return true,
        .use => |u| for (u.imports) |p| {
            const bound = p.alias orelse (if (p.segments.len > 0) p.segments[p.segments.len - 1] else "");
            if (std.mem.eql(u8, bound, name)) return true;
        },
        else => {},
    };
    return false;
}
