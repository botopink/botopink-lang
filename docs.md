# Botopink language reference

This reference describes the language as the compiler accepts it today. Every
`botopink` fence here is compiled by `zig build test-docs`; a fence that is not a
module (an operator table, a layout sample) says so in a `docs-check` comment.

## Syntax changes

A type is declared with `type` and a contract with `behavior`; `record`, `enum`
and `interface` are gone, and so are `auto`, `derive`, `get`, `macro`,
`opaque`, `private`, `set`, `new` and `delegate` — all of them are ordinary
identifiers now. An anonymous group of values is a tuple, `#(…)`, which
replaces the old anonymous record. Repetition is three keywords with one meaning
each — `for (xs) { x -> … }`, `while (cond) { … }`, `loop { … }` — and `loop (…)`
reports an error naming `for` and `while`. A host template numbers its parameters
positionally (`$0`, `$1`, …). A function's effect is its return type — `@Result`,
`@Task`, `@Component`, `@Iterator`, `@Stream` — and the effect annotations are gone
(decisions 118–128; *Migrating from the effect annotations*).

The move from the previous surface, declaration by declaration, is in
[`MIGRATION.md`](https://github.com/botopink/projects/blob/feat/specs/1.0.4-beta/MIGRATION.md).

## Program structure

A Botopink program is a sequence of declarations — bindings, functions, types,
imports, and module declarations. Execution starts at `fn main()`.

```botopink
// hello.bp
fn main() {
    @print("hello, botopink");
}
```

### Modules

Projects use an explicit, Rust-style module tree. The root module (`main.bp`
for a binary, `root.bp` for a library) declares which submodules to include;
the compiler follows these declarations instead of compiling every `.bp` it
finds.

<!-- docs-check: project modules src/main.bp -->
```botopink
// src/main.bp
import {area} from "geometry";
import {describe} from "shapes";

pub mod geometry;    // resolves src/geometry.bp
pub mod shapes;      // resolves src/shapes/mod.bp

fn main() {
    @print(area(3, 4));    // 12
    @print(describe());    // circle
}
```

<!-- docs-check: project modules src/geometry.bp -->
```botopink
// src/geometry.bp
pub fn area(w: i32, h: i32) -> i32 {
    return w * h;
}
```

<!-- docs-check: project modules src/shapes/mod.bp -->
```botopink
// src/shapes/mod.bp
pub fn describe() -> string {
    return "circle";
}
```

Leaf modules are single files; folder modules use a `mod.bp` entry point.
`pub mod` is visible through the parent; a plain `mod` is private to its
declaring module's subtree. Only `pub` declarations are visible outside their
module.

### Imports

An import either names the module it reads from, or names nothing and resolves
the sibling module that exports the names. Both forms are the language.

<!-- docs-check: project imports src/main.bp -->
```botopink
// src/main.bp
import {math} from "std";              // a stdlib module
import {area} from "geometry";         // a module of this package, named
import {name} from "shapes.circle";    // a nested module path
import {perimeter};                    // the shorthand — the sibling that exports it

pub mod geometry;
pub mod shapes;

fn main() {
    @print(area(3, 4));             // 12
    @print(name());                 // circle
    @print(perimeter(3, 4));        // 14
    @print(math.abs(0.0 - 1.0));    // 1
}
```

<!-- docs-check: project imports src/geometry.bp -->
```botopink
// src/geometry.bp
pub fn area(w: i32, h: i32) -> i32 {
    return w * h;
}

pub fn perimeter(w: i32, h: i32) -> i32 {
    return (w + h) * 2;
}
```

<!-- docs-check: project imports src/shapes/mod.bp -->
```botopink
// src/shapes/mod.bp
pub mod circle;
```

<!-- docs-check: project imports src/shapes/circle.bp -->
```botopink
// src/shapes/circle.bp
pub fn name() -> string {
    return "circle";
}
```

**A path and a group are one tree, and only the leaf enters scope.** An item
may walk into a module (`shapes.circle.name`), and several items under one
prefix may be grouped (`shapes: {circle: {name}, helpers: {seven}}`) — both
spellings bind exactly the same names: `a: {b: {c}}` is `a.b.c`. The dot serves
one leaf, the braces several under one prefix; there is no formatter rule that
converts one into the other. What an item binds is its **leaf** — `name`,
`seven` — never the segments before it: `import {io.fs.readText}` brings
`readText`, neither `io` nor `fs`; whoever wants both writes both
(`import {io, io.fs.readText}`). An intermediate node may itself be a leaf
(`import {io.fs}` binds the module `fs` as a namespace; inside a group the
prefix is a leaf if listed: `io: {fs, fs: {readText}}`). `*` and `as` belong
to the leaf in either spelling — `io: {fs: {readText as read}}` is
`io.fs.readText as read`, `collections: {ArraySets*}` activates the same
extension as `collections.ArraySets*` — and on a node that opens braces they
are a syntax error (`import-group-modifier`). Two items binding one name are
`import-name-collision` at the second item (`import {url.parse, json.parse}`);
an alias on either side clears it (`url.parse as parseUrl, json: {parse as
parseJson}`). An alias reaches a type and a type alias too (decision 110):
`import {collections.Dict as D}` brings `D`, a name for `Dict` in the program's
own text — the emitted code keeps `Dict`. An activation cannot be renamed
(`import-alias-on-activation`). A leaf that names a folder is a namespace of
its submodules (decision 110): after `import {io} from "std"`, `io.fs.readText(p)`
calls `io/fs`'s `readText` — only the modules the program reaches are imported —
and a module namespace reaches its types, so `import {collections} from "std"`
allows `collections.Dict.empty()` beside `collections.lt()` (decision 111's
constructors are type-scoped).

<!-- docs-check: project import_tree src/main.bp -->
```botopink
// src/main.bp
pub mod shapes;
import {shapes.circle.name as circleName, shapes: {helpers: {seven}}};
import {collections.Dict, collections: {gt, reverse, toInt as rank}} from "std";

fn main() {
    @print(circleName());                  // circle
    @print(seven());                       // 7
    val d: Dict<string, i32> = Dict.empty();
    @print(d.insert("a", 1).size());       // 1
    @print(rank(reverse(gt())));           // -1
}
```

<!-- docs-check: project import_tree src/shapes/mod.bp -->
```botopink
// src/shapes/mod.bp
pub mod circle;
pub mod helpers;
```

<!-- docs-check: project import_tree src/shapes/circle.bp -->
```botopink
// src/shapes/circle.bp
pub fn name() -> string {
    return "circle";
}
```

<!-- docs-check: project import_tree src/shapes/helpers.bp -->
```botopink
// src/shapes/helpers.bp
pub fn seven() -> i32 {
    return 7;
}
```

**The root of std is pure.** One criterion sorts the standard library:
`io/` is everything that talks to the world outside the process — disk,
network, clock, entropy, the environment — and a module at the root of std
is pure by definition: same input, same output. The compiler holds the root
to it: a std module at the root that imports anything under `io` (bare, or
`from "std"`, in either spelling) is `std-root-imports-io`, located at the
item, with no flag to turn it off. `io/` may import from the root, and
`testing/` (the harness) from both. Outside std the rule is not checked:
`io.` on an import line is a reading signal — `grep 'io\.'` lists what a
module touches outside the process — not a guarantee, since a `declare fn`
does what it wants.

| Where | Modules |
|---|---|
| the root (pure) | `collections` (`Dict`, `Set`, `Queue`, `Order` — a constructor is called on its type: `Dict.empty()`, `Set.fromList(xs)`), `math`, `path`, `url`, `querystring`, `json`, `regex`, `unicode`, `string_builder`, `encoding`, `hash`, `escape`, `async`; `erlang` and `beam` (the target's surface) |
| `io` | `io.fs`, `io.http`, `io.net`, `io.clock`, `io.random`, `io.os`, `io.env`, `io.process` |
| `testing` | `testing.asserts`, `testing.snapshots`, `testing.mocks` |

```botopink
import {collections: {Dict, Set}, io: {fs, clock}, testing.asserts} from "std";
```

A library is imported the same way, under the name `botopink.json` declares it
in `dependencies`:

<!-- docs-check: skip a library dependency needs that library declared in `dependencies`; the docs harness builds a scratch project with none -->
```botopink
import {of, erika} from "erika";   // a library dependency
```

**Bundled packages.** `std` is not the only package the compiler ships. The
libraries both halves of an application run — `routing` (the route matcher,
the route-table / `k` / `z` / URL-rule wires, the `nav:` navigation signals,
the `:param` grammar), `actions` (the server-action protocol) and `validation`
(constraints, `#[validated]`, the violation report) — are bundled with it and
imported by name exactly as `std` is, with no `dependencies` entry:

<!-- docs-check: skip the docs harness has no page or route table to match against -->
```botopink
import {match.matchPath, table.parseTable} from "routing";
import {envelope.writeEnvelope} from "actions";
import {decorators.validated} from "validation";
```

A bundled library is `.bp` source only (target-native code is an inline
`#[@External.…]` template, never a sidecar file), imports `std` and other
bundled packages and nothing else, and runs on erlang and commonJS. The copy
inside the compiler is the one a program gets — never a directory of the same
name on disk — and listing a bundled name in `dependencies` is refused where it
is written.

A `from` that names neither a module of this package, nor a declared
dependency, nor a bundled package is an error — it is reported where it is
written, rather than binding nothing in silence.

## Bindings

### val — immutable binding

```botopink
val x = 42;
val greeting = "hello";
```

Types are inferred via Hindley-Milner unification. Explicit annotations are
optional:

```botopink
val count: i32 = 42;
val names: string[] = ["alice", "bob"];
```

A `val` at module level is part of the **module body**: it is evaluated **once**,
in declaration order, when the module loads — before `main` runs and before the
first `test {}` block. Reading the name afterwards does not evaluate it again,
and a `_`-named statement, which nothing reads, runs just the same. So a module
whose initialisers have effects registers itself by being loaded:

```botopink
fn register(name: string) -> i32 {
    @print(name);
    return 1;
}

val _registered = register("Greeter");   // runs at module load, once
val port = 8000 + 80;                    // read as many times as you like

fn main() {
    @print(port);
}
```

`botopink test` and `botopink build` agree on this: the module body runs in both,
at the same point relative to the program's own code. A backend that cannot run
it is a gap in that backend, not a different meaning of `val`.

A `pub val` is imported like a `pub fn` — `import {port} from "config";` — and
may hold any type: a record, an enum, an array, a primitive, a function. The
bodies of the modules a program imports run before its own, dependencies first,
each once.

### var — mutable binding

<!-- docs-check: body -->
```botopink
var n = 0;
n = n + 1;
```

### fn — function

```botopink
fn add(x: i32, y: i32) -> i32 {
    return x + y;
}
```

A value leaves a function through `return`: a block is a statement, not a value, so a `fn` whose
return type has a value must end every path with `return` (or `@panic` / `@todo`) —
`fn f() -> i32 { val x = 1; }` is refused at `-> i32`.

## Types

### Primitives

`i32`, `i64`, `u32`, `u64`, `f32`, `f64`, `string`, `bool`, `void`.
Their methods are declared in `libs/std/src/primitives.bp`.

### type — records

A `type` whose fields are written in parentheses is a record: the declaration
mirrors construction.

```botopink
type Point(x: i32, y: i32)

val p = Point(x: 1, y: 2);
val px = p.x;
```

A body adds methods:

```botopink
type Counter(n: i32) {
    fn current(self: Self) -> i32 {
        return self.n;
    }
}
```

The field list is always written. A record with no fields is `type Name()`,
and with members `type Name() { … }`; braces alone declare an enum, so
`type Name {}` or `type Name { fn … }` is `type-without-field-list`, refused
where the `()` belongs:

```botopink
pub type RequestBase()

type MathOps() {
    fn double(self: Self, x: i32) -> i32 {
        return x * 2;
    }
}
```

An anonymous group of values is a tuple, not a type declaration. A tuple is
positional at run time; a label is a compile-time name, lent by the variable
used to build it or written in the type:

```botopink
fn box() -> #(value: i32) {
    val value = 1;
    return #(value);    // the variable lends the label
}

fn read() -> i32 {
    val inner = box();
    return inner.value;    // same element as inner.0
}
```

### type — enums

A `type` whose body lists variants is an enum:

```botopink
type Color { Red, Green, Blue }

type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

fn main() {
    val c = Color.Red;
    val s = Shape.Circle(radius: 2.0);
    @print(case c { Red -> "red"; _ -> "other"; });
    @print(case s { Circle(r) -> r; Square(side) -> side; });    // 2
}
```

A variant is built through its type — `Color.Red`, `Shape.Circle(radius: 2.0)`;
inside a `case` pattern the bare name is enough. A bare `Red` in expression
position type-checks but no backend lowers it (the generated program reports an
unbound `Red` at run time), so always write the qualified form.

#### Sections of an enum

An enum's body may group variants into **sections**, and a section may nest.
A section is itself a type (`Token.Color`), and a leaf is reached by its path:

```botopink
type Token {
    Color {
        Red { 100, 500 }
        Gray { 100, 500 }
    }
    Bold,
}

fn main() {
    val t: Token = .Color.Red.500;
    @print(case t { Color(_inner) -> "a colour"; Bold -> "bold"; });
}
```

**Which enum a leading-dot path names is decided by the type the position
expects.** More than one enum can carry the same path, so the answer is read
from the position the path is written in — a `val`'s annotation, a declared
parameter, the function's return type, the element type of an array literal:

```botopink
type Token  { Color { Red { 100, 500 } } }
type Border { Color { Red { 100, 500 } } }

fn onToken(t: Token) -> string { return "token"; }

fn main() {
    val a: Token = .Color.Red.500;      // Token
    val b: Border = .Color.Red.500;     // Border
    @print(onToken(.Color.Red.100));    // Token — the parameter says so
}
```

A position that expects nothing (`val x = .Color.Red.500;`) leaves the path
carried by two enums with nothing to choose between them, and the compiler
refuses rather than pick one, naming both candidates:

```
error: the path ".Color.Red.500" is carried by more than one enum —
       "Border" and "Token" — and nothing here says which
```

Give the position a type and it resolves — or write the path from its enum,
which names the answer in the path itself and needs no type around it:

```botopink
type Token  { Color { Red { 100, 500 } } }
type Border { Color { Red { 100, 500 } } }

fn main() {
    val a = Token.Color.Red.500;     // Token
    val b = Border.Color.Red.500;    // Border
}
```

### behavior

```botopink
behavior Printable {
    fn print(self: Self);
}

type Person(name: string) implement Printable {
    fn print(self: Self) {
        @print(self.name);
    }
}
```

A behavior is a type: a parameter, a return, a constructor field, an annotated
`val` or a `var` typed by it takes any type that implements it, and a call on it
dispatches to that type's method — the value's own, whatever other type declares
a method of the same name. An imported behavior is the same type it is in its
own module, and so is every name an imported type alias mentions.

```botopink
behavior Greeter {
    fn greet(self: Self) -> string;
}

type Bob(name: string) implement Greeter {
    fn greet(self: Self) -> string {
        return "hi " + self.name;
    }
}

fn welcome(g: Greeter) -> string {
    return g.greet();
}

fn main() {
    @print(welcome(Bob(name: "bob")));
}
```

A `behavior` no type in the program implements is a **runtime boundary**: the
host builds the value. Such a value carries its own members — a `val` member is
read off it, and a method is found on it the same way and applied to the
receiver and the arguments. That is what lets a host hand a program a request,
a connection or a handle without the program naming a concrete type.

### Generics

```botopink
fn identity<T>(x: T) -> T { return x; }

type Tree<T> {
    Leaf(value: T),
    Node(left: Tree<T>, right: Tree<T>),
}
```

Built-in generic types carry an `@` prefix: `@Result<D, E>`, `@Task<T>`,
`@Iterator<T>`, `@Expr<T>`. Optionals are `?T`; tuples are `#(A, B)`.

A written generic type carries all of its type arguments — `fn get(b: Box)` for a
`type Box<T>` is `error: Box needs 1 type argument`, and `Pair<i32>` for a
`Pair<A, B>` names both counts. Inside a declaration with type parameters `Self`
carries them too: `Self<T>`, and `Self<U>` for the same type over another
argument. A declaration without type parameters writes `Self`, and so does a
non-generic type implementing a generic behavior — the behavior's `Self<…>` is
that type:

```botopink
type Box<T>(value: T) {
    pub fn get(self: Self<T>) -> T { return self.value; }
    pub fn map<U>(self: Self<T>, f: fn(x: T) -> U) -> Self<U> { return Box(value: f(self.value)); }
}

fn main() {
    val b: Box<string> = Box(value: 1).map({ x -> "one" });
    @print(b.get());
}
```

### Type aliases

```botopink
type ParseError { Empty, Bad(text: string) }
type Id = i32;
type Pair<A, B> = #(A, B);
pub type Parser<T> = @Result<T, ParseError>;

fn swap(p: Pair<Id, string>) -> Pair<string, Id> { return #(p.1, p.0); }
```

`type Name<A, B> = Target;` gives an existing type another name. The alias is
**transparent**: wherever it is written — a parameter, a return, a field, a
`val` annotation — the checker reads the target with the arguments substituted,
so `Id` and `i32` are the same type and a mismatch against one is a mismatch
against the other. Nothing of the alias reaches the emitted program.

- The `;` is required, and the declaration takes no annotation
  (`type-alias-annotated`) and no parameter default (`type-alias-generic-default`).
- An alias is written with exactly the arguments it declares — `Pair<i32, i32>`,
  never a bare `Pair` (`type-alias-arity`).
- An alias names a type that already exists; one whose expansion reaches itself
  is `type-alias-recursive` (a recursive type is a `type` declaration), and one
  that takes the name of a type in scope is `type-alias-name-taken`.
- A `pub` alias is imported like a type (`import {Parser} from "parse"`); the
  types its target names come with it.
- An alias of an effect wrapper **types** a function and never **activates** the
  effect (decision 118): `-> Parser<i32>` is a function that hands a
  `@Result<i32, ParseError>` value along, and the capabilities (`throw`, `try`,
  `await`, …) are granted only by the wrapper written literally in the return.

### Union types, `unknown`, and `is`

A union type is written `A | B`. `unknown` holds any value and, unlike a union,
cannot be used as another type until it has been tested — `val b: i32 = a;` on an
`unknown` reports "an `unknown` value cannot be used as another type without
testing it". `x is <Type>` answers a `bool` and narrows `x` inside the branch it
guards.

```botopink
fn describe(x: i32 | string) -> string {
    if (x is i32) {
        return "an integer";
    }
    return "a string";
}

fn read(raw: unknown) -> string {
    if (raw is string) {
        return raw;
    }
    return "not a string";
}
```

`is` tests a type; it does not bind. Read a variant's payload in a `case` arm
(`Circle(radius) -> …`, below) and an optional with `if (x) { n -> … }`;
`assert x is Some(v)` is a located error.

### Narrowing

A test that proves something about a **name** rebinds that name for the code the
test guards. Narrowing is a rebinding, so only a plain name narrows: there is
nothing to rebind for `o.inner` or `f().x`, and those stay whatever they were.

These shapes narrow:

| Shape | Where the name is narrowed |
|---|---|
| `if (x is T) { … }` | the branch |
| `if (guard(x)) { … }`, for a `fn guard(x: …) -> x is T` | the branch |
| `if (x != null) { … }` — and `null != x` | the branch, to the `?T`'s payload |
| `if (x == null) { … } else { … }` | the `else` branch |
| `if (x == null) { return …; }` — a guard clause | the REST of the block, for a `val` |
| `if (a != null && b != null)` | both names, in the branch |
| `if (a == null \|\| b == null) { return …; }` | both names, below the guard |
| `if (x) { v -> … }` | `v` is the payload; `x` itself is untouched |
| `case x { null { … } v { … } }` | `v` is the payload |

```botopink
type Entry(key: string) {}

fn firstKeyLength(entries: Entry[]) -> i32 {
    val first = entries.at(0);
    if (first == null) { return 0; }
    return first.key.length();     // `first` is an `Entry` here, not a `?Entry`
}

pub fn main() {
    @print(firstKeyLength([Entry(key: "abc")]));
}
```

Three shapes do **not** narrow, and each for its own reason:

* `if (x)` on a `?T` with no binder is refused — "type mismatch: expected bool,
  got ?string". There is no truthiness on an optional; write `if (x) { v -> … }`
  or `if (x != null)`.
* `while (x != null) { … }` leaves its body alone. A condition loop reassigns the
  name it tests, and a narrowed name could not be assigned the optional again.
* A guard clause narrows a `val` and not a `var`, for the same reason: a `var`
  can be assigned below the guard.

## Expressions

### Literals

<!-- docs-check: skip a table of literal forms, not a module -->
```botopink
42             // i32
3.14           // f64
"hello"        // string
"hi ${name}!"  // string interpolation
true, false    // bool
```

### Arrays

<!-- docs-check: body -->
```botopink
val xs = [1, 2, 3];
val tail = xs.slice(1, xs.length);    // [2, 3]
val back = xs.reverse();              // [3, 2, 1] — and xs is still [1, 2, 3]
```

An array method **answers a value and leaves its receiver alone**, on every
target: `reverse`, `slice`, `map` and `filter` all hand back a new array.

### Indexing and slicing

**An index is a method call.** `xs[k]` *is* `xs.at(k)`, `xs[a..b]` *is*
`xs.slice(a, b)`, and an open end passes `null` — `xs[1..]` *is*
`xs.slice(1, null)`, because `start..end` is a form and not a value, so there is
nothing else to hand the method. The index expression has **no typing rule of
its own**: its type is whatever the method answers, which for `at` is `?T`.

<!-- docs-check: body -->
```botopink
val xs = [10, 20, 30];
val first: ?i32 = xs[0];         // xs.at(0)
val none: ?i32 = xs[9];          // null — absent has one spelling
val last: ?i32 = xs[-1];         // 30 — a negative index counts from the end
val gone: ?i32 = xs.at(-4);      // null — past the front is absent too
val tail: i32[] = xs[1..];       // xs.slice(1, null)
val head: i32[] = xs[0..2];      // xs.slice(0, 2)
val s = "hello";
val c: ?string = s[1];           // "e"
val o: ?string = s.at(-1);       // "o"
```

A **negative index counts from the end**, on every backend: `xs.at(-1)` is the
last element and `xs.at(-xs.length)` the first; an index past either end
(`xs.at(xs.length)`, `xs.at(-xs.length - 1)`) is the absent `?T`. `Array.at`
and `String.at` — and so `xs[i]` and `s[i]` — read the same way. `Dict.at` is
by key and has no position to count from.

Which methods those are comes from two **ambient** behaviors — ambient like
`Display`, so the syntax finds them with nothing imported:

<!-- docs-check: skip the two behaviors as libs/std declares them, not a module -->
```botopink
pub behavior Index<K, V> { fn at(self: Self<K, V>, key: K) -> ?V; }
pub behavior Slice<V>    { fn slice(self: Self<V>, start: i32, end: ?i32) -> V; }
```

So indexing is not a privilege of the three built-in collections. `Array<T>`
answers `Index<i32, T>` and `Slice<T[]>`, `string` answers `Index<i32, string>`
and `Slice<string>`, `Dict<K, V>` answers `Index<K, V>` — and **your own type
becomes indexable by answering them**, with nothing added to the compiler:

```botopink
type Matrix(rows: i32[][]) implement Index<i32, i32[]> {
    pub fn at(self: Self, key: i32) -> ?i32[] {
        return self.rows.at(key);
    }
}

val m = Matrix(rows: [[1, 2], [3, 4]]);
val row: ?i32[] = m[1];          // [3, 4]
```

A **tuple** is the one exception, and its reason is the rule's: `t[0]` needs a
*constant* index and answers a type *per position*, which `at(key: K) -> ?V`
cannot say with a single `V`. A tuple index is checked directly — `t[0]` is
`i32` and `t[1]` is `string` below, neither of them optional, and an index the
type has no position for is refused where it is written.

<!-- docs-check: body -->
```botopink
val t = #(1, "a");
val n: i32 = t[0];
val label: string = t[1];
```

### Operators

<!-- docs-check: skip an operator table, not a module -->
```botopink
a + b, a - b, a * b, a / b, a % b     // arithmetic (+ also concatenates strings)
a == b, a != b, a < b, a > b, a <= b, a >= b
!x, x && y, x || y                    // logical
a |> f                                // pipe: f(a)
x?.field                              // optional chaining
```

`/` over two integers is integer division: it truncates toward zero and answers
an integer of the operands' type, on every target (`7 / 2` is `3`, `-7 / 2` is
`-3`). With a float operand it is float division (`7.0 / 2.0` is `3.5`). A number
literal with a `.` or an exponent is a float (`2.5`, `1e3`, `5e-324`).

### Lambdas and method chains

<!-- docs-check: body -->
```botopink
val double = { n -> n * 2 };
val xs = [1, 2, 3, 4];

val total = xs
    .filter({ n -> n % 2 == 0 })
    .map({ n -> n * 2 })
    .fold(0, { acc, n -> acc + n });    // 12
```

The pipe operator `|>` is left-associative.

### Line width

`botopink format` keeps lines within 80 columns where a break exists, and every
construct breaks **all or nothing**: it fits on one line, or each of its parts
takes a line of its own, `+4` from the statement. The outer construct decides
first, so a list never breaks for what follows it:

<!-- docs-check: skip a layout sample, not a program -->
```botopink
val entry = ThemeEntry(
    name: "--text-3xl--line-height",
    value: "calc(2.25 / 1.875)",
);

return reportTitle()
    + "\n\n"
    + notAppliedLine()
    + known.length;

if (absDiff > tolerance)
    throw "values differ by more than tolerance";
```

A method chain breaks before every `.call`, a binary run before every operator, an
argument list or a literal after its opening bracket with a trailing comma, and an
`if` with a brace-less branch before that branch. Formatting is a function of the
content only: a hand-broken list that fits is joined.

### If / else

<!-- docs-check: body -->
```botopink
val x = 1;
val s = if (x > 0) { "positive" } else { "negative" };
```

An `if` used as a value needs its `else`: `val s = if (x > 0) { "positive" };` has no value when
the condition is false and is refused at the `if`.

A condition is a whole expression, `&&` and `||` included — the grammar's own
parentheses close it, so nothing has to be bound to a `val` first:

<!-- docs-check: body -->
```botopink
val a = true;
val b = false;
if (a && b) { @print("both"); } else if (a || b) { @print("either"); }
```

`if` on an optional unwraps it in the then-branch:

```botopink
fn show(x: ?i32) {
    if (x) { n -> @print(n); }
}
```

Write the binder `_` when the branch only asks whether the value is there:

<!-- docs-check: body -->
```botopink
val x: ?i32 = 5;
if (x) { _ -> @print("present"); } else { @print("absent"); }
```

### Case (pattern matching)

```botopink
type Shape {
    Circle(radius: f64),
    Square(side: f64),
}

fn area(shape: Shape) -> f64 {
    return case shape {
        Circle(radius) -> radius * radius * 3.14;
        Square(side) -> side * side;
    };
}
```

List and or-patterns:

```botopink
type Color { Red, Green, Blue }

fn warm(c: Color) -> bool {
    return case c {
        Red | Green -> true;
        Blue -> false;
    };
}

fn size(items: i32[]) -> string {
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

A section of an enum is itself a type, written by its path, so a function can
take one section instead of the whole enum:

```botopink
type Token {
    Text { Bold, Italic },
    Hover(inner: Token[]),
}

fn textToCss(t: Token.Text) -> string {
    return case t {
        Bold -> "font-weight:bold";
        Italic -> "font-style:italic";
    };
}
```

An arm may also be written as a block, `<pattern> { … }`. A block arm takes an
optional `when (…)` guard, and a pattern may be a literal, a type (`i32`) or `_`.

```botopink
fn grade(n: i32) {
    case n {
        i32 when (n > 100) { @print("impossible"); }
        0 { @print("zero"); }
        _ { @print("something else"); }
    }
}
```

A variant pattern names **every** field of its variant, or ends with `..`:

```botopink
type Shape {
    Circle(radius: i32),
    Rect(width: i32, height: i32),
}

fn describe(s: Shape) -> i32 {
    return case s {
        .Rect(width: w, ..) { w }
        .Circle(r) { r }
    };
}
```

`.Rect(width: w)` without the `..` is `error: missing required field 'height' on
type 'Rect'`, at the arm — the fields a pattern does not name are dropped, and
`..` is how you say so.

A range in a pattern is `...`, inclusive at both ends — Zig's split: `...` in a
pattern, `..` (exclusive) in a `for` and a slice. `1..9` in an arm is
`error[pattern-range-exclusive]`, naming `...`; an open end is a guard.

```botopink
fn bucket(n: i32) -> string {
    return case n {
        1...9 { "digit" }
        _ when (n < 0) { "negative" }
        _ { "other" }
    };
}
```

A name alone is not a pattern: to give the matched value a name, bind it in the
body (`_ { n -> … }`). The one exception is the optional, below, where the name
after the `null` arm *is* the pattern.

#### An optional is matched by `null` and a binder

A `?T` has exactly one pattern form — `null` for the absent value, then a name
that binds what is there, already unwrapped:

<!-- docs-check: body -->
```botopink
val x: ?i32 = 5;
val a = case x { null { "absent" } v { "present " + v.toString() } };
@print(a);
```

Two arms, in that order, and no guards. `null` comes first because a binder
written first would match the absent value too. The binder may be `_` when the
body does not read the value, and the arms cover the `?T` between them, so no
`_` arm is needed and none is allowed.

An optional is **not** a variant: `case x { .Some(v) { … } .None { … } }` is
`error: an optional is matched by ``null``, not by a variant`, located at the
arm. `Some` and `None` are not spellings this language has — `??` and `?.` read
an optional the same way this does.

### Loops

Three keywords, one meaning each (decision 105), and two prefixes that turn any of
them into an iterator or a stream (decision 125):

| Form | Does | An expression? |
|---|---|---|
| `loop { … }` | repeats until `break` | no |
| `while (cond) { … }` | repeats while `cond` holds | no |
| `for (coll) { x -> … }` | walks a collection, a range or an `@Iterator` | no |
| `for await (s) { x -> … }` | walks a `@Stream`, where the body has an await channel | no |
| `iter loop` · `iter while` · `iter for` | the loop is an iterator: `yield v` / `break v` emit | **yes** — `@Iterator<T>` |
| `stream loop` · `stream while` · `stream for` · `stream for await` | the same, and the body may `await` | **yes** — `@Stream<T>` |

A plain loop is a statement: bare `break` leaves it and `continue` starts its
next round, in all three. `for` binds the item only — the index is
`for (0..xs.length) { i -> … }`. The parentheses stay (`while (cond) {`), as
they do on `if`: without them `while x {` could not tell the body from a record
literal. `loop (…)` is an error naming `for` and `while`.

A range `a..b` excludes its end and `a...b` includes it: `for (1..4)` visits
`1 2 3`, `for (1...4)` visits `1 2 3 4`. A range is not a value — there is no
`Range` and no `.rev()`; a countdown is a `while` or `xs.reverse()`.

<!-- docs-check: body -->
```botopink
val xs = [1, 2, 3];

for (xs) { item ->
    @print(item);
}

for (1...3) { i ->
    @print(i);
}

var n = 0;
while (n < 3) {
    n = n + 1;
}

loop {
    n = n - 1;
    if (n == 0) { break; }
}
```

**`yield v` and `break v` need a generator scope** — a function whose return is
`@Iterator<T>` or `@Stream<T>`, or an `iter` / `stream` loop. `yield v` emits
and continues; `break v` emits and ends (≡ `yield v; break;`). Outside a
generator scope both are refused: no plain loop answers a value, and collecting
in an ordinary function is `xs.map(…)` / `filter(…)` or a `var`. A `yield`
inside an unprefixed `for`, `while` or `loop` feeds the **nearest** generator
scope; `yield :label v` and `break :label v` name another scope's label.

With `iter` or `stream` in front, the loop is an expression worth the iterator
(or the stream), `T` being the type of its `yield` / `break v`. It captures the
enclosing scope — a `var` it reassigns is its state:

<!-- docs-check: body -->
```botopink
var count = 0;
val doubles = iter loop {
    count = count + 1;
    if (count == 10) { break count * 2; }   // the last item: 20
    yield count * 2;                          // 2 4 6 … 18
};
for (doubles) { d -> @print(d); }

val evens = iter for ([1, 2, 3, 4]) { x -> if (x % 2 == 0) { yield x; } };
for (evens) { e -> @print(e); }
```

The rules of the prefixed loop:

- `iter` and `stream` are **contextual** words: they are keywords only
  immediately before `loop`, `while` or `for`. `g.iter()`, `val stream = 1` and
  `http.stream(…)` stay legal.
- The prefixed loop **is** the iterator: `break` and `break v` in it end the
  sequence.
- Its body is **closed**: it has the iterator's or the stream's own capabilities,
  never the enclosing function's. Inside a `@Component` function an `iter loop`
  may neither `use` nor `await`; `await` exists only in `stream` (`iter-await`
  suggests it), and `break :outer` / `continue :outer` across its border are
  refused like leaving a closure.
- The item becomes `@Result<U, E>` on its own when the body has `throw` or `try`
  (*Iterators and streams*). To pin the type, annotate the binding —
  `val xs: @Iterator<i32> = iter loop { … };` — and a `try` in the body is then a
  located error. Two different error types in one body are
  `gen-infer-conflicting-errors`, asking for that annotation.

**`for` does no implicit `try`** (decision 122): over an
`@Iterator<@Result<U, E>>` the item is the `@Result`, and the body decides —
`try r` to propagate (with a `@Result` in the return), `case` to carry on.
`for` over any `@Iterator` is legal in any body; `for await` needs an await
channel (a `@Task`, `@Component` or `@Stream` return, an `async { }` block or a
`stream` loop) and is otherwise `effect-await-without-task`. `for` over a
`bool` is refused naming `while`.

Labels go on all three: `for :outer (xs) { x -> … }`, `while :w (…) { … }`,
`loop :l { … }`, then `break :outer`, `continue :outer`.

A `//` comment inside a loop body parses like any other comment.

**Per backend.** On commonJS `iter …` is `(function* () { … })()` and
`stream …` is `(async function* () { … })()`; erlang, beam and wasm lower the
prefixed loop as they lower an `@Iterator` / `@Stream` function, inline.

### Assert

<!-- docs-check: body -->
```botopink
val x = 1;
assert x > 0;
assert x > 0, "x must be positive";
```

`val assert <pattern> = <expr>;` binds the pattern's names and is **fatal** when
the match fails, so the names below the binding are never unbound. It takes no
`catch` — `try … catch` is the form that supplies a fallback.

```botopink
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") {
        throw "empty input";
    }
    return 42;
}

fn load() {
    val assert Ok(n) = parse("42");
    @print(n);
}
```

### use — imports, activation, and hooks

One keyword, two roles: a **declaration** (the import list and the extension
activation) and an **expression prefix** (the hook activation). Grammar:

<!-- docs-check: skip a grammar, not a module -->
```
ImportDecl     := "import" "{" ImportList "}" ("from" String)? ";"
ImportList     := ImportItem ("," ImportItem)* ","?
ImportItem     := DottedName ("*" | "as" Ident)?  // a dotted path — one leaf
                | Ident ":" "{" ImportList "}"    // a group — several leaves under one prefix
DottedName     := Ident ("." Ident)*
ActivationStmt := DottedName "*" ";"              // module level only
UseExpr        := "use" Expr                      // prefix; the operand is a call
```

**Declaration role.** `import { name* } from "…"` opts an imported `implement`
/ `extend` into scope (see *Imports*). The bare statement `Name*;` at module
level names a local symbol, and is refused either way: an extension declared in
the module is applied on its own — `` `Name*` is redundant: an extension declared
in this module is auto-applied; `*` is only for imports `` (`redundantActivation`)
— and anything else is `'Name' does not name an implement/extend symbol`
(`notAnExtension`).

**Expression role.** A **hook** is a function whose return type is
`@Component<Base, R>`: `Base` is the base the hook is anchored at, `R` is what it
yields. A hook is named by its noun, without a `use` prefix (`state`, `effect`,
`router`, `pathname` — never `useState`), because the keyword *is* the
activation. `val x = use <hook>(…)` activates the hook and binds `R`; a bare
`use <hook>(…);` activates a void hook; `val {a, b} = use …` binds `R`'s fields
by name. The activating body is itself a `@Component` function — a **custom
hook** (`-> @Component<Base, _>`, hooks compose) or a **component**,
`fn Widget() -> @Component<ElementBase, Element>`, where `Element` is the type
that carries the tree: `implement @Context<ElementBase>` is the owner marker.
One wrapper serves both (decision 128): the base is always written, and a
component is the `@Component<Base, T>` whose `T` implements `@Context<Base>`. A
component is **called** (`Widget(1)`), never `use`d. Every `use` in one body
agrees on the one base its return type names. There is no annotation: the
return is the declaration of the effect (decision 118).

```botopink
type ElementBase(id: i32)
type Element(count: i32) implement @Context<ElementBase>
type State(value: i32, name: string)

// A hook: the noun, the base, the yield.
fn state(initial: i32) -> @Component<ElementBase, State> {
    return State(value: initial, name: "state");
}

// A custom hook composes hooks.
fn counter(start: i32) -> @Component<ElementBase, State> {
    val s = use state(start * 2);
    return s;
}

// A component: its return is the owner, and it may `await` too.
fn Widget(n: i32) -> @Component<ElementBase, Element> {
    val c = use state(n);
    val {value, name} = use counter(n);
    return Element(count: c.value + value);
}

// A plain return: an ordinary function, which activates nothing.
fn Loading() -> Element {
    return Element(count: 0);
}
```

The rules, each with its diagnostic:

- **Only a `@Component<C, T>` return grants `use`** (decisions 104 and 118). A
  `use` in any other body — a plain `fn`, a `@Task` one whatever it wraps — is
  refused at the `use`: `` use-without-context-effect: `use` needs a
  `@Component<…>` return on the enclosing fn 'Widget' (it returns 'Element') ``.
  Nothing is unwrapped to find an owner: the server component that awaits and
  uses is `fn Page() -> @Component<ElementBase, Element>`, which the chain lets
  `await` (`@Component ⊃ @Task`). A nested closure, an `async { }` block and an
  `iter` / `stream` loop are not the `@Component` body either: `use` is not
  inherited by them, as `await` is not.
- **The wrapper is written, with its base.** `@Component<Element>` with one
  argument is a type-arity error — the base is never read off `T`. A component
  that activates a hook under a bare `-> Element` is
  `use-without-context-effect`; an aliased return (`type Comp<T> =
  @Component<ElementBase, T>`) types the function but grants nothing
  (`effect-wrapper-behind-alias`). A `T` that owns a context at another base
  (`@Component<Http, Element>` with `Element: @Context<ElementBase>`) is refused.
- **A component never propagates** (decision 121). `throw` and `try` are legal
  in a `@Component` body only when `T` is a `@Result`; a component returns
  `Element`, so it handles a failure in its own body — `try await load() catch
  fallback`, a `case`, a navigation signal or an error screen. A bare `try` there
  is `effect-try-without-fallible-channel`. A hook may return
  `@Component<Base, @Result<T, E>>`, and then its body may `try`.
- **The operand is a hook.** `use plain()` where `plain : -> User` is
  `` use-of-non-context-fn: `use` takes a hook: 'User' is not a hook `@Component<C, _>` ``,
  and `use Card()` where `Card` is a component (its `T` owns the context) is refused: a component is
  called, not `use`d.
- **One base per body** (decision 96). The base is a property of the
  FUNCTION, not of each activation: the first `use` fixes it and every later
  one resolves against the same one. Two refusals say so, and they are
  different rules. A single `use` anchored at a base the return type never
  named is the DECLARATION's: `use connection()` with `connection : ->
  @Component<Http, _>` inside a body anchored at `Element` is
  `` context-anchor-violation: function anchors at `Element` but `use` returns
  @Component<Http, _> ``. A second `use` disagreeing with the first is the BODY's,
  refused at its own site with both bases and the line that fixed the anchor:
  `` context-anchor-violation: every `use` in one function resolves against the
  same ContextBase: this body's is `Element`, fixed by the `use` on line 9, and
  this one is @Component<Http, _> ``. Two hooks that are each legal alone are still
  refused together; there is no flag (decision 67). Each body starts over — a
  sibling `fn` may anchor wherever its own return type says.
- **The static prefix.** Every `use` of a function body comes before its first
  `if`, `case`, `loop` or `return`, at any nesting: `val c = use …` after a
  `return`, and a `use` inside an `if`'s own block, are both parse errors —
  `` `use` must be in static prefix `` with the hint `Move all `use` statements
  to the top of the function body, before any `if`, `case`, `loop`, or
  `return``. A lambda body is another function: its own prefix starts over, so
  `use memo({ -> return count * 2; })` keeps the enclosing prefix intact.
- **The type is `R`.** `val c = use state(0)` binds `c : State`, and
  `val {value, set} = use state(0)` binds each name to the field of `R` it
  names. A tuple `R` destructures positionally: with `optimistic : (i32, fn(i32,
  i32) -> i32) -> @Component<ElementBase, #(i32, fn(action: i32) -> i32)>`,
  `val #(shown, push) = use optimistic(12, addLike)` binds `shown : i32` and
  `push : fn(action: i32) -> i32`. The pattern's arity is the tuple's, and the
  hook's `R` has to be a tuple; either failing is refused at the binding —
  `` use-tuple-arity: `val #(…)` binds 1 name(s) but the hook yields a tuple
  of 2 `` and `` use-tuple-arity: `val #(…)` binds 2 name(s) but the hook
  yields 'i32', which is not a tuple `` — with no flag (decision 67).
- **`use` never leaves a function body.** There is no module-level `use` and no
  `use client;` / `use server;` directive (decision 87 of 1.0.10-beta): a
  framework's boundary markers are its own decorators (`#[client]`).

**Lowering.** `use f(x)` is `f(x)` on erlang, wasm and beam, and `await f(x)`
on commonJS, where every `@Component` body is an `async function` — awaiting or
not, as a `@Task` one is — so every hook and component answers a Promise and
every caller awaits it (decisions 88 and 104). The prefix is the
activation the checker validated, not a rename: nothing is turned into
`useState`, no dependency array is inferred — a hook that takes one declares it
as a parameter (`memo(compute, deps)`). A client runtime supplies hook semantics
through what `f` does; the pure body above is what every backend runs, and what
the server renders.

**The provider side.** A `@Component` body is also the effect under which
`@getContext(T)` reads the active provider of `T` on the same owner tree; a
provider stack is not part of this section.

## Functions

`use` and the `@Component` return (hooks and components) are under *Expressions › use*;
the effects a return grants are under *Effects*.

### Recursion

A function may call itself. When the call is the **whole** of a `return` — a
*tail* call — it costs no stack: commonJS rewrites it into a loop, and erlang
and beam run on VMs that drop the frame. The depth of a tail-recursive walk is
bounded by the data, not by the runtime.

```botopink
fn sumDown(n: i32, acc: i32) -> i32 {
    if (n == 0) return acc;
    // A tail call: the whole of the `return`. A loop, not a frame.
    return sumDown(n - 1, acc + n);
}
```

Every other recursion uses the stack, and how deep it may go is the host's
answer, not the language's:

* a call that is not the whole of the `return` — `return 1 + f(n - 1)`;
* **mutual** recursion: `a` calling `b` calling `a`;
* a call through anything but the function's own name — a method on a value, a
  function held in a binding;
* a function that also makes a closure reading one of its own parameters, or
  one with a destructuring or defaulted parameter;
* a function returning `@Iterator`, `@Stream`, `@Task` or `@Component`.

`wasm` recurses for every shape, tail call included — about 30 000 frames.
Measured at 1.0.10-beta, with node's own ceiling for a two-parameter function
between 10 000 and 20 000.

### Parameters with defaults

```botopink
fn greet(name: string, greeting: string = "hello") -> string {
    return greeting + ", " + name + "!";
}

fn main() {
    @print(greet("world"));         // hello, world!  — `greeting` takes its default
    @print(greet("world", "hi"));   // hi, world!
}
```

A call **may leave out an argument whose parameter declares a default**, and the
declared expression is what the function receives. A default may be declared on
a free `fn`, on a record's fields (where it is the constructor's default) and on
a method — including a `behavior`'s `default fn`, which is where `"hello"
.slice(1)` gets its open end from (`slice(self, start: i32, end: ?i32 = null)`).

```botopink
type Port(number: i32 = 80, host: string) {
    pub fn show(self: Self, separator: string = ":") -> string {
        return self.host + separator + self.number.toString();
    }
}

fn main() {
    @print(Port(host: "a").number);   // 80
    @print(Port(host: "a").show());   // a:80
}
```

Only the parameters a call leaves out take their defaults. A parameter the call
names by label keeps the argument it was given, whichever position it is in —
`Port(host: "a")` names the second field and fills the first from its default —
and a parameter with no default is still **required**: leaving one out is the
arity error it has always been.

<!-- docs-check: skip a call the compiler must REFUSE; compiling it is the opposite of the claim -->
```botopink
fn connect(host: string, port: i32 = 80) -> string { return host; }

connect();   // error: 'connect' expects 2 argument(s), got 0
```

Defaults are filled in by the checker, so every backend receives a call with
every argument written out; no backend emits a default of its own.

### Effects

An ordinary function cannot fail, wait, activate hooks or produce a sequence.
To gain one of those capabilities it **writes the wrapper in its return type** —
there is no annotation; the return is the annotation (decision 118):

| Return | The body may write |
|---|---|
| `T` | only `try … catch` (handles the error on the spot) |
| `@Result<T, E>` | `throw` · `try` |
| `@Task<T>` | `await` |
| `@Component<C, T>` | `use` · `await` |
| `@Iterator<T>` | `yield` · `break v` |
| `@Stream<T>` | `yield` · `break v` · `await` |

In `@Task`, `@Component`, `@Iterator` and `@Stream`, **`throw` and `try` are
also legal when the value (or the item) is a `@Result<U, E>`** — for example
`@Task<@Result<User, string>>`.

Blocks and loops have no signature, so they take a prefix:

| Form | Worth |
|---|---|
| `async { … }` | `@Task<T>` |
| `iter loop` · `iter while` · `iter for` | `@Iterator<T>` |
| `stream loop` · `stream while` · `stream for` · `stream for await` | `@Stream<T>` |

The rules that make it work:

1. **The wrapper is written in the return.** `-> @Task<User>` activates the
   effect; an alias (`type Job<T> = @Task<T>`) types the function and activates
   nothing — a capability used under it is `effect-wrapper-behind-alias`,
   because whoever reads the signature has to see the `@`. A function has one
   return, so it has one effect.
2. **The capabilities form a chain**, and each level grants everything below it:

   ```
   @Component<C, T>  ⊃  @Task<T>        use · await
   @Stream<T>        ⊃  @Task + yield   yield · await
   @Iterator<T>                         yield
   ```

   That is why a hook or a component may `await`, and a stream may `await`.
3. **Only `@Result` fails** (decisions 120 and 121). `@Task`, `@Component`,
   `@Iterator` and `@Stream` never fail. When something can fail, the failure
   goes **inside the value** — `@Task<@Result<T, E>>`,
   `@Iterator<@Result<T, E>>` — the body gains `throw` and `try`, and the
   receiver decides what to do with the error.
4. **The chain grants downwards only.** `use` exists only under a `@Component`
   return; `yield` only in iterators and streams; `await` neither under a
   `@Result` return nor in an `@Iterator`; `throw` / `try` only with a `@Result`
   in some layer of the return. A capability the return does not grant is a
   located compile error, and no flag turns it off (decision 67):

```
error: effect-try-without-fallible-channel: `try` needs a @Result in the return
(@Result<…>, @Task<@Result<…>>, @Component<C, @Result<…>>, …) — or handle it
here with `try … catch`
```

Two forms are **not** gated by the return, because neither leaves the body.
`try <e> catch <f>` handles the error on the spot, so it needs no channel and is
legal in a plain `fn` — it is bare `try`, which returns the `Error` out of the
enclosing function, that needs one. A `yield` inside a `for`, `while` or `loop`
body feeds the nearest generator scope (see *Loops*), so it is gated like any
other.

**What `return` does** (decision 119). In a function with a wrapper return,
`return v` with `v: T` **wraps** (`Ok(v)`, a resolved Task, …); `return w` with
`w` already of the wrapper's type **passes it through** as it is. With
`@Task<@Result<U, E>>` both layers wrap: `return v` with `v: U` is a Task
holding `Ok(v)`, `return r` with `r: @Result<U, E>` is a Task holding `r`. A
value that fits two layers of a nested wrapper (`-> @Result<@Result<i32, E>,
E>`) is `effect-return-ambiguous-nesting`, asking for an explicit `Ok(…)`.

The quick reference:

| I want… | I write | I call it with |
|---|---|---|
| a function that can fail | `fn f() -> @Result<T, E>` | `try f()` · `try f() catch x` · `case` |
| an asynchronous function | `fn f() -> @Task<T>` | `await f()`, with an await channel |
| an asynchronous function that can fail | `fn f() -> @Task<@Result<T, E>>` | `try await f()` · `try await f() catch x` · `case (await f())` |
| a Task in the middle of a function | `async { … }` | pass it along, `await` it |
| a hook | `fn h() -> @Component<Base, T>` | `use h()`, in a `@Component` body with the same base |
| a component, page or layout | `fn C() -> @Component<ElementBase, Element>` | `C()`, an ordinary call |
| a sequence | `fn g() -> @Iterator<T>` | `for (g()) { x -> … }`, in any function |
| a sequence of items that fail | `fn g() -> @Iterator<@Result<T, E>>` | `for` + `try r` or `case` |
| an asynchronous sequence | `fn g() -> @Stream<T>` | `for await`, with an await channel |
| an iterator or a stream in the middle of a function | `iter …` · `stream …` | `for` · `for await` |

### Results

A function that can fail returns `@Result<T, E>`; `throw` produces the error,
`return` the value, and `try` propagates the error of a call.

```botopink
type PortError { Zero, TooBig(value: i32) }

fn port(n: i32) -> @Result<i32, PortError> {
    if (n == 0) { throw PortError.Zero; }
    if (n > 65535) { throw PortError.TooBig(value: n); }
    return n;                                  // becomes Ok(n)
}

fn serverPort(n: i32) -> @Result<i32, PortError> {
    val p = try port(n);                       // an Error from `port` rises from here
    return p + 1;
}

// `return` passes an existing @Result through unchanged
fn firstOk(a: @Result<i32, string>, b: @Result<i32, string>) -> @Result<i32, string> {
    return case a {
        Ok(_) -> a;
        Error(_) -> b;
    };
}
```

Three ways to consume a `@Result`, and a fourth for when a failure is a bug:

```botopink
type PortError { Zero, TooBig(value: i32) }

fn port(n: i32) -> @Result<i32, PortError> {
    if (n == 0) { throw PortError.Zero; }
    return n;
}

// 1) try … catch — handles it on the spot; works in ANY function
fn portOrDefault(n: i32) -> i32 {
    return try port(n) catch 8080;
}

// 2) try alone — propagates; needs a @Result in the return
fn doubled(n: i32) -> @Result<i32, PortError> {
    val p = try port(n);
    return p * 2;
}

// 3) case — looks at both outcomes
fn describe(n: i32) -> string {
    return case port(n) {
        Ok(p) -> "port " + p.toString();
        Error(_) -> "no port";
    };
}

// 4) val assert — fatal if it does not match
fn mustPort() {
    val assert Ok(p) = port(443);
    @print(p);
}
```

**`try` and `await` begin an expression.** They stand where an expression
starts — a statement, a `val` / `var` initializer, the right side of `=`, a
`return` / `yield` / `break` / `throw` operand, a call argument, an element of
an array, tuple or record literal, an `if` / `while` condition, a `case`
subject, a `for` iterable — and take the whole expression after them:
`try a + b` is `try (a + b)`, and `try await f()` is `try (await f())`. Neither
is ever the operand of an operator, of a unary `-` / `!`, of parentheses or of
a `.` chain; `total + try r`, `-try x` and `(try r).length` are
`try-await-operand`, and the fix is to bind the value first:

```botopink
fn total(a: @Result<i32, string>, b: @Result<i32, string>) -> @Result<i32, string> {
    val x = try a;               // not `try a + try b`
    val y = try b;
    return x + y;
}
```

### Tasks

`@Task<T>` is a value that has not arrived yet, and `await` unwraps it. A Task
**never fails** (decision 120): if the operation can go wrong, the value is a
`@Result`, and `await` hands over that `@Result`. To propagate the error,
combine it with `try`:

```botopink
type User(id: i32, name: string)

fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
    if (id <= 0) { throw "no user " + id.toString(); }   // legal: the value is a @Result
    return User(id: id, name: "ana");                     // a Task holding Ok(…)
}

fn greetingFor(id: i32) -> @Task<@Result<string, string>> {
    val u = try await fetchUser(id);           // await answers the @Result; try propagates it
    return "Hello, " + u.name;
}

fn greetingOrGuest(id: i32) -> @Task<string> {
    val u = try await fetchUser(id) catch User(id: 0, name: "guest");
    return "Hello, " + u.name;                 // no @Result in the return: handled here
}

fn describeUser(id: i32) -> @Task<string> {
    val r = await fetchUser(id);               // the @Result itself
    return case r {
        Ok(u) -> u.name;
        Error(e) -> "error: " + e;
    };
}
```

`await` and `try` are separate things — `await t` waits, `try r` propagates.
With `t: @Task<@Result<U, E>>`:

| I write | I get | Legal where |
|---|---|---|
| `await t` | `@Result<U, E>` | with an await channel |
| `try await t` | `U` (the error rises) | with an await channel **and** a `@Result` in the return |
| `try await t catch x` | `U` (or `x`) | with an await channel |

An **await channel** is a `@Task`, `@Component` or `@Stream` return, an
`async { }` block or a `stream` loop; `await` anywhere else is
`effect-await-without-task`. An ordinary function that holds a Task either
returns a `@Task` too or hands the Task on.

**`async { … }` — a Task in the middle of a function** (decision 124). The block
creates a `@Task` without declaring a separate function, in **any** function:
it waits for nothing, it creates the Task.

```botopink
type User(id: i32, name: string)

fn fetchUser(id: i32) -> @Task<@Result<User, string>> {
    if (id <= 0) { throw "no user"; }
    return User(id: id, name: "ana");
}

fn both() -> @Task<@Result<string, string>> {
    val first = async { return try await fetchUser(1); };   // @Task<@Result<User, string>>
    val count = async { return 2; };                         // @Task<i32>
    val u = try await first;
    val n = await count;
    return u.name + n.toString();
}
```

- `return v` **leaves the block** with `v`, not the enclosing function — the
  block behaves like a closure called in place;
- it is **closed**: inside a `@Component` function an `async { }` cannot `use`,
  and `break :outer` / `continue :outer` across its border are refused;
- `T` comes from its `return`s. A body with `throw` or `try` makes the value
  `@Result<U, E>` on its own, `E` coming from those `throw` / `try`; two
  different error types are `gen-infer-conflicting-errors`, asking for an
  annotation: `val x: @Task<@Result<User, string>> = async { … };`.

**Per backend.** On commonJS every `@Task` (and `@Component`) function is an
`async function` and its caller awaits; `async { }` is `(async () => { … })()`.
**A `throw` in a `@Task<@Result<…>>` does not reject the Promise: it resolves
with the `Error` value** — JavaScript that consumes a botopink function reads
the `{ Error: … }` it answers instead of catching a rejection. On erlang, beam
and wasm a `@Task` is eager, `await` is the identity and `async { }` runs the
block in place.

### Iterators and streams

An iterator produces a sequence on demand: each `next` runs the body up to the
next `yield`. A stream is the same, asynchronous — finding out whether there is
a next item may need waiting. Both answer one step type (decision 122):
`YieldStep<T>` = `{ Yield(value: T), Done }`.

- `yield v` emits `v` and **continues**;
- `break v` emits `v` and **ends** (≡ `yield v; break;`);
- a bare `break` outside any inner loop ends without emitting.

```botopink
fn fibonacci(limit: i32) -> @Iterator<i32> {
    var a = 0;
    var b = 1;
    var i = 0;
    while (i < limit) {
        yield a;
        val t = a + b;
        a = b;
        b = t;
        i = i + 1;
    }
}

fn firstNegative(xs: i32[]) -> @Iterator<i32> {
    for (xs) { x ->
        if (x < 0) { break x; }               // emits the negative and ends
        yield x;
    }
}

fn main() {
    for (fibonacci(10)) { n -> @print(n); }  // an ordinary function may iterate
}
```

**Items that can fail — `@Iterator<@Result<T, E>>`.** The iterator does not
fail; **each item** may be an error. When the item is `@Result<U, E>` the body
gains the sugar: `yield v` with `v: U` emits `Ok(v)` (with `v: @Result<U, E>` it
emits it as is), `throw e` emits `Error(e)` and ends, and a `try x` that fails
emits `Error(e)` and ends. Whoever iterates receives the `@Result` and decides —
**`for` does no implicit `try`**:

```botopink
fn port(n: i32) -> @Result<i32, string> {
    if (n <= 0) { throw "not a port: " + n.toString(); }
    return n;
}

fn ports(xs: i32[]) -> @Iterator<@Result<i32, string>> {
    for (xs) { x -> yield try port(x); }     // a failed `try` emits Error(e) and ends
}

// stop at the first error: an explicit try, under a @Result return
fn sumPorts(xs: i32[]) -> @Result<i32, string> {
    var total = 0;
    for (ports(xs)) { r ->
        val p = try r;                         // the explicit try: an Error rises from here
        total = total + p;
    }
    return total;
}

// carry on past the error: a case, in any function
fn printPorts(xs: i32[]) {
    for (ports(xs)) { r ->
        case r {
            Ok(p) -> @print(p);
            Error(e) -> @print("error: " + e);
        }
    }
}
```

**`@Stream<T>` — asynchronous, iterated with `for await`.** The rules above
hold, and a failing `try await` also emits `Error(e)` and ends:

```botopink
fn fetchPage(n: i32) -> @Task<@Result<i32[], string>> {
    if (n > 9) { throw "no page " + n.toString(); }
    return [n, n + 1];
}

fn pages(count: i32) -> @Stream<@Result<i32[], string>> {
    var page = 0;
    while (page < count) {
        val rows = try await fetchPage(page);  // failed: emits Error(e) and ends
        yield rows;                            // emits Ok(rows)
        page = page + 1;
    }
}

fn countRows() -> @Task<@Result<i32, string>> {
    var n = 0;
    for await (pages(3)) { batch ->
        val rows = try batch;                  // `n + (try batch).length` is refused
        n = n + rows.length;
    }
    return n;
}
```

**Iterator or factory.** A function with an `@Iterator` or `@Stream` return is
an iterator if its own body has `yield` or `break v` (not counting closures and
inner `iter` / `stream` loops); otherwise it is an ordinary function that
**returns** a ready-made iterator. Mixing the two in one body is
`iter-mixed-yield-return`.

```botopink
fn evens(xs: i32[]) -> @Iterator<i32> {                 // an iterator: it yields
    for (xs) { x -> if (x % 2 == 0) { yield x; } }
}

fn evensOf(xs: i32[]) -> @Iterator<i32> {               // a factory: it returns one
    return iter for (xs) { x -> if (x % 2 == 0) { yield x; } };
}
```

**A type that is iterated exposes a method** answering an iterator; there is no
iterable behavior, and the consumer calls it — `for (grid.iter())`:

```botopink
type Grid(cells: i32[]) {
    fn iter(self: Self) -> @Iterator<i32> {
        for (self.cells) { c -> yield c; }
    }
}

fn main() {
    val g = Grid(cells: [1, 2, 3]);
    for (g.iter()) { c -> @print(c); }
}
```

The refusals, each located:

<!-- docs-check: skip bodies the compiler must REFUSE; compiling them is the opposite of the claim -->
```botopink
fn g() -> @Iterator<i32> {
    throw "x";                  // effect-try-without-fallible-channel: the item has to be
}                               //   @Result<i32, E> to throw

fn h() -> @Iterator<i32> {
    yield await count();        // iter-await: no `await` in an @Iterator — use @Stream
}

fn k(xs: i32[]) -> @Iterator<i32> {
    yield 0;
    return evens(xs);           // iter-mixed-yield-return: an iterator (yield) and a
}                               //   factory (return) in one body

fn old() -> @Iterator<i32, string> { … }
                                // iterator-error-param-removed: @Iterator<@Result<i32, string>>
```

**Per backend.** On commonJS an `@Iterator` function with `yield` is a
`function*` and a `@Stream` one an `async function*`; a factory is a plain
function. A generator cannot be an arrow function, so `this` and captured
variables get the treatment ordinary closures get.

## Comptime

### Compile-time evaluation

```botopink
val result = comptime {
    val x = 10;
    break x * 2;
};
```

### Template functions

A function taking `comptime q: @Expr<…>` expands at the call site; `@expr`
lifts a comptime value back into code.

```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val port = 8000 + t.length;
    val debug = true;
    return @expr(#(port, debug));    // the labels come from the variable names
}
```

### Host bindings

```botopink
#[@External.Node("./helpers.mjs", "parse"),
  @External.Erlang("helpers", "parse")]
