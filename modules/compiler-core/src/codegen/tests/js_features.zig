//! codegen: lambda/enum/destructure/star/import/range/pipeline/hooks (split from tests.zig).

const std = @import("std");
const Allocator = std.mem.Allocator;
const codegen = @import("../../codegen.zig");
const snap = @import(".././snapshot.zig");
const config = @import(".././config.zig");
const Lexer = @import("../../lexer.zig").Lexer;
const Parser = @import("../../parser.zig").Parser;
const Module = codegen.Module;
const ModuleOutput = @import(".././moduleOutput.zig").ModuleOutput;
const GenerateResult = @import(".././moduleOutput.zig").GenerateResult;
const comptimeMod = @import("../../comptime.zig");
const validation = @import("../../comptime/error.zig");
const h = @import("helpers.zig");

test "js: star fn ---- async function with await" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn fetch(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
        \\*fn loadTwice(x: i32) -> @Future<i32> {
        \\    val a = await fetch(x);
        \\    return a + a;
        \\}
    );
}

test "js: star fn ---- generator with yield" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn counter() -> @Iterator<i32> {
        \\    yield 1;
        \\    yield 2;
        \\    yield 3;
        \\}
    );
}

test "js: star fn ---- async generator" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn stream() -> @AsyncIterator<i32, string> {
        \\    yield 1;
        \\    yield 2;
        \\}
    );
}

test "js: star fn ---- pub typedefs" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub *fn loadOne(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
        \\pub *fn count() -> @Iterator<i32> {
        \\    yield 1;
        \\}
        \\pub *fn pulses() -> @AsyncIterator<i32, string> {
        \\    yield 1;
        \\}
    );
}

// ── effect annotations (`#[@<effect>]`) ──────────────────────────────────────

test "js: effect annotation ---- future/iterator/asyncGenerator/result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@future]
        \\fn fetch(x: i32) -> @Future<i32> {
        \\    return x;
        \\}
        \\#[@iterator]
        \\fn counter() -> @Iterator<i32> {
        \\    yield 1;
        \\    yield 2;
        \\}
        \\#[@asyncGenerator]
        \\fn stream() -> @AsyncIterator<i32, string> {
        \\    yield 1;
        \\}
        \\#[@result]
        \\fn parse(n: i32) -> @Result<i32, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return n;
        \\}
    );
}

test "js: effect annotation ---- generator lowers to function*" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\#[@generator]
        \\fn range(a: i32, b: i32) -> @Generator<i32> {
        \\    yield a;
        \\    yield b;
        \\}
    );
}

// Each `#[@<effect>]` lowers byte-identically to the deprecated `*fn` form.
test "js: effect annotation lowers identically to *fn" {
    const cases = [_]struct { ann: []const u8, star: []const u8 }{
        .{
            .ann = "#[@future]\nfn f(x: i32) -> @Future<i32> { return x; }",
            .star = "*fn f(x: i32) -> @Future<i32> { return x; }",
        },
        .{
            .ann = "#[@iterator]\nfn f() -> @Iterator<i32> { yield 1; yield 2; }",
            .star = "*fn f() -> @Iterator<i32> { yield 1; yield 2; }",
        },
        .{
            .ann = "#[@asyncGenerator]\nfn f() -> @AsyncIterator<i32, string> { yield 1; }",
            .star = "*fn f() -> @AsyncIterator<i32, string> { yield 1; }",
        },
        .{
            .ann = "#[@result]\nfn f(n: i32) -> @Result<i32, string> { if (n < 0) { throw \"x\"; }; return n; }",
            .star = "*fn f(n: i32) -> @Result<i32, string> { if (n < 0) { throw \"x\"; }; return n; }",
        },
    };
    inline for (cases) |c| {
        const a = try h.generateJs(std.testing.allocator, c.ann);
        defer std.testing.allocator.free(a);
        const b = try h.generateJs(std.testing.allocator, c.star);
        defer std.testing.allocator.free(b);
        try std.testing.expectEqualStrings(b, a);
    }
}

test "js: enum ---- unit variants" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Direction = enum {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "js: enum ---- payload variant" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Color = enum {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\}
    );
}

