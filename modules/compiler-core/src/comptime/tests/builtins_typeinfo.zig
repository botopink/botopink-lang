//! comptime: type introspection builtins tests (§1.0.0-beta)
//!
//! Tests the `@typeInfo`, `@TypeOf`, `@makeRecord`, `@RecordKeys`, and `@Field`
//! builtins at the inference level. Since these are comptime-only builtins, the
//! tests verify correct type resolution and error handling during inference.
//! Full comptime evaluation tests are deferred to the codegen test gap spec.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const prettyMod = @import("../../utils/pretty.zig");
const T = @import(".././types.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const comptimeMod = @import("../../comptime.zig");
const errorMod = @import("../error.zig");
const snapshot = @import("../snapshot.zig");
const Module = @import("../../module.zig").Module;
const format = @import("../../format.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;
const h = @import("helpers.zig");

// ── @typeInfo basic inference ────────────────────────────────────────────────

test "typeInfo: primitive i32 returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val info = @typeInfo(i32);
    );
}

test "typeInfo: primitive string returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val info = @typeInfo(string);
    );
}

test "typeInfo: primitive bool returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val info = @typeInfo(bool);
    );
}

test "typeInfo: void type returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val info = @typeInfo(void);
    );
}

test "typeInfo: record type returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = record { x: i32, y: string };
        \\val info = @typeInfo(Point);
    );
}

test "typeInfo: enum type returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum { Red, Blue };
        \\val info = @typeInfo(Color);
    );
}

test "typeInfo: fn type returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn add(a: i32, b: i32) -> i32 { return a + b; }
        \\val info = @typeInfo(add);
    );
}

test "typeInfo: float type returns TypeInfo" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val info = @typeInfo(f64);
    );
}

// ── @TypeOf basic inference ───────────────────────────────────────────────────

test "TypeOf: integer literal returns i32" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val answer: i32 = 42;
        \\val AnswerType = @TypeOf(answer);
    );
}

test "TypeOf: string literal returns string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val greeting = "hello";
        \\val GreetingType = @TypeOf(greeting);
    );
}

test "TypeOf: record value returns record type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val p = record { x: 1, y: 2 };
        \\val PType = @TypeOf(p);
    );
}

test "TypeOf: fn binding returns fn type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn identity(x: i32) -> i32 { return x; }
        \\val FnType = @TypeOf(identity);
    );
}

// ── @makeRecord basic inference ───────────────────────────────────────────────

test "makeRecord: single field returns record type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val fields: RecordField[] = [RecordField(name: "a", typeName: "i32")];
        \\val Rec = @makeRecord(fields);
    );
}

test "makeRecord: multiple fields returns record type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val fields: RecordField[] = [
        \\    RecordField(name: "x", typeName: "i32"),
        \\    RecordField(name: "y", typeName: "i32"),
        \\];
        \\val Point = @makeRecord(fields);
    );
}

// ── @RecordKeys basic inference ───────────────────────────────────────────────

test "RecordKeys: record type returns string array" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = record { x: i32, y: string };
        \\val keys = @RecordKeys(Point);
    );
}

test "RecordKeys: single field record returns string array" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Box = record { value: i32 };
        \\val keys = @RecordKeys(Box);
    );
}

// ── @Field basic inference ────────────────────────────────────────────────────

test "field: record value field access" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val p = record { x: 1, y: 2 };
        \\val xVal = @field(p, "x");
    );
}

// ── TypeInfo, RecordField, EnumVariant are known types ───────────────────────

test "typeInfo: TypeInfo enum is a known type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val ti: TypeInfo = TypeInfo.Int;
    );
}

test "typeInfo: RecordField is a known type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val rf = RecordField(name: "x", typeName: "i32");
    );
}

test "typeInfo: EnumVariant is a known type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val ev = EnumVariant(name: "Red", fields: []);
    );
}

test "typeInfo: TypeInfoKind is a known type" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val kind: TypeInfoKind = TypeInfoKind.Int;
    );
}

// ── @comptimeError ──────────────────────────────────────────────────────────

test "comptimeError: string literal raises custom error" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val err = @comptimeError("field x not found");
    );
}

// ── mergeRecords ────────────────────────────────────────────────────────────

test "mergeRecords: disjoint records merge correctly" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record User { name: string, id: i32 }
        \\record Timestamps { createdAt: string, updatedAt: string }
        \\val Merged = mergeRecords(User, Timestamps);
    );
}

test "mergeRecords: same-name same-type deduplicates" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record A { x: i32, y: string }
        \\record B { x: i32, z: bool }
        \\val Merged = mergeRecords(A, B);
    );
}

test "mergeRecords: conflict raises error" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record A { x: i32 }
        \\record B { x: string }
        \\val Merged = mergeRecords(A, B);
    );
}

// ── partial ─────────────────────────────────────────────────────────────────

test "partial: record fields become optional" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record Config { port: i32, host: string }
        \\val PartialCfg = partial(Config);
    );
}

test "partial: empty record works" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record Empty {}
        \\val PartialE = partial(Empty);
    );
}

// ── omit ────────────────────────────────────────────────────────────────────

test "omit: remove a single field" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record FullUser { id: i32, name: string, password: string }
        \\val PublicUser = omit(FullUser, "password");
    );
}

test "omit: non-existent field raises error" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record User { id: i32 }
        \\val NoField = omit(User, "email");
    );
}

// ── pick ────────────────────────────────────────────────────────────────────

test "pick: keep specified fields" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\record FullUser { id: i32, name: string, password: string }
        \\val NameOnly = pick(FullUser, ["name", "id"]);
    );
}

test "pick: field email not found raises type error" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\record User { id: i32, name: string }
        \\val BadPick = pick(User, ["email"]);
    );
}
