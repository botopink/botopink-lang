/// SemVer subset bpmp implements — minimal but enough to drive the v0.beta.18
/// ecosystem (plan §D6).
///
/// ```text
/// constraint := "*"
///             | exact_version            // "0.1.0"   exactly 0.1.0
///             | "^" version              // "^0.1.0"  >=0.1.0, <0.2.0   (0.x: minor bumps)
///             | "~" version              // "~0.1.0"  >=0.1.0, <0.2.0
///             | ">=" version             // ">=0.1.0" at least 0.1.0
///             | "feat"                   // literal moving tag <version>-feat
///             | "latest"                 // highest non-prerelease tag
/// ```
///
/// `Version` carries `{major, minor, patch, prerelease?}`. Prerelease parsing is
/// kept dumb: anything after the first `-` is preserved as an opaque slice and
/// used only for ordering (a prerelease is always **less** than the same
/// non-prerelease version, per SemVer 2.0.0). The framework lib repos use
/// `<x.y.z>-feat` as their pre-release marker; that one suffix is the only
/// shape that matters for v0.beta.18.
///
/// No backtracking solver lives here — `resolver.zig` calls `matchConstraint`
/// over a tag list and picks the highest match (or fails loudly on conflict).
const std = @import("std");

// ── Version ─────────────────────────────────────────────────────────────────────

pub const Version = struct {
    major: u32,
    minor: u32,
    patch: u32,
    /// Slice into the original buffer (or `&.{}` for none) — `<major>.<minor>.
    /// <patch>-<prerelease>`. `feat` is the canonical pre-release for lib repos.
    prerelease: []const u8 = &.{},

    pub const ParseError = error{InvalidVersion};

    /// Parse a version string. Accepts a leading `v` (`v0.0.1` → `0.0.1`) and
    /// an optional `-<prerelease>` tail (kept as an opaque slice). Refuses
    /// missing fields, non-numeric components, or trailing garbage.
    pub fn parse(s: []const u8) ParseError!Version {
        var rest = s;
        if (rest.len > 0 and (rest[0] == 'v' or rest[0] == 'V')) rest = rest[1..];

        var pre: []const u8 = &.{};
        if (std.mem.indexOfScalar(u8, rest, '-')) |dash| {
            pre = rest[dash + 1 ..];
            rest = rest[0..dash];
        }
        // Build metadata (`+…`) is unused; drop it if present so it doesn't
        // confuse the prerelease slot.
        if (std.mem.indexOfScalar(u8, pre, '+')) |plus| pre = pre[0..plus];
        if (std.mem.indexOfScalar(u8, rest, '+')) |plus| rest = rest[0..plus];

        var it = std.mem.splitScalar(u8, rest, '.');
        const major_s = it.next() orelse return error.InvalidVersion;
        const minor_s = it.next() orelse return error.InvalidVersion;
        const patch_s = it.next() orelse return error.InvalidVersion;
        if (it.next() != null) return error.InvalidVersion;
        return .{
            .major = std.fmt.parseInt(u32, major_s, 10) catch return error.InvalidVersion,
            .minor = std.fmt.parseInt(u32, minor_s, 10) catch return error.InvalidVersion,
            .patch = std.fmt.parseInt(u32, patch_s, 10) catch return error.InvalidVersion,
            .prerelease = pre,
        };
    }

    /// SemVer 2.0.0 ordering: same triple, a prerelease loses to the
    /// non-prerelease. Within prereleases the comparison is dumb-lexicographic
    /// (good enough for `<ver>-feat` vs `<ver>-rc.1`).
    pub fn order(a: Version, b: Version) std.math.Order {
        if (a.major != b.major) return std.math.order(a.major, b.major);
        if (a.minor != b.minor) return std.math.order(a.minor, b.minor);
        if (a.patch != b.patch) return std.math.order(a.patch, b.patch);
        if (a.prerelease.len == 0 and b.prerelease.len > 0) return .gt;
        if (a.prerelease.len > 0 and b.prerelease.len == 0) return .lt;
        return std.mem.order(u8, a.prerelease, b.prerelease);
    }

    pub fn isPrerelease(v: Version) bool {
        return v.prerelease.len > 0;
    }

    pub fn format(self: Version, writer: anytype) !void {
        try writer.print("{d}.{d}.{d}", .{ self.major, self.minor, self.patch });
        if (self.prerelease.len > 0) try writer.print("-{s}", .{self.prerelease});
    }
};

// ── Constraint ──────────────────────────────────────────────────────────────────

