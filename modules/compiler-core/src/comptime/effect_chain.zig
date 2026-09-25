//! The effect chain — decision 95 of 1.0.10-beta.
//!
//! The seven effect wrappers are not seven unrelated types: they form a subsumption
//! order, and an annotation grants every capability at or below its own level.
//! The order is declared in botopink, on the wrappers in
//! `libs/std/src/builtins.d.bp`:
//!
//!     pub behavior Future<T, E = any>                    extends Result
//!     pub behavior ResultGenerator<T, E = any>           extends Result
//!     pub behavior FutureGenerator<T, E = any>           extends Future
//!     pub behavior Use<C, T>                             extends Future
//!     pub behavior Component<T>                          extends Use
//!     pub behavior Generator<T>                          // no clause — decision 103
//!
//! Decision 95 calls these `implement` clauses; a `behavior` carries `extends`
//! and only a `type` writes `implement`, so `extends` is what the file spells
//! (`builtins.d.bp` § index / slice already records the same grammar limit of
//! `primitives.bp`). `extends` also cannot carry type arguments, so the full
//! clauses stay in the § 95 comment block beside the declarations.
//!
//! That file is not parsed into the type env — the whole `.d.bp` is
//! documentation, and `comptime.zig`'s embedded mirrors exist for the same
//! reason — so the relation is restated here, ONCE, and the drift test at the
//! foot reads the file and fails if the two disagree. Every legality check —
//! `try`, `await`, `use`, `yield` — asks `grants` rather than switching on an
//! effect kind, so adding a wrapper is a row in `clauses` and nothing else.
//!
//! `@Generator<T>` is deliberately absent from `clauses`: it is the one
//! wrapper with no error channel (decision 103 answers question 97 (b)), so
//! `throw` and `try` are not legal in a `#[@generator]` body — what an empty
//! row means — and `refusal` names `@ResultGenerator<T, E>` there.

const std = @import("std");
const ast = @import("../ast.zig");

/// One declared clause: `wrapper extends implements`.
const Clause = struct { wrapper: []const u8, implements: []const u8 };

/// The chain, in the order `builtins.d.bp` declares it. Transitivity is
/// computed by `wrapperImplements`, so `@Use` needs no `Result` row.
/// `@Context<Base>` is not here: it is the owner MARKER a type implements
/// (decision 102), not a wrapper, and grants nothing.
pub const clauses = [_]Clause{
    .{ .wrapper = "Future", .implements = "Result" },
    .{ .wrapper = "ResultGenerator", .implements = "Result" },
    .{ .wrapper = "FutureGenerator", .implements = "Future" },
    .{ .wrapper = "Use", .implements = "Future" },
    .{ .wrapper = "Component", .implements = "Use" },
};

/// The wrappers whose body may `yield`. `yield` is not a level of the chain:
/// it belongs to the three generator-shaped wrappers and is granted by none of
/// the others, in either direction (decision 95 — "`yield` stays exclusive to
/// the three generator wrappers and `use` stays exclusive to `#[@use]`").
pub const yielding_wrappers = [_][]const u8{ "Generator", "ResultGenerator", "FutureGenerator" };

/// A body operation whose legality the chain decides.
pub const Capability = enum {
    try_,
    await_,
    use_,
    yield_,

    /// How the capability is written in source — what a diagnostic quotes.
    pub fn spelling(self: Capability) []const u8 {
        return switch (self) {
            .try_ => "try",
            .await_ => "await",
            .use_ => "use",
            .yield_ => "yield",
        };
    }

    /// The wrapper this capability belongs to, or null for `yield`, which
    /// belongs to a set rather than to a level.
    pub fn wrapper(self: Capability) ?[]const u8 {
        return switch (self) {
            .try_ => "Result",
            .await_ => "Future",
            .use_ => "Use",
            .yield_ => null,
        };
    }
};

/// True when `wrapper` implements `target`, reflexively and transitively.
/// The chain is four clauses deep at most, so the walk is a bounded loop
/// rather than a visited set.
pub fn wrapperImplements(wrapper: []const u8, target: []const u8) bool {
    var current = wrapper;
    var steps: usize = 0;
    while (steps <= clauses.len) : (steps += 1) {
        if (std.mem.eql(u8, current, target)) return true;
        const next = directSuper(current) orelse return false;
        current = next;
    }
    return false;
}

/// The wrapper `w` directly implements, or null when it declares no clause.
fn directSuper(w: []const u8) ?[]const u8 {
    for (clauses) |c| {
        if (std.mem.eql(u8, c.wrapper, w)) return c.implements;
    }
    return null;
}

