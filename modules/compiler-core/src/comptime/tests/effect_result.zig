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

test "§1 R11 — return Result.Ok(...) inside @Result reds return-must-be-bare-R" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    return Result.Ok(42);
        \\}
    );
}

// ── R12: `return Result.Error(...)` (wrong channel) reds ───────────────────

test "§1 R12 — return Result.Error(...) inside @Result reds result-return-type-mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    return Result.Error("boom");
        \\}
    );
}

// ── R11-mirror: manual `throw Result.Error(...)` forbidden ─────────────────

test "§1 R11-mirror — throw Result.Error(...) inside @Result reds throw-must-be-bare-E" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    throw Result.Error("boom");
        \\}
    );
}

// ── throw-mismatch: `throw Result.Ok(...)` (wrong channel) reds ────────────

test "§1 throw-mismatch — throw Result.Ok(...) inside @Result reds result-throw-type-mismatch" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetch() -> @Result<i32, string> {
        \\    throw Result.Ok(42);
        \\}
    );
}

// ── happy path: bare return / throw + try-catch round-trip ─────────────────

test "§1 happy path — bare return + throw inside @Result type-checks" {
    // The F4 transform rewrites the bare jumps to `__bp_ok`/`__bp_error`;
    // the typed-AST view here only asserts inference reaches the body's
    // tail without firing any R11/R12.
    try h.assertInfersOk(std.testing.allocator,
        \\type AppError(msg: string)
        \\fn parse(n: i32) -> @Result<i32, AppError> {
        \\    if (n < 0) { throw AppError(msg: "negative"); };
        \\    return n;
        \\}
    );
}

test "§1 happy path — `try` unwraps @Result<D, E> to D" {
    try h.assertInfersOk(std.testing.allocator,
        \\type AppError(msg: string)
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

test "§1 happy path — nested `@Result` call propagates Error via `try`" {
    try h.assertInfersOk(std.testing.allocator,
        \\type AppError(msg: string)
        \\fn parse(n: i32) -> @Result<i32, AppError> {
        \\    if (n < 0) { throw AppError(msg: "negative"); };
        \\    return n;
        \\}
        \\fn double(n: i32) -> @Result<i32, AppError> {
        \\    val v = try parse(n);
        \\    return v + v;
        \\}
    );
}

// ── a `throw` in a `case` arm is the enclosing function's (144 B-22 step 6) ──

test "a throw in a case arm of a @Result fn is the fn's error in every arm form and position" {
    // An expression arm and a block arm, with the `case` returned, bound by a
    // `val`, passed as an argument and written as a statement: each of the
    // six `throw`s keeps the fn's fallible channel and is recorded as the
    // fn's `return __bp_error(e)` — a block arm is not a lambda of its own.
    const n = try h.resultJumpLoweringCount(std.testing.allocator,
        \\type Value { Num(n: i32), Text(s: string) }
        \\fn g(n: i32) -> i32 { return n; }
        \\fn returned(v: Value) -> @Result<i32, string> {
        \\    return case v {
        \\        Num(n) -> g(n);
        \\        _ -> throw "a";
        \\    };
        \\}
        \\fn bound(v: Value) -> @Result<i32, string> {
        \\    val r = case v {
        \\        Num(n) -> g(n);
        \\        Text(s) {
        \\            throw "b" + s;
        \\        }
        \\    };
        \\    return r;
        \\}
        \\fn argument(v: Value) -> @Result<i32, string> {
        \\    return g(case v {
        \\        Num(n) -> n;
        \\        _ -> throw "c";
        \\    });
        \\}
        \\fn argumentBlock(v: Value) -> @Result<i32, string> {
        \\    return g(case v {
        \\        Num(n) -> n;
        \\        _ {
        \\            throw "d";
        \\        }
        \\    });
        \\}
        \\fn statement(v: Value) -> @Result<i32, string> {
        \\    case v {
        \\        Num(_) {
        \\            @print("num");
        \\        }
        \\        _ {
        \\            throw "e";
        \\        }
        \\    }
        \\    return 0;
        \\}
        \\fn statementExpression(v: Value) -> @Result<i32, string> {
        \\    case v {
        \\        Num(_) -> @print("num");
        \\        _ -> throw "f";
        \\    }
        \\    return 0;
        \\}
    , .wrap_error);
    try std.testing.expectEqual(@as(usize, 6), n);
}
