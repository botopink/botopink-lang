const std = @import("std");
const Allocator = std.mem.Allocator;

const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const formatMod = @import("../format.zig");

// ── helpers ───────────────────────────────────────────────────────────────────

/// Parse `src`, format it, and assert the output equals `src`.
/// `src` must already be in canonical (formatted) form.
/// On mismatch prints a line-by-line diff and returns error.TestOutputMismatch.
fn assertFormat(allocator: Allocator, src: []const u8) !void {
    var l = lexerMod.Lexer.init(src);
    const tokens = try l.scanAll(allocator);
    defer l.deinit(allocator);

    var p = parserMod.Parser.init(tokens);
    var program = try p.parse(allocator);
    defer program.deinit(allocator);

    const actual = try formatMod.format(allocator, program);
    defer allocator.free(actual);

    const want = std.mem.trim(u8, src, "\n\r");
    const got = std.mem.trim(u8, actual, "\n\r");

    if (std.mem.eql(u8, want, got)) return;

    // Line-by-line diff
    var expLines: std.ArrayList([]const u8) = .empty;
    defer expLines.deinit(allocator);
    var actLines: std.ArrayList([]const u8) = .empty;
    defer actLines.deinit(allocator);

    var it = std.mem.splitScalar(u8, want, '\n');
    while (it.next()) |ln| try expLines.append(allocator, ln);
    it = std.mem.splitScalar(u8, got, '\n');
    while (it.next()) |ln| try actLines.append(allocator, ln);

    const maxLen = @max(expLines.items.len, actLines.items.len);
    std.debug.print("\n-- format output mismatch ------------------------------\n", .{});
    std.debug.print("{s:>4}  {s:<50}  {s}\n", .{ "line", "expected", "actual" });
    for (0..maxLen) |i| {
        const e = if (i < expLines.items.len) expLines.items[i] else "<missing>";
        const a = if (i < actLines.items.len) actLines.items[i] else "<missing>";
        const marker: u8 = if (std.mem.eql(u8, e, a)) ' ' else '!';
        std.debug.print("{d:>4}{c} -{s}\n     +{s}\n", .{ i + 1, marker, e, a });
    }
    std.debug.print("--------------------------------------------------------\n\n", .{});
    return error.TestOutputMismatch;
}

/// Parse `src`, format it twice ---- both passes must produce identical output.
fn assertIdempotent(allocator: Allocator, src: []const u8) !void {
    const pass1 = blk: {
        var l = lexerMod.Lexer.init(src);
        const tokens = try l.scanAll(allocator);
        defer l.deinit(allocator);
        var p = parserMod.Parser.init(tokens);
        var program = try p.parse(allocator);
        defer program.deinit(allocator);
        break :blk try formatMod.format(allocator, program);
    };
    defer allocator.free(pass1);

    const pass2 = blk: {
        var l = lexerMod.Lexer.init(pass1);
        const tokens = try l.scanAll(allocator);
        defer l.deinit(allocator);
        var p = parserMod.Parser.init(tokens);
        var program = try p.parse(allocator);
        defer program.deinit(allocator);
        break :blk try formatMod.format(allocator, program);
    };
    defer allocator.free(pass2);

    if (!std.mem.eql(u8, pass1, pass2)) {
        std.debug.print(
            "\n-- formatter is not idempotent --\n-- pass 1 --\n{s}\n-- pass 2 --\n{s}\n",
            .{ pass1, pass2 },
        );
        return error.NotIdempotent;
    }
}

// ── use declarations ──────────────────────────────────────────────────────────

test "format: use ---- empty imports from string path" {
    try assertFormat(std.testing.allocator,
        \\use {} from "mylib";
    );
}

test "format: use ---- named imports" {
    try assertFormat(std.testing.allocator,
        \\use {foo, bar, baz} from "my-lib";
    );
}

test "format: use ---- from function call" {
    try assertFormat(std.testing.allocator,
        \\use {x, y} from loader();
    );
}

test "format: use ---- multiple declarations" {
    try assertFormat(std.testing.allocator,
        \\use {a} from "lib1";
        \\use {b, c} from "lib2";
    );
}

// ── val top-level constants ───────────────────────────────────────────────────

test "format: val ---- integer constant" {
    try assertFormat(std.testing.allocator,
        \\val MAX = 100;
    );
}

test "format: val ---- comptime float mul" {
    try assertFormat(std.testing.allocator,
        \\val pi = comptime 3.14 * 2.0;
    );
}

