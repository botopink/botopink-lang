//! TypeScript `.d.ts` emitter — the only place that writes declaration text.
//!
//! It renders the declaration subset of the shared model (`js_ast.zig`):
//! `TsDecl`, `TsMember`, `TsParam` and `TsType`. A type is always a node, so a
//! declaration cannot carry a type the backend spelled by hand, and a
//! parameter always has one (`any` when the source wrote none).

const std = @import("std");
const Ast = @import("js_ast.zig");
const js_ident = @import("js_emitter.zig").ident;

const Writer = std.Io.Writer;

pub const Error = Writer.Error;

/// Sanitized TS binding name: delegates to the JS emitter's reserved-word
/// escape so declarations and implementations agree.
pub fn ident(name: []const u8) []const u8 {
    return js_ident(name);
}

// ── types ────────────────────────────────────────────────────────────────────

pub fn writeType(w: *Writer, t: Ast.TsType) Error!void {
    switch (t) {
        .name => |n| try w.writeAll(n),
        .literal => |n| {
            try w.writeByte('"');
            try w.writeAll(n);
            try w.writeByte('"');
        },
        .generic => |g| {
            try w.writeAll(g.name);
            try w.writeByte('<');
            for (g.args, 0..) |a, i| {
                if (i > 0) try w.writeAll(", ");
                try writeType(w, a);
            }
            try w.writeByte('>');
        },
        .array => |inner| {
            try writeType(w, inner.*);
            try w.writeAll("[]");
        },
        .tuple => |elems| {
            try w.writeByte('[');
            for (elems, 0..) |e, i| {
                if (i > 0) try w.writeAll(", ");
                try writeType(w, e);
            }
            try w.writeByte(']');
        },
        .union_ => |types| for (types, 0..) |ty, i| {
            if (i > 0) try w.writeAll(" | ");
            try writeType(w, ty);
        },
        .func => |f| {
            try writeParams(w, f.params);
            try w.writeAll(" => ");
            try writeType(w, f.ret.*);
        },
        .object => |o| {
            try w.writeAll("{ ");
            for (o.fields, 0..) |f, i| {
                if (i > 0) try w.writeAll(o.sep);
                try w.writeAll(f.name);
                try w.writeAll(": ");
                try writeType(w, f.type);
            }
            try w.writeAll(" }");
        },
    }
}

fn writeParams(w: *Writer, params: []const Ast.TsParam) Error!void {
    try w.writeByte('(');
    for (params, 0..) |p, i| {
        if (i > 0) try w.writeAll(", ");
        if (p.name) |n| {
            try w.writeAll(ident(n));
            try w.writeAll(": ");
        }
        try writeType(w, p.type);
    }
    try w.writeByte(')');
}

// ── members ──────────────────────────────────────────────────────────────────

fn writeMember(w: *Writer, m: Ast.TsMember) Error!void {
    try w.writeAll("    ");
    switch (m) {
        .field => |f| {
            try w.writeAll(f.modifier);
            try w.writeAll(f.name);
            try w.writeAll(": ");
            try writeType(w, f.type);
            try w.writeAll(";\n");
        },
        .method => |f| {
            try w.writeAll(f.modifier);
            try w.writeAll(f.name);
            try writeParams(w, f.params);
            try w.writeAll(": ");
            try writeType(w, f.ret);
            try w.writeAll(";\n");
        },
        .getter => |g| {
            try w.writeAll("get ");
            try w.writeAll(g.name);
            try w.writeAll(": ");
            try writeType(w, g.type);
            try w.writeAll(";\n");
        },
        .setter => |s| {
            try w.writeAll("set ");
            try w.writeAll(s.name);
            try writeParams(w, s.params);
            try w.writeAll(";\n");
        },
        .ctor => |c| {
            try w.writeAll("constructor");
            try writeParams(w, c.params);
            try w.writeAll(";\n");
        },
        .enum_member => |e| {
            try w.writeAll(e.name);
            try w.writeAll(" = \"");
            try w.writeAll(e.value);
            try w.writeAll("\",\n");
        },
    }
}

// ── declarations ─────────────────────────────────────────────────────────────

