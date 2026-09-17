//! parser: the 1.0.3 surface — `type`, `behavior`, the shared field list and
//! the member separators (front 12 step 2, dual grammar). The acceptance cases
//! of specs/1.0.4-beta/12-surface-cutover/type-grammar.md, behavior.md and
//! separators.md that do not involve a removed keyword. During the dual grammar
//! the old and the new spelling of a declaration must build the same AST, so
//! several tests compare the two JSON dumps directly.

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ast = @import("../../ast.zig");
const pretty = @import("../../utils/pretty.zig");
const receiver_marker = @import("../../comptime/primOpTemplate.zig").receiver_marker;

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

/// The parse fails with `kind`, located at `line:col` (1-based).
fn expectError(src: []const u8, kind: ParseErrorType, line: usize, col: usize) !void {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const a = arena.allocator();
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(a);
    var p = parserMod.Parser.initWithSource(tokens, src);
    if (p.parse(a)) |_| return error.TestExpectedParseError else |_| {}
    const pe = p.parseError orelse return error.TestParseErrorInfoMissing;
    try std.testing.expectEqual(kind, pe.kind);
    try std.testing.expectEqual([2]usize{ line, col }, [2]usize{ pe.line, pe.col });
}

/// The old and the new spelling parse to the same AST (same JSON dump).
fn expectSameAst(old: []const u8, new: []const u8) !void {
    var po = try parse(old);
    defer po.deinit();
    var pn = try parse(new);
    defer pn.deinit();
    const jo = try pretty.formatAlloc(std.testing.allocator, po.program);
    defer std.testing.allocator.free(jo);
    const jn = try pretty.formatAlloc(std.testing.allocator, pn.program);
    defer std.testing.allocator.free(jn);
    try std.testing.expectEqualStrings(jo, jn);
}

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

// ── old and new spelling: the same nodes ──────────────────────────────────────

test "surface: record and type build the same AST" {
    try expectSameAst(
        \\record Point { x: i32, y: i32,
        \\fn sum(self: Self) -> i32 { return self.x + self.y; } }
    ,
        \\type Point(x: i32, y: i32) {
        \\fn sum(self: Self) -> i32 { return self.x + self.y; } }
    );
}

test "surface: enum and type build the same AST" {
    try expectSameAst(
        \\enum Shape { Circle(radius: f64), Square(side: f64) }
    ,
        \\type Shape { Circle(radius: f64), Square(side: f64) }
    );
}

test "surface: interface and behavior build the same AST" {
    try expectSameAst(
        \\interface Printable { fn print(self: Self) -> string; }
    ,
        \\behavior Printable { fn print(self: Self) -> string; }
    );
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

test "surface: old interface bodies keep their lenient separators" {
    var parsed = try parse("interface B { fn f(self: Self) -> i32, fn g(self: Self) -> i32 }");
    defer parsed.deinit();
    const b = try onlyBehavior(parsed);
    try std.testing.expectEqual(@as(usize, 2), b.methods.len);
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
