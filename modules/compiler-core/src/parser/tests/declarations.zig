//! parser: struct/record/enum/interface/implement, val/pub/fn (split from tests.zig).

const std = @import("std");
const snapMod = @import("../../utils/snap.zig");
const Allocator = std.mem.Allocator;
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../../print.zig");
const h = @import("helpers.zig");

test "parser: empty program" {
    try h.assertParser(std.testing.allocator, @src(), "");
}

test "parser: whitespace-only source" {
    try h.assertParser(std.testing.allocator, @src(), "   \t\n  ");
}

test "parser: empty interface" {
    try h.assertParser(std.testing.allocator, @src(), "val Drawable = interface {}");
}

test "parser: #[@future] annotation sets FnDecl.effect" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var lx = Lexer.init("#[@future]\nfn f() -> @Future<i32> { return 0; }");
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = try p.parse(alloc);
    try std.testing.expect(program.decls.len == 1);
    try std.testing.expect(program.decls[0] == .@"fn");
    try std.testing.expectEqual(ast.EffectKind.future, program.decls[0].@"fn".effect.?);
}

test "parser: deprecated *fn derives effect from the return wrapper" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var lx = Lexer.init("*fn f() -> @Iterator<i32> { yield 1; }");
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = try p.parse(alloc);
    try std.testing.expectEqual(ast.EffectKind.iterator, program.decls[0].@"fn".effect.?);
}

test "parser: a plain fn has no effect" {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var lx = Lexer.init("fn f() -> i32 { return 0; }");
    const tokens = try lx.scanAll(alloc);
    var p = Parser.init(tokens);
    const program = try p.parse(alloc);
    try std.testing.expect(program.decls[0].@"fn".effect == null);
}

test "parser: interface with one field" {
    try h.assertParser(std.testing.allocator, @src(), "val Drawable = interface { val color: string }");
}

test "parser: abstract method with 1 param (self: Self)" {
    try h.assertParser(std.testing.allocator, @src(), "val Drawable = interface { fn draw(self: Self) }");
}

test "parser: abstract method with multiple params" {
    try h.assertParser(std.testing.allocator, @src(), "val Positionable = interface { fn moveTo(self: Self, x: i32, y: i32) }");
}

test "parser: interface with methods of varying param counts" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self)
        \\    fn drawLine(self: Self, x1: i32, y1: i32)
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string)
        \\}
    );
}

test "parser: full Drawable interface (field + abstract + default method)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\}
    );
}

test "parser: empty struct" {
    try h.assertParser(std.testing.allocator, @src(), "val Account = struct {}");
}

test "parser: struct with one field" {
    try h.assertParser(std.testing.allocator, @src(), "val Account = struct { _balance: number = 0 }");
}

test "parser: struct with field and default" {
    try h.assertParser(std.testing.allocator, @src(), "val Config = struct { host: string = \"localhost\" }");
}

test "parser: struct with a simple getter" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\}
    );
}

test "parser: struct with a setter that throws" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        throw Error(msg: "Saldo nao pode ser negativo");
        \\    }
        \\}
    );
}

test "parser: setter with assign" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\}
    );
}

test "parser: struct with a fn method (deposit)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\}
    );
}

test "parser: full Account struct (private field + getter + setter + method)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\}
    );
}

test "parser: struct with inline implement single interface" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val AuthState = struct implement Drawable {}
    );
}

test "parser: struct with inline implement builtin generic" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val AuthState = struct implement @Context<Element, AuthState> {}
    );
}

test "parser: struct with inline implement multiple interfaces" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Widget = struct implement Drawable, @Context<Element, Widget> {}
    );
}

test "parser: struct implement with array-typed field" {
    // G5: an array-typed (suffixed) field inside an inline `struct implement`
    // body must parse, just like a plain record field.
    try h.assertParser(std.testing.allocator, @src(),
        \\val E = struct implement @Context<E, E> { tag: string, children: E[] }
    );
}

test "parser: implement generic interface for type" {
    // G6: a standalone `implement <generic-iface> for <Type>` must parse, both
    // for a builtin generic (`@Context<…>`) and a user generic (`Foo<A, B>`).
    try h.assertParser(std.testing.allocator, @src(),
        \\record E { tag: string }
        \\val C = implement @Context<E, E> for E {}
        \\val D = implement Foo<E, E> for E {}
    );
}

test "parser: enum with inline implement" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Color = enum implement Printable { Red, Green, Blue }
    );
}

test "parser: record with inline implement" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Point = record implement Serializable { x: number, y: number }
    );
}

