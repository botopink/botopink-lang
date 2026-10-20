//! comptime: pub fn/record/struct/interface/implement inference (split from tests.zig).

const std = @import("std");
const lexerMod = @import("../../lexer.zig");
const parserMod = @import("../../parser.zig");
const snapMod = @import("../../utils/snap.zig");
const prettyMod = @import("../../utils/pretty.zig");
const T = @import(".././types.zig");
const envMod = @import("../env.zig");
const inferMod = @import("../infer.zig");
const ast = @import("../../ast.zig");
/// Test-only: the one way a test spells a path it writes to (per process, so a
/// second `zig build test` over this checkout cannot empty it mid-test).
/// `build.zig` gives this module to the test modules alone.
const test_scratch = @import("test_scratch");
const comptimeMod = @import("../../comptime.zig");
const errorMod = @import("../error.zig");
const snapshot = @import("../snapshot.zig");
const Module = @import("../../module.zig").Module;
const format = @import("../../format.zig");
const Lexer = lexerMod.Lexer;
const Parser = parserMod.Parser;
const Env = envMod.Env;
const h = @import("helpers.zig");

test "infer: enum constructors" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = type {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\};
        \\val c1 = Color.Red;
        \\val c2 = Color.Rgb(r: 255, g: 0, b: 0);
        \\val c3: Color = .Red;
    );
}

test "infer: record constructor" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Point = type(x: i32, y: i32);
        \\val p = Point(x: 1, y: 2);
        \\fn main() {
        \\    print(p);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: record with method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = type(
        \\    lat: f64,
        \\    lon: f64) {
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\};
        \\val g = GPSCoordinates(lat: 5.0, lon: 3.0);
    );
}

test "infer: pub fn basic ---- greet returns string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn greet(name: string) -> string {
        \\    return "Hello, " + name;
        \\}
        \\val msg = greet("world");
        \\fn main() {
        \\    print(msg);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: pub fn with local val binding in body" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn compute(x: i32) -> i32 {
        \\    val doubled = x + x;
        \\    print(doubled);
        \\    return doubled;
        \\}
        \\val result = compute(21);
        \\fn main() {
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: pub fn with comptime params" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub fn repeat(s comptime: string, n comptime: i32) -> string {
        \\    panic("not implemented");
        \\}
        \\val r = repeat("hi", 3);
        \\
        \\import {failure.panic} from "std";
    );
}

test "infer: pub fn using enum + case in body" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Direction = type {
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
        \\        _ -> "?";
        \\    };
        \\    print(result);
        \\    return result;
        \\}
        \\val n = label(Direction.North);
        \\fn main() {
        \\    print(n);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: val with explicit type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val x: i32 = 42;
        \\val y: f64 = 3.14;
        \\val msg: string = "hello";
    );
}

test "infer: val dependency chain" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val a = 10;
        \\val b = a + 5;
        \\val c = b + a;
    );
}

test "infer: dotIdent resolved from type annotation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Color = type {
        \\    Red,
        \\    Blue,
        \\};
        \\val c: Color = .Red;
    );
}

test "infer: implement block lists with its interface, target and methods" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = behavior {
        \\    fn draw(self: Self);
        \\};
        \\val Circle = type(radius: f64);
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        panic("not implemented");
        \\    }
        \\};
        \\val c = Circle(radius: 5.0);
        \\
        \\import {failure.panic} from "std";
    );
}

test "infer: interface with field and abstract method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = behavior {
        \\    val color: string;
        \\    fn draw(self: Self);
        \\}
    );
}

test "infer: interface with multiple abstract methods" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Canvas = behavior {
        \\    fn clear(self: Self);
        \\    fn drawLine(self: Self, x1: i32, y1: i32);
        \\    fn drawRect(self: Self, x: i32, y: i32, color: string);
        \\}
    );
}

test "infer: record with fields and toString method" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val GPSCoordinates = type(
        \\    lat: f64,
        \\    lon: f64) {
        \\    fn toString(self: Self) -> string {
        \\        return "Lat: " + self.lat + " Lon: " + self.lon;
        \\    }
        \\}
    );
}

test "infer: implement single interface for record" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Drawable = behavior {
        \\    fn draw(self: Self);
        \\};
        \\val Circle = type(radius: f64);
        \\val CircleDrawing = implement Drawable for Circle {
        \\    fn draw(self: Self) {
        \\        print("Drawing circle");
        \\    }
        \\};
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: implement two interfaces with qualified methods" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val UsbCharger = behavior {
        \\    fn Connect(self: Self);
        \\};
        \\val SolarCharger = behavior {
        \\    fn Connect(self: Self);
        \\};
        \\val SmartCamera = type(batteryLevel: i32);
        \\val CameraPowerCharger = implement UsbCharger, SolarCharger for SmartCamera {
        \\    fn UsbCharger.Connect(self: Self) {
        \\        print("Connected via USB");
        \\    }
        \\    fn SolarCharger.Connect(self: Self) {
        \\        print("Connected via Solar");
        \\    }
        \\};
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: doc comment on function" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// Adds two numbers
        \\pub fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\val result = add(1, 2);
    );
}

test "infer: doc comment on record" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\//// A point in 2D space
        \\val Point = type(x: i32, y: i32);
    );
}

test "infer: local extension method resolves without activation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\type Pato(id: i32)
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val splash = donald.swim();
    );
}

// ── net-new (v0.beta.13 · A5): extension dispatch ────────────────────────────