test "js: enum ---- payload variants with method using variantFields case" {
    try h.assertJsSingle(std.testing.allocator, @src(),
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

test "js: enum ---- unit variants with method using ident case" {
    try h.assertJsSingle(std.testing.allocator, @src(),
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

test "js: enum ---- mixed unit and payload with method using mixed case" {
    try h.assertJsSingle(std.testing.allocator, @src(),
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

test "js: enum ---- method using qualified enum member" {
    try h.assertJsSingle(std.testing.allocator, @src(),
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

test "js: import ---- named imports" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\import { foo, bar };
    );
}

test "codegen ---- use object destructure state to useState" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn Counter() -> Element {
        \\    val {count, setCount} = use state(0);
        \\    Element();
        \\}
    );
}

test "codegen ---- use tuple destructure state to useState" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn Counter() -> Element {
        \\    val #(count, setCount) = use state(0);
        \\    Element();
        \\}
    );
}

test "codegen ---- use memo infers dependency array" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn state(initial: i32) -> @Context<Element, i32> {
        \\    initial;
        \\}
        \\fn memo() -> @Context<Element, i32> {
        \\    0;
        \\}
        \\fn Counter() -> Element {
        \\    val {count, setCount} = use state(0);
        \\    val doubled = use memo { -> return count * 2; };
        \\    Element();
        \\}
    );
}

test "codegen ---- use effect void hook empty deps" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn cleanup() {
        \\    0;
        \\}
        \\fn effect() -> @Context<Element, i32> {
        \\    0;
        \\}
        \\fn Widget() -> Element {
        \\    use effect { -> cleanup(); };
        \\    Element();
        \\}
    );
}

test "codegen ---- inline implement context base erased at runtime" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = struct implement @Context<Element, Element> { }
        \\fn render() -> Element {
        \\    Element();
        \\}
    );
}

test "js: destructure ---- record val binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32 }
        \\fn describe(p: Point) -> i32 {
        \\    val { x, y } = p;
        \\    @print(x, y);
        \\    return x;
        \\}
    );
}

test "js: destructure ---- record val binding with spread" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32, z: i32 }
        \\fn describe(p: Point) -> i32 {
        \\    val { x, .. } = p;
        \\    return x;
        \\}
    );
}

test "js: destructure ---- record parameter in fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Person { name: string, age: i32 }
        \\fn greet({ name, .. }: Person) -> string {
        \\    @print(name);
        \\    return name;
        \\}
    );
}

test "js: destructure ---- tuple val binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn extract() {
        \\    val #(a, b) = #(12, "hello");
        \\    @print(a, b);
        \\}
    );
}

test "js: destructure ---- tuple parameter in fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(#(x, y): #(i32, i32)) -> i32 {
        \\    return x;
        \\}
    );
}

test "js: destructure ---- tuple var binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    var #(x, y) = #(10, 20);
        \\}
    );
}

test "js: destructure ---- tuple with long names" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn get_coordinates() -> #(f32, f32) {
        \\    return #(0.0, 0.0);
        \\}
        \\fn extract_coordinates() {
        \\    val #(longitude, latitude) = get_coordinates();
        \\}
    );
}

test "js: destructure ---- tuple with try-catch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record Error { msg: string }
        \\*fn fetch() -> @Result<#(i32, i32), Error> {
        \\    throw Error(msg: "boom");
        \\}
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

test "js: enum ---- shorthand declaration without val Name =" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\enum Direction {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "js: import ---- multi-module pub fn import" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "math", .source =
        \\pub fn double(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        },
        .{ .path = "", .source =
        \\import {double} from "math";
        \\val result = double(21);
        },
    });
}

test "js: import ---- multi-module pub val import" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "config", .source =
        \\pub val PORT = 8080;
        \\pub val HOST = "localhost";
        },
        .{ .path = "", .source =
        \\import {PORT, HOST} from "config";
        \\val addr = HOST;
        \\val port = PORT;
        },
    });
}

