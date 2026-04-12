/// TypeScript `.d.ts` typedef emitter.
///
/// Iterates over typed bindings and produces declaration files that mirror
/// the public contract of each botopink module.
const std = @import("std");
const ast = @import("../ast.zig");
const comptimeMod = @import("../comptime.zig");

/// Emit a TypeScript declaration file for all bindings.
pub fn emitProgram(
    allocator: std.mem.Allocator,
    bindings: []const comptimeMod.TypedBinding,
) ![]u8 {
    var aw: std.Io.Writer.Allocating = .init(allocator);
    defer aw.deinit();
    var em = Emitter{ .out = &aw.writer, .alloc = allocator };
    for (bindings, 0..) |b, i| {
        if (i > 0) try aw.writer.writeByte('\n');
        try em.emitBinding(b);
        try aw.writer.writeByte('\n');
    }
    return aw.toOwnedSlice();
}

const Emitter = struct {
    out: *std.Io.Writer,
    alloc: std.mem.Allocator,

    fn w(self: *Emitter, s: []const u8) !void {
        try self.out.writeAll(s);
    }
    fn fmt(self: *Emitter, comptime f: []const u8, args: anytype) !void {
        try self.out.print(f, args);
    }

    // ── declarations ─────────────────────────────────────────────────────────

    fn emitBinding(self: *Emitter, b: comptimeMod.TypedBinding) !void {
        switch (b.decl) {
            .val => |v| try self.emitVal(v.name, v.isPub, b.type_),
            .@"fn" => |f| try self.emitFn(f),
            .@"struct" => |s| try self.emitStruct(s),
            .record => |r| try self.emitRecord(r),
            .@"enum" => |e| try self.emitEnum(e),
            .interface => |i| try self.emitInterface(i),
            .implement => |im| try self.emitImplement(im),
            .use => |u| try self.emitUse(u),
            .delegate => |d| try self.emitDelegate(d),
        }
    }

    fn emitVal(self: *Emitter, name: []const u8, is_pub: bool, ty: *comptimeMod.Type) !void {
        if (!is_pub and name.len > 0) return;
        try self.w("export declare const ");
        try self.w(name);
        try self.w(": ");
        try self.emitType(ty.*);
        try self.w(";\n");
    }

    fn emitFn(self: *Emitter, f: ast.FnDecl) !void {
        if (!f.isPub) return;
        try self.w("export declare function ");
        try self.w(f.name);
        try self.w("(");
        try self.emitParams(f.params);
        try self.w("): ");
        if (f.returnType) |ret| {
            try self.emitTypeRef(ret);
        } else {
            try self.w("void");
        }
        try self.w(";\n");
    }

    fn emitStruct(self: *Emitter, s: ast.StructDecl) !void {
        if (!s.isPub) return;
        try self.w("export declare class ");
        try self.w(s.name);
        try self.w(" {\n");
        for (s.members) |m| switch (m) {
            .field => |f| {
                try self.w("    ");
                if (std.mem.startsWith(u8, f.name, "_")) {
                    try self.w("private ");
                } else {
                    try self.w("public ");
                }
                try self.w(f.name);
                try self.w(": ");
                try self.emitTypeRefStr(f.typeName);
                try self.w(";\n");
            },
            .method => |m2| {
                if (m2.is_declare) continue;
                try self.w("    ");
                try self.w(m2.name);
                try self.w("(");
                try self.emitParams(m2.params);
                try self.w("): ");
                if (m2.returnType) |ret| {
                    try self.emitTypeRef(ret);
                } else {
                    try self.w("void");
                }
                try self.w(";\n");
            },
            .getter => |g| {
                try self.w("    get ");
                try self.w(g.name);
                try self.w(": ");
                try self.emitTypeRefStr(g.returnType);
                try self.w(";\n");
            },
            .setter => |sg| {
                try self.w("    set ");
                try self.w(sg.name);
                try self.w("(");
                for (sg.params) |p| {
                    if (std.mem.eql(u8, p.name, "self")) continue;
                    try self.emitParam(p);
                }
                try self.w(");\n");
            },
        };
        try self.w("}\n");
    }

    fn emitRecord(self: *Emitter, r: ast.RecordDecl) !void {
        if (!r.isPub) return;
        try self.w("export declare class ");
        try self.w(r.name);
        try self.w(" {\n");
        for (r.fields) |f| {
            try self.w("    readonly ");
            try self.w(f.name);
            try self.w(": ");
            try self.emitTypeRef(f.typeRef);
            try self.w(";\n");
        }
        try self.w("    constructor(");
        for (r.fields, 0..) |f, i| {
            if (i > 0) try self.w(", ");
            try self.w(f.name);
            try self.w(": ");
            try self.emitTypeRef(f.typeRef);
        }
        try self.w(");\n");
        for (r.methods) |m| {
            if (m.is_declare) continue;
            try self.w("    ");
            try self.w(m.name);
            try self.w("(");
            try self.emitParams(m.params);
            try self.w("): ");
            if (m.returnType) |ret| {
                try self.emitTypeRef(ret);
            } else {
                try self.w("void");
            }
            try self.w(";\n");
        }
        try self.w("}\n");
    }

    fn emitEnum(self: *Emitter, e: ast.EnumDecl) !void {
        if (!e.isPub) return;
        // Emit as a TypeScript enum for unit variants, or a union type for payload variants
        var hasPayload = false;
        for (e.variants) |v| {
            if (v.fields.len > 0) {
                hasPayload = true;
                break;
            }
        }
        if (!hasPayload) {
            try self.w("export declare enum ");
            try self.w(e.name);
            try self.w(" {\n");
            for (e.variants) |v| {
                try self.w("    ");
                try self.w(v.name);
                try self.w(" = \"");
                try self.w(v.name);
                try self.w("\",\n");
            }
            try self.w("}\n");
        } else {
            // Discriminated union type
            try self.w("export declare type ");
            try self.w(e.name);
            try self.w(" = ");
            for (e.variants, 0..) |v, vi| {
                if (vi > 0) try self.w(" | ");
                if (v.fields.len == 0) {
                    try self.fmt("{{ tag: \"{s}\" }}", .{v.name});
                } else {
                    try self.fmt("{{ tag: \"{s}\"", .{v.name});
                    for (v.fields) |f| {
                        try self.fmt(", {s}: ", .{f.name});
                        try self.emitTypeRef(f.typeRef);
                    }
                    try self.w(" }");
                }
            }
            try self.w(";\n");
        }
    }

    fn emitInterface(self: *Emitter, i: ast.InterfaceDecl) !void {
        if (!i.isPub) return;
        try self.w("export declare interface ");
        try self.w(i.name);
        if (i.extends.len > 0) {
            try self.w(" extends ");
            for (i.extends, 0..) |ext, j| {
                if (j > 0) try self.w(", ");
                try self.w(ext);
            }
        }
        try self.w(" {\n");
        for (i.fields) |f| {
            try self.w("    ");
            try self.w(f.name);
            try self.w(": ");
            try self.emitTypeRefStr(f.typeName);
            try self.w(";\n");
        }
        for (i.methods) |m| {
            if (m.is_default) continue;
            try self.w("    ");
            try self.w(m.name);
            try self.w("(");
            try self.emitParams(m.params);
            try self.w("): ");
            if (m.returnType) |ret| {
                try self.emitTypeRef(ret);
            } else {
                try self.w("void");
            }
            try self.w(";\n");
        }
        try self.w("}\n");
    }

    fn emitImplement(self: *Emitter, im: ast.ImplementDecl) !void {
        // Implement declarations add methods to existing types
        for (im.methods) |m| {
            try self.w("export declare function ");
            try self.w(im.target);
            try self.w("_");
            try self.w(m.name);
            try self.w("(");
            var first = true;
            for (m.params) |p| {
                if (std.mem.eql(u8, p.name, "self")) continue;
                if (!first) try self.w(", ");
                try self.emitParam(p);
                first = false;
            }
            try self.w("): void;\n");
        }
    }

    fn emitUse(self: *Emitter, u: ast.UseDecl) !void {
        switch (u.source) {
            .stringPath => |p| {
                try self.w("import { ");
                for (u.imports, 0..) |name, i| {
                    if (i > 0) try self.w(", ");
                    try self.w(name);
                }
                try self.fmt(" }} from \"./{s}\";\n", .{p});
            },
            .functionCall => {}, // Dynamic imports don't translate cleanly
        }
    }

    fn emitDelegate(self: *Emitter, d: ast.DelegateDecl) !void {
        if (!d.isPub) return;
        try self.w("export declare type ");
        try self.w(d.name);
        try self.w(" = (");
        for (d.params, 0..) |p, i| {
            if (i > 0) try self.w(", ");
            try self.w(p.name);
            try self.w(": ");
            try self.emitTypeRefStr(p.typeName);
        }
        try self.w(") => ");
        if (d.returnType) |ret| {
            try self.emitTypeRefStr(ret);
        } else {
            try self.w("void");
        }
        try self.w(";\n");
    }

    // ── params ────────────────────────────────────────────────────────────────

    fn emitParams(self: *Emitter, params: []const ast.Param) !void {
        var first = true;
        for (params) |p| {
            if (std.mem.eql(u8, p.name, "self")) continue;
            if (!first) try self.w(", ");
            try self.emitParam(p);
            first = false;
        }
    }

    fn emitParam(self: *Emitter, p: ast.Param) !void {
        try self.w(p.name);
        try self.w(": ");
        try self.emitTypeRefStr(p.typeName);
    }

    // ── type rendering ────────────────────────────────────────────────────────

    fn derefType(ty: comptimeMod.Type) comptimeMod.Type {
        var cur = ty;
        while (true) {
            switch (cur) {
                .typeVar => |cell| switch (cell.state) {
                    .link => |linked| cur = linked.*,
                    else => return cur,
                },
                else => return cur,
            }
        }
    }

    fn emitType(self: *Emitter, ty: comptimeMod.Type) !void {
        const deref = derefType(ty);
        switch (deref) {
            .named => |n| {
                try self.w(n.name);
                if (n.args.len > 0) {
                    try self.w("<");
                    for (n.args, 0..) |a, i| {
                        if (i > 0) try self.w(", ");
                        try self.emitType(a.*);
                    }
                    try self.w(">");
                }
            },
            .func => |f| {
                try self.w("(");
                for (f.params, 0..) |p, i| {
                    if (i > 0) try self.w(", ");
                    try self.fmt("p{d}", .{i});
                    try self.w(": ");
                    try self.emitType(p.*);
                }
                try self.w(") => ");
                try self.emitType(f.ret.*);
            },
            .typeVar => try self.w("any"),
            .union_ => |types| {
                for (types, 0..) |t, i| {
                    if (i > 0) try self.w(" | ");
                    try self.emitType(t.*);
                }
            },
        }
    }

    fn emitTypeRef(self: *Emitter, tr: ast.TypeRef) !void {
        switch (tr) {
            .named => |n| {
                try self.w(n);
            },
            .array => |inner| {
                try self.emitTypeRef(inner.*);
                try self.w("[]");
            },
            .tuple_ => |elems| {
                try self.w("[");
                for (elems, 0..) |e, i| {
                    if (i > 0) try self.w(", ");
                    try self.emitTypeRef(e);
                }
                try self.w("]");
            },
            .optional => |inner| {
                try self.emitTypeRef(inner.*);
                try self.w(" | null");
            },
            .errorUnion => |eu| {
                try self.emitTypeRef(eu.errorType.*);
                try self.w(" | ");
                try self.emitTypeRef(eu.payload.*);
            },
        }
    }

    fn emitTypeRefStr(self: *Emitter, typeName: []const u8) !void {
        try self.w(typeName);
    }
};