// Implementing an interface for a PRIMITIVE (`i32`) and dispatching a method on
// a literal receiver resolves the extension method.
test "infer: net-new ---- implement an interface for a primitive and dispatch" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Doubler = behavior {
        \\    fn double(self: Self) -> i32;
        \\}
        \\val IntDoubler = implement Doubler for i32 {
        \\    fn double(self: Self) -> i32 {
        \\        return self + self;
        \\    }
        \\}
        \\val n = 3;
        \\val six = n.double();
    );
}

// Two imported libs each activating the SAME method name for the same type
// (`PatoNada*` from one, `PatoFundo*` from another) make `donald.swim()`
// cross-module ambiguous — inference reports a type error at the call.
test "infer: net-new ---- two imported libs activating the same method are ambiguous" {
    const io = std.testing.io;
    const modules = [_]Module{
        .{ .path = "swimlib", .source =
        \\pub type Pato(id: i32)
        \\pub val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\pub val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        },
        .{ .path = "divelib", .source =
        \\import {swimlib.Pato};
        \\pub val Diver = behavior {
        \\    fn swim(self: Self);
        \\}
        \\pub val PatoFundo = implement Diver for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        },
        .{ .path = "", .source =
        \\import {swimlib.Pato, swimlib.PatoNada*};
        \\import {divelib.PatoFundo*};
        \\val donald = Pato(1);
        \\val splash = donald.swim();
        },
    };

    var session = try comptimeMod.compile(
        std.testing.allocator,
        &modules,
        io,
        test_scratch.path(io, "comptime/cross_module_extension_ambiguity"),
        null,
    );
    defer session.deinit(std.testing.allocator);

    // The consumer module fails inference with an ambiguous-method diagnostic.
    var sawAmbiguous = false;
    for (session.outputs.items) |out| {
        if (out.outcome == .typeError) {
            switch (out.outcome.typeError.kind) {
                .ambiguousExtension, .ambiguousMethod => sawAmbiguous = true,
                else => {},
            }
        }
    }
    try std.testing.expect(sawAmbiguous);
}

/// The two declarers of `NotFound` every test below imports from: a page per
/// folder of an application.
const same_name_pages = [_]Module{
    .{ .path = "app/not_found", .source =
    \\pub fn NotFound() -> string {
    \\    return "app";
    \\}
    },
    .{ .path = "app/blog/not_found", .source =
    \\pub fn NotFound() -> string {
    \\    return "blog";
    \\}
    },
};

/// Compile `same_name_pages` and `consumer` (at module path `path`); the
/// consumer's type error rendered, or null when it infers.
fn consumerTypeError(path: []const u8, consumer: []const u8, comptime scratch: []const u8) !?[]u8 {
    const io = std.testing.io;
    const modules = [_]Module{ same_name_pages[0], same_name_pages[1], .{ .path = path, .source = consumer } };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, test_scratch.path(io, scratch), null);
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |out| {
        if (!std.mem.eql(u8, out.name, path)) continue;
        return switch (out.outcome) {
            .ok => null,
            .typeError => |te| try te.message(std.testing.allocator),
            else => error.ConsumerDidNotReachInference,
        };
    }
    return error.ConsumerNotCompiled;
}

/// The message of `path`'s type error in a build of `modules`, null when it checked.
fn moduleTypeError(modules: []const Module, path: []const u8, comptime scratch: []const u8) !?[]u8 {
    const io = std.testing.io;
    var session = try comptimeMod.compile(std.testing.allocator, modules, io, test_scratch.path(io, scratch), null);
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |out| {
        if (!std.mem.eql(u8, out.name, path)) continue;
        return switch (out.outcome) {
            .ok => null,
            .typeError => |te| blk: {
                const msg = try te.message(std.testing.allocator);
                errdefer std.testing.allocator.free(msg);
                const loc = te.loc orelse return error.UnlocatedError;
                const located = try std.fmt.allocPrint(std.testing.allocator, "{d}:{d} {s}", .{ loc.line, loc.col, msg });
                std.testing.allocator.free(msg);
                break :blk located;
            },
            else => error.ModuleDidNotReachInference,
        };
    }
    return error.ModuleNotCompiled;
}