/// True when a body carrying `eff` may write `cap`. A body with no effect
/// annotation grants nothing — pass null and every answer is false.
pub fn grants(eff: ?ast.EffectKind, cap: Capability) bool {
    const e = eff orelse return false;
    const w = e.returnWrapper();
    if (cap == .yield_) {
        for (yielding_wrappers) |y| {
            if (std.mem.eql(u8, w, y)) return true;
        }
        return false;
    }
    return wrapperImplements(w, cap.wrapper().?);
}

/// Every effect that grants `cap`, in declaration order — the list a refusal
/// names so the author reads the level they would need rather than guessing it.
pub fn grantingEffects(cap: Capability, buf: *[6]ast.EffectKind) []const ast.EffectKind {
    var n: usize = 0;
    for (ast.EffectKind.all) |e| {
        if (grants(e, cap)) {
            buf[n] = e;
            n += 1;
        }
    }
    return buf[0..n];
}

/// The refusal for `cap` written in a body carrying `eff` (null: a plain `fn`).
/// Decision 67 — located, with no flag, and naming the level it would need.
pub fn refusal(arena: std.mem.Allocator, code: []const u8, cap: Capability, eff: ?ast.EffectKind) ![]const u8 {
    var buf: [6]ast.EffectKind = undefined;
    const granting = grantingEffects(cap, &buf);

    var names: std.ArrayListUnmanaged(u8) = .empty;
    for (granting, 0..) |e, i| {
        if (i > 0) try names.appendSlice(arena, if (i + 1 == granting.len) " or " else ", ");
        const one = try std.fmt.allocPrint(arena, "`#[@{s}]`", .{e.annotationName()});
        try names.appendSlice(arena, one);
    }

    const level: []const u8 = if (cap.wrapper()) |w|
        try std.fmt.allocPrint(arena, "an effect that implements `@{s}`", .{w})
    else
        "a generator effect";

    const body: []const u8 = if (eff) |e|
        try std.fmt.allocPrint(
            arena,
            "`#[@{s}]` is `@{s}`, which does not",
            .{ e.annotationName(), e.returnWrapper() },
        )
    else
        "this fn carries no effect annotation";

    // Decision 103 — the infallible generator names the wrapper that has the
    // channel it lacks.
    const hint: []const u8 = if (eff != null and eff.? == .generator and cap == .try_)
        "; `@Generator` has no error channel; use `@ResultGenerator<T, E>`"
    else
        "";

    return std.fmt.allocPrint(
        arena,
        "{s}: `{s}` needs {s} — {s}; {s}{s}",
        .{ code, cap.spelling(), level, names.items, body, hint },
    );
}

// ── the file is the declaration; this test is the drift gate ──────────────────

/// `libs/std/src/builtins.d.bp`, embedded so the test below can read the
/// clauses the language actually declares rather than a copy of them.
const builtins_source = @import("std_prelude").builtins;

/// The declaration line of `wrapper` in `builtins.d.bp`, or null.
fn declarationLine(wrapper: []const u8) ?[]const u8 {
    var buf: [64]u8 = undefined;
    const decl = std.fmt.bufPrint(&buf, "pub behavior {s}<", .{wrapper}) catch return null;
    const at = std.mem.indexOf(u8, builtins_source, decl) orelse return null;
    const end = std.mem.indexOfScalarPos(u8, builtins_source, at, '\n') orelse builtins_source.len;
    return builtins_source[at..end];
}

test "effect chain: every clause here is declared in builtins.d.bp" {
    for (clauses) |c| {
        const line = declarationLine(c.wrapper) orelse {
            std.debug.print("builtins.d.bp declares no `{s}` behavior\n", .{c.wrapper});
            return error.WrapperNotDeclared;
        };
        var buf: [64]u8 = undefined;
        const clause = try std.fmt.bufPrint(&buf, "extends {s} ", .{c.implements});
        if (std.mem.indexOf(u8, line, clause) == null) {
            std.debug.print(
                "builtins.d.bp: `{s}` does not `extends {s}` — the chain drifted from the file:\n  {s}\n",
                .{ c.wrapper, c.implements, line },
            );
            return error.ClauseNotDeclared;
        }
    }
}

