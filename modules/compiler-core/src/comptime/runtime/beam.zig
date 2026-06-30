/// AtomVM/BEAM comptime evaluation backend — the BEAM counterpart to `wasm.zig`.
///
/// Builds an Erlang source module from typed comptime expressions, compiles
/// it via `erlc` to BEAM bytecode, executes it via `erl`, captures stdout,
/// and parses the JSON output.
///
/// Currently uses `erl` (full Erlang/OTP VM) for execution via subprocess.
const std = @import("std");
const ast = @import("../../ast.zig");
const eval = @import("../eval.zig");

// ── Script builder ────────────────────────────────────────────────────────────

/// Build an Erlang source module as text. The module's `main/0` function
/// writes a JSON array of `[{"id":"ct_0","value":...}, ...]` to stdout
/// via `io:format("~s", [Json])` and returns `ok`.
/// `mod_name` is the Erlang module name (must match the filename).
pub fn buildScript(allocator: std.mem.Allocator, entries: []const eval.ComptimeEntry, mod_name: []const u8) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    const bw = &aw.writer;

    var rendered: std.ArrayListUnmanaged([]const u8) = .empty;
    defer {
        for (rendered.items) |s| allocator.free(s);
        rendered.deinit(allocator);
    }

    for (entries) |e| {
        const val_str = try renderExprValue(allocator, e.expr);
        try rendered.append(allocator, val_str);
    }

    var json_buf: std.ArrayListUnmanaged(u8) = .empty;
    defer json_buf.deinit(allocator);
    try json_buf.append(allocator, '[');
    for (entries, 0..) |e, i| {
        if (i > 0) try json_buf.append(allocator, ',');
        try json_buf.appendSlice(allocator, "{\"id\":\"");
        try json_buf.appendSlice(allocator, e.id);
        try json_buf.appendSlice(allocator, "\",\"value\":");
        try json_buf.appendSlice(allocator, rendered.items[i]);
        try json_buf.append(allocator, '}');
    }
    try json_buf.append(allocator, ']');

    const json_str = json_buf.items;

    // Escape JSON for Erlang string (escape \ and ")
    var erl_str: std.ArrayListUnmanaged(u8) = .empty;
    defer erl_str.deinit(allocator);
    for (json_str) |c| {
        switch (c) {
            '\\' => try erl_str.appendSlice(allocator, "\\\\"),
            '"' => try erl_str.appendSlice(allocator, "\\\""),
            '\n' => try erl_str.appendSlice(allocator, "\\n"),
            else => try erl_str.append(allocator, c),
        }
    }

    try bw.print("-module({s}).\n", .{mod_name});
    try bw.print("-export([main/0]).\n", .{});
    try bw.print("main() -> \"{s}\".\n", .{erl_str.items});

    return aw.toOwnedSlice();
}

fn renderExprValue(allocator: std.mem.Allocator, te: ast.TypedExpr) ![]const u8 {
    switch (te) {
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| return renderExprValue(allocator, inner.*),
            .comptimeBlock => |cb| {
                for (cb.body) |stmt| {
                    switch (stmt.expr) {
                        .jump => |j| switch (j.kind) {
                            .@"break" => |y| if (y.value) |yp| return renderExprValue(allocator, yp.*),
                            else => {},
                        },
                        else => {},
                    }
                }
                return allocator.dupe(u8, "null");
            },
            else => return allocator.dupe(u8, "null"),
        },
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| return allocator.dupe(u8, n),
            .stringLit => |s| {
                var buf: std.ArrayListUnmanaged(u8) = .empty;
                defer buf.deinit(allocator);
                try buf.append(allocator, '"');
                for (s) |c| switch (c) {
                    '"' => try buf.appendSlice(allocator, "\\\""),
                    '\\' => try buf.appendSlice(allocator, "\\\\"),
                    '\n' => try buf.appendSlice(allocator, "\\n"),
                    else => try buf.append(allocator, c),
                };
                try buf.append(allocator, '"');
                return buf.toOwnedSlice(allocator);
            },
            .null_ => return allocator.dupe(u8, "null"),
            .comment => return allocator.dupe(u8, "null"),
            .stringTemplate => unreachable,
        },
        .binaryOp => |b| {
            const lhs = try evalConstInt(b.lhs.*);
            const rhs = try evalConstInt(b.rhs.*);
            const result: i64 = switch (b.op) {
                .add => lhs + rhs,
                .sub => lhs - rhs,
                .mul => lhs * rhs,
                .div => if (rhs != 0) @divTrunc(lhs, rhs) else 0,
                .mod => if (rhs != 0) @mod(lhs, rhs) else 0,
                else => 0,
            };
            return std.fmt.allocPrint(allocator, "{d}", .{result});
        },
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                var buf: std.ArrayListUnmanaged(u8) = .empty;
                defer buf.deinit(allocator);
                try buf.append(allocator, '[');
                for (al.elems, 0..) |item, i| {
                    if (i > 0) try buf.appendSlice(allocator, ",");
                    const elem_str = try renderExprValue(allocator, item);
                    defer allocator.free(elem_str);
                    try buf.appendSlice(allocator, elem_str);
                }
                try buf.append(allocator, ']');
                return buf.toOwnedSlice(allocator);
            },
            else => return allocator.dupe(u8, "null"),
        },
        .jump => |j| switch (j.kind) {
            .@"break" => |y| if (y.value) |yp| return renderExprValue(allocator, yp.*),
            else => {},
        },
        else => {},
    }
    return allocator.dupe(u8, "null");
}

