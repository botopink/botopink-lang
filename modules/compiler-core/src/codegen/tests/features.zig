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
        \\fn fetch(x: i32) -> Task<i32> {
        \\    return x;
        \\}
        \\fn loadTwice(x: i32) -> Task<i32> {
        \\    val a = await fetch(x);
        \\    return a + a;
        \\}
    );
}

test "js: star fn ---- generator with yield" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn counter() -> Iterator<i32> {
        \\    yield 1;
        \\    yield 2;
        \\    yield 3;
        \\}
    );
}

test "js: star fn ---- future generator" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn stream() -> Stream<Result<i32, string>> {
        \\    yield 1;
        \\    yield 2;
        \\}
    );
}

test "js: star fn ---- pub typedefs" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn loadOne(x: i32) -> Task<i32> {
        \\    return x;
        \\}
        \\pub fn count() -> Iterator<i32> {
        \\    yield 1;
        \\}
        \\pub fn pulses() -> Stream<Result<i32, string>> {
        \\    yield 1;
        \\}
    );
}

// ── effect annotations (`#[@<effect>]`) ──────────────────────────────────────

test "js: effect annotation ---- future/iterator/futureGenerator/result" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn fetch(x: i32) -> Task<i32> {
        \\    return x;
        \\}
        \\fn counter() -> Iterator<i32> {
        \\    yield 1;
        \\    yield 2;
        \\}
        \\fn stream() -> Stream<Result<i32, string>> {
        \\    yield 1;
        \\}
        \\fn parse(n: i32) -> Result<i32, string> {
        \\    if (n < 0) { throw "negative"; };
        \\    return n;
        \\}
    );
}

test "js: effect annotation ---- generator lowers to function*" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn range(a: i32, b: i32) -> Iterator<i32> {
        \\    yield a;
        \\    yield b;
        \\}
    );
}

// Decision 122 — `.next()` by hand answers the prelude `YieldStep<T>`: the
// module that steps a sequence gets the enum spliced in, commonJS maps the
// generator's `{ value, done }` onto it and the eager backends pop the list's
// head and rebind the receiver to the rest.
test "js: effect annotation ---- next by hand steps an iterator with YieldStep" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn two() -> Iterator<i32> {
        \\    yield 1;
        \\    yield 2;
        \\}
        \\fn stepText(s: YieldStep<i32>) -> string {
        \\    val t = case s {
        \\        Yield(v) -> "yield " + v.toString();
        \\        Done -> "done";
        \\    };
        \\    return t;
        \\}
        \\pub fn main() {
        \\    val it = two();
        \\    print(stepText(it.next()));
        \\    print(stepText(it.next()));
        \\    print(stepText(it.next()));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: effect annotation ---- next by hand on a stream answers a Task of YieldStep" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn countdown(n: i32) -> Stream<i32> {
        \\    var i = n;
        \\    while (i > 0) {
        \\        yield i;
        \\        i = i - 1;
        \\    };
        \\}
        \\fn stepText(s: YieldStep<i32>) -> string {
        \\    val t = case s {
        \\        Yield(v) -> "yield " + v.toString();
        \\        Done -> "done";
        \\    };
        \\    return t;
        \\}
        \\fn run() -> Task<void> {
        \\    val s = countdown(1);
        \\    print(stepText(await s.next()));
        \\    print(stepText(await s.next()));
        \\}
        \\pub fn main() {
        \\    run();
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: enum ---- unit variants" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Direction = type {
        \\    North,
        \\    South,
        \\    East,
        \\    West,
        \\}
    );
}

test "js: enum ---- payload variant" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Color = type {
        \\    Red,
        \\    Rgb(r: i32, g: i32, b: i32),
        \\}
    );
}

test "js: enum ---- payload variants with method using variantFields case" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Shape = type {
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
        \\val HttpMethod = type {
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
        \\val Maybe = type {
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
        \\val Status = type {
        \\    Active,
        \\    Inactive,
        \\    fn isDefault(s: Self) -> Status {
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

// `use` is a transparent prefix on every backend (decision 88, front 19 of
// 1.0.10-beta): `val c = use state(0)` is `const c = state(0)`. The React rename
// (`state` → `useState`) and the inferred dependency arrays these four cells
// used to record were deleted with the decision — the emitted name was never
// declared, and the client runtime supplies hook semantics through what `state`
// does. The component carries `#[@use]`, the effect that lets a body
// activate a hook.
test "codegen ---- use object destructure is a plain call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = type() implement Renderable
        \\fn state(initial: i32) -> Component<i32> {
        \\    return initial;
        \\}
        \\fn Counter() -> Component<Element> {
        \\    val {count, setCount} = use state(0);
        \\    return Element();
        \\}
    );
}

// Front 19 step 3: the tuple form binds `R`'s elements (`shown : i32`,
// `push : fn(action: i32) -> i32`), so the hook's `R` is a tuple here — the
// lowering is the same plain call followed by the destructure.
test "codegen ---- use tuple destructure is a plain call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = type() implement Renderable
        \\fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> Component<#(i32, fn(action: i32) -> i32)> {
        \\    val push: fn(i32) -> i32 = { action -> f(base, action) };
        \\    return #(base, push);
        \\}
        \\fn LikeWidget() -> Component<Element> {
        \\    val #(shown, push) = use optimistic(12, { c, a -> c + a });
        \\    push(shown);
        \\    return Element();
        \\}
    );
}

