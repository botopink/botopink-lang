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
//! `#[@generator]` return shape (`@Generator<T, R>` — R is the
//! return-value channel, distinct from `#[@iterator]`'s C completion).
//!
//! NOTE: §1 R8 (`yield <expr>` outside a generator/iterator body) is
//! NOT enforced at comptime by the current inference (the parser+typer
//! accept the form; only the codegens reject). Adding the R8 check is
//! a follow-up — once landed, a test row plugs in here.

const std = @import("std");
const h = @import("helpers.zig");

// ── RI4 / R10: yield :label where label is not bound reds ─────────────────

test "§1 R10 — yield :nonsense inside #[@generator] reds yield-label-unbound" {
    try h.assertTypeErrorSnap(std.testing.allocator,
        @src(),
        \\#[@generator]
        \\fn nums() -> @Generator<i32, void> :outer {
        \\    yield :nonsense 1;
        \\}
    );
}

// ── happy path: bare yield inside generator body ───────────────────────────

test "§1 happy path — yield <expr> inside #[@generator] type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@generator]
        \\fn nums() -> @Generator<i32, void> {
        \\    yield 1;
        \\    yield 2;
        \\    yield 3;
        \\}
    );
}

test "§1 happy path — labelled yield :outer matches enclosing fn label" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@generator]
        \\fn nums() -> @Generator<i32, void> :outer {
        \\    yield :outer 1;
        \\}
    );
}

test "§1 happy path — return <r> inside #[@generator] sets the R channel" {
    // `#[@generator]` carries a return-value channel R (distinct from
    // `#[@iterator]`'s completion channel C). `return <r>` resolves R.
    try h.assertInfersOk(std.testing.allocator,
        \\#[@generator]
        \\fn nums() -> @Generator<i32, string> {
        \\    yield 1;
        \\    return "done";
        \\}
    );
}
