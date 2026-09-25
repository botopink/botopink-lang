//! parser: the 1.0.3 surface — `type`, `behavior`, the shared field list and
//! the member separators (front 12 step 2, dual grammar). The acceptance cases
//! of specs/1.0.4-beta/12-surface-cutover/type-grammar.md, behavior.md and
//! separators.md, and the targeted diagnostics of the removed 1.0.2 keywords
//! (front 12 step 4).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ast = @import("../../ast.zig");
const pretty = @import("../../utils/pretty.zig");
const receiver_marker = @import("../../comptime/primOpTemplate.zig").receiver_marker;
const printMod = @import("../../print.zig");

const ParseErrorType = parserMod.ParseErrorType;

const Parsed = struct {
    arena: std.heap.ArenaAllocator,
    program: ast.Program,

    fn deinit(this: *Parsed) void {
        this.arena.deinit();
    }
};

fn parse(src: []const u8) !Parsed {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    errdefer arena.deinit();
    const a = arena.allocator();
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(a);
    var p = parserMod.Parser.initWithSource(tokens, src);
    const program = p.parse(a) catch |err| {
        if (p.parseError) |pe| std.debug.print("\nunexpected parse error {s} at {d}:{d}\n", .{ @tagName(pe.kind), pe.line, pe.col });
        return err;
    };
    return .{ .arena = arena, .program = program };
}

fn onlyType(parsed: Parsed) !ast.TypeDecl {
    try std.testing.expectEqual(@as(usize, 1), parsed.program.decls.len);
    try std.testing.expect(parsed.program.decls[0] == .type_);
    return parsed.program.decls[0].type_;
}

fn onlyBehavior(parsed: Parsed) !ast.BehaviorDecl {
    try std.testing.expectEqual(@as(usize, 1), parsed.program.decls.len);
    try std.testing.expect(parsed.program.decls[0] == .behavior);
    return parsed.program.decls[0].behavior;
}

/// The parse fails with `kind`, located at `line:col` (1-based) — the shared
/// harness `helpers.expectErrorAt`.
const expectError = @import("helpers.zig").expectErrorAt;

// ── type: shape resolution ────────────────────────────────────────────────────

test "surface: type Point(x, y) is a record with no body" {
    var parsed = try parse("type Point(x: i32, y: i32)");
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expect(t.isRecord());
    try std.testing.expectEqual(@as(usize, 2), t.recordFields().len);
    try std.testing.expectEqualStrings("y", t.recordFields()[1].name);
    try std.testing.expectEqual(@as(usize, 0), t.methods.len);
    try std.testing.expect(!t.trailingComma);
}

test "surface: type Stack<T>(items) with a method is a generic record" {
    var parsed = try parse(
        \\type Stack<T>(items: T[]) {
        \\    pub fn size(self: Self) -> i32 {
        \\        return self.items.length;
        \\    }
        \\}
    );
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expect(t.isRecord());
    try std.testing.expectEqual(@as(usize, 1), t.genericParams.len);
    try std.testing.expectEqual(@as(usize, 1), t.methods.len);
    try std.testing.expect(t.methods[0].isPub);
}

test "surface: type Element(tag) implement @Context<…> {} keeps the implement clause" {
    var parsed = try parse("type Element(tag: string) implement @Context<Element, Element> { }");
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expect(t.isRecord());
    try std.testing.expectEqual(@as(usize, 1), t.implement.len);
}

test "surface: a field list keeps comments, annotations, defaults and the trailing comma" {
    var parsed = try parse(
        \\type Config(
        \\    // where the server listens
        \\    #[value("k")] host: string = "0.0.0.0",
        \\    port: i32,
        \\)
    );
    defer parsed.deinit();
    const t = try onlyType(parsed);
    const fields = t.recordFields();
    try std.testing.expectEqual(@as(usize, 2), fields.len);
    try std.testing.expectEqual(@as(usize, 1), fields[0].comments.len);
    try std.testing.expectEqualStrings("where the server listens", fields[0].comments[0]);
    try std.testing.expectEqual(@as(usize, 1), fields[0].annotations.len);
    try std.testing.expectEqualStrings("value", fields[0].annotations[0].name);
    try std.testing.expect(fields[0].default != null);
    try std.testing.expect(t.trailingComma);
}