test "format: val ---- comptime string concat" {
    try assertFormat(std.testing.allocator,
        \\val greeting = comptime "Hello, " + "World";
    );
}

test "format: val ---- comptime block with break" {
    try assertFormat(std.testing.allocator,
        \\val hash = comptime {
        \\    break 6364 + 11;
        \\};
    );
}

test "format: val ---- multiple top-level vals" {
    try assertFormat(std.testing.allocator,
        \\val box = wrap(int);
        \\
        \\val m = maxval(float);
    );
}

// ── interface ─────────────────────────────────────────────────────────────────

test "format: interface ---- empty" {
    try assertFormat(std.testing.allocator,
        \\val Drawable = interface {};
    );
}

test "format: interface ---- one field" {
    try assertFormat(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\};
    );
}

test "format: interface ---- abstract method" {
    try assertFormat(std.testing.allocator,
        \\val Drawable = interface {
        \\    fn draw(self: Self);
        \\};
    );
}

test "format: interface ---- full Drawable (field + abstract + default method)" {
    try assertFormat(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self);
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\};
    );
}

test "format: interface ---- multiple abstract methods" {
    try assertFormat(std.testing.allocator,
        \\val Canvas = interface {
        \\    fn clear(self: Self);
        \\    fn drawLine(self: Self, x1: i32, y1: i32);
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string);
        \\};
    );
}

// ── struct ────────────────────────────────────────────────────────────────────

test "format: struct ---- empty" {
    try assertFormat(std.testing.allocator,
        \\val Account = struct {};
    );
}

test "format: struct ---- single field single-line" {
    try assertFormat(std.testing.allocator,
        \\val Account = struct { _balance: number = 0 };
    );
}

test "format: struct ---- multiple fields single-line" {
    try assertFormat(std.testing.allocator,
        \\val Point = struct { x: f32, y: f32 };
    );
}

test "format: struct ---- field with default value" {
    try assertFormat(std.testing.allocator,
        \\val Config = struct { host: string = "localhost", port: i32 = 8080 };
    );
}

test "format: struct ---- field with method multi-line" {
    try assertFormat(std.testing.allocator,
        \\val Counter = struct {
        \\    _count: i32 = 0,
        \\    fn increment(self: Self) {
        \\        self._count += 1;
        \\    }
        \\};
    );
}

test "format: struct ---- field with getter multi-line" {
    try assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    _balance: number = 0,
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\};
    );
}

test "format: struct ---- getter" {
    try assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    get balance(self: Self) -> number {
        \\        return self._balance;
        \\    }
        \\};
    );
}

test "format: struct ---- setter that throws" {
    try assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    set balance(self: Self, value: number) {
        \\        throw Error(msg: "Balance cannot be negative");
        \\    }
        \\};
    );
}

test "format: struct ---- method with augmented assign" {
    try assertFormat(std.testing.allocator,
        \\val Account = struct {
        \\    fn deposit(self: Self, amount: number) {
        \\        self._balance += amount;
        \\    }
        \\};
    );
}

test "format: struct ---- full Account" {
    try assertFormat(std.testing.allocator,
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
        \\};
    );
}

// ── record ────────────────────────────────────────────────────────────────────

test "format: record ---- empty" {
    try assertFormat(std.testing.allocator,
        \\val Point = record {};
    );
}

test "format: record ---- two fields" {
    try assertFormat(std.testing.allocator,
        \\val Point = record { x: number, y: number };
    );
}

test "format: record ---- with method" {
    try assertFormat(std.testing.allocator,
        \\val GPSCoordinates = record {
        \\    lat: number,
        \\    lon: number,
        \\    fn toString(self: Self) {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\};
    );
}

// ── enum ──────────────────────────────────────────────────────────────────────

test "format: enum ---- unit variants" {
    try assertFormat(std.testing.allocator,
        \\val Direction = enum { North, South, East, West };
    );
}

test "format: enum ---- with payload variant" {
    try assertFormat(std.testing.allocator,
        \\val Color = enum { Red, Green, Blue, Rgb(r: i32, g: i32, b: i32) };
    );
}

// ── implement ─────────────────────────────────────────────────────────────────

test "format: implement ---- single interface" {
    try assertFormat(std.testing.allocator,
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {}
        \\};
    );
}