pub declare fn parse(input: string) -> i32;
```

A declaration takes the signature a `fn` does — generic parameters, `comptime`
parameters, any return type — with or without an annotation. A parameter it
has no name for is written `_` (`declare fn getContext<T>(comptime _: type) ->
Component<T, any>;`); `_` is a bodyless declaration's placeholder, and a
function with a body refuses it (`discard-param-with-body`).

A binding may also be a template, where `$0`, `$1`, … are the declared
parameters — on a method, `self` is `$0`:

```botopink
#[@External.Node("$0.toUpperCase()"),
  @External.Erlang("string:uppercase($0)")]
pub declare fn shout(text: string) -> string;
```

**A host function that operates on a value of one type is a method of that
type.** It is declared inside the type's body with `declare fn`, `self` first,
and called like any other method — `sock.recv(16, 1000)`, never a free
`recv(sock, 16, 1000)`. The binding's `$0` is the receiver and `$1`, `$2`, … the
arguments after it; the plain `("module", "symbol")` form hands the host
function the receiver first. A host function with no such owner (`listen(port,
backlog)`, `now()`) stays at module level.

```botopink
pub type Meter(base: i32) {
    #[@External.Node("""($0.base + $1)"""),
      @External.Erlang("""(element(2, $0) + $1)""")]
    pub declare fn plus(self: Self, n: i32) -> i32;

    pub fn twice(self: Self) -> i32 {
        return self.plus(self.base);
    }
}

