# Botopink language reference

This reference describes the language as the compiler accepts it today. Every
`botopink` fence here is compiled by `zig build test-docs`. A table, a grammar or
a layout sample is not code and is fenced as `text`; a `botopink` fence that is
a statement list, one file of a project or a refusal says so in a `docs-check`
comment.

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
import {geometry.area};
import {shapes.describe};

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

#### A module's default function

A module may have one **default function**, which its importer names
(decision 289). `pub default fn (…) -> R { … }` binds no name in its own
module; `pub default <name>;` makes a function the module declares its default
(it keeps its name there, e.g. for a recursive call); `pub default fn
Name(…)` is the shorthand of both. `import {m.card};` — whose path names the
module, not an item of it — binds the default under the path's last segment,
`import {m.card as Card};` under the alias. A decorator on an anonymous
default reads the file's name as `decl.name`. A second default is
`default-twice`; `pub default nope;` naming no function is `default-unknown`.

<!-- docs-check: project default_fn src/main.bp -->
```botopink
// src/main.bp
pub mod m;
import {m.double};
import {m.tree as Tree};

fn main() {
    @print(double(4));    // 8
    @print(Tree(1));      // node(leaf)
}
```

<!-- docs-check: project default_fn src/m/mod.bp -->
```botopink
// src/m/mod.bp
pub mod double;
pub mod tree;
```

<!-- docs-check: project default_fn src/m/double.bp -->
```botopink
// src/m/double.bp
pub default fn (x: i32) -> i32 {
    return x * 2;
}
```

<!-- docs-check: project default_fn src/m/tree.bp -->
```botopink
// src/m/tree.bp
fn Tree(depth: i32) -> string {
    if (depth == 0) return "leaf";
    return "node(" + Tree(depth - 1) + ")";
}

pub default Tree;
```

### Imports

`from "<name>"` names a **package** — std or a dependency declared in
`botopink.json` — and nothing else (decision 206). A module of the importing package is imported by its path
inside the braces, with no `from`; and an import that names no module at all is
the shorthand, which resolves the sibling module that exports the names.

<!-- docs-check: project imports src/main.bp -->
```botopink
// src/main.bp
import {math} from "std";              // a module of the std package
import {geometry.area};                // a module of this package, by its path
import {shapes.circle.name};           // a nested module path
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

`from` never names a module of this package. Beside a module named like a
package, the brace form reaches the module and `from` the package:

<!-- docs-check: project import_with_from src/main.bp -->
```botopink
// src/main.bp
pub mod log;
import {log.levelName as ownLevel};    // this package's module `log`
import {Level, levelName} from "log";  // the dependency `log`

pub fn main() {
    @print(ownLevel(2));               // own:2
    @print(levelName(Level.Warn));     // warn
}
```

<!-- docs-check: project import_with_from src/log.bp -->
```botopink
// src/log.bp
pub fn levelName(level: i32) -> string {
    return "own:" + level.toString();
}
```

<!-- docs-check: project import_with_from botopink.json -->
```json
{
  "name": "app",
  "version": "0.0.1",
  "src": "src/",
  "target": "commonJS",
  "dependencies": {
    "log": { "git": "https://github.com/botopink/log.git", "branch": "feat" }
  }
}
```

A package wins its name: `from "log"` is the dependency `log` although the package
has a module `log` of its own, so a dependency declared later never changes
what an existing import means — an import that could have meant the module is
already the brace form. `from` naming a module of the package is refused at the
source string, and the refusal writes the import as it is spelled instead
(over the `imports` project above; pinned by
`tests/language/modules/import_own_module_with_from`):

```text
// src/main.bp
import {area} from "geometry";

error[module-import-with-from]: "geometry" is a module of this package — write import {geometry.area};
 --> src/main.bp:1:20
