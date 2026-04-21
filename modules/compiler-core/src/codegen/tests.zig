/// JavaScript codegen tests.
///
/// Each test produces a single snapshot at:
///   snapshots/codegen/js/<slug>.snap
///
/// The snapshot contains sections separated by "----- " headers:
///
///   ----- SOURCE CODE -- name.bp
///   <source for module 'name'>
///
///   ----- COMPTIME JAVASCRIPT -- name.js
///   <intermediate Node.js script for comptime evaluation>
///
///   ----- JAVASCRIPT -- name.js
///   <final JS produced for module 'name'>
///
///   ----- TYPESCRIPT TYPEDEF -- name.d.ts   (when typeDefLanguage is configured)
///   <TypeScript type definitions for module 'name'>
const std = @import("std");
const Allocator = std.mem.Allocator;

const codegen = @import("../codegen.zig");
const snap = @import("./snapshot.zig");
const config = @import("./config.zig");
const Module = codegen.Module;
const ModuleOutput = @import("./moduleOutput.zig").ModuleOutput;
const GenerateResult = @import("./moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../comptime.zig");

const configs = [_]config.Config{
    .{
        .comptimeRuntime = .node,
        .targetSource = .commonJS,
        .typeDefLanguage = .typescript,
    },
    .{
        .comptimeRuntime = .erlang,
        .targetSource = .erlang,
        .typeDefLanguage = null,
    },
};
// ── slug helpers ──────────────────────────────────────────────────────────────

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
    return comptime std.fmt.comptimePrint(".botopinkbuild/codegen/{s}", .{slug});
}

// ── helpers ───────────────────────────────────────────────────────────────────

/// Helper: allocate a fresh Env with builtins + stdlib preloaded.
fn freshEnv(arena_alloc: std.mem.Allocator, gpa: Allocator) !comptimeMod.Env_ {
    var env = comptimeMod.Env_.init(arena_alloc);
    try env.registerBuiltins();
    try comptimeMod.registerStdlib(&env, gpa);
    try env.bind("true", try env.namedType("bool"));
    try env.bind("false", try env.namedType("bool"));
    return env;
}

/// Full pipeline across one or more source modules.
///
/// All modules are inferred in order in isolated envs. Only `pub` declarations
/// from each dependency module are exported to the registry and available for
/// `use {X} from "path"` imports.
///
/// JS is generated for **every** module. The snapshot shows each module's
/// source under its own `----- SOURCE CODE -- name.bp` header, a single
/// `----- COMPTIME JAVASCRIPT` section (from the last/main module), and each
/// module's JS under its own `----- JAVASCRIPT -- name.js` header.
fn assertJs(
    allocator: Allocator,
    comptime loc: std.builtin.SourceLocation,
    modules: []const Module,
) !void {
    const io = std.testing.io;
    const build_root_path = comptime buildRootPathFromSrc(loc);

    for (configs) |c| {
        var cfg = c;
        cfg.build_root = build_root_path;
        var outputs = try codegen.generate(
            allocator,
            modules,
            io,
            cfg,
        );

        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }

        // Build snapshot data for each module
        var snapOutputs = std.ArrayList(snap.SnapInput).empty;
        defer snapOutputs.deinit(allocator);

        for (outputs.items) |o| {
            try snapOutputs.append(allocator, .{
                .name = o.name,
                .src = o.src,
                .result = o.result,
            });
        }

        const slug = comptime slugFromSrc(loc);
        try snap.assertCodegen(allocator, slug, snapOutputs.items, c);
    }
}

/// Pipeline for programs that are expected to fail comptime validation.
/// Produces a 2-part snapshot: source + rendered error. No JS is generated.
/// Only accepts a single source module (comptime errors are always local).
fn assertJsError(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    const io = std.testing.io;

    for (configs) |c| {
        var outputs = try codegen.generate(
            allocator,
            &.{.{ .path = "", .source = src }},
            io,
            c,
        ); // var: deinit needs *Self
        defer {
            for (outputs.items) |*o| o.result.deinit(allocator);
            outputs.deinit(allocator);
        }

        // The single output must carry a comptime validation error.
        const ct_err = outputs.items[0].result.comptime_err orelse return error.ExpectedComptimeError;

        const errText = try ct_err.renderAlloc(allocator, src);
        defer allocator.free(errText);

        const slug = comptime slugFromSrc(loc);
        try snap.assertCodegenError(allocator, slug, src, errText, c);
    }
}

/// Convenience wrapper for single-module tests.
fn assertJsSingle(allocator: Allocator, comptime loc: std.builtin.SourceLocation, src: []const u8) !void {
    return assertJs(allocator, loc, &.{.{ .path = "", .source = src }});
}

// ── val declarations ──────────────────────────────────────────────────────────

// Tests simple numeric literal assignment
test "js: val ---- number literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val x = 42;
    );
}

