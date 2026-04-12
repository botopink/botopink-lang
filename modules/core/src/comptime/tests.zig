/// Type system tests for the botopink compiler.
///
/// Two kinds of tests:
///   1. AST snapshots ---- validate inferred AST structure via `assertTypeAst`.
///   2. Error snapshots ---- verify type error messages via `assertTypeErrorSnap`.
const std = @import("std");
const lexerMod = @import("../lexer.zig");
const parserMod = @import("../parser.zig");
const snapMod = @import("../utils/snap.zig");
const prettyMod = @import("../utils/pretty.zig");
const T = @import("./types.zig");
const envMod = @import("env.zig");
const inferMod = @import("infer.zig");
const comptimeMod = @import("../comptime.zig");
const errorMod = @import("error.zig");
const snapshot = @import("snapshot.zig");
const Module = @import("../module.zig").Module;
const format = @import("../format.zig");

const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;

fn slugify(comptime s: []const u8) []const u8 {
    const n: usize = comptime blk: {
        var count: usize = 0;
        var sep = true;
        for (s) |c| {
            if (std.ascii.isAlphanumeric(c)) {
                count += 1;
                sep = false;
            } else if (!sep) {
                count += 1;
                sep = true;
            }
        }
        if (sep and count > 0) count -= 1;
        break :blk count;
    };
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

fn buildRootPathFromSrc(comptime loc: std.builtin.SourceLocation) []const u8 {
    const slug = comptime slugFromSrc(loc);
    return comptime std.fmt.comptimePrint(".botopinkbuild/comptime/{s}", .{slug});
}

// ── assertTypeAst ---- validate AST structure via JSON snapshots ───────────────

/// Validate the AST structure of inferred types via JSON snapshots.
///
/// Produces a multi-section snapshot for each module:
///   ----- SOURCE CODE -- name.bp
///   <source code>
///
///   ----- TYPED AST JSON -- name.json
///   <JSON array of binding representations>
///
/// For `val` bindings whose value is a `case` expression the JSON captures
/// the full case structure:
///   `{ "ast": "case", "param": "<subject_type>", "match": [...], "returnType": "..." }`
/// For all other bindings the JSON captures:
///   `{ "ast": "val", "returnType": "..." }` or `{ "ast": "fn_def", ... }`
fn assertComptimeAst(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) !void {
    const io = std.testing.io;
    const runtimes = [_]comptimeMod.ComptimeRuntime{ .node, .erlang };
    const base_slug = comptime slugFromSrc(loc);

    for (runtimes) |runtime| {
        var build_root_buf: [512]u8 = undefined;
        const build_root_path = try std.fmt.bufPrint(&build_root_buf, ".botopinkbuild/comptime/{s}", .{base_slug});

        var session = try comptimeMod.compile(allocator, modules, io, runtime, build_root_path);
        defer session.deinit(allocator);

        // Collect outputs
        var outputs = std.ArrayList(comptimeMod.ComptimeOutput).empty;
        defer outputs.deinit(allocator);

        for (session.outputs.items) |output| {
            try outputs.append(allocator, output);
        }

        // Save snapshots in separate directories: comptime/node/ and comptime/erlang/
        const runtime_path = switch (runtime) {
            .node => "comptime/node",
            .erlang => "comptime/erlang",
        };
        var snap_buf: [512]u8 = undefined;
        const snap_slug = try std.fmt.bufPrint(&snap_buf, "{s}/{s}", .{ runtime_path, base_slug });
        try snapshot.assertComptimeAstWithPath(allocator, snap_slug, outputs.items);
    }
}

/// Convenience wrapper for single-module AST validation.
fn assertComptimeAstSingle(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    return assertComptimeAst(allocator, loc, &.{.{ .path = "", .source = src }});
}

// ── assertTypeErrorSnap ---- snapshot the type error message ────────────────────

/// Returns the text of the `line`-th line (1-based) in `src`.
fn getSourceLine(src: []const u8, line: usize) []const u8 {
    var currentLine: usize = 1;
    var start: usize = 0;
    var i: usize = 0;
    while (i < src.len) : (i += 1) {
        if (currentLine == line) {
            var end = i;
            while (end < src.len and src[end] != '\n') end += 1;
            return src[start..end];
        }
        if (src[i] == '\n') {
            currentLine += 1;
            start = i + 1;
        }
    }
    return src[start..];
}

/// Render a TypeError as a Gleam-style diagnostic string.
/// Caller owns the returned slice (allocated from `allocator`).
fn renderTypeError(
    allocator: std.mem.Allocator,
    src: []const u8,
    err: errorMod.TypeError,
) ![]u8 {
    // Use an arena so intermediate allocPrint strings are freed together.
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const tmp = arena.allocator();

    var out: std.ArrayList(u8) = .empty;
    errdefer out.deinit(allocator);

    // ----- SOURCE CODE section
    try out.appendSlice(allocator, "----- SOURCE CODE\n");
    try out.appendSlice(allocator, src);
    if (src.len > 0 and src[src.len - 1] != '\n') try out.append(allocator, '\n');
    try out.appendSlice(allocator, "\n----- ERROR\n");

    // Error title
    const title = switch (err.kind) {
        .typeMismatch => "type mismatch",
        .unboundVariable => "unbound variable",
        .arityMismatch => "arity mismatch",
        .unknownField => "unknown field",
        .notARecord => "not a record type",
        .recursiveType => "recursive type",
        .unknownTypeName => "unknown type",
        .missingField => "missing field",
    };
    try out.appendSlice(allocator, try std.fmt.allocPrint(tmp, "error: {s}\n", .{title}));

    // Location box if available
    if (err.loc) |errLoc| {
        const lineText = getSourceLine(src, errLoc.line);
        const col0 = if (errLoc.col > 0) errLoc.col - 1 else 0;
        // ┌─ :line:col
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "  \u{250c}\u{2500} :{d}:{d}\n",
            .{ errLoc.line, errLoc.col },
        ));
        // │
        try out.appendSlice(allocator, "  \u{2502}\n");
        // N │ source line
        try out.appendSlice(allocator, try std.fmt.allocPrint(
            tmp,
            "{d} \u{2502} {s}\n",
            .{ errLoc.line, lineText },
        ));
        // │ spaces^
        try out.appendSlice(allocator, "  \u{2502} ");
        for (0..col0) |_| try out.append(allocator, ' ');
        try out.appendSlice(allocator, "^\n");
    }

    // Error details
    switch (err.kind) {
        .typeMismatch => |m| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  expected: {s}\n  found:    {s}\n",
                .{ try snapshot.typeNameOf(tmp, m.expected), try snapshot.typeNameOf(tmp, m.got) },
            ));
        },
        .unboundVariable => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not in scope\n",
                .{name},
            ));
        },
        .arityMismatch => |a| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' expected {d} argument(s), got {d}\n",
                .{ a.name, a.expected, a.got },
            ));
        },
        .unknownField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' has no field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
        .notARecord => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' is not a record or struct type\n",
                .{name},
            ));
        },
        .recursiveType => {
            try out.appendSlice(allocator, "\n  type variable would reference itself (infinite type)\n");
        },
        .unknownTypeName => |name| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  the type '{s}' is not defined in this scope\n",
                .{name},
            ));
        },
        .missingField => |f| {
            try out.appendSlice(allocator, try std.fmt.allocPrint(
                tmp,
                "\n  '{s}' requires field '{s}'\n",
                .{ f.typeName, f.field },
            ));
        },
    }

    return try out.toOwnedSlice(allocator);
}