```

**A module is its package plus its path** (decisions 170, 337). Two packages may each
hold a module of one name — a CSS library's `theme` and a component library's `theme` — and
they are two modules: inside the first, `import {theme.Ns};` names its own `theme`, inside
the second its own, and a project's `theme` is a third. Neither import is ambiguous, and
neither `Ns` is ever read as the other's — in the checker, in every backend's module names
and calls, in the `.d.ts` and at compile time. The shorthand inside a dependency resolves
among that package's modules only. Pinned by
`tests/language/modules/two_packages_one_module_name`.

**A path and a group are one tree, and only the leaf enters scope.** An item
may walk into a module (`shapes.circle.name`), and several items under one
prefix may be grouped (`shapes: {circle: {name}, helpers: {seven}}`) — both
spellings bind exactly the same names: `a: {b: {c}}` is `a.b.c`. The dot serves
one leaf, the braces several under one prefix, and `botopink format` flattens a
group into its dotted leaves — `collections: {Dict as D, lt}` is printed
`collections.Dict as D, collections.lt`. What an item binds is its **leaf** — `name`,
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
parseJson}`). One item that reaches two declarations — a bare `import {parse};`
while two modules of the package declare `pub fn parse` — is not refused itself:
every **use** of the name is, where it is written, naming both
(`ambiguous-import-use`), and the item that says which (`import {a.parse}`) is
the way out. An alias reaches a type and a type alias too (decision 110):
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
| the root (pure) | `collections` (`Dict`, `Set`, `Queue`, `Order` — a constructor is called on its type: `Dict.empty()`, `Dict.ofEntries([#("a", 1)])`, `Set.fromList(xs)`), `math`, `path`, `url`, `querystring`, `json`, `regex`, `unicode`, `string_builder`, `encoding`, `hash`, `escape`, `async`, `bpp` (the four annotations a framework marks its `.bpp` roles with — `#[bpp.html]`, `#[bpp.style]`, `#[bpp.htmlPrelude]`, `#[bpp.stylePrelude]` — and `Prelude`, decision 361); `erlang` and `beam` (the target's surface) |
| `io` | `io.fs`, `io.http`, `io.net`, `io.clock`, `io.random`, `io.os`, `io.env`, `io.process` |
| `testing` | `testing.asserts`, `testing.mocks` (`testing.snapshots` is the `snap` library, decision 391) |

```botopink
import {collections: {Dict, Set}, io: {fs, clock}, testing.asserts} from "std";
```

**What is generic lives in std, once.** A primitive several libraries need —
reading a number out of text, walking a decoded JSON value, a retry loop — is
std's, and a library calls it rather than writing its own:

| Where | What | Answers |
|---|---|---|
| a `string` | `s.parseInt()` | `@Result<i64, string>` — an optional `+` / `-` and digits, the whole string; anything else (`"4 2"`, `"42x"`, `"0x2A"`, `""`) is an `Error` naming the input, and so is an integer beyond ±(2^53 − 1), the range every target counts exactly |
| a `string` | `s.parseFloat()` | `@Result<f64, string>` — a sign, digits, an optional `.` with digits on both sides, an optional exponent; `.5`, `1.`, `NaN`, `Infinity` are an `Error`, an overflow too; the nearest `f64`, the one `json.decode` answers |
| a `string` | `s.indexOf(x)`, `s.lastIndexOf(x)` | an index `s.at` and `s.slice` take, on every target (`-1` when absent) |
| `json.Json` | `v.kindName()`, `v.isObject()`, `v.members()`, `v.field(key)`, `v.str()`, `v.items()` | the readers of a decoded value: `members` and `items` are `[]`, `str` is `""` and `field` is `null` for a value of another kind — none throws |
| `hash` | `pbkdf2Sha256(password, salt, iterations, length)` | `length` bytes of PBKDF2-HMAC-SHA256 as unpadded base64url; the password and the salt are text |
| `io.clock` | `parseDuration(text)` | `@Result<i64, string>` — the milliseconds of digits and one unit, `ms` `s` `m` `h` `d` (`"30s"` is `30000`); `"30"`, `"1.5s"`, `"30 s"`, `"30S"` are an `Error` |
| `async` | `RetryPolicy(maxAttempts, initialMillis, multiplier, maxMillis)`, `nextDelay(policy, attempt)`, `retry(policy, work)` | `nextDelay` is `?i64` — `initialMillis × multiplier^(attempt − 1)`, never above `maxMillis`, `null` past `maxAttempts`; `retry` runs a `fn() -> @Task<@Result<T, E>>` until it answers `Ok` and answers the last `Error` when every attempt failed |
| `io.fs` | `walk(root)`, `glob(pattern, root)`, `removeTree(path)` | relative, `/`-separated, sorted paths, the same for every spelling of the root; a dangling link under `walk` is an `Error` naming it; `glob`'s `*` and `**` do not match a name starting with `.` unless the segment writes the dot, and do not descend through a link to a directory |

```botopink
import {json, hash, async, io.clock} from "std";
import {json.Json, async.RetryPolicy} from "std";

fn main() {
    val port = "8080".parseInt();                       // Ok(8080)
    val ratio = "2.5e-1".parseFloat();                  // Ok(0.25)
    @print(port.isOk() && ratio.isOk());
    val doc = json.decode("{\"name\":\"ada\",\"tags\":[\"x\"]}")
        .unwrapOr(Json.Null);
    val name = doc.field("name");
    @print(if (name != null) name.str() else doc.kindName());   // ada
    @print(doc.members().length);                       // 2
    @print(clock.parseDuration("30s").isOk());          // true — 30000 ms
    @print(hash.pbkdf2Sha256("password", "salt", 1, 32));
    val policy = RetryPolicy(3, 100, 2.0, 1000);
    @print(async.nextDelay(policy, 4) == null);         // true — 100, 200, 400, then none
}
```

A library is imported the same way, under the name `botopink.json` declares it
in `dependencies`:

<!-- docs-check: project library src/main.bp -->
```botopink
import {of, erika} from "erika";   // a library dependency
```

<!-- docs-check: project library botopink.json -->
```json
{
  "name": "app",
  "version": "0.0.1",
  "src": "src/",
  "target": "commonJS",
  "dependencies": {
    "erika": { "git": "https://github.com/botopink/erika", "branch": "feat" }
  }
}
```

**std is the one package the compiler ships.** Every other library — the ones
both halves of an application run included: `routing` (the route matcher, the
route-table / `k` / `z` / URL-rule wires, the `nav:` navigation signals, the
`:param` grammar), `actions` (the server-action protocol), `validation`
(constraints, `#[validated]`, the violation report), `http` (the codecs of HTTP
semantics) and `log` (levels, renderers, the error digest) — is a repository of
its own, declared in `dependencies` like `erika` above:

<!-- docs-check: project shared src/main.bp -->
```botopink
import {match.matchPath, table.parseTable} from "routing";
import {envelope.writeEnvelope} from "actions";
import {decorators.validated} from "validation";
```

<!-- docs-check: project shared botopink.json -->
```json
{
  "name": "app",
  "version": "0.0.1",
  "src": "src/",
  "target": "commonJS",
  "dependencies": {
    "routing": { "git": "https://github.com/botopink/routing.git", "branch": "feat" },
    "actions": { "git": "https://github.com/botopink/actions.git", "branch": "feat" },
    "validation": { "git": "https://github.com/botopink/validation.git", "branch": "feat" }
  }
}
```

Without the entry, `from "routing"` is refused where it is written:
`unresolved import source "routing" — declare it in botopink.json "dependencies"`.
Listing `std` in `dependencies` is refused too — the compiler's copy is the one a
program gets.

A `from` that names neither a module of this package, nor a declared
dependency, nor std is an error — it is reported where it is
written, rather than binding nothing in silence.

## Bindings

A keyword is reserved in every position: no binding, parameter or field may
take its name (`from`, `type`, `case`, …). Writing one where a name is declared
is `reserved-word-as-name`, which names the word.

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

A `val` is immutable: assigning to it — a local or a module-level `val`, from
any `fn` body — is a compile-time error. The rule is the same one node already
enforced at run time (`const`); it now holds on every target before any code
is emitted.

```botopink
val x: i32 = 0;
// x = 1;   error: `x` is a `val` and cannot be assigned
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

A `pub val` is imported like a `pub fn` — `import {config.port};` — and
may hold any type: a record, an enum, an array, a primitive, a function. The
bodies of the modules a program imports run before its own, dependencies first,
each once.

### var — mutable binding

A `var` may be reassigned. Inside a `fn` it is a local; at module level it is
**one value per execution context** — the whole program on commonJS and wasm,
the **process** on erlang and beam. Two writes through a `fn` and one read
print `2`:

```botopink
var hits: i32 = 0;

pub fn bump() { hits = hits + 1; }

pub fn main() { bump(); bump(); @print(hits); }
```

On the BEAM the annotation `#[@BeamMemory.<member>]` widens where a module `var`
lives beyond the process (§ `@BeamMemory`). Off the BEAM the annotation is
refused where it is written — ``error: `#[@BeamMemory]` has no meaning on the
commonJS backend`` — because a target with one execution context has no BEAM
storage to name; a `var` there is one value for the whole program. A
hand-written `import { beam } from "std"` — the host primitives themselves — is
`std-unsupported-on-target` there for the same reason (decisions 43, 167).

### @BeamMemory — where a module var lives on the BEAM

`#[@BeamMemory.<member>]` above a module `var` names its memory on erlang and
beam. The member is one of `ProcessDict` (the default, which a bare `var`
already means — writing it out loud records the choice where it is read), `Ets`
or `PersistentTerm`. The only argument is `keyed: true | false`, default
`false`, and it is a `Dict`-only argument: an `i32` has no key and neither has a
list, which stores its whole value. Every part is checked at `botopink check`,
in a project whose target is erlang or beam:

<!-- docs-check: project beam_memory src/main.bp -->
```botopink
import {collections.Dict} from "std";

#[@BeamMemory.ProcessDict]        var explicit: i32 = 0;   // the default, said out loud
#[@BeamMemory.Ets]                var hits: i32 = 0;
#[@BeamMemory.PersistentTerm]     var buildVersion: i32 = 101;
#[@BeamMemory.Ets(keyed: true)]  var counts: Dict<string, i32> = Dict.empty();

// #[@BeamMemory.Etz] var x: i32 = 0;
//   error: unknown member `Etz` in `@BeamMemory` — expected `ProcessDict`, `Ets` or `PersistentTerm`
// #[@BeamMemory.Ets(keyd: true)] var x: i32 = 0;
//   error: unknown argument `keyd` — expected `keyed`
// #[@BeamMemory.Ets(keyed: true)] var n: i32 = 0;
//   error: `keyed` needs a keyed container — an `i32` has no key
// #[@BeamMemory.Ets] val x: i32 = 0;
//   error: `#[@BeamMemory.Ets]` needs a `var` — `x` is a `val`
```

<!-- docs-check: project beam_memory botopink.json -->
```json
{ "name": "app", "version": "0.0.1", "src": "src/", "target": "erlang" }
```

**`ProcessDict`** — one value per BEAM process, in the process dictionary: no
setup, no owner, erased when the process ends. It is what a bare `var` means,
and the spelling exists so that a file whose other bindings are `Ets` can say
"per-process, on purpose" where it is read. A request handler that counts under
`ProcessDict` counts its own requests only.

**`Ets`** — one value per node, in a named public ETS table the module owns
through a registered owner process, so the table survives the process that
first touched it and is re-created and re-seeded from the declaration if the
owner dies. `hits += 1` and `hits = hits + 1` on an `i32` or `i64` are one
atomic `ets:update_counter`; any other read-modify-write — `hits = hits * 2 +
1`, or `+=` on an `f64`, `bool` or `string` — is refused, because two processes
running it would lose one of the two writes. The initialiser must be a literal
or a `comptime` expression: it is re-run at a moment nobody chose. **`Ets` is
cache and counting memory, not where the truth lives** — a balance, an order, a
paid session belong in a supervised process or a database. Under **`keyed:
false`** (the default) a `Dict` is stored as **one** value: a write copies the
whole dict, and two processes writing *different* keys at the same time lose one
of the writes — measured, 20 000 writes each to two keys finished at `19 996`
and `20 000`. Under **`keyed: true`** each key is its own row: the seed is
`Dict.empty()` or `Dict.ofEntries([#("a", 1)])` of literals, a row is read as
`counts.at(k)` and written as `counts = counts.insert(k, v)`, and nothing else
names the var — measured, two processes writing 20 000 times each to their own
key finish at `20000` and `20000`; at 10 keys a write is 5× cheaper, at 10 000
keys 5 000×. Choose `keyed: true` whenever more than one process writes; keep
the default when the dict is replaced whole.

**`PersistentTerm`** — one value per node, written **once, at load**, read
everywhere for the cost of a function call. A write after load is a
compile-time error whose hint points to `#[@BeamMemory.Ets]`: at run time
a `persistent_term:put` scans every process heap (measured, 810 ns against
17 ns for a read), and the module's load hook **re-runs on every hot code
reload**, so a run-time write would be erased by the next reload anyway. It is
the mode for a routes table, a scanned-component list, configuration read at
bootstrap — anything the decorators emit at load and nothing changes
afterwards. Store a handler by **name**, not as a function value: a `fun`
belongs to the module version that created it and dies with it on reload.

### fn — function

```botopink
fn add(x: i32, y: i32) -> i32 {
    return x + y;
}
```

A value leaves a function through `return`: a block is a statement, not a value, so a `fn` whose
return type has a value must end every path with `return` (or `@panic` / `@todo`) —
`fn f() -> i32 { val x = 1; }` is refused at `-> i32`. An effect return is judged by what
running off the end would hand out: a `@Result` in any layer has a value (`Ok` or `Error`), so
`-> @Result<void, E>` and `-> @Task<@Result<void, E>>` end with the empty `return;`, and so does a
`@Task<T>` or `@Component<T>` whose `T` is a value; one whose `T` is `void` falls through as a
`void` fn does. `@Iterator` and `@Stream` end by running off their body.

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

A record is immutable: a field is never assigned. A changed copy is the update
form — `..base` and the fields that change, by label; every other field is read
from `base`, which is a name or a path of names (a call there is refused, since
it would run once per copied field — bind it with `val` first):

```botopink
type Point(x: i32, y: i32)

val p = Point(x: 1, y: 2);
val q = Point(..p, y: 5);    // Point(x: 1, y: 5)
```

A body adds methods:

```botopink
type Counter(n: i32) {
    fn current(self: Self) -> i32 {
        return self.n;
    }
}
```

`self` is the receiver of a method, and names nothing else: a parameter called
`self` is written only in a `type`, `behavior`, `implement` or `extend` body.
A free function that names one is `self-param-outside-type`, refused at the
name.

The field list is always written. A record with no fields is `type Name()`,
and with members `type Name() { … }`; braces holding variants declare an enum,
and braces holding only associated functions (none taking `self`) declare a
**namespace type** (decision 329) — `type Name { fn make() -> i32 { … } }`,
called `Name.make()`, with no value: `Name()` is `namespace-type-construction`
and a `self` function in it `namespace-type-self`. A `type` declared in a type's
body is its associated type, named `Owner.Name` (decision 330). `type Name {}` is
`type-without-field-list`, refused where the `()` belongs:

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

A variant name is declared once per level of the body (`enum-variant-duplicate`
at the second). The same name at two levels is two members, told apart by the
path and by the position's expected type: with `Layout { Break { After } }`
beside `After(inner: Token[])`, `Token.After(…)` — and `.After(…)` where a
`Token` is expected — is the payload variant, `.After` where a
`Token.Layout.Break` is expected is the leaf, and a `case` over a `Token` matches
the top-level `After` while one over the section matches the leaf.

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

Type arguments may be written at a use, adjacent to the name. A function or a
constructor takes them before its call (`first<string>([], "none")`,
`Box<i32>(value: 1)`); a type's name takes them before a member too — a
**type application**: `Dict<string, i32>.empty()` calls `empty` on
`Dict<string, i32>`, and `Slot<i32>.Empty` is that `Slot<i32>`. The list is read
as type arguments only after a type's name (an upper-case first letter) and
only when its `>` is followed by `.` or `(`; anywhere else `<` is a comparison,
so `a < b`, `x < y && z > w` and `f(a < b, c > d)` mean what they say.

```botopink
type Slot<T> { Full(value: T), Empty }

type Box<T>(value: T) {
    pub fn make(v: T) -> Box<T> { return Box(value: v); }
}

fn main() {
    val b = Box<i32>.make(7);
    val o = Slot<string>.Empty;
    @print(b.value);
    @print(o == Slot<string>.Empty);
}
```

Every `comptime` parameter other than `@Decl` is the caller's **expression**,
`comptime x: @Expr<T>` (decision 364) — a decorator's, a template function's,
any function's, a method's, a `declare fn`'s: the argument is checked against
`T` where it is written, and the body reads its value with `x.value`, known
while the program compiles. `comptime x: T` is `comptime-param-not-expr` at the
parameter, naming `@Expr<T>`. `.value` of an `@Expr` of a function is
`expr-value-of-function` and of a type `expr-value-of-type`, at the read: a
function's body is not called and a type not inspected while the program
compiles. A `comptime` parameter's `@Expr` answers `.value` (and, in a
decorator, `.fail(…)`, § Decorators); any other method of it is
`expr-param-method` — the template methods (`text()`, `parts()`, …) are a
template capture's (§ Template functions).

A `comptime` parameter may take **a value or a type** (decision 297):
`comptime source: @Expr<Box<T> | type T>`. A `Box<T>` argument binds `T` from
it; a type argument binds `T` to that type; the body tells them apart with
`source is type`, decided while the program compiles — only the branch taken
is emitted, and where `source is type` holds, reading `source` is
`type-arg-read`. The argument of an ordinary function's `comptime` parameter is
known at compile time: a local or a non-`comptime` parameter is
`comptime-arg-not-known` at the argument.

```botopink
type Box<T>(value: T)

fn orDefault<T>(comptime source: @Expr<Box<T> | type T>, fallback: T) -> T {
    if (source is type) return fallback;
    return source.value.value;
}

fn main() {
    val n: i32 = orDefault(Box(value: 4), 0);    // 4, from the value
    val s: string = orDefault(string, "none");   // "none", T bound to string
    @print(n);
    @print(s);
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
- A `pub` alias is imported like a type (`import {parse.Parser};`); the
  types its target names come with it.
- An alias of an effect wrapper **types** a function and never **activates** the
  effect (decision 118): `-> Parser<i32>` is a function that hands a
  `@Result<i32, ParseError>` value along, and the capabilities (`throw`, `try`,
  `await`, …) are granted only by the wrapper written literally in the return.

### Derived types

```botopink
import {types.Type} from "std";

type Recipe(title: string, description: ?string, servings: i32 = 2)
type Dog(name: string, age: ?i32)
type Breed(breed: string)

pub val RecipeTitle = Type.pick(Recipe, .title);         // type RecipeTitle(title: string)
pub val RecipeBrief = Type.omit(Recipe, .description);   // type RecipeBrief(title: string, servings: i32 = 2)
pub val RecipePatch = Type.partial(Recipe);              // every field `?T`
pub val RecipeFull = Type.required(RecipePatch);         // every `?` goes
pub val DogWithBreed = Type.merge(Dog, Breed);           // Dog's fields, then Breed's

fn titleOf(t: RecipeTitle) -> string { return t.title; }
```

A derived type (decision 307) is a **new** record type answered at build by one
of std's `Type` functions and bound by a module-level `val`, whose name it takes.
It is nominal — `RecipeTitle` in diagnostics and printed values, its own type
for `is` and `case`, never its source's — and usable everywhere a type is
written: a parameter, a return, a field, an annotation, a constructor call
(`RecipeTitle(title: "…")`), an export and an import
(`import {recipes.RecipeTitle};`). Two `val`s over the same call are two types.

- Each field is the source's as declared — its type, its default, its
  annotations (the markers a decorator reads). `partial` makes each field `?T`;
  `required` takes the `?` off each one, and a `null` default with it.
- `pick` keeps the named fields in the order the source declares them; `omit`
  drops them; `merge` lists the first record's fields, then the second's.
- A decorator on the `val` sees a type declaration (`decl.kind` is
  `DeclKind.Type`, `decl.fields` the derived fields):
  `#[validated] pub val RecipePatch = Type.partial(Recipe);`.
- The source is a record — of the module, imported, a local alias of one,
  another derived type (in any order), or a nested call
  (`Type.merge(Type.merge(GlobalAttrs, AriaAttrs), AnchorAttrs)`). From an
  imported record, a field's default that names a binding of its own module does
  not travel (as an imported function's default does not): the field is then
  supplied at every construction.
- The functions are `Type`'s: `import {types.Type} from "std";` (an alias
  included); a bare `partial(Recipe)` is an unbound name.

Refused, each at what it is about: a field written as a string
(`derived-type-field-string`, naming `.title`), a field the source does not
declare (the `Type.Field<T>` error, `unknown field 'titel' on type 'Recipe'`), a
field named twice, `pick` / `omit` with no field or an `omit` leaving none
(`derived-type-fields`), a source that is not a record — an enum, a namespace
type, a primitive, a record with type parameters, an imported alias
(`derived-type-source-not-record`), a field on both sides of a `merge`
(`derived-type-merge-duplicate`: nothing overrides silently, `omit` it first),
the wrong number of arguments or a labelled one (`derived-type-arguments`), and
the call anywhere but as the whole initializer of a module-level `val` without a
type annotation — a local, a `var`, an argument (`derived-type-outside-val`).
`Type.keys(T)` (`Type.Field<T>`, decision 308) is not a record derivation and is
not answered yet.

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

`x is fn(<params>) -> T` narrows an `unknown` to that function type, and a call
through the narrowed name type-checks against it (decision 254) — the form a
catalogue of factories held as `unknown` is read with. Calling an `unknown`
without the test is the refusal above. The run-time check is the **arity**, on
every target, because a function value carries no trace of its parameter or
return types: erlang and beam test `is_function(F, N)`, commonJS `typeof f ===
"function" && f.length === N`, and wasm boxes a function value entering an
`unknown` slot under a descriptor naming its arity and compares that
descriptor. A function of the right arity and another return type passes the
test; what it answers is the caller's to trust.

```botopink
type Clock(zone: string)

fn build(factory: unknown) -> string {
    if (factory is fn() -> Clock) {
        return factory().zone;
    }
    return "not a factory";
}

pub fn main() {
    @print(build({ -> Clock(zone: "UTC") }));
    @print(build(42));
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

```text
42             // i32
3.14           // f64
"hello"        // string
"hi ${name}!"  // string interpolation
true, false    // bool
```

### Numeric literals

A number is decimal (`1_000_000`, `1.5`, `2.5e-3`) or hexadecimal, octal and
binary (`0xFF`, `0o17`, `0b1010`). Without a suffix, a literal with a fraction
or an exponent is an `f64`, and an integer literal takes the integer type its
position asks for (`val k: i64 = 1`, an `i64` argument, the other operand of an
`i64` operator) — `i32` when nothing asks — and must fit it. A suffix, always
lower case, gives the literal its type wherever it stands:

```text
1.5f   2f     // f32          42u    // u32
1.5d   1d     // f64          42ul   // u64
42l           // i64          42u8  42u16  42usize
42i8  42i16  42isize
```

A literal never changes type to fit: an integer literal where a float is
expected is an error, and so is `1.5` where an `f32` is — write `1d` or `1.0`,
and `1.5f`. `f` and `d` go on decimal literals only (in `0x…` they are hex
digits); a radix literal takes an integer suffix (`0xFFul`). An uppercase
suffix (`42L`), letters that are no suffix (`10px`) and an exponent without
digits (`1e`) are refused at the suffix. A number pattern matches a subject of
its own type, and on commonJS an `l` / `ul` literal past 2^53 is refused, since
a double cannot hold it.

<!-- docs-check: body -->
```botopink
val ratio: f32 = 0.5f;
val total: f64 = 10d;
val big = 4_000_000_000ul;
val mask: u8 = 255;
val scaled = total / 4.0;
```

<!-- docs-check: reject the integer literal `1` is not an `f64` -->
```botopink
fn main() {
    val x: f64 = 1;
}
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

```text
a + b, a - b, a * b, a / b, a % b     // arithmetic (+ also concatenates strings)
a == b, a != b, a < b, a > b, a <= b, a >= b
!x, x && y, x || y                    // logical
a |> f                                // pipe: f(a)
x ?? d, x?.field, x?.[i], f?.(args), x!   // optionals (§ Optionals)
```

`/` over two integers is integer division: it truncates toward zero and answers
an integer of the operands' type, on every target (`7 / 2` is `3`, `-7 / 2` is
`-3`). With a float operand it is float division (`7.0 / 2.0` is `3.5`). A number
literal with a `.` or an exponent is a float (`2.5`, `1e3`, `5e-324`).

### Optionals

`?T` is a `T` or `null`, and it has no methods (decision 330): it is read with
TypeScript's five operators.

```text
name ?? "anon"        // the value, or the default when it is null
user?.address         // a member read through it: null when user is
xs?.[0]               // an index through it
callback?.(42)        // a call of the function it holds
name!                 // the value; null aborts: value is null — name! at src/main.bp:3:13
```

Five rules hold them: an operator over a value that is never `null` is a compile
error (`s?.length()` with `s: string`, and the left side of `??`); `?.` flattens —
a member answering `?U` read through `?.` is `?U`, never `??U`; `??` beside `&&`
or `||` takes parentheses (`(a ?? false) && b`); `x!` is checked at run time, a
program error like `@panic`, alike on every target; and `map`, `flatMap` and
`unwrapOr` belong to `@Result` alone (`r.unwrapOr(0)`) — there is no `result`
namespace.

### Numbers

An integer never wraps and never widens. `+`, `-`, `*`, `/`, a unary `-` and
`+=` over `i8`, `i16`, `i32`, `i64`, `u8`, `u16`, `u32`, `u64`, `isize` and
`usize` answer a value of the operands' type, and a result outside the type's
range aborts the program on every target — `2147483647 + 1` on `i32`, `0 - 1`
on `u32`, `-x` of an `i32` at its minimum, `i32`'s minimum `/ -1` (decision
264). The abort names the operator, the type and the place on stderr:

