//! Decisions 859, 886, 887 — a method written without `pub` is private to its
//! module, for every type.
//!
//! `x.m(…)` / `X.m(…)` naming a method of a type declared in another module,
//! written without `pub`, is `method-not-pub` at the call, naming the type and
//! the method (`refuseCall`, from `infer.zig` `checkOpaqueCall` /
//! `checkOpaqueMethodCall`). "The type's module" is `Env.ownDecls`. Two calls
//! stand: a method that implements a member of a behavior the type itself
//! declares `implement` for — reached through the behavior from anywhere,
//! with or without `pub` (859 (2)) — and a call the compiler's lowering marked
//! (`CallExpr.lowering`, decision 830).
//!
//! An extension block of another module met by such a method is 886's,
//! `infer.zig` `checkImplementSignatures`. A primitive's member of
//! `primitives.bp` — a method, or a property such as `pub val length: i32;`
//! — is read by the same rule (887 (2), `refusePrimitiveMember`): the prelude
//! writes every one `pub`.

const std = @import("std");
const ast = @import("../ast.zig");
const envMod = @import("env.zig");
const Env = envMod.Env;
const TypeError = @import("error.zig").TypeError;
const diagnostics = @import("diagnostics.zig");

const InferError = error{ TypeError, OutOfMemory };

/// `x.m(…)` / `X.m(…)` calling `typeName`'s method `method` at `loc`.
pub fn refuseCall(env: *Env, typeName: []const u8, method: []const u8, loc: ast.Loc, lowering: bool) InferError!void {
    if (lowering) return;
    const td = env.lookupTypeDef(typeName) orelse return;
    const m = env.getInherentMethodDecl(typeName, method) orelse return;
    if (m.isPub or env.ownDecls.contains(typeName)) return;
    if (implementsMember(env, td, method)) return;
    const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}.{s}`{s} is written without `pub` — a method without `pub` is called only in its own module (decision 859)", .{ diagnostics.method_not_pub, typeName, method, try moduleText(env, typeName, " of module") });
    const hint = try std.fmt.allocPrint(env.arena, "Write it `pub fn {s}` where `{s}` is declared, or call it from that module.", .{ method, typeName });
    env.lastError = TypeError.custom(msg, hint).withLoc(loc);
    return error.TypeError;
}

/// Decisions 859 (3), 887 (2) — a member of a primitive's own table
/// (`string`, `bool`, `array`, `bigint`, `bytes`, declared in `primitives.bp`)
/// written without `pub`, reached at `loc` from a program: refused. A member a
/// program's contract adopted into the table (`ast.BehaviorMethod.adoptedBy`)
/// is the contract's, not the primitive's, and stands.
pub fn refusePrimitiveMember(env: *Env, table: ?ast.BehaviorDecl, typeName: []const u8, member: []const u8, loc: ast.Loc) InferError!void {
    if (env.inStd) return;
    const decl = table orelse return;
    if (!decl.primitiveType) return;
    for (decl.methods) |m| if (std.mem.eql(u8, m.name, member)) {
        if (m.isPub or m.adoptedBy != null or !m.from_prelude) return;
        return refusePrimitive(env, typeName, member, "method", loc);
    };
    for (decl.fields) |f| if (std.mem.eql(u8, f.name, member)) {
        if (f.isPub) return;
        return refusePrimitive(env, typeName, member, "property", loc);
    };
}

fn refusePrimitive(env: *Env, typeName: []const u8, member: []const u8, what: []const u8, loc: ast.Loc) InferError!void {
    const msg = try std.fmt.allocPrint(env.arena, "{s}: `{s}.{s}` is written without `pub` in `primitives.bp` — a {s} without `pub` is reached only in its own module (decisions 859, 887)", .{ diagnostics.method_not_pub, typeName, member, what });
    env.lastError = TypeError.custom(msg, "std's prelude writes every member of a primitive `pub`; this one is std's to respell.").withLoc(loc);
    return error.TypeError;
}

/// Whether `method` is a member of a behavior `td` names in its own
/// `implement` clause, or of one that behavior extends (859 (2)). A behavior
/// this module cannot see is read as declaring it: the declaring module
/// checked the clause.
fn implementsMember(env: *Env, td: envMod.TypeDef, method: []const u8) bool {
    const impls: []const []const u8 = switch (td) {
        .record => |r| r.implements,
        .struct_ => |st| st.implements,
        .enum_ => |e| e.implements,
    };
    for (impls) |b| if (behaviorHasMember(env, b, method, 0)) return true;
    return false;
}

fn behaviorHasMember(env: *Env, name: []const u8, member: []const u8, depth: usize) bool {
    if (depth >= 16) return false;
    const decl = env.behaviorDecl(name) orelse return true;
    for (decl.methods) |m| if (std.mem.eql(u8, m.name, member)) return true;
    for (decl.extends) |sup| if (behaviorHasMember(env, sup, member, depth + 1)) return true;
    return false;
}

/// `<lead> `m`` for a type an import of this module names, else "".
fn moduleText(env: *Env, typeName: []const u8, lead: []const u8) ![]const u8 {
    var it = env.importedTypeDecls.valueIterator();
    while (it.next()) |d| if (std.mem.eql(u8, d.name, typeName)) {
        return std.fmt.allocPrint(env.arena, "{s} `{s}`", .{ lead, d.module });
    };
    return "";
}