test "surface: type Order { Lt, Eq, Gt } is an enum" {
    var parsed = try parse("type Order { Lt, Eq, Gt }");
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expect(!t.isRecord());
    try std.testing.expectEqual(@as(usize, 3), t.variants().len);
}

test "surface: an enum with payload variants and a method" {
    var parsed = try parse(
        \\type Shape {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\    pub fn area(self: Self) -> f64 {
        \\        return 0.0;
        \\    }
        \\}
    );
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expect(!t.isRecord());
    try std.testing.expectEqual(@as(usize, 2), t.variants().len);
    try std.testing.expectEqualStrings("radius", t.variants()[0].fields[0].name);
    try std.testing.expectEqual(@as(usize, 1), t.methods.len);
}

test "surface: an enum with sections" {
    var parsed = try parse(
        \\type Token {
        \\    Color {
        \\        Red { 100, 500 },
        \\        Hex(value: string),
        \\    }
        \\    Hover(inner: Token[]),
        \\}
    );
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expect(!t.isRecord());
    try std.testing.expectEqual(@as(usize, 1), t.sections().len);
    try std.testing.expectEqual(@as(usize, 1), t.variants().len);
}

test "surface: type MathOps { methods } is a record with no fields" {
    var parsed = try parse(
        \\type MathOps {
        \\    pub fn add(a: i32, b: i32) -> i32 {
        \\        return a + b;
        \\    }
        \\}
    );
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expect(t.isRecord());
    try std.testing.expectEqual(@as(usize, 0), t.recordFields().len);
    try std.testing.expectEqual(@as(usize, 1), t.methods.len);
}

test "surface: val Dict = type<K, V>(pairs) { … } is a val-form generic record" {
    var parsed = try parse(
        \\val Dict = type<K, V>(pairs: Array<#(K, V)>) {
        \\    pub fn size(self: Self) -> i32 {
        \\        return self.pairs.length;
        \\    }
        \\}
    );
    defer parsed.deinit();
    const t = try onlyType(parsed);
    try std.testing.expectEqualStrings("Dict", t.name);
    try std.testing.expect(t.isRecord());
    try std.testing.expectEqual(@as(usize, 2), t.genericParams.len);
}

test "surface: comptime T: type and -> type still name the kind of types" {
    var parsed = try parse(
        \\fn same(comptime T: type) -> type {
        \\    return T;
        \\}
    );
    defer parsed.deinit();
    try std.testing.expect(parsed.program.decls[0] == .@"fn");
}

// ── type: diagnostics ─────────────────────────────────────────────────────────

test "surface: a field list and a variant together are type-record-with-variants" {
    try expectError("type P(x: i32) { A }", .typeRecordWithVariants, 1, 18);
}

test "surface: an empty field list is an error" {
    try expectError("type P()", .typeEmptyFieldList, 1, 7);
}

test "surface: a variant after a method is type-variant-after-method" {
    try expectError("type S { fn f(self: Self) {} A }", .typeVariantAfterMethod, 1, 30);
}

test "surface: a val prefix in a field list is type-field-val-prefix" {
    try expectError("type P(val x: i32)", .typeFieldValPrefix, 1, 8);
}

test "surface: two variants need a comma between them" {
    try expectError("type Order { Lt Eq }", .unexpectedToken, 1, 17);
}

test "surface: a comma after a type method is member-comma-separator" {
    try expectError("type S { A, fn f(self: Self) {}, }", .memberCommaSeparator, 1, 32);
}

// ── the removed 1.0.2 surface ─────────────────────────────────────────────────

test "surface: record Point { … } is removed-keyword-record at the keyword" {
    try expectError("record Point { x: i32 }", .removedKeywordRecord, 1, 1);
    try expectError("pub record Point { x: i32 }", .removedKeywordRecord, 1, 5);
    try expectError("#[service] record Point { x: i32 }", .removedKeywordRecord, 1, 12);
    try expectError("val Point = record { x: i32 }", .removedKeywordRecord, 1, 13);
}

test "surface: enum E { A } is removed-keyword-enum at the keyword" {
    try expectError("enum E { A }", .removedKeywordEnum, 1, 1);
    try expectError("pub enum E<T> { A(v: T) }", .removedKeywordEnum, 1, 5);
    try expectError("val E = enum { A, B }", .removedKeywordEnum, 1, 9);
}