pub const Constraint = union(enum) {
    any,
    exact: Version,
    caret: Version,
    tilde: Version,
    gte: Version,
    /// Literal `<version>-feat` lookup. `bpmp install <name>@feat` reaches for
    /// the moving feat tag the lib-test-workflows produce.
    feat,
    /// Highest non-prerelease tag — the implicit default when nothing pins.
    latest,

    pub const ParseError = error{InvalidConstraint} || Version.ParseError;

    pub fn parse(s: []const u8) ParseError!Constraint {
        const trimmed = std.mem.trim(u8, s, " \t");
        if (trimmed.len == 0) return error.InvalidConstraint;
        if (std.mem.eql(u8, trimmed, "*")) return .any;
        if (std.mem.eql(u8, trimmed, "latest")) return .latest;
        if (std.mem.eql(u8, trimmed, "feat")) return .feat;

        if (std.mem.startsWith(u8, trimmed, "^")) {
            return .{ .caret = try Version.parse(trimmed[1..]) };
        }
        if (std.mem.startsWith(u8, trimmed, "~")) {
            return .{ .tilde = try Version.parse(trimmed[1..]) };
        }
        if (std.mem.startsWith(u8, trimmed, ">=")) {
            return .{ .gte = try Version.parse(trimmed[2..]) };
        }
        // Fall through to exact (`0.1.0`, `v0.1.0`).
        return .{ .exact = try Version.parse(trimmed) };
    }

    /// True iff `v` satisfies `self`. Pre-releases never satisfy a range
    /// constraint unless the constraint itself names a prerelease — matches
    /// Cargo / npm. `feat` is purely literal (handled by the resolver against
    /// the raw tag string, not here).
    pub fn matches(self: Constraint, v: Version) bool {
        return switch (self) {
            .any => true,
            .latest => !v.isPrerelease(),
            .feat => false, // dispatched by the resolver against the raw tag
            .exact => |req| v.order(req) == .eq,
            .gte => |req| v.order(req) != .lt and
                (req.isPrerelease() or !v.isPrerelease()),
            .caret => |req| caret(req, v),
            .tilde => |req| tilde(req, v),
        };
    }
};

/// `^X.Y.Z` accepts any `>= X.Y.Z` while keeping the **leftmost non-zero**
/// component fixed. For `^0.1.2` that is the minor (→ `<0.2.0`); for `^1.2.3`
/// that is the major (→ `<2.0.0`). For `^0.0.X` it pins to that exact patch.
fn caret(req: Version, v: Version) bool {
    if (v.order(req) == .lt) return false;
    // Pre-releases never satisfy a non-prerelease caret (npm parity).
    if (v.isPrerelease() and !req.isPrerelease()) return false;
    if (req.major > 0) return v.major == req.major;
    if (req.minor > 0) return v.major == 0 and v.minor == req.minor;
    // ^0.0.X — only exact 0.0.X.
    return v.major == 0 and v.minor == 0 and v.patch == req.patch;
}

/// `~X.Y.Z` accepts `>= X.Y.Z, < X.(Y+1).0`. Like caret, prereleases lose to
/// a non-prerelease constraint.
fn tilde(req: Version, v: Version) bool {
    if (v.order(req) == .lt) return false;
    if (v.isPrerelease() and !req.isPrerelease()) return false;
    return v.major == req.major and v.minor == req.minor;
}

// ── Resolving a tag list ────────────────────────────────────────────────────────

/// One entry in a repo's GitHub tag list — caller-owned slices.
pub const Tag = struct {
    name: []const u8,
    commit: []const u8,
};

/// Pick the highest tag in `tags` satisfying `constraint`. The `feat`
/// constraint matches only a literal `<…>-feat` tag (the moving lib tag).
/// Returns `null` when no tag matches; the caller renders the conflict /
/// "not-found" report.
pub fn pickHighest(
    constraint: Constraint,
    tags: []const Tag,
) ?Tag {
    var best: ?struct { tag: Tag, version: Version } = null;
    for (tags) |tag| {
        if (constraint == .feat) {
            // Literal moving-tag lookup — pick the first that ends in `-feat`.
            if (std.mem.endsWith(u8, tag.name, "-feat")) return tag;
            continue;
        }
        const version = Version.parse(tag.name) catch continue;
        if (!constraint.matches(version)) continue;
        if (best == null or best.?.version.order(version) == .lt) {
            best = .{ .tag = tag, .version = version };
        }
    }
    return if (best) |b| b.tag else null;
}

// ── Tests ───────────────────────────────────────────────────────────────────────

const testing = std.testing;