test "parser: empty record (no fields, no methods)" {
    try h.assertParser(std.testing.allocator, @src(), "val Point = record {}");
}

test "parser: record with two fields and no methods" {
    try h.assertParser(std.testing.allocator, @src(), "val Point = record { x: number, y: number }");
}

test "parser: record with one method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Point = record {
        \\    x: number,
        \\    fn show(self: Self) {
        \\        return self.x;
        \\    }
        \\}
    );
}

test "parser: full GPSCoordinates record (two fields + toString method)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    pub fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "parser: record with declare fn (abstract method declaration)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = record {
        \\    value: string,
        \\    declare fn foo(self: Self);
        \\}
    );
}

test "parser: struct with declare fn (abstract method declaration)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    fn deposit(self: Self) {}
        \\    declare fn withdraw(self: Self) -> number;
        \\}
    );
}

test "parser: enum with declare fn (abstract method declaration)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    declare fn label(self: Self) -> string;
        \\}
    );
}

test "parser: implement with one interface and one unqualified method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Myimplement = implement Drawable for Circle {
        \\    fn draw(self: Self) {}
        \\}
    );
}

test "parser: implement with two interfaces and qualified methods" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Conectar(self: Self) {
        \\        Console.WriteLine("Conectado via USB. Bateria atual: " + self.batteryLevel);
        \\    }
        \\    fn SolarCharger.Conectar(self: Self) {
        \\        Console.WriteLine("Conectado via Painel Solar. Bateria atual: " + self.batteryLevel);
        \\    }
        \\}
    );
}

test "parser: interface with multiple abstract methods (Canvas)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self),
        \\    fn drawLine(self: Self, x1: i32, y1: i32),
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string),
        \\}
    );
}

test "parser: struct with private field, getter, setter with throw, and method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\    set balance(self: Self, value: number) {
        \\        throw Error(msg: "Balance cannot be negative");
        \\    }
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\}
    );
}

test "parser: record with two fields and a toString method" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "parser: implement single interface with method body" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        @print("Drawing circle");
        \\    }
        \\}
    );
}

test "parser: implement two interfaces with qualified method disambiguation" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Connect(self: Self) {
        \\        @print("Connected via USB. Battery level: " + self.batteryLevel);
        \\    }
        \\    fn SolarCharger.Connect(self: Self) {
        \\        @print("Connected via Solar Panel. Battery level: " + self.batteryLevel);
        \\    }
        \\}
    );
}

test "parser: implement shorthand named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\PatoNada implement Nada for Pato {
        \\    fn swim(self: Self) {}
        \\}
    );
}

test "parser: implement shorthand named pub" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub PatoNada implement Nada for Pato {
        \\    fn swim(self: Self) {}
        \\}
    );
}

test "parser: extend shorthand named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\PatoExtra extend Pato {
        \\    fn quack(self: Self) {}
        \\}
    );
}

test "parser: extend explicit named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val PatoExtra = extend Pato {
        \\    fn quack(self: Self) {}
        \\}
    );
}

test "parser: initWithSource stores the source" {
    var l = lexerMod.Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);

    const p = parserMod.Parser.initWithSource(tokens, "const x = 1");
    try std.testing.expect(p.source != null);
    try std.testing.expectEqualStrings("const x = 1", p.source.?);
}

test "parser: init has null source" {
    var l = lexerMod.Lexer.init("");
    const tokens = try l.scanAll(std.testing.allocator);
    defer l.deinit(std.testing.allocator);

    const p = parserMod.Parser.init(tokens);
    try std.testing.expect(p.source == null);
}

test "parser: reserved words are not identifier tokens" {
    const reservedWords = [_][]const u8{ "auto", "delegate", "implement", "macro", "derive" };
    for (reservedWords) |word| {
        var l = lexerMod.Lexer.init(word);
        const tokens = try l.scanAll(std.testing.allocator);
        defer l.deinit(std.testing.allocator);
        try std.testing.expect(tokens[0].kind != .identifier);
        try std.testing.expect(lexerMod.isReservedWord(tokens[0].kind));
    }
}

test "parser: enum ---- simple unit variants" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "parser: enum ---- with payload variant" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\}
    );
}

test "parser: interface extends ---- val form single" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val I1 = interface extends T2 {}
    );
}

test "parser: interface extends ---- val form multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val I1 = interface extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- pub val form multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub val I1 = interface extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- shorthand single" {
    try h.assertParser(std.testing.allocator, @src(),
        \\interface I1 extends T2 {}
    );
}

