const std = @import("std");
const snapMod = @import("../utils/snap.zig");
const Allocator = std.mem.Allocator;

const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");

const ParseErrorType = parserMod.ParseErrorType;
const ast = @import("../ast.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const print = @import("../print.zig");

// ── helpers ───────────────────────────────────────────────────────────────────

/// Convert a comptime string to a lowercase-with-underscores slug.
/// Non-alphanumeric runs become a single `_`; leading/trailing `_` are dropped.
fn slugify(comptime s: []const u8) []const u8 {
    // Pass 1: compute the output length.
    const n: usize = comptime blk: {
        var count: usize = 0;
        var sep = true; // start true so leading non-alnum is skipped
        for (s) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                count += 1;
                sep = false;
            } else if (!sep) {
                count += 1; // pending underscore
                sep = true;
            }
        }
        // Trim any trailing underscore that would be appended at end.
        if (sep and count > 0) count -= 1;
        break :blk count;
    };

    // Pass 2: fill a fixed-size buffer (struct pattern so the data is comptime).
    const S = struct {
        const data: [n]u8 = blk: {
            var buf: [n]u8 = undefined;
            var i: usize = 0;
            var sep = true;
            for (s) |c| {
                if (std.ascii.isAlphanumeric(c)) {
                    if (i < n) {
                        buf[i] = std.ascii.toLower(c);
                        i += 1;
                    }
                    sep = false;
                } else if (!sep) {
                    if (i < n) {
                        buf[i] = '_';
                        i += 1;
                    }
                    sep = true;
                }
            }
            break :blk buf;
        };
    };
    return &S.data;
}

/// Derive a snapshot slug from a `@src()` location.
///
/// The test function name has the form `"test.category: description"`.
/// We strip the `"test."` prefix, then strip up to and including the first
/// `": "`, leaving just the description, and slugify it.
fn slugFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const desc = comptime blk: {
        const fnName = loc.fn_name;
        const afterTest = if (std.mem.startsWith(u8, fnName, "test."))
            fnName["test.".len..]
        else
            fnName;
        break :blk if (std.mem.indexOf(u8, afterTest, ": ")) |i|
            afterTest[i + 2 ..]
        else
            afterTest;
    };
    return slugify(desc);
}

fn assertParser(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    var l = Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    var p = Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);

    const slug = comptime slugFromSrc(loc);
    const snapName = try std.fmt.allocPrint(allocator, "parser/{s}", .{slug});
    defer allocator.free(snapName);
    try snapMod.check(allocator, snapName, program);
}

/// Asserts that `src` produces a parse error whose rendered output
/// matches the snapshot `expected`.
///
/// Usage:
///   try expectParseError(std.testing.allocator,
///       \\error comptime: syntax error
///       \\ --> <test>:1:8
///       \\  |
///       \\1 | wibble = 4
///       \\  |        ^ There must be a 'val' or 'var' to bind a variable to a value
///       \\  |
///       \\  = hint: Use `val <n> = <value>` for bindings.
///       \\
///   , "wibble = 4");
fn expectParseError(
    allocator: std.mem.Allocator,
    comptime expected: []const u8,
    src: []const u8,
) !void {
    var l = lexerMod.Lexer.init(src);
    const tokens = l.scanAll(allocator) catch {
        l.deinit(allocator);
        return error.LexErrorNotParseError;
    };
    defer l.deinit(allocator);

    var p = parserMod.Parser.initWithSource(tokens, src);
    if (p.parse(allocator)) |*prog| {
        var owned = prog.*;
        owned.deinit(allocator);
        return error.TestExpectedParseError;
    } else |_| {
        const pe = p.parseError orelse return;
        const actual = try print.renderAlloc(allocator, pe, src, "<test>");
        defer allocator.free(actual);
        try expectEqualOutput(allocator, expected, actual);
    }
}

