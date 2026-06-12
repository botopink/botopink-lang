# botopink Language Reference

Complete examples and language features organized by topic. Most examples map to parser/comptime/codegen snapshot coverage, and snapshot slugs may evolve across refactors.

## Table of Contents

- [Reference Updates (v0.0.13-beta)](#reference-updates-v0013-beta)
- [Imports](#imports)
- [Modules](#modules)
- [Variables](#variables)
- [Functions](#functions)
- [Operators](#operators)
- [Conditionals](#conditionals)
- [Error Handling](#error-handling)
- [Effects](#effects)
- [Null Safety](#null-safety)
- [Structs](#structs)
- [Records](#records)
- [Enums](#enums)
- [Interfaces](#interfaces)
- [Pattern Matching](#pattern-matching)
- [Loops](#loops)
- [Lambdas](#lambdas)
- [String Interpolation](#string-interpolation)
- [Comptime Evaluation](#comptime-evaluation)
- [Expr Templates](#expr-templates)
- [Function Specialization](#function-specialization)
- [Loop Unrolling](#loop-unrolling)
- [Delegates](#delegates)
- [Implement](#implement)
- [Destructuring](#destructuring)
- [Arrays and Tuples](#arrays-and-tuples)
- [Result & Option methods](#result--option-methods)
- [Test Blocks](#test-blocks)
- [Annotations & `external`](#annotations--external)

---

## Reference Updates (v0.0.13-beta)

This reference was updated after reviewing the latest commit series:
`a42d948`, `1888bfb`, `65f990d`, `8a79f94`, and `7991edc`.

### Compiler changes that affect this document

- The active expression model is now grouped into AST families:
  `literal`, `identifier`, `binaryOp`, `unaryOp`, `jump`, `branch`, `loop`, `binding`, `useHook`, `call`, `function`, `collection`, `comptime_`.
- Import syntax: `import { X };` resolves from the project root; `import { X } from "name";` resolves from a named dependency. A trailing `*` on an item activates method dispatch, `as` renames the final binding, and a bare `X*;` statement activates an already-visible symbol.
- `Expr.useHook` added to the AST for `use` hooks inside function bodies (distinct from top-level `ImportDecl` imports).
- Generic type syntax: `@Result<D, E>` with `is_builtin` flag (replaces old `@Result(D, E)` parenthesis syntax).
- `@Result` / `?T` carry builtin methods (`.map`, `.flatMap`, `.unwrapOr`,
  plus `.isOk` / `.isError` for Result) — see [Result & Option methods](#result--option-methods).
- Method calls accept an expression receiver, so chains
  (`a().map(f).unwrapOr(0)`) and zero-arg method calls (`r.isOk()`) are valid.
- Four comptime runtimes: `node`, `erlang`, `beam` (BEAM via erlang), `wasm` (WAT via wasmtime).
- Codegen snapshot directories renamed: `beam_asm` → `beam`, `wat` → `wasm`.

### Reading note

Examples in this file describe language behavior. Exact snapshot file names may change as internals are refactored.

---

## Imports

```
import   ::=  "import" "{" item ("," item)* "}" from? ";"
from     ::=  "from" string
item     ::=  dottedPath "*"? ("as" ident)?
```

- no `from` → resolves from the project root
- `from "name"` → resolves from the named dependency
- trailing `*` on an item → activates dispatch of that symbol's methods (impl or extend)
- a bare name (no `*`) → brings the name only; `obj.m()` does **not** resolve, only qualified `Sym.m(obj)`
- `as` renames the final binding

### Named imports from project root

```botopink
import { foo, bar };
```

**Generates:**
```javascript
const { foo, bar } = require("./module");
```

### Named imports from external module

```botopink
import { fetch, Response } from "http";
```

**Generates:**
```javascript
const { fetch, Response } = require("http");
```

### Multi-module public function import

```botopink
// math.bp
pub fn double(x: i32) -> i32 {
    return x * 2;
}

// main.bp
import { double } from "math";
val result = double(21);
```

### Multi-module public value import

```botopink
// config.bp
pub val PORT = 8080;
pub val HOST = "localhost";

// main.bp
import { PORT, HOST } from "config";
val addr = HOST;
val port = PORT;
```

### Dotted path imports

```botopink
import { std.List, std.Map };
```

### Activation suffix, alias, and fallback statement

```botopink
import { Pato, PatoNada*, PatoVoa* as Voa, std.List as L } from "ducks";

val p = new Pato();          // Pato: name only
p.swim();                    // PatoNada*: active dispatch
Voa.move(p);                 // PatoVoa imported as Voa, qualified
val xs = L.of(1, 2, 3);      // std.List as L

// Activate an already-visible symbol without re-importing it:
PatoExtra*;
```

---

## Modules

botopink uses an explicit, Rust-style module tree. A package declares which
files belong to it by following `mod` declarations from a root, instead of the
compiler implicitly compiling every `.bp` it finds under `src/`.

```
module ::= "pub"? "mod" ident ";"
```

`mod` is a keyword; a `mod` declaration is only valid at module top level (a
`mod` inside a function body is a parse error).

### The tree

```
src/
  main.bp          ← binary entry (holds `fn main`); roots a binary package
  root.bp          ← library root (public API surface); roots a library package
  geometry.bp      ← a leaf module, pulled in by `mod geometry;`
  shapes/
    mod.bp         ← the `shapes` module — the folder index (like Rust's mod.rs)
    circle.bp      ← pulled in by `mod circle;` inside shapes/mod.bp
    square.bp
```

```botopink
// root.bp — the tree root declares the top-level modules
pub mod geometry;     // public: re-exported, reachable package-wide / by consumers
pub mod shapes;       // public: resolves shapes/mod.bp (the folder index)
mod internal;         // private: visible only within the root's subtree

// shapes/mod.bp — a folder index declares the folder's submodules
pub mod circle;       // resolves shapes/circle.bp
pub mod square;       // resolves shapes/square.bp
mod helpers;          // private to the shapes subtree
```

- **`main.bp`** roots a **binary** package (the entry holding `fn main`);
  **`root.bp`** roots a **library** package. `botopink.json` `entry` chooses
  which root applies (auto-detected as `main.bp`, then `root.bp`).
- **`mod Name;`** declares a submodule. It resolves, in the declaring file's
  directory, to either a sibling `Name.bp` **or** a folder index `Name/mod.bp`
  — exactly one must exist (both, or neither, is an error).
- **`mod.bp`** is a folder's index module (Rust's `mod.rs`): it is the module
  named after its folder and declares that folder's submodules.
- A `.bp` not reached through any `mod` path is reported **orphaned** and is not
  compiled.

### Visibility — the path-visibility rule

`pub mod` re-exports a submodule through its parent; a plain `mod` keeps it
private to the declaring module's subtree. A declaration is importable across a
module boundary only if **every `mod` on its path is `pub mod`** *and* the
declaration itself is `pub`.

```botopink
// shapes/mod.bp
pub mod circle;   // shapes.circle is reachable from outside shapes
mod helpers;      // shapes.helpers is private to the shapes subtree
```

Importing through a private `mod` fails, naming the private segment — e.g.
`import { secret } from "shapes.helpers";` from `main.bp` is rejected because
`helpers` is private to `shapes`; the same import from another file inside
`shapes/` succeeds.

### Imports through the tree

`import { x } from "geometry"` resolves `x` from module `geometry`;
`import { x } from "shapes.circle"` follows the `mod` chain (the dotted path is
the module path `shapes/circle`). The named module must publicly export `x`.
`from "<lib>"` resolves an external dependency unchanged (the generic loader).

### Migration

Packages that predate the explicit tree (no `main.bp`/`root.bp` root) still
build through a deprecated implicit `src/` scan, with a warning. Add a root with
`mod` declarations to opt into the explicit tree; the implicit scan will be
removed in a future release.

---

## Variables

### Number literal

```botopink
val x = 42;
```

### String literal

```botopink
val greeting = "hello";
```

### Binary expression

```botopink
val sum = 1 + 2;
```

### Null literal

```botopink
val nothing = null;
```

### Optional annotation with null

```botopink
val msg: ?string = null;
```

### Public value declaration

```botopink
pub val VERSION = 1;
pub val HOST = "localhost";
```

**Generates:**
```javascript
const VERSION = 1;
const HOST = "localhost";
```

---

## Functions

### Private function with return

```botopink
fn double(x: i32) -> i32 {
    return x * 2;
}
```

### Public exported function

```botopink
pub fn add(a: i32, b: i32) -> i32 {
    return a + b;
}
```

### Function with local binding

```botopink
fn double(x: i32) -> i32 {
    val result = x * 2;
    return result;
}
```

### Forward references and mutual recursion

Top-level functions are order-independent: a function may call another declared
later in the same module, and two functions may call each other.

```botopink
fn isEven(n: i32) -> bool {
    if (n == 0) { return true; };
    return isOdd(n - 1);          // forward reference — isOdd is declared below
}

fn isOdd(n: i32) -> bool {
    if (n == 0) { return false; };
    return isEven(n - 1);
}
```

Every top-level `fn` signature is bound before any body is type-checked, so
declaration order never affects what is in scope. (A genuinely undefined name is
still reported as an unbound-variable error.)

This is a runtime guarantee, not just a type-checking one: the recursion above
compiles **and runs** to the same result on every backend (commonJS, erlang,
beam, wasm). A function's else-less base-case guard (`if (n == 0) { return … };`)
falls through to the recursive tail call when the guard is false on all of them.

---

## Operators

### Comparison

```botopink
fn isPositive(n: i32) -> bool {
    return n > 0;
}
```

**Generates:** `return (n > 0);`

### Equality

```botopink
fn isZero(n: i32) -> bool {
    return n == 0;
}
```

**Generates:** `return (n === 0);`

---

## Conditionals

### Simple conditional in function body

```botopink
fn sign(n: i32) -> string {
    val r = if (n > 0) { "positive"; };
    return r;
}
```

**Generates:**
```javascript
function sign(n) {
    const r = (() => { if ((n > 0)) { return "positive"; } })();
    return r;
}
```

### Conditional with else branch

```botopink
fn describe(n: i32) -> string {
    return if (n > 0) { "positive"; } else { "non-positive"; };
}
```

---

## Error Handling

`try` / `catch` operate on `@Result<D, E>` values and lower to **pattern
matching on the `Ok` / `Error` tag** — never to host (JS/Erlang) exceptions.
Applying `try` to a non-`@Result` value is a compile-time error.

A `@Result` is a tagged value: `{ tag: "Ok", result }` / `{ tag: "Error", error }`
in JavaScript, `{ok, V}` / `{error, E}` in Erlang and BEAM, and a linear-memory
pointer (tag `i32` at `[ptr]`, payload at `[ptr+4]`) in WebAssembly.

### Propagate without catch

`try expr` unwraps the `Ok` value; on `Error` it returns the error variant from
the enclosing function (propagation).

```botopink
fn fetch() -> @Result<i32, string> {
    todo;
}
fn process() -> i32 {
    val r = try fetch();
    return r;
}
```

**Generates (CommonJS):**
```javascript
function process() {
    const _try0 = fetch();
    if (_try0.tag === "Error") return _try0;
    const r = _try0.result;
    return r;
}
```

### With inline catch handler

`try expr catch fallback` replaces an `Error` with a fallback value. A lambda
handler (`catch fn(e) { … }`) receives the unwrapped error.

```botopink
fn fetch() -> @Result<i32, string> {
    todo;
}
fn safe() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

**Generates (CommonJS):**
```javascript
function safe() {
    const _try0 = fetch();
    const r = _try0.tag === "Error" ? (0) : _try0.result;
    return r;
}
```

**Generates (Erlang):**
```erlang
safe() ->
    R = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    R.
```

### Throw type checking

The value of a `throw` must match the `E` of the enclosing function's
`@Result<D, E>` return type:

```botopink
fn parse(s: string) -> @Result<i32, string> {
    if (s == "") {
        throw "empty input";   // ✓ "empty input": string == E
    }
    return 0;
}
```

A mismatch is a compile-time error:

```botopink
fn parse(s: string) -> @Result<i32, string> {
    throw 404;   // ✗ error: i32 thrown, but E = string
}
```

`throw` is only valid when the enclosing function returns `@Result<D, E>`. A
function with a different declared return type rejects it:

```botopink
fn run() -> i32 {
    throw "x";   // ✗ error: throw requires the fn to return @Result<D, E>
}
```

Functions with **no** declared return type leave `throw` unchecked (this is
what makes `val x = try f() catch throw err;` legal), and a `throw` inside a
nested lambda is checked against that lambda, never the outer function's `E`.

---

## Effects

A function's **effect** is named by a `#[@<effect>]` annotation — the same
`#[@…]` form used for `#[@external]`. The annotation marks the implementation;
the matching `@Effect<…>` **return wrapper** carries the effect's type
parameters. The annotation is the source of truth for how the function lowers
and which body operations it permits.

```botopink
#[@result]    fn parse(n: i32) -> @Result<i32, string> { … }
#[@future]    fn load() -> @Future<T> { … }
#[@generator] fn range(a: i32, b: i32) -> @Generator<i32> { … }
#[@iterator]  fn lazy() -> @Iterator<T> { … }
#[@context]   fn useThing() -> @Context<Base, T> { … }
```

### The effects

| Annotation          | Return wrapper        | Body operations              | CommonJS lowering    |
| ------------------- | --------------------- | ---------------------------- | -------------------- |
| `#[@result]`        | `@Result<D, E>`       | `throw` / `try` (checked)    | `function` (plain)   |
| `#[@future]`        | `@Future<T>`          | `await`                      | `async function`     |
| `#[@iterator]`      | `@Iterator<T>`        | `yield` / delegation         | `function*`          |
| `#[@generator]`     | `@Generator<T, R>`    | `yield` / delegation         | `function*`          |
| `#[@asyncGenerator]`| `@AsyncIterator<T>`   | `await` + `yield`            | `async function*`    |
| `#[@context]`       | `@Context<Base, T>`   | `use`                        | `function` (plain)   |

The effect gates the body operations: `await` is only valid inside a
`#[@future]` / `#[@asyncGenerator]` fn; `yield` (and `return <iter>`
delegation) only inside a `#[@generator]` / `#[@iterator]` / `#[@asyncGenerator]`
fn; `throw` / `try` is the checked-Result effect of a `#[@result]` fn. Using
one in the wrong effect is a compile-time error, as is an annotation that does
not match its return wrapper (`#[@future] fn -> @Result<…>`).

`@Future<T>` accepts an optional error type — `@Future<T, E>` is also valid;
the one-argument form defaults the error type.

### Implementation-only

An effect annotation marks an **implementation** (a `fn` with a body). An
**interface** method and a `.d.bp` declaration are declarative: they express
the effect through the return **wrapper** alone, with **no** annotation —
mirroring TypeScript, where the interface says `-> Promise<T>` and the impl
marks `async`.

```botopink
pub interface AsyncIterator<T, E> {
    fn next(self: Self) -> @Future<?T, E>   // declarative — no annotation
}
```

Using `#[@<effect>]` on an interface method or a bodyless `declare fn` is an
error: *effect annotations mark an implementation; declare the effect in the
return type*.

### Backends

CommonJS maps each effect to the matching JavaScript keyword (above). The
Erlang, BEAM, and WebAssembly backends lower effects **eagerly**: a `@Future<T>`
resolves to `T` (so `await` is the identity), a finite `@Iterator<T>` is a list,
and a `#[@result]` fn is a plain function returning the `{ok, V}` / `{error, E}`
tagged value.

> The bare `*fn` prefix is the **deprecated** spelling of an effect (its kind is
> inferred from the return wrapper). It still compiles to identical output, but
> the `#[@<effect>]` annotation is the canonical form.

---

## Null Safety

### Null-check binding

```botopink
var email: ?string = null;
if (email) { e ->
    print("Email: " + e);
};
```

### Optional chaining (`?.`)

JS-style optional chaining: when the receiver is null/absent the whole access
evaluates to null instead of failing. Works for member access and method calls.

```botopink
record User { name: string }

fn main() {
    val u: ?User = User(name: "ana");
    val n = u?.name;          // ?string — null when u is null
    val up = n?.to_upper();   // method-call form
}
```

**Generates (JS):**
```javascript
const n = u?.name;
const up = n?.to_upper();
```

- Typing: `a?.b` with `a: ?T` resolves `b` on `T` and yields `?U`
  (already-optional members are not double-wrapped — no `??U`).
- `?.[index]` and `?.(args)` forms are reserved (botopink has no `a[i]`
  index syntax yet — use `.at(i)`).
- Backend status: native on commonJS; erlang/beam/wasm pending the
  record-field-access lowering on those targets.

---

## Structs

### Private field, method, getter

```botopink
val Counter = struct {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

**Generates:**
```javascript
class Counter {
    _count = 0;

    increment() {
        this._count += 1;
    }

    get count() {
        return this._count;
    }
}
```

### Setter and two getters

```botopink
val Temperature = struct {
    _celsius: f64 = 0.0,
    set celsius(self: Self, value: f64) {
        self._celsius = value;
    }
    get celsius(self: Self) -> f64 {
        return self._celsius;
    }
    get fahrenheit(self: Self) -> f64 {
        return self._celsius * 1.8 + 32.0;
    }
}
```

### Multiple private fields with assign and pluseq

```botopink
val BankAccount = struct {
    _balance: f64 = 0.0,
    _owner: string = "",
    fn deposit(self: Self, amount: f64) {
        self._balance += amount;
    }
    fn setOwner(self: Self, name: string) {
        self._owner = name;
    }
    get balance(self: Self) -> f64 {
        return self._balance;
    }
    get owner(self: Self) -> string {
        return self._owner;
    }
}
```

### Method with call expression receiver

```botopink
val Logger = struct {
    _prefix: string = "",
    fn setPrefix(self: Self, p: string) {
        self._prefix = p;
    }
    fn log(self: Self, msg: string) {
        console.log(self._prefix, msg);
    }
    get prefix(self: Self) -> string {
        return self._prefix;
    }
}
```

**Generates:**
```javascript
class Logger {
    _prefix = "";

    setPrefix(p) {
        this._prefix = p;
    }

    log(msg) {
        console.log(this._prefix, msg);
    }

    get prefix() {
        return this._prefix;
    }
}
```

### Shorthand declaration without val name

```botopink
struct Counter {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

---

## Records

### Two fields

```botopink
val Point = record { x: i32, y: i32 };
```

**Generates:**
```javascript
class Point {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }
}
```

### Methods using self fields in arithmetic

```botopink
val Vec2 = record {
    x: f64,
    y: f64,
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
    }
}
```

**Generates:**
```javascript
class Vec2 {
    constructor(x, y) {
        this.x = x;
        this.y = y;
    }

    lengthSq() {
        return ((this.x * this.x) + (this.y * this.y));
    }

    scale(factor) {
        return (this.x * factor);
    }
}
```

### Method with throw

```botopink
val Invoice = record {
    subtotal: f64,
    taxRate: f64,
    fn total(self: Self) -> f64 {
        return self.subtotal + self.subtotal * self.taxRate;
    }
    fn validate(self: Self) {
        throw new Error("invalid invoice");
    }
}
```

### Method with todo placeholder

```botopink
record Unimplemented {
    id: i32,
    fn process(self: Self) -> string {
        return todo;
    }
}
```

### Shorthand declaration without val name

```botopink
record Vec2 {
    x: f64,
    y: f64,
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
}
```

---

## Enums

### Unit variants

```botopink
val Direction = enum {
    North,
    South,
    East,
    West,
}
```

### Payload variant

```botopink
val Color = enum {
    Red,
    Rgb(r: i32, g: i32, b: i32),
}
```

### Payload variants with method using variantFields case

```botopink
val Shape = enum {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            _ -> 0.0;
        };
    }
}
```

### Unit variants with method using ident case

```botopink
val HttpMethod = enum {
    Get,
    Post,
    Put,
    Delete,
    fn name(m: Self) -> string {
        val label = case m {
            Get -> "GET";
            Post -> "POST";
            Put -> "PUT";
            _ -> "DELETE";
        };
        return label;
    }
}
```

### Mixed unit and payload with method using mixed case

```botopink
val Maybe = enum {
    Nothing,
    Just(value: string),
    fn check(m: Self) -> string {
        return case m {
            Nothing -> "nothing";
            Just(value) -> "just";
        };
    }
}
```

### Method using qualified enum member

```botopink
val Status = enum {
    Active,
    Inactive,
    fn isDefault(s: Self) -> string {
        val current = Status.Active;
        return current;
    }
}
```

### Shorthand declaration without val name

```botopink
enum Direction {
    North,
    South,
    East,
    West,
}
```

---

## Interfaces

### Emits comment

```botopink
val Drawable = interface {
    val color: string,
    fn draw(self: Self);
}
```

**Generates:**
```javascript
// interface Drawable
//   color: string
//   fn draw(...)
```

---

## Pattern Matching

### Number literal patterns

```botopink
fn classify(n: i32) -> string {
    val result = case n {
        0 -> "zero";
        1 -> "one";
        _ -> "many";
    };
    return result;
}
```

**Generates:**
```javascript
function classify(n) {
    const result = (() => {
        const _s = n;
        if (_s === 0) return "zero";
        if (_s === 1) return "one";
        return "many";
    })();
    return result;
}
```

### String literal patterns

```botopink
fn greet(lang: string) -> string {
    val msg = case lang {
        "en" -> "hello";
        "pt" -> "ola";
        _ -> "hi";
    };
    return msg;
}
```

### OR patterns with numbers

```botopink
fn classify(day: i32) -> string {
    val kind = case day {
        6 | 7 -> "weekend";
        _ -> "weekday";
    };
    return kind;
}
```

**Generates:**
```javascript
function classify(day) {
    const kind = (() => {
        const _s = day;
        if (_s === 6 || _s === 7) return "weekend";
        return "weekday";
    })();
    return kind;
}
```

### List patterns empty, single, spread

```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

**Generates:**
```javascript
function describe() {
    const items = ["a", "b", "c"];
    return (() => {
        const _s = items;
        if (_s.length === 0) return "empty";
        if (_s.length === 1) {
            const x = _s[0];
            return "one";
        }
        if (_s.length >= 1) {
            const rest = _s.slice(1);
            const first = _s[0];
            return "many";
        }
    })();
}
```

### Guard clauses

A case arm may carry a guard: `pattern if <condition> -> body`. The arm matches
only when the pattern matches **and** the guard (which must be a `bool`)
evaluates to `true`; otherwise control falls through to the next arm. An
identifier pattern used with a guard binds the subject so the guard can test it.

```botopink
fn classify(n: i32) -> string {
    return case n {
        x if x > 0 -> "positive";
        0          -> "zero";
        _          -> "negative";
    };
}
```

**Generates:**
```javascript
function classify(n) {
    return (() => {
        const _s = n;
        {
            const x = _s;
            if ((x > 0)) return "positive";
        }
        if (_s === 0) return "zero";
        return "negative";
    })();
}
```

### Nested patterns

Constructor patterns nest, so a payload can be matched structurally:

```botopink
enum Found { Hit(value: i32), Miss; }

fn unwrap(r: @Result<Found, string>) -> i32 {
    return case r {
        Ok(Hit(n)) -> n;
        Ok(Miss)   -> 0;
        Error(_)   -> -1;
    };
}
```

---

## Loops

### Side-effect print in iterator

```botopink
val messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
loop (messages, 0..) { msg, i ->
    print("mensagem");
};
```

**Generates:**
```javascript
const messages = ["Erro 404", "Sucesso 200", "Aviso 500"];
const _loop = for (const [msg, i] of Object.entries(messages)) {
    print("mensagem");
};
```

### Side-effect over range

```botopink
loop (0..10) { i ->
    print("item");
};
```

### Map with break simple

```botopink
val ids = [10, 20, 30];
val dobrados = loop (ids) { id ->
    break id * 2;
};
```

**Generates:**
```javascript
const ids = [10, 20, 30];
const dobrados = for (const [id] of Object.entries(ids)) {
    (id * 2);
};
```

### Map with break (add tax)

```botopink
val precosBrutos = [100, 250, 400];
val precosComTaxa = loop (precosBrutos) { valor ->
    val taxa = valor * 0.15;
    break valor + taxa;
};
```

### Filter with conditional break

```botopink
val precosBrutos = [100, 250, 400];
val apenasGrandes = loop (precosBrutos) { valor ->
    if (valor > 200) {
        break valor;
    };
};
```

### Even numbers with break

```botopink
val processamento = loop (0..10) { i ->
    if (i % 2 == 0) {
        break i;
    };
};
```

---

## Lambdas

### Trailing lambda block

```botopink
fn run() {
    todo;
}
fn main() {
    run { x ->
        return "done";
    };
}
```

**Generates:**
```javascript
function main() {
    run((x) => {
        return "done";
    });
}
```

### Trailing lambda with multiple params

```botopink
fn calc(factor: i32) -> i32 {
    todo;
}
fn main() {
    val r = calc(2) { a, b ->
        return 0;
    };
}
```

**Generates:**
```javascript
function main() {
    const r = calc(2, (a, b) => {
        return 0;
    });
}
```

### Lambda with a full type annotation

When a `val` is annotated with a function type `fn(A, B) -> R`, the annotation
flows into the lambda: each parameter is typed from the annotation before the
body is checked, and the body's result is unified with the declared return type.

```botopink
val add: fn(i32, i32) -> i32 = { a, b -> a + b };
val result = add(2, 3);
```

---

## String Interpolation

`${…}` holes inside string literals (single-line and `"""…"""` multiline)
lower to a `+` concatenation chain per backend — interpolation is sugar, not a
runtime feature.

### Basic interpolation

```botopink
val name = "world";
val greeting = "hello ${name}!";
```

**Generates:**
```javascript
const name = "world";
const greeting = (("hello " + name) + "!");
```

### Holes follow `+` coercion semantics

A hole accepts anything the language's `+` accepts next to a string —
`"n=${1}"` works without an explicit conversion.

### Multiline templates

```botopink
val block = """
multi ${name}
line
""";
```

### Line strings (Zig style)

Consecutive lines prefixed with `\\` form a multiline string — the rest of
each line joins with newlines. Content follows the same conventions as
`"""…"""` (escape sequences resolve in the target; `${…}` interpolates), and
the tagged-call sugar applies:

```botopink
val page = html
    \\<div>
    \\  <p>${name}</p>
    \\</div>
;
```

The formatter normalizes line strings to the `"""` form.

### Escaping

`\${` produces a literal `${` (and `\$` is a valid escape):

```botopink
val price = "price \${USD}";   // → price ${USD}
```

---

## Comptime Evaluation

### Integer addition folds to literal

```botopink
val v1 = comptime 1 + 1;
```

**Generates:**
```javascript
const v1 = 2;
```

### Block with break value inlines result

```botopink
val t = comptime {
    break 2 + 22;
};
```

**Generates:**
```javascript
const t = 24;
```

### Float multiplication folds to literal

```botopink
val pi2 = comptime {
    break 3.14 * 2.0;
};
```

**Generates:**
```javascript
const pi2 = 6.28;
```

### Multiplication binds tighter than addition

```botopink
val n = comptime {
    break 2 + 3 * 4;
};
```

**Generates:**
```javascript
const n = 14;
```

### Runtime identifier inside comptime raises error

```botopink
// ERROR: comptime code cannot reference runtime identifiers
val msg = comptime {
    break greeting;  // 'greeting' not defined at comptime
};
```

**Error:**
```
error: runtime identifier 'greeting' inside comptime expression
```

### Comptime val folds arithmetic to literal

```botopink
val result = comptime 10 + 20;
```

**Generates:**
```javascript
const result = 30;
```

### Comptime basic: val and plain function coexist

```botopink
val x = comptime 1 + 2;

fn double(n: i32) -> i32 {
    return n * 2;
}

fn main() {
    val r = double(21);
}
```

**Generates:**
```javascript
const x = 3;

function double(n) {
    return (n * 2);
}

function main() {
    const r = double(21);
}
```

---

## Expr Templates

Comptime template strings: library functions receive caller source as
**unevaluated typed expressions**, inspect the caller's scope, and return
expressions that are **spliced and re-type-checked at the call site** —
zero-runtime-cost DSLs whose result types the language fully understands
after expansion.

The type surface is the builtin **`@Expr<E>`** (like `@Result`):
a *type marker* for unevaluated code of type `E`. There is no `expr` keyword
— `@Expr<E>` marks types, and code values are only **constructed explicitly**
through builtins.

### `type` meta-kind (generic constraints)

A parameter whose type is the `type` meta-kind must carry the `comptime`
modifier:

```botopink
pub fn parse(comptime T: type string | int, raw: string) -> T;
fn f(comptime T: type) { … }            // unconstrained
```

### The `@Expr<E>` type

`@Expr<E>` composes in any type position and **always carries its generic
parameter**. A result type only the expansion knows is an ordinary fn
generic, solved per call site. An `@Expr` parameter also requires `comptime`:

```botopink
pub fn html(comptime template: @Expr<string>) -> @Expr<string>;     // bounded
pub fn yaml<T>(comptime template: @Expr<string>) -> @Expr<T>;       // revealed per call
fn pick<T>(comptime first: ?@Expr<Element>) -> @Expr<T>;
```

### Tagged-call sugar

A string literal immediately after an identifier (or `a.b` access) is a call
with one argument:

```botopink
html """<Button/>"""        // ⇒ html("""<Button/>""")
sql "SELECT 1"              // ⇒ sql("SELECT 1")
```

### Unevaluated capture

An argument bound to a `comptime p: @Expr<T>` parameter is type-checked in
the caller, then captured **unevaluated** with provenance (file, span, origin
scope). V1 rule: the argument must be a **literal** string at the call site
(interpolation allowed) — a variable carries no span or scope to capture.

### `std.syntax` and `interface Expr<E>`

The data model (`Span`, `Part`, `BindingKind`, `Binding`, `Source`,
`Context`) lives in `libs/std/src/syntax.bp` as ordinary types, and the
comptime-only surface of an `@Expr<E>` value is declared as an interface:

```botopink
pub interface Expr<E> {
    val value: E                                      // the value type slot
    fn text(self: Self) -> string                     // raw template source text
    fn parts(self: Self) -> Part[]                    // text/interp alternation
    fn source(self: Self) -> Source                   // declaration position
    fn context(self: Self) -> Context                 // source + text + shape
    fn lookup(self: Self, name: string) -> ?Binding   // origin-scope resolution
    fn bindings(self: Self) -> Binding[]              // enumerate the origin scope
    fn build<R>(self: Self, source: string) -> @Expr<R> // parse text into code
    fn fail(self: Self, message: string)              // diagnostic at the expr's span
    fn failAt(self: Self, span: Span, message: string)// diagnostic INSIDE the template
}
```

`context()` is the second-layer entry point: a DSL compiler running inside a
template function gets where the template was declared (`Source`), its raw
text, and its shape in one object — input via `text`/`parts`/`lookup`/
`bindings`, code output via `build`/`@expr`/`@code`, diagnostics via
`fail`/`failAt`. These methods resolve against the expression's **origin
scope** — a caller template resolves in the caller's file (V1: top-level
decls + imports). `fail`/`failAt` abort expansion with a rustc-style
diagnostic pointing inside the `"""…"""` in the caller's file.

### Constructing code — explicit builtins only

A template function returns an `@Expr` value. There is **no implicit
coercion** — a constant is not silently an expression. Three explicit paths:

```botopink
// 1. Pass-through: an @Expr param IS an expr value — return it directly.
pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
    return template;
}

// 2. @expr(value): lift a comptime value as code, explicitly. The bound
//    is written when the author knows it.
pub fn port() -> @Expr<i32> {
    return @expr(8080);
}

// 3. @code(text) / template.build(text): parse generated source text into
//    code — the workhorse of a second-layer language. `@code` resolves where
//    it is written; `build` resolves in the template's origin scope.
pub fn sql<T>(comptime q: @Expr<string>) -> @Expr<T> {
    return q.build("runQuery(" + q.text() + ")");
}
```

`@expr`/`@code` are only valid inside a template function (`-> @Expr<…>`).

### Call-site expansion

A call to a template function (`-> @Expr<…>`) is expanded at comptime; the
expansion replaces the call and is re-type-checked in the caller's context.
Template functions never reach codegen.

```botopink
pub fn html(comptime template: @Expr<string>) -> @Expr<string> {
    return template;
}
val name = "world";
val page = html """
<p>${name}</p>
""";
```

**Generates:**
```javascript
const name = "world";
const page = (("\n<p>" + name) + "</p>\n");
```

- **Bounded** `-> @Expr<T>`: the expansion is verified against `T`; the call
  types as `T` (`page` above is `string`, not `@Expr<string>`).
- **Generic** `-> @Expr<T>` (unconstrained `T`): for when the signature
  *cannot* state the type — the expansion reveals it per call site (the yaml
  case):

```botopink
pub fn conf<T>() -> @Expr<T> {
    return @code("8080");   // the type comes from the generated code
}
val n = conf();      // n: i32 — revealed by the expansion
val m = n + 1;       // ok
```

### Anonymous record literals and the yaml model

`record { name: value, … }` builds an anonymous **structural** record in any
expression position (at top level, `val X = record { … }` is the named-record
declaration shorthand — parenthesize the literal there). Field access is
fully typed; an unknown field is a compile error:

```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    return @expr(record { port: 8000 + t.length, debug: true });
}
val cfg = conf "yaml";
val p = cfg.port + 1;     // ok: i32 — structure revealed at expansion
// cfg.prot               // COMPILE ERROR: 'record' has no field 'prot'
```

**Generates:**
```javascript
const cfg = ({ port: 8004, debug: true });
```

Records unify structurally (same field set, field types unify — V1, no width
subtyping yet); they lower to JS objects and Erlang maps.

### V1 limits

- The expansion driver handles bodies of the form `return <@Expr param>`,
  `return @expr(value)`, or `return @code("…")` with a literal string.
  Template-method bodies (`text`/`parts`/`lookup`/`build`) require the
  runtime-backed evaluator (planned).
- Template arguments must be literal strings; template functions are not
  first-class values; expressions only (no declaration-generating macros);
  cross-module template functions do not expand yet.

---

## Function Specialization

### Simple function body without loop

```botopink
fn execute(comptime slug: string, input: i32) -> i32 {
    return input + 0;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
    val r3 = execute("calc", 5);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
    const r3 = execute_$0(5);  // reuses $0 (slug="calc")
}

/**
 * Specialization execute_$0
 * slug: calc
 */
function execute_$0(input) {
    return (input + 0);
}

/**
 * Specialization execute_$1
 * slug: noop
 */
function execute_$1(input) {
    return (input + 0);
}
```

### Distinct string args generate specialized functions

```botopink
fn build(prefix comptime: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("WARN", "Memória alta");
    val r3 = build("INFO", "Log replicado");
}
```

**Generates:**
```javascript
function main() {
    const r1 = build_$0("Sistema iniciado");
    const r2 = build_$1("Memória alta");
    const r3 = build_$0("Log replicado");  // reuses $0 (prefix="INFO")
}

/**
 * Specialization build_$0
 * prefix: INFO
 */
function build_$0(name) {
    return ("INFO" + ": " + name);
}

/**
 * Specialization build_$1
 * prefix: WARN
 */
function build_$1(name) {
    return ("WARN" + ": " + name);
}
```

### Distinct integer args generate specialized functions

```botopink
fn multiply(comptime factor: i32, x: i32) -> i32 {
    return x * factor;
}

fn calculate() {
    val double = multiply(2, 21);
    val triple = multiply(3, 21);
    val doubleAgain = multiply(2, 10);
}
```

**Generates:**
```javascript
function calculate() {
    const double = multiply_$0(21);
    const triple = multiply_$1(21);
    const doubleAgain = multiply_$0(10);  // reuses $0 (factor=2)
}

/**
 * Specialization multiply_$0
 * factor: 2
 */
function multiply_$0(x) {
    return (x * 2);
}

/**
 * Specialization multiply_$1
 * factor: 3
 */
function multiply_$1(x) {
    return (x * 3);
}
```

### Same string arg reuses specialized function

```botopink
fn build(comptime prefix: string, name: string) -> string {
    return prefix + ": " + name;
}

fn main() {
    val r1 = build("INFO", "Sistema iniciado");
    val r2 = build("WARN", "Memória alta");
    val r3 = build("INFO", "Log replicado");
}
```

**Generates:**
```javascript
function main() {
    const r1 = build_$0("Sistema iniciado");
    const r2 = build_$1("Memória alta");
    const r3 = build_$0("Log replicado");  // ← same $0 as r1
}
```

### Comptime val used as specialization argument

```botopink
val base = comptime 10 + 5;

fn scale(comptime factor: i32, value: i32) -> i32 {
    return value * factor;
}

fn main() {
    val doubled = scale(2, base);
    val tripled = scale(3, base);
    val doubledAgain = scale(2, 100);
}
```

**Generates:**
```javascript
const base = 15;

function main() {
    const doubled = scale_$0(15);
    const tripled = scale_$1(15);
    const doubledAgain = scale_$0(100);  // reuses $0
}

function scale_$0(value) {
    return (value * 2);
}

function scale_$1(value) {
    return (value * 3);
}
```

---

## Loop Unrolling

### Single if condition resolved per element

```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

/**
 * Specialization execute_$0
 * slug: calc
 */
function execute_$0(input) {
    let output = 0;
    output = (input * 2);  // ← loop unrolled, if folded for "calc"
    return output;
}

/**
 * Specialization execute_$1
 * slug: noop
 */
function execute_$1(input) {
    let output = 0;
    output = input;  // ← loop unrolled, if folded for "noop"
    return output;
}
```

### Nested if-else chain fully folded

```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            if (cmd == "calc") {
                output = input * 2;
            } else if (cmd == "noop") {
                output = input;
            };
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

function execute_$0(input) {
    let output = 0;
    output = (input * 2);  // ← nested if-else fully folded
    return output;
}

function execute_$1(input) {
    let output = 0;
    output = input;
    return output;
}
```

### Case expression folded inside unrolled loop

```botopink
val COMMANDS = comptime ["calc", "noop", "help"];

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = case cmd {
                "calc" -> input * 2;
                "noop" -> input;
                _ -> 0;
            };
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

function execute_$0(input) {
    let output = 0;
    output = (input * 2);  // ← case folded: cmd="calc" matched
    return output;
}

function execute_$1(input) {
    let output = 0;
    output = input;  // ← case folded: cmd="noop" matched
    return output;
}
```

### Runtime array loop preserved, comptime param specialized

```botopink
val COMMANDS = ["calc", "noop", "help"];  // NOT comptime

fn execute(comptime slug: string, input: i32) -> i32 {
    var output = 0;
    loop (COMMANDS) { cmd ->
        if (cmd == slug) {
            output = input * 2;
        };
    };
    return output;
}

fn main() {
    val r1 = execute("calc", 10);
    val r2 = execute("noop", 42);
}
```

**Generates:**
```javascript
function main() {
    const r1 = execute_$0(10);
    const r2 = execute_$1(42);
}

/**
 * Specialization execute_$0
 * slug: calc
 */
function execute_$0(input) {
    let output = 0;
    for (const [cmd] of Object.entries(COMMANDS)) {
        if (cmd === "calc") {  // ← slug baked in, loop preserved
            output = (input * 2);
        }
    }
    return output;
}

/**
 * Specialization execute_$1
 * slug: noop
 */
function execute_$1(input) {
    let output = 0;
    for (const [cmd] of Object.entries(COMMANDS)) {
        if (cmd === "noop") {  // ← slug baked in, loop preserved
            output = (input * 2);
        }
    }
    return output;
}
```

---

## Delegates

### Emits comment

```botopink
declare fn Callback(msg: string) -> void;
```

**Generates:**
```javascript
// delegate Callback
function Callback(msg) { /* implemented elsewhere */ }
```

---

## Implement

### Attaches methods to prototype

```botopink
interface Printable {
    fn print(self: Self),
}
record Person { name: string }
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) {
        return self.name;
    }
}
```

**Generates:**
```javascript
// interface Printable
//   fn print(...)

class Person {
    constructor(name) {
        this.name = name;
    }
}
```

### Generic interface

The standalone `implement <Iface> for <Type>` form accepts a **generic**
interface (`Iface<A, B>`, including the builtin `@Context<…>`), not just a bare
identifier:

```botopink
record E { tag: string }
val C = implement @Context<E, E> for E {}
val D = implement Foo<E, E> for E {}
```

### Inline `struct implement` with fields

A `struct implement <Iface> { fields }` carries fields like a `record`, and any
field type is allowed — including array-typed (`E[]`), optional, and generic
fields. The value emits a real constructor, so its fields round-trip at runtime:

```botopink
val E = struct implement @Context<E, E> { tag: string, children: E[] }
fn mk() -> E {
    return E(tag: "x", children: []);
}
```

**Generates:**
```javascript
class E {
    constructor(tag, children) {
        this.tag = tag;
        this.children = children;
    }
}
```

---

## Destructuring

### Record val binding

```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    return x;
}
```

### Record parameter in fn

```botopink
record Person { name: string, age: i32 }
fn greet({ name, age }: Person) -> string {
    return name;
}
```

---

## Arrays and Tuples

### Array literal

```botopink
val items = ["a", "b", "c"];
```

### Empty array

```botopink
val empty: i32[] = [];
```

---

## Compiler Improvements (v0.0.11-beta)

### Allocator Consistency

All compiler components now follow a consistent pattern: **allocator is never stored, always passed as parameter**.

**Before:**
```zig
pub const Parser = struct {
    allocator: std.mem.Allocator,  // stored
    // ...
};
pub fn init(tokens: []const Token, allocator: std.mem.Allocator) Parser { ... }
```

**After:**
```zig
pub const Parser = struct {
    // no allocator field
    // ...
};
pub fn init(tokens: []const Token) Parser { ... }
pub fn parse(this: *This, alloc: std.mem.Allocator) ParseError!Program { ... }
```

This pattern applies to:
- `Parser` — `init(tokens)`, all methods receive `alloc` as first parameter
- `Lexer` — `init(source)`, `scanAll(alloc)`, `deinit(alloc)`
- All codegen functions — `alloc: std.mem.Allocator` as first parameter name
- All Emitter structs — `alloc` passed in `init()`, used consistently

### Code Reduction via Helper Functions

**Binary operator emission** (commonJS.zig, erlang.zig):
```zig
// Before: 14 operators × 6 lines = 84 lines
.add => |b| {
    try self.w("(");
    try self.emitExpr(b.lhs.*);
    try self.w(" + ");
    try self.emitExpr(b.rhs.*);
    try self.w(")");
},
// ... 13 more

// After: 1 helper + 14 single-line calls = 28 lines
fn emitBinaryOp(self: *Emitter, op: []const u8, lhs: *ast.Expr, rhs: *ast.Expr) !void {
    try self.w("(");
    try self.emitExpr(lhs.*);
    try self.w(" ");
    try self.w(op);
    try self.w(" ");
    try self.emitExpr(rhs.*);
    try self.w(")");
}

.add => |b| try self.emitBinaryOp("+", b.lhs, b.rhs),
.sub => |b| try self.emitBinaryOp("-", b.lhs, b.rhs),
// ... 12 more
```

**Parser helpers:**
- `boxExpr(alloc, expr)` — replaces repetitive `allocator.create(Expr)` pattern
- `parseStmtListInBraces(alloc)` — replaces duplicate `parseBraceBlock` function
- `parseCommaSeparatedIdentifiers(alloc, stopAt)` — reusable for extends, imports, etc.
- `reportReservedWordError()` — centralized reserved word error creation

**Total savings:** ~122 lines of repetitive code eliminated.

---

## Result & Option methods

`@Result<R, E>` and the optional type `?T` carry a small builtin method API.
The methods are resolved by type inference and lowered inline by each codegen
backend — they are not runtime library functions. `?T` is the ONLY spelling of
the optional type: optional is not a concrete named type, and the nominal forms
`@Option<T>` / `@Optional<T>` are rejected with a pointed diagnostic.

### `@Result<R, E>`

| Method | Signature | Behaviour |
|---|---|---|
| `map`      | `fn(R) -> R2` → `@Result<R2, E>`          | Apply to the `Ok` payload; an `Error` is propagated untouched. |
| `flatMap`  | `fn(R) -> @Result<R2, E>` → `@Result<R2, E>` | Like `map`, but the function returns a Result (no nesting). |
| `unwrapOr` | `(default: R) -> R`                       | The `Ok` payload, or `default` on `Error`. |
| `isOk`     | `() -> bool`                              | `true` when the receiver is `Ok`. |
| `isError`  | `() -> bool`                              | `true` when the receiver is `Error`. |

### `?T`

| Method | Signature | Behaviour |
|---|---|---|
| `map`      | `fn(T) -> T2` → `?T2`                     | Apply to the present value; absence is propagated. |
| `flatMap`  | `fn(T) -> ?T2` → `?T2`                    | Like `map`, but the function returns an optional. |
| `unwrapOr` | `(default: T) -> T`                       | The present value, or `default` when absent. |

### Example

```botopink
fn parseAge(s: string) -> @Result<i32, string> { @todo(); }
fn validate(n: i32) -> @Result<i32, string> { @todo(); }

fn main() {
    val age = parseAge("42")
        .map({ n -> n + 1 })            // @Result<i32, string>
        .flatMap({ n -> validate(n) })  // @Result<i32, string>
        .unwrapOr(0);                   // i32

    val ok = parseAge("42").isOk();     // bool
}
```

**Codegen coverage:** `commonJS` and `erlang` emit the full inline form (a tag
match for Result, a presence check for Option). `beam` and `wasm` emit a
documented stub — these targets have no Result runtime representation yet.

## Test Blocks

First-class `test` declarations, modeled on Zig: tests live next to the code,
are collected at compile time, and run with `botopink test`. Anonymous and
named forms:

```botopink
test {
    assert 1 + 1 == 2;
}

test "addition works" {
    val r = 2 + 3;
    assert r == 5;
}
```

Grammar (top-level declaration only — `test` inside a `fn` body is a parse
error):

```text
testDecl ::= "test" string? block
```

- The optional string literal names the test; the anonymous form has none.
- The body is the same statement block used by `fn` bodies.
- `assert cond` / `assert cond, "message"` fails the enclosing test. It is the
  existing expression-level `assert` — usable broadly, but only `test` blocks
  are collected by the runner.
- Test blocks are **excluded** from normal `build`/`run` output; they are only
  compiled under `botopink test`.

Running:

```bash
botopink test                    # compile + run every test block in the project
botopink test --filter "split"   # only tests whose name contains the substring
```

```text
running 3 tests
  ok   addition works
  FAIL map doubles  (map should double each element)  at main.bp:12
  ok   test_2
2 passed, 1 failed
```

**Status:** parser/AST/formatter/inference landed; `botopink test` runs on the
`commonJS` (node) and `erlang` (escript) targets. The WASM runner is a pending
phase of the `test-blocks` spec (`tasks/v0.beta.2/specs/test-blocks.md`).

---

## Annotations & `external`

A declaration may be preceded by an **annotation block** `#[ … ]` holding one
or more comma-separated annotation calls. Annotations are not parser keywords —
each entry is a normal call type-checked against its signature; builtin
annotations are `@`-prefixed (`@external`, …) and resolve against `builtins.d.bp`
(the older `@[ … ]` block delimiter is still accepted):

```botopink
#[@external(erlang, "string", "length"),
  @external(node, "./gleam_stdlib.mjs", "string_length")]
pub fn str_length(s: string) -> i32
```

### `external(target: Target, module: string, symbol: string)`

`external` is the FFI primitive: it binds a function to a host symbol per
compilation target. `Target` is `enum { node, typescript, erlang, beam, wasm }`.

- A `pub fn` annotated with `external` needs **no body** — it is typed from
  the signature alone (like a `.d.bp` declaration).
- Each backend lowers calls to its target's symbol:
  - Erlang: `str_length(s)` → `string:length(S)`
  - Node/CommonJS: emits `const { string_length: str_length } = require("./gleam_stdlib.mjs");`
    and calls `str_length(s)`
- Calling an external fn on a backend with **no matching target** is a
  codegen error (`MissingExternalTarget`).