fn main() {
    val m = Meter(base: 3);
    @print(m.plus(4));               // 7 on every backend that has a host
}
```

Every backend lowers such a method as a real method of the type whose body is
the binding: a class member on commonJS (an enum's is a static taking `self`,
like every enum method), a function exported by the type's module on erlang and
beam — so a method on an imported type is answered by its owner exactly as a
bodied one is — and a declaration in the `.d.ts`. A method with no binding for
the active backend is refused where it is **called**, naming `Type.method`
(`` `Meter.plus` has no `#[@External.<Target>(…)]` for the wasm backend ``).

Only `External.<Target>` is read. A lower-case `@external(node, …)` is a located
error naming the capitalised form (`` `#[@external]` binds no host — an external
target is written `External.<Target>` ``), rather than a function left silently
without a host.

`inline = true`, written last on `External.Erlang` or `External.Beam`, opts the
declaration out of the dispatch table so the backend's hand-coded shape keeps
emitting. Those two variants alone declare it, because the erlang and beam
emitters alone read it. Written on `Node`, `Wasm` or `Typescript`, anywhere but
last, or with a value that is not a bool, it would be a switch nothing reads, so
it is refused at the annotation (`` `External.Node` declares no `inline` — the
flag is read by the erlang and beam emitters only ``).