/// Compares `expected` with `actual` line by line and prints a readable diff
/// if they diverge.
fn expectEqualOutput(
    allocator: std.mem.Allocator,
    expected: []const u8,
    actual: []const u8,
) !void {
    if (std.mem.eql(u8, expected, actual)) return;

    var expLines: std.ArrayList([]const u8) = .empty;
    defer expLines.deinit(allocator);
    var actLines: std.ArrayList([]const u8) = .empty;
    defer actLines.deinit(allocator);

    var it = std.mem.splitScalar(u8, expected, '\n');
    while (it.next()) |line| try expLines.append(allocator, line);
    it = std.mem.splitScalar(u8, actual, '\n');
    while (it.next()) |line| try actLines.append(allocator, line);

    const maxLines = @max(expLines.items.len, actLines.items.len);

    std.debug.print("\n-- parse error output mismatch ------------------------------\n", .{});
    var hasDiff = false;
    for (0..maxLines) |i| {
        const e = if (i < expLines.items.len) expLines.items[i] else "<missing>";
        const a = if (i < actLines.items.len) actLines.items[i] else "<missing>";
        if (!std.mem.eql(u8, e, a)) {
            if (!hasDiff) std.debug.print("{s:>4}  {s:<40}  {s}\n", .{ "line", "expected", "actual" });
            std.debug.print("{d:>4}  -{s}\n      +{s}\n", .{ i + 1, e, a });
            hasDiff = true;
        }
    }
    std.debug.print("-------------------------------------------------------------\n\n", .{});
    if (hasDiff) return error.TestOutputMismatch;
}

// ── empty program ─────────────────────────────────────────────────────────────

test "parser: empty program" {
    try assertParser(std.testing.allocator, @src(), "");
}

test "parser: whitespace-only source" {
    try assertParser(std.testing.allocator, @src(), "   \t\n  ");
}

// ── use decl ─────────────────────────────────────────────────────────────────

test "parser: use {} from \"mylib\" (empty imports)" {
    try assertParser(std.testing.allocator, @src(), "use {} from \"mylib\"");
}

test "parser: use {foo} from \"lib\"" {
    try assertParser(std.testing.allocator, @src(), "use {foo} from \"lib\"");
}

test "parser: use {alpha, beta, gamma} from \"pkg\"" {
    try assertParser(std.testing.allocator, @src(), "use {alpha, beta, gamma} from \"pkg\"");
}

test "parser: trailing comma in import list" {
    try assertParser(std.testing.allocator, @src(), "use {a, b,} from \"x\"");
}

test "parser: empty string path" {
    try assertParser(std.testing.allocator, @src(), "use {x} from \"\"");
}

// ── use: source FunctionCall ──────────────────────────────────────────────────

test "parser: use {x} from loader()" {
    try assertParser(std.testing.allocator, @src(), "use {x} from loader()");
}

test "parser: use {} from init() (empty imports + FunctionCall)" {
    try assertParser(std.testing.allocator, @src(), "use {} from init()");
}

// ── use: multiple declarations ────────────────────────────────────────────────

test "parser: two use declarations" {
    try assertParser(std.testing.allocator, @src(),
        \\use {a} from "lib1"
        \\use {b, c} from "lib2"
    );
}

test "parser: mixed StringPath and FunctionCall declarations" {
    try assertParser(std.testing.allocator, @src(),
        \\use {x} from "a"
        \\use {y} from b()
        \\use {z} from "c"
    );
}

// ── interface: basic structure ────────────────────────────────────────────────────

test "parser: empty interface" {
    try assertParser(std.testing.allocator, @src(), "val Drawable = interface {}");
}

test "parser: interface with one field" {
    try assertParser(std.testing.allocator, @src(), "val Drawable = interface { val color: string }");
}

// ── interface: method params ──────────────────────────────────────────────────────

test "parser: abstract method with 1 param (self: Self)" {
    try assertParser(std.testing.allocator, @src(), "val Drawable = interface { fn draw(self: Self) }");
}

test "parser: abstract method with multiple params" {
    try assertParser(std.testing.allocator, @src(), "val Positionable = interface { fn moveTo(self: Self, x: i32, y: i32) }");
}