test "js: import ---- cross-module record construct and assoc fn" {
    // A library ships concrete emitted types (`Response`/`App`); a consumer
    // imports them, calls a record's associated fn across the package boundary
    // (`Response.ok(...)`), and constructs an imported record positionally
    // (`App(8080, "/")`). Every backend must link these to the owning module:
    // commonJS `require`s + `new`/`static`; erlang/beam remote-call the owner
    // atom + build the owner's map. (wasm stays single-module — see wat.zig.)
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "http", .source =
        \\pub record Response {
        \\    body: string,
        \\    fn ok(body: string) -> Response {
        \\        return Response(body: body);
        \\    }
        \\}
        \\
        \\pub record App {
        \\    port: i32,
        \\    path: string,
        \\}
        },
        .{ .path = "", .source =
        \\import {Response, App} from "http";
        \\
        \\fn main() {
        \\    val r = Response.ok("hi");
        \\    @print(r.body);
        \\    val a = App(8080, "/");
        \\    @print(a.port);
        \\}
        },
    });
}

test "js: import ---- disk-lib namespace member binds + emits the namespace object" {
    // A disk-loaded lib (module path `<lib>/<stem>`, reached via `from "<lib>"`)
    // exports an ordinary `pub fn` (`make`, an emitted symbol) and a template fn
    // whose name equals the lib (`qlib`, comptime-only → no emitted symbol). The
    // consumer imports both: `make` destructures from the owning module, while
    // the lib-named handle is bound to the whole module object so `qlib.make(...)`
    // resolves at runtime — parity with the bare form. Generic: no lib name lives
    // in the core; the lib is whatever `from "<lib>"` resolved off disk.
    try h.assertConsumerJs(std.testing.allocator, &.{
        .{ .path = "qlib/qlib", .source =
        \\pub fn make(x: i32) -> i32 {
        \\    return x + 1;
        \\}
        \\
        \\pub fn qlib(comptime e: @Expr<string>) -> @Expr<i32> {
        \\    return e.build("99");
        \\}
        },
        .{ .path = "", .source =
        \\import {make, qlib} from "qlib";
        \\
        \\fn main() {
        \\    val a = make(1);
        \\    val b = qlib.make(5);
        \\    @print(a + b);
        \\}
        },
    }, &.{
        "const { make } = require(\"./qlib/qlib.js\");",
        "const qlib = require(\"./qlib/qlib.js\");",
        "qlib.make(5)",
    }, &.{});
}

test "js: import ---- disk-lib namespace merges across the lib's modules" {
    // A lib spread over two files (`mlib/core`, `mlib/extra`, both under the
    // `mlib/` prefix): the namespace handle merges every module of the lib via
    // `Object.assign({}, …)`, sorted for deterministic output, so members from
    // either file resolve (`mlib.make` from core, `mlib.twice` from extra).
    try h.assertConsumerJs(std.testing.allocator, &.{
        .{ .path = "mlib/core", .source =
        \\pub fn make(x: i32) -> i32 {
        \\    return x + 1;
        \\}
        \\
        \\pub fn mlib(comptime e: @Expr<string>) -> @Expr<i32> {
        \\    return e.build("7");
        \\}
        },
        .{ .path = "mlib/extra", .source =
        \\pub fn twice(x: i32) -> i32 {
        \\    return x * 2;
        \\}
        },
        .{ .path = "", .source =
        \\import {mlib} from "mlib";
        \\
        \\fn main() {
        \\    @print(mlib.make(1) + mlib.twice(3));
        \\}
        },
    }, &.{
        "const mlib = Object.assign({}, require(\"./mlib/core.js\"), require(\"./mlib/extra.js\"));",
        "mlib.make(1)",
        "mlib.twice(3)",
    }, &.{});
}

test "js: pipeline ---- simple chain" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1
        \\        |> double
        \\        |> inc;
        \\    @print(result);
        \\}
    );
}

test "js: pipeline ---- with labeled args" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1
        \\        |> double
        \\        |> inc;
        \\    @print(result);
        \\}
    );
}

test "js: range ---- iterate over range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sumTo(n: i32) -> i32 {
        \\    return loop (0..n) { i ->
        \\        yield i;
        \\    };
        \\}
    );
}

test "js: range ---- open-ended range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn countUp(x: i32) {
        \\    loop (x..) { i ->
        \\        if (i > 100) {
        \\          break;
        \\        };
        \\    };
        \\}
    );
}

test "js: negation ---- simple unary minus" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn negate(x: i32) -> i32 {
        \\    return -x;
        \\}
        \\fn main() {
        \\    @print(negate(42));
        \\}
    );
}