// Tests string literal assignment
test "js: val ---- string literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val greeting = "hello";
    );
}

// Tests binary expression evaluation
test "js: val ---- binary expression" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val sum = 1 + 2;
    );
}

// ── fn declarations ───────────────────────────────────────────────────────────

// Tests private function with return statement
test "js: fn ---- private function with return" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
    );
}

// Tests pub function gets exported via exports object
test "js: fn ---- pub exported function" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
    );
}

// Tests local val binding inside function body
test "js: fn ---- with local binding" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 {
        \\    val result = x * 2;
        \\    return result;
        \\}
    );
}

// ── struct declarations ───────────────────────────────────────────────────────

// Tests struct with private field, method, and getter
test "js: struct ---- private field, method, getter" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Counter = struct {
        \\    _count: i32 = 0,
        \\    fn increment(self: Self) {
        \\        self._count += 1;
        \\    }
        \\    get count(self: Self) -> i32 {
        \\        return self._count;
        \\    }
        \\}
    );
}

// Tests struct with setter and multiple getters
test "js: struct ---- setter and two getters" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Temperature = struct {
        \\    _celsius: f64 = 0.0,
        \\    set celsius(self: Self, value: f64) {
        \\        self._celsius = value;
        \\    }
        \\    get celsius(self: Self) -> f64 {
        \\        return self._celsius;
        \\    }
        \\    get fahrenheit(self: Self) -> f64 {
        \\        return self._celsius * 1.8 + 32.0;
        \\    }
        \\}
    );
}

// Tests struct with multiple fields using assign and plus-equal operators
test "js: struct ---- multiple private fields with assign and pluseq" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val BankAccount = struct {
        \\    _balance: f64 = 0.0,
        \\    _owner: string = "",
        \\    fn deposit(self: Self, amount: f64) {
        \\        self._balance += amount;
        \\    }
        \\    fn setOwner(self: Self, name: string) {
        \\        self._owner = name;
        \\    }
        \\    get balance(self: Self) -> f64 {
        \\        return self._balance;
        \\    }
        \\    get owner(self: Self) -> string {
        \\        return self._owner;
        \\    }
        \\}
    );
}

// ── record declarations ───────────────────────────────────────────────────────

// Tests record with two fields
test "js: record ---- two fields" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Point = record { x: i32, y: i32 }
    );
}

// Tests record with methods using self fields in arithmetic
test "js: record ---- methods using self fields in arithmetic" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Vec2 = record {
        \\    x: f64,
        \\    y: f64,
        \\    fn lengthSq(self: Self) -> f64 {
        \\        return self.x * self.x + self.y * self.y;
        \\    }
        \\    fn scale(self: Self, factor: f64) -> f64 {
        \\        return self.x * factor;
        \\    }
        \\}
    );
}

// Tests record method with throw expression
test "js: record ---- method with throw" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Invoice = record {
        \\    subtotal: f64,
        \\    taxRate: f64,
        \\    fn total(self: Self) -> f64 {
        \\        return self.subtotal + self.subtotal * self.taxRate;
        \\    }
        \\    fn validate(self: Self) {
        \\        throw new Error("invalid invoice");
        \\    }
        \\}
    );
}

// ── enum declarations ─────────────────────────────────────────────────────────

// Tests enum with unit variants only
test "js: enum ---- unit variants" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

// Tests enum with payload variant
test "js: enum ---- payload variant" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\}
    );
}

// Tests enum payload variants with method using variantFields case
test "js: enum ---- payload variants with method using variantFields case" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Shape = enum {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\    Triangle(base: f64, height: f64),
        \\    fn area(shape: Self) -> f64 {
        \\        return case shape {
        \\            Circle(radius) -> radius * radius * 3.14;
        \\            Square(side) -> side * side;
        \\            Triangle(base, height) -> base * height * 0.5;
        \\            _ -> 0.0;
        \\        };
        \\    }
        \\}
    );
}

// Tests enum unit variants with method using ident case
test "js: enum ---- unit variants with method using ident case" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val HttpMethod = enum {
        \\    Get,
        \\    Post,
        \\    Put,
        \\    Delete,
        \\    fn name(m: Self) -> string {
        \\        val label = case m {
        \\            Get -> "GET";
        \\            Post -> "POST";
        \\            Put -> "PUT";
        \\            _ -> "DELETE";
        \\        };
        \\        return label;
        \\    }
        \\}
    );
}

// Tests enum with mixed unit and payload variants using mixed case patterns
test "js: enum ---- mixed unit and payload with method using mixed case" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Maybe = enum {
        \\    Nothing,
        \\    Just(value: string),
        \\    fn check(m: Self) -> string {
        \\        return case m {
        \\            Nothing -> "nothing";
        \\            Just(value) -> "just";
        \\        };
        \\    }
        \\}
    );
}

// ── case: literal and or patterns ────────────────────────────────────────────

