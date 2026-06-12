/// Snapshot infrastructure for comptime AST tests.
///
/// Converts typed bindings to structured JSON representations and builds
/// multi-section snapshot content for assertion:
///   ----- SOURCE CODE -- name.bp
///   ----- COMPTIME JAVASCRIPT -- name.js  (if comptime expressions exist)
///   ----- BOTOPINK TRANSFORM CODE -- name.bp  (if comptime expressions exist)
///   ----- TYPED AST JSON -- name.json
const std = @import("std");
const snapMod = @import("../utils/snap.zig");
const format = @import("../format.zig");
const T = @import("./types.zig");
const ast = @import("../ast.zig");
const inferMod = @import("infer.zig");
const comptimeMod = @import("../comptime.zig");

// ── JSON representation types ─────────────────────────────────────────────────

/// A single parameter in a function signature.
const Param = struct {
    name: []const u8,
    type: []const u8,
    is_comptime: ?bool = null,
};

/// A string→string map serialized as a JSON object.
const FieldMap = struct {
    const Entry = struct { name: []const u8, value: []const u8 };
    entries: []const Entry,

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginObject();
        for (self.entries) |e| {
            try jws.objectField(e.name);
            try jws.write(e.value);
        }
        try jws.endObject();
    }
};

/// A source line extracted from a function body.
const FnBodyLine = struct {
    source: []const u8,
};

/// A use-declaration inside a `use` statement.
const UseDeclaration = struct {
    ast: []const u8,
    indent: []const u8,
    return_type: []const u8,

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        try jws.beginObject();
        try jws.objectField("ast");
        try jws.write(self.ast);
        try jws.objectField("indent");
        try jws.write(self.indent);
        try jws.objectField("return_type");
        try jws.write(self.return_type);
        try jws.endObject();
    }
};

/// A call argument in a constructor or function call.
const CallParam = struct {
    name: ?[]const u8,
    value: []const u8,
};

/// A call expression inside a `val` binding.
const CallExpr = struct {
    ast: []const u8,
    params: []const CallParam,
    return_type: []const u8,
};

/// A statement inside a `case` block arm body.
const StmtType = struct {
    return_type: []const u8,
};

/// One arm of a `case` expression.
/// `ast` is `"value"` for simple expression arms or `"block"` for lambda arms.
const CaseArm = struct {
    ast: []const u8,
    body: ?[]const StmtType,
    return_type: []const u8,
};

/// Full JSON representation of a `val x = case … { … }` binding.
const CaseExpr = struct {
    ast: []const u8,
    param: []const u8,
    match: []const CaseArm,
    return_type: []const u8,
};

/// Full JSON representation of a `use {a, b} from "module"` statement.
const UseExpr = struct {
    ast: []const u8,
    declarations: []const UseDeclaration,
};

/// Tagged union over all binding values — serialized via `jsonStringify`.
const BindingRepr = union(enum) {
    val: struct {
        ast: []const u8,
        indent: []const u8,
        expr: ?CallExpr,
        return_type: []const u8,

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.beginObject();
            try jws.objectField("ast");
            try jws.write(self.ast);
            try jws.objectField("indent");
            try jws.write(self.indent);
            try jws.objectField("return_type");
            try jws.write(self.return_type);
            if (self.expr) |expr| {
                try jws.objectField("expr");
                try jws.write(expr);
            }
            try jws.endObject();
        }
    },
    use: struct {
        ast: []const u8,
        declarations: []const UseDeclaration,

        pub fn jsonStringify(self: @This(), jws: anytype) !void {
            try jws.beginObject();
            try jws.objectField("ast");
            try jws.write(self.ast);
            try jws.objectField("declarations");
            try jws.write(self.declarations);
            try jws.endObject();
        }
    },
    case: struct {
        ast: []const u8,
        param: []const u8,
        match: []const CaseArm,
        return_type: []const u8,
    },
    fn_: struct {
        ast: []const u8,
        name: []const u8,
        is_pub: bool,
        generic_params: ?[]const []const u8,
        params: []const Param,
        return_type: []const u8,
        body: []const FnBodyLine,
    },
    struct_: struct {
        ast: []const u8,
        name: []const u8,
        id: usize,
        generic: ?[]const []const u8,
        fields: FieldMap,
    },
    record: struct {
        ast: []const u8,
        name: []const u8,
        id: usize,
        generic: ?[]const []const u8,
        fields: FieldMap,
    },
    enum_: struct {
        ast: []const u8,
        name: []const u8,
        id: usize,
        generic: ?[]const []const u8,
    },
    interface: struct {
        ast: []const u8,
        name: []const u8,
        generic: ?[]const []const u8,
    },
    other: struct {
        ast: []const u8,
    },

    pub fn jsonStringify(self: @This(), jws: anytype) !void {
        switch (self) {
            inline else => |inner| try jws.write(inner),
        }
    }
};

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Extract the text of a specific line (1-based) from source, trimmed.
fn extractLine(src: []const u8, line: usize) []const u8 {
    var currentLine: usize = 1;
    var start: usize = 0;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (currentLine == line) {
            var end = i;
            while (end < src.len and src[end] != '\n') end += 1;
            return trimWhitespace(src[start..end]);
        }
        if (src[i] == '\n') {
            currentLine += 1;
            start = i + 1;
        }
    }
    return trimWhitespace(src[start..]);
}

