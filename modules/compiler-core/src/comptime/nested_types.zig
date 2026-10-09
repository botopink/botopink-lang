//! Decision 330 (7) — a type declared in the body of a type is that type's
//! associated type: `pub type Type { pub type Field<T>(…) { … } … }` declares
//! `Type.Field<T>`, the node `decl.addType` produces (decision 216 (3)).
//!
//! The parser keeps such a type on its owner (`TypeDecl.assocTypes`), where the
//! formatter prints it. This pass, run on the parsed program before the checker
//! and the backends see it (`analyzeSource`), hoists every one of them — at any
//! depth — as the top-level type `Owner__Name` (`env.assocTypeName`), shown
//! `Owner.Name` (`TypeDecl.displayName`), declared right after its owner;
//! `assoc_types.zig` then rewrites every `Owner.Name` the source writes into
//! that one name, so no checker rule and no backend learns a new node. The
//! pass is idempotent: a program that already holds `Owner__Name` (a
//! re-analysis of the merged program) is answered as it is.
const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");

const Error = error{OutOfMemory};

/// The program with every type declared in a type's body hoisted to the top
/// level under its owner's path.
pub fn expand(arena: std.mem.Allocator, program: ast.Program) Error!ast.Program {
    var any = false;
    for (program.decls) |d| if (d == .type_ and d.type_.assocTypes.len > 0) {
        any = true;
    };
    if (!any) return program;
    var out: std.ArrayListUnmanaged(ast.DeclKind) = .empty;
    for (program.decls) |d| {
        try out.append(arena, d);
        if (d == .type_) try hoist(arena, &out, program.decls, d.type_, d.type_.name, d.type_.printedName());
    }
    return .{ .decls = try out.toOwnedSlice(arena) };
}

fn hoist(
    arena: std.mem.Allocator,
    out: *std.ArrayListUnmanaged(ast.DeclKind),
    existing: []const ast.DeclKind,
    owner: ast.TypeDecl,
    ownerName: []const u8,
    ownerShown: []const u8,
) Error!void {
    for (owner.assocTypes) |nested| {
        const mangled = try envMod.assocTypeName(arena, ownerName, nested.name);
        const shown = try std.fmt.allocPrint(arena, "{s}.{s}", .{ ownerShown, nested.name });
        if (!declares(existing, mangled)) {
            var t = nested;
            t.name = mangled;
            t.displayName = shown;
            t.comments = &.{};
            try out.append(arena, .{ .type_ = t });
        }
        try hoist(arena, out, existing, nested, mangled, shown);
    }
}

fn declares(decls: []const ast.DeclKind, name: []const u8) bool {
    for (decls) |d| if (d == .type_ and std.mem.eql(u8, d.type_.name, name)) return true;
    return false;
}

/// The names of the types declared in `t`'s body (one level: `Owner.Name`).
pub fn namesOf(arena: std.mem.Allocator, t: ast.TypeDecl) Error![]const []const u8 {
    const names = try arena.alloc([]const u8, t.assocTypes.len);
    for (t.assocTypes, 0..) |a, i| names[i] = a.name;
    return names;
}