// ── interface: multiple methods with varying param counts ────────────────────────

test "parser: interface with methods of varying param counts" {
    try assertParser(std.testing.allocator, @src(),
        \\val Canvas = interface {
        \\    fn clear(self: Self)
        \\    fn drawLine(self: Self, x1: i32, y1: i32)
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string)
        \\}
    );
}

// ── interface: full Drawable from spec ────────────────────────────────────────────

test "parser: full Drawable interface (field + abstract + default method)" {
    try assertParser(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\}
    );
}

// ── struct: basic structure ───────────────────────────────────────────────────

test "parser: empty struct" {
    try assertParser(std.testing.allocator, @src(), "val Account = struct {}");
}

test "parser: struct with one field" {
    try assertParser(std.testing.allocator, @src(), "val Account = struct { _balance: number = 0 }");
}

test "parser: struct with field and default" {
    try assertParser(std.testing.allocator, @src(), "val Config = struct { host: string = \"localhost\" }");
}

// ── struct: getter ────────────────────────────────────────────────────────────

test "parser: struct with a simple getter" {
    try assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\}
    );
}

// ── struct: setter ────────────────────────────────────────────────────────────

test "parser: struct with a setter that throws" {
    try assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        throw Error(msg: "Saldo nao pode ser negativo");
        \\    }
        \\}
    );
}

test "parser: setter with assign" {
    try assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        self._balance = value;
        \\    }
        \\}
    );
}

// ── struct: method ────────────────────────────────────────────────────────────

test "parser: struct with a fn method (deposit)" {
    try assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\}
    );
}

// ── struct: full Account from spec ────────────────────────────────────────────