test "format: implement ---- two interfaces with qualified methods" {
    try assertFormat(std.testing.allocator,
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Connect(self: Self) {
        \\        Console.WriteLine("Connected via USB. Battery level: " + self.batteryLevel);
        \\    }
        \\    fn SolarCharger.Connect(self: Self) {
        \\        Console.WriteLine("Connected via Solar Panel. Battery level: " + self.batteryLevel);
        \\    }
        \\};
    );
}

// ── pub fn ────────────────────────────────────────────────────────────────────

test "format: pub fn ---- simple with return type" {
    try assertFormat(std.testing.allocator,
        \\pub fn greet(name: string) -> string {
        \\    return "Hello, " + name;
        \\}
    );
}

test "format: pub fn ---- comptime params" {
    try assertFormat(std.testing.allocator,
        \\pub fn repeat(s comptime: string, n comptime: int) -> string {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- syntax fn type param" {
    try assertFormat(std.testing.allocator,
        \\pub fn select<T, R>(lamb comptime: syntax fn(item: T) -> R) {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- typeinfo no constraint" {
    try assertFormat(std.testing.allocator,
        \\pub fn wrap(comptime: typeinfo T) -> type {
        \\    todo;
        \\}
    );
}

test "format: pub fn ---- typeinfo with constraints" {
    try assertFormat(std.testing.allocator,
        \\pub fn maxval(comptime: typeinfo T int | float) -> T {
        \\    todo;
        \\}
    );
}

// ── case expressions ──────────────────────────────────────────────────────────

test "format: case ---- wildcard and ident" {
    try assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case status {
        \\            0 -> "zero";
        \\            _ -> "nonzero";
        \\        };
        \\    }
        \\};
    );
}

test "format: case ---- variant with field bindings" {
    try assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case color {
        \\            Red -> "#FF0000";
        \\            Rgb(r, g, b) -> toHex(r, g, b);
        \\        };
        \\    }
        \\};
    );
}

test "format: case ---- list patterns with spread" {
    try assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case items {
        \\            [] -> "empty";
        \\            [x] -> "one item";
        \\            [first, ..rest] -> "starts with " + first;
        \\        };
        \\    }
        \\};
    );
}

test "format: case ---- OR patterns" {
    try assertFormat(std.testing.allocator,
        \\val X = implement Foo for Bar {
        \\    fn run(self: Self) {
        \\        case n {
        \\            0 | 2 | 4 | 6 | 8 -> "even digit";
        \\            1 | 3 | 5 | 7 | 9 -> "odd digit";
        \\            _ -> "not a digit";
        \\        };
        \\    }
        \\};
    );
}

// ── lambdas ───────────────────────────────────────────────────────────────────

test "format: lambda ---- trailing no params" {
    try assertFormat(std.testing.allocator,
        \\val Test = interface {
        \\    default fn run() {
        \\        executar {
        \\            ok;
        \\        };
        \\    }
        \\};
    );
}

test "format: lambda ---- named arg + trailing with params" {
    try assertFormat(std.testing.allocator,
        \\val Test = interface {
        \\    default fn run() {
        \\        calcular(fator: 2) { a, b ->
        \\            a + b;
        \\        };
        \\    }
        \\};
    );
}

test "format: lambda ---- two trailing blocks second labeled" {
    try assertFormat(std.testing.allocator,
        \\val Test = interface {
        \\    default fn run() {
        \\        executar {
        \\            ok;
        \\        } erro: {
        \\            fail;
        \\        };
        \\    }
        \\};
    );
}

// ── idempotency ───────────────────────────────────────────────────────────────

test "format: idempotent ---- full Account struct" {
    try assertIdempotent(std.testing.allocator,
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
        \\};
    );
}

test "format: idempotent ---- full Drawable interface" {
    try assertIdempotent(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\};
    );
}

test "format: idempotent ---- enum with payload" {
    try assertIdempotent(std.testing.allocator,
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
    );
}

test "format: idempotent ---- pub fn with comptime params" {
    try assertIdempotent(std.testing.allocator,
        \\pub fn repeat(s comptime: string, n comptime: int) -> string {
        \\    todo;
        \\}
    );
}

// ── imports (adapted from Gleam) ─────────────────────────────────────────────

test "format: use ---- empty" {
    try assertFormat(std.testing.allocator,
        \\use {} from "one";
    );
}

test "format: use ---- single import" {
    try assertFormat(std.testing.allocator,
        \\use {one} from "one";
    );
}

test "format: use ---- multiple imports" {
    try assertFormat(std.testing.allocator,
        \\use {one} from "one";
        \\use {two} from "two";
    );
}