test "Version.parse accepts plain and v-prefixed" {
    const a = try Version.parse("0.1.2");
    try testing.expectEqual(@as(u32, 0), a.major);
    try testing.expectEqual(@as(u32, 1), a.minor);
    try testing.expectEqual(@as(u32, 2), a.patch);

    const b = try Version.parse("v1.2.3");
    try testing.expectEqual(@as(u32, 1), b.major);
}

test "Version.parse captures prerelease" {
    const v = try Version.parse("0.0.1-feat");
    try testing.expectEqualStrings("feat", v.prerelease);
}

test "Version.parse rejects malformed" {
    try testing.expectError(error.InvalidVersion, Version.parse("0.1"));
    try testing.expectError(error.InvalidVersion, Version.parse("a.b.c"));
    try testing.expectError(error.InvalidVersion, Version.parse("0.1.2.3"));
}

test "Version.order: prerelease loses to non-prerelease" {
    const stable = try Version.parse("0.0.1");
    const pre = try Version.parse("0.0.1-feat");
    try testing.expectEqual(std.math.Order.gt, stable.order(pre));
    try testing.expectEqual(std.math.Order.lt, pre.order(stable));
}

test "Constraint.parse: caret / tilde / exact / >= / *" {
    try testing.expect((try Constraint.parse("*")) == .any);
    switch (try Constraint.parse("0.1.2")) {
        .exact => |v| try testing.expectEqual(@as(u32, 2), v.patch),
        else => return error.WrongVariant,
    }
    switch (try Constraint.parse("^0.1.0")) {
        .caret => {},
        else => return error.WrongVariant,
    }
    switch (try Constraint.parse("~0.1.0")) {
        .tilde => {},
        else => return error.WrongVariant,
    }
    switch (try Constraint.parse(">=0.1.0")) {
        .gte => {},
        else => return error.WrongVariant,
    }
}

test "Constraint.parse: feat / latest aliases" {
    try testing.expect((try Constraint.parse("feat")) == .feat);
    try testing.expect((try Constraint.parse("latest")) == .latest);
}

test "Constraint.matches: ^0.1.0 accepts 0.1.x, rejects 0.2.0" {
    const c = try Constraint.parse("^0.1.0");
    try testing.expect(c.matches(try Version.parse("0.1.0")));
    try testing.expect(c.matches(try Version.parse("0.1.5")));
    try testing.expect(!c.matches(try Version.parse("0.2.0")));
    try testing.expect(!c.matches(try Version.parse("0.0.9")));
}

test "Constraint.matches: ^1.2.0 accepts 1.x, rejects 2.0" {
    const c = try Constraint.parse("^1.2.0");
    try testing.expect(c.matches(try Version.parse("1.2.0")));
    try testing.expect(c.matches(try Version.parse("1.3.0")));
    try testing.expect(!c.matches(try Version.parse("2.0.0")));
}

test "Constraint.matches: ~0.1.0 accepts 0.1.x, rejects 0.2.0" {
    const c = try Constraint.parse("~0.1.0");
    try testing.expect(c.matches(try Version.parse("0.1.5")));
    try testing.expect(!c.matches(try Version.parse("0.2.0")));
}

test "Constraint.matches: latest excludes pre-releases" {
    const c = try Constraint.parse("latest");
    try testing.expect(c.matches(try Version.parse("1.2.3")));
    try testing.expect(!c.matches(try Version.parse("1.2.3-feat")));
}

test "pickHighest: highest matching stable wins over pre-release" {
    const tags = [_]Tag{
        .{ .name = "0.0.1-feat", .commit = "aaaa" },
        .{ .name = "0.0.1", .commit = "bbbb" },
        .{ .name = "0.0.2", .commit = "cccc" },
    };
    const c = try Constraint.parse("^0.0.1");
    const picked = pickHighest(c, &tags) orelse return error.NoMatch;
    // ^0.0.1 pins to exact patch — 0.0.1 wins (highest *matching*, not just
    // highest overall).
    try testing.expectEqualStrings("0.0.1", picked.name);
}

test "pickHighest: feat picks the literal -feat tag" {
    const tags = [_]Tag{
        .{ .name = "0.0.1", .commit = "bbbb" },
        .{ .name = "0.0.1-feat", .commit = "aaaa" },
    };
    const picked = pickHighest(.feat, &tags) orelse return error.NoMatch;
    try testing.expectEqualStrings("0.0.1-feat", picked.name);
}

test "pickHighest: returns null when nothing matches" {
    const tags = [_]Tag{.{ .name = "0.0.1", .commit = "bbbb" }};
    const c = try Constraint.parse("^1.0.0");
    try testing.expect(pickHighest(c, &tags) == null);
}