test "js: negation ---- in expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn diff(x: i32, y: i32) -> i32 {
        \\    return x + -y;
        \\}
        \\fn main() {
        \\    @print(diff(10, 3));
        \\}
    );
}

test "js: enum ---- method with case on self" {
    try h.assertJsSingle(std.testing.allocator, @src(),
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

test "js: lambda ---- with parameter" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn apply(f: syntax fn(x: i32) -> i32) -> i32 {
        \\    return f(10);
        \\}
    );
}

test "js: lambda ---- multi-statement body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(f: syntax fn(x: i32) -> i32) -> i32 {
        \\    return f(5);
        \\}
    );
}

test "js: lambda ---- standalone with params" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val add = { x, y ->
        \\    x + y;
        \\};
        \\val result = add(10, 20);
        \\@print(result);
    );
}

test "js: lambda ---- with type annotation" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val func: fn(string)-> string = {s ->
        \\        return s;
        \\    };
        \\    return func("hello");
        \\}
    );
}

test "js: lambda ---- multi param with type annotation" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> i32 {
        \\    val add: fn(i32,i32)-> i32 = {a, b ->
        \\        return a + b;
        \\    };
        \\    return add(10, 20);
        \\}
    );
}

test "js: lambda ---- simple standalone" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() -> string {
        \\    val func = {s ->
        \\        return s;
        \\    };
        \\    return func("hello");
        \\}
    );
}

test "js: lambda ---- full type annotation infers params" {
    // Before the `fn(...) -> ...` annotation was lowered to a `.func` type,
    // this failed to type-check (named-vs-func mismatch). It must now compile,
    // with `a`/`b` inferred as `i32` from the annotation.
    try h.assertJsContains(std.testing.allocator,
        \\val add: fn(i32, i32) -> i32 = { a, b -> a + b };
        \\val result = add(2, 3);
    , &.{
        "add(2, 3)",
    });
}

test "js: lambda ---- string-typed annotation infers params" {
    // A different element type proves the annotation (not just `+` defaulting)
    // drives param typing: `a`/`b` are `string` and the body concatenates them.
    try h.assertJsContains(std.testing.allocator,
        \\val join: fn(string, string) -> string = { a, b -> a + b };
        \\val r = join("x", "y");
    , &.{
        "join(",
    });
}

test "js: optional chaining ---- member access short-circuits null" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\record User { name: string }
        \\
        \\fn main() {
        \\    val u: ?User = User(name: "ana");
        \\    @print(u?.name);
        \\}
    );
}

test "js: reserved word identifiers" {
    // JS reserved words used as botopink fn names, params, and locals must be
    // renamed on emission (`delete` → `delete_`, `with` → `with_`) — emitting
    // them verbatim is a SyntaxError that kills the whole module. The rename is
    // consistent across the decl, call sites, and the `exports.<name>` property
    // keeps the original botopink name.
    // `delete`/`with`/`class`/`static` are JS reserved words but valid botopink
    // identifiers (botopink keywords like `new`/`enum` are excluded by the
    // parser, so they can never reach codegen as user names).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn delete(with: string, class: string) -> string {
        \\    val static = with + class;
        \\    return static;
        \\}
        \\
        \\fn main() {
        \\    @print(delete("a", "b"));
        \\}
    );
}

test "js: iterator fromList yields array items" {
    // A `*fn -> @Iterator<T>` generator: `loop (xs) { yield }` must lower to a
    // real `for…of` with native `yield` (not `.map()`), and `return <iter>`
    // must delegate via `yield*` — otherwise the generator yields nothing.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\*fn fromList<T>(xs: Array<T>) -> @Iterator<T> {
        \\    loop (xs) { item ->
        \\        yield item;
        \\    };
        \\}
        \\
        \\*fn doRange(cur: i32, stop: i32) -> @Iterator<i32> {
        \\    if (cur < stop) {
        \\        yield cur;
        \\        return doRange(cur + 1, stop);
        \\    };
        \\}
        \\
        \\fn toList<T>(iter: @Iterator<T>) -> Array<T> {
        \\    var out = [];
        \\    loop (iter) { item ->
        \\        out.push(item);
        \\    };
        \\    return out;
        \\}
        \\
        \\fn main() {
        \\    @print(toList(fromList([1, 2, 3])).join(","));
        \\    @print(toList(doRange(0, 3)).join(","));
        \\}
    );
}