/// Parse `src`, expect inference to fail, snapshot the error description.
fn assertTypeErrorSnap(
    allocator: std.mem.Allocator,
    comptime loc: std.builtin.SourceLocation,
    src: []const u8,
) !void {
    var arena = std.heap.ArenaAllocator.init(allocator);
    defer arena.deinit();
    const alloc = arena.allocator();

    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try p.parse(alloc);
    defer program.deinit(alloc);

    var env = Env.init(alloc);
    defer env.deinit();
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, allocator);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));

    const result = inferMod.inferProgram(&env, program);
    try std.testing.expectError(error.TypeError, result);
    const err = env.lastError orelse return error.TestExpectedEqual;

    const desc = try renderTypeError(allocator, src, err);
    defer allocator.free(desc);

    const base_slug = comptime slugFromSrc(loc);
    
    // Save the same error snapshot in both node/errors/ and erlang/errors/
    // Error messages are runtime-agnostic (type inference happens before codegen)
    const runtimes = [_][]const u8{ "node", "erlang" };
    for (runtimes) |runtime| {
        var snap_buf: [512]u8 = undefined;
        const snap_slug = try std.fmt.bufPrint(&snap_buf, "comptime/{s}/errors/{s}", .{ runtime, base_slug });
        try snapMod.checkText(allocator, snap_slug, desc);
    }
}