test "parser: full Account struct (private field + getter + setter + method)" {
    try assertParser(std.testing.allocator, @src(),
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

// ── record: basic structure ───────────────────────────────────────────────────

test "parser: empty record (no fields, no methods)" {
    try assertParser(std.testing.allocator, @src(), "val Point = record {}");
}

test "parser: record with two fields and no methods" {
    try assertParser(std.testing.allocator, @src(), "val Point = record { x: number, y: number }");
}

test "parser: record with one method" {
    try assertParser(std.testing.allocator, @src(),
        \\val Point = record {
        \\    x: number,
        \\    fn show(self: Self) {
        \\        return self.x;
        \\    }
        \\}
    );
}

// ── record: full GPSCoordinates from spec ─────────────────────────────────────

test "parser: full GPSCoordinates record (two fields + toString method)" {
    try assertParser(std.testing.allocator, @src(),
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
    try assertParser(std.testing.allocator, @src(),
        \\val X = record {
        \\    value: string,
        \\    declare fn foo(self: Self);
        \\}
    );
}

test "parser: struct with declare fn (abstract method declaration)" {
    try assertParser(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    fn deposit(self: Self) {}
        \\    declare fn withdraw(self: Self) -> number;
        \\}
    );
}

test "parser: enum with declare fn (abstract method declaration)" {
    try assertParser(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    declare fn label(self: Self) -> string;
        \\}
    );
}

// ── impl: basic structure ─────────────────────────────────────────────────────

test "parser: implement with one interface and one unqualified method" {
    try assertParser(std.testing.allocator, @src(),
        \\val Myimplement = implement Drawable for Circle {
        \\    fn draw(self: Self) {}
        \\}
    );
}

test "parser: implement with two interfaces and qualified methods" {
    try assertParser(std.testing.allocator, @src(),
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

// ── parse errors: snapshot tests ─────────────────────────────────────────────

test "parser error: assignment without val" {
    try expectParseError(std.testing.allocator,
        \\error comptime: syntax error
        \\ --> <test>:1:1
        \\  |
        \\1 | wibble = 4
        \\  | ^^^^^^ There must be a 'val' or 'var' to bind a variable to a value
        \\  |
        \\  = hint: Use `val <n> = <value>` for bindings.
        \\
        \\
    , "wibble = 4");
}

test "parser error: reserved word at top-level" {
    try expectParseError(std.testing.allocator,
        \\error: This is a reserved word and cannot be used as a name
        \\ --> <test>:1:1
        \\  |
        \\1 | auto
        \\  | ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    , "auto");
}

test "parser error: reserved word in expression" {
    try expectParseError(std.testing.allocator,
        \\error: This is a reserved word and cannot be used as a name
        \\ --> <test>:1:1
        \\  |
        \\1 | echo
        \\  | ^^^^ This is a reserved word and cannot be used as a name
        \\  |
        \\  = hint: Choose a different identifier.
        \\
        \\
    , "echo");
}

// ── validateListSpread ────────────────────────────────────────────────────────

test "parser: validateListSpread ---- empty list is valid" {
    try std.testing.expect(parserMod.validateListSpread(false, false, 0) == null);
}

test "parser: validateListSpread ---- [1, 2, ..xs] is valid" {
    try std.testing.expect(parserMod.validateListSpread(true, true, 2) == null);
}

test "parser: validateListSpread ---- [..xs, 3] gives elementsAfterSpread" {
    const result = parserMod.validateListSpread(true, false, 0);
    try std.testing.expectEqual(parserMod.ListSpreadError.elementsAfterSpread, result.?);
}

test "parser: validateListSpread ---- [..xs] gives UselessSpread" {
    const result = parserMod.validateListSpread(true, true, 0);
    try std.testing.expectEqual(parserMod.ListSpreadError.uselessSpread, result.?);
}

// ── listSpreadErrorMessage ────────────────────────────────────────────────────

test "parser: listSpreadErrorMessage.elementsAfterSpread mentions 'after'" {
    const msgs = parserMod.listSpreadErrorMessage(.elementsAfterSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.message, "after") != null or
            std.mem.indexOf(u8, msgs.message, "expecting") != null,
    );
}

test "parser: listSpreadErrorMessage.uselessSpread mentions spread has no effect" {
    const msgs = parserMod.listSpreadErrorMessage(.uselessSpread);
    try std.testing.expect(
        std.mem.indexOf(u8, msgs.message, "nothing") != null or
            std.mem.indexOf(u8, msgs.message, "does") != null,
    );
}

// ── ParseErrorInfo ────────────────────────────────────────────────────────────

test "parser: ParseErrorInfo has all expected fields" {
    const info = parserMod.ParseErrorInfo{
        .kind = .reservedWord,
        .start = 0,
        .end = 4,
        .lexeme = "auto",
        .detail = "auto",
    };
    try std.testing.expectEqual(ParseErrorType.reservedWord, info.kind);
    try std.testing.expectEqualStrings("auto", info.lexeme);
    try std.testing.expectEqual(@as(usize, 0), info.start);
    try std.testing.expectEqual(@as(usize, 4), info.end);
}

test "parser: ParseErrorInfo detail is optional" {
    const info = parserMod.ParseErrorInfo{
        .kind = .novalBinding,
        .start = 0,
        .end = 6,
        .lexeme = "wibble",
    };
    try std.testing.expect(info.detail == null);
}

// ── Parser.initWithSource ─────────────────────────────────────────────────────

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

// ── reserved words recognized by lexer ───────────────────────────────────────

test "parser: reserved words are not identifier tokens" {
    const reservedWords = [_][]const u8{ "auto", "delegate", "echo", "implement", "macro", "derive" };
    for (reservedWords) |word| {
        var l = lexerMod.Lexer.init(word);
        const tokens = try l.scanAll(std.testing.allocator);
        defer l.deinit(std.testing.allocator);
        try std.testing.expect(tokens[0].kind != .identifier);
        try std.testing.expect(lexerMod.isReservedWord(tokens[0].kind));
    }
}

// ── lexicalErrorMessage ───────────────────────────────────────────────────────

test "lexer: lexicalErrorMessage for DigitOutOfRadix" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .DigitOutOfRadix, .start = 4, .end = 5, .invalidChar = '8' });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "radix") != null or std.mem.indexOf(u8, msg, "Digit") != null,
    );
}

