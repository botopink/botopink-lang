/// Hindley-Milner unification for the botopink type checker.
///
/// `unify(env, a, b)` makes `a` and `b` the same type by mutating type
/// variable cells in place.  It returns `error.TypeError` on failure; the
/// caller should inspect `env.lastError` for the diagnostic payload.
const std = @import("std");
const T = @import("./types.zig");
const Env = @import("env.zig").Env;
const TypeError = @import("error.zig").TypeError;

pub const UnifyError = error{ TypeError, OutOfMemory };

/// Unify types `a` and `b`.  Both are dereferenced first so link chains
/// are never seen inside the match arms.
pub fn unify(env: *Env, a: *T.Type, b: *T.Type) UnifyError!void {
    const ta = a.deref();
    const tb = b.deref();

    // Identical pointer → already the same type.
    if (ta == tb) return;

    switch (ta.*) {
        // ── type variable on the left ─────────────────────────────────────────
        .typeVar => |cellA| switch (cellA.state) {
            .unbound => |u| {
                // Occurs check: reject `a = List<a>` style recursive types.
                if (occursIn(u.id, tb)) {
                    env.lastError = TypeError.recursiveType(u.id);
                    return error.TypeError;
                }
                // Link this var to tb.
                cellA.state = .{ .link = tb };
            },
            .link => unreachable, // deref() already follows all links
            .generic => {
                // Generic vars should be instantiated before unification.
                env.lastError = TypeError.typeMismatch(ta, tb);
                return error.TypeError;
            },
        },

        // ── named types ───────────────────────────────────────────────────────
        .named => |na| switch (tb.*) {
            .typeVar => return unify(env, tb, ta), // symmetric
            .named => |nb| {
                if (!std.mem.eql(u8, na.name, nb.name)) {
                    env.lastError = TypeError.typeMismatch(ta, tb);
                    return error.TypeError;
                }
                if (na.args.len != nb.args.len) {
                    env.lastError = TypeError.typeMismatch(ta, tb);
                    return error.TypeError;
                }
                for (na.args, nb.args) |argA, argB| {
                    try unify(env, argA, argB);
                }
            },
            else => {
                env.lastError = TypeError.typeMismatch(ta, tb);
                return error.TypeError;
            },
        },

        // ── function types ────────────────────────────────────────────────────
        .func => |fa| switch (tb.*) {
            .typeVar => return unify(env, tb, ta),
            .func => |fb| {
                if (fa.params.len != fb.params.len) {
                    env.lastError = TypeError.arityMismatch("fn", fa.params.len, fb.params.len);
                    return error.TypeError;
                }
                for (fa.params, fb.params) |pa, pb| {
                    try unify(env, pa, pb);
                }
                try unify(env, fa.ret, fb.ret);
            },
            else => {
                env.lastError = TypeError.typeMismatch(ta, tb);
                return error.TypeError;
            },
        },

        // ── union types ───────────────────────────────────────────────────────
        .union_ => |typesA| switch (tb.*) {
            .typeVar => return unify(env, tb, ta),
            .union_ => |typesB| {
                if (typesA.len != typesB.len) {
                    env.lastError = TypeError.typeMismatch(ta, tb);
                    return error.TypeError;
                }
                for (typesA, typesB) |ua, ub| {
                    try unify(env, ua, ub);
                }
            },
            else => {
                env.lastError = TypeError.typeMismatch(ta, tb);
                return error.TypeError;
            },
        },
    }
}

/// Returns true if type variable `id` appears anywhere inside `ty`.
/// Used for the occurs check to prevent infinite recursive types.
fn occursIn(id: T.TypeId, ty: *T.Type) bool {
    const t = ty.deref();
    switch (t.*) {
        .typeVar => |cell| return switch (cell.state) {
            .unbound => |u| u.id == id,
            .link => unreachable, // deref() already followed links
            .generic => false,
        },
        .named => |n| {
            for (n.args) |arg| if (occursIn(id, arg)) return true;
            return false;
        },
        .func => |f| {
            for (f.params) |p| if (occursIn(id, p)) return true;
            return occursIn(id, f.ret);
        },
        .union_ => |types| {
            for (types) |ut| if (occursIn(id, ut)) return true;
            return false;
        },
    }
}