// Tests number literal patterns in case expressions
test "js: case ---- number literal patterns" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(n: i32) -> string {
        \\    val result = case n {
        \\        0 -> "zero";
        \\        1 -> "one";
        \\        _ -> "many";
        \\    };
        \\    return result;
        \\}
    );
}

// Tests string literal patterns in case expressions
test "js: case ---- string literal patterns" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn greet(lang: string) -> string {
        \\    val msg = case lang {
        \\        "en" -> "hello";
        \\        "pt" -> "ola";
        \\        _ -> "hi";
        \\    };
        \\    return msg;
        \\}
    );
}

// Tests or patterns with numbers in case expressions
test "js: case ---- or patterns with numbers" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn classify(day: i32) -> string {
        \\    val kind = case day {
        \\        6 | 7 -> "weekend";
        \\        _ -> "weekday";
        \\    };
        \\    return kind;
        \\}
    );
}

// ── call expression ───────────────────────────────────────────────────────────

// Tests struct method with call expression using receiver
test "js: struct ---- method with call expression receiver" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Logger = struct {
        \\    _prefix: string = "",
        \\    fn setPrefix(self: Self, p: string) {
        \\        self._prefix = p;
        \\    }
        \\    fn log(self: Self, msg: string) {
        \\        console.log(self._prefix, msg);
        \\    }
        \\    get prefix(self: Self) -> string {
        \\        return self._prefix;
        \\    }
        \\}
    );
}

// ── todo expression ───────────────────────────────────────────────────────────

// Tests todo placeholder in record method
test "js: record ---- method with todo placeholder" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\record Unimplemented { id: i32,
        \\    fn process(self: Self) -> string {
        \\        return @todo();
        \\    }
        \\}
    );
}

// ── qualifiedIdent ────────────────────────────────────────────────────────────

// Tests method using qualified enum member
test "js: enum ---- method using qualified enum member" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Status = enum {
        \\    Active,
        \\    Inactive,
        \\    fn isDefault(s: Self) -> string {
        \\        val current = Status.Active;
        \\        return current;
        \\    }
        \\}
    );
}

// ── implement declaration ─────────────────────────────────────────────────────

// Tests implement attaches methods to prototype
test "js: implement ---- attaches methods to prototype" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\interface Printable {
        \\    fn print(self: Self),
        \\}
        \\record Person { name: string }
        \\val PersonPrintable = implement Printable for Person {
        \\    fn print(self: Self) {
        \\        return self.name;
        \\    }
        \\}
    );
}

// ── delegate declaration ──────────────────────────────────────────────────────

// Tests delegate emits comment
test "js: delegate ---- emits comment" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

// ── interface declarations ────────────────────────────────────────────────────

// Tests interface emits comment
test "js: interface ---- emits comment" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Drawable = interface {
        \\    val color: string,
        \\    fn draw(self: Self);
        \\}
    );
}

// ── use → import ──────────────────────────────────────────────────────────────

// Tests named imports from module
test "js: use ---- named imports" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\use { foo, bar } from "mylib";
    );
}

// ── operators ─────────────────────────────────────────────────────────────────

// Tests comparison operators
test "js: operators ---- comparison" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn isPositive(n: i32) -> bool {
        \\    return n > 0;
        \\}
    );
}

// Tests equality operator maps to ==
test "js: operators ---- equality maps to ==" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn isZero(n: i32) -> bool {
        \\    return n == 0;
        \\}
    );
}

// Tests logical and operator
test "js: operators ---- logical and" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn both(a: bool, b: bool) -> bool {
        \\    return a && b;
        \\}
    );
}

// Tests logical or operator
test "js: operators ---- logical or" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn either(a: bool, b: bool) -> bool {
        \\    return a || b;
        \\}
    );
}

// Tests logical not operator
test "js: operators ---- logical not" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn negate(v: bool) -> bool {
        \\    return !v;
        \\}
    );
}

// Tests chained logical operators
test "js: operators ---- chained logical and" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn allThree(a: bool, b: bool, c: bool) -> bool {
        \\    return a && b && c;
        \\}
    );
}

// ── destructuring val bindings ────────────────────────────────────────────────

// Tests record destructuring in val binding
test "js: destructure ---- record val binding" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32 }
        \\fn describe(p: Point) -> i32 {
        \\    val { x, y } = p;
        \\    return x;
        \\}
    );
}

// Tests record destructuring with spread
test "js: destructure ---- record val binding with spread" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32, z: i32 }
        \\fn describe(p: Point) -> i32 {
        \\    val { x, .. } = p;
        \\    return x;
        \\}
    );
}

// ── destructuring parameters ──────────────────────────────────────────────────

// Tests record destructuring in function parameter
test "js: destructure ---- record parameter in fn" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\record Person { name: string, age: i32 }
        \\fn greet({ name, .. }: Person) -> string {
        \\    return name;
        \\}
    );
}