A relative path (`"./helpers.mjs"`, `"helpers"` on erlang) names a **sidecar** the
library keeps beside its sources, in `<src>/sidecars/` or `<src>/`. `botopink
build` and `botopink test` copy it next to the emitted module, from the
directory the dependency resolved to — so it ships the same whether the library
is a workspace member, a `{ "path": … }` package outside every library root, or
one of two checkouts declaring the name. A sidecar the build cannot ship is a
located error on the `dependencies` entry that named the library, never a
silent exit 0. See [`docs/botopink-json.md`](./docs/botopink-json.md) § Host
sidecars.

**A host that answers a record may build it either way.** A value knows its own
type (§ *A value knows its own type*), and a host is the one writer the compiler
does not own — a `.erl` sidecar shipped by a library, a template written before
the rule existed. So the boundary accepts both shapes and the declared return
type decides which record the answer becomes: a plain object or map is adopted
into the record the declaration names, field by declared name, and an answer
that already carries its type is left exactly as it is. The same holds one
container deep — `?T`, `T[]`, `@Result<T, E>` and `@Task<T>` are looked
through — and no deeper.

```botopink
type Point(x: i32, y: i32)

#[@External.Node("({ x: 7, y: 9 })"),
  @External.Erlang("#{x => 7, y => 9}")]
declare fn hostPoint() -> Point;

fn distance(p: Point) -> i32 {
    return p.x + p.y;                // 16 on every backend that has a host
}
```