fn trimWhitespace(s: []const u8) []const u8 {
    var end = s.len;
    while (end > 0 and std.ascii.isWhitespace(s[end - 1])) end -= 1;
    var start: usize = 0;
    while (start < end and std.ascii.isWhitespace(s[start])) start += 1;
    return s[start..end];
}

/// Resolve the typeId for a type if it references a registered type definition.
fn resolveTypeId(ty: *T.Type, type_ids: std.StringHashMap(usize)) ?usize {
    return switch (ty.deref().*) {
        .named => |n| type_ids.get(n.name),
        else => null,
    };
}

fn genericNames(allocator: std.mem.Allocator, params: anytype) ![]const []const u8 {
    var gens: std.ArrayList([]const u8) = .empty;
    defer gens.deinit(allocator);
    for (params) |gp| try gens.append(allocator, gp.name);
    return allocator.dupe([]const u8, gens.items);
}

fn typeNameFromTypeRef(tr: anytype) []const u8 {
    return switch (tr) {
        .named => |n| if (@TypeOf(n) == []const u8) n else n.name,
        else => "?",
    };
}

fn extractFnBody(
    allocator: std.mem.Allocator,
    src: []const u8,
    stmts: []const ast.Stmt,
) ![]FnBodyLine {
    var body: std.ArrayList(FnBodyLine) = .empty;
    defer body.deinit(allocator);
    for (stmts) |stmt| {
        try body.append(allocator, .{ .source = extractLine(src, getExprLoc(stmt.expr).line) });
    }
    return body.toOwnedSlice(allocator);
}

fn buildCaseExpr(allocator: std.mem.Allocator, expr: ast.TypedExpr) !CaseExpr {
    const case_ = expr.collection.kind.case;
    var arms: std.ArrayList(CaseArm) = .empty;
    defer arms.deinit(allocator);
    for (case_.arms) |arm| {
        try arms.append(allocator, try buildCaseArm(allocator, arm.body));
    }
    return CaseExpr{
        .ast = "case",
        .param = if (case_.subjects.len > 0) try typeNameOf(allocator, getTypedExprType(case_.subjects[0])) else "unknown",
        .match = try allocator.dupe(CaseArm, arms.items),
        .return_type = try typeNameOf(allocator, getTypedExprType(expr)),
    };
}

fn buildCallExpr(allocator: std.mem.Allocator, expr: ast.TypedExpr) !CallExpr {
    const call_ = expr.call.kind.call;
    var params: std.ArrayList(CallParam) = .empty;
    defer params.deinit(allocator);
    for (call_.args) |arg| {
        try params.append(allocator, .{
            .name = arg.label,
            .value = try typeNameOf(allocator, getTypedExprType(arg.value.*)),
        });
    }
    return CallExpr{
        .ast = "call",
        .params = try params.toOwnedSlice(allocator),
        .return_type = try typeNameOf(allocator, getTypedExprType(expr)),
    };
}

