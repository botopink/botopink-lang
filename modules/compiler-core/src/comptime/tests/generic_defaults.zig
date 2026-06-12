//! comptime: default generic parameters (§1G).
//!
//! Covers the §1G "Default generic parameters (general language rule)"
//! contract from `tasks/v0.beta.19/specs/frente-b-rules-tooling.md`:
//!
//!   GenericParam      := IDENT ( "=" TypeRef )? ;
//!   GenericParamList  := "<" GenericParam ("," GenericParam)* ">" ;
//!
//! Every RG-code in §2 of the spec has at least one rejection test here:
//!
//!   RG1 — `<T = default, U>`: default-before-required is illegal
//!         (`generic-default-before-required`, parser-level, fires at every
//!         `GenericParamList` site: struct, fn, enum, interface, TypeRef).
//!   RG2 — `<>` with every param defaulted is legal (no diagnostic).
//!   RG3 — `@Future<>`/`@Iterator<>`/`@Result<i32>` etc.: a required
//!         (non-defaulted) generic argument missing
//!         (`generic-required-arg-missing`, comptime, fires at type-ref
//!         resolution time via `builtinRequiredGenericArgs`).
//!   RG4 — `@Iterator<i32, , i64>`: a middle generic argument skipped while
//!         a later one is provided (`generic-arg-skip-forbidden`, parser).
//!
//! Resolution rules (`comptime/types.zig` default-fill for omitted trailing
//! args) are deferred until F4G compile-side lands; once that ships, the
//! "RG2 — every default supplied" cases below get matching resolution
//! assertions (e.g. `@Future<User>` resolves with E = any).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const ParseErrorType = parserMod.ParseErrorType;
const ParseErrorInfo = parserMod.ParseErrorInfo;
const h = @import("helpers.zig");

// ── parse-time helpers ──────────────────────────────────────────────────────
//
// Mirror `parser/tests/effect_rejections.zig`'s harness so a §1G case can be
// asserted at the parser-error level without touching inference.

fn expectParseKind(src: []const u8, kind: ParseErrorType) !void {
    const alloc = std.testing.allocator;
    var l = Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, src);
    if (p.parse(alloc)) |*prog| {
        var owned = prog.*;
        owned.deinit(alloc);
        return error.TestExpectedParseError;
    } else |_| {
        const pe = p.parseError orelse return error.TestExpectedParseErrorInfo;
        try std.testing.expectEqual(kind, pe.kind);
    }
}

fn expectParseOk(src: []const u8) !void {
    const alloc = std.testing.allocator;
    var l = Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, "");
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    try std.testing.expectEqual(@as(?ParseErrorInfo, null), p.parseError);
}

// ── RG1 — default-before-required (every GenericParamList site) ─────────────

test "§1G RG1 — struct: <T = i32, U> rejected" {
    try expectParseKind(
        \\record Container<T = i32, U>(val item: T)
    , .genericDefaultBeforeRequired);
}

test "§1G RG1 — fn: <A = i32, B> rejected" {
    try expectParseKind(
        \\fn pair<A = i32, B>(a: A, b: B) -> B { return b; }
    , .genericDefaultBeforeRequired);
}

test "§1G RG1 — three params, default-then-default-then-required rejected" {
    try expectParseKind(
        \\fn triple<A, B = string, C>(a: A, b: B, c: C) -> C { return c; }
    , .genericDefaultBeforeRequired);
}

// ── RG2 — every default is legal; trailing-defaulted is legal ───────────────

test "§1G RG2 — every parameter defaulted is accepted" {
    try expectParseOk(
        \\fn triple<T = i32, U = string, V = bool>(a: T, b: U, c: V) -> V { return c; }
    );
}

test "§1G — trailing defaulted parameters are accepted (canonical form)" {
    try expectParseOk(
        \\fn pair<T, U = string>(a: T, b: U) -> U { return b; }
    );
}

test "§1G — defaulted struct trailing param is accepted" {
    try expectParseOk(
        \\val Container = record <T, U = string> { item: T, tag: U };
    );
}

// ── RG3 — required generic argument missing ─────────────────────────────────

test "§1G RG3 — @Future<> rejects (T is required)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@future]
        \\fn empty() -> @Future<> { return 0; }
    );
}

test "§1G RG3 — @Iterator<> rejects (T is required)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@iterator]
        \\fn empty() -> @Iterator<> { break; }
    );
}

test "§1G RG3 — @Result<i32> rejects (E is required, no default)" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\#[@result]
        \\fn parse() -> @Result<i32> { return 0; }
    );
}