// A module that fails to check exports nothing. Its importers used to read
// every name they took from it as `unbound variable`, each at its first use and
// transitively — the one real error (`shapes`') buried under one per importer.
// A use of such a name is `import-of-failed-module` at the import item, naming
// the module the item names: `user` names `shapes` (a namespace), `main` names
// `user`, and `shapes` keeps its own error.
test "infer: import of a failed module ---- the importer names the module, not an unbound name" {
    const modules = [_]Module{
        .{ .path = "shapes", .source =
        \\pub fn area(side: i32) -> i32 {
        \\    val label: string = side * side;
        \\    return side * side;
        \\}
        },
        .{ .path = "user", .source =
        \\import {shapes};
        \\pub fn describe(n: i32) -> string {
        \\    return "area ${shapes.area(n)}";
        \\}
        },
        .{ .path = "main", .source =
        \\import {user.describe};
        \\pub fn main() {
        \\    print(describe(2));
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    };
    const scratch = "comptime/import_of_failed_module";
    const shapes = (try moduleTypeError(&modules, "shapes", scratch)).?;
    defer std.testing.allocator.free(shapes);
    try std.testing.expectEqualStrings("2:30 type mismatch: expected string, got i32", shapes);
    const user = (try moduleTypeError(&modules, "user", scratch)).?;
    defer std.testing.allocator.free(user);
    try std.testing.expectEqualStrings("1:9 import-of-failed-module: `shapes` comes from `shapes`, which failed to check — its own errors are reported there (shapes.bp)", user);
    const main = (try moduleTypeError(&modules, "main", scratch)).?;
    defer std.testing.allocator.free(main);
    try std.testing.expectEqualStrings("1:9 import-of-failed-module: `describe` comes from `user`, which failed to check — its own errors are reported there (user.bp)", main);
}

// The rule never hides a real error: a name the named module does not declare,
// where that module checked, stays `unbound variable` at the use — even beside
// a refused module elsewhere in the build.
test "infer: import of a failed module ---- a name missing from a module that checked stays unbound" {
    const modules = [_]Module{
        .{ .path = "broken", .source =
        \\pub fn f() -> i32 {
        \\    return "x";
        \\}
        },
        .{ .path = "shapes", .source =
        \\pub fn area(side: i32) -> i32 {
        \\    return side * side;
        \\}
        },
        .{ .path = "main", .source =
        \\import {shapes.perimeter};
        \\pub fn main() {
        \\    print(perimeter(2));
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    };
    const main = (try moduleTypeError(&modules, "main", "comptime/import_of_failed_module_missing")).?;
    defer std.testing.allocator.free(main);
    try std.testing.expectEqualStrings("3:11 unbound variable 'perimeter'", main);
}

// An import that names its module says which declaration a name is. The
// dotted spelling of a nested module path (`app.not_found.NotFound`, decision
// 206's brace form; `from "app.not_found"` before it) used to be compared byte
// for byte with the module's `/` path, so it named nothing and every lookup
// widened to the whole program — where the second `NotFound` made the import
// `ambiguous-import-use`. The consumer is a route table: one
// aliased import per page, in a module that is not the program's entry.
test "infer: import source ---- a dotted module path names its module among same-named pub fns" {
    const err = try consumerTypeError("routes",
        \\import {app.not_found.NotFound as appNotFound};
        \\import {app.blog.not_found.NotFound as blogNotFound};
        \\pub fn pages() -> string {
        \\    return appNotFound() + blogNotFound();
        \\}
    , "comptime/import_source_dotted_aliases");
    defer if (err) |e| std.testing.allocator.free(e);
    try std.testing.expectEqual(@as(?[]u8, null), err);
}

// The same inside a package that is somebody's dependency: its modules are
// keyed `<package>/…`, and one of them names a sibling by the path below the
// package's own root.
test "infer: import source ---- a module path below the importer's package names its module" {
    const io = std.testing.io;
    const modules = [_]Module{
        .{ .path = "site/app/not_found", .source = same_name_pages[0].source, .package = "site" },
        .{ .path = "site/app/blog/not_found", .source = same_name_pages[1].source, .package = "site" },
        .{ .path = "site/routes", .package = "site", .source =
        \\import {app.blog.not_found.NotFound};
        \\pub fn page() -> string {
        \\    return NotFound();
        \\}
        },
    };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, test_scratch.path(io, "comptime/import_source_below_package"), null);
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |out| try std.testing.expect(out.outcome == .ok);
}

// A module is its package plus its path (decisions 170, 337): `a` and `b`
// each hold a `theme` declaring `Ns` and `make`, with different fields, and
// each package's `user` imports its own by path. Read as the bare `theme`, the
// import named both, and the checker bound whichever the registry walk reached
// first — `b/user` read `a/theme`'s `Ns` (`unknown field size`).
test "infer: import source ---- two packages' modules of one name are two modules" {
    const io = std.testing.io;
    const modules = [_]Module{
        .{ .path = "a/theme", .package = "a", .source =
        \\pub type Ns(label: string)
        \\pub fn make() -> Ns {
        \\    return Ns(label: "red");
        \\}
        },
        .{ .path = "b/theme", .package = "b", .source =
        \\pub type Ns(size: i32)
        \\pub fn make() -> Ns {
        \\    return Ns(size: 4);
        \\}
        },
        .{ .path = "a/user", .package = "a", .source =
        \\import {theme.make};
        \\import {theme.Ns};
        \\pub fn label() -> string {
        \\    val n: Ns = make();
        \\    return n.label;
        \\}
        },
        .{ .path = "b/user", .package = "b", .source =
        \\import {theme.make};
        \\import {theme.Ns};
        \\pub fn size() -> i32 {
        \\    val n: Ns = make();
        \\    return n.size;
        \\}
        },
    };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, test_scratch.path(io, "comptime/import_source_two_packages_one_module_name"), null);
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |out| try std.testing.expect(out.outcome == .ok);
}

// The full path is read first: a project's own `app/not_found` is the one
// `import {app.not_found.NotFound};` names, although a dependency's module
// has the same path below its package and declares the name too.
test "infer: import source ---- a project's own module wins over a dependency's of the same relative path" {
    const io = std.testing.io;
    const modules = [_]Module{
        same_name_pages[0],
        .{ .path = "site/app/not_found", .package = "site", .source =
        \\pub fn NotFound() -> i32 {
        \\    return 404;
        \\}
        },
        .{ .path = "routes", .source =
        \\import {app.not_found.NotFound};
        \\pub fn page() -> string {
        \\    return NotFound();
        \\}
        },
    };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, test_scratch.path(io, "comptime/import_source_own_module_first"), null);
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |out| try std.testing.expect(out.outcome == .ok);
}

// Decision 337: a bare `import {NotFound};` names no module of the package —
// the shorthand — and is refused at the item, every module that declares the
// name `pub` written as a fix.
test "infer: import source ---- the shorthand over same-named pub fns lists the candidates" {
    const err = (try consumerTypeError("routes",
        \\import {NotFound};
        \\pub fn page() -> string {
        \\    return NotFound();
        \\}
    , "comptime/import_source_bare_ambiguous")) orelse return error.ExpectedShorthandImport;
    defer std.testing.allocator.free(err);
    try std.testing.expectEqualStrings(
        "shorthand-import: `NotFound` names no module of this package, and 2 modules declare it `pub` — write import {app.blog.not_found.NotFound}; or import {app.not_found.NotFound};",
        err,
    );
}

// One local name is one declaration: two imports that each name their module
// and bind the same name are `import-name-collision` at the second item,
// naming both modules. The second used to replace the first silently, and the
// backends disagreed on which declaration the call reached.
test "infer: import source ---- two un-aliased imports of one name collide at the second" {
    const io = std.testing.io;
    const modules = [_]Module{
        same_name_pages[0], same_name_pages[1],
        .{ .path = "routes", .source =
        \\import {app.not_found.NotFound};
        \\import {app.blog.not_found.NotFound};
        \\pub fn page() -> string {
        \\    return NotFound();
        \\}
        },
    };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, test_scratch.path(io, "comptime/import_source_twice_unaliased"), null);
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |out| {
        if (!std.mem.eql(u8, out.name, "routes")) continue;
        try std.testing.expect(out.outcome == .typeError);
        const te = out.outcome.typeError;
        const msg = try te.message(std.testing.allocator);
        defer std.testing.allocator.free(msg);
        try std.testing.expectEqualStrings(
            "import-name-collision: `NotFound` is already bound by the import of `NotFound` from `app/not_found`; `NotFound` from `app/blog/not_found` would bind it again",
            msg,
        );
        try std.testing.expectEqual(@as(usize, 2), te.loc.?.line);
        try std.testing.expectEqual(@as(usize, 9), te.loc.?.col);
        return;
    }
    return error.ConsumerNotCompiled;
}

