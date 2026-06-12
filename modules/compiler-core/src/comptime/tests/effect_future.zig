//! comptime: §1F `#[@future]` effect contract end-to-end (F6-T2).
//!
//! Covers the §1F contract from
//! `tasks/v0.beta.20/specs/frente-b.md` F6-T2:
//!
//!   RF1 — `return Future.resolved(...)` inside `#[@future]` reds
//!         `future-return-must-be-bare-T` (manual wrapping forbidden).
//!   RF2 — `throw Future.rejected(...)` reds `future-throw-must-be-bare-E`.
//!   RF3 — `return Future.rejected(...)` reds `future-return-type-mismatch`
//!         (the resolved channel uses `return`; rejection uses `throw`).
//!   RF4 — `throw Future.resolved(...)` reds `future-throw-type-mismatch`
//!         (mirror of RF3).
//!   RF5 — let-binding `Future.resolved(...)` reds
//!         `future-manual-construction-forbidden`.
//!
//! Happy path: bare `return <t>;` / `throw <e>;` inside `#[@future]` flow
//! through the F4F-T1 transform (`return __bp_future_<resolved|rejected>(...);`)
//! and re-emerge as native shapes at codegen — see
//! `codegen/tests/effect_future_lowering.zig` for the per-backend
//! rendering pair.

const std = @import("std");
const h = @import("helpers.zig");

// ── RF1: manual `return Future.resolved(...)` forbidden ────────────────────

test "§1F RF1 — return Future.resolved(value: t) inside #[@future] reds future-return-must-be-bare-T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    return Future.resolved(value: 42);
        \\}
    );
}

// ── RF2: manual `throw Future.rejected(...)` forbidden ─────────────────────

test "§1F RF2 — throw Future.rejected(error: e) inside #[@future] reds future-throw-must-be-bare-E" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    throw Future.rejected(error: "boom");
        \\}
    );
}

// ── RF3: `return Future.rejected(...)` (wrong channel) reds ────────────────

test "§1F RF3 — return Future.rejected(error: e) inside #[@future] reds future-return-type-mismatch" {
    // `return` resolves the T channel; the rejection variant only travels
    // via `throw`. Catches the cross-channel mismatch at the jump site.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    return Future.rejected(error: "boom");
        \\}
    );
}

// ── RF4: `throw Future.resolved(...)` (wrong channel) reds ─────────────────

test "§1F RF4 — throw Future.resolved(value: t) inside #[@future] reds future-throw-type-mismatch" {
    // Mirror of RF3 — `throw` is the rejection channel; resolved values
    // travel via `return`.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    throw Future.resolved(value: 42);
        \\}
    );
}

// ── RF5: let-binding `Future.resolved(...)` inside body reds ──────────────

test "§1F RF5 — let-binding Future.resolved inside #[@future] reds future-manual-construction-forbidden" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch() -> @Future<i32, string> {
        \\    val f = Future.resolved(value: 42);
        \\    return 0;
        \\}
    );
}

// ── happy path: bare return / throw / await (the §1F `fetchUser` shape) ────

test "§1F happy path — bare return <t> + throw <e> inside #[@future] type-checks" {
    // The F4F-T1 transform rewrites the bare jumps to the marker shape;
    // the typed-AST view here only asserts inference reaches the body's
    // tail without firing any RF*. The codegen pair lives in
    // `codegen/tests/effect_future_lowering.zig`.
    try h.assertInfersOk(std.testing.allocator,
        \\record User { id: i32, name: string }
        \\#[@future]
        \\fn fetchUser(id: i32) -> @Future<User, string> {
        \\    if (id < 0) { throw "negative-id"; };
        \\    return User(id: id, name: "alice");
        \\}
    );
}

test "§1F happy path — await unwraps @Future<T, E> to T" {
    // Inside another `#[@future]` body, `await` resolves a `@Future<T, E>`
    // operand to T. The E channel travels via the outer fn's throw shape.
    try h.assertInfersOk(std.testing.allocator,
        \\record User { id: i32, name: string }
        \\#[@future]
        \\fn fetchUser(id: i32) -> @Future<User, string> {
        \\    return User(id: id, name: "alice");
        \\}
        \\#[@future]
        \\fn greet(id: i32) -> @Future<string, string> {
        \\    val u = await fetchUser(id);
        \\    return u.name;
        \\}
    );
}