test "parser: interface extends ---- shorthand multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\interface I1 extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- pub shorthand multiple" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub interface I1 extends T2, T3, T4 {}
    );
}

test "parser: annotation ---- fn no args" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[inline]
        \\fn greet() {}
    );
}

test "parser: annotation ---- fn with dot-ident arg" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\pub fn maxval() {}
    );
}

test "parser: annotation ---- fn multiple annotations" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\#[inline]
        \\fn compute() {}
    );
}

test "parser: annotation ---- val form fn" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val maxval = #[target(.erlang)] fn() {}
    );
}

test "parser: annotation ---- struct shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\struct Point {}
    );
}

test "parser: annotation ---- record shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[derive(Eq)]
        \\record Person { name: string }
    );
}

test "parser: annotation ---- enum shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.beam)]
        \\enum Color {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\}
    );
}

test "parser: annotation ---- interface shorthand" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\interface Printable {}
    );
}

test "parser: annotation block ---- hash bracket builtin" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[@external(erlang, "string", "length"),
        \\  @external(node, "./gleam_stdlib.mjs", "string_length")]
        \\pub declare fn length(s: string) -> i32;
    );
}

test "parser: annotation block ---- external decl then next decl" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[@external(erlang, "erlang", "abs")]
        \\pub declare fn absolute_value(n: i32) -> i32;
        \\
        \\fn main() {
        \\    absolute_value(-5);
        \\}
    );
}

test "parser: val local binding with case expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        val result = case x {
        \\            _ -> "ok";
        \\        };
        \\    }
        \\}
    );
}

test "parser: val top-level constant ---- integer" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val MAX = 100;
    );
}

test "parser: val top-level constant ---- comptime float mul" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val pi = comptime 3.14 * 2.0;
    );
}

test "parser: val top-level constant ---- comptime string concat" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val greeting = comptime "Hello, " + "World";
    );
}

test "parser: val top-level constant ---- comptime block" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val hash = comptime {
        \\    break 6364 + 11;
        \\};
    );
}

test "parser: pub fn ---- comptime params" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: int) -> string {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- syntax bool param" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn check(cond comptime: syntax bool) {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- syntax fn type param returning generic" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn select<T, R>(lamb comptime: syntax fn(item: T) -> R) {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- syntax fn type param returning bool" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn where<T>(pred comptime: syntax fn(item: T) -> bool) {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- type meta-kind no constraint" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn wrap(comptime T: type) -> type {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- type meta-kind single constraint" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn render(comptime tag: type string, props: i32) -> string {
        \\    @todo();
        \\}
    );
}

test "parser: pub fn ---- type meta-kind multiple pipe constraints" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn coerce(comptime v: type string | int | bool, x: i32) -> i32 {
        \\    @todo();
        \\}
    );
}

test "parser: val top-level ---- call expression" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val box = wrap(int);
        \\val m = maxval(float);
    );
}

test "parser: empty array literal" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val xs = [];
    );
}

test "parser: val with array type annotation" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "parser: val with tuple type annotation" {
    try h.assertParser(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "parser: test anonymous" {
    try h.assertParser(std.testing.allocator, @src(),
        \\test {
        \\    assert 1 + 1 == 2;
        \\}
    );
}

test "parser: test named" {
    try h.assertParser(std.testing.allocator, @src(),
        \\test "addition works" {
        \\    val r = 2 + 3;
        \\    assert r == 5;
        \\}
    );
}

test "parser: test named with message assert" {
    try h.assertParser(std.testing.allocator, @src(),
        \\test "map doubles" {
        \\    assert [2, 4, 6] == [2, 4, 6], "map should double each element";
        \\}
    );
}

test "parser: test rejects in fn body" {
    // `test` is a top-level declaration only.
    try h.expectParseFails(std.testing.allocator,
        \\fn run() {
        \\    test { assert true; }
        \\}
    );
}

test "parser: Expr builtin type ---- param and bounded return" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub fn html(comptime template: @Expr<string>) -> @Expr<Component> {
        \\    @todo();
        \\}
    );
}

test "parser: Expr builtin type ---- generic return" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn yaml<T>(comptime template: @Expr<string>) -> @Expr<T> {
        \\    @todo();
        \\}
    );
}

test "parser: Expr builtin type ---- composed type position" {
    try h.assertParser(std.testing.allocator, @src(),
        \\fn collect<T>(comptime first: ?@Expr<Element>) -> @Expr<T> {
        \\    @todo();
        \\}
    );
}