// Tests tuple destructuring in val binding
test "js: destructure ---- tuple val binding" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn extract() {
        \\    val #(a, b) = #(12, "hello");
        \\}
    );
}

// Tests tuple destructuring as function parameter
test "js: destructure ---- tuple parameter in fn" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn process(#(x, y): #(i32, i32)) -> i32 {
        \\    return x;
        \\}
    );
}

// Tests tuple destructuring with var binding
test "js: destructure ---- tuple var binding" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    var #(x, y) = #(10, 20);
        \\}
    );
}

// Tests tuple destructuring with long variable names
test "js: destructure ---- tuple with long names" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn get_coordinates() -> #(f32, f32) {
        \\    return #(0.0, 0.0);
        \\}
        \\fn extract_coordinates() {
        \\    val #(longitude, latitude) = get_coordinates();
        \\}
    );
}

// Tests tuple destructuring with try-catch
test "js: destructure ---- tuple with try-catch" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\record Error { msg: string }
        \\fn fetch() -> #(i32, i32) {
        \\    return #(1, 2);
        \\}
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

// ── null literal ──────────────────────────────────────────────────────────────

// Tests null literal assignment
test "js: val ---- null literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val nothing = null;
    );
}

// Tests optional annotation with null
test "js: val ---- optional annotation with null" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val msg: ?string = null;
    );
}

// ── if expression ─────────────────────────────────────────────────────────────

// Tests simple conditional in fn body
test "js: if ---- simple conditional in fn body" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn sign(n: i32) -> string {
        \\    val r = if (n > 0) { "positive"; };
        \\    return r;
        \\}
    );
}

// Tests conditional with else branch
test "js: if ---- conditional with else branch" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn describe(n: i32) -> string {
        \\    return if (n > 0) "positive" else "non-positive";
        \\}
    );
}

// ── try / catch ───────────────────────────────────────────────────────────────

// Tests try without catch propagates error
test "js: try ---- propagate without catch" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn fetch() -> i32 {
        \\    @todo();
        \\}
        \\fn process() -> i32 {
        \\    val r = try fetch();
        \\    return r;
        \\}
    );
}

// Tests try with inline catch handler
test "js: try ---- with inline catch handler" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn fetch() -> i32 {
        \\    @todo();
        \\}
        \\fn safe() -> i32 {
        \\    val r = try fetch() catch 0;
        \\    return r;
        \\}
    );
}

// ── trailing lambda ───────────────────────────────────────────────────────────

test "js: call ---- trailing lambda block" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn run() {
        \\    @todo();
        \\}
        \\fn main() {
        \\    run { x ->
        \\        return "done";
        \\    };
        \\}
    );
}

test "js: call ---- trailing lambda with multiple params" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn calc(factor: i32) -> i32 {
        \\    @todo();
        \\}
        \\fn main() {
        \\    val r = calc(2) { a, b ->
        \\        return 0;
        \\    };
        \\}
    );
}

// ── case list patterns ────────────────────────────────────────────────────────

test "js: case ---- list patterns empty, single, spread" {
    try assertJsSingle(std.testing.allocator, @src(),
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

// ── loop: side-effect only (sem break) ────────────────────────────────────────

test "js: loop ---- side-effect print in iterator" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
        \\loop (messages, 0..) { msg, i ->
        \\    print("mensagem");
        \\};
    );
}

test "js: loop ---- side-effect over range" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\loop (0..10) { i ->
        \\    print("item");
        \\};
    );
}

// ── loop: transformation with break ────────────────────────────────────────────

test "js: loop ---- map with break (add tax)" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val precosBrutos = [100, 250, 400];
        \\val precosComTaxa = loop (precosBrutos) { valor ->
        \\    val taxa = valor * 0.15;
        \\    break valor + taxa;
        \\};
    );
}

test "js: loop ---- filter with conditional break" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val precosBrutos = [100, 250, 400];
        \\val apenasGrandes = loop (precosBrutos) { valor ->
        \\    if (valor > 200) {
        \\        break valor;
        \\    };
        \\};
    );
}

test "js: loop ---- map with break simple" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val ids = [10, 20, 30];
        \\val dobrados = loop (ids) { id ->
        \\    break id * 2;
        \\};
    );
}

// ── loop: complex conditional break ────────────────────────────────────────────

test "js: loop ---- even numbers with break" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val processamento = loop (0..10) { i ->
        \\    if (i % 2 == 0) {
        \\        break i;
        \\    };
        \\};
    );
}

// ── pub val ───────────────────────────────────────────────────────────────────

test "js: val ---- pub val declaration" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\pub val VERSION = 1;
        \\pub val HOST = "localhost";
    );
}

// ── shorthand declarations ────────────────────────────────────────────────────

