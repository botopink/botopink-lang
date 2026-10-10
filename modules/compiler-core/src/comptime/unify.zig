/// Hindley-Milner unification for the botopink type checker.
///
/// `unify(env, a, b)` makes `a` and `b` the same type by mutating type
/// variable cells in place.  It returns `error.TypeError` on failure; the
/// caller should inspect `env.lastError` for the diagnostic payload.
const std = @import("std");
const T = @import("./types.zig");
const Env = @import("env.zig").Env;
const TypeError = @import("error.zig").TypeError;
const diagnostics = @import("diagnostics.zig");

pub const UnifyError = error{ TypeError, OutOfMemory };

/// Decision 8 §2 — `unknown` reaches inference as the reserved named type
/// `ast.unknown_type_name`; the lexer makes it a keyword and `isReservedWord`
/// refuses it as a user name, so nothing else can be spelled this way.
pub fn isUnknown(ty: *T.Type) bool {
    return ty.deref().isNamed("unknown");
}

/// Decision 332 — whether `t` is or holds a `bigint`.
pub fn mentionsBigint(t: *T.Type) bool {
    const d = t.deref();
    return switch (d.*) {
        .named => |n| blk: {
            if (std.mem.eql(u8, n.name, "bigint")) break :blk true;
            for (n.args) |a| if (mentionsBigint(a)) break :blk true;
            break :blk false;
        },
        .union_ => |ms| for (ms) |m| {
            if (mentionsBigint(m)) break true;
        } else false,
        else => false,
    };
}

/// Unify types `a` and `b`.  Both are dereferenced first so link chains
/// are never seen inside the match arms.
///
/// `a` is the **expected** type and `b` the value's — every caller passes them
/// target-first (`unifyAt(param, arg)`), which is what makes the one-way rules
/// below (`?T` accepting a `T`, and `unknown` accepting everything) sound.
pub fn unify(env: *Env, a: *T.Type, b: *T.Type) UnifyError!void {
    unifyTypes(env, a, b) catch |err| {
        if (err == error.TypeError) noteResultOrigin(env);
        return err;
    };
}

/// E3.9 — a mismatch whose `got` side is a `@Result` inference recorded the
/// origin of (`Env.resultOrigins`) carries that origin, so the hint can name
/// the fix for it (`try await t`, `try r`, the `try` / `throw` that made it).
fn noteResultOrigin(env: *Env) void {
    const le = if (env.lastError) |*e| e else return;
    if (le.kind != .typeMismatch) return;
    const m = &le.kind.typeMismatch;
    if (m.origin.source != .unknown or m.origin.made_at != null) return;
    if (env.resultOrigins.get(m.got.deref())) |o| m.origin = o;
}

fn unifyTypes(env: *Env, a: *T.Type, b: *T.Type) UnifyError!void {
    const ta = a.deref();
    const tb = b.deref();

    // Identical pointer → already the same type.
    if (ta == tb) return;

    // ── decision 8 §2.1 — `unknown` is the one-way top type ───────────────────
    // Every type is assignable **to** `unknown`; `unknown` is assignable to
    // nothing but `unknown`. The rule has to sit above the match because it
    // holds against every kind on the other side, not only `.named`.
    if (isUnknown(ta)) {
        // Decision 332 (question 139-a) — a `bigint` never widens to
        // `unknown`: no target can tell it from another integer at run time
        // (erlang holds one integer, commonJS's `i64` past 2^53 is a `BigInt`
        // too), so a test on the `unknown` would answer per target.
        if (mentionsBigint(tb)) {
            env.lastError = TypeError.custom(
                diagnostics.bigint_widened ++ ": a `bigint` does not widen to `unknown`",
                "A `bigint` is told from another integer by its static type alone (decision 332): keep it typed `bigint`, or convert it (`b.toString()`, `b.toI64()`).",
            );
            return error.TypeError;
        }
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

    // `noreturn` is the one-way bottom type: a call that never returns
    // (`@todo()`, `@panic(…)`, a `-> noreturn` fn) stands wherever a value of
    // any type is expected. An unbound variable on the left is not linked to
    // it — `val x = @todo();` leaves `x` open rather than typed `noreturn`.
    // The other way round (`-> noreturn` answered by a value) still reds.
    if (tb.isNamed("noreturn")) return;

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
            .typeVar => |cellB| {
                // Optional subsumption for a variable: an expected `?T` takes
                // a value typed by the `T` it wraps (`fn some<T>(v: T) -> ?T
                // { return v; }`), as it takes a concrete `i32` for `?i32`.
                // Linking the variable to the optional instead would fail the
                // occurs check — the variable sits inside it.
                if (isOptional(na) and cellB.state == .unbound and
                    occursIn(cellB.state.unbound.id, na.args[0]))
                {
                    return unify(env, na.args[0], tb);
                }
                return unify(env, tb, ta); // symmetric
            },
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
        // Decision 8 §3.3 — a union is one-way, like `unknown` and `?T`: a
        // **member** is assignable to the union (`val v: i32 | string = 1;`),
        // and the union is assignable to a member only after narrowing. The
        // arity-for-arity walk this replaced could only ever accept a union
        // written in exactly the same order as the expected one.
        .union_ => |typesA| switch (tb.*) {
            .typeVar => return unify(env, tb, ta),
            .union_ => |typesB| {
                // Every member the value may be has to be one the target
                // accepts. The target may be wider; it may never be narrower.
                for (typesB) |ub| {
                    const target = memberAccepting(typesA, ub) orelse {
                        env.lastError = TypeError.typeMismatch(ta, tb);
                        return error.TypeError;
                    };
                    try unify(env, target, ub);
                }
            },
            else => {
                const target = memberAccepting(typesA, tb) orelse {
                    env.lastError = TypeError.typeMismatch(ta, tb);
                    return error.TypeError;
                };
                try unify(env, target, tb);
            },
        },
    }
}

fn isOptional(n: anytype) bool {
    return std.mem.eql(u8, n.name, "optional") and n.args.len == 1;
}

/// The member of `members` that `value` goes into, matched by shape so the
/// answer never depends on a trial unification: a failed probe would leave the
/// alternative it tried linked, and there is no way to roll that back.
///
/// A member still an unbound variable accepts anything — inference has not
/// decided it, and refusing there would red on its own gap.
fn memberAccepting(members: []*T.Type, value: *T.Type) ?*T.Type {
    const v = value.deref();
    for (members) |m| {
        const dm = m.deref();
        if (dm == v) return m;
        switch (dm.*) {
            .typeVar => return m,
            .named => |nm| switch (v.*) {
                .named => |nv| if (std.mem.eql(u8, nm.name, nv.name) and
                    nm.args.len == nv.args.len) return m,
                .typeVar => return m,
                else => {},
            },
            .func => switch (v.*) {
                .func, .typeVar => return m,
                else => {},
            },
            .record => switch (v.*) {
                .record, .typeVar => return m,
                else => {},
            },
            .union_ => {},
        }
    }
    return null;
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