test "surface: interface I {} is removed-keyword-interface at the keyword" {
    try expectError("interface I {}", .removedKeywordInterface, 1, 1);
    try expectError("#[mock] interface I { fn f(self: Self) -> i32; }", .removedKeywordInterface, 1, 9);
    try expectError("val I = interface { }", .removedKeywordInterface, 1, 9);
    try expectError("val Cb = interface fn(x: i32);", .removedKeywordInterface, 1, 10);
}

test "surface: record { x: 1 } is removed-record-literal" {
    try expectError("val p = record { x: 1 }", .removedRecordLiteral, 1, 9);
    try expectError("fn f() { val p = record { x: 1 }; }", .removedRecordLiteral, 1, 18);
    try expectError("fn f() { g(record { x: 1 }); }", .removedRecordLiteral, 1, 12);
}

test "surface: fn f(p: { x: i32 }) is removed-record-type" {
    try expectError("fn f(p: { x: i32 }) {}", .removedRecordType, 1, 9);
    try expectError("fn f() -> { x: i32 } { }", .removedRecordType, 1, 11);
}

test "surface: record, enum and interface are ordinary identifiers elsewhere" {
    var parsed = try parse(
        \\val record = 1;
        \\val enum = 2;
        \\fn interface(x: i32) -> i32 { return x + record + enum; }
    );
    defer parsed.deinit();
    try std.testing.expectEqual(@as(usize, 3), parsed.program.decls.len);
}

test "surface: a removed-keyword diagnostic renders its code, the location and the 1.0.3 spelling" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    const src = "record Point { x: i32 }";
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(a);
    var p = parserMod.Parser.initWithSource(tokens, src);
    if (p.parse(a)) |_| return error.TestExpectedParseError else |_| {}
    var out: std.Io.Writer.Allocating = .init(a);
    try printMod.render(&out.writer, p.parseError.?, src, "main.bp");
    const text = out.written();
    try std.testing.expect(std.mem.indexOf(u8, text, "error[removed-keyword-record]") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "--> main.bp:1:1") != null);
    try std.testing.expect(std.mem.indexOf(u8, text, "type Name(fields)") != null);
}

// ── behavior ──────────────────────────────────────────────────────────────────

test "surface: behavior Printable parses to a BehaviorDecl" {
    var parsed = try parse("behavior Printable { fn print(self: Self) -> string; }");
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    try std.testing.expectEqualStrings("Printable", b.name);
    try std.testing.expectEqual(@as(usize, 1), b.methods.len);
}

test "surface: behavior with extends and a default method" {
    var parsed = try parse(
        \\behavior Integer extends Number {
        \\    default fn isEven(self: Self) -> bool {
        \\        return self % 2 == 0;
        \\    }
        \\}
    );
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    try std.testing.expectEqual(@as(usize, 1), b.extends.len);
    try std.testing.expect(b.methods[0].is_default);
}

test "surface: an annotated behavior keeps its annotation" {
    var parsed = try parse("#[mock] behavior UserRepo { fn find(self: Self, id: i32) -> string; }");
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    try std.testing.expectEqual(@as(usize, 1), b.annotations.len);
    try std.testing.expectEqualStrings("mock", b.annotations[0].name);
}

test "surface: val Drawable = behavior { … } is the val-form" {
    var parsed = try parse("val Drawable = behavior { fn draw(self: Self); }");
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    try std.testing.expectEqualStrings("Drawable", b.name);
}

test "surface: behavior generics may follow the name" {
    var parsed = try parse("behavior Stack<T> { fn push(self: Self, item: T); }");
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    try std.testing.expectEqual(@as(usize, 1), b.genericParams.len);
}

// ── separators ────────────────────────────────────────────────────────────────

test "surface: a comma after a behavior member is member-comma-separator" {
    try expectError("behavior B { fn f(self: Self) -> i32, }", .memberCommaSeparator, 1, 37);
}

test "surface: a bodyless behavior member without ; is member-missing-semicolon" {
    try expectError("behavior B { fn f(self: Self) -> i32 }", .memberMissingSemicolon, 1, 34);
}