// ── inference tests ───────────────────────────────────────────────────────────

test "infer: integer and float literals" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = 42;
        \\val y = 3.14;
    );
}

test "infer: string literal" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val greeting = "hello";
    );
}

test "infer: binary operators" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val sum = 1 + 2;
        \\val product = 3.0 * 2.0;
        \\val joined = "a" + "b";
    );
}

test "infer: local binding inside comptime" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val hash = comptime { break 6364 + 11; };
    );
}

test "infer: enum constructors" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
        \\val c1 = Color.Red;
        \\val c2 = Color.Rgb(r: 255, g: 0, b: 0);
        \\val c3: Color = .Red;
    );
}

// ── records ───────────────────────────────────────────────────────────────────

test "infer: record constructor" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = record { x: i32, y: i32 };
        \\val p = Point(x: 1, y: 2);
    );
}

test "infer: generic record Pair<A, B>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Pair = record <A, B> { first: A, second: B };
        \\val p = Pair(first: 42, second: "hello");
    );
}

test "infer: record with method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = record {
        \\    lat: f64,
        \\    lon: f64,
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\};
        \\val g = GPSCoordinates(lat: 5.0, lon: 3.0);
    );
}

test "infer: generic record Triple<A, B, C>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Triple = record <A, B, C> { first: A, second: B, third: C };
        \\val t = Triple(first: 1, second: "x", third: 3.14);
    );
}

// ── structs ───────────────────────────────────────────────────────────────────

test "infer: struct constructor" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Counter = struct {
        \\    count: i32 = 0,
        \\};
        \\val c = Counter(0);
    );
}

test "infer: struct with private field and method" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Account = struct {
        \\    _balance: i32 = 0,
        \\    fn deposit(self: Self, amount: i32) {
        \\        self._balance += amount;
        \\    }
        \\};
        \\val a = Account(0);
    );
}

test "infer: generic struct Box<T>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Box = struct <T> {
        \\    value: T = todo,
        \\};
        \\val b = Box(42);
    );
}

// ── generic enums ─────────────────────────────────────────────────────────────

test "infer: generic enum Option<T> ---- unit and payload variants" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Option = enum <T> {
        \\    None,
        \\    Some(value: T),
        \\};
        \\val n = Option.None;
        \\val s = Option.Some(value: 42);
    );
}

test "infer: generic enum Result<T> with Ok and Err" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Result = enum <T> {
        \\    Ok(value: T),
        \\    Err(message: string),
        \\};
        \\pub fn isOk(r: Result) -> bool {
        \\    return true;
        \\}
        \\val r = Result.Ok(value: 42);
        \\val ok = isOk(r);
    );
}

// ── case expressions ──────────────────────────────────────────────────────────

