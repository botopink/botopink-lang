//! TypeScript `.d.ts` emitter — the only place that writes declaration text.
//!
//! It renders the declaration subset of the shared model (`js_ast.zig`):
//! `TsDecl`, `TsMember`, `TsParam` and `TsType`. A type is always a node, so a
//! declaration cannot carry a type the backend spelled by hand, and a
//! parameter always has one (`any` when the source wrote none).

const std = @import("std");
const Ast = @import("js_ast.zig");
const jsEmitter = @import("js_emitter.zig");
const js_ident = jsEmitter.ident;

const Writer = std.Io.Writer;

pub const Error = Writer.Error;

/// Sanitized TS binding name: delegates to the JS emitter's reserved-word
/// escape so declarations and implementations agree.
pub fn ident(name: []const u8) []const u8 {
    return js_ident(name);
}

/// Decision 561 — a name holding a backtick identifier. As a binding it is
/// the JS emitter's escaped name (`jsEmitter.writeIdent`), as a property the
/// string of its name (`jsEmitter.writeKey`), as the commonJS module exports
/// it: an exported declaration is declared under the escaped name and
/// exported under the string (`export { $60f$60 as "`f`" };`), and an import
/// reads it back the same way.
fn hasBacktick(name: []const u8) bool {
    return std.mem.indexOfScalar(u8, name, '`') != null;
}

/// `export declare <kind> ` — without `export` for a backtick name, which
/// `writeExportAs` exports after the declaration.
fn writeDeclHead(w: *Writer, exported: bool, name: []const u8, kind: []const u8) Error!void {
    if (exported and !hasBacktick(name)) try w.writeAll("export ");
    try w.writeAll("declare ");
    try w.writeAll(kind);
    try w.writeByte(' ');
    try jsEmitter.writeIdent(w, name);
}

fn writeExportAs(w: *Writer, exported: bool, name: []const u8) Error!void {
    if (!exported or !hasBacktick(name)) return;
    try w.writeAll("export { ");
    try jsEmitter.writeName(w, name);
    try w.writeAll(" as ");
    try jsEmitter.writeKey(w, name);
    try w.writeAll(" };\n");
}

/// One item of `import { … }`: `name` or `name as local`.
fn writeImportItem(w: *Writer, item: []const u8) Error!void {
    const at = std.mem.indexOf(u8, item, " as ");
    const imported = if (at) |i| item[0..i] else item;
    const local = if (at) |i| item[i + 4 ..] else item;
    if (!hasBacktick(imported) and !hasBacktick(local)) return w.writeAll(item);
    try jsEmitter.writeKey(w, imported);
    if (at != null or hasBacktick(imported)) {
        try w.writeAll(" as ");
        try jsEmitter.writeIdent(w, local);
    }
}

// ── types ────────────────────────────────────────────────────────────────────

