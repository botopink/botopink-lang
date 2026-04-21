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
        switch (e.expr) {
            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |inner| try writeExprErl(bw, allocator, inner.*),
                .comptimeBlock => |cb| {
                    for (cb.body) |stmt| {
                        switch (stmt.expr) {
                            .controlFlow => |cf| switch (cf.kind) {
                                .@"break" => |y| if (y) |yp| {
                                    try writeExprErl(bw, allocator, yp.*);
                                    break;
                                },
                                else => {},
                            },
                            else => {},
                        }
                    } else try bw.writeAll("undefined");
                },
                else => try bw.writeAll("undefined"),
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

/// Returns true when the expression is a string literal or string-typed operation.
fn isStringExpr(te: ast.TypedExpr) bool {
    return switch (te) {
        .literal => |lit| lit.kind == .stringLit,
        .binaryOp => |b| switch (b.kind) {
            .add => |op| isStringExpr(op.lhs.*) or isStringExpr(op.rhs.*),
            else => false,
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |e| isStringExpr(e.*),
            else => false,
        },
        else => false,
    };
}

fn writeExprErl(bw: anytype, allocator: std.mem.Allocator, te: ast.TypedExpr) !void {
    switch (te) {
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| try bw.writeAll(n),
            .stringLit => |s| {
                try bw.writeByte('"');
                for (s) |c| switch (c) {
                    '"' => try bw.writeAll("\\\""),
                    '\\' => try bw.writeAll("\\\\"),
                    '\n' => try bw.writeAll("\\n"),
                    '\r' => try bw.writeAll("\\r"),
                    '\t' => try bw.writeAll("\\t"),
                    else => try bw.writeByte(c),
                };
                try bw.writeByte('"');
            },
            .comment => |c| {
                const prefix: []const u8 = switch (c.kind) {
                    .normal => "%",
                    .doc => "%%",
                    .module => "%%%",
                };
                try bw.writeAll(prefix);
                try bw.writeAll(" ");
                try bw.writeAll(c.text);
            },
            .null_ => try bw.writeAll("undefined"),
        },
        .binaryOp => |b| switch (b.kind) {
            .add => |op| {
                const is_string_op = isStringExpr(op.lhs.*) or isStringExpr(op.rhs.*);
                try bw.writeByte('(');
                try writeExprErl(bw, allocator, op.lhs.*);
                try bw.writeAll(if (is_string_op) " ++ " else " + ");
                try writeExprErl(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .sub => |op| {
                try bw.writeByte('(');
                try writeExprErl(bw, allocator, op.lhs.*);
                try bw.writeAll(" - ");
                try writeExprErl(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .mul => |op| {
                try bw.writeByte('(');
                try writeExprErl(bw, allocator, op.lhs.*);
                try bw.writeAll(" * ");
                try writeExprErl(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .div => |op| {
                try bw.writeByte('(');
                try writeExprErl(bw, allocator, op.lhs.*);
                try bw.writeAll(" div ");
                try writeExprErl(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .mod => |op| {
                try bw.writeByte('(');
                try writeExprErl(bw, allocator, op.lhs.*);
                try bw.writeAll(" rem ");
                try writeExprErl(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            else => try bw.writeAll("undefined"),
        },
        .call => |c| switch (c.kind) {
            .pipeline => |p| {
                // Flatten the pipeline chain
                var items: std.ArrayList(ast.TypedExpr) = .empty;
                defer items.deinit(allocator);
                try items.append(allocator, p.lhs.*);
                var current = p.rhs.*;
                while (true) {
                    if (current != .call or current.call.kind != .pipeline) break;
                    const inner = current.call.kind.pipeline;
                    try items.append(allocator, inner.lhs.*);
                    current = inner.rhs.*;
                }
                try items.append(allocator, current);

                // Emit as nested calls: last(...(first))
                var i: usize = items.items.len - 1;
                while (i > 0) : (i -= 1) {
                    try writeExprErl(bw, allocator, items.items[i]);
                    try bw.writeByte('(');
                }
                try writeExprErl(bw, allocator, items.items[0]);
                i = items.items.len - 1;
                while (i > 0) : (i -= 1) {
                    try bw.writeByte(')');
                }
            },
            else => try bw.writeAll("undefined"),
        },
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                try bw.writeByte('[');
                for (al.elems, 0..) |item, i| {
                    if (i > 0) try bw.writeAll(", ");
                    try writeExprErl(bw, allocator, item);
                }
                if (al.spread) |name| {
                    if (al.elems.len > 0) try bw.writeAll(", ");
                    if (name.len > 0) try bw.writeAll(name);
                }
                try bw.writeByte(']');
            },
            else => try bw.writeAll("undefined"),
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |e| try writeExprErl(bw, allocator, e.*),
            else => try bw.writeAll("undefined"),
        },
        .controlFlow => |cf| switch (cf.kind) {
            .@"break" => |y| if (y) |yp| try writeExprErl(bw, allocator, yp.*),
            else => try bw.writeAll("undefined"),
        },
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
            .string => |s| try std.fmt.allocPrint(allocator, "\"{s}\"", .{s}),
            .array => |items| blk: {
                // Check if this is a charcode array (string encoded as [72,101,108...])
                const is_charcode_array = blk2: {
                    if (items.items.len == 0) break :blk2 false;
                    for (items.items) |elem| {
                        if (elem != .integer) break :blk2 false;
                        const int_val = elem.integer;
                        if (int_val < 0 or int_val > 127) break :blk2 false;
                    }
                    break :blk2 true;
                };
                
                if (is_charcode_array) {
                    // Convert charcode array back to string
                    var str_buf: std.ArrayListUnmanaged(u8) = .empty;
                    defer str_buf.deinit(allocator);
                    for (items.items) |elem| {
                        try str_buf.append(allocator, @intCast(elem.integer));
                    }
                    break :blk try std.fmt.allocPrint(allocator, "\"{s}\"", .{str_buf.items});
                } else {
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
                            .string => |es| try std.fmt.allocPrint(allocator, "\"{s}\"", .{es}),
                            else => try allocator.dupe(u8, "undefined"),
                        };
                        try out_buf.appendSlice(allocator, elem_lit);
                    }
                    try out_buf.append(allocator, ']');
                    break :blk out_buf.toOwnedSlice(allocator);
                }
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
const ErlangError = error{
    ErlangRuntimeFailed,
};

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

    // Check if stdout is empty (Erlang might have failed silently)
    if (res.stdout.len == 0) {
        // Try to get more info from stderr
        const err_msg = if (res.stderr.len > 0) res.stderr else "Erlang returned empty stdout";
        std.debug.print("Erlang error: {s}\n", .{err_msg});
        return error.ErlangRuntimeFailed;
    }

    // Parse results from stdout
    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer values.deinit();

    parseResults(allocator, res.stdout, &values) catch |err| {
        std.debug.print("Failed to parse Erlang JSON output: {s}\n{s}\n", .{ @errorName(err), res.stdout });
        return err;
    };
    return .{ .script = src, .values = values };
}
