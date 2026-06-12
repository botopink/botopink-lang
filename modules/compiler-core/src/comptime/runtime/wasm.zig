/// WebAssembly comptime evaluation backend.
///
/// Builds a WAT module from typed comptime expressions, runs it via
/// `wasmtime`, and parses the JSON array printed to stdout.
const std = @import("std");
const ast = @import("../../ast.zig");
const eval = @import("../eval.zig");

// ── Script builder ────────────────────────────────────────────────────────────

fn buildScript(allocator: std.mem.Allocator, entries: []const eval.ComptimeEntry) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    const bw = &aw.writer;

    // Collect string data for results
    var data_buf: std.ArrayListUnmanaged(u8) = .empty;
    defer data_buf.deinit(allocator);

    // Pre-render each entry value as a string
    var rendered: std.ArrayListUnmanaged([]const u8) = .empty;
    defer {
        for (rendered.items) |s| allocator.free(s);
        rendered.deinit(allocator);
    }

    for (entries) |e| {
        const val_str = try renderExprValue(allocator, e.expr);
        try rendered.append(allocator, val_str);
    }

    // Build JSON output: [{"id":"ct_0","value":...}, ...]
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
    const data_offset: u32 = 0;
    const data_len: u32 = @intCast(json_str.len);

    // Emit WAT module with WASI fd_write
    try bw.writeAll("(module\n");
    try bw.writeAll("  (import \"wasi_snapshot_preview1\" \"fd_write\"\n");
    try bw.writeAll("    (func $fd_write (param i32 i32 i32 i32) (result i32)))\n");
    try bw.writeAll("  (memory (export \"memory\") 1)\n");

    // Data section with our JSON string
    try bw.writeAll("  (data (i32.const 8) \"");
    for (json_str) |c| {
        switch (c) {
            '"' => try bw.writeAll("\\\""),
            '\\' => try bw.writeAll("\\\\"),
            '\n' => try bw.writeAll("\\n"),
            '\t' => try bw.writeAll("\\t"),
            else => try bw.writeByte(c),
        }
    }
    try bw.writeAll("\")\n");

    // iov at offset 0: [ptr=8, len=data_len]
    try bw.writeAll("  (func $main (export \"_start\")\n");
    try bw.print("    (i32.store (i32.const 0) (i32.const 8))\n", .{});
    try bw.print("    (i32.store (i32.const 4) (i32.const {d}))\n", .{data_len});
    // fd_write(fd=1, iovs=0, iovs_len=1, nwritten=200)
    try bw.print("    (drop (call $fd_write (i32.const 1) (i32.const {d}) (i32.const 1) (i32.const 200))))\n", .{data_offset});
    try bw.writeAll(")\n");

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
                            .@"break" => |y| if (y) |yp| return renderExprValue(allocator, yp.*),
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
            // Desugared to a `+` chain during inference; never reaches eval.
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
            .@"break" => |y| if (y) |yp| return renderExprValue(allocator, yp.*),
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
    const parsed = try std.json.parseFromSlice(std.json.Value, allocator, data, .{});
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
                for (items.items, 0..) |elem, i| {
                    if (i > 0) try buf.appendSlice(allocator, ", ");
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

/// Evaluate `entries` using wasmtime.
///
/// Writes a temporary WAT file to `<build_root>/wasm/main.wat`,
/// runs it via `wasmtime`, reads stdout as JSON,
/// and returns the script source + evaluated id→value map.
pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult {
    var dir_buf: [512]u8 = undefined;
    const tmp_dir = try std.fmt.bufPrint(&dir_buf, "{s}/wasm", .{build_root});
    var src_path_buf: [512]u8 = undefined;
    const src_path = try std.fmt.bufPrint(&src_path_buf, "{s}/main.wat", .{tmp_dir});

    std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    const src = try buildScript(allocator, entries);
    errdefer allocator.free(src);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = src_path, .data = src });

    const res = try std.process.run(allocator, io, .{ .argv = &.{ "wasmtime", src_path } });
    defer allocator.free(res.stderr);
    defer allocator.free(res.stdout);

    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer values.deinit();

    try parseResults(allocator, res.stdout, &values);
    return .{ .script = src, .values = values };
}