test "codegen ---- use memo is a plain call with no inferred deps" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = type() implement Renderable
        \\fn state(initial: i32) -> Component<i32> {
        \\    return initial;
        \\}
        \\fn memo(f: fn() -> i32) -> Component<i32> {
        \\    return 0;
        \\}
        \\fn Counter() -> Component<Element> {
        \\    val {count, setCount} = use state(0);
        \\    val doubled = use memo { -> return count * 2; };
        \\    return Element();
        \\}
    );
}

test "codegen ---- use effect void hook is a plain call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = type() implement Renderable
        \\fn cleanup() {
        \\    0;
        \\}
        \\fn effect(f: fn()) -> Component<i32> {
        \\    return 0;
        \\}
        \\fn Widget() -> Component<Element> {
        \\    use effect { -> cleanup(); };
        \\    return Element();
        \\}
    );
}

test "codegen ---- inline implement context base erased at runtime" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Element = type() implement Renderable
        \\fn render() -> Element {
        \\    return Element();
        \\}
    );
}

test "js: destructure ---- record val binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32)
        \\fn describe(p: Point) -> i32 {
        \\    val { x, y } = p;
        \\    print(x, y);
        \\    return x;
        \\}
        \\fn main() {
        \\    describe(Point(x: 3, y: 4));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: destructure ---- record val binding with spread" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Point(x: i32, y: i32, z: i32)
        \\fn describe(p: Point) -> i32 {
        \\    val { x, .. } = p;
        \\    return x;
        \\}
    );
}

test "js: destructure ---- record parameter in fn" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Person(name: string, age: i32)
        \\fn greet({ name, .. }: Person) -> string {
        \\    print(name);
        \\    return name;
        \\}
        \\fn main() {
        \\    greet(Person(name: "Ana", age: 30));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: destructure ---- tuple val binding" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val #(a, b) = #(12, "hello");
        \\    print(a, b);
        \\}
        \\
        \\import {io.terminal.print} from "std";
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
        \\fn get_coordinates() -> #(f64, f64) {
        \\    return #(0.0, 0.0);
        \\}
        \\fn extract_coordinates() {
        \\    val #(longitude, latitude) = get_coordinates();
        \\}
    );
}

test "js: destructure ---- tuple with try-catch" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Error(msg: string)
        \\fn fetch() -> Result<#(i32, i32), Error> {
        \\    throw Error(msg: "boom");
        \\}
        \\fn f() {
        \\    val #(a, b) = try fetch() catch throw Error(msg: "failed");
        \\}
    );
}

test "js: enum ---- shorthand declaration without val Name =" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Direction {
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
        \\import {math.double};
        \\val result = double(21);
        },
    });
}

// 13 half 1 — the collision the erlang module atom used to have: two `.bp`
// files whose paths share a BASENAME both emitted `-module(user)`, so one
// silently overwrote the other in a shared output directory and silently
// shadowed it on one code path. Nothing diagnosed it, and no cell could see it
// because no fixture had two same-named modules. The atom is the whole path
// joined with `@` now, so this program has `models@user` and `services@user`
// and both answer. It could not exist before.
test "js: import ---- two modules whose files share a basename" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "models/user", .source =
        \\pub fn label() -> string {
        \\    return "models/user";
        \\}
        },
        .{ .path = "services/user", .source =
        \\pub fn tag() -> string {
        \\    return "services/user";
        \\}
        },
        .{ .path = "", .source =
        \\import {models.user.label};
        \\import {services.user.tag};
        \\
        \\fn main() {
        \\    print(label());
        \\    print(tag());
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    });
}

// ── decision 107: a dotted path and a braced group are one tree ──────────────
//
// The consumer binds LEAVES through paths into a module tree — the dotted
// spelling (`shapes.circle.name as circleName`) and the grouped spelling
// (`shapes: {helpers: {seven}}`) — with no `from`: the package's own tree. Only
// the leaf enters scope, under its alias when one is written, and the four
// backends resolve the owner through the path, not through the bare name (the
// two `label`s below live in different modules and both answer on all four
// backends).
test "js: import ---- a dotted path and a group bind their leaves across a module tree" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "shapes/circle", .source =
        \\pub fn name() -> string {
        \\    return "circle";
        \\}
        \\
        \\pub fn label() -> string {
        \\    return "shapes/circle";
        \\}
        },
        .{ .path = "shapes/helpers", .source =
        \\pub fn seven() -> i32 {
        \\    return 7;
        \\}
        \\
        \\pub fn label() -> string {
        \\    return "shapes/helpers";
        \\}
        },
        .{ .path = "", .source =
        \\import {shapes.circle.name as circleName, shapes: {helpers: {seven, label}, circle: {label as circleLabel}}};
        \\
        \\fn main() {
        \\    print(circleName());
        \\    print(seven());
        \\    print(label());
        \\    print(circleLabel());
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    });
}