test "format: use ---- nested path" {
    try assertFormat(std.testing.allocator,
        \\use {one, two, three} from "one/two/three";
    );
}

test "format: use ---- ordered imports" {
    try assertFormat(std.testing.allocator,
        \\use {four, five} from "four/five";
        \\use {one, two, three} from "one/two/three";
    );
}

test "format: use ---- selective imports" {
    try assertFormat(std.testing.allocator,
        \\use {fun, fun2, fun3} from "one";
    );
}

test "format: use ---- mixed type and function imports" {
    try assertFormat(std.testing.allocator,
        \\use {One, Two, fun1, fun2} from "one";
    );
}

// ── multiple statements ──────────────────────────────────────────────────────

test "format: multiple statements with use and types" {
    try assertFormat(std.testing.allocator,
        \\use {one} from "one";
        \\use {three} from "three";
        \\use {two} from "two";
        \\
        \\pub val One = struct {};
        \\
        \\pub val Two = struct {};
        \\
        \\pub val Three = struct {};
        \\
        \\pub val Four = struct {};
    );
}

// ── lambda expressions ───────────────────────────────────────────────────────

test "format: lambda ---- simple no params" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn() {
        \\        x;
        \\    };
        \\}
    );
}

test "format: lambda ---- with param" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn(x) {
        \\        x;
        \\    };
        \\}
    );
}

test "format: lambda ---- multi-statement body" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn() {
        \\        1;
        \\        2;
        \\    };
        \\}
    );
}

test "format: lambda ---- case expression in body" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val f = fn(x) {
        \\        case x {
        \\            1 -> 1;
        \\            _ -> 0;
        \\        };
        \\    };
        \\}
    );
}

// ── call expressions ─────────────────────────────────────────────────────────

test "format: call ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run();
        \\}
    );
}

test "format: call ---- single argument" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run(1);
        \\}
    );
}

test "format: call ---- labeled argument" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    run(with: 1);
        \\}
    );
}

test "format: call ---- constructor with labeled args" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    Person(name: "Al", is_cool: VeryTrue);
        \\}
    );
}

// ── tuple expressions ────────────────────────────────────────────────────────

test "format: tuple ---- empty" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #();
        \\}
    );
}

test "format: tuple ---- single element" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(1);
        \\}
    );
}

test "format: tuple ---- two elements" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(1, 2);
        \\}
    );
}

test "format: tuple ---- three elements" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(1, 2, 3);
        \\}
    );
}

// ── function statements ──────────────────────────────────────────────────────

test "format: fn statement ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main(one: string, two: string, three: string) {
        \\    null;
        \\}
    );
}

test "format: fn statement ---- discarded parameter" {
    try assertFormat(std.testing.allocator,
        \\fn main(_discarded: string) {
        \\    null;
        \\}
    );
}

test "format: fn statement ---- with return type" {
    try assertFormat(std.testing.allocator,
        \\fn main() -> null {
        \\    null;
        \\}
    );
}

test "format: fn statement ---- trailing comment" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    null;
        \\    // Done
        \\}
    );
}

// ── binary operators ─────────────────────────────────────────────────────────

test "format: binary ---- logical and" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True && False;
        \\}
    );
}

test "format: binary ---- logical or" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True || False;
        \\}
    );
}

test "format: binary ---- comparison less than" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 < 1;
        \\}
    );
}

test "format: binary ---- comparison less than or equal" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 <= 1;
        \\}
    );
}

test "format: binary ---- equality" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 == 1;
        \\}
    );
}

test "format: binary ---- inequality" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 != 1;
        \\}
    );
}

test "format: binary ---- addition" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 + 1;
        \\}
    );
}

test "format: binary ---- subtraction" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 - 1;
        \\}
    );
}

test "format: binary ---- multiplication" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 * 1;
        \\}
    );
}

test "format: binary ---- division" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 / 1;
        \\}
    );
}

test "format: binary ---- modulo" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1 % 1;
        \\}
    );
}

// ── integer literals ─────────────────────────────────────────────────────────

test "format: int ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn i() {
        \\    1;
        \\}
    );
}

test "format: int ---- with underscores" {
    try assertFormat(std.testing.allocator,
        \\fn i() {
        \\    121_234_345_989_000;
        \\}
    );
}

test "format: int ---- negative" {
    try assertFormat(std.testing.allocator,
        \\fn i() {
        \\    -12_928_347_925;
        \\}
    );
}

// ── float literals ───────────────────────────────────────────────────────────

test "format: float ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    1.0;
        \\}
    );
}

