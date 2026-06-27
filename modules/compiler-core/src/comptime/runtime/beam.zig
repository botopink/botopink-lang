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
    try bw.print("main() -> io:format(\"~s\", [\"{s}\"]).\n", .{erl_str.items});

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
    // io:format wraps in quotes. Strip the outer Erlang string quoting.
    var stripped = data;
    // Erlang io:format("~s", ["..."]) outputs the string without extra wrapping
    // but trailed by "ok". Actually io:format returns ok, so the output
    // is just the formatted string followed by newline.
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

/// Evaluate `entries` via Erlang/OTP (`erlc` + `erl`).
///
/// Generates an Erlang source module, compiles it via `erlc`, runs it via
/// `erl -noshell -run <module> main -run init stop`, captures stdout, and
/// parses the captured JSON.
pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult {
    // Compute a stable hash from the entries for the module/file name.
    // Use the entries IDs as input so the hash is deterministic across runs.
    var hash_input: std.ArrayListUnmanaged(u8) = .empty;
    defer hash_input.deinit(allocator);
    for (entries) |e| {
        try hash_input.appendSlice(allocator, e.id);
    }
    const hash = std.hash.Wyhash.hash(0, hash_input.items);
    const mod_name = try std.fmt.allocPrint(allocator, "comptime_{x}", .{hash});
    defer allocator.free(mod_name);

    const src = try buildScript(allocator, entries, mod_name);
    errdefer allocator.free(src);

    const erl_filename = try std.fmt.allocPrint(allocator, "{s}.erl", .{mod_name});
    defer allocator.free(erl_filename);

    const tmp_dir_base = try std.fs.path.join(allocator, &.{ build_root, ".botopinkbuild", "tmp" });
    defer allocator.free(tmp_dir_base);
    const tmp_dir = try std.fmt.allocPrint(allocator, "{s}/{x}", .{ tmp_dir_base, hash });
    defer allocator.free(tmp_dir);
    try std.Io.Dir.cwd().createDirPath(io, tmp_dir);

    const erl_path = try std.fs.path.join(allocator, &.{ tmp_dir, erl_filename });
    defer allocator.free(erl_path);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = erl_path, .data = src });

    // Compile with erlc.
    const compile_result = std.process.run(allocator, io, .{
        .argv = &.{ "erlc", "-o", tmp_dir, erl_path },
    }) catch |err| switch (err) {
        error.FileNotFound => return error.AtomvmExecuteFailed,
        else => return err,
    };
    defer allocator.free(compile_result.stdout);
    defer allocator.free(compile_result.stderr);
    if (compile_result.term != .exited or compile_result.term.exited != 0) {
        return error.AtomvmModuleLoadFailed;
    }

    // Run with erl.
    const beam_path = try std.fs.path.join(allocator, &.{ tmp_dir, mod_name });
    defer allocator.free(beam_path);
    // erl -noshell -run <module> main -run init stop
    const run_result = std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noshell", "-pa", tmp_dir, "-run", mod_name, "main", "-run", "init", "stop" },
    }) catch |err| switch (err) {
        error.FileNotFound => return error.AtomvmExecuteFailed,
        else => return err,
    };
    defer allocator.free(run_result.stdout);
    defer allocator.free(run_result.stderr);

    const stdout = try allocator.dupe(u8, run_result.stdout);
    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer values.deinit();

    try parseResults(allocator, stdout, &values);
    return .{ .script = src, .values = values };
}