test "parser: interface with default method and external declare member" {
    try h.assertParser(std.testing.allocator, @src(),
        \\pub interface List<T> {
        \\    default fn isEmpty(self: Self) -> bool {
        \\        return self.length == 0;
        \\    }
        \\    #[@external(erlang, "lists", "reverse"),
        \\      @external(node, "./bp_stdlib.mjs", "list_reverse")]
        \\    declare fn reverse(self: Self) -> Array<T>;
        \\}
    );
}

// ── §A annotation-driven-builtins: extended `#[@external]` vocabulary ──────────

test "parser: external ---- qualified enum target and call template" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[@external(Target.Erlang, "lists", "zip(other, self)"),
        \\  @external(Target.Node, "./gleam_stdlib.mjs", "zip")]
        \\pub declare fn zip(self: Array<i32>, other: Array<i32>) -> Array<i32>;
    );
}

test "parser: external ---- keyword-argument form" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[@external(runtime: Target.Erlang, module: "lists", method: "reverse(self)")]
        \\pub declare fn reverse(self: Array<i32>) -> Array<i32>;
    );
}

test "parser: external ---- node prototype shorthand (module omitted)" {
    try h.assertParser(std.testing.allocator, @src(),
        \\#[@external(Target.Node, "reverse"),
        \\  @external(.Erlang, "lists", "reverse")]
        \\pub declare fn reverse(self: Array<i32>) -> Array<i32>;
    );
}

// Semantic check: every spelling of the extended vocabulary resolves to the same
// `(module, symbol)` via `externalFor`, and the back-compat bare form still works.
test "ast: externalFor resolves extended @external vocabulary" {
    const alloc = std.testing.allocator;
    const src =
        \\#[@external(Target.Erlang, "lists", "zip(other, self)"),
        \\  @external(runtime: Target.Node, method: "zip")]
        \\pub declare fn zip(self: Array<i32>, other: Array<i32>) -> Array<i32>;
        \\#[@external(erlang, "lists", "reverse")]
        \\pub declare fn rev(self: Array<i32>) -> Array<i32>;
    ;
    var l = Lexer.init(src);
    const tokens = try l.scanAll(alloc);
    defer l.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var zip: ?ast.FnDecl = null;
    var rev: ?ast.FnDecl = null;
    for (program.decls) |d| switch (d) {
        .@"fn" => |f| {
            if (std.mem.eql(u8, f.name, "zip")) zip = f;
            if (std.mem.eql(u8, f.name, "rev")) rev = f;
        },
        else => {},
    };
    try std.testing.expect(zip != null);
    try std.testing.expect(rev != null);

    // Qualified `Target.Erlang` target + call template carried in the symbol slot.
    const erl = zip.?.externalFor("erlang").?;
    try std.testing.expectEqualStrings("lists", erl.module);
    try std.testing.expectEqualStrings("zip(other, self)", erl.symbol);

    // Keyword form with the module omitted (node prototype) → empty module.
    const nod = zip.?.externalFor("node").?;
    try std.testing.expectEqualStrings("", nod.module);
    try std.testing.expectEqualStrings("zip", nod.symbol);

    // Back-compat: bare lowercase target still resolves; a missing target is null.
    const rerl = rev.?.externalFor("erlang").?;
    try std.testing.expectEqualStrings("lists", rerl.module);
    try std.testing.expectEqualStrings("reverse", rerl.symbol);
    try std.testing.expect(rev.?.externalFor("node") == null);
}

// Splits the symbol slot into `(host symbol, ordered arg names)`. The bare
// form has no parens (codegen falls back to declaration order); `"sym()"` is
// the zero-arg call.
test "ast: parseExternalCallTemplate splits symbol from arg order" {
    var slots: [8][]const u8 = undefined;

    const bare = ast.parseExternalCallTemplate("reverse", &slots);
    try std.testing.expectEqualStrings("reverse", bare.symbol);
    try std.testing.expect(bare.args == null);

    const swapped = ast.parseExternalCallTemplate("zip(other, self)", &slots);
    try std.testing.expectEqualStrings("zip", swapped.symbol);
    try std.testing.expect(swapped.args != null);
    try std.testing.expectEqual(@as(usize, 2), swapped.args.?.len);
    try std.testing.expectEqualStrings("other", swapped.args.?[0]);
    try std.testing.expectEqualStrings("self", swapped.args.?[1]);

    const nullary = ast.parseExternalCallTemplate("now()", &slots);
    try std.testing.expectEqualStrings("now", nullary.symbol);
    try std.testing.expect(nullary.args != null);
    try std.testing.expectEqual(@as(usize, 0), nullary.args.?.len);
}