test "infer: case on enum variants ---- all arms return string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\}
        \\val subject = Color.Red;
        \\val label = case subject {
        \\    Red -> "red";
        \\    Green -> "green";
        \\    Blue -> "blue";
        \\    else -> "other";
        \\};
    );
}

test "infer: case on integer with wildcard" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val desc = case 42 {
        \\    0 -> "zero";
        \\    else -> "nonzero";
        \\};
    );
}

test "infer: case with OR patterns" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    else -> "odd";
        \\};
    );
}

test "infer: case with variant field bindings ---- body does not use bound vars" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\    Point,
        \\}
        \\val s = Shape.Point;
        \\val label = case s {
        \\    Circle(radius) -> "circle";
        \\    Square(side)   -> "square";
        \\    Point          -> "point";
        \\    else           -> "other";
        \\};
    );
}

// ── pub fn ────────────────────────────────────────────────────────────────────

test "infer: pub fn basic ---- greet returns string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "Hello, " + name;
        \\}
        \\val msg = greet("world");
    );
}

test "infer: pub fn generic ---- identity<T>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn identity<T>(x: T) -> T {
        \\    return x;
        \\}
        \\val r = identity(42);
    );
}

test "infer: pub fn with local val binding in body" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn compute(x: i32) -> i32 {
        \\    val doubled = x + x;
        \\    return doubled;
        \\}
        \\val result = compute(21);
    );
}

test "infer: pub fn with comptime params" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: i32) -> string {
        \\    todo;
        \\}
        \\val r = repeat("hi", 3);
    );
}

test "infer: pub fn generic with two type params<T, R>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn transform<T, R>(x: T, y: R) -> R {
        \\    return y;
        \\}
        \\val result = transform(42, "mapped");
    );
}

test "infer: pub fn using enum + case in body" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
        \\pub fn label(d: Direction) -> string {
        \\    val result = case d {
        \\        North -> "N";
        \\        South -> "S";
        \\        East -> "E";
        \\        West -> "W";
        \\        else -> "?";
        \\    };
        \\    return result;
        \\}
        \\val n = label(Direction.North);
    );
}

// ── val declarations ──────────────────────────────────────────────────────────

test "infer: val with explicit type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x: i32 = 42;
        \\val y: f64 = 3.14;
        \\val msg: string = "hello";
    );
}

test "infer: val dependency chain" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val a = 10;
        \\val b = a + 5;
        \\val c = b + a;
    );
}

test "infer: lt comparison returns bool" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val less = 1 < 2;
        \\val bigger = 10 < 5;
    );
}

test "infer: dotIdent resolved from type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Blue,
        \\};
        \\val c: Color = .Red;
    );
}

test "infer comptime: expressions of multiple types" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val pi      = comptime 3.14 * 2.0;
        \\val maxVal  = comptime 100 + 1;
        \\val banner  = comptime "Hello, " + "World";
    );
}

// ── implement (produces no binding) ──────────────────────────────────────────

test "infer: generic interface Container<T>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Container = interface <T> {
        \\    fn fetch(self: Self) -> T;
        \\    fn store(self: Self, value: T);
        \\}
    );
}

test "infer: implement block is invisible to the binding list" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    fn draw(self: Self);
        \\};
        \\val Circle = record { radius: f64 };
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        todo;
        \\    }
        \\};
        \\val c = Circle(radius: 5.0);
    );
}

// ── error cases ───────────────────────────────────────────────────────────────

// type mismatch ───────────────────────────────────────────────────────────────

test "infer error: type mismatch ---- i32 + bool" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 1 + true;
    );
}

test "infer: concat with i32 rhs ---- coerces to string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val s = "hello" + 42;
    );
}

test "infer: concat with i32 lhs ---- coerces to string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val s = 1 + "hello";
    );
}

test "infer error: type mismatch ---- mul with non-numeric" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val bad = 3.14 * "oops";
    );
}