/// Decision 310 — two modules' `Policy` and `consumer` (module `routes`): the
/// consumer's type error rendered, or null when it infers.
fn policyConsumerTypeError(consumer: []const u8, comptime scratch: []const u8) !?[]u8 {
    const io = std.testing.io;
    const modules = [_]Module{
        .{ .path = "app/a", .source =
        \\pub type Policy(ms: i32)
        \\pub fn slow() -> Policy {
        \\    return Policy(ms: 100);
        \\}
        },
        .{ .path = "app/b", .source =
        \\pub type Policy(name: string)
        \\pub fn named(p: Policy) -> string {
        \\    return p.name;
        \\}
        },
        .{ .path = "routes", .source = consumer },
    };
    var session = try comptimeMod.compile(std.testing.allocator, &modules, io, test_scratch.path(io, scratch), null);
    defer session.deinit(std.testing.allocator);
    for (session.outputs.items) |out| {
        if (!std.mem.eql(u8, out.name, "routes")) continue;
        return switch (out.outcome) {
            .ok => null,
            .typeError => |te| try te.message(std.testing.allocator),
            else => error.ConsumerDidNotReachInference,
        };
    }
    return error.ConsumerNotCompiled;
}

// Decision 310 — two same-named types of two modules, each under an alias,
// are two types: each alias constructs its own fields, and a function of
// either module takes and answers its alias's type.
test "infer: two aliased imports of two same-named types are two types" {
    const err = try policyConsumerTypeError(
        \\import {app.a.Policy as APolicy, app.a.slow};
        \\import {app.b.Policy as BPolicy, app.b.named};
        \\pub fn total() -> string {
        \\    val x: APolicy = slow();
        \\    val y = BPolicy(name: "n");
        \\    return named(y) + x.ms.toString() + APolicy(ms: 1).ms.toString();
        \\}
    , "comptime/two_aliased_types");
    defer if (err) |e| std.testing.allocator.free(e);
    if (err) |e| std.debug.print("unexpected: {s}\n", .{e});
    try std.testing.expect(err == null);
}

// Decision 310 — each alias is its own type: one module's value where the
// other's is expected is a type mismatch, never the declared name's match.
test "infer: an aliased type's value is not the other same-named type" {
    const err = try policyConsumerTypeError(
        \\import {app.a.Policy as APolicy, app.a.slow};
        \\import {app.b.Policy as BPolicy, app.b.named};
        \\pub fn wrong() -> string {
        \\    return named(slow());
        \\}
    , "comptime/two_aliased_types_mismatch");
    defer if (err) |e| std.testing.allocator.free(e);
    try std.testing.expect(err != null);
    try std.testing.expect(std.mem.indexOf(u8, err.?, "BPolicy") != null);
}

// Decision 310 — a value reached through a module namespace's call is the
// alias's type too.
test "infer: a namespace call answers the aliased same-named type" {
    const err = try policyConsumerTypeError(
        \\import {app.a as pa, app.a.Policy as APolicy};
        \\import {app.b.Policy as BPolicy, app.b.named};
        \\pub fn total() -> string {
        \\    val x: APolicy = pa.slow();
        \\    return named(BPolicy(name: "n")) + x.ms.toString();
        \\}
    , "comptime/two_aliased_types_namespace");
    defer if (err) |e| std.testing.allocator.free(e);
    if (err) |e| std.debug.print("unexpected: {s}\n", .{e});
    try std.testing.expect(err == null);
}

