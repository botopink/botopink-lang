/// Node.js comptime evaluation backend.
///
/// Builds a JavaScript script from typed comptime expressions, runs it via
/// `node`, writes results to an output file, and parses the JSON array.
const std = @import("std");
const ast = @import("../../ast.zig");
const eval = @import("../eval.zig");

// ── Script builder ────────────────────────────────────────────────────────────

fn buildScript(allocator: std.mem.Allocator, entries: []const eval.ComptimeEntry) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    const bw = &aw.writer;

    try bw.writeAll("const fs = require('fs');\n");
    try bw.writeAll("const results = [\n");
    
    for (entries, 0..) |e, i| {
        try bw.writeAll("    { id: \"");
        try bw.writeAll(e.id);
        try bw.writeAll("\", value: ");
        switch (e.expr) {
            .comptime_ => |ct| switch (ct.kind) {
                .comptimeExpr => |inner| try writeExprJs(bw, allocator, inner.*),
                .comptimeBlock => |cb| {
                    for (cb.body) |stmt| {
                        switch (stmt.expr) {
                            .controlFlow => |cf| switch (cf.kind) {
                                .@"break" => |y| if (y) |yp| {
                                    try writeExprJs(bw, allocator, yp.*);
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
        try bw.writeAll(" }");
        if (i < entries.len - 1) try bw.writeAll(",");
        try bw.writeAll("\n");
    }
    
    try bw.writeAll("];\n");
    try bw.writeAll("process.stdout.write(JSON.stringify(results));\n");

    return aw.toOwnedSlice();
}

fn writeExprJs(bw: anytype, allocator: std.mem.Allocator, te: ast.TypedExpr) !void {
    switch (te) {
        .literal => |lit| switch (lit.kind) {
            .numberLit => |n| try bw.writeAll(n),
            .stringLit => |s| try writeJsString(bw, s),
            .comment => |c| {
                const prefix: []const u8 = switch (c.kind) {
                    .normal => "//",
                    .doc => "///",
                    .module => "////",
                };
                try bw.writeAll(prefix);
                try bw.writeAll(" ");
                try bw.writeAll(c.text);
            },
            .null_ => try bw.writeAll("null"),
        },
        .binaryOp => |b| switch (b.kind) {
            .add => |op| {
                try bw.writeByte('(');
                try writeExprJs(bw, allocator, op.lhs.*);
                try bw.writeAll(" + ");
                try writeExprJs(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .sub => |op| {
                try bw.writeByte('(');
                try writeExprJs(bw, allocator, op.lhs.*);
                try bw.writeAll(" - ");
                try writeExprJs(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .mul => |op| {
                try bw.writeByte('(');
                try writeExprJs(bw, allocator, op.lhs.*);
                try bw.writeAll(" * ");
                try writeExprJs(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .div => |op| {
                try bw.writeByte('(');
                try writeExprJs(bw, allocator, op.lhs.*);
                try bw.writeAll(" / ");
                try writeExprJs(bw, allocator, op.rhs.*);
                try bw.writeByte(')');
            },
            .mod => |op| {
                try bw.writeByte('(');
                try writeExprJs(bw, allocator, op.lhs.*);
                try bw.writeAll(" % ");
                try writeExprJs(bw, allocator, op.rhs.*);
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

                // Emit as nested calls: last(items)(...(items[1](items[0])))
                try bw.writeByte('(');
                var i: usize = items.items.len - 1;
                while (i > 0) : (i -= 1) {
                    try writeExprJs(bw, allocator, items.items[i]);
                    try bw.writeByte('(');
                }
                try writeExprJs(bw, allocator, items.items[0]);
                i = items.items.len - 1;
                while (i > 0) : (i -= 1) {
                    try bw.writeByte(')');
                }
                try bw.writeByte(')');
            },
            else => try bw.writeAll("undefined"),
        },
        .collection => |col| switch (col.kind) {
            .arrayLit => |al| {
                try bw.writeByte('[');
                for (al.elems, 0..) |item, i| {
                    if (i > 0) try bw.writeAll(", ");
                    try writeExprJs(bw, allocator, item);
                }
                if (al.spread) |name| {
                    if (al.elems.len > 0) try bw.writeAll(", ");
                    if (name.len > 0) {
                        try bw.writeAll("...");
                        try bw.writeAll(name);
                    }
                }
                try bw.writeByte(']');
            },
            else => try bw.writeAll("undefined"),
        },
        .comptime_ => |ct| switch (ct.kind) {
            .comptimeExpr => |e| try writeExprJs(bw, allocator, e.*),
            else => try bw.writeAll("undefined"),
        },
        .controlFlow => |cf| switch (cf.kind) {
            .@"break" => |y| if (y) |yp| try writeExprJs(bw, allocator, yp.*),
            else => try bw.writeAll("undefined"),
        },
        else => try bw.writeAll("undefined"),
    }
}

fn writeJsString(bw: anytype, s: []const u8) !void {
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
        
        // Convert JSON value to JS literal string
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
                    '\r' => try buf.appendSlice(allocator, "\\r"),
                    '\t' => try buf.appendSlice(allocator, "\\t"),
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
                        else => try allocator.dupe(u8, "undefined"),
                    };
                    try buf.appendSlice(allocator, try elem_str);
                }
                try buf.append(allocator, ']');
                break :blk buf.toOwnedSlice(allocator);
            },
            else => try allocator.dupe(u8, "undefined"),
        };
        try out.put(id, try lit);
    }
}

// ── Public entry point ────────────────────────────────────────────────────────

/// Evaluate `entries` using Node.js.
///
/// Writes a temporary JavaScript file to `.botopinkbuild/<module_name>.js`,
/// runs it via `node`, reads the output file `<module_name>.json`,
/// and returns the script source + evaluated id→value map.
pub fn run(
    allocator: std.mem.Allocator,
    io: std.Io,
    entries: []const eval.ComptimeEntry,
    build_root: []const u8,
) !eval.RunResult {
    // Build directory path: <build_root>/node/
    var dir_buf: [512]u8 = undefined;
    const tmp_dir = try std.fmt.bufPrint(&dir_buf, "{s}/node", .{build_root});
    var src_path_buf: [512]u8 = undefined;
    const src_path = try std.fmt.bufPrint(&src_path_buf, "{s}/main.js", .{tmp_dir});
    
    // Clean previous build if exists, then create directory
    std.Io.Dir.cwd().deleteTree(io, tmp_dir) catch {};
    std.Io.Dir.cwd().createDirPath(io, tmp_dir) catch |err| {
        if (err != error.PathAlreadyExists) return err;
    };

    // Build and write the JavaScript file
    const src = try buildScript(allocator, entries);
    errdefer allocator.free(src);
    try std.Io.Dir.cwd().writeFile(io, .{ .sub_path = src_path, .data = src });

    // Run the script
    const res = try std.process.run(allocator, io, .{ .argv = &.{ "node", src_path } });
    defer allocator.free(res.stderr);
    defer allocator.free(res.stdout);

    // Parse results from stdout
    var values = std.StringHashMap([]const u8).init(allocator);
    errdefer values.deinit();

    try parseResults(allocator, res.stdout, &values);
    return .{ .script = src, .values = values };
}