test "infer error: type mismatch ---- function argument wrong type" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn double(x: i32) -> i32 {
        \\    todo;
        \\}
        \\val bad = double("hello");
    );
}

test "infer error: type mismatch ---- val annotation mismatch" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x: string = 42;
    );
}

test "infer: case arms with different types ---- string | i32 union" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> "zero";
        \\    else -> 1;
        \\};
    );
}

test "infer: case arms with same type ---- no union" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val label = case 42 {
        \\    0 -> "zero";
        \\    1 -> "one";
        \\    else -> "many";
        \\};
    );
}

test "infer: case arms three distinct types ---- union of three" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = case 0 {
        \\    0 -> "zero";
        \\    1 -> 42;
        \\    else -> 3.14;
        \\};
    );
}

// arity mismatch ──────────────────────────────────────────────────────────────

test "infer error: arity mismatch ---- too many arguments" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "hi";
        \\}
        \\val bad = greet("a", "extra");
    );
}

test "infer error: arity mismatch ---- too few arguments" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    todo;
        \\}
        \\val bad = add(1);
    );
}

test "infer error: arity mismatch ---- zero-param function called with argument" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\pub fn hello() -> string {
        \\    todo;
        \\}
        \\val bad = hello(42);
    );
}

// unbound variable ────────────────────────────────────────────────────────────

test "infer error: unbound variable ---- undefined identifier" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x = undefinedIdent;
    );
}

test "infer error: unbound variable ---- undefined function call" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\val x = undefinedFn(42);
    );
}

test "infer error: not a record ---- destructure val binding on primitive" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn describe(x: i32) -> string {
        \\    val { result } = x;
        \\    return result;
        \\}
    );
}

// ── arrays and tuples ─────────────────────────────────────────────────────────

test "types: array literal infers element type" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val xs = ["hello", "world"];
    );
}

test "types: val with array type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "types: tuple literal infers element types" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t = #("56454", "85484");
    );
}

test "types: val with tuple type annotation" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "types: tuple literal with mixed types" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val t = #(12, "5452");
    );
}

// ── assertTypeAst: multi-module (use … from "…") ─────────────────────────────

test "assertTypeAst: single module ---- basic val bindings" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "", .source = 
        \\val x = 42;
        \\val name = "alice";
        },
    });
}

test "assertTypeAst: import single val from dependency module" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "constants", .source = 
        \\pub val MAX = 100;
        },
        .{ .path = "", .source = 
        \\use {MAX} from "constants";
        \\val limit = MAX;
        },
    });
}

test "assertTypeAst: import multiple vals from dependency module" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "config", .source = 
        \\pub val host = "localhost";
        \\pub val port = 8080;
        },
        .{ .path = "", .source = 
        \\use {host, port} from "config";
        \\val addr = host;
        \\val p = port;
        },
    });
}

test "assertTypeAst: import fn from dependency module" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "math", .source = 
        \\pub fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        },
        .{ .path = "", .source = 
        \\use {double} from "math";
        \\val result = double(21);
        },
    });
}

test "assertTypeAst: three-level chain ---- a imports b, b imports c" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "base", .source = 
        \\pub val VERSION = 1;
        },
        .{ .path = "mid", .source = 
        \\use {VERSION} from "base";
        \\pub val MAJOR = VERSION;
        },
        .{ .path = "", .source = 
        \\use {MAJOR} from "mid";
        \\val v = MAJOR;
        },
    });
}

test "infer error: import of val ---- unbound variable" {
    // `val SECRET` is private (no `pub`), so it is not exported to the registry.
    // The `use` declaration resolves nothing, leaving SECRET unbound in the
    // main module.  The type checker must report an unbound variable error.
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\use {SECRET} from "mod";
        \\val x = SECRET;
    );
}

test "assertTypeAst: unused dependency does not pollute main bindings" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "unused", .source = 
        \\val secret = "hidden";
        },
        .{ .path = "", .source = 
        \\val answer = 42;
        },
    });
}

