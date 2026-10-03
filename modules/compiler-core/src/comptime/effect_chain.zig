//! The effect chain — decisions 118, 120 and 128 of 1.0.10-beta.
//!
//! The return type is the annotation (decision 118): a body gains `await`,
//! `use` or `yield` by writing the effect wrapper as its return type. The
//! wrappers form a subsumption order, and each level grants everything below
//! it. The order is declared in botopink, on the wrappers in
//! `libs/std/src/builtins.d.bp`:
//!
//!     pub behavior Task<T>                   { … }
//!     pub behavior Component<C, T> extends Task   // decision 128
//!     pub behavior Stream<T> extends Task         // decision 122
//!     pub behavior Iterator<T>                    // no clause
//!
//! `@Result` is NOT a level of the chain (decision 120): only `@Result` fails
//! (decision 121), and `throw` / `try` read the FALLIBLE CHANNEL — a `@Result`
//! in some layer of the return — which the checker computes from the return
//! type apart from the level (`comptime/infer.zig` `fallibleErrorOf`). So
//! `grants` answers the three level capabilities only.
//!
//! `extends` cannot carry type arguments, so the full clauses stay in the
//! comment block beside the declarations. That file is not parsed into the
//! type env — the whole `.d.bp` is documentation, and `comptime.zig`'s
//! embedded mirrors exist for the same reason — so the relation is restated
//! here, ONCE, and the drift tests at the foot read the file and fail if the
//! two disagree. Every legality check — `await`, `use`, `yield` — asks
//! `grants` rather than switching on an effect kind, so adding a wrapper is a
//! row in `clauses` and nothing else.

const std = @import("std");
const ast = @import("../ast.zig");

/// One declared clause: `wrapper extends implements`.
const Clause = struct { wrapper: []const u8, implements: []const u8 };

/// The chain, in the order `builtins.d.bp` declares it. Transitivity is
/// computed by `wrapperImplements`. `@Context<Base>` is not here: it is the
/// owner MARKER a type implements (decision 102), not a wrapper, and grants
/// nothing.
pub const clauses = [_]Clause{
    .{ .wrapper = "Component", .implements = "Task" },
    .{ .wrapper = "Stream", .implements = "Task" },
};

/// The wrappers whose body may `yield`. `yield` is not a level of the chain:
/// it belongs to the two sequence wrappers and is granted by none of the
/// others, in either direction (decision 122).
pub const yielding_wrappers = [_][]const u8{ "Iterator", "Stream" };

/// A body operation whose legality the chain decides. `throw` / `try` are not
/// here: they follow the fallible channel, not the level (decision 121).
pub const Capability = enum {
    await_,
    use_,
    yield_,

    /// How the capability is written in source — what a diagnostic quotes.
    pub fn spelling(self: Capability) []const u8 {
        return switch (self) {
            .await_ => "await",
            .use_ => "use",
            .yield_ => "yield",
        };
    }

    /// The wrapper this capability belongs to, or null for `yield`, which
    /// belongs to a set rather than to a level.
    pub fn wrapper(self: Capability) ?[]const u8 {
        return switch (self) {
            .await_ => "Task",
            .use_ => "Component",
            .yield_ => null,
        };
    }
};

/// True when `wrapper` implements `target`, reflexively and transitively.
/// The chain is two clauses deep at most, so the walk is a bounded loop
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

/// True when a body whose return activates `eff` may write `cap`. A body with
/// no effect grants nothing — pass null and every answer is false.
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
/// names so the author reads the return they would need rather than guessing it.
pub fn grantingEffects(cap: Capability, buf: *[ast.EffectKind.all.len]ast.EffectKind) []const ast.EffectKind {
    var n: usize = 0;
    for (ast.EffectKind.all) |e| {
        if (grants(e, cap)) {
            buf[n] = e;
            n += 1;
        }
    }
    return buf[0..n];
}

/// The returns that grant `cap`, spelled — "`@Task<…>`, `@Stream<…>` or
/// `@Component<C, …>`".
pub fn grantingReturnsSpelled(arena: std.mem.Allocator, cap: Capability) ![]const u8 {
    var buf: [ast.EffectKind.all.len]ast.EffectKind = undefined;
    const granting = grantingEffects(cap, &buf);
    var names: std.ArrayListUnmanaged(u8) = .empty;
    for (granting, 0..) |e, i| {
        if (i > 0) try names.appendSlice(arena, if (i + 1 == granting.len) " or " else ", ");
        const one = if (e == .component)
            "`-> @Component<C, …>`"
        else
            try std.fmt.allocPrint(arena, "`-> @{s}<…>`", .{e.returnWrapper()});
        try names.appendSlice(arena, one);
    }
    return names.items;
}