fn evalConstInt(te: ast.TypedExpr) !i64 {
    switch (te) {
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| return std.fmt.parseInt(i64, n, 10) catch 0,
            else => return 0,
        },
        .binaryOp => |b| {
            const lhs = try evalConstInt(b.lhs.*);
            const rhs = try evalConstInt(b.rhs.*);
            return switch (b.op) {
                .add => lhs + rhs,
                .sub => lhs - rhs,
                .mul => lhs * rhs,
                .div => if (rhs != 0) @divTrunc(lhs, rhs) else 0,
                .mod => if (rhs != 0) @mod(lhs, rhs) else 0,
                else => 0,
            };
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |inner| return evalConstInt(inner.*),
            else => return 0,
        },
        else => return 0,
    }
}

// ── Result parser ─────────────────────────────────────────────────────────────

fn parseResults(
    allocator: std.mem.Allocator,
    data: []const u8,
    out: *std.StringHashMap([]const u8),
) !void {
    // The persistent erl server returns the module's main/0 result formatted
    // with io:format("~s~n", [Result]). Strip the trailing newline.
    var stripped = data;
    if (stripped.len > 0 and stripped[stripped.len - 1] == '\n') stripped = stripped[0 .. stripped.len - 1];

    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, stripped, .{});
    defer parsed.deinit();

    const arr = switch (parsed.value) {
        .array => |a| a,
        else => return,
    };
    for (arr.items) |item| {
        const obj = switch (item) {
            .object => |o| o,
            else => continue,
        };
        const id_val = obj.get("id") orelse continue;
        const id = switch (id_val) {
            .string => |s| s,
            else => continue,
        };
        const val = obj.get("value") orelse continue;

        const lit = switch (val) {
            .integer => |n| try std.fmt.allocPrint(allocator, "{d}", .{n}),
            .float => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
            .bool => |b| try allocator.dupe(u8, if (b) "true" else "false"),
            .null => try allocator.dupe(u8, "null"),
            .string => |s| blk: {
                var buf: std.ArrayListUnmanaged(u8) = .empty;
                defer buf.deinit(allocator);
                try buf.append(allocator, '"');
                for (s) |c| switch (c) {
                    '"' => try buf.appendSlice(allocator, "\\\""),
                    '\\' => try buf.appendSlice(allocator, "\\\\"),
                    '\n' => try buf.appendSlice(allocator, "\\n"),
                    else => try buf.append(allocator, c),
                };
                try buf.append(allocator, '"');
                break :blk buf.toOwnedSlice(allocator);
            },
            .array => |items| blk: {
                var buf: std.ArrayListUnmanaged(u8) = .empty;
                defer buf.deinit(allocator);
                try buf.append(allocator, '[');
                for (items.items, 0..) |elem, j| {
                    if (j > 0) try buf.appendSlice(allocator, ", ");
                    const elem_str = switch (elem) {
                        .integer => |n| try std.fmt.allocPrint(allocator, "{d}", .{n}),
                        .float => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
                        .bool => |b| try allocator.dupe(u8, if (b) "true" else "false"),
                        .null => try allocator.dupe(u8, "null"),
                        .string => |es| blk2: {
                            var sbuf: std.ArrayListUnmanaged(u8) = .empty;
                            defer sbuf.deinit(allocator);
                            try sbuf.append(allocator, '"');
                            for (es) |c| switch (c) {
                                '"' => try sbuf.appendSlice(allocator, "\\\""),
                                '\\' => try sbuf.appendSlice(allocator, "\\\\"),
                                else => try sbuf.append(allocator, c),
                            };
                            try sbuf.append(allocator, '"');
                            break :blk2 sbuf.toOwnedSlice(allocator);
                        },
                        else => try allocator.dupe(u8, "null"),
                    };
                    const elem_str_owned = try elem_str;
                    try buf.appendSlice(allocator, elem_str_owned);
                    allocator.free(elem_str_owned);
                }
                try buf.append(allocator, ']');
                break :blk buf.toOwnedSlice(allocator);
            },
            else => try allocator.dupe(u8, "null"),
        };
        try out.put(id, try lit);
    }
}