test "surface: val fields, signatures and default methods with the separator rule" {
    var parsed = try parse(
        \\behavior B {
        \\    val x: i32;
        \\    fn f(self: Self) -> i32;
        \\    default fn g(self: Self) -> i32 {
        \\        return 1;
        \\    }
        \\}
    );
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    try std.testing.expectEqual(@as(usize, 1), b.fields.len);
    try std.testing.expectEqual(@as(usize, 2), b.methods.len);
}

test "surface: a behavior member separated by a comma is member-comma-separator" {
    try expectError("behavior B { fn f(self: Self) -> i32, fn g(self: Self) -> i32; }", .memberCommaSeparator, 1, 37);
}

// ── template markers (decision 5) ─────────────────────────────────────────────

test "surface: $self in an External template is template-self-marker" {
    try expectError(
        \\behavior S {
        \\    #[@External.Erlang("string:trim($self)")]
        \\    fn trim(self: Self) -> Self;
        \\}
    , .templateSelfMarker, 2, 24);
}

test "surface: a marker past the declared parameters is template-marker-out-of-range" {
    try expectError(
        \\#[@External.Node("f($0, $1)")]
        \\declare fn one(x: i32) -> i32;
    , .templateMarkerOutOfRange, 1, 18);
}

test "surface: a method's $0 is self and $1 its first argument" {
    var parsed = try parse(
        \\behavior S {
        \\    #[@External.Erlang("lists:member($1, $0)")]
        \\    fn has(self: Self, x: i32) -> bool;
        \\}
    );
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    const ann = b.methods[0].annotations[0];
    try std.testing.expectEqualStrings("\"lists:member($1, $0)\"", ann.writtenArgs()[0]);
    try std.testing.expectEqualStrings("\"lists:member($0, " ++ receiver_marker ++ ")\"", ann.args[0]);
}

// ── decision 8 §10 and 06 N27 ────────────────────────────────────────────────

test "surface: while (…) is removed-keyword-while at `while`" {
    try expectError("fn f() { while (true) { }; }", .removedKeywordWhile, 1, 10);
}

test "surface: throw new Error(…) is removed-keyword-new at `new`" {
    try expectError("fn f() { throw new Error(\"x\"); }", .removedKeywordNew, 1, 16);
}

// ── front 17, decision 38: the annotated binding takes the plain form only ────

test "surface: an annotated `val` shorthand is refused at the annotation" {
    // `val add = fn …` is a `fn` declaration in a `val` coat; the annotation
    // would have nowhere to land, so the form is refused where it starts.
    try expectError("#[@BeamMemory.Ets]\nval add = fn(x: i32) -> i32 { return x; }", .unexpectedToken, 1, 1);
    try expectError("#[@BeamMemory.Ets] pub val add = fn(x: i32) -> i32 { return x; }", .unexpectedToken, 1, 1);
}

test "surface: `var` takes no shorthand — `var add = fn …` is not a fn declaration" {
    var parsed = try parse(
        \\var hits: i32 = 0;
        \\#[@BeamMemory.PersistentTerm]
        \\pub var version = 101;
    );
    defer parsed.deinit();
    try std.testing.expectEqual(@as(usize, 2), parsed.program.decls.len);
    try std.testing.expect(parsed.program.decls[0].val.mutable);
    try std.testing.expect(parsed.program.decls[1].val.mutable);
    try std.testing.expect(parsed.program.decls[1].val.isPub);
    try std.testing.expectEqual(@as(usize, 1), parsed.program.decls[1].val.annotations.len);
}

test "surface: new, delegate and const are ordinary identifiers" {
    var parsed = try parse(
        \\val new = 1;
        \\val delegate = 2;
        \\val const = 3;
    );
    defer parsed.deinit();
    try std.testing.expectEqual(@as(usize, 3), parsed.program.decls.len);
}

test "surface: loop (condition) and loop { … } parse with no parameter" {
    var parsed = try parse(
        \\fn f() {
        \\    var i = 0;
        \\    loop (i < 3) { i = i + 1; };
        \\    loop { i = i + 1; break; };
        \\}
    );
    defer parsed.deinit();
    try std.testing.expectEqual(@as(usize, 1), parsed.program.decls.len);
}
