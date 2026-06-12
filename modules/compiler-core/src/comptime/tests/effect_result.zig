//! comptime: §1 `#[@result]` effect contract end-to-end (F6-T1).
//!
//! Covers the §1 contract from
//! `tasks/v0.beta.20/specs/frente-b.md` F6-T1:
//!
//!   R11 — `return Result.Ok(...)` inside `#[@result]` reds
//!         `return-must-be-bare-R` (auto-wrap on return is implicit).
//!   R12 — `return Result.Error(...)` reds `result-return-type-mismatch`
//!         (the success channel uses `return`; error uses `throw`).
//!   R11-mirror — `throw Result.Error(...)` reds `throw-must-be-bare-E`.
//!   throw-mismatch — `throw Result.Ok(...)` reds `result-throw-type-mismatch`.
//!
//! Happy path: bare `return <r>;` / `throw <e>;` inside `#[@result]` flow
//! through the existing F4 transform (`__bp_ok(<r>)` / `__bp_error(<e>)`)
//! and lower per-backend to native `@Result` value shapes. `try ... catch`
//! round-trips the value back to D in the surrounding fn.

const std = @import("std");
const h = @import("helpers.zig");

// ── R11: manual Result.Ok in `return` forbidden ────────────────────────────

test "§1 R11 — return Result.Ok(...) inside #[@result] reds return-must-be-bare-R" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch() -> @Result<i32, string> {
        \\    return Result.Ok(42);
        \\}
    );
}

// ── R12: `return Result.Error(...)` (wrong channel) reds ───────────────────

test "§1 R12 — return Result.Error(...) inside #[@result] reds result-return-type-mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch() -> @Result<i32, string> {
        \\    return Result.Error("boom");
        \\}
    );
}

// ── R11-mirror: manual `throw Result.Error(...)` forbidden ─────────────────

test "§1 R11-mirror — throw Result.Error(...) inside #[@result] reds throw-must-be-bare-E" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch() -> @Result<i32, string> {
        \\    throw Result.Error("boom");
        \\}
    );
}

// ── throw-mismatch: `throw Result.Ok(...)` (wrong channel) reds ────────────

test "§1 throw-mismatch — throw Result.Ok(...) inside #[@result] reds result-throw-type-mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn fetch() -> @Result<i32, string> {
        \\    throw Result.Ok(42);
        \\}
    );
}

// ── happy path: bare return / throw + try-catch round-trip ─────────────────

test "§1 happy path — bare return + throw inside #[@result] type-checks" {
    // The F4 transform rewrites the bare jumps to `__bp_ok`/`__bp_error`;
    // the typed-AST view here only asserts inference reaches the body's
    // tail without firing any R11/R12.
    try h.assertInfersOk(std.testing.allocator,
        \\record AppError { msg: string }
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, AppError> {
        \\    if (n < 0) { throw AppError(msg: "negative"); };
        \\    return n;
        \\}
    );
}

test "§1 happy path — `try` unwraps @Result<D, E> to D" {
    try h.assertInfersOk(std.testing.allocator,
        \\record AppError { msg: string }
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, AppError> {
        \\    if (n < 0) { throw AppError(msg: "negative"); };
        \\    return n;
        \\}
        \\fn process(n: i32) -> i32 {
        \\    val v = try parse(n) catch 0;
        \\    return v;
        \\}
    );
}

test "§1 happy path — nested `#[@result]` call propagates Error via `try`" {
    try h.assertInfersOk(std.testing.allocator,
        \\record AppError { msg: string }
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, AppError> {
        \\    if (n < 0) { throw AppError(msg: "negative"); };
        \\    return n;
        \\}
        \\#[@result]
        \\fn double(n: i32) -> @Result<i32, AppError> {
        \\    val v = try parse(n);
        \\    return v + v;
        \\}
    );
}