test "lexer: lexicalErrorMessage for RadixIntNovalue" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .RadixIntNovalue, .start = 1, .end = 1 });
    try std.testing.expect(msg.len > 0);
}

test "lexer: lexicalErrorMessage for InvalidTripleEqual" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .InvalidTripleEqual, .start = 0, .end = 3 });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "===") != null or std.mem.indexOf(u8, msg, "botopink") != null,
    );
}

test "lexer: lexicalErrorMessage for BadStringEscape" {
    const msg = lexerMod.lexicalErrorMessage(.{ .kind = .BadStringEscape, .start = 1, .end = 3, .invalidChar = 'g' });
    try std.testing.expect(msg.len > 0);
}

test "lexer: lexicalErrorMessage for InvalidUnicodeEscape ExpectedHexDigitOrCloseBrace" {
    const msg = lexerMod.lexicalErrorMessage(.{
        .kind = .InvalidUnicodeEscape,
        .unicodeKind = .ExpectedHexDigitOrCloseBrace,
        .start = 1,
        .end = 5,
    });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "hex") != null or
            std.mem.indexOf(u8, msg, "Hex") != null or
            std.mem.indexOf(u8, msg, "Expected") != null,
    );
}

test "lexer: lexicalErrorMessage for InvalidUnicodeEscape InvalidCodepoint" {
    const msg = lexerMod.lexicalErrorMessage(.{
        .kind = .InvalidUnicodeEscape,
        .unicodeKind = .InvalidCodepoint,
        .start = 1,
        .end = 11,
    });
    try std.testing.expect(
        std.mem.indexOf(u8, msg, "10FFFF") != null or
            std.mem.indexOf(u8, msg, "codepoint") != null or
            std.mem.indexOf(u8, msg, "Codepoint") != null,
    );
}

// ── lambda / call expressions ─────────────────────────────────────────────────

test "parser: lambda: plain positional call ---- print(\"hello\")" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        print("hello");
        \\    }
        \\}
    );
}

test "parser: lambda: named argument call ---- calcular(fator: 2)" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        calcular(fator: 2);
        \\    }
        \\}
    );
}

test "parser: lambda: trailing lambda with no params ---- executar { ok }" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        executar { ok; };
        \\    }
        \\}
    );
}

test "parser: lambda: named arg + trailing lambda with two params and addition" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        calcular(fator: 2) { a, b ->
        \\            a + b;
        \\        };
        \\    }
        \\}
    );
}

test "parser: lambda: two trailing lambdas, second labeled ---- executar {} erro: {}" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        executar { ok; } erro: { fail; };
        \\    }
        \\}
    );
}

test "parser: lambda: method call with two-param trailing lambda ---- precos.forEach { fruta, valor -> fruta }" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        precos.forEach { fruta, valor -> fruta; };
        \\    }
        \\}
    );
}

test "parser: lambda: binary addition ---- a + b" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a + b;
        \\    }
        \\}
    );
}

// ── enum declarations ─────────────────────────────────────────────────────────

test "parser: enum ---- simple unit variants" {
    try assertParser(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "parser: enum ---- with payload variant" {
    try assertParser(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\}
    );
}

// ── shorthand type declarations ───────────────────────────────────────────────

test "parser: shorthand enum ---- simple" {
    try assertParser(std.testing.allocator, @src(),
        \\enum Direction {
        \\    North,
        \\    South,
        \\}
    );
}

test "parser: shorthand enum ---- pub with generics and payload" {
    try assertParser(std.testing.allocator, @src(),
        \\pub enum Option <T> {
        \\    None,
        \\    Some(value: T),
        \\}
    );
}

test "parser: shorthand struct ---- simple" {
    try assertParser(std.testing.allocator, @src(),
        \\struct Account {
        \\    _balance: i32 = 0,
        \\}
    );
}

test "parser: shorthand struct ---- pub with generics" {
    try assertParser(std.testing.allocator, @src(),
        \\pub struct Box <T> {
        \\    item: T = 0,
        \\}
    );
}

test "parser: shorthand record ---- simple" {
    try assertParser(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32 }
    );
}

