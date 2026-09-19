//! codegen: extension dispatch (implement/interface/delegate) (split from tests.zig).

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

test "js: implement ---- attaches methods to prototype" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\behavior Printable {
        \\    fn print(self: Self);
        \\}
        \\type Person(name: string)
        \\val PersonPrintable = implement Printable for Person {
        \\    fn print(self: Self) {
        \\        return self.name;
        \\    }
        \\}
    );
}

test "js: dispatch ---- inherent record method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Contador(
        \\    n: i32) {
        \\    fn atual(self: Self) {
        \\        return self.n;
        \\    }
        \\}
        \\fn main() {
        \\    val c = Contador(5);
        \\    @print(c.atual());
        \\}
    );
}

test "js: dispatch ---- string contains lowers to native includes" {
    // `s.contains(x)` on a `string` has no `String.prototype.contains`; inference
    // records a type-directed rename so codegen emits `s.includes(x)`. A `record`
    // method of the same name (`Set.contains`) keeps its own dispatch — see the
    // inherent-record-method case above.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val hw = "hello world";
        \\    @print(hw.contains("world"));
        \\}
    );
}

test "js: dispatch ---- string startsWith lowers to native startsWith" {
    // `s.startsWith(p)` on a string is a host-native call on every backend —
    // JS keeps the literal `startsWith`, erlang/BEAM lower to `string:prefix/2`
    // with a `=/= nomatch` test (the `primCmpAgainstNomatch` shape in
    // `beam_asm.zig`).
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\fn main() {
        \\    val hw = "hello world";
        \\    @print(hw.startsWith("hello"));
        \\}
    );
}

test "js: dispatch ---- auto-applied extension method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\type Pato(id: i32)
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\fn main() {
        \\    val donald = Pato(2);
        \\    @print(donald.swim());
        \\}
    );
}

test "js: dispatch ---- qualified extension method call" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\type Pato(id: i32)
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\fn main() {
        \\    val donald = Pato(3);
        \\    @print(PatoNada.swim(donald));
        \\}
    );
}

test "js: dispatch ---- multi-module implement on an imported record" {
    // `Pato` crosses the module boundary; the interface and `implement` are local
    // to the consumer. The extension is auto-applied — `donald.swim()` lowers to
    // the local symbol with no activation statement.
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "pond", .source =
        \\pub type Pato(id: i32)
        },
        .{ .path = "", .source =
        \\import {Pato} from "pond";
        \\val Swimmer = behavior {
        \\    fn swim(self: Self);
        \\}
        \\val PatoNada = implement Swimmer for Pato {
        \\    fn swim(self: Self) {
        \\        return self.id;
        \\    }
        \\}
        \\fn main() {
        \\    val donald = Pato(2);
        \\    @print(donald.swim());
        \\}
        },
    });
}

test "js: dispatch ---- multi-module extension activated via star import" {
    // `pond` ships the `implement`; the consumer activates it with `PatoNada*` and
    // `donald.swim()` lowers to the imported symbol `PatoNada.swim(donald)`.
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
        \\import {Pato, PatoNada*} from "pond";
        \\fn main() {
        \\    val donald = Pato(2);
        \\    @print(donald.swim());
        \\}
        },
    });
}