test "effect chain: builtins.d.bp declares no clause this module does not carry" {
    // The other direction: a clause added to the file and forgotten here would
    // otherwise pass the test above.
    var seen: usize = 0;
    var rest: []const u8 = builtins_source;
    while (std.mem.indexOf(u8, rest, "pub behavior ")) |at| {
        const end = std.mem.indexOfScalarPos(u8, rest, at, '\n') orelse rest.len;
        const line = rest[at..end];
        rest = rest[end..];
        if (std.mem.indexOf(u8, line, " extends ") == null) continue;
        seen += 1;
        var found = false;
        for (clauses) |c| {
            var buf: [64]u8 = undefined;
            const decl = try std.fmt.bufPrint(&buf, "pub behavior {s}<", .{c.wrapper});
            if (std.mem.startsWith(u8, line, decl)) found = true;
        }
        if (!found) {
            std.debug.print("builtins.d.bp carries an `extends` this module does not:\n  {s}\n", .{line});
            return error.ClauseNotCarried;
        }
    }
    try std.testing.expectEqual(clauses.len, seen);
}

test "effect chain: `@Generator` declares no clause (question 97)" {
    for (clauses) |c| {
        try std.testing.expect(!std.mem.eql(u8, c.wrapper, "Generator"));
    }
    try std.testing.expect(!grants(.generator, .try_));
    // The generator still yields: `yield` is a set, not a level.
    try std.testing.expect(grants(.generator, .yield_));
    const line = declarationLine("Generator") orelse return error.WrapperNotDeclared;
    try std.testing.expect(std.mem.indexOf(u8, line, "extends") == null);
}

test "effect chain: decision 95's table, row by row" {
    // `#[@result]` — the base.
    try std.testing.expect(grants(.result, .try_));
    try std.testing.expect(!grants(.result, .await_));
    try std.testing.expect(!grants(.result, .use_));
    try std.testing.expect(!grants(.result, .yield_));
    // `#[@future]` ⊃ `@Result`.
    try std.testing.expect(grants(.future, .try_));
    try std.testing.expect(grants(.future, .await_));
    try std.testing.expect(!grants(.future, .use_));
    try std.testing.expect(!grants(.future, .yield_));
    // `#[@resultGenerator]` ⊃ `@Result`, and yields.
    try std.testing.expect(grants(.resultGenerator, .try_));
    try std.testing.expect(!grants(.resultGenerator, .await_));
    try std.testing.expect(!grants(.resultGenerator, .use_));
    try std.testing.expect(grants(.resultGenerator, .yield_));
    // `#[@futureGenerator]` ⊃ `@Future` ⊃ `@Result`, and yields.
    try std.testing.expect(grants(.futureGenerator, .try_));
    try std.testing.expect(grants(.futureGenerator, .await_));
    try std.testing.expect(!grants(.futureGenerator, .use_));
    try std.testing.expect(grants(.futureGenerator, .yield_));
    // `#[@generator]` — question 97: it yields and nothing else.
    try std.testing.expect(!grants(.generator, .try_));
    try std.testing.expect(!grants(.generator, .await_));
    try std.testing.expect(!grants(.generator, .use_));
    try std.testing.expect(grants(.generator, .yield_));
    // `#[@use]` — `@Use` ⊃ `@Future` ⊃ `@Result`, and activates.
    try std.testing.expect(grants(.use, .try_));
    try std.testing.expect(grants(.use, .await_));
    try std.testing.expect(grants(.use, .use_));
    try std.testing.expect(!grants(.use, .yield_));
    // A plain `fn` grants nothing.
    try std.testing.expect(!grants(null, .try_));
    try std.testing.expect(!grants(null, .await_));
    try std.testing.expect(!grants(null, .use_));
    try std.testing.expect(!grants(null, .yield_));
}

test "effect chain: the chain grants downwards, never upwards" {
    // `use` is `#[@use]`'s alone, in both directions.
    for (ast.EffectKind.all) |e| {
        if (e == .use) continue;
        try std.testing.expect(!grants(e, .use_));
    }
    // `@Result` implements nothing above it.
    try std.testing.expect(!wrapperImplements("Result", "Future"));
    try std.testing.expect(!wrapperImplements("Result", "Use"));
    try std.testing.expect(!wrapperImplements("Future", "Use"));
    // `@Component<T>` is `@Use<B, T>`: it answers every level `@Use` does.
    try std.testing.expect(wrapperImplements("Component", "Use"));
    try std.testing.expect(wrapperImplements("Component", "Future"));
    try std.testing.expect(!wrapperImplements("Use", "Component"));
    // `@Context<Base>` is a marker, not a level of the chain.
    try std.testing.expect(!wrapperImplements("Context", "Result"));
    // …and everything below it, reflexively.
    try std.testing.expect(wrapperImplements("Result", "Result"));
    try std.testing.expect(wrapperImplements("Use", "Result"));
    try std.testing.expect(wrapperImplements("FutureGenerator", "Result"));
}