test "parser: shorthand record ---- pub with generics" {
    try assertParser(std.testing.allocator, @src(),
        \\pub record Pair <T> { first: T, second: T }
    );
}

test "parser: shorthand interface ---- simple" {
    try assertParser(std.testing.allocator, @src(),
        \\interface Drawable {
        \\    fn draw()
        \\}
    );
}

test "parser: shorthand interface ---- pub with generics" {
    try assertParser(std.testing.allocator, @src(),
        \\pub interface Container <T> {
        \\    fn size() -> Int
        \\}
    );
}

// ── interface extends ─────────────────────────────────────────────────────────

test "parser: interface extends ---- val form single" {
    try assertParser(std.testing.allocator, @src(),
        \\val I1 = interface extends T2 {}
    );
}

test "parser: interface extends ---- val form multiple" {
    try assertParser(std.testing.allocator, @src(),
        \\val I1 = interface extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- pub val form multiple" {
    try assertParser(std.testing.allocator, @src(),
        \\pub val I1 = interface extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- shorthand single" {
    try assertParser(std.testing.allocator, @src(),
        \\interface I1 extends T2 {}
    );
}

test "parser: interface extends ---- shorthand multiple" {
    try assertParser(std.testing.allocator, @src(),
        \\interface I1 extends T2, T3, T4 {}
    );
}

test "parser: interface extends ---- pub shorthand multiple" {
    try assertParser(std.testing.allocator, @src(),
        \\pub interface I1 extends T2, T3, T4 {}
    );
}

// ── delegate decl ─────────────────────────────────────────────────────────────

test "parser: delegate ---- val form simple" {
    try assertParser(std.testing.allocator, @src(),
        \\val log = declare fn(self: Self);
    );
}

test "parser: delegate ---- val form with return type" {
    try assertParser(std.testing.allocator, @src(),
        \\val Predicate = declare fn(value: i32) -> bool;
    );
}

test "parser: delegate ---- shorthand simple" {
    try assertParser(std.testing.allocator, @src(),
        \\declare fn log(self: Self);
    );
}

test "parser: delegate ---- shorthand pub with return type" {
    try assertParser(std.testing.allocator, @src(),
        \\pub declare fn transform(input: string) -> string;
    );
}

// ── annotations ───────────────────────────────────────────────────────────────

test "parser: annotation ---- fn no args" {
    try assertParser(std.testing.allocator, @src(),
        \\#[inline]
        \\fn greet() {}
    );
}

test "parser: annotation ---- fn with dot-ident arg" {
    try assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\pub fn maxval() {}
    );
}

test "parser: annotation ---- fn multiple annotations" {
    try assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\#[inline]
        \\fn compute() {}
    );
}

test "parser: annotation ---- val form fn" {
    try assertParser(std.testing.allocator, @src(),
        \\val maxval = #[target(.erlang)] fn() {}
    );
}

test "parser: annotation ---- struct shorthand" {
    try assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\struct Point {}
    );
}

test "parser: annotation ---- record shorthand" {
    try assertParser(std.testing.allocator, @src(),
        \\#[derive(Eq)]
        \\record Person { name: string }
    );
}

test "parser: annotation ---- enum shorthand" {
    try assertParser(std.testing.allocator, @src(),
        \\#[target(.beam)]
        \\enum Color {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\}
    );
}

test "parser: annotation ---- interface shorthand" {
    try assertParser(std.testing.allocator, @src(),
        \\#[target(.erlang)]
        \\interface Printable {}
    );
}

// ── case expressions ──────────────────────────────────────────────────────────