// Decision 603: a type of this module beside an aliased import of a
// same-named type is two types — the alias is the import's identity here.
test "infer: a local type beside an aliased same-named import is two types" {
    const err = try policyConsumerTypeError(
        \\import {app.a.Policy as APolicy};
        \\import {app.b.Policy as BPolicy};
        \\pub type Policy(id: i32)
        \\pub fn f() -> i32 {
        \\    return Policy(id: 1).id;
        \\}
    , "comptime/local_beside_aliased_types");
    defer if (err) |e| std.testing.allocator.free(e);
    if (err) |e| std.debug.print("unexpected: {s}\n", .{e});
    try std.testing.expect(err == null);
}

// The same declaration imported twice is one declaration: an `@emit`
// contribution re-imports what its module already imports.
test "infer: import source ---- the same declaration imported twice is not a collision" {
    const err = try consumerTypeError("routes",
        \\import {app.not_found.NotFound};
        \\import {app.not_found.NotFound};
        \\pub fn page() -> string {
        \\    return NotFound();
        \\}
    , "comptime/import_source_same_declaration_twice");
    defer if (err) |e| std.testing.allocator.free(e);
    try std.testing.expectEqual(@as(?[]u8, null), err);
}

// What a source's text names (`ast.ImportSource`): `.` and `/` both separate
// the segments of a module path. A module is named by its full path or its
// last segment (pass 0); across a package boundary (pass 1) the source is a
// package's handle, or a module path below a package's root.
test "infer: import source ---- namesModule and inPackage read the source as a path" {
    const ImportSource = @import("../../ast.zig").ImportSource;
    const dotted: ImportSource = .{ .module = "app.blog.not_found" };
    try std.testing.expect(dotted.namesModule("app/blog/not_found"));
    try std.testing.expect(!dotted.namesModule("app/not_found"));
    try std.testing.expect(!dotted.namesModule("site/app/blog/not_found"));
    // Below a package's root: the second reading, whole segments only.
    try std.testing.expect(dotted.inPackage("site/app/blog/not_found"));
    try std.testing.expect(!dotted.inPackage("app/blog/not_found"));
    try std.testing.expect(!dotted.inPackage("myapp/blog/not_found"));
    try std.testing.expect(!dotted.inPackage("site/blog/not_found"));
    const slashed: ImportSource = .{ .module = "app/not_found" };
    try std.testing.expect(slashed.namesModule("app/not_found"));
    try std.testing.expect(!slashed.namesModule("site/app/not_found"));
    try std.testing.expect(slashed.inPackage("site/app/not_found"));
    try std.testing.expect(!slashed.inPackage("site/app/blog/not_found"));
    // The full path is the first pass, so a project's own module is found
    // before a dependency's module of the same relative path is looked at.
    try std.testing.expect(slashed.admits("app/not_found", 0));
    try std.testing.expect(!slashed.admits("site/app/not_found", 0));
    try std.testing.expect(slashed.admits("site/app/not_found", 1));
    // A `/` of the source is never a `.` of the path, and one segment still
    // names a module by its last segment only.
    try std.testing.expect(!slashed.namesModule("app.not_found"));
    const leaf: ImportSource = .{ .module = "not_found" };
    try std.testing.expect(leaf.namesModule("app/not_found"));
    try std.testing.expect(!leaf.namesModule("app/is_not_found"));
    try std.testing.expect(!leaf.namesModule("not_found/page"));
    // A folder is a package of the modules below it, however it is spelled.
    const folder: ImportSource = .{ .module = "site.app" };
    try std.testing.expect(folder.inPackage("site/app/not_found"));
    try std.testing.expect(folder.inPackage("site/app/blog/not_found"));
    try std.testing.expect(!folder.inPackage("site/app"));
    try std.testing.expect(!folder.inPackage("site/apps/not_found"));
    const root: ImportSource = .root;
    try std.testing.expect(!root.namesModule("app/not_found"));
    try std.testing.expect(!root.inPackage("site/app/not_found"));
}

// A qualified item under a dotted source composes one `/` path: the registry
// key of the module the item's prefix (or, with `whole`, the item itself)
// names. `a.b/c` was the key of nothing, so `import {c} from "a.b"` bound no
// namespace and `c.f()` was an unbound variable.
test "infer: import source ---- leafSource composes a slashed path under a dotted source" {
    const astMod = @import("../../ast.zig");
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const decl: astMod.ImportDecl = .{ .imports = &.{}, .source = .{ .module = "site.app" } };
    const item: astMod.ImportPath = .{ .segments = &.{ "blog", "not_found" }, .alias = null };
    try std.testing.expectEqualStrings("site/app/blog", (try decl.leafSource(item, arena.allocator(), false)).module);
    try std.testing.expectEqualStrings("site/app/blog/not_found", (try decl.leafSource(item, arena.allocator(), true)).module);
    const single: astMod.ImportPath = .{ .segments = &.{"not_found"}, .alias = null };
    try std.testing.expectEqualStrings("site.app", (try decl.leafSource(single, arena.allocator(), false)).module);
}

// Precedence: when a record has an inherent method and an interface
// implementation declares the SAME method name, the inherent method wins (it is
// always available, so `t.label()` resolves without ambiguity).
test "infer: net-new ---- inherent method wins over a same-name implemented one" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Tag(
        \\    name: string) {
        \\    fn label(self: Self) -> string {
        \\        return self.name;
        \\    }
        \\}
        \\val Named = behavior {
        \\    fn label(self: Self) -> string;
        \\}
        \\val TagNamed = implement Named for Tag {
        \\    fn label(self: Self) -> string {
        \\        return "iface";
        \\    }
        \\}
        \\val t = Tag(name: "x");
        \\val l: string = t.label();
    );
}

