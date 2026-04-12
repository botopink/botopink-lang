/// Type error diagnostics and comptime validation for the botopink type checker.
const std = @import("std");
const T = @import("./types.zig");
const ast = @import("../ast.zig");
const render = @import("./render.zig");

pub const Loc = ast.Loc;

// ── ComptimeError ─────────────────────────────────────────────────────────────

/// Describes a `comptime` expression that cannot be evaluated at compile time.
pub const ComptimeError = struct {
    /// The identifier that triggered the error (e.g. `"greeting"`).
    ident: []const u8,
    /// Source location of the offending node.
    loc: ast.Loc,

    /// Render the error to an allocated string. Caller owns the result.
    pub fn renderAlloc(self: ComptimeError, allocator: std.mem.Allocator, src: []const u8) ![]u8 {
        var aw: std.Io.Writer.Allocating = .init(allocator);
        defer aw.deinit();
        try self.renderTo(&aw.writer, src);
        return aw.toOwnedSlice();
    }

    fn renderTo(self: ComptimeError, writer: anytype, src: []const u8) !void {
        const line_text = render.extractLine(src, self.loc.line);
        const line_w = render.digitWidth(self.loc.line);
        const gutter = line_w + 1;

        try writer.writeAll("error comptime: expression cannot be evaluated at compile time\n");
        try render.padSpaces(writer, gutter - 1);
        try writer.print("┌─ :{d}:{d}\n", .{ self.loc.line, self.loc.col });
        try render.padSpaces(writer, gutter);
        try writer.writeAll("│\n");
        try writer.print("{d} │ {s}\n", .{ self.loc.line, line_text });
        try render.padSpaces(writer, gutter);
        try writer.writeAll("│ ");
        try render.padSpaces(writer, self.loc.col - 1);
        for (0..self.ident.len) |_| try writer.writeByte('^');
        try writer.writeAll("\n\n");
        try writer.print("  '{s}' is a runtime identifier\n", .{self.ident});
    }
};

// ── TypeError ─────────────────────────────────────────────────────────────────

/// The kind of type error that occurred.
pub const TypeErrorKind = union(enum) {
    /// Two types could not be unified.
    typeMismatch: struct {
        expected: *T.Type,
        got: *T.Type,
    },
    /// Identifier not found in scope.
    unboundVariable: []const u8,
    /// Wrong number of arguments in a call.
    arityMismatch: struct {
        name: []const u8,
        expected: usize,
        got: usize,
    },
    /// Field does not exist on a record or struct type.
    unknownField: struct {
        typeName: []const u8,
        field: []const u8,
    },
    /// Type is not a record or struct (field access on incompatible type).
    notARecord: []const u8,
    /// Occurs check failed — would create an infinite recursive type.
    recursiveType: T.TypeId,
    /// Type name used in source is not registered in the environment.
    unknownTypeName: []const u8,
    /// Record constructor is missing a required field.
    missingField: struct {
        typeName: []const u8,
        field: []const u8,
    },
};

/// A type error with its source location.
pub const TypeError = struct {
    kind: TypeErrorKind,
    /// Source location of the triggering expression, if known.
    loc: ?Loc = null,

    pub fn withLoc(self: TypeError, loc: Loc) TypeError {
        var t = self;
        t.loc = loc;
        return t;
    }

    pub fn typeMismatch(expected: *T.Type, got: *T.Type) TypeError {
        return .{ .kind = .{ .typeMismatch = .{ .expected = expected, .got = got } } };
    }

    pub fn unboundVariable(name: []const u8) TypeError {
        return .{ .kind = .{ .unboundVariable = name } };
    }

    pub fn arityMismatch(name: []const u8, expected: usize, got: usize) TypeError {
        return .{ .kind = .{ .arityMismatch = .{ .name = name, .expected = expected, .got = got } } };
    }

    pub fn unknownField(typeName: []const u8, field: []const u8) TypeError {
        return .{ .kind = .{ .unknownField = .{ .typeName = typeName, .field = field } } };
    }

    pub fn notARecord(typeName: []const u8) TypeError {
        return .{ .kind = .{ .notARecord = typeName } };
    }

    pub fn recursiveType(id: T.TypeId) TypeError {
        return .{ .kind = .{ .recursiveType = id } };
    }

    pub fn unknownTypeName(name: []const u8) TypeError {
        return .{ .kind = .{ .unknownTypeName = name } };
    }

    pub fn missingField(typeName: []const u8, field: []const u8) TypeError {
        return .{ .kind = .{ .missingField = .{ .typeName = typeName, .field = field } } };
    }
};

// ── Comptime validation ───────────────────────────────────────────────────────

/// Validates that every `comptime` / `comptime { }` expression in `program`
/// contains only compile-time-evaluable nodes (literals and arithmetic).
/// Returns the first offending expression, or null if valid.
pub fn validateComptime(program: ast.Program) ?ComptimeError {
    for (program.decls) |decl| {
        if (validateDecl(decl)) |err| return err;
    }
    return null;
}

fn validateDecl(decl: ast.DeclKind) ?ComptimeError {
    switch (decl) {
        .val => |v| return validateIfComptime(v.value.*),
        else => return null,
    }
}

fn validateIfComptime(expr: ast.Expr) ?ComptimeError {
    switch (expr.kind) {
        .@"comptime" => |e| return validateComptimeExpr(e.*),
        .comptimeBlock => |cb| {
            for (cb.body) |stmt| {
                if (validateComptimeExpr(stmt.expr)) |err| return err;
            }
            return null;
        },
        else => return null,
    }
}

fn validateComptimeExpr(expr: ast.Expr) ?ComptimeError {
    switch (expr.kind) {
        .numberLit, .stringLit => return null,
        .add, .sub, .mul, .div, .mod, .lt, .gt, .lte, .gte, .eq, .ne => |b| {
            if (validateComptimeExpr(b.lhs.*)) |err| return err;
            return validateComptimeExpr(b.rhs.*);
        },
        .arrayLit => |elems| {
            for (elems) |elem| {
                if (validateComptimeExpr(elem)) |err| return err;
            }
            return null;
        },
        .@"break" => |e| if (e) |ep| return validateComptimeExpr(ep.*) else return null,
        .@"comptime" => |e| return validateComptimeExpr(e.*),
        .comptimeBlock => |cb| {
            for (cb.body) |stmt| {
                if (validateComptimeExpr(stmt.expr)) |err| return err;
            }
            return null;
        },
        .ident => |name| return ComptimeError{ .ident = name, .loc = expr.loc },
        else => return ComptimeError{ .ident = @tagName(expr.kind), .loc = expr.loc },
    }
}
