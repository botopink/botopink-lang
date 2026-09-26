//! comptime: the `@Task` contract end-to-end (decisions 118–121 of 1.0.10-beta).
//!
//! `@Task<T>` replaces `@Future<T, E>` and never fails: a failure lives in an
//! inner `@Result` (`@Task<@Result<T, E>>`), `await t` answers that `@Result`,
//! and `try await t` propagates its error. `throw` / `try` read the fallible
//! channel — a `@Result` in some layer of the return — and nothing else.
//! (The file keeps its historical name; the `@Future` constructors it used to
//! pin left with the wrapper.)

const std = @import("std");
const h = @import("helpers.zig");

test "@Task happy path — bare return <t> + throw <e> inside @Task<@Result<…>> type-checks" {
    try h.assertInfersOk(std.testing.allocator,
        \\type User(id: i32, name: string)
        \\fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
        \\    if (id < 0) { throw "negative-id"; };
        \\    return User(id: id, name: "alice");
        \\}
    );
}

test "@Task — try await unwraps @Task<@Result<T, E>> to T and propagates" {
    try h.assertInfersOk(std.testing.allocator,
        \\type User(id: i32, name: string)
        \\fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
        \\    return User(id: id, name: "alice");
        \\}
        \\fn greet(id: i32) -> @Task<@Result<string, string>> {
        \\    val u = try await fetchUser(id);
        \\    return u.name;
        \\}
    );
}

test "@Task — await answers the @Result; case reads both outcomes" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn fetchCount() -> @Task<@Result<i32, string>> {
        \\    return 3;
        \\}
        \\fn count() -> @Task<i32> {
        \\    val r = await fetchCount();
        \\    return r.unwrapOr(0);
        \\}
    );
}

test "@Task — a @Result value passes through the Task layer (decision 119)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn parse(s: string) -> @Result<i32, string> {
        \\    if (s == "") { throw "empty"; };
        \\    return 1;
        \\}
        \\fn load(s: string) -> @Task<@Result<i32, string>> {
        \\    return parse(s);
        \\}
    );
}

test "@Task — throw in a @Task<i32> reds effect-try-without-fallible-channel" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetch() -> @Task<i32> {
        \\    throw "boom";
        \\}
    );
}

test "@Task — try await in a @Task<i32> reds effect-try-without-fallible-channel" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetchUser() -> @Task<@Result<i32, string>> {
        \\    return 1;
        \\}
        \\fn count() -> @Task<i32> {
        \\    val n = try await fetchUser();
        \\    return n;
        \\}
    );
}

test "@Task — await under a @Result return reds effect-await-without-task" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn fetchCount() -> @Task<i32> {
        \\    return 3;
        \\}
        \\fn semAwait() -> @Result<i32, string> {
        \\    val x = await fetchCount();
        \\    return x;
        \\}
    );
}

// `effect-wrapper-behind-alias` (decision 118 rule 1) is pinned by the
// `tests/language` cells once type aliases parse (`front/24-type-alias`).