A field the host leaves out is the absent value, not an error — a host is not
asked to fill a record it does not know about.

**A host that answers later** is declared with a `@Task` return (decision 126).
Declared `-> @Task<@Result<T, E>>`, a rejected Promise (Node) or an
`{error, R}` (Erlang) becomes `Error(…)`; declared `-> @Task<T>`, a rejection is
a fatal host failure — that form is for a host that guarantees it does not fail.

```botopink
#[@External.Node("fetch($0).then(__r => __r.text())"),
  @External.Erlang("helpers", "get")]
pub declare fn getText(url: string) -> @Task<@Result<string, string>>;
```

**Calling a host binding on a target it does not name is refused where the call
is written, on every backend:**

```
error: `listToBinary` has no `#[@External.<Target>(…)]` for the wasm backend
  --> src/main.bp:21:12
```

| Target | Reads | A call with no binding for it |
|---|---|---|
| `commonJS` | `@External.Node` | refused at compile time — "for the node backend" |
| `erlang` | `@External.Erlang` | refused at compile time — "for the erlang backend" |
| `beam` | `@External.Erlang` (the same vocabulary) | refused at compile time — "for the beam backend" |
| `wasm` | `@External.Wasm` — nothing declares one today, so **every** host binding is refused here | refused at compile time — "for the wasm backend" |

wasm has no host to bind a declaration to, and no WASI call stands in for an
arbitrary host symbol. Until 2026-09-21 it lowered such a call to a `wasm trap`
instead, so the program compiled and then died at run time where the other three
refused it; it now refuses too, and there is no flag that restores the trap. A
program that needs a host symbol on wasm needs a wasm implementation, not a
looser compiler.

## Builtins

```botopink
fn greet() {
    @print("hello");
}