test "format: float ---- negative" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    -1.0;
        \\}
    );
}

test "format: float ---- with decimals" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    9999.6666;
        \\}
    );
}

test "format: float ---- scientific notation" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    1.0e1;
        \\}
    );
}

test "format: float ---- negative exponent" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    1.0e-1;
        \\}
    );
}

// ── string literals ──────────────────────────────────────────────────────────

test "format: string ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    "Hello";
        \\}
    );
}

test "format: string ---- escape sequences" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    "\\n\\t";
        \\}
    );
}

// ── sequential expressions ───────────────────────────────────────────────────

test "format: seq ---- multiple expressions" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1;
        \\    2;
        \\    3;
        \\}
    );
}

test "format: seq ---- call then literal" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    first(1);
        \\    1;
        \\}
    );
}

// ── list expressions ─────────────────────────────────────────────────────────

test "format: list ---- empty" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [];
        \\}
    );
}

test "format: list ---- single element" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [1];
        \\}
    );
}

test "format: list ---- multiple elements" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [1, 2, 3];
        \\}
    );
}

test "format: list ---- with spread" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [1, 2, 3, ..x];
        \\}
    );
}

test "format: list ---- nested lists" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        really_long_variable_name,
        \\        really_long_variable_name,
        \\        really_long_variable_name,
        \\        [1, 2, 3],
        \\        really_long_variable_name,
        \\    ];
        \\}
    );
}

// ── let bindings ─────────────────────────────────────────────────────────────

test "format: let ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = 1;
        \\    null;
        \\}
    );
}

test "format: let ---- block value" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = @block{
        \\        1;
        \\        2;
        \\    };
        \\    null;
        \\}
    );
}

test "format: let ---- case value" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val y = case x {
        \\        1 -> 1;
        \\        _ -> 0;
        \\    };
        \\    y;
        \\}
    );
}

test "format: let ---- fn value" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = fn(x) {
        \\        x;
        \\    };
        \\    x;
        \\}
    );
}

// ── patterns ─────────────────────────────────────────────────────────────────

test "format: pattern ---- simple let" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val x = 1;
        \\    val y = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- discard" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val _ = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- list empty" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val [] = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- list with elements" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val [1, 2, 3, 4] = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- list with spread" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val [1, 2, 3, 4, ..x] = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- constructor" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val True = 1;
        \\    null;
        \\}
    );
}

test "format: pattern ---- constructor with fields" {
    try assertFormat(std.testing.allocator,
        \\val Result = enum { Ok(value: i32), Error(message: String) };
        \\
        \\fn main() {
        \\    val result = Result.Ok(42);
        \\    val Ok(value) = case result {
        \\        Ok ok -> ok;
        \\        Error err -> Result.Ok(-1);
        \\    };
        \\    null;
        \\}
    );
}

test "format: pattern ---- constructor with labeled fields" {
    try assertFormat(std.testing.allocator,
        \\val Person = enum { Person(name: String, age: i32), Dog(name: String, age: i32) };
        \\
        \\fn main() {
        \\    val thing = Person.Dog("bob", 121);
        \\    val Person(name, age) = case thing {
        \\        Person person -> person;
        \\        Dog dog -> Person.Person(dog.name, dog.age);
        \\    };
        \\    null;
        \\}
    );
}

// ── case expressions ─────────────────────────────────────────────────────────

test "format: case ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> 1;
        \\        _ -> 0;
        \\    };
        \\}
    );
}

test "format: case ---- block body" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> {
        \\            1;
        \\            2;
        \\        };
        \\        _ -> 1;
        \\    };
        \\}
    );
}

test "format: case ---- multiple subjects" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1, 2, 3, 4 {
        \\        1, 2, 3, 4 -> 1;
        \\        _, _, _, _ -> 0;
        \\    };
        \\}
    );
}

test "format: case ---- alternative patterns" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 | 2 | 3 -> null;
        \\    };
        \\}
    );
}

test "format: case ---- nested case" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> case x {
        \\            1 -> 1;
        \\            _ -> 0;
        \\        };
        \\        _ -> 1;
        \\    };
        \\}
    );
}

test "format: case ---- fn body" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> fn(x) {
        \\            x;
        \\        };
        \\        _ -> 1;
        \\    };
        \\}
    );
}

test "format: case ---- with empty lines between arms" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case x {
        \\        1 -> 2;
        \\
        \\        2 -> 3;
        \\
        \\        _ -> 0;
        \\    };
        \\}
    );
}