// ── RG4 — skipped middle generic argument ───────────────────────────────────

test "§1G RG4 — @Iterator<i32, , i64> rejects (middle slot empty)" {
    try expectParseKind(
        \\fn middle() -> @Iterator<i32, , i64> { return 0; }
    , .genericArgSkipForbidden);
}

test "§1G RG4 — trailing `, >` is also a skipped slot" {
    try expectParseKind(
        \\fn trail() -> @Future<i32, > { return 0; }
    , .genericArgSkipForbidden);
}

test "§1G RG4 — user-defined skip rejected (nominal TypeRef site)" {
    try expectParseKind(
        \\fn p() -> Container<i32, , bool> { return 0; }
    , .genericArgSkipForbidden);
}

// ── Resolution rules ────────────────────────────────────────────────────────
//
// `builtinDefaultFilledArgs` in `comptime/infer.zig` fills omitted trailing
// args with the spec-declared defaults; the resolver builds the full args
// slice and binds the missing positions to `env.namedType(<default>)`.
// These cases assert the fill is observable: the type-checks succeed with no
// error, even though the surface text omits the defaulted positions.

test "§1G resolution — @Future<i32> resolves with E = any (E omitted)" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@future]
        \\fn fetch(id: i64) -> @Future<i32> { return 0; }
    );
}

test "§1G resolution — @Iterator<i32> resolves with E = any, C = void" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@iterator]
        \\fn count(n: i32) -> @Iterator<i32> { yield n; }
    );
}

test "§1G resolution — @Iterator<i32, string> resolves with C = void" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@iterator]
        \\fn run(n: i32) -> @Iterator<i32, string> { yield n; }
    );
}

test "§1G resolution — @Generator<i32> resolves with R = void" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[@generator]
        \\fn range(a: i32) -> @Generator<i32> { yield a; }
    );
}

// ── F4G consumer-threading: user-typeDef defaults ───────────────────────────
//
// `TypeDef.{Record,Struct,Enum}` carries `genericDefaults: []const ?*T.Type`,
// resolved at `registerTypeDef` time against the same generic map the field
// types use; `resolveTypeRefInContext` consumes them in the `.generic` arm
// to fill omitted trailing args at user-typeDef call sites. Parallel to
// `builtinDefaultFilledArgs`; only the source of the default differs.

test "§1G F4G — user record default fills omitted trailing arg" {
    try h.assertInfersOk(std.testing.allocator,
        \\record Container<A, B = string> { primary: A, label: B }
        \\fn make() -> Container<i32> {
        \\    return Container(primary: 0, label: "default");
        \\}
    );
}

test "§1G F4G — user record default with chained-param reference" {
    // A default that references an earlier param (`<T, U = T>`) — the
    // resolver runs each default through the same `genericMap` the field
    // types use, so `U` binds to `T`'s fresh var; the literal then
    // instantiates both to the same concrete type.
    try h.assertInfersOk(std.testing.allocator,
        \\record Sym<T, U = T> { left: T, right: U }
        \\fn pair() -> Sym<i32> {
        \\    return Sym(left: 1, right: 2);
        \\}
    );
}

test "§1G F4G — user enum default fills omitted trailing arg" {
    // The enum variant constructor's return type carries the enum's generic
    // cells (`Result2<T_cell, E_cell>`), so `Result2.Yes(value: 42)` pins
    // T_cell = i32 and stays bare on E_cell — at the fn-return unification,
    // the annotation `Result2<i32>` resolves to `Result2<i32, string>` via
    // the registered default, the unifier matches arity, and E_cell gets
    // pinned to `string` via a single fresh-var <-> string unification.
    try h.assertInfersOk(std.testing.allocator,
        \\enum Result2<T, E = string> { Yes(value: T), No(message: E) }
        \\fn pick() -> Result2<i32> {
        \\    return Result2.Yes(value: 42);
        \\}
    );
}

test "§1G F4G — user enum default with chained-param reference" {
    // `<T, U = T>` enum: default references an earlier param, so the variant
    // payload's `U` cell binds to the same fresh var as `T` at registration
    // time. The annotation `Sym2<i32>` resolves the default, pinning both
    // slots to i32 via a single arity-matching unification.
    try h.assertInfersOk(std.testing.allocator,
        \\enum Sym2<T, U = T> { L(value: T), R(value: U) }
        \\fn left() -> Sym2<i32> {
        \\    return Sym2.L(value: 7);
        \\}
    );
}
