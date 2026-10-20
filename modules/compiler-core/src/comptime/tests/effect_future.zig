//! comptime: the `@Async` contract end-to-end (decisions 118–121 of 1.0.10-beta).
//!
//! `@Async<T>` replaces `@Future<T, E>` and never fails: a failure lives in an
//! inner `@Result` (`@Async<@Result<T, E>>`), `await t` answers that `@Result`,
//! and `try await t` propagates its error. `throw` / `try` read the fallible
//! channel — a `@Result` in some layer of the return — and nothing else.
//! (The file keeps its historical name; the `@Future` constructors it used to
//! pin left with the wrapper.)

const std = @import("std");
const h = @import("helpers.zig");

test "@Async happy path — bare return <t> + throw <e> inside @Async<@Result<…>> type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\type User(id: i32, name: string)
        \\async fn fetchUser(id: i32) -> Async<Result<User, string>> {
        \\    if (id < 0) { throw "negative-id"; };
        \\    return User(id: id, name: "alice");
        \\}
    );
}

test "@Async — try await unwraps @Async<@Result<T, E>> to T and propagates" {
    try h.assertInfersOk(std.testing.allocator,
        \\type User(id: i32, name: string)
        \\async fn fetchUser(id: i32) -> Async<Result<User, string>> {
        \\    return User(id: id, name: "alice");
        \\}
        \\async fn greet(id: i32) -> Async<Result<string, string>> {
        \\    val u = try await fetchUser(id);
        \\    return u.name;
        \\}
    );
}

test "@Async — await answers the @Result; case reads both outcomes" {
    try h.assertInfersOk(std.testing.allocator,
        \\async fn fetchCount() -> Async<Result<i32, string>> {
        \\    return 3;
        \\}
        \\async fn count() -> Async<i32> {
        \\    val r = await fetchCount();
        \\    return r.unwrapOr(0);
        \\}
    );
}

test "@Async — a @Result value passes through the Async layer (decision 119)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn parse(s: string) -> Result<i32, string> {
        \\    if (s == "") { throw "empty"; };
        \\    return 1;
        \\}
        \\async fn load(s: string) -> Async<Result<i32, string>> {
        \\    return parse(s);
        \\}
    );
}

test "@Async — throw in a @Async<i32> reds effect-try-without-fallible-channel" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\async fn fetch() -> Async<i32> {
        \\    throw "boom";
        \\}
    );
}

test "@Async — try await in a @Async<i32> reds effect-try-without-fallible-channel" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\async fn fetchUser() -> Async<Result<i32, string>> {
        \\    return 1;
        \\}
        \\async fn count() -> Async<i32> {
        \\    val n = try await fetchUser();
        \\    return n;
        \\}
    );
}

test "@Async — await under a @Result return reds await-without-async" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\async fn fetchCount() -> Async<i32> {
        \\    return 3;
        \\}
        \\fn semAwait() -> Result<i32, string> {
        \\    val x = await fetchCount();
        \\    return x;
        \\}
    );
}

// `effect-wrapper-behind-alias` (decision 118 rule 1) is pinned by the
// `conformance` cells once type aliases parse (`front/24-type-alias`).