// The same tree, with `*` and a type on the leaves: `pond: {Pato, PatoNada*}`
// activates the imported extension exactly as `import {Pato, PatoNada*} from
// "pond"` does (`dispatch_multi_module_extension_activated_via_star_import`).
test "js: import ---- a group activates an extension on its leaf" {
    try h.assertJs(std.testing.allocator, @src(), &.{
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
        \\import {pond: {Pato, PatoNada*}};
        \\fn main() {
        \\    val donald = Pato(2);
        \\    print(donald.swim());
        \\}
        \\
        \\import {io.terminal.print} from "std";
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
        \\import {config.PORT, config.HOST};
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
        \\pub type Response(
        \\    body: string) {
        \\    fn ok(body: string) -> Response {
        \\        return Response(body: body);
        \\    }
        \\}
        \\
        \\pub type App(
        \\    port: i32,
        \\    path: string,
        \\)
        },
        .{ .path = "", .source =
        \\import {http.Response, http.App};
        \\
        \\fn main() {
        \\    val r = Response.ok("hi");
        \\    print(r.body);
        \\    val a = App(8080, "/");
        \\    print(a.port);
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    });
}

test "js: import ---- disk-lib module named like the lib binds its namespace, not its like-named fn" {
    // A disk-loaded lib (module path `<lib>/<stem>`, reached via `from "<lib>"`)
    // exports an ordinary `pub fn` (`make`) and a template fn whose name equals
    // the module's (`qlib`). Decision 582: `import {qlib} from "qlib"` names the
    // module `qlib/qlib`, so it binds that module's namespace — the like-named
    // fn no longer wins — and `qlib.make(5)` is `make` of it, imported from the
    // owning module like the bare `make`. Generic: no lib name lives in the core.
    try h.assertConsumerJs(std.testing.allocator, &.{
        .{ .path = "qlib/qlib", .source =
        \\pub fn make(x: i32) -> i32 {
        \\    return x + 1;
        \\}
        \\
        \\pub fn qlib(syntax e: string) -> i32 {
        \\    return compiler.build("99");
        \\}
        \\
        \\import {compiler} from "std";
        },
        .{ .path = "", .source =
        \\import {make, qlib} from "qlib";
        \\
        \\fn main() {
        \\    val a = make(1);
        \\    val b = qlib.make(5);
        \\    print(a + b);
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    }, &.{
        "const { make, make: __bp_ns_qlib__make } = require(\"./qlib/qlib.js\");",
        "__bp_ns_qlib__make(5)",
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
        \\pub fn mlib(syntax e: string) -> i32 {
        \\    return compiler.build("7");
        \\}
        \\
        \\import {compiler} from "std";
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
        \\    print(mlib.make(1) + mlib.twice(3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    }, &.{
        "const mlib = Object.assign({}, require(\"./mlib/core.js\"), require(\"./mlib/extra.js\"));",
        "mlib.make(1)",
        "mlib.twice(3)",
    }, &.{});
}

test "js: import ---- a sibling module imported with no `from` requires its own path" {
    // `pub mod leaf; import { leaf.Leaf };` — the emitter used to write the
    // literal word for an import with no `from`: `require("./module")` in a
    // project, `require("../module")` inside a dependency, which is how a
    // library's examples built and then died (04-js step 5). The path is the
    // sibling's own, relative to the importing module, in both shapes; the
    // RUN LOG is `conformance/modules/sibling/cells/sibling_import_in_a_dependency`'s.
    try h.assertConsumerJs(std.testing.allocator, &.{
        .{ .path = "leaf", .source = "pub type Leaf(v: i32)\n" },
        .{ .path = "", .source =
        \\pub mod leaf;
        \\import { leaf.Leaf };
        \\fn main() {
        \\    print(Leaf(v: 7).v);
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    }, &.{"const { Leaf } = require(\"./leaf.js\");"}, &.{"./module"});
    try h.assertModuleJs(std.testing.allocator, &.{
        .{ .path = "tree/leaf", .package = "tree", .source = "pub type Leaf(v: i32)\n" },
        .{ .path = "tree/api", .package = "tree", .source =
        \\import { leaf.Leaf };
        \\pub fn seven() -> i32 {
        \\    return Leaf(v: 7).v;
        \\}
        },
        .{ .path = "", .source =
        \\import {tree.api.seven};
        \\fn main() {
        \\    print(seven());
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    }, "tree/api", &.{"const { Leaf } = require(\"../tree/leaf.js\");"});
}

test "js: pipeline ---- simple chain" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn double(x: i32) -> i32 { return x * 2; }
        \\fn inc(x: i32) -> i32 { return x + 1; }
        \\fn main() {
        \\    val result = 1
        \\        |> double
        \\        |> inc;
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
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
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: range ---- iterate over range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn sumTo(n: i32) -> i32 {
        \\    var sum = 0;
        \\    for (0..n) { i ->
        \\        sum = sum + i;
        \\    };
        \\    return sum;
        \\}
    );
}

test "js: range ---- open-ended range" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn countUp(x: i32) {
        \\    for (x..) { i ->
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
        \\    print(negate(42));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: negation ---- in expression" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn diff(x: i32, y: i32) -> i32 {
        \\    return x + -y;
        \\}
        \\fn main() {
        \\    print(diff(10, 3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: enum ---- method with case on self" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Color = type {
        \\    Red,
        \\    Green,
        \\    Blue,
        \\    fn name(self: Self) -> string {
        \\        case (self) {
        \\            Red -> "red";
        \\            Green -> "green";
        \\            Blue -> "blue";
        \\        };
        \\    }
        \\};
    );
}

// An associated `fn` on an `enum` — no `self`, so it is a constructor-like
// helper, not an instance method. `memberCallNode`'s qualified-payload-variant
// branch fired on ANY `EnumName.callee(...)` without checking that `callee`
// names a variant, so this lowered to the tagged tuple `{unit}` on erlang: erlc
// clean, and the program died at run time with `{case_clause,{unit}}` inside the
// method that matched on it. beam had the mirror image — the receiver was
// lowercased into a module atom and the call was `shape:unit()`,
// `{undef,[{shape,unit,[],[]}…]}` — because an enum name is not in
// `record_fields` and nothing else claimed it.
test "js: enum ---- an associated fn on an enum is a call, not a variant" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "", .source =
        \\pub type Shape {
        \\    Circle(radius: i32),
        \\    Square(side: i32),
        \\
        \\    pub fn unit() -> Shape {
        \\        return Shape.Square(side: 1);
        \\    }
        \\
        \\    pub fn area(self: Self) -> i32 {
        \\        return case self {
        \\            Circle(r) -> r * r * 3;
        \\            Square(s) -> s * s;
        \\        };
        \\    }
        \\}
        \\
        \\fn main() {
        \\    val s: Shape = Shape.unit();
        \\    print(s.area());
        \\}
        \\
        \\import {io.terminal.print} from "std";
        },
    });
}

// 1.0.4-beta EXAMPLES.md §5: an enum method called on a variant value. Enum
// values carry no methods on commonJS (a payload variant is a plain object), so
// the call passes the value to the enum's method: `Shape.area(Shape.Square(4))`.
// It used to throw `Shape.Square(...).area is not a function`. All four
// backends print `16` then `12`.
test "js: enum ---- a method is called on a variant value" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub type Shape {
        \\    Circle(radius: i32),
        \\    Square(side: i32),
        \\
        \\    pub fn area(self: Self) -> i32 {
        \\        return case self {
        \\            Circle(r) -> r * r * 3;
        \\            Square(s) -> s * s;
        \\        };
        \\    }
        \\}
        \\
        \\pub fn main() {
        \\    print(Shape.Square(side: 4).area());
        \\    print(Shape.Circle(radius: 2).area());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: lambda ---- with parameter" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn apply(f: fn(x: i32) -> i32) -> i32 {
        \\    return f(10);
        \\}
    );
}

test "js: lambda ---- multi-statement body" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn process(f: fn(x: i32) -> i32) -> i32 {
        \\    return f(5);
        \\}
    );
}

test "js: lambda ---- standalone with params" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val add: fn(i32, i32) -> i32 = { x, y ->
        \\    x + y
        \\};
        \\val result = add(10, 20);
        \\fn main() {
        \\    print(result);
        \\}
        \\
        \\import {io.terminal.print} from "std";
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
        \\    val func: fn(string) -> string = {s ->
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
        \\type User(name: string)
        \\
        \\fn main() {
        \\    val u: ?User = User(name: "ana");
        \\    print(u?.name);
        \\}
        \\
        \\import {io.terminal.print} from "std";
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
        \\    print(delete("a", "b"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: iterator fromList yields array items" {
    // A `fn -> @Iterator<T>` generator: `for (xs) { x -> yield x; }`
    // must lower to a real `for…of` with native `yield` (not `.map()`).
    // Recursive delegation (the legacy `return <iter>` shortcut) is forbidden
    // by RI1 (§1I). A `@Iterator<T>` is infallible, so a plain fn iterates it
    // (decision 103); a fallible one needs a body that grants `try`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn fromList<T>(xs: Array<T>) -> Iterator<T> {
        \\    for (xs) { item ->
        \\        yield item;
        \\    };
        \\}
        \\
        \\fn toList<T>(iter: Iterator<T>) -> Array<T> {
        \\    var out = [];
        \\    for (iter) { item ->
        \\        out.push(item);
        \\    };
        \\    return out;
        \\}
        \\
        \\fn main() {
        \\    print(toList(fromList([1, 2, 3])).join(","));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: a tuple element's optional read by the nullish default" {
    // A `?T` flowing through a tuple element (`result._1`) keeps its type —
    // inference resolves the tuple-index type so `??` reads the optional
    // (decision 330). `== null` uses loose equality so an `undefined` none
    // (from `Array.at`) matches.
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
        \\    print(head ?? -1);
        \\    val empty = firstAndRest([]);
        \\    print(empty._1 == null);
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: array slice 2-arg lowers byte-identically across backends" {
    // 2-arg `xs.slice(start, end)` — beam-inline-prim-methods F4. Both args are
    // literal ints so they reduce to `simpleTerm`s; the BEAM emitter computes
    // `Start+1` and `End-Start` via `gc_bif` and dispatches `lists:sublist/3`
    // (`primArraySlice2`). commonJS keeps `xs.slice(start, end)`; erlang lowers
    // to `lists:sublist`. Verifies the BEAM register choreography survives
    // assembly + run via `erlc +from_asm`.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs = [1, 2, 3, 4, 5];
        \\    print(xs.slice(1, 4));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: array join lowers byte-identically across backends" {
    // `xs.join(sep)` — beam-inline-prim-methods F1. BEAM lowers via
    // `primJoin` → `lists:map(stringify_fun, xs)` + `lists:join(sep, _)`
    // + `iolist_to_binary/1`, with the per-element stringify fun shipped
    // via `ensureStringifyHelper` (`make_fun3` over `'-bp_stringify-'/1`,
    // dispatching `is_binary` / `is_integer` / `io_lib:format` arms).
    // commonJS keeps `xs.join(sep)`; erlang already lowers via the
    // `prim-op-annotation` template form.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    print([10, 20, 30].join(", "));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: array indexOf lowers byte-identically across backends" {
    // `xs.indexOf(item)` — beam-inline-prim-methods F2. BEAM lowers via
    // `primIndexOf` → recursive synth helper `'-bp_indexOf-'/3 (L, X, I)`
    // tail-recursing through `call_only`. Hit returns the running index
    // (0-based); miss returns `-1`. commonJS keeps the native
    // `xs.indexOf(item)`; erlang lowers via the prim-op annotation.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    print([1, 2, 3, 4].indexOf(3));
        \\    print([1, 2, 3].indexOf(99));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: array at lowers byte-identically across backends" {
    // `xs.at(i)` — beam-inline-prim-methods F3. BEAM lowers via `primAt`
    // → synth helper `'-bp_at-'/2 (L, I)` that owns the bounds check
    // (`is_ge` against 0 + `is_lt` against `erlang:length`) and either
    // tail-calls `lists:nth(I + 1, L)` on hit or returns the `undefined`
    // atom on miss. commonJS keeps the native `xs.at(i)`; erlang lowers
    // via the prim-op annotation. The `undefined` miss tag matches the
    // erlang backend's `@Option` none representation.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    print([10, 20].at(0));
        \\    print([10].at(5));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: interface associated fn namespace" {
    // An interface's associated functions (`default fn` with no `self`) emit as
    // a namespace object so `Interface.method(...)` resolves at runtime.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\behavior Pairish<A, B> {
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
        \\    print(Pairish.first(p));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: stdlib associated fn namespace injected" {
    // `Array`'s statics live in primitives.bp (not in the user program).
    // When one is used, codegen injects the behavior decl so the namespace
    // object is emitted at runtime.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    print(Array.range(0, 3).length);
        \\    print(Array.repeat("x", 2).join(","));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: array instance default-fn methods" {
    // `Array<T>` `default fn` instance methods (`prepend`, `fold`, `isEmpty`, …)
    // materialize as `Array.prototype.<m>` patches when used. `append` maps to
    // native `concat`; native `Array.prototype` methods are left to the engine.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs = [1, 2, 3];
        \\    print(xs.prepend(0).join(","));
        \\    print(xs.fold(0, { a, x -> a + x }));
        \\    print(xs.isEmpty());
        \\    print(xs.all({ x -> x > 0 }));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: array zip via @External.Node template" {
    // `Array.zip` is a non-`default fn` instance method with a template-form
    // `@External.Node` annotation (`$self.map((__x, __i) => [__x, ($0)[__i]])
    // .slice(0, Math.min(...))`). Validates that the template-instance-methods
    // dispatch path renders the `$self`/`$0` markers via the prototype patcher
    // without requiring a hand-rolled `lowerXxx` arm in commonJS.zig.
    //
    // The inference pass now marks the Array interface as used for any
    // template-form prim-method dispatch (not just default-fn) — see the
    // `looksLikeTemplate` branch in `findInterfaceDefaultFn` — so a program
    // calling ONLY `xs.zip(ys)` triggers the prototype-patch emission.
    //
    // Semantics decision 1a: the array of tuples prints
    // `[#(1, "a"), #(2, "b"), #(3, "c")]` on all four backends.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val xs = [1, 2, 3];
        \\    val ys = ["a", "b", "c"];
        \\    print(xs.zip(ys));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: bool instance default-fn methods" {
    // `Bool` `default fn`s materialize as `Boolean.prototype.<m>`. A boxed
    // primitive's `this` is a truthy wrapper, so the body unwraps via
    // `this.valueOf()` (`const self = this.valueOf()`).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    print(true.negate());
        \\    print(false.nor(false));
        \\    print(true.nand(true));
        \\    print(true.exclusiveOr(false));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

test "js: numeric instance methods (external + default-fn)" {
    // Numeric `#[@External.Node(…)]` methods backed by a JS global (`Math`) lower to
    // `Number.prototype.<m> = function(a){ return Math.<sym>(this.valueOf(), a); }`;
    // `default fn`s like `clamp`/`isEven` materialize and call them.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val n = -5;
        \\    print(n.abs());
        \\    print(n.min(3));
        \\    print(n.max(10));
        \\    print(n.clamp(0, 5));
        \\    val x = 7;
        \\    print(x.isEven());
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// `String.at -> ?string` (`charAt` until decision 63's amendment): native JS
// answers `undefined` out of range, so commonJS calls the
// `__bp_string_char_at` prelude helper, emitted only into the module that uses
// it. RUN LOG asserted without a snapshot (commonJS-only behaviour).
// `at` is the reader of BOTH `Array<T>` (native `at`) and `string` (native
// `charAt`) since decision 63's amendment. The type-naive `prim_node_renames`
// map used to take the string rename for every untyped `at` call, so the
// `Array` default-fn bodies materialised as prototype patches (`first`,
// `unique`: `self.at(0)`) emitted `this.charAt(0)` on an array and threw on
// node. A name two behaviors send to different host symbols has no type-naive
// rename; the typed call sites keep their per-loc one. RUN LOG asserted.
// The `"abcd".slice(1, 3)` line is the second route, `libs/std`'s own
// `querystring.bp`: once a String `default fn` is in use the program the
// emitter scans carries the String behavior alone, `at → charAt` looks
// unambiguous there, and a TYPED array receiver whose per-loc rename is
// "none" (`Array.at` is its own host symbol) fell through to the type-naive
// map — `parts.charAt is not a function`. The disagreement is therefore read
// off the whole embedded std registry, not the program's behaviors.
// `unique` itself is not run: its body calls `prev.unwrapOr(x)` on a `?T`
// that is an unboxed number on JS (`prev.unwrapOr is not a function`), a
// pre-existing defect of that default fn and not of the rename.
test "js: `at` on an array default fn and on a string do not share a rename" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    val xs = [3, 4];
        \\    print(xs.first() ?? 0);
        \\    print(xs.at(1) ?? 0);
        \\    print("abc".at(1) ?? "?");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "3\n4\nb\n");
}

// The second route, on its own: NO Array default fn in the program (the test
// above calls `first`, which materialises the Array behavior beside String's
// and lets the program-local disagreement mask this one). Only the registry-
// wide `ambiguous_prim_renames` keeps `ys.at(1)` from becoming `charAt` here.
test "js: a typed array `at` beside a String default fn in use keeps its name" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    print("abcd".slice(1, 3));
        \\    val ys: i32[] = [7, 8];
        \\    print(ys.at(1) ?? 0);
        \\    val parts = "a=1".split("=");
        \\    print(parts.at(0) ?? "");
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "bc\n8\na\n");
}

// Decision 139: a negative index counts from the end — `s.at(-1)` is the last
// character, and past either end (`2`, `-3`) is `null`.
test "js: string at out of range is null, a negative index counts from the end" {
    try h.assertJsRunLog(std.testing.allocator,
        \\fn main() {
        \\    val s = "ab";
        \\    print(s.at(1));
        \\    print(s.at(2));
        \\    print(s.at(-1));
        \\    print(s.at(-3));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , "b\nnull\nb\nnull\n");
}

test "js: string methods map to native JS names" {
    // `String` host-backed methods whose name differs from the native JS one are
    // mapped (`toUpper`→`toUpperCase`, `toLower`→`toLowerCase`); same-named ones
    // (`split`, `trim`, `slice`, `startsWith`) use the engine directly.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "Hello,World";
        \\    print(s.toUpper());
        \\    print(s.toLower());
        \\    print(s.split(",").join("|"));
        \\    print(s.slice(0, 5));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// `String.endsWith` is an `@External.Erlang` template (OTP has no
// `string:suffix/2`), which the beam target compiles at build time into a
// helper (decision 437: the one BEAM annotation); the snapshots pin the JS
// lowering and the beam helper.
test "beam template path: endsWith lowers via its @External.Erlang template" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val s = "foobar";
        \\    print(s.endsWith("bar"));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── enum-sections F4: cross-backend codegen ─────────────────────────────────
//
// F4 pins that an enum carrying sections emits byte-identically against the
// manually-written enum-of-enum form. The F1 desugar registers a synthesised
// inner enum per section under a mangled name (`__<Enum>__<SectionPath>`);
// F4 (`withSynthesisedEnumDecls` in `comptime.zig`) prepends each as a
// top-level AST decl so codegen emits them as ordinary enums. The parent
// enum's section wrappers (`Section(_inner: __Enum__Section)`) then resolve
// against the synthesised decls at codegen time. F2 path-access
// (`.Color.Red.500`) lowers to nested constructor calls that each backend
// emits via the standard variant ctor path.

test "js: enum sections ---- section emits as synthesised inner enum decl" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Token {
        \\    Text {
        \\        Bold, Italic, Underline,
        \\    }
        \\    Hover(inner: i32),
        \\}
    );
}

test "js: enum sections ---- nested sections with numeric leaves emit decls" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Token {
        \\    Color {
        \\        Red { 100, 500 }
        \\        Hex(value: string),
        \\    }
        \\}
    );
}