test "parser: case ---- wildcard and ident patterns" {
    try assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case x {
        \\            else -> y;
        \\            Red -> z;
        \\        };
        \\    }
        \\}
    );
}

test "parser: case ---- variant with field bindings" {
    try assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case (self.color) {
        \\            Red -> "red";
        \\            Rgb(r, g, b) -> "rgb";
        \\        };
        \\    }
        \\}
    );
}

test "parser: case ---- list patterns" {
    try assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case xs {
        \\            [] -> "empty";
        \\            [1] -> "one";
        \\            [_, _] -> "two";
        \\            [first, ..rest] -> first;
        \\        };
        \\    }
        \\}
    );
}

test "parser: case ---- OR patterns" {
    try assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case n {
        \\            2 | 4 | 6 -> "even";
        \\            else -> "other";
        \\        };
        \\    }
        \\}
    );
}

test "parser: val local binding with case expression" {
    try assertParser(std.testing.allocator, @src(),
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        val result = case x {
        \\            else -> "ok";
        \\        };
        \\    }
        \\}
    );
}

// ── top-level val constant declarations ──────────────────────────────────────

test "parser: val top-level constant ---- integer" {
    try assertParser(std.testing.allocator, @src(),
        \\val MAX = 100;
    );
}

test "parser: val top-level constant ---- comptime float mul" {
    try assertParser(std.testing.allocator, @src(),
        \\val pi = comptime 3.14 * 2.0;
    );
}

test "parser: val top-level constant ---- comptime string concat" {
    try assertParser(std.testing.allocator, @src(),
        \\val greeting = comptime "Hello, " + "World";
    );
}

test "parser: val top-level constant ---- comptime block" {
    try assertParser(std.testing.allocator, @src(),
        \\val hash = comptime {
        \\    break 6364 + 11;
        \\};
    );
}

// ── pub fn parameter modifiers ────────────────────────────────────────────────

test "parser: pub fn ---- comptime params" {
    try assertParser(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: int) -> string {
        \\    todo;
        \\}
    );
}

test "parser: pub fn ---- syntax bool param" {
    try assertParser(std.testing.allocator, @src(),
        \\pub fn check(cond comptime: syntax bool) {
        \\    todo;
        \\}
    );
}

test "parser: pub fn ---- syntax fn type param returning generic" {
    try assertParser(std.testing.allocator, @src(),
        \\pub fn select<T, R>(lamb comptime: syntax fn(item: T) -> R) {
        \\    todo;
        \\}
    );
}

test "parser: pub fn ---- syntax fn type param returning bool" {
    try assertParser(std.testing.allocator, @src(),
        \\pub fn where<T>(pred comptime: syntax fn(item: T) -> bool) {
        \\    todo;
        \\}
    );
}

test "parser: pub fn ---- typeinfo param no constraint" {
    try assertParser(std.testing.allocator, @src(),
        \\pub fn wrap(comptime: typeinfo T) -> type {
        \\    todo;
        \\}
    );
}

test "parser: pub fn ---- typeinfo param with constraints" {
    try assertParser(std.testing.allocator, @src(),
        \\pub fn maxval(comptime: typeinfo T int | float) -> T {
        \\    todo;
        \\}
    );
}

// ── top-level val with call expression ───────────────────────────────────────

test "parser: val top-level ---- call expression" {
    try assertParser(std.testing.allocator, @src(),
        \\val box = wrap(int);
        \\val m = maxval(float);
    );
}

// ── operator precedence ───────────────────────────────────────────────────────

test "parser: operator precedence ---- mul binds tighter than add" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        1 + 2 * 3;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- left-to-right associativity for add" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        1 + 2 + 3;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- add binds tighter than compare" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a + 1 < b + 2;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- compare binds tighter than eq" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a < b == c > d;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- all arithmetic operators" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a + b - c * d / e % f;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- comparison operators" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a < b;
        \\        a > b;
        \\        a <= b;
        \\        a >= b;
        \\    }
        \\}
    );
}