test "js: option method on tuple element" {
    // A `?T` flowing through a tuple element (`result._1`) must keep its
    // `@Option` method surface — inference resolves the tuple-index type so
    // `.unwrapOr` lowers to `__bp_option_unwrapOr`. `== null` uses loose
    // equality so an `undefined` none (from `Array.at`) matches.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn firstAndRest(xs: Array<i32>) -> #(Array<i32>, ?i32) {
        \\    val head = xs.at(0);
        \\    val rest = xs.slice(1, xs.length);
        \\    return #(rest, head);
        \\}
        \\
        \\fn main() {
        \\    val result = firstAndRest([1, 2, 3]);
        \\    val head = result._1;
        \\    @print(head.unwrapOr(-1));
        \\    val empty = firstAndRest([]);
        \\    @print(empty._1 == null);
        \\}
    );
}

test "js: interface associated fn namespace" {
    // An interface's associated functions (`default fn` with no `self`) emit as
    // a namespace object so `Interface.method(...)` resolves at runtime.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\interface Pairish<A, B> {
        \\    default fn of(first: A, second: B) -> #(A, B) {
        \\        return #(first, second);
        \\    }
        \\    default fn first(p: #(A, B)) -> A {
        \\        return p._0;
        \\    }
        \\}
        \\
        \\fn main() {
        \\    val p = Pairish.of(1, "one");
        \\    @print(Pairish.first(p));
        \\}
    );
}

test "js: stdlib associated fn namespace injected" {
    // `Pair`/`Function` are primitives in primitives.d.bp (not in the user
    // program). When their associated fns are used, codegen injects the
    // interface decl so the namespace object is emitted at runtime.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val p = Pair.of(1, "one");
        \\    @print(Pair.first(p));
        \\    @print(Function.identity(42));
        \\    val inc = Function.compose({ x -> x + 1 }, { y -> y * 2 });
        \\    @print(inc(10));
        \\}
    );
}

test "js: array instance default-fn methods" {
    // `Array<T>` `default fn` instance methods (`prepend`, `fold`, `isEmpty`, …)
    // materialize as `Array.prototype.<m>` patches when used. `append` maps to
    // native `concat`; native `Array.prototype` methods are left to the engine.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs = [1, 2, 3];
        \\    @print(xs.prepend(0).join(","));
        \\    @print(xs.fold(0, { a, x -> a + x }));
        \\    @print(xs.isEmpty());
        \\    @print(xs.all({ x -> x > 0 }));
        \\}
    );
}

test "js: bool instance default-fn methods" {
    // `Bool` `default fn`s materialize as `Boolean.prototype.<m>`. A boxed
    // primitive's `this` is a truthy wrapper, so the body unwraps via
    // `this.valueOf()` (`const self = this.valueOf()`).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    @print(true.negate());
        \\    @print(false.nor(false));
        \\    @print(true.nand(true));
        \\    @print(true.exclusiveOr(false));
        \\}
    );
}

test "js: numeric instance methods (external + default-fn)" {
    // Numeric `@[external]` methods backed by a JS global (`Math`) lower to
    // `Number.prototype.<m> = function(a){ return Math.<sym>(this.valueOf(), a); }`;
    // `default fn`s like `clamp`/`isEven` materialize and call them.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val n = -5;
        \\    @print(n.abs());
        \\    @print(n.min(3));
        \\    @print(n.max(10));
        \\    @print(n.clamp(0, 5));
        \\    val x = 7;
        \\    @print(x.isEven());
        \\}
    );
}

test "js: string methods map to native JS names" {
    // `String` host-backed methods whose name differs from the native JS one are
    // mapped (`toUpper`→`toUpperCase`, `toLower`→`toLowerCase`); same-named ones
    // (`split`, `trim`, `slice`, `startsWith`) use the engine directly.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "Hello,World";
        \\    @print(s.toUpper());
        \\    @print(s.toLower());
        \\    @print(s.split(",").join("|"));
        \\    @print(s.slice(0, 5));
        \\}
    );
}