test "js: enum sections ---- path-access lowers to qualified ctor calls" {
    // F2 path-access (`.Color.Red.500`) rewrites at transform time to a
    // qualified-ctor chain `Token.Color(_inner: __Token__Color.Red(_inner:
    // __Token__Color__Red._500))` so codegen emits proper variant accesses
    // rather than the bare source-text fallback (`Color.Red.500`).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Token {
        \\    Color {
        \\        Red { 100, 500 }
        \\    }
        \\}
        \\fn red500() -> Token {
        \\    return .Color.Red.500;
        \\}
    );
}

// An imported enum's synthesised inner enums are re-synthesised in every module
// that writes the section path, and their values carry the OWNER's tags, so
// `'__bp_tagged'` formats them through the owner's `<owner>@@__Token__Color`
// module. Only the owner emits that type module: before, erlang and beam wrote
// one byte-identical copy per importing module (emilia's ~680 inner enums,
// six times over).
const imported_section_modules = [_]Module{
    .{ .path = "tok", .source =
    \\pub type Token {
    \\    Color {
    \\        Red, Blue,
    \\    }
    \\    Hover(inner: i32),
    \\}
    \\pub fn red() -> Token { return .Color.Red; }
    },
    .{ .path = "lib", .source =
    \\import {tok.Token};
    \\pub fn blue() -> Token { return .Color.Blue; }
    },
    .{ .path = "main", .source =
    \\import {tok.Token, tok.red};
    \\import {lib.blue};
    \\pub fn main() {
    \\    val t: Token = .Color.Red;
    \\    print(t);
    \\    print(red());
    \\    print(blue());
    \\}
    \\
    \\import {io.terminal.print} from "std";
    },
};