pub fn writeDecl(w: *Writer, d: Ast.TsDecl) Error!void {
    switch (d) {
        .none => {},
        .const_ => |c| {
            try w.writeAll("export declare const ");
            try w.writeAll(ident(c.name));
            try w.writeAll(": ");
            try writeType(w, c.type);
            try w.writeAll(";\n");
        },
        .func => |f| {
            try w.writeAll("export declare function ");
            try w.writeAll(ident(f.name));
            try writeParams(w, f.params);
            try w.writeAll(": ");
            try writeType(w, f.ret);
            try w.writeAll(";\n");
        },
        .class => |c| {
            try w.writeAll("export declare class ");
            try w.writeAll(ident(c.name));
            try w.writeAll(" {\n");
            for (c.members) |m| try writeMember(w, m);
            try w.writeAll("}\n");
        },
        .interface => |i| {
            try w.writeAll("export declare interface ");
            try w.writeAll(ident(i.name));
            if (i.extends.len > 0) {
                try w.writeAll(" extends ");
                for (i.extends, 0..) |ext, j| {
                    if (j > 0) try w.writeAll(", ");
                    try w.writeAll(ext);
                }
            }
            try w.writeAll(" {\n");
            for (i.members) |m| try writeMember(w, m);
            try w.writeAll("}\n");
        },
        .enum_ => |e| {
            try w.writeAll("export declare enum ");
            try w.writeAll(ident(e.name));
            try w.writeAll(" {\n");
            for (e.members) |m| try writeMember(w, m);
            try w.writeAll("}\n");
        },
        .type_alias => |t| {
            try w.writeAll("export declare type ");
            try w.writeAll(t.name);
            try w.writeAll(" = ");
            try writeType(w, t.type);
            try w.writeAll(";\n");
        },
        .import => |i| {
            try w.writeAll("import { ");
            for (i.names, 0..) |n, j| {
                if (j > 0) try w.writeAll(", ");
                try w.writeAll(n);
            }
            try w.writeAll(" } from \"");
            try w.writeAll(i.source);
            try w.writeAll("\";\n");
        },
        .import_namespace => |i| {
            try w.writeAll("import * as ");
            try w.writeAll(ident(i.name));
            try w.writeAll(" from \"");
            try w.writeAll(i.source);
            try w.writeAll("\";\n");
        },
        .group => |items| for (items) |item| try writeDecl(w, item),
    }
}

/// Write a whole `.d.ts`: one declaration per binding, separated by a blank
/// line. A binding with no declaration surface (`.none`) still takes its
/// separator — that is what keeps the emitted file's blank runs stable.
pub fn writeProgram(w: *Writer, decls: []const Ast.TsDecl) Error!void {
    for (decls, 0..) |d, i| {
        if (i > 0) try w.writeByte('\n');
        try writeDecl(w, d);
        try w.writeByte('\n');
    }
}

// ── tests ────────────────────────────────────────────────────────────────────

fn expectDecl(expected: []const u8, d: Ast.TsDecl) !void {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    try writeDecl(&aw.writer, d);
    try std.testing.expectEqualStrings(expected, aw.written());
}

test "ts_emitter: types are nodes, never strings" {
    var aw: Writer.Allocating = .init(std.testing.allocator);
    defer aw.deinit();
    const w = &aw.writer;
    try writeType(w, .{ .array = &Ast.TsType{ .name = "i32" } });
    try w.writeAll(" | ");
    try writeType(w, .{ .generic = .{ .name = "Promise", .args = &.{.{ .name = "i32" }} } });
    try w.writeAll(" | ");
    try writeType(w, .{ .union_ = &.{
        .{ .object = .{ .fields = &.{ .{ .name = "tag", .type = .{ .literal = "Ok" } }, .{ .name = "result", .type = .{ .name = "i32" } } }, .sep = "; " } },
        .{ .object = .{ .fields = &.{.{ .name = "tag", .type = .{ .literal = "Error" } }}, .sep = "; " } },
    } });
    try w.writeAll(" | ");
    try writeType(w, .{ .func = .{ .params = &.{.{ .type = .{ .name = "string" } }}, .ret = &Ast.TsType{ .name = "void" } } });
    try std.testing.expectEqualStrings(
        "i32[] | Promise<i32> | { tag: \"Ok\"; result: i32 } | { tag: \"Error\" } | (string) => void",
        aw.written(),
    );
}

test "ts_emitter: declarations" {
    try expectDecl("export declare const x: i32;\n", .{ .const_ = .{ .name = "x", .type = .{ .name = "i32" } } });
    try expectDecl(
        "export declare function add(a: i32, b: i32): i32;\n",
        .{ .func = .{
            .name = "add",
            .params = &.{ .{ .name = "a", .type = .{ .name = "i32" } }, .{ .name = "b", .type = .{ .name = "i32" } } },
            .ret = .{ .name = "i32" },
        } },
    );
    try expectDecl(
        \\export declare class Person {
        \\    readonly name: string;
        \\    constructor(name: string);
        \\    greet(): string;
        \\}
        \\
    , .{ .class = .{ .name = "Person", .members = &.{
        .{ .field = .{ .modifier = "readonly ", .name = "name", .type = .{ .name = "string" } } },
        .{ .ctor = .{ .params = &.{.{ .name = "name", .type = .{ .name = "string" } }} } },
        .{ .method = .{ .name = "greet", .params = &.{}, .ret = .{ .name = "string" } } },
    } } });
    try expectDecl("import { a, b } from \"std\";\n", .{ .import = .{ .names = &.{ "a", "b" }, .source = "std" } });
}
