//! Decisions 811 (1), 814 — the `opaque` type modifier, checked.
//!
//! `[pub] opaque type X(…) { … }` (the parser's `TypeDecl.isOpaque`, carried
//! onto `TypeDef.Record.opaque_` by `infer.zig` `registerRecord`): `X(…)` is
//! written only inside `X`'s own methods (`opaque-construction`) and a field
//! is read only there (`opaque-field`) — type-private, not elsewhere in `X`'s
//! module either (decision 814 (1)); a method written without `pub` is called
//! only in `X`'s module, as every type's is (`method-not-pub`, decision 859,
//! `method_visibility.zig`). Outside, an `X` is named, passed,
//! stored, compared with `==` and tested with `is` — never built nor opened.
//!
//! "Inside `X`'s own methods" is `Env.opaqueOwner`, set by `inferTypeMethods`
//! while it checks a method body of `X`; "`X`'s module" is `Env.ownDecls`. The
//! compiler's own lowering may build an `X` from any module: a call node the lowering marked
//! (`CallExpr.lowering`, decision 830) is admitted, never a line range.

const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const Env = envMod.Env;
const TypeError = @import("error.zig").TypeError;
const diagnostics = @import("diagnostics.zig");

const InferError = error{ TypeError, OutOfMemory };

/// The opaque record `name` names, or null.
pub fn opaqueRecord(env: *Env, name: []const u8) ?envMod.TypeDef.Record {
    const td = env.lookupTypeDef(name) orelse return null;
    return switch (td) {
        .record => |r| if (r.opaque_) r else null,
        else => null,
    };
}

/// True while a method body of the opaque type `r` is checked.
fn inside(env: *Env, r: envMod.TypeDef.Record) bool {
    const owner = env.opaqueOwner orelse return false;
    return std.mem.eql(u8, owner, r.name);
}

/// `X(…)` written for the opaque record `name` (the declared name, an import
/// alias already read through): refused outside `X`'s methods, naming the
/// `pub` methods that make one.
pub fn refuseConstruction(env: *Env, name: []const u8, loc: ast.Loc, lowering: bool) InferError!void {
    const r = opaqueRecord(env, name) orelse return;
    if (inside(env, r) or lowering) return;
    const madeBy = try makersText(env, r);
    const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}` is an opaque type — `{s}(…)` is written only inside its own methods (decisions 811, 814)", .{ diagnostics.opaque_construction, r.name, r.name });
    const hint = if (madeBy.len > 0)
        try std.fmt.allocPrint(env.arena, "Make one through the type's methods: {s}.", .{madeBy})
    else
        try std.fmt.allocPrint(env.arena, "No method of `{s}` a program calls makes one: the compiler answers it.", .{r.name});
    env.lastError = TypeError.custom(msg, hint).withLoc(loc);
    return error.TypeError;
}

/// `x.f` read on a value of the opaque record `name`: refused outside `X`'s
/// methods.
pub fn refuseField(env: *Env, name: []const u8, member: []const u8, loc: ast.Loc) InferError!void {
    const r = opaqueRecord(env, name) orelse return;
    if (inside(env, r)) return;
    const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}` is an opaque type — its field `{s}` is read only inside its own methods (decisions 811, 814)", .{ diagnostics.opaque_field, r.name, member });
    const hint = if (env.getInherentMethodDecl(r.name, member)) |m| (if (m.isPub)
        try std.fmt.allocPrint(env.arena, "Call its method: `.{s}()`.", .{member})
    else
        "Read it through one of the type's `pub` methods.") else "Read it through one of the type's `pub` methods.";
    env.lastError = TypeError.custom(msg, hint).withLoc(loc);
    return error.TypeError;
}

/// A record pattern over the opaque record `name` (`X(f: v)` in a `case`):
/// it opens the value, refused as a field read is.
pub fn refusePattern(env: *Env, name: []const u8) InferError!void {
    const r = opaqueRecord(env, name) orelse return;
    if (inside(env, r)) return;
    const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}` is an opaque type — a pattern of its fields opens it, and only its own methods do (decisions 811, 814)", .{ diagnostics.opaque_field, r.name });
    env.lastError = TypeError.custom(msg, "Test the type with `is`, or read what its `pub` methods answer.");
    return error.TypeError;
}

/// The `pub` methods of `r` that answer an `X`, as `` `X.m(…)` `` joined by
/// commas; "" when none does.
fn makersText(env: *Env, r: envMod.TypeDef.Record) ![]const u8 {
    var out: std.ArrayListUnmanaged(u8) = .empty;
    for (r.makers) |m| {
        if (out.items.len > 0) try out.appendSlice(env.arena, ", ");
        try out.print(env.arena, "`{s}.{s}(…)`", .{ r.name, m });
    }
    return out.items;
}

/// The `pub` methods of the declaration `t` that answer the type itself
/// (`-> Self`, `-> X`, `-> X<…>`): the methods that make one, which
/// `opaque-construction` names.
pub fn makers(arena: std.mem.Allocator, t: ast.TypeDecl) ![]const []const u8 {
    var out: std.ArrayListUnmanaged([]const u8) = .empty;
    for (t.methods) |m| {
        if (!m.isPub) continue;
        const rt = m.returnType orelse continue;
        const answered: ?[]const u8 = switch (rt) {
            .named => |n| n,
            .generic => |g| g.name,
            else => null,
        };
        const a = answered orelse continue;
        if (std.mem.eql(u8, a, t.name) or std.mem.eql(u8, a, "Self")) try out.append(arena, m.name);
    }
    return out.items;
}