/// Every unit the program writes for `__Token__Color` is the owner's, once.
fn expectOneInnerEnumUnit(cfg: config.Config) !void {
    var outputs = try h.generate(std.testing.allocator, &imported_section_modules, std.testing.io, cfg);
    defer {
        for (outputs.items) |*o| o.result.deinit(std.testing.allocator);
        outputs.deinit(std.testing.allocator);
    }
    var inner: usize = 0;
    for (outputs.items) |o| for (o.result.units) |u| {
        if (std.mem.endsWith(u8, u.atom, "@@__Token__Color")) {
            inner += 1;
            try std.testing.expectEqualStrings("test@tok@@__Token__Color", u.atom);
        }
    };
    try std.testing.expectEqual(@as(usize, 1), inner);
}

test "erlang: enum sections ---- an imported enum's inner enum has one type module" {
    try expectOneInnerEnumUnit(h.configs[1]);
}

test "beam: enum sections ---- an imported enum's inner enum has one type module" {
    try expectOneInnerEnumUnit(h.configs[2]);
}

// A comptime body has no inferred types, so a primitive method call in it lowers
// to the runtime-dispatch shim `'__bp_prim_<method>'` (`codegen/erlang.zig`
// `untypedPrimCallNode`); the `COMPTIME ERLANG` section shows the call sites.
// The string receivers avoid `indexOf`, whose `string:str/2` host op rejects a
// binary (a `libs/std/src/primitives.bp` table defect, not a dispatch one).
// The comptime sections, the replies and the RUN LOG are identical on all four
// backends.
test "js: comptime primitives ---- template body calls string and array methods" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn shout(syntax q: string) -> string {
        \\    val t = compiler.text(q).trim();
        \\    val words = t.split(" ").map({ w -> w.toUpper() });
        \\    val lead = t.slice(0, 5);
        \\    val rest = t.slice(6, t.length);
        \\    val all = words.append(["END"]).reverse();
        \\    val at = if (words.at(1) == "BIG") { "at"; } else { "-"; };
        \\    val big = if (t.contains("big")) { "contains"; } else { "-"; };
        \\    val greet = if (lead.startsWith("hel")) { "startsWith"; } else { "-"; };
        \\    val where = if (words.indexOf("WORLD") == 2) { "indexOf"; } else { "-"; };
        \\    return compiler.build("\"" + all.join(",") + "|" + lead + "|" + rest + "|" + at + "|" + big + "|" + greet + "|" + where + "\"");
        \\}
        \\
        \\val s = shout @` hello big world `;
        \\
        \\fn main() {
        \\    print(s);
        \\}
        \\import {compiler} from "std";
        \\
        \\import {io.terminal.print} from "std";
    );
}

