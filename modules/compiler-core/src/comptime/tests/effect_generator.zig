//! comptime: §1 `#[@generator]` effect contract end-to-end (F6-T3).
//!
//! Covers the §1 contract from
//! `tasks/v0.beta.20/specs/frente-b.md` F6-T3:
//!
//!   RI4 — `yield :label` whose `:label` is not bound in the enclosing
//!         label stack reds `yield-label-unbound` (alias of R10).
//!
//! Happy path: `yield <expr>` inside a `#[@generator]` body, labelled
//! `yield :outer` interacting with the enclosing fn label, and
//! `#[@generator]` return shape (`@Iterator<T>` — no return channel and
//! no error channel, decision 103).
//!
//! NOTE: §1 R8 (`yield <expr>` outside a generator/iterator body) is
//! NOT enforced at comptime by the current inference (the parser+typer
//! accept the form; only the codegens reject). Adding the R8 check is
//! a follow-up — once landed, a test row plugs in here.

const std = @import("std");
const h = @import("helpers.zig");

// ── RI4 / R10: yield :label where label is not bound reds ─────────────────

test "§1 R10 — yield :nonsense inside @Iterator reds yield-label-unbound" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Iterator<i32> :outer {
        \\    yield :nonsense 1;
        \\}
    );
}

// ── happy path: bare yield inside generator body ───────────────────────────

test "§1 happy path — yield <expr> inside @Iterator type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn nums() -> @Iterator<i32> {
        \\    yield 1;
        \\    yield 2;
        \\    yield 3;
        \\}
    );
}

test "§1 happy path — labelled yield :outer matches enclosing fn label" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn nums() -> @Iterator<i32> :outer {
        \\    yield :outer 1;
        \\}
    );
}

test "decision 123 — yield and return <expr> in one @Iterator body reds iter-mixed-yield-return" {
    // `@Iterator<T>` that yields is an iterator; `return <v>` answers a
    // ready one (a factory). The last value of an iterator is an item
    // (`break <v>`), never a `return <r>`.
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Iterator<i32> {
        \\    yield 1;
        \\    return 2;
        \\}
    );
}

test "decision 103 — break <v> at the level of a @Iterator body is its last item" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn nums() -> @Iterator<i32> {
        \\    yield 1;
        \\    break 2;
        \\}
    );
}

test "decision 121 — throw inside @Iterator<i32> reds effect-try-without-fallible-channel" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Iterator<i32> {
        \\    yield 1;
        \\    throw "no";
        \\}
    );
}

test "RG5 — a second argument on @Stream reds generic-arg-count-exceeded" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn nums() -> @Stream<i32, string> {
        \\    yield 1;
        \\}
    );
}