test "js: struct ---- shorthand declaration without val Name =" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\struct Counter {
        \\    _count: i32 = 0,
        \\    fn increment(self: Self) {
        \\        self._count += 1;
        \\    }
        \\    get count(self: Self) -> i32 {
        \\        return self._count;
        \\    }
        \\}
    );
}

test "js: record ---- shorthand declaration without val Name =" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\record Vec2 {
        \\    x: f64,
        \\    y: f64,
        \\    fn dot(self: Self, other: Vec2) -> f64 {
        \\        return self.x * other.x + self.y * other.y;
        \\    }
        \\}
    );
}

test "js: enum ---- shorthand declaration without val Name =" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\enum Direction {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

// ── multi-module import/export ────────────────────────────────────────────────

test "js: use ---- multi-module pub fn import" {
    try assertJs(std.testing.allocator, @src(), &.{
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

test "js: use ---- multi-module pub val import" {
    try assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "config", .source =
        \\pub val PORT = 8080;
        \\pub val HOST = "localhost";
        },
        .{ .path = "", .source =
        \\use {PORT, HOST} from "config";
        \\val addr = HOST;
        \\val port = PORT;
        },
    });
}

// ── comptime: constant folding ─────────────────────────────────────────────────
//
// These tests verify that comptime expressions are evaluated during compilation
// and their results are inlined as literal values in the generated JavaScript.
// No runtime computation should occur for pure comptime expressions.

// Verifies that integer addition in a comptime expression is folded into a
// single literal constant in the generated JS (no runtime `1 + 1`).
test "js: comptime folding ---- integer addition folds to literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val v1 = comptime 1 + 1;
    );
}

// Verifies that comptime blocks with `break expr` return the expression value
// and inline it as a literal, not as a runtime computation.
test "js: comptime folding ---- block with break value inlines result" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val t = comptime {
        \\    break 2 + 22;
        \\};
    );
}

// Verifies that floating-point multiplication in comptime is evaluated at
// compile time, producing a literal float in the generated JS.
test "js: comptime folding ---- float multiplication folds to literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val pi2 = comptime {
        \\    break 3.14 * 2.0;
        \\};
    );
}

// Verifies that comptime respects standard operator precedence: multiplication
// binds tighter than addition, producing `14` not `20`.
test "js: comptime folding ---- multiplication binds tighter than addition" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val n = comptime {
        \\    break 2 + 3 * 4;
        \\};
    );
}

// Verifies that referencing runtime-only identifiers inside a comptime block
// produces a compile-time error (comptime must be pure).
test "js: comptime validation ---- runtime identifier inside comptime raises error" {
    try assertJsError(std.testing.allocator, @src(),
        \\val msg = comptime {
        \\    break greeting;
        \\};
    );
}

// ── comptime: function specialization ──────────────────────────────────────────
//
// When a function has `comptime` parameters, the compiler generates a specialized
// version of that function for each unique set of comptime argument values.
// Specialized functions are suffixed with `$0`, `$1`, etc. in the generated JS.
// The comptime parameter is removed from the runtime signature and its value is
// baked into the function body.

// Verifies that a simple runtime val binding generates a JS const declaration.
test "js: comptime val ---- runtime val with string literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val greeting = "Hello, World!";
    );
}

// Verifies that a comptime val binding folds to a literal at compile time,
// producing a const with the computed value (no runtime addition).
test "js: comptime val ---- comptime val folds arithmetic to literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val result = comptime 10 + 20;
    );
}

// Verifies that multiple calls to a function with different comptime string
// arguments generate distinct specialized versions ($0, $1, $2) with the
// string value baked into the body.
test "js: comptime specialization ---- distinct string args generate specialized functions" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn build(prefix comptime: string, name: string) -> string {
        \\    return prefix + ": " + name;
        \\}
        \\
        \\fn main() {
        \\    val r1 = build("INFO", "Sistema iniciado");
        \\    val r2 = build("WARN", "Memória alta");
        \\    val r3 = build("INFO", "Log replicado");
        \\}
    );
}

// Verifies that calls with different comptime integer arguments generate separate
// specialized versions. Same integer value reuses the same specialization ($0 for
// factor=2 appears twice, $1 for factor=3).
test "js: comptime specialization ---- distinct integer args generate specialized functions" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn multiply(comptime factor: i32, x: i32) -> i32 {
        \\    return x * factor;
        \\}
        \\
        \\fn calculate() {
        \\    val double = multiply(2, 21);
        \\    val triple = multiply(3, 21);
        \\    val doubleAgain = multiply(2, 10);
        \\}
    );
}

// Verifies that comptime string arguments are interned: the same string value
// ("INFO") in multiple calls reuses the same specialized function ($0 and $2
// are both build with prefix="INFO", so they share $0).
test "js: comptime specialization ---- same string arg reuses specialized function" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn build(comptime prefix: string, name: string) -> string {
        \\    return prefix + ": " + name;
        \\}
        \\
        \\fn main() {
        \\    val r1 = build("INFO", "Sistema iniciado");
        \\    val r2 = build("WARN", "Memória alta");
        \\    val r3 = build("INFO", "Log replicado");
        \\}
    );
}