/// Get the type from a TypedExpr based on its category
fn getTypedExprType(expr: ast.TypedExpr) *T.Type {
    return switch (expr) {
        .literal => |e| e.type_,
        .identifier => |e| e.type_,
        .binaryOp => |e| e.type_,
        .unaryOp => |e| e.type_,
        .jump => |e| e.type_,
        .branch => |e| e.type_,
        .loop => |e| e.type_,
        .binding => |e| e.type_,
        .useHook => |e| e.type_,
        .call => |e| e.type_,
        .function => |e| e.type_,
        .collection => |e| e.type_,
        .comptime_ => |e| e.type_,
    };
}

/// Get the location from a TypedExpr based on its category
fn getTypedExprLoc(expr: ast.TypedExpr) ast.Loc {
    return switch (expr) {
        .literal => |e| e.loc,
        .identifier => |e| e.loc,
        .binaryOp => |e| e.loc,
        .unaryOp => |e| e.loc,
        .jump => |e| e.loc,
        .branch => |e| e.loc,
        .loop => |e| e.loc,
        .binding => |e| e.loc,
        .useHook => |e| e.loc,
        .call => |e| e.loc,
        .function => |e| e.loc,
        .collection => |e| e.loc,
        .comptime_ => |e| e.loc,
    };
}

/// Get the location from an Expr based on its category
fn getExprLoc(expr: ast.Expr) ast.Loc {
    return switch (expr) {
        .literal => |e| e.loc,
        .identifier => |e| e.loc,
        .binaryOp => |e| e.loc,
        .unaryOp => |e| e.loc,
        .jump => |e| e.loc,
        .branch => |e| e.loc,
        .loop => |e| e.loc,
        .binding => |e| e.loc,
        .useHook => |e| e.loc,
        .call => |e| e.loc,
        .function => |e| e.loc,
        .collection => |e| e.loc,
        .comptime_ => |e| e.loc,
    };
}

fn buildCaseArm(allocator: std.mem.Allocator, body: ast.TypedExpr) !CaseArm {
    const retType = try typeNameOf(allocator, body.getType());
    if (body == .function) {
        const fk = body.function.kind;
        if (fk.syntax == .lambda and fk.params.len == 0) {
            var items: std.ArrayList(StmtType) = .empty;
            defer items.deinit(allocator);
            for (fk.body) |stmt| {
                const stmt_type = getTypedExprType(stmt.expr);
                try items.append(allocator, .{ .return_type = try typeNameOf(allocator, stmt_type) });
            }
            return CaseArm{
                .ast = "block",
                .body = try allocator.dupe(StmtType, items.items),
                .return_type = retType,
            };
        }
    }
    return CaseArm{ .ast = "value", .body = null, .return_type = retType };
}

