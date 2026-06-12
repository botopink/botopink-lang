//! Parser-level effect-annotation rejections (frente-b-rules-tooling §2):
//! R1 — `#[@<effect>] declare fn …` — effect-on-declare-forbidden.
//! R2 — `interface I { #[@<effect>] fn … }` — effect-on-interface-method-forbidden.
//! R5 — duplicate `#[@<effect>]` annotations — effect-duplicate-annotation.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const ParseErrorType = parserMod.ParseErrorType;
const ParseErrorInfo = parserMod.ParseErrorInfo;

fn expectKind(src: []const u8, kind: ParseErrorType) !void {
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

test "R1 — #[@result] declare fn rejected at parse" {
    try expectKind(
        \\#[@result]
        \\pub declare fn parse(n: i32) -> @Result<i32, string>;
    , .effectOnDeclareForbidden);
}

test "R1 — bare #[@future] declare fn rejected at parse" {
    try expectKind(
        \\#[@future]
        \\declare fn fetch() -> @Future<i32>;
    , .effectOnDeclareForbidden);
}

test "R1 §A3 — #[@future] declare fn with @external accepted at parse" {
    const alloc = std.testing.allocator;
    var l = Lexer.init(
        \\#[@future]
        \\#[@External.node(when(argc == 1): """fetch($0)""")]
        \\pub declare fn fetch(url: string) -> @Future<i32>;
    );
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, "");
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    try std.testing.expectEqual(@as(?parserMod.ParseErrorInfo, null), p.parseError);
}

test "R2 — #[@future] inside interface method rejected" {
    try expectKind(
        \\val AsyncSource = interface {
        \\    #[@future]
        \\    fn next(self: Self) -> @Future<i32>
        \\}
    , .effectOnInterfaceMethodForbidden);
}

test "R2 — #[@result] on default interface method rejected" {
    try expectKind(
        \\val Parser = interface {
        \\    #[@result]
        \\    default fn parse(self: Self) -> @Result<i32, string> { return 0; }
        \\}
    , .effectOnInterfaceMethodForbidden);
}

test "R5 — two effect markers on one fn rejected" {
    try expectKind(
        \\#[@result]
        \\#[@future]
        \\fn bad() -> @Future<i32> {
        \\    return 0;
        \\}
    , .effectDuplicateAnnotation);
}

test "R5 — three effect markers also red" {
    try expectKind(
        \\#[@result]
        \\#[@future]
        \\#[@generator]
        \\fn bad() -> @Generator<i32> { return 0; }
    , .effectDuplicateAnnotation);
}

test "RI6 — legacy `yield break <expr>` is rejected at parse" {
    try expectKind(
        \\#[@iterator]
        \\fn it() -> @Iterator<i32, string, i32> {
        \\    yield break 0;
        \\}
    , .yieldBreakRemoved);
}

test "RI6 — bare `yield break` is also rejected" {
    try expectKind(
        \\#[@generator]
        \\fn g() -> @Generator<i32> {
        \\    yield break;
        \\}
    , .yieldBreakRemoved);
}

test "RG1 — record with default before required is rejected" {
    try expectKind(
        \\record Container<T = i32, U>(val item: T)
    , .genericDefaultBeforeRequired);
}

test "RG1 — fn with default before required is rejected" {
    try expectKind(
        \\fn pair<A = i32, B>(a: A, b: B) -> B { return b; }
    , .genericDefaultBeforeRequired);
}

test "RG1 — defaulted trailing parameters are accepted" {
    const alloc = std.testing.allocator;
    var l = Lexer.init(
        \\fn pair<T, U = string>(a: T, b: U) -> U { return b; }
    );
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, "");
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    try std.testing.expectEqual(@as(?parserMod.ParseErrorInfo, null), p.parseError);
}

test "RG1 — every parameter defaulted is accepted" {
    const alloc = std.testing.allocator;
    var l = Lexer.init(
        \\fn triple<T = i32, U = string, V = bool>(a: T, b: U, c: V) -> V { return c; }
    );
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);

    var p = Parser.initWithSource(tokens, "");
    var prog = try p.parse(alloc);
    defer prog.deinit(alloc);
    try std.testing.expectEqual(@as(?parserMod.ParseErrorInfo, null), p.parseError);
}

test "RG4 — `@Iterator<i32, , i64>` rejected at parse" {
    try expectKind(
        \\fn middle() -> @Iterator<i32, , i64> { return 0; }
    , .genericArgSkipForbidden);
}

test "RG4 — trailing `,>` is also a skipped slot" {
    try expectKind(
        \\fn trail() -> @Future<i32, > { return 0; }
    , .genericArgSkipForbidden);
}

test "RG4 — user-defined generic skip is rejected" {
    try expectKind(
        \\fn p() -> Container<i32, , bool> { return 0; }
    , .genericArgSkipForbidden);
}