// ── field access ─────────────────────────────────────────────────────────────

test "format: access ---- simple field access" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one.two;
        \\}
    );
}

test "format: access ---- chained field access" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one.two.three.four;
        \\}
    );
}

test "format: access ---- tuple access" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    tup.0;
        \\}
    );
}

test "format: access ---- chained tuple access" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    tup.1.2;
        \\}
    );
}

// ── todo and panic ───────────────────────────────────────────────────────────

test "format: todo ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    todo;
        \\}
    );
}

test "format: todo ---- with message" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @todo("todo with a label");
        \\}
    );
}

test "format: panic ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic();
        \\}
    );
}

test "format: panic ---- with message" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic("panicking");
        \\}
    );
}

// ── comments ─────────────────────────────────────────────────────────────────

test "format: comments ---- single line before fn" {
    try assertFormat(std.testing.allocator,
        \\// one
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: comments ---- multiple lines before fn" {
    try assertFormat(std.testing.allocator,
        \\// one
        \\// two
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: comments ---- inside function" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    // Hello
        \\    // world
        \\    1;
        \\}
    );
}

test "format: comments ---- between statements" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    // Hello
        \\    1;
        \\    // world
        \\    2;
        \\}
    );
}

test "format: comments ---- trailing after function" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    x;
        \\}
        \\// Hello world
        \\// ok!
    );
}

test "format: comments ---- inside list" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        // One
        \\        1,
        \\        // Two
        \\        2,
        \\    ];
        \\}
    );
}

test "format: comments ---- inside call" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    one(
        \\        // One
        \\        1,
        \\        // Two
        \\        2,
        \\    );
        \\}
    );
}

// ── empty lines ──────────────────────────────────────────────────────────────

test "format: empty lines ---- single between statements" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1;
        \\
        \\    2;
        \\}
    );
}

test "format: empty lines ---- between comments" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    // one
        \\
        \\    // two
        \\
        \\    3;
        \\}
    );
}

// ── doc comments ─────────────────────────────────────────────────────────────

test "format: doc comment ---- before fn" {
    try assertFormat(std.testing.allocator,
        \\/// This is a documented function
        \\fn main() {
        \\    null;
        \\}
    );
}

test "format: doc comment ---- multiline before fn" {
    try assertFormat(std.testing.allocator,
        \\/// First line of documentation
        \\/// Second line of documentation
        \\fn greet(name: string) -> string {
        \\    return name;
        \\}
    );
}

test "format: doc comment ---- before struct" {
    try assertFormat(std.testing.allocator,
        \\/// User account structure
        \\val Account = struct {};
    );
}

test "format: doc comment ---- before enum" {
    try assertFormat(std.testing.allocator,
        \\/// Color enumeration
        \\val Color = enum { Red, Blue };
    );
}

test "format: doc comment ---- before interface" {
    try assertFormat(std.testing.allocator,
        \\/// Drawable interface
        \\val Drawable = interface {};
    );
}

test "format: doc comments ---- module level" {
    try assertFormat(std.testing.allocator,
        \\//// One
        \\//// Two
        \\//// Three
        \\
        \\pub fn main() {
        \\    val x = 1;
        \\
        \\    x;
        \\}
    );
}

// ── constants ────────────────────────────────────────────────────────────────

test "format: const ---- integer" {
    try assertFormat(std.testing.allocator,
        \\val MAX = 100;
    );
}

test "format: const ---- float" {
    try assertFormat(std.testing.allocator,
        \\val PI = 3.14;
    );
}

test "format: const ---- string" {
    try assertFormat(std.testing.allocator,
        \\val greeting = "Hello";
    );
}

test "format: const ---- multiple constants" {
    try assertFormat(std.testing.allocator,
        \\val str = "a string";
        \\
        \\val int = 4;
        \\
        \\val float = 3.14;
    );
}

// ── binary operator precedenceence ───────────────────────────────────────────

test "format: precedence ---- parentheses around addition" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    (1 + 2) * 3;
        \\}
    );
}

test "format: precedence ---- multiplication on right" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    3 * (1 + 2);
        \\}
    );
}

test "format: precedence ---- logical or in parentheses" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    True != (a == b);
        \\}
    );
}

// ── record spread (adapted to botopink) ──────────────────────────────────────

// ── negation ─────────────────────────────────────────────────────────────────

test "format: negation ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    !x;
        \\}
    );
}

test "format: negation ---- block" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    !@block{
        \\        123;
        \\        x;
        \\    };
        \\}
    );
}