pub fn writeType(w: *Writer, t: Ast.TsType) Error!void {
    switch (t) {
        .name => |n| try jsEmitter.writeName(w, n),
        .literal => |n| {
            try w.writeByte('"');
            try w.writeAll(n);
            try w.writeByte('"');
        },
        .generic => |g| {
            try jsEmitter.writeName(w, g.name);
            try w.writeByte('<');
            for (g.args, 0..) |a, i| {
                if (i > 0) try w.writeAll(", ");
                try writeType(w, a);
            }
            try w.writeByte('>');
        },
        .array => |inner| {
            // `(number | bigint)[]` — `[]` binds tighter than `|`.
            if (inner.* == .union_) {
                try w.writeByte('(');
                try writeType(w, inner.*);
                try w.writeByte(')');
            } else try writeType(w, inner.*);
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
                try jsEmitter.writeKey(w, f.name);
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
        if (p.rest) try w.writeAll("...");
        if (p.name) |n| {
            try jsEmitter.writeIdent(w, n);
            try w.writeAll(": ");
        }
        try writeType(w, p.type);
    }
    try w.writeByte(')');
}

// ── members ──────────────────────────────────────────────────────────────────

fn writeMember(w: *Writer, m: Ast.TsMember) Error!void {
    return writeMemberAt(w, m, 1);
}

/// `/** @throws {E} */` and a newline — the error a failing task rejects
/// with (decision 432), which a `Promise<T>` cannot name.
fn writeThrows(w: *Writer, e: Ast.TsType) Error!void {
    try w.writeAll("/** @throws {");
    try writeType(w, e);
    try w.writeAll("} */\n");
}

fn writeIndent(w: *Writer, depth: usize) Error!void {
    for (0..depth) |_| try w.writeAll("    ");
}

fn writeMemberAt(w: *Writer, m: Ast.TsMember, depth: usize) Error!void {
    try writeIndent(w, depth);
    switch (m) {
        .field => |f| {
            try w.writeAll(f.modifier);
            try jsEmitter.writeKey(w, f.name);
            try w.writeAll(": ");
            try writeType(w, f.type);
            try w.writeAll(";\n");
        },
        .method => |f| {
            if (f.throws) |e| {
                try writeThrows(w, e);
                try writeIndent(w, depth);
            }
            try w.writeAll(f.modifier);
            try jsEmitter.writeKey(w, f.name);
            try writeParams(w, f.params);
            try w.writeAll(": ");
            try writeType(w, f.ret);
            try w.writeAll(";\n");
        },
        .getter => |g| {
            try w.writeAll("get ");
            try jsEmitter.writeKey(w, g.name);
            try w.writeAll(": ");
            try writeType(w, g.type);
            try w.writeAll(";\n");
        },
        .setter => |s| {
            try w.writeAll("set ");
            try jsEmitter.writeKey(w, s.name);
            try writeParams(w, s.params);
            try w.writeAll(";\n");
        },
        .ctor => |c| {
            try w.writeAll(c.modifier);
            try w.writeAll("constructor");
            try writeParams(w, c.params);
            try w.writeAll(";\n");
        },
        .enum_member => |e| {
            try jsEmitter.writeKey(w, e.name);
            try w.writeAll(" = \"");
            try w.writeAll(e.value);
            try w.writeAll("\",\n");
        },
    }
}

// ── namespaces ───────────────────────────────────────────────────────────────

/// The items of a `namespace` block, `depth` levels in: inside an ambient
/// namespace every member is exported, so neither `export` nor `declare` is
/// written again.
fn writeNamespaceItems(w: *Writer, items: []const Ast.TsNamespaceItem, depth: usize) Error!void {
    for (items) |item| switch (item) {
        .interface => |i| {
            try writeIndent(w, depth);
            try w.writeAll("interface ");
            try jsEmitter.writeIdent(w, i.name);
            try w.writeAll(" {\n");
            for (i.members) |m| try writeMemberAt(w, m, depth + 1);
            try writeIndent(w, depth);
            try w.writeAll("}\n");
        },
        .namespace => |ns| {
            try writeIndent(w, depth);
            try w.writeAll("namespace ");
            try jsEmitter.writeIdent(w, ns.name);
            try w.writeAll(" {\n");
            try writeNamespaceItems(w, ns.items, depth + 1);
            try writeIndent(w, depth);
            try w.writeAll("}\n");
        },
    };
}

// ── declarations ─────────────────────────────────────────────────────────────

pub fn writeDecl(w: *Writer, d: Ast.TsDecl) Error!void {
    switch (d) {
        .none => {},
        .const_ => |c| {
            try writeDeclHead(w, true, c.name, "const");
            try w.writeAll(": ");
            try writeType(w, c.type);
            try w.writeAll(";\n");
            try writeExportAs(w, true, c.name);
        },
        .func => |f| {
            if (f.throws) |e| try writeThrows(w, e);
            try writeDeclHead(w, true, f.name, "function");
            try writeParams(w, f.params);
            try w.writeAll(": ");
            try writeType(w, f.ret);
            try w.writeAll(";\n");
            try writeExportAs(w, true, f.name);
        },
        .class => |c| {
            try writeDeclHead(w, c.exported, c.name, "class");
            try w.writeAll(" {\n");
            for (c.members) |m| try writeMember(w, m);
            try w.writeAll("}\n");
            try writeExportAs(w, c.exported, c.name);
        },
        .interface => |i| {
            try writeDeclHead(w, i.exported, i.name, "interface");
            if (i.extends.len > 0) {
                try w.writeAll(" extends ");
                for (i.extends, 0..) |ext, j| {
                    if (j > 0) try w.writeAll(", ");
                    try jsEmitter.writeName(w, ext);
                }
            }
            try w.writeAll(" {\n");
            for (i.members) |m| try writeMember(w, m);
            try w.writeAll("}\n");
            try writeExportAs(w, i.exported, i.name);
        },
        .enum_ => |e| {
            try writeDeclHead(w, true, e.name, "enum");
            try w.writeAll(" {\n");
            for (e.members) |m| try writeMember(w, m);
            try w.writeAll("}\n");
            try writeExportAs(w, true, e.name);
        },
        .type_alias => |t| {
            try writeDeclHead(w, t.exported, t.name, "type");
            try w.writeAll(" = ");
            try writeType(w, t.type);
            try w.writeAll(";\n");
            try writeExportAs(w, t.exported, t.name);
        },
        .namespace_ => |ns| {
            try writeDeclHead(w, ns.exported, ns.name, "namespace");
            try w.writeAll(" {\n");
            try writeNamespaceItems(w, ns.items, 1);
            try w.writeAll("}\n");
            try writeExportAs(w, ns.exported, ns.name);
        },
        .import => |i| {
            try w.writeAll("import { ");
            for (i.names, 0..) |n, j| {
                if (j > 0) try w.writeAll(", ");
                try writeImportItem(w, n);
            }
            try w.writeAll(" } from \"");
            try w.writeAll(i.source);
            try w.writeAll("\";\n");
        },
        .import_namespace => |i| {
            try w.writeAll("import * as ");
            try jsEmitter.writeIdent(w, i.name);
            try w.writeAll(" from \"");
            try w.writeAll(i.source);
            try w.writeAll("\";\n");
        },
        .export_none => try w.writeAll("export {};\n"),
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
    // A module-private type a public signature names: declared, not exported,
    // and the file's `export {};` turns TypeScript's implicit export off.
    try expectDecl(
        \\declare class Loc {
        \\    readonly line: number;
        \\}
        \\
    , .{ .class = .{ .name = "Loc", .exported = false, .members = &.{
        .{ .field = .{ .modifier = "readonly ", .name = "line", .type = .{ .name = "number" } } },
    } } });
    try expectDecl("declare type Id = string;\n", .{ .type_alias = .{ .name = "Id", .type = .{ .name = "string" }, .exported = false } });
    try expectDecl("export {};\n", .export_none);
    try expectDecl(
        \\export declare namespace Token {
        \\    interface Layout {
        \\        readonly tag: "Break";
        \\    }
        \\    namespace Layout {
        \\        interface Break {
        \\            readonly tag: "Before" | "After";
        \\        }
        \\    }
        \\}
        \\
    , .{ .namespace_ = .{ .name = "Token", .items = &.{
        .{ .interface = .{ .name = "Layout", .members = &.{
            .{ .field = .{ .modifier = "readonly ", .name = "tag", .type = .{ .literal = "Break" } } },
        } } },
        .{ .namespace = .{ .name = "Layout", .items = &.{
            .{ .interface = .{ .name = "Break", .members = &.{
                .{ .field = .{ .modifier = "readonly ", .name = "tag", .type = .{ .union_ = &.{ .{ .literal = "Before" }, .{ .literal = "After" } } } } },
            } } },
        } } },
    } } });
}