```text
integer overflow: + on i32 at src/main.bp:7:14
```

| Type | Range |
|---|---|
| `i8` / `u8` | −128 … 127 / 0 … 255 |
| `i16` / `u16` | −32768 … 32767 / 0 … 65535 |
| `i32` / `u32` | −2^31 … 2^31 − 1 / 0 … 2^32 − 1 |
| `i64`, `isize` / `u64`, `usize` | −2^63 … 2^63 − 1 / 0 … 2^64 − 1 |

On commonJS an `i64` (and `isize`, `u64`, `usize`) holds the integers a JS
number counts exactly, ±(2^53 − 1): a result past that bound aborts there too,
never a rounded value. An integer `/` or `%` by zero aborts on every target
(commonJS names it `integer division by zero`). A `%` never leaves its type.
No flag turns the check off (decision 67); wrapping arithmetic, where an
algorithm wants it, is written with an explicit operation.

`==` compares by value on every target: two records, tuples, arrays or enum
variants are equal when they have the same type and their fields are equal, field
by field and recursively — `Person(name: "Ana", age: 30) == Person(name: "Ana",
age: 30)` is `true`. Two values of different types are never equal, `!=` is the
negation, and `==` never calls a method of the type (one named `equals` included).
An `f64` compares as a total order under `==`, as Java's `Double.compare` does:
`0.0 == -0.0` is `false` and `NaN == NaN` is `true`, bare or inside a composite;
`<`, `>`, `<=` and `>=` keep the IEEE ordering (`-0.0 < 0.0` is `false`).

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

A lambda's parameters take the types of the position it is passed to or the
`val` it is bound to; `fn(a, b) { … }` is the same function written with
`fn`. The typed form `fn(x: T) -> R { … }` is the member a decorator hands to
`decl.addMember(name, fn…)` alone (§ Decorators, decision 370 (2)); anywhere
else it is `fn-expr-typed`.

The pipe operator `|>` is left-associative.

### Line width

`botopink format` keeps lines within 80 columns where a break exists, and every
construct breaks **all or nothing**: it fits on one line, or each of its parts
takes a line of its own, `+4` from the statement. The outer construct decides
first, so a list never breaks for what follows it:

```text
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
the condition is false and is refused at the `if`. It stands where an expression begins — a `val` /
`var` initializer, the right side of `=`, a `return`, a call argument, a literal's element — and is
never an operand: `1 + if (c) { 2 } else { 3 }`, `-if (c) 1 else 2` and `(if (c) a else b).v` are
`error[if-operand]` at the `if`; bind it first (`val x = if (c) { 2 } else { 3 }; 1 + x`).

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

**Expression role.** `@Component<R>` is the one wrapper of `use` (decisions
104, 118, 128, 354). A function returning it is a **component** when its `R`
implements the marker `@Renderable` (`type Element(…) implement @Renderable`):
a component is **called** (`Widget(1)`, or as a tag), never `use`d. Any other
`@Component<R>` is **read with `use`** — what React calls a hook: `val x = use
<f>(…)` runs it and binds `R`, a bare `use <f>(…);` runs one whose `R` is
`void`, and `val {a, b} = use …` binds `R`'s fields by name. Such a function is
named by its noun (`state`, `effect`, `router`, `pathname` — never
`useState`), because the keyword *is* the activation. The body that `use`s is
itself a `@Component` function — another one read with `use` (they compose) or
a component, which may `await` too. There is no annotation: the return is the
declaration of the effect (decision 118), and there is no base: any
`@Component` may be `use`d in any `@Component` body.

```botopink
type Element(count: i32) implement @Renderable
type State(value: i32, name: string)

// Read with `use`: the noun, the yield.
fn state(initial: i32) -> @Component<State> {
    return State(value: initial, name: "state");
}

// One read with `use` composes others.
fn counter(start: i32) -> @Component<State> {
    val s = use state(start * 2);
    return s;
}