// ── list formatting with comments ────────────────────────────────────────────

test "format: list ---- comments inside" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        // First!
        \\        // First?
        \\        1,
        \\        // Spread!
        \\        // Spread?
        \\        ..[2, 3],
        \\    ];
        \\}
    );
}

test "format: list ---- trailing comments" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        1,
        \\        2,
        \\        // One and two are above me.
        \\    ];
        \\}
    );
}

// ── pipeline expressions (adapted to botopink) ───────────────────────────────

test "format: pipeline ---- simple" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    |> really_long_variable_name
        \\    |> really_long_variable_name
        \\    |> really_long_variable_name;
        \\}
    );
}

test "format: pipeline ---- in list" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        1
        \\        |> succ
        \\        |> succ,
        \\        2,
        \\        3,
        \\    ];
        \\}
    );
}

test "format: pipeline ---- with comments" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    // 1
        \\    |> func1
        \\    // 2
        \\    |> func2;
        \\}
    );
}

// ── compact lists ────────────────────────────────────────────────────────────

test "format: list ---- compact wrapping integers" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [100, 200, 300, 400, 500, 600, 700, 800, 900, 1000, 1100, 1200, 1300, 1400, 1500, 1600, 1700, 1800, 1900, 2000];
        \\}
    );
}

test "format: list ---- compact wrapping strings" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve"];
        \\}
    );
}

// ── labeled arguments with comments ──────────────────────────────────────────

test "format: labeled args ---- with comments" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    Emulator(
        \\        // one
        \\        one: 1,
        \\        // two
        \\        two: 1,
        \\    );
        \\}
    );
}

// ── complex formatting scenarios ─────────────────────────────────────────────

// ── tuple destructuring ─────────────────────────────────────────────────────

test "format: tuple destruct ---- val binding" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    val #(a, b) = #(1, 2);
        \\}
    );
}

test "format: tuple destruct ---- var binding" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    var #(x, y) = #(10, 20);
        \\}
    );
}

test "format: tuple destruct ---- function parameter" {
    try assertFormat(std.testing.allocator,
        \\fn process(#(x, y): #(i32, i32)) -> i32 {
        \\    return x;
        \\}
    );
}

test "format: tuple destruct ---- long variable names" {
    try assertFormat(std.testing.allocator,
        \\fn extract_coordinates() {
        \\    val #(longitude, latitude) = get_coordinates();
        \\}
    );
}

test "format: tuple destruct ---- with try-catch" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

// ── record patterns with comments ────────────────────────────────────────────

// ── multiline strings in function calls ──────────────────────────────────────

// ── pipeline as function argument ────────────────────────────────────────────

// ── comments inside constant lists ───────────────────────────────────────────

test "format: const list ---- with comments" {
    try assertFormat(std.testing.allocator,
        \\val wibble = [
        \\    // A comment
        \\    1, 2,
        \\    // Another comment
        \\    3,
        \\    // One last comment
        \\];
    );
}

// ── comments inside constant tuples ──────────────────────────────────────────

test "format: const tuple ---- with comments" {
    try assertFormat(std.testing.allocator,
        \\val wibble = #(
        \\    // A comment
        \\    1,
        \\    2,
        \\    // Another comment
        \\    3,
        \\    // One last comment
        \\);
    );
}

// ── comments at end of anonymous function ────────────────────────────────────

test "format: comments ---- at end of anonymous fn" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    fn() {
        \\        1;
        \\        // a final comment
        \\
        \\        // another final comment
        \\        // at the end of the block
        \\    };
        \\}
    );
}

// ── multiline comment in case block ──────────────────────────────────────────

test "format: comments ---- multiline inside case block" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case list {
        \\        [] -> acc;
        \\        [_, ..rest] -> rest |> do_len(acc + 1);
        \\        // Even the opposite wouldn't be optimised:
        \\        // { acc + 1 } |> do_len(rest, _);
        \\    };
        \\}
    );
}

// ── complex formatting scenarios ─────────────────────────────────────────────

test "format: complex ---- case with long message" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    case x {
        \\        _ -> [123];
        \\    };
        \\}
    );
}

test "format: complex ---- function arguments after comment" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    wibble(
        \\        // Wobble
        \\        1 + 1,
        \\        "wibble",
        \\    );
        \\}
    );
}

test "format: complex ---- tuple items after comment" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    #(
        \\        // Wobble
        \\        1 + 1,
        \\        "wibble",
        \\    );
        \\}
    );
}