// ── Public entry point ────────────────────────────────────────────────────────

/// Evaluate `entries` via the persistent erl subprocess.
///
/// Generates an Erlang source module, writes it to a tmp file, and delegates
/// compilation + execution to the persistent erl process. Returns a `RunResult`
/// with the generated script and evaluated values.
pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult {
    const persistent_erl = @import("./persistent_erl.zig");

    // Compute a stable hash from the entries for the module/file name.
    var hash_input: std.ArrayListUnmanaged(u8) = .empty;
    defer hash_input.deinit(allocator);
    for (entries) |e| {
        try hash_input.appendSlice(allocator, e.id);
    }
    const hash = std.hash.Wyhash.hash(0, hash_input.items);
    const mod_name = try std.fmt.allocPrint(allocator, "comptime_{x}", .{hash});
    defer allocator.free(mod_name);

    const tmp_dir_base = try std.fs.path.join(allocator, &.{ build_root, ".botopinkbuild", "tmp" });
    defer allocator.free(tmp_dir_base);
    const tmp_dir = try std.fmt.allocPrint(allocator, "{s}/{x}", .{ tmp_dir_base, hash });
    defer allocator.free(tmp_dir);
    try std.Io.Dir.cwd().createDirPath(io, tmp_dir);

    // BEAM bytecode cache: check for a pre-compiled .beam file.
    const cache_dir = try std.fs.path.join(allocator, &.{ build_root, ".botopinkbuild", "tmp", "beam_cache" });
    defer allocator.free(cache_dir);
    const cache_beam = try std.fmt.allocPrint(allocator, "{s}/{s}.beam", .{ cache_dir, mod_name });
    defer allocator.free(cache_beam);

    // Try cache hit: if a cached BEAM exists, copy to tmp dir and load directly.
    var cache_buf: [65536]u8 = undefined;
    const cache_hit = std.Io.Dir.cwd().readFile(io, cache_beam, &cache_buf) catch null;
    if (cache_hit) |cached_bytes_slice| {
        const cached_bytes = try allocator.dupe(u8, cached_bytes_slice);
        defer allocator.free(cached_bytes);
        const beam_path = try std.fs.path.join(allocator, &.{ tmp_dir, mod_name });
        defer allocator.free(beam_path);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = beam_path, .data = cached_bytes });

        if (persistent_erl.loadBeam(allocator, io, beam_path)) |stdout| {
            defer allocator.free(stdout);
            var values = std.StringHashMap([]const u8).init(allocator);
            errdefer values.deinit();
            try parseResults(allocator, stdout, &values);
            const script = try allocator.dupe(u8, "(cached)");
            return .{ .script = script, .values = values };
        } else |_| {
            // Load failed — remove stale cache and fall through.
            std.Io.Dir.cwd().deleteFile(io, cache_beam) catch {};
        }
    }

    return runUncached(allocator, io, entries, build_root, mod_name, tmp_dir, cache_dir, cache_beam);
}

fn runUncached(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
    mod_name: []const u8,
    tmp_dir: []const u8,
    cache_dir: []const u8,
    cache_beam: []const u8,
) !eval.RunResult {
    _ = build_root;
    const persistent_erl = @import("./persistent_erl.zig");

    const src = try buildScript(allocator, entries, mod_name);
    errdefer allocator.free(src);

    const erl_filename = try std.fmt.allocPrint(allocator, "{s}.erl", .{mod_name});
    defer allocator.free(erl_filename);

    const erl_path = try std.fs.path.join(allocator, &.{ tmp_dir, erl_filename });
    defer allocator.free(erl_path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_path, .data = src });

    // Delegate to persistent erl: compile + execute in one round-trip.
    const stdout = try persistent_erl.eval(allocator, io, erl_path);
    errdefer allocator.free(stdout);

    // Cache the compiled BEAM for future runs.
    // The BEAM file was written to tmp_dir by erlc (compile:file).
    const beam_path = try std.fmt.allocPrint(allocator, "{s}/{s}.beam", .{ tmp_dir, mod_name });
    defer allocator.free(beam_path);
    var cache_read_buf: [65536]u8 = undefined;
    const beam_result = std.Io.Dir.cwd().readFile(io, beam_path, &cache_read_buf) catch null;
    if (beam_result) |beam_bytes_slice| {
        const beam_bytes = try allocator.dupe(u8, beam_bytes_slice);
        defer allocator.free(beam_bytes);
        try std.Io.Dir.cwd().createDirPath(io, cache_dir);
        try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = cache_beam, .data = beam_bytes });
    }

    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer values.deinit();

    try parseResults(allocator, stdout, &values);
    return .{ .script = src, .values = values };
}