test "assertTypeAst: import record constructor from dependency" {
    try assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "models", .source = 
        \\record Point { x: i32, y: i32 }
        },
        .{ .path = "", .source = 
        \\use {Point} from "models";
        \\val origin = Point(0, 0);
        },
    });
}

// ── optional types ────────────────────────────────────────────────────────────

test "infer: null literal ---- type is optional<?>" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x = null;
    );
}

test "infer: optional annotation ---- ?string val" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val msg: ?string = null;
    );
}

test "infer: optional annotation ---- ?i32 val with null" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val count: ?i32 = null;
    );
}

// ── if expression ─────────────────────────────────────────────────────────────

test "infer: if expression ---- result type from then branch" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn sign(n: i32) -> string {
        \\    val r = if (n > 0) { "positive"; };
        \\    return r;
        \\}
        \\val s = sign(1);
    );
}

test "infer: if expression ---- with else branch" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn describe(n: i32) -> string {
        \\    return if (n > 0) { "positive"; } else { "non-positive"; };
        \\}
        \\val s = describe(5);
    );
}

// ── var binding ───────────────────────────────────────────────────────────────

test "infer: var binding ---- mutable local inside fn" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn count() -> i32 {
        \\    var n = 0;
        \\    return n;
        \\}
        \\val r = count();
    );
}

test "infer: var binding ---- mutable string" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet() -> string {
        \\    var msg = "hello";
        \\    return msg;
        \\}
        \\val r = greet();
    );
}

// ── null-check binding ────────────────────────────────────────────────────────

test "infer: null-check binding ---- if (x) { e -> } body ignores binding" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn check() -> string {
        \\    var x = null;
        \\    if (x) { e ->
        \\        return "found";
        \\    };
        \\    return "none";
        \\}
        \\val r = check();
    );
}

// ── try / catch ───────────────────────────────────────────────────────────────

test "infer: try expression ---- result type unified with return" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn fetch() -> i32 {
        \\    todo;
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch();
        \\    return r;
        \\}
        \\val x = process();
    );
}

test "infer: try-catch ---- handler provides fallback" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn fetch() -> i32 {
        \\    todo;
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
        \\val x = safe();
    );
}

// ── pub val ───────────────────────────────────────────────────────────────────

test "infer: pub val ---- infers same as private val" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub val VERSION = 1;
        \\pub val NAME = "botopink";
    );
}

// ── variable assignment ───────────────────────────────────────────────────────

test "infer: assign ---- number literal to var" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = 10;
        \\}
        \\val r = f();
    );
}

test "infer: assign ---- string to var" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    var name = "old";
        \\    name = "new";
        \\}
        \\val r = f();
    );
}

test "infer: assign ---- type mismatch error" {
    try assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn f() {
        \\    var x = 0;
        \\    x = "oops";
        \\}
    );
}

// ── additional case patterns (not covered by infer: section above) ────────────

test "infer ast: case ---- list patterns empty, single, spread" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn describe() -> string {
        \\    val items = ["a", "b", "c"];
        \\    return case items {
        \\        [] -> "empty";
        \\        [x] -> "one";
        \\        [first, ..rest] -> "many";
        \\    };
        \\}
    );
}

// ── unique case patterns (not covered by infer: section above) ────────────────

test "infer ast: delegate declaration" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

test "infer ast: case ---- OR patterns with block arm body" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    else      -> {
        \\        val value = "odd";
        \\        break value;
        \\    };
        \\};
    );
}

test "infer ast: case ---- union return type from mismatched arms" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0    -> "zero";
        \\    else -> 1;
        \\};
    );
}

test "infer ast: case ---- nested case in block arm" {
    try assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> {
        \\      case 1 {
        \\          0    -> 54;
        \\          else -> 1;
        \\      };
        \\   };
        \\   else -> 1;
        \\};
    );
}