// A component: its `R` implements `@Renderable`, and it may `await` too.
fn Widget(n: i32) -> @Component<Element> {
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

- **Only a `@Component<R>` return grants `use`** (decisions 104 and 118). A
  `use` in any other body — a plain `fn`, a `@Task` one whatever it wraps — is
  refused at the `use`: `` use-without-context-effect: `use` needs a
  `-> @Component<R>` return on the enclosing fn 'Widget' (it returns 'Element') ``.
  Nothing is unwrapped to find one: the server component that awaits and
  uses is `fn Page() -> @Component<Element>`, which the chain lets `await`
  (`@Component ⊃ @Task`). An `async { }` block is not the `@Component` body
  either: `use` is not inherited by it, as `await` is not.
- **The wrapper takes one type argument.** `@Component<C, R>` — decision
  128's base — is refused where it is written, at the base: `` `@Component`
  takes one type argument, `@Component<R>` — its base parameter was removed
  (decision 354) `` (`generic-arg-count-exceeded`). The owner marker
  `@Context<C>` left with it (`context-marker-removed`, naming `implement
  @Renderable`), and `@Renderable` takes no type argument. An aliased return
  (`type Comp<T> = @Component<T>`) types the function but grants nothing
  (`effect-wrapper-behind-alias`).
- **A component never propagates** (decision 121). `throw` and `try` are legal
  in a `@Component` body only when `R` is a `@Result`; a component returns
  `Element`, so it handles a failure in its own body — `try await load() catch
  fallback`, a `case`, a navigation signal or an error screen. A bare `try` there
  is `effect-try-without-fallible-channel`. One read with `use` may return
  `@Component<@Result<T, E>>`, and then its body may `try`.
- **The operand is read with `use`.** `use plain()` where `plain : -> User` is
  `` use-of-non-context-fn: `use` takes a hook: 'User' is not a hook `@Component<R>` ``,
  and `use Card()` where `Card` is a component (its `R` implements
  `@Renderable`) is refused: a component is called, not `use`d.
- **The rules of hooks** (decision 357). A `use` is written at the top level of
  its `@Component` body and runs on every call, in the same order and the same
  number. One inside an `if` / `else`, a `case` arm, a `for` / `while` /
  `loop` (or an `iter` / `stream` loop), a lambda, a `catch` handler, the right
  operand of `&&` / `||` / `??`, or after a statement that may `return`,
  `throw` or `try` early is refused at the `use`, naming what encloses it:
  `` use-not-top-level: `use` inside an `if` / `else` — a `use` is written at the
  top level of a `@Component` body and runs on every call (decision 357) ``. A
  condition goes inside the argument, never around the `use` (the example
  below the list).
- **The type is `R`.** `val c = use state(0)` binds `c : State`, and
  `val {value, set} = use state(0)` binds each name to the field of `R` it
  names. A tuple `R` destructures positionally: with `optimistic : (i32, fn(i32,
  i32) -> i32) -> @Component<#(i32, fn(action: i32) -> i32)>`,
  `val #(shown, push) = use optimistic(12, addLike)` binds `shown : i32` and
  `push : fn(action: i32) -> i32`. The pattern's arity is the tuple's, and the
  `R` has to be a tuple; either failing is refused at the binding —
  `` use-tuple-arity: `val #(…)` binds 1 name(s) but the hook yields a tuple
  of 2 `` and `` use-tuple-arity: `val #(…)` binds 2 name(s) but the hook
  yields 'i32', which is not a tuple `` — with no flag (decision 67).
- **`use` exists only where there is a render tree** (decision 354 (3)). A
  decorator body, a template body and a `comptime { … }` are compile-time
  evaluation with none: `use` there is `use-outside-render-tree`; what they
  need comes from the catalogue (`@TypeInfo.all`, 353).
- **`use` never leaves a function body.** There is no module-level `use` and no
  `use client;` / `use server;` directive (decision 87 of 1.0.10-beta): a
  framework's boundary markers are its own decorators (`#[client]`).

A condition inside the argument is at the top level; around the `use`, it is
refused:

```botopink
import {context.Context, context.provide} from "std";

type Element(text: string) implement @Renderable
type Theme(mode: string)

pub val ThemeContext = Context<Theme>();

fn App(dark: bool) -> @Component<Element> {
    use provide(ThemeContext, if (dark) Theme(mode: "dark") else Theme(mode: "light"));
    return Element(text: "app");
}
```

<!-- docs-check: reject use-not-top-level -->
```botopink
type Element(count: i32) implement @Renderable

fn state(initial: i32) -> @Component<i32> {
    return initial;
}

fn Widget(on: bool) -> @Component<Element> {
    if (on) {
        val n = use state(1);
    }
    return Element(count: 0);
}
```

**Lowering.** `use f(x)` is `f(x)` on erlang, wasm and beam. On commonJS a
`@Component` function whose hooks node is asynchronous (`HookNode.async`,
decision 375 — it writes `await` or `async { … }`, or reaches an asynchronous
hook, component or host task) is an `async function`, and a `use` or call of
it is awaited (`await f(x)`); a synchronous one is a plain `function`, and a
`use` or call of it is not awaited, written or not — `await` stays legal on
any component, a no-op on a synchronous one. A method, a lambda and a
`default fn` answering `@Component` are `async function`s (they have no
node). The prefix is the activation the
checker validated, not a rename: nothing is turned into `useState`, no
dependency array is inferred — a function that takes one declares it as a
parameter (`memo(compute, deps)`). A client runtime supplies hook semantics
through what `f` does; the pure body above is what every backend runs, and what
the server renders.

**Contexts** (decision 354). What a body reads from above it is a context: a
declared object, its identity the declaration (281) — `pub val ThemeContext =
Context<Theme>();` with std's `context.Context`, no default value, and no other
way to make one (`context-not-declared`: a `Context<T>()` that is not a
module-level `val`'s whole initializer, a `val` naming another context, a
context named by a local or a parameter). Two hooks of std's `context` module
work it, `use`d and nothing else (`context-hook-without-use`):

- `use provide(ThemeContext, value);` in a **component's** body gives `value`
  to everything that component renders below it — descendants only, never
  itself or a sibling; the nearest provider wins. In a body whose `R` is not
  `@Renderable` it is `context-provide-outside-component`, and after the body
  rendered a component it is `context-provide-after-render` (that child would
  not see it).
- `val t = use context(ThemeContext);` reads the value provided nearest above
  — a `Theme`; with no provider above it is `context-unbound` at run time.

```botopink
import {context.Context, context.provide, context.context} from "std";

type Theme(mode: string)
type Element(text: string) implement @Renderable

pub val ThemeContext = Context<Theme>();

fn Label() -> @Component<Element> {
    val t = use context(ThemeContext);
    return Element(text: t.mode);
}

fn App() -> @Component<Element> {
    use provide(ThemeContext, Theme(mode: "dark"));
    val l = Label();
    return Element(text: "[" + l.text + "]");
}
```

Every `@Component` function takes a hidden context map (its first parameter,
after `self` on a method): `provide` makes the map its children receive,
`context` looks it up, and a call outside every `@Component` body passes the
empty map (`comptime/context_lower.zig`). A `@Component` lambda written as an
argument of a host function (a bodyless `declare fn`, an `#[@External…]`
binding) takes no map: it reads the map of the body it is written in, as a
closure reads a local, so the host's call — now, later or twice — keeps every
provider above it; a declared component named as such an argument is wrapped
the same way (`hostNow(Page)` passes `{ -> Page() }`), and a lambda's own
parameters stay (decision 374). A lambda handed to a botopink function takes
the map, passed by the call that runs it. erlang, beam and commonJS run it; the
wasm backend refuses a `use provide` / `use context` where it is written, and
a component reached from a `comptime` evaluation does not take the map yet
(`language-gaps.md` row 354-wasm, 354-comptime).

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

### An inline parameter type

A parameter's type may be written in place, with the field grammar of `type
Name(…)` and no name (decision 207):

```botopink
fn link(props: type(href: string, label: string, external: bool = false)) -> string {
    return props.label + " <" + props.href + ">";
}

fn main() {
    @print(link(href: "/a", label: "A"));   // A </a>
}
```

The call builds the value from its own labelled arguments, each naming a field
(a defaulted one may be left out); a value already of the type is passed as the
parameter itself. One parameter of a function may have an inline type, and none
of its fields is named like another parameter. It is a top-level `fn`'s only — a
return, a field, a `val` annotation and a method's parameter refuse it — and it
is not exported: a call from another module that writes its fields is refused.
A diagnostic names it by its owner: ``the props of `link` ``.

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
a free `fn`, on a record's fields (where it is the constructor's default), on a
variant's payload and on a method — including a `behavior`'s `default fn`, which
is where `"hello".slice(1)` gets its open end from (`slice(self, start: i32,
end: ?i32 = null)`). Wherever it is declared, **a default is trailing**: a
parameter or field with a default is followed only by others with defaults
(`fn lead(a: i32 = 1, b: i32)` and `type Port(number: i32 = 80, host: string)`
are refused at `b` and `host`).

```botopink
type Port(host: string, number: i32 = 80) {
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
`Port(number: 8080, host: "a")` reorders to the declaration —
and a parameter with no default is still **required**: leaving one out is the
arity error it has always been.

<!-- docs-check: reject 'connect' expects 2 argument(s), got 0 -->
```botopink
fn connect(host: string, port: i32 = 80) -> string { return host; }

fn main() { connect(); }   // error: 'connect' expects 2 argument(s), got 0
```

Defaults are filled in by the checker, so every backend receives a call with
every argument written out; no backend emits a default of its own.

A label names the parameter it fills on every call — a free function, a
constructor, a method, an associated function (`Box.make(count: 3, label: "b")`),
one imported from another module or reached through a namespace
(`helper.pad(width: 7, s: "q")`) — so the arguments may be written in any order.
A function **value** (a parameter, a local, a field) has a positional type with
no names, so a label in a call of one is refused (`error[label-on-function-value]`).
A pipeline is a call: `x |> f(a)` is `f(x, a)` and `x |> f` is `f(x)`, so it
takes defaults and labels like one (`"w" |> greet(mark: "?")`).

### A variadic parameter

```botopink
fn total(label: string, ..values: i32[]) -> string {
    var sum = 0;
    for (values) { v ->
        sum = sum + v;
    }
    return label + ": " + sum.toString();
}

fn main() {
    @print(total("none"));            // none: 0
    @print(total("three", 1, 2, 3));  // three: 6
}
```

`..name: T[]` as a function's **last** parameter takes zero or more positional
arguments after the fixed ones, each checked against `T`, and the body reads
`name` as a `T[]` (decision 267). It holds for a free `fn`, a method, an
associated function and a `declare fn` alike — `@print`, `@println` and `@debug`
are declared `(..values: unknown[])`. A function has at most one, it is the last
parameter, its type is written `T[]` and it takes no default
(`variadic-not-last`, `variadic-twice`, `variadic-not-array`,
`variadic-default`, at the declaration). Its arguments are positional: a label
on one is `variadic-label`, and there is no spread at a call — a function that
takes an existing array declares `values: T[]`, not `..values`:

<!-- docs-check: reject variadic-spread -->
```botopink
fn total(..values: i32[]) -> i32 { return values.length(); }

fn main() {
    val xs = [1, 2, 3];
    @print(total(..xs));
}
```

The checker packs the arguments into one array, so erlang and beam receive one
list argument and wasm one array; commonJS writes the function with a rest
parameter (`function total(label, ...values)`) and the call with the arguments
one by one, so a host function bound by `#[@External.Node(…)]` receives them as
JavaScript does (`Math.max(3, 9, 4)`), and `#[@External.Erlang(…)]` one list
(`lists:max([3, 9, 4])`).

### Effects

An ordinary function cannot fail, wait, activate hooks or produce a sequence.
To gain one of those capabilities it **writes the wrapper in its return type** —
there is no annotation; the return is the annotation (decision 118):

| Return | The body may write |
|---|---|
| `T` | only `try … catch` (handles the error on the spot) |
| `@Result<T, E>` | `throw` · `try` |
| `@Task<T>` | `await` |
| `@Component<T>` | `use` · `await` |
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
   @Component<T>  ⊃  @Task<T>        use · await
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
(@Result<…>, @Task<@Result<…>>, @Component<@Result<…>>, …) — or handle it
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
E>`) is `effect-return-ambiguous-nesting`, asking which layer is meant: return
the inner value (`return try r;`), or bind the whole value with the declared type
and return that. `Ok(…)` / `Error(…)` are never written as constructors: a
`@Result` is made by `return` and `throw` alone (decision 208) — they are
patterns only (`Ok(n) -> …`).

The quick reference:

| I want… | I write | I call it with |
|---|---|---|
| a function that can fail | `fn f() -> @Result<T, E>` | `try f()` · `try f() catch x` · `case` |
| an asynchronous function | `fn f() -> @Task<T>` | `await f()`, with an await channel |
| an asynchronous function that can fail | `fn f() -> @Task<@Result<T, E>>` | `try await f()` · `try await f() catch x` · `case (await f())` |
| a Task in the middle of a function | `async { … }` | pass it along, `await` it |
| a `@Component` read with `use` | `fn h() -> @Component<T>` (`T` not `@Renderable`) | `use h()`, at the top level of a `@Component` body |
| a component, page or layout | `fn C() -> @Component<Element>` | `C()`, an ordinary call |
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

**Per backend.** On commonJS every `@Task` function, and every `@Component`
one whose hooks node is asynchronous (decision 375), is an `async function`
and its caller awaits; `async { }` is `(async () => { … })()`.
**A `throw` in a `@Task<@Result<…>>` does not reject the Promise: it resolves
with the `Error` value** — JavaScript that consumes a botopink function reads
the `{ Error: … }` it answers instead of catching a rejection. On erlang and
beam a `@Task` is eager, `await` is the identity and `async { }` runs the
block in place.

**On wasm a `@Task` behaves as a Promise** (decision 392): a task starts when
it is made and runs to its first `await`; `await` on a task still pending
suspends the body while other tasks run; a task settles once. A `-> @Task<T>`
function, a method answering one and an `async { }` block compile to a
resumable state machine — the locals live in a frame on the heap, and the
body is entered again at the `await` it suspended at, inside a loop, an `if`,
a `case` or a `try` alike — and the module's scheduler resumes a task when
what it awaits settles: after `main`, it runs the ready tasks and waits on the
host's pending pollables (`wasi:io/poll` on `wasi`; on `browser` the loader
waits on the JavaScript event loop and hands each answer back — no JSPI). A
synchronous function is untouched. A call evaluated before an `await` in the
same statement is refused where it is written — re-entering the statement
would run it twice; bind it to a `val` first. A `@Component` body stays eager
on wasm: an `await` of a task there runs the ready tasks until it settles, and
traps — on both hosts — when the task still waits on the host.

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

<!-- docs-check: reject effect-try-without-fallible-channel -->
```botopink
fn g() -> @Iterator<i32> {
    throw "x";                  // effect-try-without-fallible-channel: the item has to be
}                               //   @Result<i32, E> to throw
```

<!-- docs-check: reject iter-await -->
```botopink
fn h() -> @Iterator<i32> {
    yield await count();        // iter-await: no `await` in an @Iterator — use @Stream
}
```

<!-- docs-check: reject iter-mixed-yield-return -->
```botopink
fn k(xs: i32[]) -> @Iterator<i32> {
    yield 0;
    return evens(xs);           // iter-mixed-yield-return: an iterator (yield) and a
}                               //   factory (return) in one body
```

<!-- docs-check: reject iterator-error-param-removed -->
```botopink
fn old() -> @Iterator<i32, string> { yield 0; }
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

A `comptime` may call the module's functions and imported ones, and they may
interpolate (`"n=${n}"`) and call template functions: a template call the
`comptime` reaches is the code its expansion built, carried with the functions
that code names. A function holding a template call is expanded where it is
inferred, so it is declared before the `comptime` that calls it — otherwise
the `comptime` is refused, naming the call. A record the `comptime` answers is
written back as its type's constructor; a type of another module that this one
does not import is imported where the value is written.

An enum value crosses a `comptime` both ways, a leaf under a section included
(§ Sections of an enum): `comptime name(.Pad.All.4)` passes it in — alone, in
an array, inside a payload variant — and a `comptime` whose type is the enum
writes its answer back as the enum's constructor. A section path written in a
function the `comptime` reaches is resolved where that function is inferred,
so, as with a template call, the function is declared before the `comptime` —
otherwise the `comptime` is refused, naming the path. A decorator's argument
(`#[mark(.Pad.All.4)]`, read as `tokens.value`) and the functions a decorator
reaches carry the same values.

```botopink
type Tok {
    Pad {
        All { 4, 8 }
    }
    Bold,
}

fn first(ts: Tok[]) -> Tok {
    return ts[0] ?? .Bold;
}

fn main() {
    val t: Tok = comptime first([.Pad.All.8, .Bold]);    // written as Tok.Pad.All.8
    @print(t == Tok.Pad.All.8);                          // true
}
```

### Template functions

A function taking `comptime q: @Expr<…>` expands at the call site; `@expr`
lifts a comptime value back into code. `q.value` is the literal's value when
it has no `${…}` hole (decision 364 (2)); a holed literal is not known at
build, and a template that reads `q.value` refuses it at the argument
(`template-value-not-known`) — its parts are read with `q.parts()`.

```botopink
pub fn conf<T>(comptime q: @Expr<string>) -> @Expr<T> {
    val t = q.text();
    val port = 8000 + t.length;
    val debug = true;
    return @expr(#(port, debug));    // the labels come from the variable names
}
```

The code a template builds has two authors, and each name in it resolves in
the scope of whoever wrote it (decision 112). Text the library writes in
`e.build` resolves in the **library's** module, its private functions
included, and names that declaration wherever the template is expanded; the
text from `e.text()` resolves at the **call site**, with the consumer's
imports, aliases and locals. So `e.build("double(" + e.text() + ")")` calls
the library's `double` even where the consumer declares its own, and
`shapesdsl "surface(4, 5)"` reaches `area` through the consumer's
`import {area as surface}`. `e.lookup(name)` resolves at the call site and
answers the declaration — its own name and its `<package>@<path>@@<Decl>`
identity, never the alias — which is what hover and go-to-definition inside
the literal follow.

**A hole known at build** (decision 355). Each `Interp` part of `q.parts()`
carries `known` and `value`: `known` is true when the hole's value is known
while the program compiles — a literal, a `comptime` value, a `val` of the
module whose initializer is known at build, or a template call (another
expansion) whose every argument is — and `value` is that value, read as data
(a record is its fields); for any other hole (a parameter, a local, a call)
`known` is false and `value` is `null`, and the hole is the program's to
compute. The rule reads the hole's value, never the literal's text. A hole
known at build is evaluated as a `comptime` is, and a value that raises there
is refused at the hole. So a template can write its answer as a constant when
every hole is known — `styled "${tab4} color: red;"` with `tab4 =
styledProperty "tab-size: 4;"` is emitted as `styledConstant("s_…",
".s_…{tab-size:4;color:red}")` — and leave the holes to the program otherwise:

```botopink
pub fn shout(comptime q: @Expr<string>) -> @Expr<string> {
    var built = "";
    var computed = "\"\"";
    var known = true;
    for (q.parts()) { p ->
        if (p.kind == "Interp") {
            if (p.known) built = built + p.value else known = false;
            computed = computed + " + " + p.code;
        } else {
            built = built + p.text;
            computed = computed + " + \"" + p.text + "\"";
        }
    }
    if (known) return q.build("\"" + built.toUpper() + "\"");
    return q.build("(" + computed + ").toUpper()");
}

pub val name = "world";
pub val fixed = shout "hello ${name}";      // "HELLO WORLD", written at build

fn greet(who: string) -> string {
    return shout "hello ${who}";            // computed when it runs
}
```

A template call expands wherever an expression may stand (decision 425): a
function's or a type's method body, a destructuring initializer
(`val #(n, total) = f "…";`), a lambda, an argument, a record field's or a
parameter's default (each call that leaves it out gets the expansion), a
`case` arm. A call the compiler did not expand is refused where it is
written (`template-call-unexpanded`), never left to run as a call of a
function that exists only at build.

A template whose second parameter is `comptime decl: @Decl` is written as an
annotation, `#[f "…"]` — § Template annotations below.

### Decorators

A decorator is a function whose first parameter is `comptime decl: @Decl`;
`#[name(args)]` runs it at compile time over the declaration it annotates, the
annotation's arguments after the handle. `decl` reflects the declaration
(`kind`, `name`, `fields`, `variants`, `methods`, `returnType`,
`annotations`, a function's or a method's own `params`, and a function's `hooks`, § The hooks a function reaches), `decl.fail(message)` refuses it at the annotation, and what
the decorator produces goes to one of four places (decision 216):

| Place | Written | Read |
|---|---|---|
| a member of the annotated type | `decl.addMember("pub fn table() -> string { … }")` | `City.table()`, `c.describe()` — run-time code of the type, imported with it |
| comptime meta, a typed value keyed by its type (decision 298) | `decl.setMeta(Entity(table: "cities"))`, `decl.addMeta(Index(column: "name"))` | `@typeInfo(City).meta(Entity)` → `?Entity`, `.metaAll(Index)` → `Index[]`, and on a `@TypeInfo.all` entry — the values written back where they are read |
| comptime meta, per decorator (decision 216 (2); goes once the library sites are migrated, 130 step 8) | `decl.setMeta("table", "cities")` | `@typeInfo(City).meta.entity.table` — a string constant, never run-time code |
| an associated type | `decl.addType("Columns", "(name: string)")` | `City.Columns` in a type position, `City.Columns(name: "n")`, imported with its owner |
| the program's catalogue | (every declaration a decorator runs over) | `@TypeInfo.all(with: entity)` at an entry point |

A member or an associated type from a field's or a method's decorator belongs
to the type that owns it; a function and a module-level `val` have none
(`decorator-member-without-type`, `decorator-type-without-owner`). A decorator
on a `val` runs like one on a `fn` (decision 356): `decl.kind` is
`DeclKind.Val`, `decl.returnType` the declared type as written (`""` when
none), `setMeta` is legal, and the `val` is an entry of `@TypeInfo.all` — one
query answers functions, `val`s or types, never two of them
(`typeinfo-all-mixed`). A decorator adds and never replaces: a name
the type already has is `decorator-member-duplicate` / `decorator-type-duplicate`.
Meta describes a top-level declaration — a `type`, a `behavior`, a `fn` or a `val` — and
each key is set once (`decorator-meta-duplicate`); a read naming a key the
decorator did not set is `typeinfo-meta-missing`.
A record-shaped type's members are closed: a call through the type names an
associated fn it declares, by hand or through `decl.addMember`, and any other
name is `unknown-associated-fn` where the call is written.

<!-- docs-check: reject unknown-associated-fn -->
```botopink
type City(name: string)

fn main() {
    @print(City.table());
}
```

```botopink
fn entity(comptime decl: @Decl, comptime table: @Expr<string>) {
    var cols: string[] = [];
    decl.fields.forEach({ f -> cols.push(f.name + ": string") });
    decl.setMeta("table", table.value);
    decl.addMember("pub fn table() -> string { return \"" + table.value + "\"; }");
    decl.addType("Columns", "(" + cols.join(", ") + ")");
}

#[entity("cities")]
type City(name: string, people: i32)

fn header(c: City.Columns) -> string {
    return c.name + "|" + c.people;
}

fn main() {
    @print(City.table());                          // cities
    @print(@typeInfo(City).meta.entity.table);     // cities
    @print(@typeInfo(City).name);                  // City
    @print(header(City.Columns(name: "n", people: "p")));   // n|p
}
```

A decorator's arguments are typed compile-time values (decision 280), checked
where they are written, as a call's are:

1. **Every parameter after `@Decl` is `comptime x: @Expr<T>`**, written out —
   the argument is the user's expression, checked against `T` where it is
   written (decision 364); what runs later comes from the decorator's outputs.
   A parameter without `comptime` is `decorator-param-not-comptime` at the
   parameter, and one without `@Expr` `comptime-param-not-expr`. A `comptime` parameter may
   take a default, which an annotation that leaves it out gets — a literal,
   `null`, a variant `.Name`, or an array or tuple of those; outside a
   decorator no call fills one, and a `comptime` default there is
   `comptime-default-outside-decorator` at the default.
2. **An argument may be of any type** — a string, a number, an array, a
   record built by its constructor (directly or through a module `val`), a
   variant, a function, a type (`comptime t: @Expr<type>`), a field. It is checked
   against its parameter's type at the argument (an integer literal takes the
   integer type asked for, decision 247), positional arguments first and
   labelled ones by name (`at: .confirm`); a variadic last parameter (decision
   267) takes the positional arguments left. The body reads each argument's
   value with `x.value`, as it is: `[1, 2]`'s has length 2. An argument not
   known at compile time — a function call such as `env("X")`, a module `var`
   — is refused at it (`decorator-value-not-comptime`) when the body reads the
   parameter; a body that never reads it accepts any expression of `T`.
   `x.fail("…")` refuses the declaration at `x`'s argument, not at the
   annotation.
3. **`@Decl<P>` names the shape of the annotated declaration** — a type, a
   field's type, a function's type — and binds the type parameters `P` names,
   through a pattern too: `@Decl<fn(e: E) -> unknown>` binds `E` to the
   function's parameter type. A declaration that does not fit is refused at the
   annotation, both shapes spelled; `@Decl` alone is `@Decl<unknown>`.
4. **`Type.Field<T>` and `.name`** — a field of `T` (decision 308, std's
   `types.bp`); `.name` resolves against the `T` the parameter expects, a field
   `T` does not declare is refused at the `.name`, and the body reads it as the
   record `decl.fields` hands out (`name`, `typeName`, `annotations`). A
   variant against an enum parameter resolves the same way. Either is named
   exactly as declared, case included: `.custom` against `Custom` is the
   missing-name error. A name that points at botopink code is a reference; a
   name of another system (a table, a URL, a cache key, text for a user) stays
   a string.

```botopink
import {types.Type} from "std";

type Level { Low, High }

fn index<T>(comptime decl: @Decl<T>, comptime ..fields: @Expr<Type.Field<T>[]>) {
    decl.setMeta("columns", fields.value.map({ f -> f.name }).join(","));
}

fn mark(comptime decl: @Decl, comptime sizes: @Expr<i32[]>, comptime level: @Expr<Level> = .Low) {
    decl.setMeta("sizes", sizes.value.length.toString());
    decl.setMeta("level", if (level.value == Level.High) "high" else "low");
}

#[index(.state, .name), mark([1, 2], level: .High)]
type City(code: string, name: string, state: string)

fn main() {
    @print(@typeInfo(City).meta.index.columns);    // state,name
    @print(@typeInfo(City).meta.mark.sizes);       // 2
    @print(@typeInfo(City).meta.mark.level);       // high
}
```

A function or a type argument is checked at the argument and never run at
build (decision 364 (3)): its `@Expr` has no `.value` (`expr-value-of-function`,
`expr-value-of-type`, at the read). The body hands an `@Expr` on to the program
through a typed member (decision 370 (2)) — `decl.addMember(name, fn…)` with
the member written as a function expression at the call, its parameters and
its return typed:

```botopink
pub type Violation(field: string, message: string)

fn check<T>(
    comptime decl: @Decl<T>,
    comptime message: @Expr<string>,
    comptime rule: @Expr<fn(v: T) -> bool>,
) {
    decl.addMember("validate", fn(self: T) -> Violation[] {
        if (rule(self)) return [];
        return [Violation(field: "confirm", message: message)];
    });
}

fn passwordsMatch(a: Signup) -> bool {
    return a.password == a.confirm;
}

fn t(key: string) -> string {
    return key;
}

#[check(t("signup.mismatch"), passwordsMatch)]
pub type Signup(password: string, confirm: string)
// Signup(password: "a", confirm: "b").validate() calls passwordsMatch and
// t("signup.mismatch") at run time
```

The member is the program's code: inside it each `@Expr<T>` parameter is a
`T`, and the type receives `pub fn validate(self: Self) -> Violation[] { … }`
with each parameter's argument spliced where the member uses it, as the
annotation wrote it — evaluated at run time, each time that use is reached, so
an argument not known at build (`t("…")`) is accepted where the body never
reads `.value`. The decorator's type parameters take what the annotation bound
them to (`T` is `Signup`, written `Self`). The member reads nothing else of the
decorator's body: the `@Decl` handle and its locals exist only while the
program compiles (`decorator-member-captures`). Every parameter is typed
(`decorator-member-fn-untyped`), the member is written at the call
(`decorator-member-not-fn`), a `self` is the type the member joins and every
type parameter it writes is bound (`decorator-member-type`), and a typed
function expression anywhere else is `fn-expr-typed`. Every other name a
member of a decorator declared in another module writes resolves where the
decorator wrote it (decision 384): its module's types and functions, a private
helper included, never a same-named declaration of the annotated module — a
type of that name declared there is `import-name-collision` at the annotation.
In the member, `@typeInfo(T)` of the decorator's type parameter reads the
annotated type's typed meta (decision 395): typed in the decorator's body,
answered where the member joins the type, the list written under `comptime`
(`for (comptime @typeInfo(T).metaAll(Check)) { c -> … }`). The source text of an
argument never reaches an output (`rule.text()` is `expr-param-method`, 370
(3)). The other channel is typed meta whose record has `@Expr<T>` fields
(370 (1), § Typed meta below).

### Typed meta (decision 298)

A decorator's meta is a typed value keyed by its record type, never by the
decorator's name: `decl.setMeta(Entity(table: table.value))` records one
`Entity` on the declaration, `decl.addMeta(Index(column: c.value))` one more
`Index` each time. A reader names the type — `@typeInfo(City).meta(Entity)` is
an `?Entity` (`null` when nothing recorded one), `@typeInfo(City).metaAll(Index)`
an `Index[]` —, so a renamed decorator changes no reader, two decorators may
write one type, and who may read is who sees the type. The values are built at
build time and written back as their constructors where they are read: each
field is a string, an integer, a float, a `bool`, a variant of an enum without
payloads, an array or an optional of those (`decorator-meta-field-type`), and
the value is the record's constructor written at the call
(`decorator-meta-not-record`), in the decorator's own body.

```botopink
type Entity(table: string, audited: bool)
type Index(column: string)

fn entity(comptime decl: @Decl, comptime table: @Expr<string>) {
    decl.setMeta(Entity(table: table.value, audited: decl.name == "City"));
}

fn index(comptime decl: @Decl, comptime column: @Expr<string>) {
    decl.addMeta(Index(column: column.value));
}

#[entity("cities")]
#[index("name")]
#[index("state")]
type City(name: string, state: string)

fn main() {
    @print(@typeInfo(City).meta(Entity)?.table ?? "none");     // cities
    @print(@typeInfo(City).metaAll(Index).length);              // 2
    @print(@typeInfo(City).metaAll(Entity).length);             // 1
}
```

A type is recorded once per declaration with `setMeta` — a second value of it,
or one added with `addMeta` beside it, is `decorator-meta-twice` at the
annotation that recorded it —, and `meta(T)` over several values is
`typeinfo-meta-several` (read them with `metaAll(T)`). Meta describes a
top-level declaration (`decorator-meta-on-member` from a field's or a method's
decorator).

<!-- docs-check: reject decorator-meta-twice -->
```botopink
type Entity(table: string)

fn entity(comptime decl: @Decl, comptime table: @Expr<string>) {
    decl.setMeta(Entity(table: table.value));
}

#[entity("cities")]
#[entity("towns")]
type City(name: string)

fn main() {
    @print(@typeInfo(City).meta(Entity)?.table ?? "none");
}
```

A meta record may hold `@Expr<T>` fields (decision 370 (1)): the decorator
hands one of its `comptime x: @Expr<T>` parameters on as it is, and the value
is built in the reading program with the expression spliced where the
annotation wrote it — a rule is called, a message evaluated, at run time, never
while the program compiles. Such a field takes a parameter and nothing else,
and a parameter goes to no other field (`decorator-meta-expr-arg`; a plain field
reads `x.value`). The expressions resolve their names where the annotation
wrote them, wherever the value is read (decision 385): a private rule of the
annotation's module is reached, a same-named function of the reader is not.

```botopink
pub type Check<T>(message: @Expr<string>, rule: @Expr<fn(v: T) -> bool>)

fn check<T>(comptime decl: @Decl<T>, comptime message: @Expr<string>, comptime rule: @Expr<fn(v: T) -> bool>) {
    decl.addMeta(Check(message: message, rule: rule));
}

fn passwordsMatch(s: Signup) -> bool {
    return s.password == s.confirm;
}

#[check("the passwords differ", passwordsMatch)]
type Signup(password: string, confirm: string)

fn main() {
    val s = Signup(password: "a", confirm: "b");
    for (@typeInfo(Signup).metaAll(Check)) { c ->
        if (!c.rule(s)) @print(c.message);                     // the passwords differ
    }
}
```

`@typeInfo` is the one reflection builtin (decision 248): `.name` and
`.meta.<decorator>.<key>` read a declaration, `.meta(T)` / `.metaAll(T)` its
typed meta (§ Typed meta), the static `@TypeInfo.all(…)` of
its type the program (decision 253; `@typeInfo.all` is `typeinfo-all-on-function`),
and `@typeInfo(T)` used as a value is a `TypeInfo<T>` (decision 253; its members
other than `name` and `meta` are `typeinfo-unknown-member` until they are answered). The lowercase
`@typeinfo` is `typeinfo-lowercase`, naming `@typeInfo`.

<!-- docs-check: reject typeinfo-lowercase -->
```botopink
type City(name: string)

fn main() {
    @print(@typeinfo(City).name);
}
```

`@TypeInfo.all(with: d)` answers every declaration of the program that carries
`d`, so an entry point builds its catalogue explicitly — no module registers
itself when it loads. The answer is always a `Declared<unknown>[]` (decision 254)
— one type whatever the program declares —, each entry a
`Declared<unknown>(name, module, meta, returnTypeName, value, typedMeta)`: `meta` is what `d` set on it,
`d.meta(T)` / `d.metaAll(T)` the typed meta its decorators recorded (decision
298; carried in `typedMeta`, one thunk per value, and built through an import
the answer adds, so the record type is `pub` — `typeinfo-all-private`; a
generic record is read through `@typeInfo` — question `130-s8-d`; not in a
decorator's or a template's body, `typeinfo-meta-at-build`),
`returnTypeName` a function's declared return type as written (`""` for a type, decision 256),
`value` the function itself, or for a type a thunk calling the associated fn
named by `member:` (`@TypeInfo.all(with: component, member: "register")`), typed
`unknown`, so a use tests it with `is` before it calls it. It sees every module of
the build — the package, its dependencies, std — in module-path order, then
declaration order, and the reading module's own declarations; a module that
reads it is imported by nobody (`typeinfo-all-imported`), and every declaration
it answers from another module is `pub` (`typeinfo-all-private`).
A template function's body may read the catalogue too (decision 353): there,
`@TypeInfo.all(with: d)` answers for the program that expands the call — every
module's declarations carrying `d`, every module's decorators applied —, not for
the library that declares the template, so a library's `pub default fn` finds
the application's `#[theme]`. Such a module is no reader (it may be imported); a
query written in a function the template only calls still makes its module one.
The catalogue's rules hold, refused at the expansion; an entry's `name`,
`module`, `meta` and `returnTypeName` are answered, and its `value` — a
declaration of the program — is no value at build: the template body's read of
it is `typeinfo-all-template-value`. An import of a reader's default function
(`import pkg from "pkg"`) is `typeinfo-all-imported` at the handle.
`with:` may list several decorators (decision 235):
`@TypeInfo.all(with: [service, repository], member: "make")` answers every
declaration carrying any of them in the same one order, a declaration carrying
two of them once, its `meta` what the listed decorators set; a decorator listed
twice is `typeinfo-all-arguments`.

```botopink
fn route(comptime decl: @Decl, comptime path: @Expr<string>) {
    decl.setMeta("path", path.value);
}

#[route("/about")]
pub fn about() -> string {
    return "about us";
}

fn main() {
    for (@TypeInfo.all(with: route)) { r ->
        for (r.meta) { m ->
            @print(r.name + " " + m.value);        // about /about
        }
    }
}
```

#### The hooks a function reaches — `decl.hooks`

A function's `@Decl` lists every function it reaches through hooks and
components (decision 277), so a framework's decorator checks what a page
activates at build — which markers its hooks carry, which contexts it reads —
without the compiler naming any stage, marker or library. `decl.hooks:
HookNode[]` is the function's own node first, then the node of every function
reachable through its `use`s and calls of `@Component` functions,
breadth-first, each node's edges in body order, each function once; empty for
a type, a field, a method and a `val`. A node holds only what is written in its
`function`:

| Record | Fields |
|---|---|
| `HookNode` | `function: Declared<unknown>`, `uses: HookUse[]`, `calls: HookCall[]`, `async: bool` (decision 375) |
| `HookUse` — one `use h(…)` | `hook: ?Declared<unknown>` (`null` over a function value), `annotations: DeclAnnotation[]` (the hook's own), `at: string`, `typeArgs: TypeInfo<unknown>[]` (`use params<BlogParams>()` → `BlogParams`, its fields as the checker spells them), `context: ?Declared<unknown>` (the context object of a `use provide(C, …)` / `use context(C)`, decision 354 (4); `null` for any other hook) |
| `HookCall` — one call of a `@Component` function | `callee: Declared<unknown>`, `at: string` |

A call a template builds from a tag counts as written. `at` is
`"<module>:<line>:<column>"`, the entry module `main`. A cycle is an edge back
to a listed node; a host function (`declare fn`, `#[@External…]`) and std's
`provide` / `context` get no node. Each node is recorded once, when its
function's body is checked, and an importer reads the nodes of the functions
it reaches in another module. A node is `async` when its body writes `await`
or `async { … }`; when it `use`s an asynchronous hook or calls an asynchronous
component, written `await` or not; when it calls a host function answering
`@Task` (or `@Component`, which extends it); or when it calls what the checker
cannot follow — a function value or a method answering `@Component<R>`, a
`use` with `hook: null`. A cycle is asynchronous when any node in it is; every
other node is synchronous (a page may then be rendered without streaming), and
commonJS emits a synchronous component as a plain `function`. In a decorator body a `Declared`'s `value` is
`null` (no function of the program runs while it compiles) and its `meta` is
every entry its declaration's decorators set, keyed `<decorator>.<key>`. A
`DeclAnnotation`'s `decorator` is the `Decorator` its name names — an alias
(`#[srv]` after `import {serverOnly as srv}`) and a namespace give the
declaration, never the spelling.

**A decorator that reads `.hooks` runs last** (decision 372, provisional). A
module's decorators run in two phases: first every decorator that reads no
`.hooks` — the ones that add members and associated types —, then the module's
bodies are checked with every member and type already there, then each
decorator that reads `.hooks` (in its body or a function it reaches) runs over
them. So a page may call a member another decorator of its module adds
(`Account(…).validate()` above `#[check(…)] pub type Account`). Such a
decorator records meta or refuses, nothing else: `@emit`, `decl.addMember` (a
source or a typed `fn…`) and `decl.addType` in it are `decorator-hooks-output`, at the call, whether or not
it annotates anything. A `@typeInfo(X).meta` read of its meta in the same module
is answered once it ran; a `@TypeInfo.all(with: d)` in the module of a
declaration `#[d]` annotates is `typeinfo-all-hooks-reader` at `d` — its answer
is built before `d` runs (read the catalogue from another module).

**Comparing decorators** (decision 371). `a.decorator.same(other)` answers
whether two decorators are one declaration: `other` is a decorator's name — an
alias and a namespace resolved where it is written — or another `Decorator`
(`b.decorator`); a same-named decorator of another module or package is
`false`, and anything else is no `Decorator` (a string spelling the name is a
type mismatch at the argument). `is` stays a keyword and `==` on two
`Decorator`s has no meaning.

```botopink
type Element(text: string) implement @Renderable

fn graph(comptime decl: @Decl) {
    var names: string[] = [];
    decl.hooks.forEach({ n -> names.push(n.function.name + "/" + n.uses.length.toString()) });
    decl.setMeta("nodes", names.join(" "));
}

fn session() -> @Component<string> {
    return "alice";
}

fn user() -> @Component<string> {
    val s = use session();
    return "user " + s;
}

#[graph]
fn Page() -> @Component<Element> {
    val u = use user();
    return Element(text: u);
}

fn main() {
    @print(@typeInfo(Page).meta.graph.nodes);       // Page/1 user/1 session/0
}
```

```botopink
fn serverOnly(comptime decl: @Decl) {
    val _n = decl.name;
}

// Refuses a function marked `serverOnly`, however the mark is spelled.
fn clientOnly(comptime decl: @Decl) {
    decl.annotations.forEach({ a ->
        if (a.decorator.same(serverOnly)) decl.fail("`" + decl.name + "` runs on the server");
    });
}

#[clientOnly]
fn Widget() -> string {
    return "w";
}
```

### Template annotations (decision 311)

The template call `f "…"` may be written as an annotation, `#[f "…"]` or
`#[f """…"""]`, alone or in a `#[a, b]` list. `f` is a template function
whose first parameter is the literal, `comptime q: @Expr<…>`, and whose second
receives the annotated declaration, `comptime decl: @Decl<…>` (question
`s29-a`). Such a function is written only as an annotation; a template for a
call site declares no `@Decl`:

- the literal is captured unevaluated, as at a call site: `q.text()`,
  `q.parts()` (each hole an `Interp` part whose `code` names it), `q.lookup`,
  `q.value` for a literal without a hole;
- a `${…}` hole resolves in the annotated declaration's scope — on a function
  or a method its parameters, by name and type (a method's `self` is
  `Self`) —, every other name in the module's scope, its imports included
  (decision 112); a name it does not declare is the ordinary unbound-name
  error at the hole;
- what the body records goes where a decorator's does (decision 216): typed
  meta (decision 298), a member, an associated type, a loose declaration. A
  string an output carries names a hole by the expression written in it —
  the part's `code` placeholder becomes `id` where the meta is recorded;
- the value it returns is not used: an annotation has no call site to splice
  it into. `q.fail(m)` / `decl.fail(m)` refuse the declaration at the
  annotation.

Refused at the annotation: a name that is not a template function
(`template-annotation-not-template`), a template that takes no `@Decl`
(`template-annotation-without-decl`) and the call form `#[f(…)]` or `#[f]`
naming a template function (`template-annotation-call-form`, naming
`#[f "…"]`); a call `f "…"` of a template that takes a `@Decl` is
`template-annotation-only` at the call.

**A method's typed meta, read by its owner's decorator** (question `s29-b`).
A method's decorators — a template annotation and a `#[d(…)]` alike — run
before its owner's, and the typed meta they record (`decl.setMeta(v)`,
`decl.addMeta(v)`) is read by the owner's decorator on a `decl.methods` entry:
`m.meta(T)` is a `?T`, `m.metaAll(T)` a `T[]`, `T` the record written by its
declared name. A field's decorator still records no meta
(`decorator-meta-on-member`).

```botopink
pub type Query(sql: string, params: string[])

fn query(comptime q: @Expr<string>, comptime decl: @Decl) -> @Expr<string> {
    var sql = "";
    var params: string[] = [];
    for (q.parts()) { p ->
        if (p.kind == "Interp") {
            params.push(p.code);
            sql = sql + "$" + params.length.toString();
        } else sql = sql + p.text;
    }
    decl.setMeta(Query(sql: sql, params: params));
    return q.build("\"\"");
}

fn repository(comptime decl: @Decl) {
    var lines: string[] = [];
    for (decl.methods) { m ->
        val found = m.meta(Query);
        if (found != null) lines.push(m.name + ": " + found.sql + " <- " + found.params.join(", "));
    }
    decl.setMeta("statements", lines.join(" | "));
}

#[repository]
behavior Users {
    #[query "select * from users where id = ${id} limit 1"]
    fn find(self: Self, id: i32) -> string;
}

fn main() {
    // find: select * from users where id = $1 limit 1 <- id
    @print(@typeInfo(Users).meta.repository.statements);
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
has no name for is written `_` (`declare fn typeInfo<T>(comptime _: @Expr<type>) ->
TypeInfo<T>;`); `_` is a bodyless declaration's placeholder, and a
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
(`` `Meter.plus` has no `#[@External.<Target>(…)]` for the wasm backend ``); a
bodyless method with no binding at all binds no backend, and is refused on
every one.

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
| `wasm` | `@External.Wasm` — the closed vocabulary below | refused at compile time — "for the wasm backend" |

A declaration nothing calls is free on every target; a **call** is refused
wherever it is written, whether or not anything reaches it. A function whose
body is only a host call is an ordinary function and inherits no restriction:
its call is statically present, so a target the declaration does not name
refuses the program even when nothing calls the wrapper. A project that needs
such a wrapper names its `targets`, or the declaration gains the other
target's binding.

wasm has no host of its own, so `@External.Wasm` does not name a host symbol
or carry target text: it is **one string from a closed vocabulary of three
forms** (decision 238), read and checked where the annotation is written. The
arguments are always the declared parameters, in order.

| Form | Binds the declaration to |
|---|---|
| `op:<opcode>` | one numeric wasm instruction (`op:f64.floor`, `op:i32.add`, `op:f64.lt`, `op:f64.convert_i32_s`); the declared parameter and return types must be exactly the instruction's — a comparison or `eqz` answers `bool` |
| `fn:<name>` | a private (not `pub`) `fn` of the same module, with a body, taking the same parameter types in the same order and answering the same type — the algorithm stays in the library, in botopink |
| `wasi:<adapter>` | a compiler adapter over the host, one of the list below — each has an implementation per host (WASI preview 2 through the `wasi` component, JavaScript in the `browser` loader), so one list serves both (decision 394) |

```botopink
#[@External.Node("Math", "floor"),
  @External.Erlang("math", "floor"),
  @External.Wasm("op:f64.floor")]
pub declare fn floorOf(x: f64) -> f64;

#[@External.Node("Math", "round"),
  @External.Erlang("erlang", "round"),
  @External.Wasm("fn:roundHalfUp")]
pub declare fn roundOf(x: f64) -> f64;

fn roundHalfUp(x: f64) -> f64 {
    val up = -1.0 * floorOf(-1.0 * x);
    return if (up - 0.5 > x) up - 1.0 else up;
}
```

| Adapter | Signature | Answers |
|---|---|---|
| `random_f64` | `() -> f64` | a uniform `f64` in `[0.0, 1.0)` from 53 bits of `random_get` (an errno from the host traps) |
| `seed_u32` | `(i32) -> void` | nothing; seeds the module's one Mulberry32 stream with the word's bits — no WASI call: the state a seeded stream needs, which no botopink module holds on every target |
| `seeded_f64` | `() -> f64` | the stream's next draw in `[0.0, 1.0)` — Mulberry32 as the commonJS sidecar of `std/io/random` draws it, so a seed gives the same draws there and here —, or `random_f64`'s draw before any seed |
| `delay` | `(i32, T) -> @Task<T>` | a task that settles with the value once the milliseconds have passed on the host's monotonic clock (`wasi:clocks/monotonic-clock` and `wasi:io/poll` on `wasi`, `setTimeout` on `browser`); a negative duration is `0` |
| `race` | `(Array<@Task<T>>) -> @Task<T>` | the first of the started tasks to settle — the first settled one in input order when some already are; an empty list traps |
| `race_of` | `(Array<fn() -> @Task<T>>) -> @Task<T>` | each thunk called in order (its task runs to its first `await`), then raced; an empty list traps |
| `spawn_all` | `(Array<fn() -> @Task<T>>) -> @Task<Array<T>>` | each thunk called in order; the answers in input order once the last has settled |

An adapter answering `@Task<T>` (decision 393) is declared over one type
parameter and checked by **shape** at the annotation — the signature in the
table, whatever `T` is — and the compiler makes the pending task the host's
pollable backs:

```botopink
#[@External.Node("""new Promise((__r) => setTimeout(() => __r($1), $0))"""),
  @External.Erlang("""(fun(__M, __V) -> timer:sleep(__M), __V end)($0, $1)"""),
  @External.Wasm("wasi:delay")]
pub declare fn pause<T>(millis: i32, value: T) -> @Task<T>;
```

The task carries its `T` in one word: a task adapter reached with a float or
an `i64` value is refused at the call.

Anything else — another prefix, an opcode the backend does not bind, an opcode
whose type differs from the signature, a `fn:` naming no private bodied fn of
the module (or a `pub` one, or one of another signature), an adapter not in
the list, a template with `$` markers — is an error at the annotation. No
runtime-helper name of the backend is part of a binding and nothing a binding
writes names an address: there is no raw memory in the vocabulary. A
`declare fn` with no `@External.Wasm` keeps the refusal above at its call.

**A wasm build binds to the runtime it runs on** (decision 334). The package
names it in `botopink.json`, `"wasm": { "host": "wasi" }` or `"browser"`
(`docs/botopink-json.md`); absent, it is `wasi` — wasmtime and the runtimes
that follow WASI preview 2. A binding may name the host it serves with
`host:` — `#[@External.Wasm("op:f64.floor", host: .Wasi)]` beside
`#[@External.Wasm("fn:floorBody", host: .Browser)]` —, and one written without
`host:` serves every host. A build reads the binding serving its host and
checks every other one too; a function with no binding for the build's host
is refused at its call as above, and a std function with none is
`std-unsupported-on-target: … for target 'wasm' on host 'wasi'`. `host:` on
another `External` variant, a value other than `.Wasi` or `.Browser`, and a
second binding for one host (a binding without `host:` beside a hosted one
included) are errors at the annotation.

On the `wasi` host the file `botopink build --target wasm` writes is a **WASI
preview 2 component** in WebAssembly text, which `botopink run` runs with
`wasmtime run -S http`: the module the backend lowers, unchanged but for its
start function (called by the component's `wasi:cli/run` export before
`main`), and a preview 1 adapter the compiler writes — `fd_write` on
`wasi:cli/stdout` and `wasi:cli/stderr` through `wasi:io/streams`,
`random_get` on `wasi:random/random`. The adapters above keep their preview 1
names inside the module; the component imports `wasi:io/error`,
`wasi:io/streams`, `wasi:cli/stdout`, `wasi:cli/stderr` and
`wasi:random/random` at `@0.2.0`.

On the `browser` host the build writes, beside the module's text, its binary
`<module>.wasm` and a loader `<module>.mjs`: an ES module that instantiates the
binary with the imports a browser offers — `fd_write` on the console
(`console.log` / `console.error`, line by line; `fs.writeSync` on the same fd
under node), `random_get` on `crypto.getRandomValues` — then calls the
module's start and `main`. A page imports the loader; `botopink run` runs it
with `node <module>.mjs`. Every wasm program prints the same on both hosts:
`tests/language` runs its wasm column under both and fails a cell whose
answers differ.

**`fn:<name>` binds a declaration on every target** (decisions 238, 263). On
`@External.Node`, `@External.Erlang` and `@External.Beam` a single string
starting with `fn:` is not a host expression or a template: it is the same form
as on wasm — a private `fn` of the same module, with a body, taking the same
parameter types in the same order and answering the same type — and it is
checked the same way, at the annotation. One algorithm written in botopink then
answers the same bits on every target, instead of each host's own library
(`std/math`'s `sin`, `pow`, … run std's bodies on erlang and beam, and `pow` on
commonJS too).

```botopink
#[@External.Node("fn:mixBody"),
  @External.Erlang("fn:mixBody"),
  @External.Beam("fn:mixBody"),
  @External.Wasm("fn:mixBody")]
pub declare fn mix(x: f64, y: f64) -> f64;

fn mixBody(a: f64, b: f64) -> f64 {
    return a * 2.0 + b;
}
```
Until 2026-09-21 wasm lowered such a call to a `wasm trap`, so the program
compiled and then died at run time where the other three refused it; it
refuses too, and there is no flag that restores the trap.

## Builtins

```botopink
fn greet() {
    @print("hello");
}

fn notReady() -> i32 { @todo(); }
```

Every builtin is declared in `libs/std/src/builtins.d.bp` (`@todo` and `@panic`,
which carry a default, in `libs/std/src/builtins_fns.d.bp`), and the compiler is
held to the declarations (decision 252): a unit test fails, naming the builtin,
when the compiler implements one the files do not declare, the files declare one
it does not implement, or the two signatures differ. The declarations, as
written there (COMPTIME-ONLY: evaluated while the program is checked or while a
decorator or template body runs, never at run time):

| Builtin | Declaration | Held at the call by |
|---|---|---|
| `@print` / `@println` / `@debug` | `print(..values: unknown[])` (each alike) — any number of arguments (§ A variadic parameter) | the declaration |
| `@panic` | `panic(message: string = "panic") -> noreturn` | the declaration |
| `@todo` | `todo(message: string = "not implemented") -> noreturn` | the declaration |
| `@trap` | `trap() -> noreturn` | the declaration |
| `@block` | `block<T>(body: fn() -> T) -> T` — `@block { … }`, its value what its `return`s carry | the declaration |
| `@module` | `module() -> module` | refused at every call (`builtin-not-lowered`) |
| `@field` | `field<T, F>(obj: T, comptime name: @Expr<string>) -> F` — COMPTIME-ONLY name | the declaration |
| `@src` | `src() -> SourceLocation` — COMPTIME-ONLY (§ `@src()` and `SourceLocation`) | its own rule (`src-takes-no-arguments`) |
| `@typeInfo` | `typeInfo<T>(comptime _: @Expr<type>) -> TypeInfo<T>` — COMPTIME-ONLY (§ Decorators) | its own rule (`typeinfo-unknown-declaration`, `typeinfo-unknown-member`) |
| `@TypeInfo.all` | `all(with: Decorator \| Decorator[], member: ?string = null) -> Declared<unknown>[]`, a static `declare fn` of `TypeInfo<T>` — COMPTIME-ONLY | the declaration — `Decorator` is the type of a decorator's name (decision 268), so anything else in `with:` is the ordinary mismatch at the argument —, after its own shape rule (`typeinfo-all-arguments`) |
| `@TypeOf` | `TypeOf<T>(value: T) -> T` — COMPTIME-ONLY | the declaration |
| `@makeRecord` | `makeRecord<R>(fields: RecordField[]) -> R` — COMPTIME-ONLY | the declaration |
| `@RecordKeys` | `RecordKeys(comptime _: @Expr<type>) -> string[]` — COMPTIME-ONLY | the declaration |
| `@comptimeError` | `comptimeError(comptime message: @Expr<string>) -> noreturn` — COMPTIME-ONLY | its own rule (the message it raises) |
| `@emit` | `emit(source: string)` — COMPTIME-ONLY, a decorator body | the declaration |
| `@compilerError` | `compilerError(message: string) -> noreturn` — COMPTIME-ONLY, a decorator or template body | the declaration |
| `@expr` / `@code` | `expr<T>(comptime value: @Expr<T>) -> Expr<T>`, `code<T>(text: string) -> Expr<T>` — COMPTIME-ONLY, a template body | the declaration |

A call the declaration refuses — more arguments than it declares, a parameter
without a default left out, a label naming no parameter — is
`error[builtin-arguments]` at the call, naming the declaration; an argument of
another type is the ordinary type mismatch, at the argument.

<!-- docs-check: reject builtin-arguments -->
```botopink
fn main() {
    @panic("first", "second");
}
```

Builtin names are exact: an unrecognised `@name(…)` is `error[unknown-builtin]`
(with the nearest name when one is an edit away), never a silent `void`. `is`
is only an operator (decision 322): `x is T` tests a type, and a hand-written
`@is(…)` is `error[unknown-builtin]` naming the operator.

`Decorator` (declared in `builtins.d.bp`, decision 268) is the type of a
decorator's name: a name has it when it names a function whose first parameter
is `comptime _: @Decl` and which has a body — further arguments included —, and
an array literal of such names is a `Decorator[]`. Nothing else is assignable to
it, and it cannot be constructed: `@TypeInfo.all(with: 42)` and
`@TypeInfo.all(with: someOrdinaryFn)` are the ordinary type mismatch, at the
argument.

`@panic`, `@todo` and `@trap` never return: they are declared `-> noreturn`, the
bottom type, so a call to one stands wherever a value of any type is expected —
`val x: i32 = @todo();`, `return @panic("…");`, one branch of an `if` whose other
branch has the value. `@module()` is declared but no target lowers it, so it is
`error[builtin-not-lowered]`.

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
messages and the `snap` library's paths are computed from the caller's `@src()`.

## Tests

```botopink
test "addition works" {
    assert 1 + 1 == 2;
}
```

Test blocks are declared at module level. Run with `botopink test`
(`--target`, `--filter <substring>`). A test that spawns the compiler — to
build a fixture project — reads its path from the `BOTOPINK_BIN` environment
variable: `botopink test` sets it to its own executable for the tests it runs,
unless the caller already set it.

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

`#[mocks.mock]` writes that double for you — it reflects the annotated
`behavior`'s methods through `@Decl` and gives the behavior the associated
type `<Name>.Mock` and the factory `<Name>.mock()` (§ Decorators). A std module's decorators come with its namespace
import, under the handle it binds: `import {testing.mocks}` makes `mock`
the annotation `#[mocks.mock]` (an alias `as m` makes it `#[m.mock]`), and the
code it adds reaches the runtime through that same handle (`mocks.invoke(…)`).
A name through the handle that is not one of the module's decorators is
`error[unknown-annotation]`, and a decorator imported as a leaf
(`import {testing.mocks.mock}`) is `error[std-decorator-leaf-import]`: the code
it adds would have no handle to name the runtime by.

```botopink
import {testing.mocks} from "std";

#[mocks.mock]
behavior OrderRepo {
    fn total(self: Self, id: i32) -> i32;
}

test "orders: the synthesized double answers its stub" {
    val repo = OrderRepo.mock();
    val _s = mocks.when(repo.total(mocks.eq(3))).thenReturn(30);
    assert repo.total(3) == 30;
    assert repo.total(4) == 0;
}
```

Two more limits carried over from the old library: a matched `thenThrow` is a
host throw, not an `@Result`, so the caller catches it with `asserts.throws`
and not with `try … catch`; and there is no generic `any<T>()` matcher, because
it would need a per-type default it cannot synthesize.

## Backends

| Target     | Output | Runner                      |
|------------|--------|-----------------------------|
| `commonJS` | `.js`  | `node` ≥ 22                 |
| `erlang`   | `.erl` | `escript` (OTP)             |
| `beam`     | `.S`   | `erlc +from_asm` + `erl`    |
| `wasm`     | `.wat` | `wasmtime`                  |

Select the target with `--target`:

```bash
botopink run --target commonJS
botopink build --target erlang
```

`botopink clean` deletes `out/` and `.botopinkbuild/` whole: the comptime
scratch (`.botopinkbuild/tmp/`), the run directories of `botopink test` and the
`bpmp install` links under `.botopinkbuild/deps/` — run `bpmp install` again
after it — and every build cache (`.botopinkbuild/cache/`: the erlang verdicts
of `botopink build`, the `.beam` files of `botopink test --target erlang`). In
a workspace member, the workspace root's `.botopinkbuild/cache/` goes too: the
members of a workspace share one cache there.

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

The compiler emits Erlang for one Erlang/OTP release — `botopink --version`
prints it (`otp: 28`) — and `botopink build`, `run` and `test` on `erlang` or
`beam` refuse an `erl` on `PATH` of another release before writing anything.
A manifest may pin the release too, inside what the compiler supports:

```json
{ "name": "rakun", "otp": "28" }
```

Another value (`"otp": "26"`) is a manifest error located at the value, and
every package of a build's closure that declares `otp` must declare the same
release; a workspace member without one inherits its workspace's.

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
| `#[@use] fn f() -> @Use<C, T>` | `fn f() -> @Component<T>` (`throw` / `try` only if `T` is a `@Result`) |
| `#[@use] fn f() -> @Component<T>` | `fn f() -> @Component<T>` |
| `#[@generator]` + `@Generator<T>` | `@Iterator<T>` |
| `#[@resultGenerator]` + `@ResultGenerator<T, E>` | `@Iterator<@Result<T, E>>` (`for` no longer does an implicit `try`) |
| `#[@futureGenerator]` + `@FutureGenerator<T, E>` | `@Stream<@Result<T, E>>` |
| `#[@generator] loop { … }` | `iter loop { … }` |
| `#[@resultGenerator] loop { … }` | `iter loop { … }` (the item becomes a `@Result` from the body) |
| `#[@futureGenerator] loop { … }` | `stream loop { … }` |
| `YieldStep<T, E>` with `Error(error: E)` | `YieldStep<T>` = `{ Yield(value: T), Done }` |
| `@Iterator<T, E>` | `@Iterator<@Result<T, E>>` |
| `#[@context]` / `@Context<B, R>` as an effect | `-> @Component<R>` |
| `#[@iterator]` / `#[@asyncGenerator]` / `@AsyncIterator` | `@Iterator<@Result<…>>` / `@Stream<@Result<…>>` |
| `Iterable`, `IteratorStep`, `Yield<T, R>` | `YieldStep<T>` |
| `loop (xs) { x -> }` · `loop (cond)` · `loop await` | `for (xs) { x -> }` · `while (cond)` · `for await` |
| `-> Element` on a component that uses a hook | `-> @Component<Element>` |
| `@Component<C, R>` (decision 128's base) | `@Component<R>` (decision 354) |
| `type T(…) implement @Context<C>` | `type T(…) implement @Renderable` |
| `val c = use @getContext(T);` | a declared `Context<T>`, `use provide(…)` in the component that renders the reader, `val c = use context(…);` |

Decision 354's three rows have a codemod, `scripts/codemod-component-contexts.py`
(`scripts/AGENTS.md`): it rewrites the first two and reports each `use
@getContext(T)` at its line — which component provides the context is the
author's choice.

Four changes are not a rename and are reviewed by hand:

- **An `await` whose error used to propagate.** `await` answers the `@Result`
  now; where the function's return carries a `@Result`, write `try await`.
  Where it does not — a component returning `Element`, a `@Task<T>` — handle the
  error there: `try await x catch fallback`, a `case`, a navigation signal.
- **A `throw` in a hook or component** whose `T` is not a `@Result`: either the
  hook returns `@Component<@Result<T, E>>`, or the error is handled in its
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
| A decorator's output goes to one of the four places of § Decorators; **module-level `@emit` is gone** (decision 216), refused by name with the four places in its message | `@emit(source)` still compiles, splicing loose declarations into the module: the libraries' sites move to the four places first | `01-compiler/130-decorator-outputs` steps 5–6 |
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
by every caller; a `@Component` whose hooks node is synchronous is a plain
`function`, decision 375).

A default on an **imported function** is filled at the call like a local
one's when it is closed — a literal, `true` / `false`, `null`, a sign, an array
or tuple of those — so `import {helper.greet}; greet("w")` takes
`greet`'s declared greeting; a default that names a binding of its own module
cannot be written at the importer's call site, and leaving that argument out
of an imported call is the arity error (`'greet' expects 2 argument(s), got 1`).
A method called through a **behavior-typed** value is answered by the value's
own type on all four backends.

These forms are **deliberately absent**, so that none reads as unfinished work:

| Form | What the compiler says |
|---|---|
| `assert x is Some(n)` — `is` binding a payload | `error[is-variant-binding]`: `is` tests a type; it does not bind. Read the payload in a `case` arm |
| `type Shape { Circle(i32) }` — a variant payload with no field name | `error[field-needs-name]`: a field with no name, at the payload, naming `Variant(field: T)`. A payload nobody can name is a payload no `case` arm can bind |
| `val assert Ok(v) = parse("42") catch 0` | ``after `catch` the value is not a @Result — a `val assert` over a `@Result` takes no `catch` `` — the match is fatal, and `try … catch` is the form that supplies a fallback |
| `c ? a : b` | `error[ternary-absent]` — `if` is an expression: `val x = if (c) { a } else { b };` |
| `1 + if (c) { 2 } else { 3 }` — an `if` as an operand | `error[if-operand]`, at the `if`: an `if` begins an expression, as `try` / `await` do; bind it first |
| `x: any` — a type that takes anything | `any-type-removed`, at the annotation: the type that holds any value is `unknown`, tested with `is` before use |
| `<<` `>>` `&` `^` | `error[bitwise-operator-absent]` — there are no bitwise operators; `&&` and `\|\|` are the boolean ones, and a bit operation is a host function |
| `'a'` | `error[char-literal-absent]` — a character is a one-character string, `"a"` |
| `fn inner(…) { … }` inside a body | `error[nested-fn-decl]` — inside a body a function is a value: `val inner = { x -> … };` |
| `[..a, 3]` | `error[list-spread-not-last]` — the spread of an array literal comes last: `[3, ..a]` |
| `[...a]` | `error[list-spread-dot-dot-dot]` — `...` is a pattern's inclusive range; an array spreads with `..` |
| `implement A for P { … }` after a bodyless `type P(…)` | `error[implement-clause-for]` — the type's own clause is `type P(…) implement A { … }` |
| `#(x: 1, y: 2)` | `error[tuple-literal-label]` — a tuple literal is positional, `#(1, 2)`; labels belong to the tuple type, `#(x: i32, y: i32)` |