fn bindingToRepr(
    allocator: std.mem.Allocator,
    b: inferMod.TypedBinding,
    src: []const u8,
    type_ids: std.StringHashMap(usize),
) !?BindingRepr {
    const resolvedTypeId = resolveTypeId(b.type_, type_ids);
    const typeStr = try typeNameOf(allocator, b.type_);

    return switch (b.decl) {
        .use => {
            // Create a slice with a single use-declaration for this binding
            const decls = try allocator.alloc(UseDeclaration, 1);
            decls[0] = .{
                .ast = "use-declaration",
                .indent = b.name,
                .return_type = typeStr,
            };

            return .{ .use = .{
                .ast = "use",
                .declarations = decls,
            } };
        },
        .val => blk: {
            if (b.typedExpr) |te| {
                if (te == .collection and te.collection.kind == .case) {
                    const caseExpr = try buildCaseExpr(allocator, te);
                    break :blk .{ .case = .{
                        .ast = caseExpr.ast,
                        .param = caseExpr.param,
                        .match = caseExpr.match,
                        .return_type = caseExpr.return_type,
                    } };
                }
                if (te == .call) {
                    break :blk .{ .val = .{
                        .ast = "val",
                        .indent = b.name,
                        .expr = try buildCallExpr(allocator, te),
                        .return_type = typeStr,
                    } };
                }
            }
            break :blk .{ .val = .{ .ast = "val", .indent = b.name, .expr = null, .return_type = typeStr } };
        },

        .@"fn" => |f| blk: {
            var params: std.ArrayList(Param) = .empty;
            for (f.params) |p| {
                try params.append(allocator, .{
                    .name = p.name,
                    .type = typeNameFromTypeRef(p.typeRef),
                    .is_comptime = if (p.modifier == .@"comptime") true else null,
                });
            }
            const gens = try genericNames(allocator, f.genericParams);
            break :blk .{ .fn_ = .{
                .ast = "fn_def",
                .name = b.name,
                .is_pub = f.isPub,
                .generic_params = if (gens.len > 0) gens else null,
                .params = try params.toOwnedSlice(allocator),
                .return_type = if (f.returnType) |rt| typeNameFromTypeRef(rt) else "void",
                .body = try extractFnBody(allocator, src, f.body),
            } };
        },

        .@"struct" => |s| blk: {
            var entries: std.ArrayList(FieldMap.Entry) = .empty;
            for (s.members) |member| switch (member) {
                .field => |fld| try entries.append(allocator, .{ .name = fld.name, .value = typeNameFromTypeRef(fld.typeRef) }),
                else => {},
            };
            const gens = try genericNames(allocator, s.genericParams);
            break :blk .{ .struct_ = .{
                .ast = "struct_def",
                .name = b.name,
                .id = resolvedTypeId orelse 0,
                .generic = if (gens.len > 0) gens else null,
                .fields = .{ .entries = try entries.toOwnedSlice(allocator) },
            } };
        },

        .record => |r| blk: {
            var entries: std.ArrayList(FieldMap.Entry) = .empty;
            for (r.fields) |fld| {
                try entries.append(allocator, .{ .name = fld.name, .value = typeNameFromTypeRef(fld.typeRef) });
            }
            const gens = try genericNames(allocator, r.genericParams);
            break :blk .{ .record = .{
                .ast = "record_def",
                .name = b.name,
                .id = resolvedTypeId orelse 0,
                .generic = if (gens.len > 0) gens else null,
                .fields = .{ .entries = try entries.toOwnedSlice(allocator) },
            } };
        },

        .@"enum" => |e| blk: {
            const gens = try genericNames(allocator, e.genericParams);
            break :blk .{ .enum_ = .{
                .ast = "enum_def",
                .name = b.name,
                .id = resolvedTypeId orelse 0,
                .generic = if (gens.len > 0) gens else null,
            } };
        },

        .interface => |i| blk: {
            const gens = try genericNames(allocator, i.genericParams);
            break :blk .{ .interface = .{
                .ast = "interface_def",
                .name = b.name,
                .generic = if (gens.len > 0) gens else null,
            } };
        },

        else => .{ .other = .{ .ast = @tagName(b.decl) } },
    };
}

// ── Public API ────────────────────────────────────────────────────────────────

