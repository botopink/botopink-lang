const std = @import("std");
const SourceLocation = std.builtin.SourceLocation;
const pretty = @import("pretty.zig");
const jsonDiff = @import("json_diff.zig");

pub const SNAP_DIR = "snapshots";

/// true on Zig 0.16+, false on 0.15.x
const newIo = @hasDecl(std, "Io") and @hasDecl(std.Io, "Dir");

pub const OhSnap = struct {
    pub fn snap(_: OhSnap, location: SourceLocation, _: []const u8) Snap {
        return .{ .location = location };
    }
};

pub const Snap = struct {
    location: SourceLocation,

    pub fn expectEqual(self: Snap, args: anytype) !void {
        const allocator = std.testing.allocator;
        const got = try pretty.formatAlloc(allocator, args);
        defer allocator.free(got);

        const path = try snapFilePath(allocator, self.location);
        defer allocator.free(path);

        try compareOrCreate(allocator, path, got);
    }
};

/// File-based snapshot: reads `snapshots/{name}.botopink` as source, compares
/// result against `snapshots/{name}.snap.md` (creates it on first run).
pub fn check(allocator: std.mem.Allocator, name: []const u8, args: anytype) !void {
    const got = try pretty.formatAlloc(allocator, args);
    defer allocator.free(got);

    const snapPath = try std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}.snap.md", .{name});
    defer allocator.free(snapPath);

    try compareOrCreate(allocator, snapPath, got);
}

/// File-based snapshot for plain text (not JSON-encoded).
/// Compares `text` directly against `snapshots/{name}.snap.md`.
pub fn checkText(allocator: std.mem.Allocator, name: []const u8, text: []const u8) !void {
    const snapPath = try std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}.snap.md", .{name});
    defer allocator.free(snapPath);
    try compareOrCreate(allocator, snapPath, text);
}

/// Reads `snapshots/{name}.botopink`. Caller owns the returned slice.
pub fn readSource(allocator: std.mem.Allocator, name: []const u8) ![]u8 {
    const path = try std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}.botopink", .{name});
    defer allocator.free(path);
    return readFile(allocator, path);
}

// ── internals ─────────────────────────────────────────────────────────────────

fn compareOrCreate(allocator: std.mem.Allocator, snapPath: []const u8, got: []const u8) !void {
    const existing = readFile(allocator, snapPath) catch |err| switch (err) {
        error.FileNotFound => {
            try writeFile(snapPath, got);
            std.debug.print("snap created: {s}\n", .{snapPath});
            return;
        },
        else => return err,
    };
    defer allocator.free(existing);

    // Normalise mid-content CRLF → LF and path-separator drift on both sides
    // before compare so windows-2022 runners — which check files out with
    // `core.autocrlf` defaulting to true and report errors with `\\`-style
    // paths — produce snapshot output that matches LF-recorded baselines.
    const expected_norm = try normalizeForCompare(allocator, existing);
    defer allocator.free(expected_norm);
    const actual_norm = try normalizeForCompare(allocator, got);
    defer allocator.free(actual_norm);

    const expected = std.mem.trim(u8, expected_norm, "\n\r");
    const actual = std.mem.trim(u8, actual_norm, "\n\r");

    if (std.mem.eql(u8, expected, actual)) {
        // Delete stale .new file if it exists from a previous failed run.
        const new_path = try std.fmt.allocPrint(allocator, "{s}.new", .{snapPath});
        defer allocator.free(new_path);
        deleteFile(new_path);
        return;
    }

    // Write a .new file next to the original so the diff is easy to inspect.
    const new_path = try std.fmt.allocPrint(allocator, "{s}.new", .{snapPath});
    defer allocator.free(new_path);
    try writeFile(new_path, got);

    std.debug.print("\nsnap mismatch: {s}\n", .{snapPath});
    {
        // Only attempt JSON diff if the expected snapshot looks like JSON.
        // Guard the index: a previously-empty snapshot trims to a zero-length
        // slice, and indexing `[0]` on it would panic.
        const expected_trimmed = std.mem.trim(u8, expected, " \n\r\t");
        const looks_like_json = expected_trimmed.len > 0 and
            (expected_trimmed[0] == '[' or expected_trimmed[0] == '{');

        if (looks_like_json) {
            var aw: std.Io.Writer.Allocating = .init(allocator);
            defer aw.deinit();
            _ = jsonDiff.diff(allocator, expected, actual, &aw.writer) catch {};
            const diffOut = aw.toOwnedSlice() catch null;
            if (diffOut) |d| {
                defer allocator.free(d);
                std.debug.print("{s}\n", .{d});
            }
        }
    }
    std.debug.print("new output written to: {s}\n", .{new_path});
    return error.SnapshotMismatch;
}

