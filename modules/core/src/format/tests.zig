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
        \\
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
        \\            else -> "nonzero";
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
        \\            else -> "not a digit";
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