/// Return the string representation of a type (allocated, caller owns).
pub fn typeNameOf(allocator: std.mem.Allocator, ty: *T.Type) std.mem.Allocator.Error![]const u8 {
    return switch (ty.deref().*) {
        .named => |n| {
            if (n.args.len == 0) return allocator.dupe(u8, n.name);
            var buf: std.ArrayList(u8) = .empty;
            defer buf.deinit(allocator);
            if (std.mem.eql(u8, n.name, "array") and n.args.len == 1) {
                const elem = try typeNameOf(allocator, n.args[0]);
                defer allocator.free(elem);
                return std.fmt.allocPrint(allocator, "{s}[]", .{elem});
            }
            if (std.mem.eql(u8, n.name, "tuple")) {
                try buf.appendSlice(allocator, "#(");
                for (n.args, 0..) |arg, i| {
                    if (i > 0) try buf.append(allocator, ',');
                    const arg_name = try typeNameOf(allocator, arg);
                    defer allocator.free(arg_name);
                    try buf.appendSlice(allocator, arg_name);
                }
                try buf.append(allocator, ')');
                return buf.toOwnedSlice(allocator);
            }
            try buf.appendSlice(allocator, n.name);
            try buf.append(allocator, '<');
            for (n.args, 0..) |arg, i| {
                if (i > 0) try buf.append(allocator, ',');
                const arg_name = try typeNameOf(allocator, arg);
                defer allocator.free(arg_name);
                try buf.appendSlice(allocator, arg_name);
            }
            try buf.append(allocator, '>');
            return buf.toOwnedSlice(allocator);
        },
        .func => |f| return typeNameOf(allocator, f.ret),
        .typeVar => return allocator.dupe(u8, "?"),
        .record => |fields| {
            var buf: std.ArrayList(u8) = .empty;
            defer buf.deinit(allocator);
            try buf.appendSlice(allocator, "record { ");
            for (fields, 0..) |f, i| {
                if (i > 0) try buf.appendSlice(allocator, ", ");
                try buf.appendSlice(allocator, f.name);
                try buf.appendSlice(allocator, ": ");
                const fieldName = try typeNameOf(allocator, f.type_);
                defer allocator.free(fieldName);
                try buf.appendSlice(allocator, fieldName);
            }
            try buf.appendSlice(allocator, " }");
            return buf.toOwnedSlice(allocator);
        },
        .union_ => |types| {
            var buf: std.ArrayList(u8) = .empty;
            defer buf.deinit(allocator);
            for (types, 0..) |t, i| {
                if (i > 0) try buf.appendSlice(allocator, " | ");
                const type_name = try typeNameOf(allocator, t);
                defer allocator.free(type_name);
                try buf.appendSlice(allocator, type_name);
            }
            return buf.toOwnedSlice(allocator);
        },
    };
}

/// Build the full snapshot text for a single module output.
pub fn buildSnapshot(allocator: std.mem.Allocator, output: comptimeMod.ComptimeOutput) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);

    const srcHdr = try std.fmt.allocPrint(allocator, "----- SOURCE CODE -- {s}.bp\n```botopink\n", .{output.name});
    defer allocator.free(srcHdr);
    try buf.appendSlice(allocator, srcHdr);
    try buf.appendSlice(allocator, output.src);
    try buf.appendSlice(allocator, "\n```\n\n");

    switch (output.outcome) {
        .ok => |ok| {
            if (ok.comptime_script) |ct| {
                const ctHdr = try std.fmt.allocPrint(allocator, "----- COMPTIME JAVASCRIPT -- {s}.js\n```javascript\n", .{output.name});
                defer allocator.free(ctHdr);
                try buf.appendSlice(allocator, ctHdr);
                try buf.appendSlice(allocator, ct);
                try buf.appendSlice(allocator, "\n```\n\n");

                const fmtHdr = try std.fmt.allocPrint(allocator, "----- BOTOPINK TRANSFORM CODE -- {s}.bp\n```botopink\n", .{output.name});
                defer allocator.free(fmtHdr);
                try buf.appendSlice(allocator, fmtHdr);
                const formatted = try format.format(allocator, ok.transformed);
                defer allocator.free(formatted);
                try buf.appendSlice(allocator, formatted);
                try buf.appendSlice(allocator, "\n```\n\n");
            }

            const jsonHdr = try std.fmt.allocPrint(allocator, "----- TYPED AST JSON -- {s}.json\n```json\n", .{output.name});
            defer allocator.free(jsonHdr);
            try buf.appendSlice(allocator, jsonHdr);

            // Use a temporary arena for all intermediate work: BindingRepr structs
            // (which own allocated slices) plus intermediate JSON values.
            var json_arena = std.heap.ArenaAllocator.init(allocator);
            defer json_arena.deinit();
            const ja = json_arena.allocator();

            var items = std.json.Array.init(ja);

            // First pass: collect and merge use declarations
            var merged_uses: std.StringHashMap(std.ArrayList(UseDeclaration)) = std.StringHashMap(std.ArrayList(UseDeclaration)).init(ja);
            defer {
                var iter = merged_uses.iterator();
                while (iter.next()) |entry| {
                    entry.value_ptr.deinit(ja);
                }
                merged_uses.deinit();
            }

            for (ok.bindings) |b| {
                const repr = (try bindingToRepr(ja, b, output.src, ok.type_ids)) orelse continue;

                if (repr == .use) {
                    const use_info = b.decl.use;
                    const module_source = "module";
                    _ = use_info;

                    const gop = try merged_uses.getOrPut(module_source);
                    if (!gop.found_existing) {
                        gop.value_ptr.* = std.ArrayList(UseDeclaration).empty;
                    }

                    // Add all declarations from this use to the merged list
                    for (repr.use.declarations) |decl| {
                        try gop.value_ptr.append(ja, decl);
                    }
                } else {
                    // For non-use declarations, add directly to items
                    const jsonStr = try std.json.Stringify.valueAlloc(ja, repr, .{ .emit_null_optional_fields = false, .whitespace = .indent_2 });
                    const value = try std.json.parseFromSliceLeaky(std.json.Value, ja, jsonStr, .{});
                    try items.append(value);
                }
            }

            // Second pass: add merged use declarations to items
            var iter = merged_uses.iterator();
            while (iter.next()) |entry| {
                const use_repr = BindingRepr{ .use = .{
                    .ast = "use",
                    .declarations = try entry.value_ptr.toOwnedSlice(ja),
                } };
                const jsonStr = try std.json.Stringify.valueAlloc(ja, use_repr, .{ .emit_null_optional_fields = false, .whitespace = .indent_2 });
                const value = try std.json.parseFromSliceLeaky(std.json.Value, ja, jsonStr, .{});
                try items.append(value);
            }
            var root = if (comptime @hasDecl(std.array_hash_map, "String"))
                try std.json.ObjectMap.init(ja, &.{}, &.{})
            else
                std.json.ObjectMap.init(ja);
            if (comptime @hasDecl(std.array_hash_map, "String")) {
                try root.put(ja, "declarations", .{ .array = items });
            } else {
                try root.put("declarations", .{ .array = items });
            }

            const json = try std.json.Stringify.valueAlloc(allocator, std.json.Value{ .object = root }, .{ .whitespace = .indent_2 });
            defer allocator.free(json);
            try buf.appendSlice(allocator, json);
            try buf.appendSlice(allocator, "\n```\n\n");
        },
        .validationError => {},
        .typeError => {},
        .parseError => {},
    }

    return buf.toOwnedSlice(allocator);
}