// `normalizeForCompare` rewrites two host-dependent surfaces before
// `compareOrCreate` runs `std.mem.eql` on both sides:
//
//   1. CRLF → LF — windows runners check files out with `core.autocrlf`
//      defaulting to true, so the recorded `.snap.md` reads back as CRLF
//      bytes while the runtime-captured `got` stays LF. Without the
//      collapse, every snapshot drifts on windows even when the textual
//      content is byte-identical.
//   2. `\\` → `/` on lines that look like paths. Both the codegen and the
//      runtime-error sites stringify paths via the host's preferred
//      separator on windows. The heuristic is conservative: it only
//      rewrites a `\\` byte when its containing line also carries a
//      filename marker (`.bp`, `.erl`, `.js`, `.wat`, `.wasm`,
//      `.snap.md`, or one of the known src/test/snapshots/snapshots-cache
//      prefixes). Lines that legitimately embed `\\` escape sequences in
//      regex/string literals stay untouched.
//
// Applied to both `expected` (read from disk) and `actual` (just
// captured) so the comparison is robust to either side carrying CRLF or
// `\\` paths.
fn normalizeForCompare(allocator: std.mem.Allocator, raw: []const u8) ![]u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    errdefer out.deinit(allocator);
    try out.ensureTotalCapacity(allocator, raw.len);

    // Iterate per line so the path-separator heuristic can scan the
    // surrounding context without re-walking.
    var line_start: usize = 0;
    var i: usize = 0;
    while (i < raw.len) : (i += 1) {
        const c = raw[i];
        if (c == '\n' or (c == '\r' and (i + 1 == raw.len or raw[i + 1] != '\n'))) {
            // Bare LF, or bare CR (rare but possible). Treat as line break.
            const line = raw[line_start..i];
            try appendLineNormalized(allocator, &out, line);
            try out.append(allocator, '\n');
            line_start = i + 1;
        } else if (c == '\r' and i + 1 < raw.len and raw[i + 1] == '\n') {
            // CRLF — collapse to LF.
            const line = raw[line_start..i];
            try appendLineNormalized(allocator, &out, line);
            try out.append(allocator, '\n');
            i += 1;
            line_start = i + 1;
        }
    }
    if (line_start < raw.len) {
        try appendLineNormalized(allocator, &out, raw[line_start..]);
    }
    return out.toOwnedSlice(allocator);
}

fn appendLineNormalized(
    allocator: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(u8),
    line: []const u8,
) !void {
    if (lineLooksLikePath(line)) {
        for (line) |b| {
            try out.append(allocator, if (b == '\\') '/' else b);
        }
    } else {
        try out.appendSlice(allocator, line);
    }
}

fn lineLooksLikePath(line: []const u8) bool {
    // The line is a candidate for path-separator rewriting if it contains
    // both a `\\` byte AND a filename / pathname marker. Both conditions
    // together protect lines that legitimately escape characters in
    // string literals (e.g. `"\\n"`) where there is no filename context.
    var has_backslash = false;
    for (line) |b| {
        if (b == '\\') {
            has_backslash = true;
            break;
        }
    }
    if (!has_backslash) return false;

    const markers = [_][]const u8{
        ".bp",         ".erl",         ".js",          ".wat",
        ".wasm",       ".snap.md",     ".escript",     ".beam",
        "snapshots/",  "snapshots\\",  "modules/",     "modules\\",
        "src/",        "src\\",        "test-out/",    "test-out\\",
        "libs/",       "libs\\",       "repository/",  "repository\\",
    };
    inline for (markers) |m| {
        if (std.mem.indexOf(u8, line, m) != null) return true;
    }
    return false;
}

fn snapFilePath(allocator: std.mem.Allocator, loc: SourceLocation) ![]u8 {
    const safe = try allocator.dupe(u8, loc.file);
    defer allocator.free(safe);
    for (safe) |*c| {
        if (c.* == '/' or c.* == '\\' or c.* == '.') c.* = '_';
    }
    return std.fmt.allocPrint(allocator, SNAP_DIR ++ "/{s}_{d}.snap.md", .{ safe, loc.line });
}

fn readFile(allocator: std.mem.Allocator, path: []const u8) ![]u8 {
    if (newIo) {
        return std.Io.Dir.cwd().readFileAlloc(std.testing.io, path, allocator, .unlimited);
    } else {
        return std.fs.cwd().readFileAlloc(allocator, path, 10 * 1024 * 1024);
    }
}

fn writeFile(path: []const u8, content: []const u8) !void {
    // Extract the directory component of path (everything before the last slash).
    const dir_part: []const u8 = blk: {
        var i = path.len;
        while (i > 0) : (i -= 1) {
            if (path[i - 1] == '/' or path[i - 1] == '\\') break :blk path[0 .. i - 1];
        }
        break :blk "";
    };

    if (newIo) {
        const io = std.testing.io;
        const cwd = std.Io.Dir.cwd();
        if (dir_part.len > 0) {
            cwd.createDirPath(io, dir_part) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }
        try cwd.writeFile(io, .{ .sub_path = path, .data = content });
    } else {
        if (dir_part.len > 0) {
            std.fs.cwd().makePath(dir_part) catch |err| switch (err) {
                error.PathAlreadyExists => {},
                else => return err,
            };
        }
        try std.fs.cwd().writeFile(.{ .sub_path = path, .data = content });
    }
}

fn deleteFile(path: []const u8) void {
    if (newIo) {
        std.Io.Dir.cwd().deleteFile(std.testing.io, path) catch {};
    } else {
        std.fs.cwd().deleteFile(path) catch {};
    }
}