// The first decorator `COMPTIME ERLANG` section: the same shims from a decorator
// body, including `length()`, whose name is an auto-imported Erlang BIF. The
// wasm run log is empty (a wasm backend gap, not a comptime one).
test "js: comptime primitives ---- decorator body calls string and array methods" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn describe(syntax decl: unknown) {
        \\    val names = compiler.fields(decl).map({ f -> f.name });
        \\    val upper = names.map({ n -> n.toUpper() }).join("_");
        \\    val hidden = if (names.contains("secret")) { "hidden"; } else { "open"; };
        \\    val short = compiler.name(decl)!.slice(0, 3);
        \\    val size = if (compiler.name(decl)!.length() == 4) { "four"; } else { "other"; };
        \\    @emit("pub fn describe" + compiler.name(decl)! + "() -> string { return \"" + upper + ":" + hidden + ":" + short + ":" + size + "\"; }");
        \\}
        \\
        \\#[describe]
        \\type User(name: string, secret: string, age: i32)
        \\
        \\fn main() {
        \\    print(describeUser());
        \\}
        \\import {compiler} from "std";
        \\
        \\import {io.terminal.print} from "std";
    );
}

// `out.push(x)` mutates its receiver. On erlang the statement rebinds the local
// (`Out@2 = (Out@1 ++ [X])`) and a closure that pushes threads the list out
// through `lists:foldl` like an assignment does — in straight-line position, in
// a multi-statement `forEach` closure, and in a decorator body (a dependency-injection
// constructor shape: an inner mutating `forEach`, then the push).
// All four backends print the same RUN LOG.
test "js: receiver mutation ---- push inside a multi-statement closure threads out" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\pub fn component(syntax decl: unknown) {
        \\    var args: Array<string> = [];
        \\    compiler.fields(decl).forEach({ f ->
        \\        var valKey = "";
        \\        f.annotations.forEach({ a -> if (a.name == "value") { valKey = a.args.join(""); } });
        \\        val expr = if (valKey != "") {
        \\            "prop(" + valKey + ")";
        \\        } else {
        \\            "make" + f.typeName + "()";
        \\        };
        \\        args.push(f.name + ": " + expr);
        \\    });
        \\    @emit("pub fn wire" + compiler.name(decl)! + "() -> string { return \"" + compiler.name(decl)! + "(" + args.join(", ") + ")\"; }");
        \\}
        \\
        \\val port = "port";
        \\
        \\fn value(syntax decl: unknown, comptime key: string) { }
        \\
        \\#[component]
        \\type Service(
        \\    #[value(port)]
        \\    port: i32,
        \\    name: string,
        \\)
        \\
        \\fn collect(xs: Array<i32>) -> Array<string> {
        \\    var out: Array<string> = [];
        \\    out.push("start");
        \\    xs.forEach({ x ->
        \\        val doubled = x * 2;
        \\        out.push("v" + doubled.toString());
        \\    });
        \\    return out;
        \\}
        \\
        \\fn main() {
        \\    print(wireService());
        \\    print(collect([1, 2, 3]).join(","));
        \\}
        \\import {compiler} from "std";
        \\
        \\import {io.terminal.print} from "std";
    );
}