test "format: complex ---- list items after comment" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    [
        \\        // Wobble
        \\        1 + 1,
        \\        "wibble",
        \\    ];
        \\}
    );
}

// ── todo/panic/echo with comments ────────────────────────────────────────────

test "format: todo ---- with message and comment" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @todo("wibble");
        \\}
    );
}

test "format: panic ---- with message and comment" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    @panic("wibble");
        \\}
    );
}

// ── multiline string in function calls ──────────────────────────────────────

test "format: multiline string ---- as function argument" {
    try assertFormat(std.testing.allocator,
        \\fn main() {
        \\    wibble(
        \\        wobble,
        \\        """
        \\        This is a multiline string.
        \\        It can span several lines.
        \\        """,
        \\        wibble,
        \\        wibble,
        \\    );
        \\}
    );
}

// ── idempotency tests for new patterns ───────────────────────────────────────

test "format: idempotent ---- case with empty lines" {
    try assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    case x {
        \\        1 -> 2;
        \\
        \\        2 -> 3;
        \\
        \\        _ -> 0;
        \\    };
        \\}
    );
}

test "format: idempotent ---- pipeline with comments" {
    try assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    1
        \\    // 1
        \\    |> func1
        \\    // 2
        \\    |> func2;
        \\}
    );
}

test "format: idempotent ---- nested case expressions" {
    try assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    case 1 {
        \\        1 -> case x {
        \\            1 -> 1;
        \\            _ -> 0;
        \\        };
        \\        _ -> 1;
        \\    };
        \\}
    );
}

test "format: idempotent ---- struct with methods" {
    try assertIdempotent(std.testing.allocator,
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
        \\};
    );
}

test "format: idempotent ---- interface with default method" {
    try assertIdempotent(std.testing.allocator,
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self),
        \\    default fn log(self: Self) {
        \\        Console.WriteLine("Rendering object with color: " + self.color);
        \\    }
        \\};
    );
}

test "format: idempotent ---- enum with payload variants" {
    try assertIdempotent(std.testing.allocator,
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
    );
}

test "format: idempotent ---- complex case with OR patterns" {
    try assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    case n {
        \\        0 | 2 | 4 | 6 | 8 -> "even digit";
        \\        1 | 3 | 5 | 7 | 9 -> "odd digit";
        \\        _ -> "not a digit";
        \\    };
        \\}
    );
}

test "format: idempotent ---- lambda with multiple trailing blocks" {
    try assertIdempotent(std.testing.allocator,
        \\fn main() {
        \\    executar {
        \\        ok;
        \\    } erro: {
        \\        fail;
        \\    };
        \\}
    );
}

test "format: array ---- prepend with empty array" {
    try assertFormat(std.testing.allocator,
        \\val list1 = [1, ..[]];
    );
}

test "format: array ---- prepend with single element array" {
    try assertFormat(std.testing.allocator,
        \\val list2 = [1, 2, ..[3]];
    );
}

test "format: array ---- prepend with multiple elements array" {
    try assertFormat(std.testing.allocator,
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "format: array ---- prepend with identifier" {
    try assertFormat(std.testing.allocator,
        \\val rest = [3, 4];
        \\
        \\val list = [1, 2, ..rest];
    );
}

test "format: idempotent ---- array prepend" {
    try assertIdempotent(std.testing.allocator,
        \\val list1 = [1, ..[]];
        \\val list2 = [1, 2, ..[3]];
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "format: assert pattern ---- with catch throw" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert Person(name, age) = r catch throw Error("is not person");
        \\}
    );
}

test "format: assert pattern ---- with catch default value" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "format: assert pattern ---- with list pattern" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [first, ..] = items catch throw Error("not a list");
        \\}
    );
}

test "format: assert pattern ---- with string literal" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert "hello" = greeting catch throw Error("not hello");
        \\}
    );
}

test "format: assert pattern ---- with number literal" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert 42 = answer catch throw Error("not 42");
        \\}
    );
}

test "format: assert pattern ---- with enum variant" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert Ok(value) = result catch throw Error("not ok");
        \\}
    );
}

test "format: assert pattern ---- with empty list" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [] = list catch throw Error("not empty");
        \\}
    );
}

test "format: assert pattern ---- with multiple element list" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [1, 2, 3] = numbers catch throw Error("not matching");
        \\}
    );
}

test "format: assert pattern ---- with list and rest" {
    try assertFormat(std.testing.allocator,
        \\fn f() {
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}