// The three shapes a method call reaches a type from ANOTHER module through, in
// one module pair — the siblings of the row `448b935` landed (a method whose
// owning type came from another module is a remote call, not a `call_fun` on the
// receiver's map). All three print on beam, each through a different resolution
// path in `beam_asm.zig`:
//
//   * a method on an imported **enum** — `Shape.Square(side: 4).area()` →
//     `{call_ext, 1, {extfunc, geometry, 'Shape_area', 1}}` (the link index's
//     `kind == .enum` arm of `methodOwnerModule`);
//   * a method on the value an imported **associated fn** answers —
//     `val c: Counter = Counter.zero(); c.bump()` → `'Counter_zero'/0` remotely,
//     then `'Counter_bump'/1` remotely;
//   * a method on the value an imported plain `fn` answers — `make().bump()`,
//     the shape `tests/language/modules/two_modules` runs.
//
// Verified by hand on a real project (`botopink build --target beam`, then
// `erlc +from_asm out/*.S`, then `erl -noshell -pa . -eval
// "main:'_botopink_main'(), halt()."`): `1`, `16`, `42` — what commonJS prints.
//
// FIXED on erlang (`02-erlang`, the enum half of `7783fd6` and `1193d3c`). It
// was a bare LOCAL call — `main.erl` held `area({'Square', 4})` while
// `geometry.erl` exports `area/1`, so the emitted program did not compile
// (`out/main.erl:11:19: function area/1 undefined`) while the two record cases
// beside it were already right (`geometry:bump(C)`). `typedMethodNode` read
// `imported_types`, which the `import { … }` **enum** arm never writes (it
// registers the variants, because a tagged tuple is module-independent), and it
// had no link-index fallback at all — so the erlang side was missing the `enum`
// kind *and* the `info.methods` membership test. `methodOwnerModule` now mirrors
// `beam_asm.zig`'s (`448b935`) over both sources, and `main.erl` calls
// `geometry:area/1`; the RUN LOG is `1`, `16`, `42` — what commonJS and beam
// print.
// KNOWN-WRONG (wasm): wasm stays single-module and has no named-type identity,
// so the imported enum's `case self` traps (`unreachable`); the two record
// shapes print.
//
// NOT pinned here, because it fails on beam and wasm both and the row is the
// CHECKER's: the same associated fn WITHOUT the type annotation —
// `Counter.zero().bump()`, or `val c = Counter.zero()` — reaches beam as
// `{unresolved_method, bump, 1}` and wasm as a trap, because
// `env.instanceLowerings` carries no entry for the call: the checker gives
// `Type.assoc()` no return type, so the receiver's type is a fresh var and
// `recordInstanceCall` never runs. It reproduces inside ONE module, so it is not
// about imports at all, and the two dynamic-dispatch backends cannot see it
// (commonJS dispatches at run time; erlang names a record method flatly, so it
// needs no type either).
test "js: dispatch ---- a method on an imported enum, an imported associated fn and an imported fn" {
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{ .path = "geometry", .source =
        \\pub type Counter(n: i32) {
        \\    pub fn zero() -> Self { return Counter(n: 0); }
        \\    pub fn bump(self: Self) -> i32 { return self.n + 1; }
        \\}
        \\
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
        \\pub fn make() -> Counter { return Counter(n: 41); }
        },
        .{ .path = "", .source =
        \\import {Counter, Shape, make} from "geometry";
        \\fn main() {
        \\    val c: Counter = Counter.zero();
        \\    @print(c.bump());
        \\    @print(Shape.Square(side: 4).area());
        \\    @print(make().bump());
        \\}
        },
    });
}

// A user interface's instance `default fn` calling other members, reached
// through a record that implements it. commonJS emitted `Bounded.prototype.clamp
// = …` for an interface that is no JS constructor (`Bounded is not defined` at
// load); the default is now a method of the implementing class. erlang emits it
// beside the record's own methods (`clamp(Self, Lo, Hi) -> min(max(Self, Lo),
// Hi).`) and prints the same `120`. KNOWN: beam aborts
// `{unresolved_method, clamp, 3}` (empty RUN LOG) and wasm traps — neither
// reaches a user interface's default through a record yet (1.0.4-beta 01).
test "js: interface ---- a default fn calls members of the implementing record" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\behavior Bounded {
        \\    fn min(self: Self, other: Self) -> Self;
        \\    fn max(self: Self, other: Self) -> Self;
        \\
        \\    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        \\        return self.max(lo).min(hi);
        \\    }
        \\}
        \\
        \\type Money(
        \\    cents: i32,
        \\) implement Bounded {
        \\    fn min(self: Self, other: Self) -> Self {
        \\        return if (self.cents < other.cents) { self; } else { other; };
        \\    }
        \\
        \\    fn max(self: Self, other: Self) -> Self {
        \\        return if (self.cents > other.cents) { self; } else { other; };
        \\    }
        \\}
        \\
        \\fn main() {
        \\    val m = Money(cents: 500).clamp(Money(cents: 0), Money(cents: 120));
        \\    @print(m.cents);
        \\}
    );
}

// The generic half of the same row (front 15's `test/generic_behavior.bp`): a
// generic record adopts a behavior through an `extends` chain and defines only
// the abstract member. Both defaults are the record's own functions, and
// `self.size()` inside them reaches `size/1`, so `Bag(items: []).isEmpty()` is
// `true` on every backend that runs the program. KNOWN: beam and wasm do not
// reach a record's adopted default (same 1.0.4-beta 01 row as the test above);
// beam's RUN LOG is empty and wasm's is the trap.
test "js: interface ---- a generic record adopts defaults through an extends chain" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\behavior Sized {
        \\    fn size(self: Self) -> i32;
        \\
        \\    default fn isEmpty(self: Self) -> bool {
        \\        return self.size() == 0;
        \\    }
        \\}
        \\
        \\behavior Counted extends Sized {
        \\    default fn twiceSize(self: Self) -> i32 {
        \\        return self.size() * 2;
        \\    }
        \\}
        \\
        \\type Bag<T>(
        \\    items: Array<T>,
        \\) implement Counted {
        \\    pub fn size(self: Self) -> i32 {
        \\        return self.items.length;
        \\    }
        \\}
        \\
        \\fn main() {
        \\    @print(Bag(items: []).isEmpty());
        \\    @print(Bag(items: [1]).isEmpty());
        \\    @print(Bag(items: [1, 2]).twiceSize());
        \\}
    );
}