// Verifies that comptime val bindings can be used as arguments to specialized
// functions, and the folded val value propagates into the specialization.
test "js: comptime specialization ---- comptime val used as specialization argument" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val base = comptime 10 + 5;
        \\
        \\fn scale(comptime factor: i32, value: i32) -> i32 {
        \\    return value * factor;
        \\}
        \\
        \\fn main() {
        \\    val doubled = scale(2, base);
        \\    val tripled = scale(3, base);
        \\    val doubledAgain = scale(2, 100);
        \\}
    );
}

// ── comptime: loop unrolling and static branch folding ─────────────────────────
//
// When a `loop` iterates over a comptime array, the compiler fully unrolls the
// loop: each iteration becomes a separate block of code. If the loop body
// contains `if` conditions comparing the loop variable against literals, those
// conditions are evaluated at compile time (static branch folding). True branches
// are inlined; false branches are eliminated entirely.

// Verifies that a function with no loop and simple comptime parameters
// generates correctly specialized versions with the comptime value baked in.
test "js: comptime specialization ---- simple function body without loop" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    return input + 0;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\    val r3 = execute("calc", 5);
        \\}
    );
}

// Verifies that a loop over a comptime array is fully unrolled. Each iteration
// becomes inline code, and `if (cmd == slug)` is resolved at compile time:
// only the iteration where `cmd` equals the specialized `slug` value generates
// the assignment; all other iterations produce no code.
test "js: comptime loop unrolling ---- single if condition resolved per element" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = comptime ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            output = input * 2;
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

// Verifies that nested `if` conditions inside a comptime-unrolled loop are both
// resolved statically. The outer `if (cmd == slug)` and inner
// `if (cmd == "calc") / else if (cmd == "noop")` are evaluated per element,
// producing exactly one assignment with the correct operation inlined.
test "js: comptime loop unrolling ---- nested if-else chain fully folded" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = comptime ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            if (cmd == "calc") {
        \\                output = input * 2;
        \\            } else if (cmd == "noop") {
        \\                output = input;
        \\            };
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

// Verifies that a `case` expression inside a comptime-unrolled loop is resolved
// statically per element. The outer `if (cmd == slug)` filters by the specialized
// parameter, and the inner `case cmd { ... }` folds to a single branch at compile
// time, producing the same result as nested if-else but with pattern-matching syntax.
test "js: comptime loop unrolling ---- case expression folded inside unrolled loop" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = comptime ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            output = case cmd {
        \\                "calc" -> input * 2;
        \\                "noop" -> input;
        \\                _ -> 0;
        \\            };
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

// Verifies that when the loop iterates over a runtime array (not comptime),
// the loop is preserved in the generated JS as a regular `for...of`. The
// comptime parameter `slug` is still specialized, so each function version
// has the slug value baked in, but iteration happens at runtime.
test "js: comptime partial ---- runtime array loop preserved, comptime param specialized" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val COMMANDS = ["calc", "noop", "help"];
        \\
        \\fn execute(comptime slug: string, input: i32) -> i32 {
        \\    var output = 0;
        \\    loop (COMMANDS) { cmd ->
        \\        if (cmd == slug) {
        \\            output = input * 2;
        \\        };
        \\    };
        \\    return output;
        \\}
        \\
        \\fn main() {
        \\    val r1 = execute("calc", 10);
        \\    val r2 = execute("noop", 42);
        \\}
    );
}

// Verifies that a simple comptime expression and a function without comptime
// parameters compile correctly together, ensuring the basic pipeline works
// without any specialization or unrolling machinery.
test "js: comptime basic ---- comptime val and plain function coexist" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val x = comptime 1 + 2;
        \\
        \\fn double(n: i32) -> i32 {
        \\    return n * 2;
        \\}
        \\
        \\fn main() {
        \\    val r = double(21);
        \\}
    );
}

// ── arrays ────────────────────────────────────────────────────────────────────

test "js: array ---- string array literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val xs = ["hello", "world"];
    );
}

test "js: array ---- val with array type annotation" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val array: string[] = ["65454"];
    );
}

test "js: array ---- prepend with empty array" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val list1 = [1, ..[]];
    );
}

test "js: array ---- prepend with single element array" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val list2 = [1, 2, ..[3]];
    );
}

test "js: array ---- prepend with multiple elements array" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val list3 = [1, 2, ..[3, 4]];
    );
}

test "js: array ---- prepend with identifier" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val rest = [3, 4];
        \\val list = [1, 2, ..rest];
    );
}

test "js: assert ---- simple assertion" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert true;
        \\}
    );
}

test "js: assert ---- with arithmetic comparison" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert 1.0 + 2.0 == 3.0;
        \\}
    );
}

