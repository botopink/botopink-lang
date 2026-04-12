/// Erlang comptime evaluation backend.
///
/// Builds an Erlang script from typed comptime expressions, runs it via
/// `escript`, and parses the JSON array `[{id, value}, …]` printed to stdout.
const std = @import("std");
const ast = @import("../../ast.zig");
const eval = @import("../eval.zig");

// ── Script builder ────────────────────────────────────────────────────────────

fn buildScript(allocator: std.mem.Allocator, entries: []const eval.ComptimeEntry, module_name: []const u8) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    const bw = &aw.writer;

    try bw.print("-module({s}).\n", .{module_name});
    try bw.writeAll("-export([main/1]).\n\n");
    try bw.writeAll("main(_) ->\n");
    try bw.writeAll("    Values = [\n");

    for (entries, 0..) |e, i| {
        try bw.writeAll("        #{<<\"id\">> => <<\"");
        try bw.writeAll(e.id);
        try bw.writeAll("\">>, <<\"value\">> => ");
        switch (e.expr.kind) {
            .@"comptime" => |inner| {
                try writeExprErl(bw, inner.*);
            },
            .comptimeBlock => |cb| {
                for (cb.body) |stmt| {
                    switch (stmt.expr.kind) {
                        .@"break" => |y| if (y) |yp| {
                            try writeExprErl(bw, yp.*);
                            break;
                        },
                        else => {},
                    }
                } else try bw.writeAll("undefined");
            },
            else => try bw.writeAll("undefined"),
        }
        try bw.writeAll("}");
        if (i < entries.len - 1) try bw.writeAll(",");
        try bw.writeAll("\n");
    }

    try bw.writeAll("    ],\n");
    try bw.writeAll("    Json = json:encode(Values),\n");
    try bw.writeAll("    io:format(\"~s~n\", [Json]).\n");

    return aw.toOwnedSlice();
}

fn writeExprErl(bw: anytype, te: ast.TypedExpr) !void {
    switch (te.kind) {
        .numberLit => |n| try bw.writeAll(n),
        .stringLit => |s| {
            try bw.writeAll("<<\"");
            for (s) |c| switch (c) {
                '"' => try bw.writeAll("\\\""),
                '\\' => try bw.writeAll("\\\\"),
                '\n' => try bw.writeAll("\\n"),
                '\r' => try bw.writeAll("\\r"),
                '\t' => try bw.writeAll("\\t"),
                else => try bw.writeByte(c),
            };
            try bw.writeAll("\">>");
        },
        .add => |b| {
            try bw.writeByte('(');
            try writeExprErl(bw, b.lhs.*);
            try bw.writeAll(" + ");
            try writeExprErl(bw, b.rhs.*);
            try bw.writeByte(')');
        },
        .sub => |b| {
            try bw.writeByte('(');
            try writeExprErl(bw, b.lhs.*);
            try bw.writeAll(" - ");
            try writeExprErl(bw, b.rhs.*);
            try bw.writeByte(')');
        },
        .mul => |b| {
            try bw.writeByte('(');
            try writeExprErl(bw, b.lhs.*);
            try bw.writeAll(" * ");
            try writeExprErl(bw, b.rhs.*);
            try bw.writeByte(')');
        },
        .div => |b| {
            try bw.writeByte('(');
            try writeExprErl(bw, b.lhs.*);
            try bw.writeAll(" div ");
            try writeExprErl(bw, b.rhs.*);
            try bw.writeByte(')');
        },
        .mod => |b| {
            try bw.writeByte('(');
            try writeExprErl(bw, b.lhs.*);
            try bw.writeAll(" rem ");
            try writeExprErl(bw, b.rhs.*);
            try bw.writeByte(')');
        },
        .arrayLit => |arr| {
            try bw.writeByte('[');
            for (arr, 0..) |item, i| {
                if (i > 0) try bw.writeAll(", ");
                try writeExprErl(bw, item);
            }
            try bw.writeByte(']');
        },
        .@"comptime" => |e| try writeExprErl(bw, e.*),
        .@"break" => |y| if (y) |yp| try writeExprErl(bw, yp.*),
        else => try bw.writeAll("undefined"),
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
        
        // Convert JSON value to Erlang literal
        const lit = switch (val) {
            .integer => |n| try std.fmt.allocPrint(allocator, "{d}", .{n}),
            .float => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
            .bool => |b| try allocator.dupe(u8, if (b) "true" else "false"),
            .null => try allocator.dupe(u8, "undefined"),
            .string => |s| try std.fmt.allocPrint(allocator, "<<\"{s}\">>", .{s}),
            .array => |items| blk: {
                var out_buf: std.ArrayListUnmanaged(u8) = .empty;
                defer out_buf.deinit(allocator);
                try out_buf.append(allocator, '[');
                for (items.items, 0..) |elem, i| {
                    if (i > 0) try out_buf.appendSlice(allocator, ", ");
                    const elem_lit = switch (elem) {
                        .integer => |n| try std.fmt.allocPrint(allocator, "{d}", .{n}),
                        .float => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
                        .bool => |b| try allocator.dupe(u8, if (b) "true" else "false"),
                        .null => try allocator.dupe(u8, "undefined"),
                        .string => |es| try std.fmt.allocPrint(allocator, "<<\"{s}\">>", .{es}),
                        else => try allocator.dupe(u8, "undefined"),
                    };
                    try out_buf.appendSlice(allocator, elem_lit);
                }
                try out_buf.append(allocator, ']');
                break :blk out_buf.toOwnedSlice(allocator);
            },
            else => try allocator.dupe(u8, "undefined"),
        };
        try out.put(id, try lit);
    }
}

// ── Public entry point ────────────────────────────────────────────────────────

/// Evaluate `entries` using Erlang.
///
/// Writes a temporary escript to `.botopinkbuild/<module_name>.escript`,
/// runs it via `escript`, reads the output file `<module_name>.json`,
/// and returns the script source + evaluated id→value map.
pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult {
    // Build directory path: <build_root>/erlang/
    var dir_buf: [512]u8 = undefined;
    const tmp_dir = try std.fmt.bufPrint(&dir_buf, "{s}/erlang", .{build_root});
    var src_path_buf: [512]u8 = undefined;
    const src_path = try std.fmt.bufPrint(&src_path_buf, "{s}/main.erl", .{tmp_dir});

    // Clean previous build if exists, then create directory
    std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    // Build and write the Erlang module
    const src = try buildScript(allocator, entries, "main");
    errdefer allocator.free(src);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = src_path, .data = src });

    // Compile the module first
    const compile_res = try std.process.run(allocator, io, .{
        .argv = &.{ "erlc", "-o", tmp_dir, src_path },
    });
    defer allocator.free(compile_res.stderr);
    defer allocator.free(compile_res.stdout);

    // Run with erl: execute compiled module
    var eval_cmd_buf: [256]u8 = undefined;
    const eval_cmd = try std.fmt.bufPrint(&eval_cmd_buf, "main:main(ok).", .{});
    const res = try std.process.run(allocator, io, .{
        .argv = &.{ "erl", "-noshell", "-pa", tmp_dir, "-eval", eval_cmd, "-s", "init", "stop" },
    });
    defer allocator.free(res.stderr);
    defer allocator.free(res.stdout);

    // Parse results from stdout
    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer values.deinit();

    try parseResults(allocator, res.stdout, &values);
    return .{ .script = src, .values = values };
}