/// Build a multi-section snapshot for multiple module outputs joined together.
pub fn buildSnapshotMulti(allocator: std.mem.Allocator, outputs: []const comptimeMod.ComptimeOutput) ![]u8 {
    var buf: std.ArrayListUnmanaged(u8) = .empty;
    errdefer buf.deinit(allocator);
    for (outputs, 0..) |output, idx| {
        if (idx > 0) try buf.appendSlice(allocator, "\n");
        const text = try buildSnapshot(allocator, output);
        defer allocator.free(text);
        try buf.appendSlice(allocator, text);
    }
    return buf.toOwnedSlice(allocator);
}

/// Assert the comptime AST against a snapshot file.
/// The snapshot path is `"comptime/ast/{slug}.snap.md"`.
pub fn assertComptimeAst(
    allocator: std.mem.Allocator,
    slug: []const u8,
    outputs: []const comptimeMod.ComptimeOutput,
) !void {
    const snapName = try std.fmt.allocPrint(allocator, "comptime/ast/{s}", .{slug});
    defer allocator.free(snapName);
    const text = try buildSnapshotMulti(allocator, outputs);
    defer allocator.free(text);
    try snapMod.checkText(allocator, snapName, text);
}

/// Assert the comptime AST against a snapshot file with a full custom path.
/// Allows saving snapshots in separate directories (e.g., `comptime/node/` or `comptime/erlang/`).
pub fn assertComptimeAstWithPath(
    allocator: std.mem.Allocator,
    snap_slug: []const u8,
    outputs: []const comptimeMod.ComptimeOutput,
) !void {
    const text = try buildSnapshotMulti(allocator, outputs);
    defer allocator.free(text);
    try snapMod.checkText(allocator, snap_slug, text);
}