test "js: assert ---- with message" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert false, "error message";
        \\}
    );
}

test "js: assert ---- array equality" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    assert [] == [];
        \\}
    );
}

test "js: assert pattern ---- with catch throw" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch throw Error("is not person");
        \\}
    );
}

test "js: assert pattern ---- with catch default value" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
        \\}
    );
}

test "js: assert pattern ---- with list pattern" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [first, ..] = items catch throw Error("not a list");
        \\}
    );
}

test "js: assert pattern ---- with string literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert "hello" = greeting catch throw Error("not hello");
        \\}
    );
}

test "js: assert pattern ---- with number literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert 42 = answer catch throw Error("not 42");
        \\}
    );
}

test "js: assert pattern ---- with enum variant" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert Ok(value) = result catch throw Error("not ok");
        \\}
    );
}

test "js: assert pattern ---- with empty list" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [] = list catch throw Error("not empty");
        \\}
    );
}

test "js: assert pattern ---- with multiple element list" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [1, 2, 3] = numbers catch throw Error("not matching");
        \\}
    );
}

test "js: assert pattern ---- with list and rest" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn f() {
        \\    val assert [first, second, ..rest] = items catch [];
        \\}
    );
}

// ── tuples ────────────────────────────────────────────────────────────────────

test "js: tuple ---- string pair literal" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val t = #("56454", "85484");
    );
}

test "js: tuple ---- val with tuple type annotation" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val t: #(string, string) = #("56454", "85484");
    );
}

test "js: tuple ---- mixed types" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val t = #(12, "5452");
    );
}

// ── case: additional patterns ─────────────────────────────────────────────────

test "js: case ---- OR patterns with block arm body" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val parity = case 5 {
        \\    0 | 2 | 4 -> "even";
        \\    _      -> {
        \\        val value = "odd";
        \\        break value;
        \\    };
        \\};
    );
}

test "js: case ---- union return type from mismatched arms" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0    -> "zero";
        \\    _ -> 1;
        \\};
    );
}

test "js: case ---- nested case in block arm" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val result = case 42 {
        \\    0 -> {
        \\      case 1 {
        \\          0    -> 54;
        \\          _ -> 1;
        \\      };
        \\   };
        \\   _ -> 1;
        \\};
    );
}

// ── delegate ──────────────────────────────────────────────────────────────────

test "js: delegate ---- declaration" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

// ── tuple ─────────────────────────────────────────────────────────────────────

test "js: tuple ---- literal pair" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val pair = #(1, "hello");
    );
}

test "js: tuple ---- nested tuples" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val nested = #(#(1, 2), #(3, 4));
    );
}

test "js: tuple ---- access elements" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn getFirst(t: #(i32, string)) -> i32 {
        \\    return t._0;
        \\}
    );
}

// ── pipeline ─────────────────────────────────────────────────────────────────

test "js: pipeline ---- simple chain" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1
        \\        |> double
        \\        |> inc;
        \\}
    );
}

test "js: pipeline ---- with labeled args" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1
        \\        |> double
        \\        |> inc;
        \\}
    );
}

// ── break / continue / yield ──────────────────────────────────────────────────

test "js: loop ---- break with value" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn find(arr: i32[]) -> i32 {
        \\    return loop (arr) { x ->
        \\        if (x > 10) { break x; };
        \\    };
        \\}
    );
}

test "js: loop ---- continue in iteration" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn sumEvens(arr: i32[]) -> i32 {
        \\    return loop (arr) { x ->
        \\        if (x % 2 != 0) { continue; };
        \\        yield x;
        \\    };
        \\}
    );
}

test "js: loop ---- yield accumulation" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn doubles(arr: i32[]) -> i32[] {
        \\    return loop (arr) { x ->
        \\        yield x * 2;
        \\    };
        \\}
    );
}

// ── range ─────────────────────────────────────────────────────────────────────

test "js: range ---- iterate over range" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn sumTo(n: i32) -> i32 {
        \\    return loop (0..n) { i ->
        \\        yield i;
        \\    };
        \\}
    );
}

test "js: range ---- open-ended range" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn countUp(x: i32) {
        \\    loop (x..) { i ->
        \\        if (i > 100) {
        \\          break;
        \\        };
        \\    };
        \\}
    );
}

// ── comments ──────────────────────────────────────────────────────────────────

test "js: comment ---- single line before fn" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\// This is a comment
        \\fn main() {
        \\    null;
        \\}
    );
}

test "js: comment ---- inside function body" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    // Initialize value
        \\    val x = 1;
        \\    // Return null
        \\    null;
        \\}
    );
}

// ── doc comments ──────────────────────────────────────────────────────────────

test "js: doc comment ---- before fn" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\/// This function greets the user
        \\fn greet(name: string) -> string {
        \\    return name;
        \\}
    );
}