fn notReady() -> i32 { @todo(); }
```

Other builtins (`@panic`, `@field`, `@emit`, …) are declared in
`libs/std/src/builtins.d.bp` and `libs/std/src/builtins_fns.d.bp`. Builtin
names are exact: an unrecognised `@name(…)` is `error[unknown-builtin]`
(with the nearest name when one is an edit away), never a silent `void`.

### What `@print` writes

A value prints the way the source writes it. A record names its type and its
fields, a variant names its enum, a container separates its elements with
`", "`, and a type implementing `Display` prints its `display()` instead —
nested inside a container too.

```botopink
type Point(x: i32, y: i32)
type Shape { Square(side: i32), Nothing }

behavior Display { fn display(self: Self) -> string; }
type Money(cents: i32) implement Display {
    pub fn display(self: Self) -> string { return "$" + self.cents.toString(); }
}

fn main() {
    @print([1, 2]);                   // [1, 2]
    @print(#(1, "a"));                // #(1, "a")
    @print(Point(x: 1, y: 2));        // Point(x: 1, y: 2)
    @print(Shape.Square(side: 4));    // Shape.Square(side: 4)
    @print(Shape.Nothing);            // Shape.Nothing
    @print([Money(cents: 1)]);        // [$1]
}
```

A string prints as its text at the top level (`hi`) and quoted inside a
container (`["hi"]`). erlang, BEAM, commonJS and wasm all write the record and
variant text; `Display` is consulted on the first three, and wasm prints the
record's own fields instead.

### A value knows its own type

Two declarations with the same fields are two types, and their values are never
equal:

```botopink
type Person(name: string, age: i32)
type Vec(name: string, age: i32)

test "two types with the same fields are different values" {
    assert (Person(name: "Ana", age: 30) == Vec(name: "Ana", age: 30)) == false;
}
```

The declaration is inside the value on every backend: erlang and BEAM tag the
term with the module the type is declared in, commonJS makes it a class.

`is` and a `case` arm read it back — the arm is chosen by the value's own type,
not by the annotation it arrived under:

```botopink
type Person(name: string, age: i32)
type Vec(name: string, age: i32)

fn nameOf(v: Person | Vec) -> string {
    return case v {
        Person { "person" }
        Vec { "vec" }
    };
}

test "the value decides" {
    val u: unknown = Vec(name: "Ana", age: 30);
    assert u is Vec;
    assert (u is Person) == false;
    assert nameOf(Vec(name: "Ana", age: 30)) == "vec";
}
```

### `@src()` and `SourceLocation`

```botopink
// A builtin record every module sees:
//   type SourceLocation(file: string, line: i32, column: i32, fnName: string)

fn where() -> SourceLocation {
    return @src();
}

test "src: a test knows its own name" {
    val loc = @src();
    @print(loc.file, loc.line, loc.column, loc.fnName);
    // src/example.bp 10 15 src: a test knows its own name
}
```

`@src()` is the place it is written, evaluated at compile time: the four
fields are literals at the call site and the expression costs nothing at run
time — every backend emits the same code it emits for the constructor call
`SourceLocation(file: "…", line: N, column: C, fnName: "…")`.

| Field | Value |
|---|---|
| `file` | the source file relative to the root of its package, forward slashes, with extension (`src/emilia.bp`, `test/color_test.bp`) |
| `line`, `column` | 1-based position of the `@` — the numbers a diagnostic prints |
| `fnName` | the enclosing `fn`'s name; `Type.method` inside a method; the test name inside `test "…" { }` (`test_<idx>` for an anonymous block); `""` at module level. A lambda does not change it |

`@src()` takes no arguments and no trailing lambda (`@src(1)` is
`error[src-takes-no-arguments]`). It is a value like any other: `@src().line`
reads a field in place. Its consumer is the test contract — `std/testing/asserts`
messages and `std/testing/snapshots` paths are computed from the caller's `@src()`.

## Tests

```botopink
test "addition works" {
    assert 1 + 1 == 2;
}
```

Test blocks are declared at module level. Run with `botopink test`
(`--target`, `--filter <substring>`).

A test body is a **fallible context**: a `try` whose operand is an `Error(e)`
ends the test as `FAIL <name>  (<e>)  at <file>:<line>` — `e` is the message
(a non-string `e` is rendered) and the `at` is the test's own line. The
statements after the failed `try` do not run; a `try` inside a lambda is the
lambda's, not the test's. An assertion helper is therefore an ordinary
`fn … -> @Result<void, string>` whose `ok` position is the empty
`return;`:

```botopink
fn isPositive(n: i32) -> @Result<void, string> {
    if (n <= 0) { throw "asserts.isPositive: value not positive"; }
    return;
}

test "t: a propagated error fails the test" {
    try isPositive(-1);     // FAIL t: a propagated error fails the test  (asserts.isPositive: value not positive)  at src/main.bp:12
}
```

### Mocks

`std/testing/mocks` is the Mockito-style double: `when(...)` stubs a return, the
matchers `eq` / `anyInt` / `anyString` pick which call a stub answers, and
`verify(mock, spec)` checks how many matching calls were recorded. It is the
old `onze` library, retired into std (1.0.10-beta front 01-std, decision 71).
commonJS and erlang only — its cells are `pub declare fn` with a Node and an
Erlang template each, so `import {testing.mocks} from "std"` is refused on beam and
wasm, where `botopink test` does not run.

```botopink
import {testing.mocks} from "std";

behavior UserRepo {
    fn find(self: Self, id: i32) -> string;
}

// The double: every method funnels through `mocks.invoke`, which records the
// call and answers the matching stub value or the type-default.
type MockUserRepo(__id: string) implement UserRepo {
    fn find(self: Self, id: i32) -> string {
        return mocks.invoke(self.__id, "find", [mocks.key(id)], "");
    }
}

fn mockUserRepo() -> UserRepo { return MockUserRepo(__id: mocks.newMock()); }

test "repo: eq(v) stubs only the matching argument" {
    val repo = mockUserRepo();
    val _s = mocks.when(repo.find(mocks.eq(7))).thenReturn("ana");
    assert repo.find(7) == "ana";
    assert repo.find(8) == "";
    val _v = mocks.verify(repo, mocks.times(2)).find(mocks.anyInt());
}
```

`#[mock]` writes that double for you — it reflects the annotated `behavior`'s
methods through `@Decl` and `@emit`s the type plus a `mock<Name>()` factory.
**It fires inside the module that declares it only.** `@emit` splices its text
into the module that hosts the annotated behavior, and the text names the
runtime bare (`invoke`, `key`, `newMock`), which resolves in `std/testing/mocks` and
nowhere else: a `from "std"` import binds the module handle (`mocks`), never
its functions, and `#[mocks.mock]` is not looked up as a decorator at all. So a
consumer writes the double by hand, as above. Recorded in
`specs/1.0.10-beta/01-std/onze-migration.md` § *Language gaps*.

Two more limits carried over from the old library: a matched `thenThrow` is a
host throw, not an `@Result`, so the caller catches it with `asserts.throws`
and not with `try … catch`; and there is no generic `any<T>()` matcher, because
it would need a per-type default it cannot synthesize.

## Backends

| Target     | Output | Runner                      |
|------------|--------|-----------------------------|
| `commonJS` | `.js`  | `node` ≥ 20                 |
| `erlang`   | `.erl` | `escript` (OTP)             |
| `beam`     | `.S`   | artifact — `erlc +from_asm` |
| `wasm`     | `.wat` | `wasmtime`                  |

Select the target with `--target`:

```bash
botopink run --target commonJS
botopink build --target erlang
```

## Project manifest

Every project carries a `botopink.json` at its root:

```json
{
  "name": "my-project",
  "version": "0.1.0",
  "target": "commonJS",
  "dependencies": {
    "erika": { "git": "https://github.com/botopink/erika.git", "branch": "feat" }
  }
}
```

Optional `entry` names the module-tree root under `src/` (default: `main.bp`,
else `root.bp`). `dependencies` is an object — one entry per import name, each
with exactly one source: `{ "path": "…" }`, `{ "git": "…", "branch"|"tag"|"rev":
"…" }` or `{ "workspace": true }` (the sibling member of the enclosing
workspace). A manifest with `"workspaces": ["modules/*", "examples/*"]` is a
workspace: it declares members and is not a package. Every field, both forms
and every refusal are in [`docs/botopink-json.md`](docs/botopink-json.md).

## Migrating from the effect annotations

1.0.10-beta replaced the effect annotations with the return type (decisions
118–128) and kept no compatibility window (decision 127): every old form below
is a located compile error with a fix-it — `effect-annotation-removed` for an
annotation (on a loop it suggests `iter` / `stream`), `effect-type-removed` for
a wrapper name, `iterator-error-param-removed` for `@Iterator<T, E>`. There is
no automatic rewriter: each error names the new spelling, from the table below.

| Old | Now |
|---|---|
| `#[@result] fn f() -> @Result<T, E>` | `fn f() -> @Result<T, E>` |
| `#[@future] fn f() -> @Future<T, E>` | `fn f() -> @Task<@Result<T, E>>` (and `await x` → `try await x` where the error must propagate) |
| `@Future<T>` with no error | `@Task<T>` |
| `#[@use] fn f() -> @Use<C, T>` | `fn f() -> @Component<C, T>` (`throw` / `try` only if `T` is a `@Result`) |
| `#[@use] fn f() -> @Component<T>` | `fn f() -> @Component<B, T>`, `B` from `T implement @Context<B>` |
| `#[@generator]` + `@Generator<T>` | `@Iterator<T>` |
| `#[@resultGenerator]` + `@ResultGenerator<T, E>` | `@Iterator<@Result<T, E>>` (`for` no longer does an implicit `try`) |
| `#[@futureGenerator]` + `@FutureGenerator<T, E>` | `@Stream<@Result<T, E>>` |
| `#[@generator] loop { … }` | `iter loop { … }` |
| `#[@resultGenerator] loop { … }` | `iter loop { … }` (the item becomes a `@Result` from the body) |
| `#[@futureGenerator] loop { … }` | `stream loop { … }` |
| `YieldStep<T, E>` with `Error(error: E)` | `YieldStep<T>` = `{ Yield(value: T), Done }` |
| `@Iterator<T, E>` | `@Iterator<@Result<T, E>>` |
| `#[@context]` / `@Context<B, R>` as an effect | `-> @Component<B, R>` |
| `#[@iterator]` / `#[@asyncGenerator]` / `@AsyncIterator` | `@Iterator<@Result<…>>` / `@Stream<@Result<…>>` |
| `Iterable`, `IteratorStep`, `Yield<T, R>` | `YieldStep<T>` |
| `loop (xs) { x -> }` · `loop (cond)` · `loop await` | `for (xs) { x -> }` · `while (cond)` · `for await` |
| `-> Element` on a component that uses a hook | `-> @Component<ElementBase, Element>` |

Four changes are not a rename and are reviewed by hand:

- **An `await` whose error used to propagate.** `await` answers the `@Result`
  now; where the function's return carries a `@Result`, write `try await`.
  Where it does not — a component returning `Element`, a `@Task<T>` — handle the
  error there: `try await x catch fallback`, a `case`, a navigation signal.
- **A `throw` in a hook or component** whose `T` is not a `@Result`: either the
  hook returns `@Component<C, @Result<T, E>>`, or the error is handled in its
  body (decision 121).
- **A `for` over a fallible iterator** hands over the `@Result`: add `try r`
  (with a `@Result` in the return) or a `case`; `for await` likewise.
- **JavaScript that consumes botopink.** A `@Task<@Result<…>>` resolves its
  Promise with the `Error` value instead of rejecting it.

## Decided, not yet implemented

These are settled language rules that the compiler does not accept yet. They
are listed so nothing here reads as working code; each names the front that
closes it, or says that it has none yet. Every row below was re-derived by
**running** the form, not by reading the previous revision of this table.

| Rule | Today | Closes with |
|---|---|---|
| A block-shaped statement ends itself: **no** `;` after the closing brace of an `if`, a loop or a `case` in statement position | the `;` is **optional** there: the parser accepts both, `botopink format` prints none, and the compiler's own trees are migrated — a library or a `tests/language` cell that still writes it compiles | 1.0.10-beta C-13, in decision 132's order: each library drops the `;` (`botopink format`), then `tests/language`, then the parser refuses it (`blockStatementSemicolon`) |

A row leaves this table when the compiler accepts the form, and the form is then
taught in the section that owns it: union types, the `unknown` type and its
assignability rule, `x is <Type>` with narrowing, `case` arms written
`Pattern { … }` with `when (…)` guards, the pattern range `1...9` (decision 53 —
the four backends agree on it), `val assert <pattern> = <expr>;` (binding its
names, and fatal when the match fails), a `//` comment inside a loop body, a
**parameter default applied at the call site** on all four backends, an
**effect on a record method** (`fn iter(self: Self) -> @Iterator<i32>` in a
`type … { … }` body is a generator method, walked by `for (b.iter()) { x -> … }`),
and `await` inside a `@Component` body (an `async function` on commonJS, awaited
by every caller).

Two limits worth stating here, because a library meets them before it meets a
rule. The checker half is `00 · 01-checker`'s:

- A default on an **imported function** is not filled. The cross-module export
  registry carries no plain `fn` declaration, so `import { greet } from "helper";
  greet("w")` reds `'greet' expects 2 argument(s), got 1` where the same `greet`
  called inside `helper` fills. An imported record's field default is filled.
- On wasm a method called through a **behavior-typed** value traps
  (`unreachable`) at run time; commonJS, erlang and beam dispatch it
  (`00 · 05-wasm`'s).

These forms are **deliberately absent**, so that none reads as unfinished work:

| Form | What the compiler says |
|---|---|
| `assert x is Some(n)` — `is` binding a payload | `error[is-variant-binding]`: `is` tests a type; it does not bind. Read the payload in a `case` arm |
| `type Shape { Circle(i32) }` — a variant payload with no field name | `error[field-needs-name]`: a field with no name, at the payload, naming `Variant(field: T)`. A payload nobody can name is a payload no `case` arm can bind |
| `val assert Ok(v) = parse("42") catch 0` | ``after `catch` the value is not a @Result — a `val assert` over a `@Result` takes no `catch` `` — the match is fatal, and `try … catch` is the form that supplies a fallback |
| `c ? a : b` | `error[ternary-absent]` — `if` is an expression: `val x = if (c) { a } else { b };` |
| `<<` `>>` `&` `^` | `error[bitwise-operator-absent]` — there are no bitwise operators; `&&` and `\|\|` are the boolean ones, and a bit operation is a host function |
| `'a'` | `error[char-literal-absent]` — a character is a one-character string, `"a"` |
| `fn inner(…) { … }` inside a body | `error[nested-fn-decl]` — inside a body a function is a value: `val inner = { x -> … };` |
| `[..a, 3]` | `error[list-spread-not-last]` — the spread of an array literal comes last: `[3, ..a]` |
| `[...a]` | `error[list-spread-dot-dot-dot]` — `...` is a pattern's inclusive range; an array spreads with `..` |
| `implement A for P { … }` after a bodyless `type P(…)` | `error[implement-clause-for]` — the type's own clause is `type P(…) implement A { … }` |
| `#(x: 1, y: 2)` | `error[tuple-literal-label]` — a tuple literal is positional, `#(1, 2)`; labels belong to the tuple type, `#(x: i32, y: i32)` |