// Chained `x.a().b()` where both `a` and `b` are extension methods resolves each
// link in the chain (the result of the first call is the receiver of the second).
test "infer: net-new ---- chained extension calls resolve each link" {
    try h.assertInfersOk(std.testing.allocator,
        \\val Stepper = behavior {
        \\    fn inc(self: Self) -> i32;
        \\    fn dec(self: Self) -> i32;
        \\}
        \\val IntStepper = implement Stepper for i32 {
        \\    fn inc(self: Self) -> i32 { return self + 1; }
        \\    fn dec(self: Self) -> i32 { return self - 1; }
        \\}
        \\val n = 5;
        \\val r: i32 = n.inc().dec();
    );
}

test "infer: qualified extension call needs no activation" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\type Pato(id: i32)
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val splash = PatoNada.swim(donald);
    );
}

test "infer: multi-module local extension resolves on an imported record" {
    // `Pato` is imported; the interface and `implement` are declared in the
    // consumer module and auto-applied, so `donald.swim()` resolves without activation.
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "pond", .source =
        \\pub type Pato(id: i32)
        },
        .{ .path = "", .source =
        \\import {pond.Pato};
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val splash = donald.swim();
        },
    });
}

test "infer: multi-module extension activated via star import" {
    // The interface + record + `implement` all live in `pond`; the consumer pulls
    // the type in and activates the imported extension with `PatoNada*`, so
    // `donald.swim()` dispatches across the module boundary.
    try h.assertComptimeAst(std.testing.allocator, @src(), &.{
        .{ .path = "pond", .source =
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\pub type Pato(id: i32)
        \\pub val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        },
        .{ .path = "", .source =
        \\import {pond.Pato, pond.PatoNada*};
        \\val donald = Pato(1);
        \\val splash = donald.swim();
        },
    });
}

test "infer: inherent record method is always available" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\type Pato(
        \\    id: i32) {
        \\    fn quack(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\val donald = Pato(1);
        \\val noise = donald.quack();
    );
}

// Decision 2 — a block is not a value, so two branches that end in a STATEMENT
// need not agree. `if (p) { out = …; } else { taking = false; }` used to red
// "expected array, got bool" — a shape a library in this repository writes in
// a `takeWhile` / `skipWhile`, and the same shape in a plain fn.
test "infer: an if whose branches end in assignments of different types" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn takeWhile(items: i32[], pred: fn(item: i32) -> bool) -> i32[] {
        \\    var out: Array<i32> = [];
        \\    var taking = true;
        \\    items.forEach({ x ->
        \\        if (taking) {
        \\            if (pred(x)) { out = out.append([x]); } else { taking = false; };
        \\        };
        \\    });
        \\    return out;
        \\}
        \\fn main() {
        \\    print(takeWhile([1, 2, 3], { n -> return n < 3; }).length());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: var binding ---- mutable local inside fn" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn count() -> i32 {
        \\    var n = 0;
        \\    return n;
        \\}
        \\val r = count();
    );
}

test "infer: var binding ---- mutable string" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\fn greet() -> string {
        \\    var msg = "hello";
        \\    return msg;
        \\}
        \\val r = greet();
    );
}

test "infer: pub val ---- infers same as private val" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\pub val VERSION = 1;
        \\pub val NAME = "botopink";
    );
}

test "infer: star fn ---- async returns @Future is valid" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\async fn fetch(x: i32) -> Async<i32> {
        \\    return x;
        \\}
    );
}

test "infer: star fn ---- generator returns @ResultGenerator is valid" {
    try h.assertComptimeAstSingle(std.testing.allocator, @src(),
        \\iter fn gen() -> Iter<i32> {
        \\    yield 1;
        \\}
    );
}

test "infer: test body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn add(a: i32, b: i32) -> i32 {
        \\    return a + b;
        \\}
        \\test "addition works" {
        \\    val r = add(2, 3);
        \\    assert r == 5;
        \\}
    );
}

test "infer: anonymous test body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\test {
        \\    assert 1 + 1 == 2;
        \\}
    );
}

// R3 (decision 8 §8, decision 15) — the second annotation was written
// `@external(node, …)` in lower case. That form binds no host and is now a
// located error, so the cell writes the capitalised path; what it asserts —
// a bodyless `declare fn` carrying MORE THAN ONE external annotation
// typechecks — is unchanged.
test "infer: external ---- fn no body typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[compiler.external(.Erlang("string:length($0)"), .JavaScript("$0.length"))]
        \\pub declare fn str_length(s: string) -> i32;
        \\
        \\fn main() {
        \\    val n = str_length("hi");
        \\}
        \\
        \\import {compiler} from "std";
    );
}

// Front 20 F9, decisions 437, 487 — `inline` on the one variant that
// declares it (`External.Erlang`) is accepted, labelled
// (`inline: true`) and read by its label in any position;
// `result: false`, the default, sits beside it on any variant.
test "infer: external ---- inline on erlang typechecks" {
    try h.assertInfersOk(std.testing.allocator,
        \\#[compiler.external(.Erlang("max($args)", inline: true))]
        \\pub declare fn biggest(a: i32, b: i32) -> i32;
        \\
        \\#[compiler.external(.Erlang("min($args)", inline: true, result: false))]
        \\pub declare fn smallest(a: i32, b: i32) -> i32;
        \\
        \\#[compiler.external(.JavaScript("Math.abs($0)", result: false))]
        \\pub declare fn magnitude(a: i32) -> i32;
        \\
        \\fn main() {
        \\    val n = biggest(1, 2);
        \\}
        \\
        \\import {compiler} from "std";
    );
}