test "js: doc comment ---- multiline before struct" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\/// User account structure
        \\/// Holds name and email
        \\val Account = struct { name: string, email: string };
    );
}

// ── module comments ───────────────────────────────────────────────────────────

test "js: module comment ---- at top of file" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\//// This module provides utility functions
        \\//// for string manipulation
        \\
        \\fn capitalize(s: string) -> string {
        \\    return s;
        \\}
    );
}

// ── negation ──────────────────────────────────────────────────────────────────

test "js: negation ---- simple unary minus" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn negate(x: i32) -> i32 {
        \\    return -x;
        \\}
    );
}

test "js: negation ---- in expression" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn diff(x: i32, y: i32) -> i32 {
        \\    return x + -y;
        \\}
    );
}

// ── assign / field assign ─────────────────────────────────────────────────────

test "js: assign ---- update var with plusEq" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn increment() {
        \\    var count = 0;
        \\    count += 1;
        \\}
    );
}

test "js: field assign ---- self.field update" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Counter = struct {
        \\    count: i32 = 0,
        \\    fn inc() {
        \\        self.count += 1;
        \\    }
        \\};
    );
}

// ── builtin calls ─────────────────────────────────────────────────────────────

test "js: builtin ---- @todo with message" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn notImplemented() {
        \\    @todo("implement this function");
        \\}
    );
}

test "js: builtin ---- @panic with message" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn fail() {
        \\    @panic("something went wrong");
        \\}
    );
}

// ── comptime block ────────────────────────────────────────────────────────────

test "js: comptime ---- block with break" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val result = comptime {
        \\    val x = 10;
        \\    break x * 2;
        \\};
    );
}

// ── self field access ────────────────────────────────────────────────────────

test "js: self ---- field access in method" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Point = struct {
        \\    x: i32,
        \\    y: i32,
        \\    fn sum() -> i32 {
        \\        return self.x + self.y;
        \\    }
        \\};
    );
}

// ── enum method ───────────────────────────────────────────────────────────────

test "js: enum ---- method with case on self" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    fn name() -> string {
        \\        case (self) {
        \\            Red -> "red";
        \\            Green -> "green";
        \\            Blue -> "blue";
        \\        };
        \\    }
        \\};
    );
}

// ── lambda variations ────────────────────────────────────────────────────────

test "js: lambda ---- with parameter" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn apply(f: syntax fn(x: i32) -> i32) -> i32 {
        \\    return f(10);
        \\}
    );
}

test "js: lambda ---- multi-statement body" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn process(f: syntax fn(x: i32) -> i32) -> i32 {
        \\    return f(5);
        \\}
    );
}

test "js: lambda ---- standalone with params" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\val add = { x, y ->
        \\    x + y;
        \\};
        \\val result = add(10, 20);
    );
}

test "js: block ---- @block builtin" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val input = 42;
        \\    val status = @block{
        \\        val calculo = input * 2;
        \\        if (calculo > 100) return "Alto";
        \\        return "Baixo";
        \\    };
        \\    return status;
        \\}
    );
}

test "js: lambda ---- with type annotation" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val func: fn(String)-> string = {s ->
        \\        return s;
        \\    };
        \\    return func("hello");
        \\}
    );
}

test "js: lambda ---- multi param with type annotation" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> i32 {
        \\    val add: fn(i32,i32)-> i32 = {a, b ->
        \\        return a + b;
        \\    };
        \\    return add(10, 20);
        \\}
    );
}

test "js: lambda ---- simple standalone" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val func = {s ->
        \\        return s;
        \\    };
        \\    return func("hello");
        \\}
    );
}

// TODO: Implement lambda syntax with type annotations:
// val func: fn(String, Int) -> String = { s, i ->
//     val dd = "f";
//     return s + i + dd;
// };
// This requires parser support for lambda expressions as standalone values

// ── if expression ─────────────────────────────────────────────────────────────

test "js: if ---- with else branch" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn abs(n: i32) -> i32 {
        \\    val result = if (n < 0) -n else n;
        \\    return result;
        \\}
    );
}

test "js: if ---- null-check binding" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn getName(name: ?string) -> string {
        \\    if (name) { n ->
        \\        return n;
        \\    };
        \\    return "unknown";
        \\}
    );
}

// ── case variations ───────────────────────────────────────────────────────────

test "js: case ---- multiple subjects" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn process(a: i32, b: i32) {
        \\    case a, b {
        \\        0, 0 -> null;
        \\        _, _ -> null;
        \\    };
        \\}
    );
}

test "js: case ---- nested case in fn body" {
    try assertJsSingle(std.testing.allocator, @src(),
        \\fn process(x: i32) -> string {
        \\    return case (x) {
        \\        0 -> {
        \\            break case (x) {
        \\                0 -> "zero";
        \\                _ -> "other";
        \\            };
        \\        };
        \\        _ -> "non-zero";
        \\    };
        \\}
    );
}