/// The refusal for `cap` written in a body whose return activates `eff`
/// (null: a plain `fn`). Decision 67 — located, with no flag, and naming the
/// return it would need.
pub fn refusal(arena: std.mem.Allocator, code: []const u8, cap: Capability, eff: ?ast.EffectKind) ![]const u8 {
    const names = try grantingReturnsSpelled(arena, cap);
    const body: []const u8 = if (eff) |e|
        try std.fmt.allocPrint(arena, "this fn returns `@{s}<…>`, which does not", .{e.returnWrapper()})
    else
        "this fn's return type is no effect wrapper";
    return std.fmt.allocPrint(
        arena,
        "{s}: `{s}` needs {s} return — {s}",
        .{ code, cap.spelling(), names, body },
    );
}

// ── the file is the declaration; these tests are the drift gate ──────────────

/// `libs/std/src/builtins.d.bp`, embedded so the tests below can read the
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

test "effect chain: every effect wrapper is declared, and no removed one is" {
    for (ast.EffectKind.all) |e| {
        if (e == .result) continue; // `Result` is a `type`, not a behavior
        if (declarationLine(e.returnWrapper()) == null) {
            std.debug.print("builtins.d.bp declares no `{s}` behavior\n", .{e.returnWrapper()});
            return error.WrapperNotDeclared;
        }
    }
    // Decision 127 — gone, not aliased.
    for ([_][]const u8{ "Future", "Generator", "ResultGenerator", "FutureGenerator", "Use", "Iterable" }) |old| {
        try std.testing.expect(declarationLine(old) == null);
    }
    try std.testing.expect(std.mem.indexOf(u8, builtins_source, "pub type YieldStep<T> {") != null);
    // `@Iterator<T>` declares no clause: it neither awaits nor fails.
    const line = declarationLine("Iterator") orelse return error.WrapperNotDeclared;
    try std.testing.expect(std.mem.indexOf(u8, line, "extends") == null);
}

test "effect chain: decision 118's table, row by row" {
    // `-> @Result<T, E>` — no level: `throw` / `try` come from the fallible channel.
    try std.testing.expect(!grants(.result, .await_));
    try std.testing.expect(!grants(.result, .use_));
    try std.testing.expect(!grants(.result, .yield_));
    // `-> @Task<T>` — await.
    try std.testing.expect(grants(.task, .await_));
    try std.testing.expect(!grants(.task, .use_));
    try std.testing.expect(!grants(.task, .yield_));
    // `-> @Component<C, T>` ⊃ `@Task` — use · await.
    try std.testing.expect(grants(.component, .await_));
    try std.testing.expect(grants(.component, .use_));
    try std.testing.expect(!grants(.component, .yield_));
    // `-> @Iterator<T>` — yield, and nothing else (`iter-await`).
    try std.testing.expect(!grants(.iterator, .await_));
    try std.testing.expect(!grants(.iterator, .use_));
    try std.testing.expect(grants(.iterator, .yield_));
    // `-> @Stream<T>` ⊃ `@Task` — yield · await.
    try std.testing.expect(grants(.stream, .await_));
    try std.testing.expect(!grants(.stream, .use_));
    try std.testing.expect(grants(.stream, .yield_));
    // A plain `fn` grants nothing.
    try std.testing.expect(!grants(null, .await_));
    try std.testing.expect(!grants(null, .use_));
    try std.testing.expect(!grants(null, .yield_));
}

test "effect chain: the chain grants downwards, never upwards" {
    // `use` is `@Component`'s alone.
    for (ast.EffectKind.all) |e| {
        if (e == .component) continue;
        try std.testing.expect(!grants(e, .use_));
    }
    // `@Result` is outside the chain (decision 120).
    try std.testing.expect(!wrapperImplements("Result", "Task"));
    try std.testing.expect(!wrapperImplements("Task", "Result"));
    try std.testing.expect(!wrapperImplements("Component", "Result"));
    try std.testing.expect(!wrapperImplements("Task", "Component"));
    try std.testing.expect(wrapperImplements("Component", "Task"));
    try std.testing.expect(wrapperImplements("Stream", "Task"));
    try std.testing.expect(!wrapperImplements("Iterator", "Task"));
    // `@Context<Base>` is a marker, not a level of the chain.
    try std.testing.expect(!wrapperImplements("Context", "Task"));
}