// Decision 518 — `ast.WasmNeed` restates std's `pub type WasmNeed { … }` from
// `external.bp`: the same values in the same order, and `Implementation.Wasm`
// declares `needs: WasmNeed[]`.
test "infer: external ---- WasmNeed agrees with external.bp" {
    const source: []const u8 = @import("std_prelude").external;
    const head = "pub type WasmNeed {";
    const at = std.mem.indexOf(u8, source, head) orelse return error.WasmNeedNotDeclared;
    const close = std.mem.indexOfScalarPos(u8, source, at + head.len, '}') orelse return error.WasmNeedNotClosed;
    var lines = std.mem.splitScalar(u8, source[at + head.len .. close], '\n');
    var i: usize = 0;
    const want = std.enums.values(ast.WasmNeed);
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r,");
        if (line.len == 0) continue;
        try std.testing.expect(i < want.len);
        try std.testing.expectEqualStrings(want[i].spelling(), line);
        i += 1;
    }
    try std.testing.expectEqual(want.len, i);
    try std.testing.expect(std.mem.indexOf(u8, source, "needs: WasmNeed[] = [],") != null);
}

// Decisions 394, 481 — std's `WasiAdapter` names the wasm backend's adapters
// (`wat/host_binding.zig` `adapters`), one variant each, in their order.
test "infer: external ---- WasiAdapter agrees with the adapter table" {
    const hostBinding = @import("../../codegen/wat/host_binding.zig");
    const source: []const u8 = @import("std_prelude").external;
    const head = "pub type WasiAdapter {";
    const at = std.mem.indexOf(u8, source, head) orelse return error.WasiAdapterNotDeclared;
    const close = std.mem.indexOfScalarPos(u8, source, at + head.len, '}') orelse return error.WasiAdapterNotClosed;
    var lines = std.mem.splitScalar(u8, source[at + head.len .. close], '\n');
    var i: usize = 0;
    while (lines.next()) |raw| {
        const line = std.mem.trim(u8, raw, " \t\r,");
        if (line.len == 0) continue;
        try std.testing.expect(i < hostBinding.adapters.len);
        const snake = try ast.snakeOf(std.testing.allocator, line);
        defer std.testing.allocator.free(snake);
        try std.testing.expectEqualStrings(hostBinding.adapters[i].name, snake);
        i += 1;
    }
    try std.testing.expectEqual(hostBinding.adapters.len, i);
}

test "infer: std package ---- import binds namespace" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {collections} from "std";
        \\
        \\fn main() {
        \\    val a: i32 = collections.toInt(collections.lt());
        \\    val b: i32 = collections.toInt(collections.reverse(collections.gt()));
        \\}
    );
}

// ── decision 107: only the leaf enters scope ─────────────────────────────────

test "infer: std package ---- a dotted path binds its leaf, a group binds several" {
    // `Dict` (a type, whose type-scoped `empty` builds it — decision 111),
    // `gt`/`reverse` and `rank` (fns, the last aliased) — and `collections`
    // is not bound: only the leaf enters scope, so the namespace has to be
    // imported on its own to be spelled.
    try h.assertInfersOk(std.testing.allocator,
        \\import {collections.Dict, collections: {gt, reverse, toInt as rank}} from "std";
        \\
        \\fn main() {
        \\    val d: Dict<string, i32> = Dict.empty();
        \\    val n: i32 = d.insert("a", 1).size();
        \\    val o: i32 = rank(reverse(gt()));
        \\}
    );
}

test "infer: std package ---- an intermediate node may be a leaf" {
    // `io: {clock}` binds the module `clock` as a namespace, and inside the
    // same group the prefix is a leaf too: `clock: {monotonicMillis}` beside
    // `clock` itself.
    try h.assertInfersOk(std.testing.allocator,
        \\import {io: {clock, clock: {monotonicMillis}}} from "std";
        \\
        \\fn main() {
        \\    val a = clock.monotonicMillis();
        \\    val b = monotonicMillis();
        \\    val n = b - a;
        \\}
    );
}

test "infer: std package ---- the namespace is not bound by a path through it" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {collections.lt} from "std";
        \\
        \\fn main() {
        \\    val a = collections.toInt(lt());
        \\}
    );
}

test "infer: std package ---- two leaves binding one name collide at the second" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {url.parse, json.parse} from "std";
        \\
        \\fn main() {
        \\    val u = parse("http://a");
        \\}
    );
}

test "infer: std package ---- an alias on either side clears the collision" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {url.parse as parseUrl, json: {parse as parseJson}} from "std";
        \\
        \\fn main() {
        \\    val u = parseUrl("http://a/b");
        \\    val j = parseJson("{}");
        \\}
    );
}

// Decision 110 — `as` binds a type leaf: `D` is a checker-local name of
// `Dict` (it used to be refused as `import-alias-on-type`).
test "infer: std package ---- a type keeps its declared name" {
    try h.assertInfersOk(std.testing.allocator,
        \\import {collections.Dict as D} from "std";
        \\
        \\fn main() {
        \\    val d: D<string, i32> = D(pairs: []);
        \\}
    );
}

test "infer: std package ---- a path whose prefix is no module is refused at the item" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {dict.Dict} from "std";
        \\
        \\fn main() {
        \\    val n = 1;
        \\}
    );
}

