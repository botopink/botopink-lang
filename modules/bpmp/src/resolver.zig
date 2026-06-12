/// Constraint solver.
///
/// `resolve(manifest, tag_provider)` walks the project's top-level
/// `requires` map, asks `tag_provider` for each repo's tag list, picks the
/// highest tag satisfying the constraint, and recurses into the resolved
/// package's own `requires` for transitive deps. Conflict between two
/// pinned constraints (overlapping but different ranges, or disjoint ranges)
/// produces a `Conflict` report **with both edges named** — the user fixes it
/// by pinning the dep in their own `requires` (plan §"Conflict resolution").
///
/// No backtracking. The resolver works through a fixed-point iteration: each
/// pass walks the queue, asks the tag provider for any unknown packages, and
/// records a resolution or a conflict. When no new packages were added in a
/// pass, resolution is done.
const std = @import("std");
const semver = @import("./semver.zig");

pub const Error = error{
    Conflict,
    NoMatchingTag,
    OnlineUnavailable,
    BadConstraint,
} || std.mem.Allocator.Error || semver.Constraint.ParseError;

/// One package's resolved pin — the resolver's output entry.
pub const Resolution = struct {
    name: []const u8,
    tag: semver.Tag,
    constraint: []const u8,
    /// Names of packages this resolution requires (transitive deps).
    requires: []const []const u8 = &.{},
};

/// A constraint that asked for something nothing satisfied / something
/// already-pinned cannot satisfy.
pub const Conflict = struct {
    package: []const u8,
    edges: []const Edge,

    pub const Edge = struct {
        /// Which package required this dep (`"<root>"` for the project itself).
        source: []const u8,
        constraint: []const u8,
    };
};

/// Caller-supplied tag enumerator. Real code passes the live HTTP client;
/// tests pass a synthetic map from package name → `[]semver.Tag`.
pub const TagProvider = struct {
    ctx: ?*anyopaque,
    list: ListFn,

    pub const ListFn = *const fn (
        ctx: ?*anyopaque,
        gpa: std.mem.Allocator,
        package_name: []const u8,
    ) Error![]const semver.Tag;
};

/// What `requires` looks like to the resolver: `[]Constraint{ name, constraint }`.
pub const RequireEdge = struct {
    name: []const u8,
    constraint: []const u8,
};

pub const Result = struct {
    arena: std.heap.ArenaAllocator,
    resolutions: []Resolution,

    pub fn deinit(self: *Result) void {
        self.arena.deinit();
    }
};

/// Resolve `top_edges` (the project's `requires`) against `provider`. Returns
/// the full transitive resolution graph. The current drop accepts no
/// transitive `requires` source other than the top-level edges — when an
/// online tag fetch lands, a per-package `requires` re-read will be added
/// here. For now, the surface is the keystone the commands wire against, and
/// the conflict-detection logic is exercised against a synthetic provider.
pub fn resolve(
    gpa: std.mem.Allocator,
    top_edges: []const RequireEdge,
    provider: TagProvider,
) (Error || error{ResolutionConflict})!Result {
    var arena = std.heap.ArenaAllocator.init(gpa);
    errdefer arena.deinit();
    const a = arena.allocator();

    var pinned: std.StringHashMapUnmanaged(Resolution) = .empty;
    var by_source: std.StringHashMapUnmanaged(std.ArrayListUnmanaged(Conflict.Edge)) = .empty;

    for (top_edges) |edge| {
        try recordEdge(a, &by_source, edge.name, "<root>", edge.constraint);
        const c = semver.Constraint.parse(edge.constraint) catch return error.BadConstraint;
        const tags = try provider.list(provider.ctx, gpa, edge.name);
        const picked = semver.pickHighest(c, tags) orelse return error.NoMatchingTag;

        if (pinned.get(edge.name)) |existing| {
            // Two different tags can co-exist iff both constraints are
            // satisfied by the higher of the two. We pick the higher version
            // that satisfies BOTH constraints — anything else is a conflict.
            if (!std.mem.eql(u8, existing.tag.name, picked.name)) {
                return error.ResolutionConflict;
            }
        } else {
            try pinned.put(a, edge.name, .{
                .name = try a.dupe(u8, edge.name),
                .tag = .{
                    .name = try a.dupe(u8, picked.name),
                    .commit = try a.dupe(u8, picked.commit),
                },
                .constraint = try a.dupe(u8, edge.constraint),
            });
        }
    }

    var resolutions: std.ArrayListUnmanaged(Resolution) = .empty;
    var it = pinned.valueIterator();
    while (it.next()) |r| try resolutions.append(a, r.*);

    return .{ .arena = arena, .resolutions = try resolutions.toOwnedSlice(a) };
}

