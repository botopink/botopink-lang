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

/// Decision 8 §2 — `unknown` reaches inference as the reserved named type
/// `ast.unknown_type_name`; the lexer makes it a keyword and `isReservedWord`
/// refuses it as a user name, so nothing else can be spelled this way.
pub fn isUnknown(ty: *T.Type) bool {
    return ty.deref().isNamed("unknown");
}

/// Unify types `a` and `b`.  Both are dereferenced first so link chains
/// are never seen inside the match arms.
///
/// `a` is the **expected** type and `b` the value's — every caller passes them
/// target-first (`unifyAt(param, arg)`), which is what makes the one-way rules
/// below (`?T` accepting a `T`, and `unknown` accepting everything) sound.
pub fn unify(env: *Env, a: *T.Type, b: *T.Type) UnifyError!void {
    const ta = a.deref();
    const tb = b.deref();

    // Identical pointer → already the same type.
    if (ta == tb) return;

    // ── decision 8 §2.1 — `unknown` is the one-way top type ───────────────────
    // Every type is assignable **to** `unknown`; `unknown` is assignable to
    // nothing but `unknown`. The rule has to sit above the match because it
    // holds against every kind on the other side, not only `.named`.
    if (isUnknown(ta)) {
        // A value inference has not worked out yet is pinned to `unknown`
        // rather than left free: the annotation is the only thing known about
        // it. The recursive call lands in the `.typeVar` arm below — `ta` is
        // the variable there, so the refusal just under this block is skipped.
        if (tb.* == .typeVar) return unify(env, tb, ta);
        return;
    }
    // Coming *out* of `unknown` is the located error §2.1 sketches. An unbound
    // variable on the left is not a use — it is inference still deciding — so
    // it falls through and links, exactly as it would for any other type.
    if (isUnknown(tb) and ta.* != .typeVar) {
        env.lastError = TypeError.custom(
            "an `unknown` value cannot be used as another type without testing it",
            "Test it first: `if (x is i32) { … }` narrows `x` to `i32` inside the block.",
        );
        return error.TypeError;
    }

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
                // Optional subsumption (one-way): an expected `?T` accepts a
                // plain `T` value (`val x: ?i32 = 5`); unify inner with value.
                if (std.mem.eql(u8, na.name, "optional") and na.args.len == 1 and
                    !std.mem.eql(u8, nb.name, "optional"))
                {
                    return unify(env, na.args[0], tb);
                }
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

        // ── anonymous structural records ─────────────────────────────────────
        // Same field set, in declaration order, field types unify (V1 — no
        // width subtyping yet).
        .record => |fieldsA| switch (tb.*) {
            .typeVar => return unify(env, tb, ta),
            .record => |fieldsB| {
                if (fieldsA.len != fieldsB.len) {
                    env.lastError = TypeError.typeMismatch(ta, tb);
                    return error.TypeError;
                }
                for (fieldsA, fieldsB) |fa, fb| {
                    if (!std.mem.eql(u8, fa.name, fb.name)) {
                        env.lastError = TypeError.typeMismatch(ta, tb);
                        return error.TypeError;
                    }
                    try unify(env, fa.type_, fb.type_);
                }
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
        .record => |fields| {
            for (fields) |f| if (occursIn(id, f.type_)) return true;
            return false;
        },
    }
}