test "infer: std package ---- a leaf the module does not declare is refused at the item" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\import {collections: {Dict, emptyish}} from "std";
        \\
        \\fn main() {
        \\    val n = 1;
        \\}
    );
}

test "infer: a @Result's methods typecheck (decision 330: no `result` namespace)" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn parse(n: i32) -> Result<i32, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return n;
        \\}
        \\
        \\fn main() {
        \\    val doubled = parse(21).map({ x -> x * 2 });
        \\    val n: i32 = doubled.unwrapOr(0);
        \\    val ok: bool = parse(n).isOk();
        \\}
    );
}

// Decision 330 — `?T` has no methods; `??` is its default and answers the
// payload. `conformance/modules/decisions-taken/optional_typescript_operators-330/refused/src/cases/optional_has_no_methods` carries the
// refusal of `.unwrapOr` on a `?T`.
test "infer: the nullish default answers the inner type" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn firstChar(s: string) -> ?string { panic("not implemented"); }
        \\fn main() {
        \\    val s: string = firstChar("abc") ?? "";
        \\    print(s);
        \\}
        \\
        \\import {io.terminal.print, failure.panic} from "std";
    );
}

test "infer: @Option<T> is rejected ---- the optional type is ?T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn takeOption(x: @Option<i32>) -> i32 {
        \\    return x.unwrapOr(0);
        \\}
        \\fn main() {
        \\    print(takeOption(3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: @Optional<T> is rejected ---- the optional type is ?T" {
    try h.assertTypeErrorSnap(std.testing.allocator, @src(),
        \\fn takeOptional(x: @Optional<i32>) -> i32 {
        \\    return x.unwrapOr(0);
        \\}
        \\fn main() {
        \\    print(takeOptional(3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "infer: forward_reference_top_level ---- a() calls b() declared after" {
    try h.assertInfersOk(std.testing.allocator,
        \\fn a() -> i32 { return b(); }
        \\fn b() -> i32 { return 1; }
    );
}

test "infer: mutual_recursion ---- renderToString and renderChildren call each other" {
    try h.assertInfersOk(std.testing.allocator,
        \\type Element(tag: string, value: string, children: Element[])
        \\
        \\fn renderChildren(items: Element[]) -> string {
        \\    var out = "";
        \\    for (items) { c -> out = out + renderToString(c); };
        \\    return out;
        \\}
        \\
        \\fn renderToString(e: Element) -> string {
        \\    if (e.tag == "#text") { return e.value; };
        \\    return "<" + e.tag + ">" + renderChildren(e.children) + "</" + e.tag + ">";
        \\}
    );
}

/// Infers `src` and answers the rendered refusal (caller frees), or fails
/// the test when inference accepts it.
fn refusalOf(src: []const u8) ![]u8 {
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var lx = Lexer.init(src);
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    var program = try @import("../std_calls.zig").expand(alloc, try p.parse(alloc), null);
    defer program.deinit(alloc);
    var env = try inferMod.freshEnv(alloc, std.testing.allocator);
    defer env.deinit();
    try std.testing.expectError(error.TypeError, inferMod.inferProgram(&env, program));
    const err = env.lastError orelse return error.TestExpectedEqual;
    try std.testing.expect(err.loc != null);
    return h.renderTypeError(std.testing.allocator, src, err);
}

test "infer error: a module fn named like an import item is import-name-collision at its name" {
    const desc = try refusalOf(
        \\import {page} from "deco";
        \\pub fn page(n: i32) -> i32 {
        \\    return n;
        \\}
    );
    defer std.testing.allocator.free(desc);
    try std.testing.expect(std.mem.indexOf(u8, desc, "import-name-collision: `page` is already bound by the import of `page`; a function of this module") != null);
    try std.testing.expect(std.mem.indexOf(u8, desc, ":2:8") != null);
}

test "infer error: a module val named like an import item is import-name-collision at its name" {
    const desc = try refusalOf(
        \\import {limit} from "conf";
        \\val limit = 3;
    );
    defer std.testing.allocator.free(desc);
    try std.testing.expect(std.mem.indexOf(u8, desc, "a `val` of this module would bind it again") != null);
    try std.testing.expect(std.mem.indexOf(u8, desc, ":2:5") != null);
}

test "parse error: a default is trailing in a record's fields and a variant's payload (decision 244)" {
    const cases = [_][]const u8{
        "type Port(number: i32 = 80, host: string)",
        "type Shape { Rect(width: i32 = 1, height: i32), Dot }",
    };
    for (cases) |src| {
        var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
        defer arena.deinit();
        const alloc = arena.allocator();
        var lx = Lexer.init(src);
        const tokens = try lx.scanAll(alloc);
        defer lx.deinit(alloc);
        var p = Parser.init(tokens);
        try std.testing.expectError(error.UnexpectedToken, p.parse(alloc));
        const info = p.parseError orelse return error.TestExpectedEqual;
        try std.testing.expectEqual(parserMod.ParseErrorType.fieldDefaultTrailingOnly, info.kind);
    }
    // Every field after the first default carries one: accepted.
    var arena = std.heap.ArenaAllocator.init(std.testing.allocator);
    defer arena.deinit();
    const alloc = arena.allocator();
    var lx = Lexer.init("type Port(host: string, number: i32 = 80, tls: bool = false)");
    const tokens = try lx.scanAll(alloc);
    defer lx.deinit(alloc);
    var p = Parser.init(tokens);
    _ = try p.parse(alloc);
}