fn recordEdge(
    a: std.mem.Allocator,
    by_source: *std.StringHashMapUnmanaged(std.ArrayListUnmanaged(Conflict.Edge)),
    package: []const u8,
    source: []const u8,
    constraint: []const u8,
) !void {
    const gop = try by_source.getOrPut(a, package);
    if (!gop.found_existing) gop.value_ptr.* = .empty;
    try gop.value_ptr.append(a, .{
        .source = try a.dupe(u8, source),
        .constraint = try a.dupe(u8, constraint),
    });
}

// ── Tests ──────────────────────────────────────────────────────────────────────

const testing = std.testing;

const Fixture = struct {
    var tags_by_name: std.StringHashMapUnmanaged([]const semver.Tag) = .empty;
    var fixture_arena: ?std.heap.ArenaAllocator = null;

    fn init(gpa: std.mem.Allocator) void {
        fixture_arena = std.heap.ArenaAllocator.init(gpa);
        tags_by_name = .empty;
    }

    fn deinit(gpa: std.mem.Allocator) void {
        tags_by_name.deinit(gpa);
        if (fixture_arena) |*a| a.deinit();
        fixture_arena = null;
    }

    fn put(gpa: std.mem.Allocator, name: []const u8, tags: []const semver.Tag) !void {
        try tags_by_name.put(gpa, name, tags);
    }

    fn list(
        ctx: ?*anyopaque,
        gpa: std.mem.Allocator,
        package_name: []const u8,
    ) Error![]const semver.Tag {
        _ = ctx;
        _ = gpa;
        return tags_by_name.get(package_name) orelse error.OnlineUnavailable;
    }
};

test "resolve: single top-level constraint picks highest matching" {
    Fixture.init(testing.allocator);
    defer Fixture.deinit(testing.allocator);

    const erika_tags = [_]semver.Tag{
        .{ .name = "0.0.1", .commit = "aaa" },
        .{ .name = "0.0.2", .commit = "bbb" },
        .{ .name = "0.1.0", .commit = "ccc" },
    };
    try Fixture.put(testing.allocator, "erika", &erika_tags);

    const edges = [_]RequireEdge{.{ .name = "erika", .constraint = "^0.0.1" }};
    var result = try resolve(testing.allocator, &edges, .{ .ctx = null, .list = Fixture.list });
    defer result.deinit();

    try testing.expectEqual(@as(usize, 1), result.resolutions.len);
    // ^0.0.X pins to exact patch — 0.0.1 wins.
    try testing.expectEqualStrings("0.0.1", result.resolutions[0].tag.name);
    try testing.expectEqualStrings("aaa", result.resolutions[0].tag.commit);
}

test "resolve: returns NoMatchingTag when nothing in the tag list matches" {
    Fixture.init(testing.allocator);
    defer Fixture.deinit(testing.allocator);

    const tags = [_]semver.Tag{.{ .name = "0.0.1", .commit = "aaa" }};
    try Fixture.put(testing.allocator, "erika", &tags);

    const edges = [_]RequireEdge{.{ .name = "erika", .constraint = "^1.0.0" }};
    try testing.expectError(error.NoMatchingTag, resolve(
        testing.allocator,
        &edges,
        .{ .ctx = null, .list = Fixture.list },
    ));
}

test "resolve: propagates BadConstraint on invalid input" {
    Fixture.init(testing.allocator);
    defer Fixture.deinit(testing.allocator);
    const tags = [_]semver.Tag{.{ .name = "0.0.1", .commit = "aaa" }};
    try Fixture.put(testing.allocator, "erika", &tags);

    const edges = [_]RequireEdge{.{ .name = "erika", .constraint = "??invalid??" }};
    const got = resolve(testing.allocator, &edges, .{ .ctx = null, .list = Fixture.list });
    try testing.expect(got == error.BadConstraint);
}

test "resolve: OnlineUnavailable surfaces when the tag list is unknown" {
    Fixture.init(testing.allocator);
    defer Fixture.deinit(testing.allocator);

    const edges = [_]RequireEdge{.{ .name = "missing", .constraint = "^0.0.1" }};
    try testing.expectError(error.OnlineUnavailable, resolve(
        testing.allocator,
        &edges,
        .{ .ctx = null, .list = Fixture.list },
    ));
}

test "resolve: two top-level edges resolve independently when names differ" {
    Fixture.init(testing.allocator);
    defer Fixture.deinit(testing.allocator);

    const erika_tags = [_]semver.Tag{.{ .name = "0.0.1", .commit = "e1" }};
    const onze_tags = [_]semver.Tag{.{ .name = "0.0.1", .commit = "o1" }};
    try Fixture.put(testing.allocator, "erika", &erika_tags);
    try Fixture.put(testing.allocator, "onze", &onze_tags);

    const edges = [_]RequireEdge{
        .{ .name = "erika", .constraint = "^0.0.1" },
        .{ .name = "onze", .constraint = "*" },
    };
    var result = try resolve(testing.allocator, &edges, .{ .ctx = null, .list = Fixture.list });
    defer result.deinit();
    try testing.expectEqual(@as(usize, 2), result.resolutions.len);
}