// ── the removed 1.0.2 surface (front 12 step 4) ──────────────────────────────
// `record`, `enum` and `interface` lex as identifiers; each removed form gets
// its targeted diagnostic, located at the removed word or brace.

test "js: removed surface ---- a record declaration" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\record Point { x: i32, y: i32 }
    );
}

test "js: removed surface ---- an enum declaration" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\enum Color { Red, Green }
    );
}

test "js: removed surface ---- an interface declaration" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\interface Printable {}
    );
}

test "js: removed surface ---- an anonymous record literal" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn main() {
        \\    val p = record { x: 1 };
        \\}
    );
}

test "js: removed surface ---- an anonymous record type" {
    try h.assertJsCompileError(std.testing.allocator, @src(),
        \\fn f(p: { x: i32 }) -> i32 {
        \\    return 1;
        \\}
    );
}

// B-51: JavaScript has one number type, so an `f64` only prints with its `.0`
// when the emitter knows the value is one. A call through an imported module's
// handle to a `pub fn` declared `-> f64` (`math.abs(0.0 - 1.0)`) is known from
// the owner's declared return type; without it `@print` wrote `1`.
test "js: print ---- an f64 answered by a module-handle call keeps its .0" {
    try h.assertJsContains(std.testing.allocator,
        \\import {math} from "std";
        \\
        \\fn main() {
        \\    print(math.abs(0.0 - 1.0));
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , &.{"__bp_print_as([\"f\"], math.abs("});
}

// B-51: an `f64` read out of a `case` arm's payload binding (`Circle(r) -> r`)
// is typed by the variant's declared field, so it prints `2.0`, not `2`.
test "js: print ---- an f64 out of a case payload binding keeps its .0" {
    try h.assertJsContains(std.testing.allocator,
        \\type Shape {
        \\    Circle(radius: f64),
        \\    Square(side: f64),
        \\}
        \\
        \\fn main() {
        \\    val s = Shape.Circle(radius: 2.0);
        \\    print(
        \\        case s {
        \\            Circle(r) -> r;
        \\            Square(side) -> side;
        \\        },
        \\    );
        \\}
        \\
        \\import {io.terminal.print} from "std";
    , &.{"__bp_print_as([\"f\"], "});
}