// 1.0.4-beta EXAMPLES.md §9's shape: a module redeclares the primitive
// `interface Number` with bodyless `min`/`max` and a `default fn` calling them.
// The redeclaration replaces the prelude's, annotations included; commonJS
// took the host binding (`Math.max`) from the std prelude's declaration of the
// same member, so `self.max(lo)` is not `self.max is not a function`.
test "js: interface ---- a redeclared primitive interface keeps its host members" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\behavior Number {
        \\    fn min(self: Self, other: Self) -> Self;
        \\    fn max(self: Self, other: Self) -> Self;
        \\
        \\    default fn clamp(self: Self, lo: Self, hi: Self) -> Self {
        \\        return self.max(lo).min(hi);
        \\    }
        \\}
        \\
        \\fn main() {
        \\    val n: i32 = 50;
        \\    @print(n.clamp(0, 10));
        \\}
    );
}

test "js: delegate ---- emits comment" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

test "js: interface ---- emits comment" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\val Drawable = behavior {
        \\    val color: string;
        \\    fn draw(self: Self);
        \\}
    );
}

test "js: delegate ---- declaration" {
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\declare fn Callback(msg: string) -> void;
    );
}

// ── imported calls and fn-typed fields (erlang C1/C2) ─────────────────────────

test "js: import ---- a call to an imported fn names its module" {
    // erlang resolves a bare call in the CALLING module, so `twice(X)` from
    // `b` was `function twice/1 undefined`; it must reach the owner (`a:twice`).
    // The owner exports what another module consumes.
    try h.assertJs(std.testing.allocator, @src(), &.{
        .{
            .path = "a",
            .source =
            \\pub fn twice(x: i32) -> i32 {
            \\    return x * 2;
            \\}
            ,
        },
        .{
            .path = "b",
            .source =
            \\import { twice };
            \\
            \\pub fn quad(x: i32) -> i32 {
            \\    return twice(twice(x));
            \\}
            \\
            \\pub fn main() {
            \\    @print(quad(3));
            \\}
            ,
        },
    });
}

test "js: import ---- the shorthand resolves a sibling inside a dependency" {
    // 1.0.5-beta decision 3: `import { … };` names no module and used to emit
    // the literal word — `require("./module")` at the project root and
    // `require("../module")` one level down, neither of which exists, which is
    // what made two of the shipped examples build and then die at run time. A
    // module under a package prefix (`web/api`) reaches its sibling back through
    // the output root, so the path is `../web/shapes.js`. The project-root half
    // of the row is pinned with a RUN LOG by `import ---- a call to an imported
    // fn names its module`, whose log was empty until this landed.
    //
    // Needles, not a snapshot: the consumer's own module is the only one
    // `assertConsumerJs` reads, and a four-backend snapshot would record
    // erlang, beam and wasm baselines this front does not own.
    try h.assertConsumerJs(
        std.testing.allocator,
        &.{
            .{
                .path = "web/shapes",
                .source =
                \\pub fn mk(v: i32) -> i32 {
                \\    return v;
                \\}
                ,
            },
            .{
                .path = "web/api",
                .source =
                \\import { mk };
                \\
                \\pub fn serve() -> i32 {
                \\    return mk(7);
                \\}
                ,
            },
        },
        &.{"require(\"../web/shapes.js\")"},
        &.{"require(\"../module\")"},
    );
}

test "js: record ---- a field of function type is called like a method" {
    // `c.set(9)` on a record whose `set` field holds a lambda: the record emits
    // no `set/2`, so the call applies what the field holds. erlang read the map
    // field (`set(C, 9)` → `function set/2 undefined`) before this.
    try h.assertJsSingle(std.testing.allocator, @src(),
        \\type Cell(
        \\    value: i32,
        \\    set: fn(next: i32) -> i32,
        \\)
        \\
        \\fn mk(v: i32) -> Cell {
        \\    return Cell(value: v, set: { next -> next + v });
        \\}
        \\
        \\pub fn main() {
        \\    val c = mk(5);
        \\    @print(c.value);
        \\    @print(c.set(9));
        \\}
    );
}