test "parser: operator precedence ---- equality operators" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        a == b;
        \\        a != b;
        \\    }
        \\}
    );
}

// ── destructuring in val bindings ─────────────────────────────────────────────

test "parser: destructure ---- record val binding" {
    try assertParser(std.testing.allocator, @src(),
        \\fn greet(person: Person) -> string {
        \\    val { name, age } = person;
        \\    return name;
        \\}
    );
}

// ── destructuring in function parameters ─────────────────────────────────────

test "parser: destructure ---- record parameter" {
    try assertParser(std.testing.allocator, @src(),
        \\fn greet({ name, age }: Person) -> string {
        \\    return name;
        \\}
    );
}

test "parser: destructure ---- mixed params" {
    try assertParser(std.testing.allocator, @src(),
        \\fn process(prefix: string, { name }: Person) -> string {
        \\    return prefix;
        \\}
    );
}

// ── builtin function calls ────────────────────────────────────────────────────

test "parser: builtin ---- zero-arg call" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        @src();
        \\    }
        \\}
    );
}

test "parser: builtin ---- single-arg call" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        @sizeOf(Int);
        \\        @typeName(Bool);
        \\        @panic("unreachable");
        \\    }
        \\}
    );
}

test "parser: builtin ---- multi-arg call" {
    try assertParser(std.testing.allocator, @src(),
        \\val Test = interface {
        \\    default fn run() {
        \\        @min(a, b);
        \\        @max(x, y);
        \\        @as(Int, value);
        \\    }
        \\}
    );
}

test "parser: builtin ---- in expression context" {
    try assertParser(std.testing.allocator, @src(),
        \\fn doubled(x: Int) -> Int {
        \\    return @abs(x) + @abs(x);
        \\}
    );
}

test "parser: builtin ---- as val initializer" {
    try assertParser(std.testing.allocator, @src(),
        \\val size = @sizeOf(Float);
        \\val name = @typeName(String);
        \\val src = @src();
    );
}

// ── arrays and tuples ─────────────────────────────────────────────────────────

test "parser: array literal" {
    try assertParser(std.testing.allocator, @src(),
        \\val xs = ["hello", "world"];
    );
}

test "parser: empty array literal" {
    try assertParser(std.testing.allocator, @src(),
        \\val xs = [];
    );
}

test "parser: val with array type annotation" {
    try assertParser(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "parser: tuple literal" {
    try assertParser(std.testing.allocator, @src(),
        \\val t = #("56454", "85484");
    );
}

test "parser: val with tuple type annotation" {
    try assertParser(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "parser: val tuple destructuring" {
    try assertParser(std.testing.allocator, @src(),
        \\fn bind() {
        \\    val #(a, b) = #(12, "5452");
        \\}
    );
}

test "parser: var tuple destructuring" {
    try assertParser(std.testing.allocator, @src(),
        \\fn swap(x: i32, y: i32) -> i32 {
        \\    var #(a, b) = #(x, y);
        \\    return a;
        \\}
    );
}

test "parser: nested array type" {
    try assertParser(std.testing.allocator, @src(),
        \\val matrix: i32[][] = [];
    );
}

// ── try / catch ───────────────────────────────────────────────────────────────

test "parser: try expression" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val x = try fetch();
        \\}
    );
}

test "parser: try-catch expression" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val x = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

test "parser: try-catch with tuple destructure" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

// ── if with null-check binding ────────────────────────────────────────────────

test "parser: if with null-check binding" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var email: ?string = null;
        \\    if (email) { e ->
        \\        console.log(e);
        \\    };
        \\}
    );
}

// ── variable assignment ───────────────────────────────────────────────────────

test "parser: assign ---- simple number literal" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = 10;
        \\}
    );
}

test "parser: assign ---- expression" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var total = 0;
        \\    total = total + 1;
        \\}
    );
}

test "parser: assign ---- string value" {
    try assertParser(std.testing.allocator, @src(),
        \\fn f() {
        \\    var name = "old";
        \\    name = "new";
        \\}
    );
}

