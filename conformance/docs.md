# Botopink language reference

This reference describes the language as the compiler accepts it today. Every
example is a conformance cell (decisions 457, 461, 462): a line
`<!-- example: modules/<cell> -->` names `conformance/modules/<cell>/`, whose
`src/` is the program and whose `snapshot/` is its answer on every target —
the output, or the refusal and where — checked by `zig build test-conformance`;
`<!-- example: test/<suite> -->` names a `test` suite of `conformance/test/`.
Beside each cell, its `docs.md` holds the text of this reference it shows.
`zig build test-docs` checks that every example names a cell or a suite. A
table, a grammar, a layout sample or a runner's report is not a program and is
fenced as `text`.

A first program:

<!-- example: modules/greet -->

| Section | What |
|---|---|
| *Syntax changes* | what the 1.0.4-beta surface removed |
| *Program structure* | modules, a module's default function, imports, std and the libraries |
| *Bindings* | `val`, `var`, `@BeamMemory`, `fn` |
| *Types* | primitives, records, enums and their sections, `behavior`, generics, aliases, derived types, spread, unions and `is`, narrowing |
| *Expressions* | literals, numbers, arrays, indexing, operators, optionals, lambdas, blocks, `if`, `case`, loops, `assert`, `use` |
| *Functions* | recursion, inline parameter types, defaults, variadics, record parameters, effects, results, tasks, iterators and streams |
| *Comptime* | `comptime`, template functions, decorators, typed meta, template annotations, host bindings |
| *Builtins* | the builtins, what `@print` writes, a value's own type, `@src()` |
| *Tests* | `test` blocks, mocks |
| *Backends*, *Project manifest*, *The manifest schema* | the four targets; `botopink.json`, every field and every refusal |
| *Migrating from the effect annotations*, *Decided, not yet implemented* | the 1.0.10-beta move; what is decided and not built |

### How an example answers — a cell's snapshot

A cell's answer is one `.snap` file per module (decisions 457, 475, 485):
`snapshot/output/<module>.snap` is the answer every target gives, and
`snapshot/targets/<target>/<module>.snap` exists only where a target departs from
it — it refuses the module (a host binding it lacks) or names an abort in its
runtime's words, and replaces the module's whole answer there. A cell narrowed
to some targets names them in its `botopink.json` `"targets"`, as any project does — never in a
`targets` file, which `botopink cell check` refuses, naming the manifest field (decision 475 (1)).
A `test/` suite that narrows its targets is a project suite the same way — its own directory with a
`botopink.json` naming `"targets"` (decision 536); a single test file declares no narrowing, and a
`// targets:` line in it is a comment: the manifest is the one place for a restriction.
A cell's `{ "path": "deps/<lib>" }` dependency is relative to the cell's own directory, as a
project's is to its own; every cell found is reported, a cell that cannot run as a red naming it:

<!-- example: modules/local_dependency -->

A `.snap` is a record per line, in this order, one spelling per answer:

```text
botopink-cell 1          the format and its version — always line 1
refused <message line>   the compiler refuses the module: its `error…` line
at <file>:<line>:<col>   … and where, when the diagnostic is located
label <text>             after `at`: the label printed beside the caret, exactly as printed;
                         absent when the caret has none (the `hint` lines are not claimed)
from <file>:<line>:<col> after `at` and `label`: one `called from` line of a raise at build,
                         innermost first, down to the program's call, annotation or `comptime`
out <text>               one line the program printed (`out` alone: an empty line)
no-final-newline         the last `out` line ended without a newline
abort                    the program exits non-zero (the status is never pinned)
stderr <text>            after `abort`: the program's stderr contains <text>
```

A refusal and program output never share a file, and the header alone is the
empty answer — a module that compiles and, for `main`, a program that printed
nothing. A `label` follows its `at` once: one with no `at` before it, a second
one, or one in a file of program output makes the `.snap` malformed; a label
that changes, disappears or appears where none is accepted is a different
answer, and so is a `from` line that does. An `at` names its file relative to the cell — `src/main.bp`,
`botopink.json` (the column of the key that is refused), a dependency's module
under `deps/<lib>/…` — wherever the cell is checked from.

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

<!-- example: modules/hello -->

A package to run declares `fn main` in its entry module: `botopink run` of one
whose entry module declares none refuses before running anything, located at
that module and naming the missing `fn main` (decision 517) — the same answer
on commonJS, erlang, beam and wasm, under the `wasi` and the `browser` host:

<!-- example: modules/run_without_main -->

### Modules

Projects use an explicit, Rust-style module tree. The root module (`main.bp`
for a binary, `root.bp` for a library) declares which submodules to include;
the compiler follows these declarations instead of compiling every `.bp` it
finds.

<!-- example: modules/modules -->

Leaf modules are single files; folder modules use a `mod.bp` entry point.
`pub mod` is visible through the parent; a plain `mod` is private to its
declaring module's subtree. Only `pub` declarations are visible outside their
module.

A type is its declaring module's. Two modules that each declare `pub type
Order` keep two types, and each module's `Order(…)`, `Order.make(…)` and
`o.label()` reach its own (decision 430) — under `botopink run`, and under
`botopink test`, where every test module of `test/` is a module of its own:

<!-- example: modules/two_modules_one_type_name -->
<!-- example: test/two_test_modules_one_type_name -->

**`mod` binds the module it declares** (decision 337). In the module that
declares it, `mod config;` (or `pub mod config;`) binds `config` as a namespace,
as `import {config};` binds it elsewhere — `config.splitPath(x)`, a type
`config.Pair` in a signature, a constructor `config.Pair(…)`, a variant path,
a function as a value, with no import. The namespace walks a folder module's
tree: with `src/text/mod.bp` declaring `pub mod split;`, `mod text;` alone
reaches `text.split.splitPath(x)` — each step a `pub mod` and the leaf `pub`; a
plain `mod split;` is private to `text`'s subtree, and `text.split` from outside
it is `private-module` at `split`. A sibling or nested module reaches `config`
only by import (`import {config};`, `import {text.split};`). There is no
combined form and no re-export syntax: a folder's `mod.bp` exposes a
submodule's declaration with a value or a type of the same name — `pub val
splitPath = split.splitPath;`, `pub type Pair = split.Pair;` — which is that
declaration, not a second one, so the name has one public path
(`text.splitPath`) and the submodule can stay private.

<!-- example: modules/mod_namespace_reexport -->

In the declaring module `import {config};` is a second spelling of the
namespace, `redundant-module-import` at the item (delete it); a top-level
declaration named like a declared module is `import-name-collision`.

#### A module's default function

A module may have one **default function**, which its importer names
(decision 289). `pub default fn (…) -> R { … }` binds no name in its own
module; `pub default <name>;` makes a function the module declares its default
(it keeps its name there, e.g. for a recursive call); `pub default fn
Name(…)` is the shorthand of both. `import {m.card};` — whose path names the
module, not an item of it — binds the default under the path's last segment,
`import {m.card as Card};` under the alias. A decorator on an anonymous
default reads the file's name as `compiler.name(decl)`. A second default is
`default-twice`; `pub default nope;` naming no function is `default-unknown`.

<!-- example: modules/default_fn_import -->
<!-- example: modules/default_named_twice -->
<!-- example: modules/default_unknown -->

#### A `.bpp` file

A `.bpp` file is another spelling of a module (decisions 198, 199, 212, 213,
221, 275, 289, 338). The application's `botopink.json` names, in `"bpp"`, the
dependency whose declarations std's `bpp` annotations mark (decision 361;
§ The manifest schema); the toolchain reads those marks and knows no library,
tag or type name.

The **header** runs from the first line to the first separator line: `---`
(the markup follows, to the end of the file) or `--- style ---` (the style
section follows, closed by a `---` line, then the markup). A file with no
separator line is markup only. The file unfolds to a module:

- the header's declarations — `import`, `type`, `pub …`, a private `fn`, a
  `test`, a decorated declaration — stay at module level, as written (a `test`
  is found and run by `botopink test` as one in a `.bp` module is,
  `test/bpp_header_test`);
- the module's anonymous `pub default fn (props: Props) -> R` — `()` when the
  header declares no `Props` — whose body is the header's statements (`val`,
  `var`, `use`, `if`, an expression statement) in order, so they read `props`;
- `` use <style> @`<the section>`; `` when there is a style section, onto the
  package's `#[bpp.style]` function, after the statements;
- `` return <html> @`<the markup>`; `` onto the package's `#[bpp.html]`
  function: the template text (decision 577) is the bytes after the separator
  line, to the end of the file;
- `R` is the `R` that function answers. The imports of the two
  functions bind no name the header can reach.

A decorator written on the header's last line, before the separator line,
annotates the unfolded function, whose `compiler.name(decl)` is the file's name; no
decorator comes from the file's name. `mod x;` resolves `x.bp`, then
`x.bpp`, then `x/mod.bp`; the importer names the default function
(`import {components.Card};`). A file whose name is no identifier is declared
and imported by it between backticks (decision 561, § Bindings): `` pub mod
`not-found`; `` resolves `not-found.bpp`, `` import {pages.`not-found` as
NotFound}; `` binds its default function as `NotFound`, and without an alias
(`` import {pages.`not-found`}; ``) the bound name is `` `not-found` `` — an
alias is optional. A diagnostic in the file is reported at its own
line and column — the header's, the markup's and the style section's alike.

<!-- example: modules/bpp_unfold_props -->
<!-- example: modules/bpp_unfold_without_props -->
<!-- example: modules/bpp_decorator_last_line -->
<!-- example: modules/bpp_diagnostics_located -->
<!-- example: modules/bpp_not_found_aliased -->
<!-- example: modules/bpp_not_found_unaliased -->
<!-- example: test/bpp_header_test -->

Refused, each at its line: a first line `---` (`the header starts on the first
line; a .bpp has no opening ---`), a `--- style ---` after the markup, a second
style section, a style section no `---` line closes, a backtick in a section
(it would end the template text), `X.bp` beside `X.bpp` (one module written twice), and a
header declaration written after a statement (decision 552: the header reads top
to bottom as written, the declarations first and the statements after; the
refusal is at the declaration and names the statement before it, and the unfold
moves no declaration).

<!-- example: modules/bpp_first_line_separator -->
<!-- example: modules/bpp_style_after_markup -->
<!-- example: modules/bpp_second_style_section -->
<!-- example: modules/bpp_style_unclosed -->
<!-- example: modules/bpp_beside_bp -->
<!-- example: modules/bpp_declaration_after_statement -->

### Imports

`from "<name>"` names a **package** — std or a dependency declared in
`botopink.json` — and nothing else (decision 206). A module of the importing package is imported by its path
inside the braces, with no `from`. An import always names where its names come
from (decision 337): an item with no `from` whose first segment names no module
of the package — `import {perimeter};` — is `shorthand-import` at the item, its
fix written (below).

<!-- example: modules/import_module_paths -->

A dependency's module named whole — `import {shapes} from "kit"` for
`kit`'s `shapes` — is a namespace as a module of the package is: `shapes.Pt`
written as a type, `shapes.Pt(…)` and `shapes.origin()` called, `shapes.shift`
a function value (decision 430):

<!-- example: modules/package_module_namespace -->

The shorthand is refused at the item, and the refusal writes the import as it
is spelled instead: the path of the one module of the package that declares the
name `pub`, every candidate when several do, `unresolved import` when none does
(pinned by `conformance/modules/shorthand_import_one_candidate`,
`shorthand_import_several_candidates` and `modules/shorthand_import`):

```text
// src/main.bp — `pub mod geometry;` declares `pub fn perimeter`
import {perimeter};

error: shorthand-import: `perimeter` names no module of this package — write import {geometry.perimeter};
 --> src/main.bp:2:9
```

`from` never names a module of this package. Beside a module named like a
package, the brace form reaches the module and `from` the package:

<!-- example: modules/import_bundled_package_beside_own_module -->

A package wins its name: `from "log"` is the dependency `log` although the package
has a module `log` of its own, so a dependency declared later never changes
what an existing import means — an import that could have meant the module is
already the brace form. `from` naming a module of the package is refused at the
source string, and the refusal writes the import as it is spelled instead
(over the `imports` project above; pinned by
`conformance/modules/import_own_module_with_from`):

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
and calls, in the `.d.ts` and at compile time. Pinned by
`conformance/modules/two_packages_one_module_name`. A module named like its package — `src/p.bp`
of the package `p` — is one module, `p/p`, like any other: a program using it that is refused
answers its own refusal alone.

<!-- example: modules/module_named_like_its_package -->

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
parseJson}`). One item that reaches two declarations — `import {parse} from
"kit"` while two modules of the package `kit` declare `pub fn parse` — is not
refused itself: every **use** of the name is, where it is written, naming both
(`ambiguous-import-use`), and the item that names the module (`import
{a.parse} from "kit"`) is the way out. An alias reaches a type and a type alias too (decision 110):
`import {collections.Dict as D}` brings `D`, a name for `Dict` in the program's
own text — the emitted code keeps `Dict`. Two same-named types of two modules
are two types when each is imported under an alias, or one of the two is
(decision 310): `import {a.p.Policy as APolicy}; import {b.p.Policy as
BPolicy};` — each alias names its own type in every type and value position,
a function of either module taking or answering its `Policy` takes or answers
that alias's type — called by name, through a module namespace (`pa.slow()`),
from an imported template's built code or a decorator's member alike —, `is`
tells them apart, and each value prints as declared. A std type is one of the
two as well (`import {collections.Dict as D} from "std";` beside `import
{kit.Dict as KitDict};`).
Without an alias the second item binds the name again (`import-name-collision`,
decision 170), and a type this module declares beside an aliased import of a
same-named type is refused too (question B-23-a). An activation cannot be
renamed (`import-alias-on-activation`). A leaf that names a folder is a namespace of
its submodules (decision 110): after `import {io} from "std"`, `io.fs.readText(p)`
calls `io/fs`'s `readText` — only the modules the program reaches are imported —
and a module namespace reaches its types, so `import {collections} from "std"`
allows `collections.Dict.empty()` beside `collections.lt()` (decision 111's
constructors are type-scoped).

A namespace brings no bare name of its module, std's as a module of the
package: neither a type's constructor nor an enum's variant enters scope. After
`import {failure} from "std"`, `failure`'s `HostErrorName.Error` is
`failure.HostErrorName.Error`, and a bare `Error` is what it is without the
import — no name in an expression (decision 208), the `@Result`'s error in a
pattern:

<!-- example: modules/import_std_namespace_no_bare_variant -->

A type leaf brings the types its fields and methods name along, as types —
from std as from a module of the package: `import {failure.HostError} from
"std"` alone builds a `HostError` with `name: .Error` and matches its `name`
by the variants of `HostErrorName`, which it never names. A refusal met in a
std module's declaration is located in that module's file:

<!-- example: modules/import_std_leaf_field_types -->

<!-- example: modules/import_group_modifier -->

<!-- example: modules/import_tree_group -->

<!-- example: modules/import_record_beside_std_record_of_same_name -->

<!-- example: modules/import_two_types_one_name -->

<!-- example: modules/import_two_enums_one_name -->

<!-- example: modules/import_same_type_name_two_packages_one_aliased -->

<!-- example: modules/import_two_types_one_name_reached_indirectly -->

<!-- example: modules/import_std_type_beside_aliased_type -->

<!-- example: modules/import_two_types_one_name_unaliased -->

<!-- example: modules/own_type_beside_aliased_type_import -->

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
| the root (pure) | `collections` (`Dict`, `Set`, `Queue`, `Order` — a constructor is called on its type: `Dict.empty()`, `Dict.ofEntries([#("a", 1)])`, `Set.fromList(xs)`; a `Set` member is compared by `==`, so two structurally equal records are one member on every target, decision 210), `math`, `decimal` (`Decimal`, `Rounding`), `path`, `url`, `querystring`, `json`, `regex`, `unicode`, `string_builder`, `encoding`, `hash`, `escape`, `async`, `bpp` (the four annotations a framework marks its `.bpp` roles with — `#[bpp.html]`, `#[bpp.style]`, `#[bpp.htmlPrelude]`, `#[bpp.stylePrelude]` — and `Prelude`, decision 361); `erlang` and `beam` (the target's surface) |
| `io` | `io.fs`, `io.http`, `io.net`, `io.clock`, `io.random`, `io.os`, `io.env`, `io.process` |
| `testing` | `testing.asserts`, `testing.mocks` (`testing.snapshots` is the `snap` library, decision 391) |

<!-- example: modules/import_std_groups -->

**What is generic lives in std, once.** A primitive several libraries need —
reading a number out of text, walking a decoded JSON value, a retry loop — is
std's, and a library calls it rather than writing its own:

| Where | What | Answers |
|---|---|---|
| a `string` | `s.parseInt()` | `@Result<i64, string>` — an optional `+` / `-` and digits, the whole string; anything else (`"4 2"`, `"42x"`, `"0x2A"`, `""`) is an `Error` naming the input, and so is an integer past the `i64` range, −2^63 … 2^63 − 1 |
| a `string` | `s.parseFloat()` | `@Result<f64, string>` — a sign, digits, an optional `.` with digits on both sides, an optional exponent; `.5`, `1.`, `NaN`, `Infinity` are an `Error`, an overflow too; the nearest `f64`, the one `json.decode` answers |
| a `string` | `s.indexOf(x)`, `s.lastIndexOf(x)` | an index `s.at` and `s.slice` take, on every target (`-1` when absent) |
| `json.Json` | `v.kindName()`, `v.isObject()`, `v.members()`, `v.field(key)`, `v.str()`, `v.items()` | the readers of a decoded value: `members` and `items` are `[]`, `str` is `""` and `field` is `null` for a value of another kind — none throws |
| `hash` | `pbkdf2Sha256(password, salt, iterations, length)` | `length` bytes of PBKDF2-HMAC-SHA256 as unpadded base64url; the password and the salt are text |
| `io.clock` | `parseDuration(text)` | `@Result<i64, string>` — the milliseconds of digits and one unit, `ms` `s` `m` `h` `d` (`"30s"` is `30000`); `"30"`, `"1.5s"`, `"30 s"`, `"30S"` are an `Error` |
| `async` | `RetryPolicy(maxAttempts, initialMillis, multiplier, maxMillis)`, `nextDelay(policy, attempt)`, `retry(policy, work)` | `nextDelay` is `?i64` — `initialMillis × multiplier^(attempt − 1)`, never above `maxMillis`, `null` past `maxAttempts`; `retry` runs a `fn() -> @Task<@Result<T, E>>` until it answers `Ok` and answers the last `Error` when every attempt failed |
| `io.fs` | `walk(root)`, `glob(pattern, root)`, `removeTree(path)` | relative, `/`-separated, sorted paths, the same for every spelling of the root; a dangling link under `walk` is an `Error` naming it; `glob`'s `*` and `**` do not match a name starting with `.` unless the segment writes the dot, and do not descend through a link to a directory |

<!-- example: modules/std_generic_primitives -->

<!-- example: modules/async_retry_policy -->

`parseInt` and `parseFloat` answer the same on every target, the wasm one included: every `i64`
is read, one past either end an `Error`, and a numeral is converted to its nearest `f64`:

<!-- example: modules/string_parse_int_i64_range -->

<!-- example: modules/string_parse_float_every_target -->

**Exact decimals.** std's `decimal` is Java's `BigDecimal` (decision 332): a
`Decimal` is an unscaled `bigint` and a `scale`, the value `unscaled × 10^-scale`
(`Decimal(unscaled: 150n, scale: 2)` is `1.50`). `add`, `sub` and `mul` are
exact — the sum's scale is the larger of the two, the product's their sum;
`div(other, scale, rounding)` answers at the scale it is given, rounded by a
`Rounding` — `Up`, `Down`, `Ceiling`, `Floor`, `HalfUp`, `HalfDown`, `HalfEven`,
Java's `RoundingMode` — and has no form without them; `Unnecessary` asserts the
quotient is exact, and an inexact one aborts (`Decimal.div: rounding
necessary`), as a zero divisor does (`Decimal.div: division by zero`).
`compare(other)` is `-1`, `0` or `1` by numeric value, whatever the scales
(`1.0` against `1.00` is `0`); `toString()` writes the plain text with the scale
kept (`"1.00"`, `"100"` for a negative scale, never an exponent); and
`Decimal.parse(text)` reads a numeral — an optional sign, digits, an optional
`.` with digits, an optional exponent — into its scale (`"1.50"` is scale 2,
`"1E+2"` scale −2), anything else an `Error` naming the text. Pure botopink over
`bigint`: one answer on the four targets.

<!-- example: modules/decimal_exact_arithmetic -->

<!-- example: modules/decimal_div_rounding_necessary_aborts -->

<!-- example: modules/decimal_div_by_zero_aborts -->

**`io` answers alike on every target.** `io.clock`'s `formatIso8601`,
`toCivil` and `offsetMinutes` take the epochs RFC 3339 writes,
0000-01-01T00:00:00Z … 9999-12-31T23:59:59.999Z (−62167219200000 …
253402300799999 milliseconds), the same on every target, and past them abort
naming the value (`clock.toCivil: 253402300800000 is past RFC 3339's range`)
(decision 497). `fs.stat`'s `mtime` is whole seconds, as epoch milliseconds, on
every target (decision 499). The two run where `io` has a host binding:
commonJS, erlang and beam.

<!-- example: modules/clock_rfc3339_domain -->

<!-- example: modules/clock_format_past_rfc3339_aborts -->

<!-- example: modules/clock_civil_past_rfc3339_aborts -->

<!-- example: modules/clock_offset_past_rfc3339_aborts -->

<!-- example: modules/fs_stat_mtime_whole_seconds -->

### The command line, `io.stdin`, `io.terminal` and `io.process`

What a command-line program needs of its host (decision 506 (1)), the same on commonJS, erlang and
beam, and refused at the call on wasm (`std-unsupported-on-target`, decision 518 (4)); every failure is a
type of its own module (decision 431-a).

`io.stdin.readLine()` is a `@Task<?string>`: the next line without its `\n` or `\r\n`, a last line with no
terminator included, `null` at the end of input — again and again once it has ended. `isTTY()` is `false`
for a pipe, a file or `/dev/null`; `readChunk()` is the byte-level read, whatever has arrived, `null` at the end.

<!-- example: modules/std_io_stdin_eof -->

`io.terminal` is the terminal. `stdoutIsTTY()` and `size()` (`#(columns, rows)`, `null` with no terminal) say what
the output is; `setRaw(on)` answers `@Result<void, TerminalError>` (`NotATerminal` when standard input is none) and
`keys()` is the `@Stream<Key>` of key presses (`Char`, `Ctrl`, `Alt`, `Enter`, `Tab`, `Backspace`, `Delete`,
`Escape`, the arrows, `Home`, `End`, `PageUp`, `PageDown`, `Unknown`) that `parseKey(sequence)` decodes. With no
terminal the non-terminal answers are the same on every target:

<!-- example: modules/std_io_terminal_not_a_tty -->

`io.process.onSignal(s, handler)` runs `handler` each time the process receives `s` (`Int`, `Term`, `Hup`, `Winch`);
several handlers for one signal run in the order they were added, and while one is installed the signal no longer
ends the process. It answers `@Result<void, ProcessError>`.

<!-- example: modules/std_io_signal_handlers -->

`io.process.spawn(cmd, args)` starts a child with no shell, sharing the parent's streams, and answers
`@Result<Child, ProcessError>` without waiting: `NotFound` and `PermissionDenied` say why nothing started.
`Child.wait()` is a `@Task<i32>` of the exit status (`128 + n` for a child ended by signal `n`) and answers the same
again; `Child.kill(s)` sends a signal and is `NoSuchProcess` once the child has ended.

<!-- example: modules/std_io_process_spawn -->

`Child.forwardSignals()` carries the parent's `Term`, `Hup` and `Winch` (and `Int` where the target can catch it)
to the child: the parent no longer ends on them, and ends when the child does.

<!-- example: modules/std_io_process_forward_signals -->

### The file system, `io.fs`

Every `io.fs` function that can fail answers `@Result<…, FsError>` (decision 540) — never a `string`
error — and `FsError` is std's, the same on every target:

```text
pub type FsError {
    NotFound(path), PermissionDenied(path), IsDirectory(path), NotDirectory(path),
    AlreadyExists(path), InvalidUtf8(path, offset: i64), Other(path, message),
}
```

The same OS error is the same variant on every target (`ENOENT` on commonJS, `enoent` on erlang and
beam: `NotFound`), whichever function met it. `path` is the path the caller wrote (for `copy`, the
source; for `walk`, the root); `Other.message` is the host's text; a dangling link under `walk` is an
`Other` whose message names it. `exists` stays a `bool`: it cannot fail.

<!-- example: modules/fs_error_variants -->

`FsError` carries its own text (decision 563): `e.message()` answers one string per variant, `<what>: <path>` —
`not found: <path>`, `permission denied: <path>`, `is a directory: <path>`, `not a directory: <path>`,
`already exists: <path>`, `not UTF-8: <path> at byte <offset>`, and `<path>: <message>` for `Other` — the same on
every target; a library that carries an `io.fs` failure into a `string` writes `e.message()`, no `case` of its own.

<!-- example: modules/fs_error_message -->

**The whole-file shortcuts.** `readBytes`, `readText`, `writeBytes`, `writeText` (creating or
truncating), `appendText` (creating), `stat` (`size: i64`, `mtime: i64`, `isDir: bool`) and the directory
functions (`exists`, `list`, `mkdir`, `mkdirRecursive`, `rm`, `removeTree`, `copy`, `walk`, `glob`).
`readText` is UTF-8 checked on every target: bytes that are not UTF-8 are `InvalidUtf8(path, offset)`,
`offset` the byte where the first invalid sequence starts — never node's silent U+FFFD, nor erlang's
unchecked binary.

<!-- example: modules/fs_whole_file_shortcuts -->

<!-- example: modules/fs_read_text_not_utf8 -->

**The handle.** `open(path)` (reading) and `create(path)` (writing, creating or truncating) answer a
`File`, a `Closeable` the writer closes — `val f = try fs.open(p); defer f.close();` — and nothing checks
that it is. Its calls are `path()`, `size()`, `read(n)` (up to `n` bytes, empty at the end), `bytes()` and
`text()` (the rest from the position), `hash()` (the SHA-256 of the whole file, lowercase hex),
`write(b)` and `close()`; each that can fail answers `@Result<…, FsError>`.

<!-- example: modules/fs_file_handle -->

<!-- example: modules/fs_file_defer_close -->

`chunks(size = 65536)` and `lines()` are `@Stream<@Result<…, FsError>>`: the rest of the file in pieces of
at most `size` bytes, or line by line with `\n` and `\r\n` stripped. An error ends the stream; a line that
is not UTF-8 is `InvalidUtf8`.

<!-- example: modules/fs_file_streams -->

The `io.fs` functions have a host binding on commonJS, erlang and beam; the `wasi:filesystem` bindings
of wasm are not written yet (a build for wasm refuses a program that calls them, naming the host cell
that has no binding).

A library is imported the same way, under the name `botopink.json` declares it
in `dependencies`:

<!-- example: modules/import_bundled_package_beside_own_module -->

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

```text
import {match.matchPath, table.parseTable} from "routing";
import {envelope.writeEnvelope} from "actions";
import {decorators.validated} from "validation";
```

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

**An import of a module that failed to check names that module.** A module the
build refuses — a syntax error, a type error — exports nothing, and the error to
fix is its own. An importer that uses a name it takes from it is refused once,
at the import item, naming the module and its file (`import-of-failed-module`:
`` `area` comes from `shapes`, which failed to check — its own errors are reported
there (src/shapes.bp) ``) — the file is the label the module's own errors are printed at, `a/client.bp` for a
dependency's module —, never as an `unbound variable` at the use; the importer's importers name the importer the
same way, so every line of the report leads to the one real error. A name the
named module does not declare, where that module checked, is still refused as
missing:

<!-- example: modules/import_of_failed_module -->

## Bindings

A keyword is reserved in every position: no binding, parameter or field may
take its name (`from`, `type`, `case`, …). Writing one where a name is declared
is `reserved-word-as-name`, which names the word, and the label under the caret
names it too (``reserved word `from` ``):

<!-- example: modules/reserved_word_field_name -->

<!-- example: modules/reserved_word_param_name -->
<!-- example: modules/reserved_word_as_binding_name -->

A name written between backticks is an identifier, anywhere a name goes
(decision 561, Kotlin's escaped identifier): `` `text` `` names the text between
the backticks — any characters but a backtick and a line break, a keyword
included — as a binding, a parameter, a function, a type, a variant, a field, a
module path's segment, an import item and its alias. `` `not-found` `` and
`not-found` never meet: the plain spelling stays `not - found`. A name that is
already an identifier means the same written either way — `` `count` `` is
`count`, and `botopink format` writes it `count`. A diagnostic prints such a
name as written, between its backticks; each backend gives it a name of its own
that meets no other name of the module (erlang a quoted atom, commonJS and wasm
an escaped name), and a printed value spells it as written.

<!-- example: modules/backtick_name_binding -->
<!-- example: modules/backtick_name_parameter -->
<!-- example: modules/backtick_name_function -->
<!-- example: modules/backtick_name_type -->
<!-- example: modules/backtick_name_field -->
<!-- example: modules/backtick_name_module_segment -->
<!-- example: modules/backtick_name_import_item -->
<!-- example: modules/backtick_name_in_diagnostic -->

An empty `` `` `` is refused at the lexer (`empty backtick identifier`), and so
is a line break before the closing backtick (`unclosed backtick identifier`),
each at the opening backtick.

<!-- example: modules/backtick_name_empty -->
<!-- example: modules/backtick_name_line_break -->

### val — immutable binding

<!-- example: modules/val_binding -->

Types are inferred via Hindley-Milner unification. Explicit annotations are
optional:

<!-- example: modules/val_annotated -->

A `val` is immutable: assigning to it — a local or a module-level `val`, from
any `fn` body — is a compile-time error. The rule is the same one node already
enforced at run time (`const`); it now holds on every target before any code
is emitted.

<!-- example: modules/val_cannot_be_assigned -->

A `val` may bind a pattern instead of a name when the pattern matches every
value of the initialiser's type, so the binding has no failure path: a list
pattern that is only a spread (`val [..rest] = xs;` binds the whole list), and
the constructor of a one-variant `type` or a record's own constructor whose
every argument is a name, a `_` or such a constructor in turn — so constructors
nest (`val Pair(Circle(r), n) = p;`). Any other pattern is
`refutable-val-pattern`; `val assert` and `case` say what a mismatch does.

<!-- example: modules/val_spread_only_list_pattern -->

<!-- example: modules/val_nested_ctor_pattern -->

A `val` at module level is part of the **module body**: it is evaluated **once**,
in declaration order, when the module loads — before `main` runs and before the
first `test {}` block. Reading the name afterwards does not evaluate it again,
and a `_`-named statement, which nothing reads, runs just the same. So a module
whose initialisers have effects registers itself by being loaded:

<!-- example: modules/val_runs_at_module_load -->

An initialiser is any expression, a call included (`val t = "a b".split(" ");`):
the functions of the module read the bound value, whatever else they call:

<!-- example: modules/module_val_call_init -->

An initialiser reads the module's earlier `val`s, bound by then — a `_`-prefixed name a program
writes (`val _c = …`) is a binding like any other, read by name; only `_` itself is a statement:

<!-- example: modules/module_val_reads_module_val -->

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

<!-- example: modules/module_var -->

The same holds for a `var` of a dependency's module, read and written through
that module's functions:

<!-- example: modules/module_var_in_dependency -->

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

<!-- example: modules/beam_memory_annotations -->

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
`counts.at(k)`, written as `counts = counts.insert(k, v)` and counted as
`counts = counts.bump(k, n)` (`Dict.bump`, integer values, an absent key counting from 0 — one
atomic `ets:update_counter`, so concurrent bumps of one key lose none), and nothing else
names the var — measured, two processes writing 20 000 times each to their own
key finish at `20000` and `20000`; at 10 keys a write is 5× cheaper, at 10 000
keys 5 000×. Choose `keyed: true` whenever more than one process writes; keep
the default when the dict is replaced whole.

<!-- example: modules/beam_memory_ets_keyed_bump -->

`bump` is atomic only on integer rows (decision 340): on a keyed `Dict` of `f64` it is refused at
the write, naming the rows' type. A `bump` whose key or amount reads the var, and the increment
written out — `counts = counts.insert(k, (counts.at(k) ?? 0) + n)`, which is not recognised as a
`bump` — are the recompose refusal, as any row computed from the var's own rows is:

<!-- example: modules/beam_memory_ets_keyed_bump_non_integer -->
<!-- example: modules/beam_memory_ets_keyed_bump_reads_itself -->
<!-- example: modules/beam_memory_ets_keyed_read_modify_write -->

On any other `Dict`, `bump(key, by)` is `insert(key, (at(key) ?? 0) + by)`, on every target: an
absent key counts from 0, and the dict it was called on is unchanged:

<!-- example: modules/dict_bump -->

`bump` exists for an integer `V` alone (decisions 340, 534): on a `Dict` whose `V` is not an integer
type the call is refused, located at the call:

<!-- example: modules/dict_bump_non_integer -->

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

<!-- example: modules/fn_declaration -->

A declaration with no body says what it answers: `fn f(x: string);` with no `-> R` is `bodyless-fn-needs-return-type`, whose label suggests `-> void` or a body.

<!-- example: modules/bodyless_fn_no_return_type -->

A value leaves a function through `return` or its tail (below), so a `fn` whose return type has a
value must end every path with one of them (or `@panic` / `@todo`) —
`fn f() -> i32 { val x = 1; }` is refused at `-> i32`. An effect return is judged by what
running off the end would hand out: a `@Result` in any layer has a value (`Ok` or `Error`), so
`-> @Result<void, E>` and `-> @Task<@Result<void, E>>` end with the empty `return;`, and so does a
`@Task<T>` or `@Component<T>` whose `T` is a value; one whose `T` is `void` falls through as a
`void` fn does. `@Iterator` and `@Stream` end by running off their body.

A function body's last expression written without `;` is its value (decision 409) — in every
body: a named `fn`, a method, a function expression and a lambda. `fn inc(x: i32) -> i32 { x + 1 }`;
an early `return` stays (`fn sign(n: i32) -> i32 { if (n < 0) return -1; n }`), and every `return
x;` stays valid. With `;` it is a statement, and a body with `-> R` then needs a `return` — `fn
semi(x: i32) -> i32 { x + 1; }` is refused at `-> i32` as above. A braced `if` / `case` / loop at the
end is a statement, never the tail. The tail is checked against `-> R` at the expression; in a body
answering nothing (no `-> R`, or `-> void`), a tail of another type is refused at it.
`botopink format` neither adds nor removes the tail's missing `;`, and prints a body of one tail on
one line when it fits:

<!-- example: modules/fn_tail_value -->

<!-- example: modules/method_tail_value -->

<!-- example: modules/fn_tail_type_mismatch -->

<!-- example: modules/fn_tail_in_void -->

An early `return` from inside a loop or a `case` arm leaves the function, and the tail is its value
on every other path; an `if` / `else if` / `else` expression is a tail like any other, and a tail
may name a `case` bound by a `val` before it. A method answering nothing refuses a tail of another
type as a free function does; a `void` tail — a call answering nothing — is accepted in a function,
a method and a lambda that answer nothing. A tail is the function's value wherever its body runs:
at compile time (`comptime square(3)`), and in a function answering `@Result<T, E>`, where it is
the `T` as `return value;` is:

<!-- example: modules/fn_tail_after_loop_return -->

<!-- example: modules/fn_tail_if_else_chain -->

<!-- example: modules/fn_tail_case_arm_block -->

<!-- example: modules/method_tail_in_void -->

<!-- example: modules/fn_tail_void_call -->

<!-- example: modules/fn_tail_comptime -->

<!-- example: modules/fn_tail_result -->

An empty body is a function that does nothing: `pub fn main() {}` builds and runs, printing
nothing, and a call of a `fn` written `{}` runs and answers nothing, on every target:

<!-- example: modules/fn_empty_main -->

<!-- example: modules/fn_empty_body_call -->

## Types

### Primitives

`i32`, `i64`, `u32`, `u64`, `f32`, `f64`, `bigint`, `string`, `Bytes`, `bool`,
`void`. Their methods are declared in `libs/std/src/primitives.bp`.

A `string` is indexed by codepoint on every target (decision 320): `length`,
`at`, `slice`, `indexOf` and `lastIndexOf` count codepoints — `"e\u{301}".length`
is 2 and its `.at(1)` is `"\u{301}"`, `"👍".length` is 1 — never UTF-16 units,
bytes or grapheme clusters, so the index `indexOf` answers is the one `at` and
`slice` read back. A JavaScript host template receives and answers codepoint
indices.

<!-- example: modules/string_index_of_codepoints -->

`Bytes` is an immutable sequence of bytes (decision 346): an Erlang binary on
erlang and beam, a `Uint8Array` on commonJS, a buffer in wasm memory. No literal
is `Bytes`, and nothing converts between `Bytes` and `string` but two calls:
`Bytes.fromUtf8(s)` answers the UTF-8 bytes of `s`, and `b.toUtf8()` answers
`@Result<string, string>` — the text, or `Error("Bytes.toUtf8: not valid
UTF-8")` for bytes that are not well-formed UTF-8 (a sequence cut short, an
overlong form, a surrogate, a code point past U+10FFFF; a byte order mark is kept).
A string literal where `Bytes` is expected, and `Bytes` where a `string` is, are
mismatches at the value. Every index counts bytes: `length()` (and the property `length`, the same count), `slice(start,
end)` with `string`'s bounds (a negative index counts from the end, both clamp,
an absent end is the length — `b[1..3]`, `b[2..]`), and `a.concat(b)` joins two.
`==` and `!=` compare the bytes; `Bytes` takes no other operator (`+` and a string
template do not read it as text). A host binding takes and answers `Bytes` as its
target holds it. `Bytes` does not widen to `unknown` (so `@print` does not take it),
and `is` does not test it — erlang holds it and a `string` alike. A `Bytes` value
may exist at build (decision 520): a `comptime` computes one, and the artifact
carries it as a build constant — an Erlang binary, a `Uint8Array` on commonJS, a
wasm data segment (`@embed`'s `Asset.bytes`, § `@embed` and `Asset`).

<!-- example: modules/bytes_round_trip -->
<!-- example: modules/bytes_length_property -->
<!-- example: modules/bytes_comptime -->

std's `encoding` bridges `Bytes` and text losslessly: `base64EncodeBytes(b)` and
`hexEncodeBytes(b)` answer the text of the bytes as they are, and
`base64DecodeBytes(s)` / `hexDecodeBytes(s)` answer `@Result<Bytes, EncodingError>` with
the text codecs' rules and `Error` variants (`NotBase64`, `NotHex`, decision 486).

<!-- example: modules/bytes_encoding_bridges -->
<!-- example: modules/bytes_string_literal -->
<!-- example: modules/bytes_where_string_expected -->
<!-- example: modules/bytes_plus_string -->

### type — records

A `type` whose fields are written in parentheses is a record: the declaration
mirrors construction.

<!-- example: modules/record_construct_read -->

A record is immutable: a field is never assigned. A changed copy is the update
form — `..base` and the fields that change, by label; every other field is read
from `base`, which is a name or a path of names (a call there is refused, since
it would run once per copied field — bind it with `val` first):

<!-- example: modules/record_update_spread -->

A body adds methods:

<!-- example: modules/record_method -->

An associated function — one taking no `self` — named without a call is a
function value of its declared signature, as a top-level `fn` is: `apply(1,
Box.wrap)`, `val w = Box.wrap;`, through an imported type or an enum alike
(decision 430):

<!-- example: modules/associated_fn_as_value -->

The record such a value's call answers is read by its field, for a member a
decorator adds as for one written by hand:

<!-- example: modules/associated_fn_value_answers_record -->

`self` is the receiver of a method, and names nothing else: a parameter called
`self` is written only in a `type`, `behavior`, `implement` or `extend` body.
A free function that names one is `self-param-outside-type`, refused at the
name.

<!-- example: modules/self_param_free_fn -->

The field list is always written. A record with no fields is `type Name()`,
and with members `type Name() { … }`; braces holding variants declare an enum,
and braces holding only associated functions (none taking `self`) declare a
**namespace type** (decision 329) — `type Name { fn make() -> i32 { … } }`,
called `Name.make()`, with no value: `Name()` is `namespace-type-construction`
and a `self` function in it `namespace-type-self`. A `type` declared in a type's
body is its associated type, named `Owner.Name` (decision 330), so a name the body already gives a member is `assoc-type-duplicate`, refused at the type's name. `type Name {}` is
`type-without-field-list`, refused where the `()` belongs:

<!-- example: modules/record_empty -->
<!-- example: modules/assoc_type_named_like_member -->
<!-- example: modules/namespace_type_self -->
<!-- example: modules/type_empty_braces -->

An anonymous group of values is a tuple, not a type declaration. A tuple is
positional at run time; a label is a compile-time name, lent by the variable
used to build it or written in the type:

<!-- example: modules/tuple_label_from_variable -->

A tuple's `bool` element prints `true` / `false`, read by its label or its
index, a module-level tuple's read inside a function too:

<!-- example: modules/global_tuple_bool_field -->

### type — enums

A `type` whose body lists variants is an enum:

<!-- example: modules/enum_declaration -->

A variant is built through its type — `Color.Red`, `Shape.Circle(radius: 2.0)`;
inside a `case` pattern the bare name is enough. A bare `Red` in expression
position type-checks but no backend lowers it (the generated program reports an
unbound `Red` at run time), so always write the qualified form.

#### Sections of an enum

An enum's body may group variants into **sections**, and a section may nest.
A section is itself a type (`Token.Color`), and a leaf is reached by its path:

<!-- example: modules/enum_sections -->

A section holds variants and nested sections, not methods: a `fn` inside a section's braces is `section-body-method`, refused at the `fn` — declare it in the enum's own body.

<!-- example: modules/section_body_method -->

A variant name is declared once per level of the body (`enum-variant-duplicate`
at the second). The same name at two levels is two members, told apart by the
path and by the position's expected type: with `Layout { Break { After } }`
beside `After(inner: Token[])`, `Token.After(…)` — and `.After(…)` where a
`Token` is expected — is the payload variant, `.After` where a
`Token.Layout.Break` is expected is the leaf, and a `case` over a `Token` matches
the top-level `After` while one over the section matches the leaf.

<!-- example: modules/enum_variant_duplicate -->

**Which enum a leading-dot path names is decided by the type the position
expects.** More than one enum can carry the same path, so the answer is read
from the position the path is written in — a `val`'s annotation, a declared
parameter, the function's return type, the element type of an array literal:

<!-- example: modules/enum_section_path_by_expected_type -->

The expected type names the enum also where the module never does — an enum
of a dependency or of another module, reached through an imported function's
parameter (decision 430):

<!-- example: modules/dot_shorthand_enum_not_imported -->

A position that expects nothing (`val x = .Color.Red.500;`) leaves the path
carried by two enums with nothing to choose between them, and the compiler
refuses rather than pick one, naming both candidates:

```
error: the path ".Color.Red.500" is carried by more than one enum —
       "Border" and "Token" — and nothing here says which
```

Give the position a type and it resolves — or write the path from its enum,
which names the answer in the path itself and needs no type around it:

<!-- example: modules/enum_section_path_qualified -->

### behavior

<!-- example: modules/behavior_declaration -->

A behavior is a type: a parameter, a return, a constructor field, an annotated
`val` or a `var` typed by it takes any type that implements it, and a call on it
dispatches to that type's method — the value's own, whatever other type declares
a method of the same name. An imported behavior is the same type it is in its
own module, and so is every name an imported type alias mentions.

<!-- example: modules/behavior_parameter -->

A method the behavior declares with no return answers nothing through the
behavior as through the type, the last statement of a function included:

<!-- example: modules/behavior_method_no_return_by_value -->

A method's parameter typed by a behavior takes an implementer as a free
function's does — through the instance and through the type alike
(decision 430):

<!-- example: modules/method_behavior_parameter_implementer -->

A behavior's associated `default fn` — one taking no `self` — is called
through the behavior's name, `Shape.unit()`, wherever the behavior is
imported, under an alias too, as in its own module:

<!-- example: modules/behavior_associated_fn_imported -->

A type implementing a behavior of another module adopts the behavior's
instance `default fn`s, and those of what it extends, as a type implementing a
behavior of its own module does; a method of the same name the type writes
wins:

<!-- example: modules/behavior_default_adopted_across_modules -->

`Display`, `Closeable`, `Index<K, V>` and `Slice<V>` are **ambient** behaviors
(decision 539 (6)): `builtins.d.bp` declares them, and a program names them with
no import — as a type, a parameter's included and with its arguments
(`m: Index<string, i32>`), and in an `implement` clause, which is checked
against the declaration as a behavior of the module's own is (a required method
the type does not write is refused at the type). Every public behavior of
`builtins.d.bp` that no rule of the compiler reads is ambient; `Task`,
`Iterator`, `Stream`, `Component`, `Annotation`, `Renderable`
and `Decorator` each have a rule of their own. A module's own `behavior` of the
same name, or an imported one, is the one its name reads, and so is a type of
the name it declares or imports.

<!-- example: modules/ambient_behavior_parameter -->

<!-- example: modules/ambient_behavior_implement_missing_method -->

<!-- example: modules/ambient_index_parameter -->

<!-- example: modules/ambient_index_implement_missing_method -->

That holds for every name the prelude gives — a type (`Result`, `Field`),
a behavior, a bare variant (`DeclKind.Component`, `Stage.Any`):
a `behavior` the module declares or imports under that name is what the name
reads in every type position — an annotation, a decorator's `expr decl: …`, an
`implement` clause — and the prelude's declaration is out of that module's
scope.

<!-- example: modules/behavior_named_like_prelude_value -->

<!-- example: modules/behavior_named_like_prelude_type -->

<!-- example: modules/import_behavior_named_like_prelude -->

A `behavior` no type in the program implements is a **runtime boundary**: the
host builds the value. Such a value carries its own members — a `val` member is
read off it, and a method is found on it the same way and applied to the
receiver and the arguments. That is what lets a host hand a program a request,
a connection or a handle without the program naming a concrete type.

### Generics

<!-- example: modules/generic_fn_and_type -->

Built-in generic types carry an `@` prefix: `@Result<D, E>`, `@Task<T>`,
`@Iterator<T>`. Optionals are `?T`; tuples are `#(A, B)`.

A written generic type carries all of its type arguments — `fn get(b: Box)` for a
`type Box<T>` is `error: Box needs 1 type argument`, and `Pair<i32>` for a
`Pair<A, B>` names both counts. Inside a declaration with type parameters `Self`
carries them too: `Self<T>`, and `Self<U>` for the same type over another
argument. A declaration without type parameters writes `Self`, and so does a
non-generic type implementing a generic behavior — the behavior's `Self<…>` is
that type:

<!-- example: modules/generic_method_map -->

Type arguments may be written at a use, adjacent to the name. A function or a
constructor takes them before its call (`first<string>([], "none")`,
`Box<i32>(value: 1)`); a type's name takes them before a member too — a
**type application**: `Dict<string, i32>.empty()` calls `empty` on
`Dict<string, i32>`, and `Slot<i32>.Empty` is that `Slot<i32>`. The list is read
as type arguments only after a type's name (an upper-case first letter) and
only when its `>` is followed by `.` or `(`; anywhere else `<` is a comparison,
so `a < b`, `x < y && z > w` and `f(a < b, c > d)` mean what they say. A
type's name reached through a module namespace takes them the same way:
`collections.Dict<string, i32>.empty()`, `shapes.Box<i32>.make(7)`.

<!-- example: modules/explicit_type_arguments_static -->

<!-- example: modules/type_application_through_namespace -->

<!-- example: modules/type_application_through_namespace_mismatch -->

A parameter says how its argument arrives (decisions 575 (4), 576). `comptime
x: T` is the argument's **value**, known while the program compiles: the body
holds a `T` and reads `x` directly, never `.value` — in a decorator, a template
function, any function, a method, a `declare fn`; the argument is checked
against `T` where it is written. `expr x: T` is the **expression** written,
checked against `T` where it is written and captured as a tree: opaque in the
body, handed only to `compiler.*` or into another tree (§ Template functions);
an `expr` argument to an `expr` parameter hands its tree on. A function or a
type given to a `comptime` parameter is checked at the argument and never run
or inspected while the program compiles. A method or a field read on an `expr`
parameter is `expr-param-method`: its text is read with `compiler.text(x)`. `@Expr<T>`, `@ExprCustom<T>`,
`@Decl`, `Decl<T>` and `Expr<E>` are not part of the language
(`removed-expr-type`), nor the parameter modifier `syntax`.

A `comptime` parameter may take **a value or a type** (decisions 297, 575 (5)):
`comptime source: Box<T> | type<T>`. A `Box<T>` argument binds `T` from
it; a type argument binds `T` to that type; the body tells them apart with
`source is type`, decided while the program compiles — only the branch taken
is emitted, and where `source is type` holds, reading `source` is
`type-arg-read`. `type T` is written `type<T>`, the type of the type `T`
(`removed-type-bare-param` refuses the bare form). The argument of an ordinary function's `comptime` parameter is
known at compile time: a local or a non-`comptime` parameter is
`comptime-arg-not-known` at the argument.

<!-- example: modules/comptime_value_or_type_param -->

A function's name follows the scope rule whatever its parameters: a
parameter or a local named like a function with `comptime` parameters is
the value a call there calls, and every argument of that call is the
value's — none of them is taken as a `comptime` one.

<!-- example: modules/comptime_fn_name_shadowed_by_local -->

A field of a generic record may hold a function: read into a local and called, it
answers what the function answers — an array, a record, an optional, a string,
through two type parameters or a generic record nested in another:

<!-- example: modules/generic_field_fn_value_nested -->

### Type aliases

<!-- example: modules/type_alias_declarations -->

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

<!-- example: modules/derived_type_declarations -->

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
- A decorator on the `val` sees a type declaration (`compiler.kind(decl)` is
  `DeclKind.Type`, `compiler.fields(decl)` the derived fields):
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

#### Field keys

`pub val RecipeKey = Type.keys(Recipe);` names `Type.Field<Recipe>` — the same
type, never a copy nor an enum (decision 308): its values are the fields of
`Recipe`'s declaration, written `.title` where a `Type.Field<Recipe>` is
expected (a field `Recipe` does not declare is the `Type.Field<T>` error at the
`.name`). A key is a value at run time as at compile time:

- stored, passed and compared like any value (`key == .title`);
- `key.name` is the field's name;
- `case key { .title -> …; .description | .servings -> … }` is exhaustive over
  `Recipe`'s fields — a field added to `Recipe` makes a `case` without its arm
  (and without `_`) an error at the `case`;
- `RecipeKey.of(text)` is the key named `text`, or `null`; `RecipeKey.all()`
  every key, in declaration order.

`Type.keys` is bound by a module-level `val` as a derived type is; its argument
is a record by its name.

<!-- example: modules/field_key_runtime -->

A generic constructor's type parameter is pinned by the position's written type as by the call's own
type arguments, so a key resolves there too: `val t: Sort<Book> = Sort(by: .title)` is
`Sort<Book>(by: .title)`.

<!-- example: modules/field_key_under_annotation -->

### Spread

`Name(..src, field: value)` copies a record's fields into its constructor
(decision 359): `..src` at the start of an argument, any number of them,
mixed with labels. The arguments apply left to right, the later winning; a
field no spread and no label supplies takes its default. The spread builds a
new record — `src` is read, never changed — and `a...b` stays the inclusive
range.

<!-- example: modules/record_spread -->

The source is any expression whose type is the record itself or a type derived
from it by `Type.pick`, `Type.omit` or `Type.merge` — a call, a method call, a
field path, another spread — evaluated once however many fields it supplies.
The lineage holds across modules and through an import alias: a type derived in
another module from an imported record, or from an imported derived type, is
derived from that record.

<!-- example: modules/record_spread_call_source -->
<!-- example: modules/record_spread_nested -->
<!-- example: modules/record_spread_across_modules -->
<!-- example: modules/record_spread_import_alias -->

Every argument is evaluated once. A source that is not a name is evaluated
before the labelled values, even one written before it (question B-14-b); a
labelled value a later spread overrides is still evaluated, and typed against
its field, though the field is the spread's.

<!-- example: modules/record_spread_evaluation_order -->
<!-- example: modules/record_spread_overridden_label_type -->

Decision 37's update form `Name(..base, field: value)` is this spread: one
spelling, `..`, builds the record (question B-14-a). `...` is only the inclusive
range `a...b`: a spread written `Name(...src)` is refused at the `...`
(`spread-dot-dot-dot`, decision 529 (3)), and `botopink format` writes `..`.

<!-- example: modules/record_spread_beside_record_update -->
<!-- example: modules/record_spread_dot_dot_dot -->

Refused, each at what it is about: a source of another type — a record of the
same fields, an optional of the record, a type derived from a `Type.partial`
type, a `Type.required` type (question B-14-c) — `record-spread-type` at the
`..`, naming both types; a `Type.partial` value, `record-spread-partial` at the
`..` (a field of it may be null); a field without a default that nothing
supplies, `record-spread-missing-field` at the call; a label written twice or an
argument without one, `record-spread-arguments` at it; a spread at any call but
a record's constructor, `call-spread` at the `..` (decision 267: a function
call takes no spread).

<!-- example: modules/record_spread_other_type -->
<!-- example: modules/record_spread_optional -->
<!-- example: modules/record_spread_derived_partial -->
<!-- example: modules/record_spread_required -->
<!-- example: modules/record_spread_partial -->
<!-- example: modules/record_spread_missing_field -->
<!-- example: modules/record_spread_label_twice -->
<!-- example: modules/record_spread_positional_argument -->
<!-- example: modules/call_spread -->

### Union types, `unknown`, and `is`

A union type is written `A | B`. `unknown` holds any value and, unlike a union,
cannot be used as another type until it has been tested — `val b: i32 = a;` on an
`unknown` reports "an `unknown` value cannot be used as another type without
testing it". `x is <Type>` answers a `bool` and narrows `x` inside the branch it
guards.

<!-- example: modules/union_is_narrowing -->

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

<!-- example: modules/is_function_type -->

The elements of an array literal that disagree make the union of their types
(`[3, "abcd"]` is `(i32 | string)[]`), and each element read back — printed,
iterated, by index or `at`, passed to a parameter of the union — is the member it
is, whether the union is inferred or written:

<!-- example: modules/array_literal_union_elements -->

A `case` whose arms disagree is the union of their types, and so is an `if` /
`else` whose branches do — whatever shape an arm is written in (a value, a
block, a lambda arm, over an `unknown` subject, in an `async` body that
awaits) and wherever the value goes (a `val`, a `return` from a function
answering the union, an argument of a parameter of it); each value read back
is the member it is:

<!-- example: modules/case_if_union_value_shapes -->

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

<!-- example: modules/narrow_after_null_return -->

Three shapes do **not** narrow, and each for its own reason:

* `if (x)` on a `?T` with no binder is refused — "type mismatch: expected bool,
  got ?string". There is no truthiness on an optional; write `if (x) { v -> … }`
  or `if (x != null)`.
* `while (x != null) { … }` leaves its body alone. A condition loop reassigns the
  name it tests, and a narrowed name could not be assigned the optional again.
* A guard clause narrows a `val` and not a `var`, for the same reason: a `var`
  can be assigned below the guard.

The binder of `if (x) { v -> … }` (and of `x ?? d`, which reads as one) is bound in the then-branch
alone: a later closure — a `for` body — that binds the same name in its own `if` reads its own
binding, never the earlier one, whether the earlier optional was present or absent:

<!-- example: modules/if_binding_before_loop_closure -->
<!-- example: modules/component_loop_await_accumulates -->

## Expressions

### Literals

```text
42             // i32
3.14           // f64
"hello"        // string
"hi ${name}!"  // string interpolation
true, false    // bool
```

A template is a `string` whatever its parts: a template whose only part is a
hole (`"${5.0}"`) is the hole written out as text, a `string` as a `val`, as an
array element and as an operand of `+`.

<!-- example: modules/interpolation_single_float_hole -->

A template hole holding a value of an enum writes it as `@print` writes it at
the top level (§ What `@print` writes) — a variant names its enum, `Shape.Dot`,
`Shape.Circle(radius: 2)` —, and `string + value` writes the same text.

<!-- example: modules/enum_value_template_hole -->

A template hole writes the text `@print` writes for every value (decision 530) — a record
`Point(x: 1, y: 2)`, an array `[1, 2, 3]`, a tuple `#(1, "a")`, `null`, an enum — on every target, and
a `string` writes itself. A type implementing `Display` writes its `display()` in a hole as in `@print`.
A `Bytes` hole stays refused.

<!-- example: modules/template_hole_prints_every_value -->

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
42i8  42i16  42isize          123456789012345678901234567890n   // bigint
```

A literal never changes type to fit: an integer literal where a float is
expected is an error, and so is `1.5` where an `f32` is — write `1d` or `1.0`,
and `1.5f`. `f` and `d` go on decimal literals only (in `0x…` they are hex
digits); a radix literal takes an integer suffix (`0xFFul`). An uppercase
suffix (`42L`), letters that are no suffix (`10px`) and an exponent without
digits (`1e`) are refused at the suffix. A number pattern matches a subject of
its own type. `n` makes an integer literal a `bigint` of any size (§ Numbers);
it takes no fraction or exponent (`1.5n` is refused at the suffix).

Each of those refusals has its own name, located at the suffix or the exponent: an upper-case suffix is `number-suffix-uppercase`, letters that are no suffix `number-suffix-unknown`, an exponent without digits `number-exponent-without-digits`, an integer suffix on a literal with a fraction or an exponent (`1.5l`, `1.5n`), which is floating and takes `f` or `d` only, `number-suffix-integer-on-float`, and a floating suffix on a hexadecimal, octal or binary literal, which is an integer, `number-suffix-float-on-radix`.

<!-- example: modules/bigint_literal_fraction -->
<!-- example: modules/number_exponent_without_digits -->
<!-- example: modules/number_suffix_float_on_radix -->
<!-- example: modules/number_suffix_integer_on_float -->
<!-- example: modules/number_suffix_unknown -->
<!-- example: modules/number_suffix_uppercase -->

<!-- example: modules/numeric_literal_kinds -->

A `case` over a 64-bit integer (`i64`, `u64`) or a float compares it as its own type: a number pattern, a
range, an `|` of patterns and a guard see the value whole, on every target.

<!-- example: modules/case_wide_integer_scrutinee -->

<!-- example: modules/integer_literal_never_fits_f64 -->

### Arrays

<!-- example: modules/array_slice_reverse -->

An array method **answers a value and leaves its receiver alone**, on every
target: `reverse`, `slice`, `map` and `filter` all hand back a new array.

`Array.range(start, stop)` is the integers of `[start, stop)`, empty when
`stop <= start`; `Array.repeat(value, times)` is `times` copies of `value`, empty
when `times <= 0`. A result costs its own length in memory, a long one too, and so
does `xs.fill(v)`, which is `Array.repeat(v, xs.length)`:

<!-- example: modules/array_range_and_repeat -->

<!-- example: modules/array_fill_large -->

### Indexing and slicing

**An index is a method call.** `xs[k]` *is* `xs.at(k)`, `xs[a..b]` *is*
`xs.slice(a, b)`, and an open end passes `null` — `xs[1..]` *is*
`xs.slice(1, null)`, because `start..end` is a form and not a value, so there is
nothing else to hand the method. The index expression has **no typing rule of
its own**: its type is whatever the method answers, which for `at` is `?T`.

<!-- example: modules/index_and_slice_sugar -->

A **negative index counts from the end**, on every backend: `xs.at(-1)` is the
last element and `xs.at(-xs.length)` the first; an index past either end
(`xs.at(xs.length)`, `xs.at(-xs.length - 1)`) is the absent `?T`. `Array.at`
and `String.at` — and so `xs[i]` and `s[i]` — read the same way. `Dict.at` is
by key and has no position to count from. A `Dict`'s value is any type, a float or a 64-bit integer
included: `insert` keeps the value whole and `at` (and so `d["k"]`) answers it as the `?V` it is — present,
absent or overwritten — on every target.

<!-- example: modules/dict_float_value -->

Which methods those are comes from two **ambient** behaviors — ambient like
`Display` (§ behavior), so the syntax finds them with nothing imported, a
program names them as a type, and an `implement` of one is checked:

```text
pub behavior Index<K, V> { fn at(self: Self<K, V>, key: K) -> ?V; }
pub behavior Slice<V>    { fn slice(self: Self<V>, start: i32, end: ?i32) -> V; }
```

So indexing is not a privilege of the three built-in collections. `Array<T>`
answers `Index<i32, T>` and `Slice<T[]>`, `string` answers `Index<i32, string>`
and `Slice<string>`, `Dict<K, V>` answers `Index<K, V>` — and **your own type
becomes indexable by answering them**, with nothing added to the compiler:

<!-- example: modules/index_user_type -->

A **tuple** is the one exception, and its reason is the rule's: `t[0]` needs a
*constant* index and answers a type *per position*, which `at(key: K) -> ?V`
cannot say with a single `V`. A tuple index is checked directly — `t[0]` is
`i32` and `t[1]` is `string` below, neither of them optional, and an index the
type has no position for is refused where it is written.

<!-- example: modules/index_tuple_literal -->

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

At build, in a `comptime`, `==` compares two values of any depth (it walks an explicit work list, never the
runtime's stack, so two 2,000,000-deep chains answer `true`), and an arithmetic error reads as Erlang's
`badarith`: ``error: comptime-badarith: an error occurred when evaluating an arithmetic expression — `1.0 / 0.0`
(division by zero)``, the same on every target. Every division and remainder by zero reads so — `/` and `%`,
integer and float, alone, inside a larger expression, or in a function the `comptime` calls — and is located at
the operator that divides, never at the whole expression. At run time each target keeps its own answer
(commonJS and wasm `Infinity`, erlang and beam `badarith`). An integer division by zero at build is the same
refusal, naming `7 / 0`:

<!-- example: modules/comptime_deep_structure_equality -->
<!-- example: modules/comptime_float_division_by_zero -->
<!-- example: modules/comptime_integer_division_by_zero -->

A remainder by zero, a division by zero inside a larger expression and one in a function the `comptime`
calls are the same refusal, at the `%` or the `/` that divides:

<!-- example: modules/comptime_remainder_by_zero -->
<!-- example: modules/comptime_nested_division_by_zero -->
<!-- example: modules/comptime_division_by_zero_in_helper -->

At run time a float division by zero prints the float's word on commonJS and
wasm, and erlang and beam abort with `badarith`:

<!-- example: modules/float_nan_infinity_words -->

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
or `||` takes parentheses (`(a ?? false) && b`; `nullish-beside-logical`); `x!` is checked at run time, a
program error like `@panic`, alike on every target; and `map`, `flatMap` and
`unwrapOr` belong to `@Result` alone (`r.unwrapOr(0)`) — there is no `result`
namespace.

<!-- example: modules/nullish_beside_logical -->

A `?.` makes the rest of its chain conditional: at the first absent link the whole
chain is absent, and a member or a method after the link runs only on a present
value — along record fields, and for a primitive's, a record's or an enum's method:

<!-- example: modules/optional_operators -->

<!-- example: modules/optional_chain_record_fields -->

<!-- example: modules/optional_method_absent_receiver -->

<!-- example: modules/optional_record_method_absent_receiver -->

<!-- example: modules/optional_enum_method_absent_receiver -->

A field read is a link like a method: one written after a `?.` link — after a method's
(`p(true)?.me().x`) or a field's (`p(true)?.inner.x`) — reads the payload and continues
the chain, and so does a method after it (`p(true)?.me().name.length()`):

<!-- example: modules/optional_chain_field_after_call -->

A method written after a `?.` field that is a list is the list's: `meta(Tags)?.list.join(",")`
reads the payload's list and joins its elements as the list's element type says, and
`(opt?.list ?? []).join(",")` keeps that element type across `??` — an empty default
adds none, so a list of strings joins as strings on every target:

<!-- example: modules/meta_list_method_on_optional -->

<!-- example: modules/meta_list_coalesced_method -->

A tuple's label read through `?.` on an absent element is absent (`es.at(3)?.a ?? 0`
is `0`), and a present element's label is its value, `0`, `false` and `""` included
— never taken for absence:

<!-- example: modules/tuple_label_through_absent_optional -->

An optional holds any type: a record's `?f64` field holds a float or `null` and
reads back as either, and an optional of an enum with a payload variant holds a
variant or `null`. A leading dot where a `?Place` is expected names `Place`'s
variant (`.Here` is `Place.Here`):

<!-- example: modules/record_optional_float_field -->

<!-- example: modules/optional_payload_enum_value -->

`f?.(args)` over a function answering a plain `T` is a `?T`, a present `0`
included. The default of `??` may itself be such a call, and a default runs only
when everything before it is absent:

<!-- example: modules/optional_call_operator -->

<!-- example: modules/optional_call_plain_answers -->

<!-- example: modules/nullish_optional_call_default -->

`x!` over `null` aborts after what was printed before it, naming the expression
and where it is written — inside a lambda too, when the lambda runs:

<!-- example: modules/optional_bang_aborts -->

<!-- example: modules/optional_bang_in_lambda -->

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
| `bigint` | any integer: no range, never an overflow (below) |

The range is the type's on every target (decision 319). On commonJS an `i64`
(and `isize`, `u64`, `usize`) is a JS `number` while it lies within
±(2^53 − 1) and a `BigInt` beyond, always in that canonical form, so `==`, a
`Dict` key and a `Set` member compare by value across 2^53; an operation keeps
the number's fast path and computes in `BigInt` only when its result leaves
that range. A Node host template receives and answers such a value as
`number | bigint` in the canonical form, and the emitted `.d.ts` types it so.
The narrower integers stay JS numbers. An integer `/` or `%` by zero aborts on
every target (commonJS names it `integer division by zero`). A `%` never leaves its type.
No flag turns the check off (decision 67); wrapping arithmetic, where an
algorithm wants it, is written with an explicit operation.

<!-- example: modules/i64_full_range -->

<!-- example: modules/wide_literal_past_js_safe_integer -->

<!-- example: modules/i64_dict_key_across_safe_edge -->

Crossing between integer types, and to `f64`, is written and exact:
`toI32()`, `toI64()`, `toU32()`, `toU64()` and `toF64()` answer the value when
the target type holds it and abort otherwise, never wrap, saturate or round
(`toI32: 2147483648 does not fit i32`, `toF64: 9007199254740993 has no exact
f64`). `@print` and string interpolation write an integer's digits, whatever
its size.

<!-- example: modules/integer_conversions_exact -->

<!-- example: modules/integer_conversion_u64_to_i64_aborts -->

<!-- example: modules/integer_conversion_to_i32_aborts -->

<!-- example: modules/integer_conversion_to_f64_inexact_aborts -->

`bigint` is an integer of any size (decision 332): `+`, `-`, `*`, `/`, `%`, a
unary `-`, `+=`, the comparisons and `==` over two `bigint`s answer exactly and
never overflow; `/` truncates toward zero and `%` takes the dividend's sign, as
for the other integers, and `/` or `%` by zero aborts. Its literal is suffixed
`n` (`2n`); an unsuffixed literal is never one, and a `bigint` mixes with no
other number — the crossing is written: `bigint.of(n)` (an `i64`) and
`bigint.parse(text)` (`@Result<bigint, string>`, a decimal numeral of any
length) in, `toString()`, `toI64()` and `toF64()` out, each conversion aborting
when the value does not fit (`toI64: 9223372036854775808 does not fit i64`).
erlang and beam hold the VM's own integer, commonJS a `BigInt` (`.d.ts`
`bigint`), and wasm a block of 32-bit limbs its runtime computes on. A `bigint`
does not widen to `unknown`, `is` does not test one (a value typed `bigint` is
one), and a `comptime` does not compute one yet.

<!-- example: modules/bigint_arithmetic -->

<!-- example: modules/bigint_plus_int_literal -->

`==` compares by value on every target: two records, tuples, arrays or enum
variants are equal when they have the same type and their fields are equal, field
by field and recursively — `Person(name: "Ana", age: 30) == Person(name: "Ana",
age: 30)` is `true`. Two values of different types are never equal, `!=` is the
negation, and `==` never calls a method of the type (one named `equals` included).
An `f64` compares as a total order under `==`, as Java's `Double.compare` does:
`0.0 == -0.0` is `false` and `NaN == NaN` is `true`, bare or inside a composite;
`<`, `>`, `<=` and `>=` keep the IEEE ordering (`-0.0 < 0.0` is `false`).

### Lambdas and method chains

<!-- example: modules/lambda_method_chain -->

A lambda's parameters take the types of the position it is passed to or the
`val` it is bound to; `fn(a, b) { … }` is the same function written with
`fn`. The braced lambda stays untyped (decision 328): `val inc: fn(x: i32) ->
i32 = { x -> x + 1 };`. The typed function expression `fn(x: T, …) -> R { … }`
is legal in every position (decision 408) — a `val`, a `var`, an argument, a
return and the member a decorator hands to `compiler.addMember(name, fn…)` alike;
every parameter typed or none, and no `-> R` answers nothing. Where the
position has a type, the written types are checked against it — `val f: fn(x:
i32) -> i32 = fn(x: string) -> i32 { … };` is refused at the expression; with
none, the written types are the function's:

<!-- example: modules/fn_expr_typed_anywhere -->

<!-- example: modules/fn_expr_typed_mismatch -->

<!-- example: modules/fn_expression_string_parameter -->

An untyped fn expression takes its parameter types from its use: called where it is written
(`(fn(s) { return s + "x"; })("a")`), passed to a parameter that expects `fn(string) -> string`,
or bound to a `val` and called, a `string` parameter writes its text on every target.

A record field's value and an array element are positions like any other: the expression is
checked against the field's function type, and a lambda beside it in an array takes its types from
the element type. The member a decorator hands to `compiler.addMember(name, fn…)` answers its tail as
any function expression does:

<!-- example: modules/fn_expr_typed_in_record_field -->

<!-- example: modules/fn_expr_typed_field_mismatch -->

A lambda passed for a function's parameter reads its parameters as the
parameter's function type says: `{ p -> p.nome }` for `fn(Pessoa) -> Pessoa`
reads `Pessoa`'s `nome` though another record declares a field of the name,
and `Pessoa(..p, idade: 31)` spreads a `Pessoa`:

<!-- example: modules/lambda_param_shared_field -->

<!-- example: modules/decorator_member_fn_tail -->

A lambda handed to `fold` reads its accumulator as the initial value's type:
over a string, `{ acc, c -> acc.split(c).join("") }` chains string and array
methods on `acc`. A dependency's module holding such a function builds as the
program's own does, so a program importing it prints the same whether or not
it calls the function:

<!-- example: modules/fold_split_join_lambda -->

<!-- example: modules/dependency_prints_with_fold_join -->

A lambda bound with no annotation takes its parameters' types from the calls
that use it: `val later = { n -> async { … n.toString() … } }` called as
`later(2)` types `n` as `i32`, and `n.toString()` is `i32`'s method on every
target. A parameter that no position, annotation or call types cannot choose a
method: a method called on it is refused at the call, `cannot infer the type
of `n`` (decision 328). A lambda passed where a parameter receives it is typed
by that parameter, a type parameter of the callee included: `{ req, chain ->
chain.next(req) }` handed to `register<Rq, Ch>(…, entry: fn(req: Rq, chain:
Ch) -> string)` is not refused:

<!-- example: modules/lambda_param_typed_by_later_call -->

<!-- example: modules/lambda_param_untyped_method_refused -->

<!-- example: modules/lambda_arg_generic_param_method -->

A function value is a value like any other: a tuple's element holds one, read by position and
called after its arguments are evaluated (`p.0("abc")`):

<!-- example: modules/fn_value_in_tuple -->

Each element keeps its own function type, so the one answering a string prints the string, and a
function-typed field called on a loop's element answers its declared type (`op.run(5).toString()`):

<!-- example: modules/fn_value_tuple_string_answer -->

<!-- example: modules/fn_field_call_in_for -->

A lambda's and a function expression's last expression written without `;` is
its value, as a named function's is (§ fn — function, decision 409):
`val inc = fn(x: i32) -> i32 { x + 1 };`, `{ x -> x + 1 }`. With `;` a typed
function expression's last expression is a statement, so one with `-> R` then
needs a `return`:

<!-- example: modules/fn_expr_tail_value -->

<!-- example: modules/fn_expr_tail_semicolon -->

A lambda answers its last expression written without `;` (decision 541): `{ x -> x + 1 }`
answers `x + 1`. With `;` the expression is a statement and the lambda answers nothing, so it stands
where a function returning `void` is expected even though its last call answers a value, and where
a function returning a value is expected it is refused, at the lambda. (An untyped `fn(x) { … }`
keeps the value of its last statement, `;` or not; a typed function expression with `-> R` refuses
a `;`-terminated last expression, as above.)

<!-- example: modules/lambda_last_statement_semicolon -->

<!-- example: modules/lambda_semicolon_not_a_value -->

The pipe operator `|>` is left-associative.

### Blocks

A `{` followed by parameters and `->` (or `->` alone) is a lambda; a `{` without `->` is a
**block** — a scope of the enclosing function, never a closure (decision 525). A block used as a
value answers its last expression written without `;` (decision 409), as a function and a lambda
do; a braced `if` / `case` at its end is that expression too:

<!-- example: modules/block_tail_value -->

A `//` comment after a block's last expression, written without `;`, is a comment after the tail:
the expression stays the block's value, in a function body, a lambda, an `if` / `else` block and a
`case` arm's block alike, and `botopink format` keeps the comment after it:

<!-- example: modules/block_tail_comment -->

A `return` in a block leaves the enclosing function — from its own statements, from a `case` arm or
a nested block in it, from a `for` inside it — and the block's tail is its value on every other
path:

<!-- example: modules/block_return_leaves_function -->

<!-- example: modules/block_for_return_leaves_function -->

<!-- example: modules/block_partial_return -->

A `var` of the enclosing function reassigned in a block is a plain reassignment, seen after the
block on every target, whether the block's value is used or not:

<!-- example: modules/block_reassigns_enclosing_var -->

<!-- example: modules/block_value_reassigns_enclosing_var -->

The same rule reads every block used as a value: a `case` arm `p { … }`, `comptime { … }` and
`async { … }` answer their last expression written without `;`. An arm of a `case` used as a value
whose last expression ends with `;` answers nothing, refused at the arm beside arms that answer a
value; `break <value>` gives a block no value — in `comptime { … }` and in a `case` arm alike
(decision 541) — refused at the `break`:

<!-- example: modules/case_arm_no_value -->

<!-- example: modules/comptime_block_break_value -->

<!-- example: modules/case_arm_break_value_removed -->

A block is a scope of the enclosing function, never a closure (decision 541): an `await` in a block
or in a `case` arm's block waits for the enclosing task, a `yield` feeds the enclosing generator, and
a bare `break` leaves the enclosing loop. A block that ends a function body is its tail:

<!-- example: modules/block_await_reaches_function -->

<!-- example: modules/block_yield_reaches_generator -->

<!-- example: modules/block_break_reaches_loop -->

<!-- example: modules/block_ends_function_body_is_tail -->

A labelled `break :outer` in a block or in a `case` arm's block leaves the loop it names, from however
many loops in, and a bare `return` in a `case` arm that yields ends the enclosing generator, so
nothing after the `case` is emitted:

<!-- example: modules/block_jump_label_reaches_loop -->

<!-- example: modules/case_arm_return_in_yielding_arm -->

A block handed where a function is expected is refused at the block, with the hint "expected a
function, got a block's value — missing `->`?"; a trailing lambda follows the same rule, so one
with no parameter is written `f(x) { -> … }`. A block whose value is `void` handed where
`unknown` is expected is refused. `@block` is removed, refused at the builtin, its fix the block
`{ … }`:

<!-- example: modules/block_trailing_not_function -->

<!-- example: modules/block_argument_not_function -->

<!-- example: modules/block_void_value_refused -->

<!-- example: modules/block_builtin_removed -->

A trailing lambda is the call's last argument: it fills the parameter after the written arguments, of
a method or of a plain function, with parameters (`f(3) { n -> n * 3 }`) or with none (`b.run { -> 10 }`,
`twice { -> 4 }`), and the parameter is checked and bound as any lambda argument's is:

<!-- example: modules/trailing_lambda_call -->

`defer <expr>;` runs `<expr>` when the block it is written in ends (decision 539) — block scope, as in
Zig and Swift. Several run in reverse order, and each runs on every exit of the block: the end,
`return`, `break`, `continue`, a propagating `try`, a `throw`, a panic `attempt` catches:

<!-- example: modules/defer_block_end_reverse_order -->

<!-- example: modules/defer_scope_is_block -->

<!-- example: modules/defer_in_loop_break_continue -->

<!-- example: modules/defer_try_and_throw_propagate -->

<!-- example: modules/defer_panic_attempt_catches -->

The deferred expression is evaluated when it runs, not when `defer` is written (`var f = open("a");
defer f.close(); f = open("b");` closes `b`), and a `return <expr>`'s value is computed before the
block's defers run:

<!-- example: modules/defer_reads_latest_value -->

<!-- example: modules/defer_return_value_before_defers -->

A reassignment inside a nested arm counts, a value `case`'s or `if`'s included: an arm that reassigns a `var` and
then panics hands the `defer` the new value:

<!-- example: modules/defer_reads_var_set_in_arm -->

The names a deferred expression reads bind where `defer` is written; only their values are read late. A `val`
written after the `defer` that shadows a name the deferred expression reads is another binding, and the
deferred expression does not see it:

<!-- example: modules/defer_reads_binding_at_defer -->

A `defer` is written in any block: an `if` branch or a `case` arm, one that answers a value included, and a
lambda a higher-order function runs. A panic `attempt` catches runs the defers of the block or arm it happens in:

<!-- example: modules/defer_in_value_branch -->

<!-- example: modules/defer_panic_in_arm -->

A deferred statement that panics runs once, even when the way out that ran it is a `return` inside the block:

<!-- example: modules/defer_inner_panic_runs_once -->

In an `async` body a `defer` runs when the task's body ends, after its awaits; in a `@Stream` when
the stream ends or its consumer stops (a `break` in `for await`):

<!-- example: modules/defer_async_after_awaits -->

<!-- example: modules/defer_stream_consumer_stops -->

Its body cannot leave the path it runs on: `return`, a `break` or `continue` that leaves it, `yield`
and `await` in it are refused, located (a loop wholly inside the body may `break`). The value of the
deferred expression is discarded, and the compiler checks nothing about what is deferred: a value
that is never closed compiles (decision 539 (6)).

<!-- example: modules/defer_refuses_return -->

<!-- example: modules/defer_refuses_break -->

<!-- example: modules/defer_refuses_continue -->

<!-- example: modules/defer_refuses_yield -->

<!-- example: modules/defer_refuses_await -->

`botopink format` migrates the older spellings: a trailing lambda without `->` gains it, the last
`;` of a `case` arm used as a value is dropped, and `comptime { …; break v; }` and a `case` arm's last
`break v;` become the tail `v`. It prints a block of one tail on one line when it fits (`{ 1 + 2 }`), as it prints a function
body.

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

`botopink format` is applied, never checked (decision 524): no gate fails on a file
that is not canonical — each repository's commit hook formats the commit's `.bp`
files as they are staged, and the editor formats on save. A rule of the language is
an error of the parser or the checker; the formatter changes layout and synonyms
only. A `;` after the closing brace of a block-shaped statement — an `if`, a loop
or a `case` in statement position — is one of them: the parser accepts it, and
`botopink format` removes it.

### If / else

<!-- example: modules/if_expression -->

An `if` used as a value needs its `else`: `val s = if (x > 0) { "positive" };` has no value when
the condition is false and is refused at the `if`. It stands where an expression begins — a `val` /
`var` initializer, the right side of `=`, a `return`, a call argument, a literal's element — and is
never an operand: `1 + if (c) { 2 } else { 3 }`, `-if (c) 1 else 2` and `(if (c) a else b).v` are
`error[if-operand]` at the `if`; bind it first (`val x = if (c) { 2 } else { 3 }; 1 + x`).

<!-- example: modules/if_in_parentheses -->
<!-- example: modules/if_operand_of_operator -->
<!-- example: modules/if_operand_of_unary -->

A condition is a whole expression, `&&` and `||` included — the grammar's own
parentheses close it, so nothing has to be bound to a `val` first:

<!-- example: modules/if_else_if -->

A value `if` keeps what its branches reassign: a `var` set in whichever branch ran, an `else if`
chain's included, holds that value after the `if`:

<!-- example: modules/value_if_reassigns_var -->

`if` on an optional unwraps it in the then-branch:

<!-- example: modules/if_optional_binder -->

Write the binder `_` when the branch only asks whether the value is there:

<!-- example: modules/if_optional_else -->

### Case (pattern matching)

<!-- example: modules/case_variant_fields -->

List and or-patterns:

<!-- example: modules/case_alternatives_and_arrays -->

A section of an enum is itself a type, written by its path, so a function can
take one section instead of the whole enum:

<!-- example: modules/case_section_subtype -->

An arm may also be written as a block, `<pattern> { … }`. A block arm takes an
optional `when (…)` guard, and a pattern may be a literal, a type (`i32`) or `_`.
The arm is a block (§ Blocks): used as a value it answers its last expression
written without `;`. A `//` comment between the statements of an arm's block is
a comment there as it is in a function body, and `botopink format` keeps it:

<!-- example: modules/case_arm_block_comment -->

A guard and a type pattern:

<!-- example: modules/case_type_guard_arms -->

A variant pattern names **every** field of its variant, or ends with `..`:

<!-- example: modules/case_dot_variant_patterns -->

A constructor pattern of a record type takes the same `..`, and a field it names
may hold a literal (`Point(x: 0, ..)` matches a point whose `x` is `0`):

<!-- example: modules/point_ctor_rest_in_case -->

`.Rect(width: w)` without the `..` is `error: missing required field 'height' on
type 'Rect'`, at the arm — the fields a pattern does not name are dropped, and
`..` is how you say so.

A range in a pattern is `...`, inclusive at both ends — Zig's split: `...` in a
pattern, `..` (exclusive) in a `for` and a slice. `1..9` in an arm is
`error[pattern-range-exclusive]`, naming `...`; an open end is a guard.

<!-- example: modules/case_range_and_guard -->

A tuple pattern is positional, as a tuple literal is: a label in one (`#(name: n, ..)`) is `pattern-tuple-label`, refused at the label — match by position.

<!-- example: modules/case_tuple_label -->
<!-- example: modules/pattern_range_exclusive -->

A name alone is not a pattern: to give the matched value a name, bind it in the
body (`_ { n -> … }`). The one exception is the optional, below, where the name
after the `null` arm *is* the pattern. `n { … }` is `case-bare-name-arm`, the
label under it naming the binder to write:

<!-- example: modules/case_bare_name_arm -->

A constant is not a pattern either: `MAX { … }` is `case-constant-pattern`, the
label under it naming the guard to write (`_ when (x == MAX) { … }`):

<!-- example: modules/case_constant_pattern -->

The `pattern -> value` arm is no exception: `k -> k + 1` is refused at the arm
as `k { … }` is.

<!-- example: modules/case_bare_name_arrow_arm -->

The binder of a catch-all arm over a record is that record: its fields read as
declared, a generic record's too, wherever the `case` stands:

<!-- example: modules/case_catch_all_binder_record -->

A `case` is a value of its arms' type, a catch-all arm that binds the subject
included — a string here, as a `val`'s value and as an argument:

<!-- example: modules/case_binder_arm_string_value -->

#### An optional is matched by `null` and a binder

A `?T` has exactly one pattern form — `null` for the absent value, then a name
that binds what is there, already unwrapped:

<!-- example: modules/optional_case_null_binder -->

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

`loop (xs) { x -> … }` and `loop (cond)` are `removed-loop-parenthesised`, naming `for` and `while`. `while` and `loop` bind nothing, so a binder on one is `loop-binds-nothing`, refused at the binder. `loop await` does not exist either: a stream is walked with `for await`, and the parser refuses the `await` after `loop`, located at it.

<!-- example: modules/loop_await_removed -->
<!-- example: modules/loop_condition_parameter -->
<!-- example: modules/loop_condition_parenthesised -->
<!-- example: modules/loop_parenthesised -->

A range `a..b` excludes its end and `a...b` includes it: `for (1..4)` visits
`1 2 3`, `for (1...4)` visits `1 2 3 4`. A range is not a value — there is no
`Range` and no `.rev()`; a countdown is a `while` or `xs.reverse()`.

<!-- example: modules/loop_forms -->

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

<!-- example: modules/iter_loop_and_for -->

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
`stream` loop) and is otherwise `await-without-async`. `for` over a
`bool` is refused naming `while`.

Labels go on all three: `for :outer (xs) { x -> … }`, `while :w (…) { … }`,
`loop :l { … }`, then `break :outer`, `continue :outer`. A `continue :outer` from a nested loop's body or from a
`case` arm's block ends the inner loops and starts the named loop's next round; a label no enclosing loop carries is
`break-label-unbound`, on `continue` as on `break`. A bare `continue` from a block or a `case` arm in a loop's
body starts the loop's next round:

<!-- example: modules/block_continue_reaches_loop -->
<!-- example: modules/block_jump_label_continue_reaches_loop -->

<!-- example: modules/continue_label_unbound -->

A `//` comment inside a loop body parses like any other comment.

**Per backend.** On commonJS `iter …` is `(function* () { … })()` and
`stream …` is `(async function* () { … })()`; erlang and beam make the prefixed
loop a generator as they make an `@Iterator` / `@Stream` function's — the body
runs in a process of its own, one step per item; wasm makes the body a resumable state machine
as an asynchronous function's, each `yield` a suspension point.

### Assert

`assert <condition>;` and `assert <condition>, "<message>";` do nothing when
the condition holds; when it fails the program aborts, and the abort names the
message on stderr, on every target.

<!-- example: modules/assert_statement -->

<!-- example: modules/assert_message_aborts -->

`val assert <pattern> = <expr>;` binds the pattern's names and is **fatal** when
the match fails, so the names below the binding are never unbound. It takes no
`catch` — `try … catch` is the form that supplies a fallback.

<!-- example: modules/val_assert_ok -->

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

<!-- example: modules/component_use -->

The rules, each with its diagnostic:

- **Only a `@Component<R>` return grants `use`** (decisions 104 and 118). A
  `use` in any other body — a plain `fn`, a `@Task` one whatever it wraps — is
  refused at the `use`: `` use-without-component: `use` needs a
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

<!-- example: modules/use_conditional_argument -->

<!-- example: modules/use_in_if -->

**Lowering.** `use f(x)` is `f(x)` on erlang, wasm and beam. On commonJS a
`@Component` function whose hooks node is asynchronous (`HookNode.async`,
decision 375 — it writes `await` or `async { … }`, or reaches an asynchronous
hook, component or host task) is an `async function`, and a `use` or call of
it is awaited (`await f(x)`); a synchronous one is a plain `function`, and a
`use` or call of it is not awaited, written or not — `await` stays legal on
any component, a no-op on a synchronous one. A method answering `@Component`
— a type's, an enum's, a behavior's `default fn` — is marked by its own body
as a top-level function is, and a call of a `default fn` follows the adopting
type's `implement` to the behavior's mark (decision 375, question 04s12-a); a
lambda is an `async` arrow only when its own body awaits. The prefix is the activation the
checker validated, not a rename: nothing is turned into `useState`, no
dependency array is inferred — a function that takes one declares it as a
parameter (`memo(compute, deps)`). A client runtime supplies hook semantics
through what `f` does; the pure body above is what every backend runs, and what
the server renders.

<!-- example: modules/component_method_sync -->

<!-- example: modules/component_default_fn_sync -->

**Contexts** (decisions 354, 378, 379). What a body reads from above it is a
context, named by its value's type. std's `context.createContext(value)` makes
one; written as a module-level `val`'s initializer it **declares** that type's
default — `pub val themeContext = comptime createContext(Theme(mode: "light"));`
— one declaration per type in the program (`context-declared-twice` at the
second, naming the first), and a module-level `Context<T>` made any other way
(a `val` naming another context, a `var`) is `context-not-declared`. Two
contexts over one base type are two types (`type Depth(n: i32)`, `type
Step(n: i32)`). Two hooks of std's `context` module work it, `use`d and nothing
else (`context-hook-without-use`):

- `use provide(createContext(value));` in a **component's** body gives the
  context to everything that component renders below it — descendants only,
  never itself or a sibling; the nearest provider of a type wins (`use
  provide(themeContext)` gives the declared default again). In a body whose
  `R` is not `@Renderable` it is `context-provide-outside-component`, and after
  the body rendered a component it is `context-provide-after-render` (that
  child would not see it).
- `val t = use context(Theme);` reads the context of type `Theme` provided
  nearest above, else `Theme`'s declared default — no read is unbound. A type
  with no declared default is `context-not-declared` at the read; the
  declaration is found in the reading module, or in a module analysed before
  it — the type's own module included (question B-17-g).

<!-- example: modules/context_default -->

<!-- example: modules/context_nearest_wins -->

<!-- example: modules/context_default_imported -->

<!-- example: modules/context_undeclared_type -->

<!-- example: modules/context_declared_twice -->

<!-- example: modules/context_declared_twice_across_modules -->

<!-- example: modules/context_enum_default -->

**Dependency injection** rides the context tree (decision 416). `val deps = use
inject(Deps);` builds the record `Deps`, each field the nearest context of its
field's type provided above, else that type's declared default, else the field's
own default — a field with none of the three is `context-not-declared` at the
`inject`, naming the field; `inject` of a behavior or of any type that is no
record is `inject-not-record` (a behavior is read with `use context(B)`). A
second argument of `createContext` names the behavior the context is provided
as — `createContext(PgRepository(pool), Repository)`, the value checked to
implement it as a parameter typed `Repository` is, through its own `implement`
clause or a behavior that `extends` `Repository` (`context-behavior-not-implemented`
at the argument) — so `use
context(Repository)` and an `inject` field typed `Repository` read it; its
declaration is the behavior's default. A read of a behavior with no declared
default is `context-not-declared` at the read, naming the declaration a behavior
takes — `createContext(value, Repository)`, a value of a type that implements it
— never a constructor call, which a behavior has none of. Providing stays one
context per dependency, so a test's root swaps one.

<!-- example: modules/inject_record -->

<!-- example: modules/inject_behavior_keyed -->

<!-- example: modules/inject_test_root_fake -->

<!-- example: modules/inject_field_undeclared -->

<!-- example: modules/inject_behavior -->

<!-- example: modules/inject_not_record_enum -->

<!-- example: modules/inject_default_imported -->

<!-- example: modules/context_behavior_not_implemented -->

<!-- example: modules/context_behavior_undeclared -->

<!-- example: modules/context_behavior_implemented_indirectly -->

<!-- example: modules/context_behavior_method_find -->

<!-- example: modules/context_provide_read -->

A component is a lambda over a render scope (decision 388): `fn C(…) ->
@Component<R>` answers a function of std's opaque `RenderScope`, and calling
`C` runs nothing (`itens.map(Card)` answers lambdas, which the render runs with
the scope of the body that places them). In the body, `use provide(ctx)` makes
the scope its children receive, `use context(T)` finds `T`'s identity in the
scope the body received, else `T`'s declared default, and `await c` runs `c`
with the children's scope. Outside every body — `main`, a test, a plain
function, a lambda — `await c` runs `c` with `RenderScope.root()`, and
`c.run(scope)` answers the result and the children's scope, so a render
library holds the scopes explicitly; `RenderScope(…)` is refused
(`comptime/context_lower.zig`). A `Context<T>` is its value at run time. A
lambda written in a body is outside it: it takes the scope of the call that
runs it. erlang, beam, commonJS and wasm run it — on wasm a value crosses the
scope as its own word, typed where it is read back by the checker's type the
lowering carries (decision 504); a value of any type crosses it, an `f64` or
an `i64` provided or rendered there included — and a `?f64` or a `?i64`, with
its number or `null`. The comptime runtimes do not run this lowering: a
`comptime` that reaches a `use` is refused (`language-gaps.md` row
354-comptime).

<!-- example: modules/context_wide_number_through_scope -->

<!-- example: modules/context_optional_wide_number_through_scope -->

<!-- example: modules/component_is_lambda -->

<!-- example: modules/component_run_root -->

<!-- example: modules/render_scope_library -->

<!-- example: modules/comptime_reaches_use -->

**Only a component whose own body awaits is a state machine** (decision 504),
on every target: it writes `await` or `uses` an asynchronous hook (375 (1)).
Calling a component runs nothing, so one that composes others stays direct
even when it receives a component as a value; the render runs a direct
component in place and waits only on a marked one, so a synchronous component
pays nothing and a component waiting on the host (`delay`) lets the render go
on once its task settles (`modules/component_awaits_host_task`). A body that
keeps a bare `try` and then awaits is one too: the `try` leaves early with the
error before the wait, and past it the render waits on the host as before.
A `try … catch` never leaves: the `catch` value stands for the error and the
body waits on the host the same way.

<!-- example: modules/component_try_then_awaits_host_task -->

<!-- example: modules/component_try_catch_then_awaits_host_task -->

## Functions

`use` and the `@Component` return (hooks and components) are under *Expressions › use*;
the effects a return grants are under *Effects*.

### Recursion

A function may call itself. When the call is the **whole** of a `return` — a
*tail* call — it costs no stack: commonJS rewrites it into a loop, and erlang
and beam run on VMs that drop the frame. The depth of a tail-recursive walk is
bounded by the data, not by the runtime.

<!-- example: modules/self_tail_recursion -->

<!-- example: modules/tail_recursive_sum -->

An expression in the body that reads the parameters — `xs.at(i) ?? 0` — keeps
the tail call a loop:

<!-- example: modules/self_tail_recursion_nullish -->

Every other recursion uses the stack, and how deep it may go is the host's
answer, not the language's:

* a call that is not the whole of the `return` — `return 1 + f(n - 1)`;
* **mutual** recursion: `a` calling `b` calling `a`;
* a call through anything but the function's own name — a method on a value, a
  function held in a binding;
* a function that also makes a closure reading one of its own parameters, or
  one with a destructuring or defaulted parameter;
* a function returning `@Iterator`, `@Stream`, `@Task` or `@Component`.

A function may call one declared after it, so two functions recurse into each
other in either order:

<!-- example: modules/mutual_recursion_forward_reference -->

`wasm` recurses for every shape, tail call included — about 30 000 frames.
Measured at 1.0.10-beta, with node's own ceiling for a two-parameter function
between 10 000 and 20 000.

### An inline parameter type

A parameter's type may be written in place, with the field grammar of `type
Name(…)` and no name (decision 207):

<!-- example: modules/inline_parameter_type -->

The call builds the value from its own labelled arguments, each naming a field
(a defaulted one may be left out); a value already of the type is passed as the
parameter itself. One parameter of a function may have an inline type, and none
of its fields is named like another parameter. It is a top-level `fn`'s only — a
return, a field, a `val` annotation and a method's parameter refuse it — and it
is not exported: a call from another module that writes its fields is refused.
A diagnostic names it by its owner: ``the props of `link` ``. An inline type written anywhere but a parameter's type is `inline-type-outside-parameter`, refused at the type.

<!-- example: modules/inline_type_in_field -->
<!-- example: modules/inline_type_in_return -->
<!-- example: modules/inline_type_in_val_annotation -->

### Parameters with defaults

<!-- example: modules/parameter_defaults -->

A call **may leave out an argument whose parameter declares a default**, and the
declared expression is what the function receives. A default may be declared on
a free `fn`, on a record's fields (where it is the constructor's default), on a
variant's payload and on a method — including a `behavior`'s `default fn`, which
is where `"hello".slice(1)` gets its open end from (`slice(self, start: i32,
end: ?i32 = null)`). Wherever it is declared, **a default is trailing**: a
parameter or field with a default is followed only by others with defaults
(`fn lead(a: i32 = 1, b: i32)` and `type Port(number: i32 = 80, host: string)`
are refused at `b` and `host`; the diagnostic is `fn-param-default-trailing-only` for a function's or a method's parameters and `field-default-trailing-only` for a record's fields and a variant's payload).

<!-- example: modules/fn_param_default_not_trailing -->
<!-- example: modules/method_param_default_not_trailing -->
<!-- example: modules/record_field_default_not_trailing -->
<!-- example: modules/variant_payload_default_not_trailing -->

<!-- example: modules/parameter_defaults_record -->

Only the parameters a call leaves out take their defaults. A parameter the call
names by label keeps the argument it was given, whichever position it is in —
`Port(number: 8080, host: "a")` reorders to the declaration —
and a parameter with no default is still **required**: leaving one out is the
arity error it has always been.

<!-- example: modules/missing_required_argument -->

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

<!-- example: modules/variadic_parameter_total -->

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

<!-- example: modules/variadic_spread_at_call -->
<!-- example: modules/variadic_default -->
<!-- example: modules/variadic_not_array -->
<!-- example: modules/variadic_not_last -->
<!-- example: modules/variadic_twice -->

The checker packs the arguments into one array, so erlang and beam receive one
list argument and wasm one array; commonJS writes the function with a rest
parameter (`function total(label, ...values)`) and the call with the arguments
one by one, so a host function bound by `#[@external(.Node(…))]` receives them as
JavaScript does (`Math.max(3, 9, 4)`), and `#[@external(.Erlang(…))]` one list
(`lists:max([3, 9, 4])`).

### A record parameter

`..props: R` with `R` a record type (or one derived by `Type.pick`, `Type.omit`
or `Type.merge`, decision 307) makes `R`'s fields the function's parameters from
outside (decision 529 (2)): a call passes them by label, a field with a default
may be left out, and the body reads them as the record `props`. The record
parameter sits beside other parameters, which a call passes as it always did —
by position or by label. It is told from a variadic `..values: T[]` by its type:
a record type against an array.

<!-- example: modules/record_param -->
<!-- example: modules/record_param_across_modules -->

A spread (`Card(..p, featured: true)`) is legal only into a record parameter,
`p` of its type or of one derived from it (decision 359's rule); the later
supplier of a field wins, as in a record's construction, and a function of plain
parameters takes no spread (`call-spread`).

Refused: a second record parameter (`record-param-twice`, at its `..`), a type
that is no record (`record-param-not-record`, at the type), a name that is both a
parameter and a field of the record (`record-param-clash`, at the parameter), a
record parameter beside a variadic (`record-param-variadic`, at the variadic) and
a default on it (`record-param-default`, at the `=`), all at the declaration; at
a call, a label that names neither a parameter nor a field
(`record-param-label`, at the label) and a spread of a value that is not of
the record's type or one derived from it (`record-spread-type`, at the `..`).

<!-- example: modules/record_param_twice -->
<!-- example: modules/record_param_not_record -->
<!-- example: modules/record_param_clash -->
<!-- example: modules/record_param_variadic -->
<!-- example: modules/record_param_default -->
<!-- example: modules/record_param_unknown_label -->
<!-- example: modules/record_param_spread_other_type -->

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

```text
error: effect-try-without-fallible-channel: `try` needs a `@Result` in some layer
of the return — this fn's return has no `@Result` in it; `try … catch` handles
the failure on the spot, and a host binding answers a `@Result` with `result: true`
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

#### Body markers

A body that compiles specially carries a marker (decision 553): `async` (its
body may `await`), `iter` (`yield`), `async iter` (`yield` and `await`) and
`component` (`use`, `await`), written right before `fn` — `[#[…]] [pub]
[default] <marker> fn` — on a declaration, a type's method, a behavior's
`default fn` and an implement's method, and the return type is the wrapper the
marker names. The marked body answers what the same body answers unmarked:

<!-- example: modules/marker_fn_forms -->

A marker whose return type is not its wrapper, or a marked function with no
return type, is `marker-type-mismatch` at the marker; a declaration without a
body takes no marker (`marker-on-declaration`) — its return type alone says
what it answers:

<!-- example: modules/marker_type_mismatch -->
<!-- example: modules/marker_on_declaration -->

Before a lambda's brace the marker makes a marked lambda — `async { x -> … }`,
`iter { n -> … }`, `async iter { n -> … }` — and before `fn(…)` a marked
function expression; `->` tells the lambda from the block forms `async { … }`
and `iter loop { … }`. A marked lambda is typed by the function type it is
written for (decision 147): an annotated `val`, a parameter. It answers what the
lambda returning the block form would — `async { x -> b }` is
`{ x -> async { b } }`, `iter { x -> b }` is `{ x -> iter loop { b; break; } }`:

<!-- example: modules/marker_lambda_async -->
<!-- example: modules/marker_lambda_iter -->

With no function type to agree with it is
`marker-lambda-without-expected-type`, with another wrapper than its own
`marker-type-mismatch`, and `iter`, `async iter` or `component` before a brace
without `->` is `marker-without-arrow` — a function named `iter`, `async` or
`component` called with a trailing lambda writes its parentheses:

<!-- example: modules/marker_lambda_without_expected_type -->
<!-- example: modules/marker_lambda_type_mismatch -->
<!-- example: modules/marker_without_arrow -->

A `component { x -> … }` lambda is a `component fn` (decision 574): typed by
the function type it is written for, `fn(x: T) -> @Component<R>`, its body is a
component body — it `use`s and `await`s, and its `return`s and its last
expression answer `R` — and calling it only makes the component, which runs
where it is rendered, with the scope it is rendered with. Its parameters and
what it captures reach the body:

<!-- example: modules/component_lambda_typed_val -->
<!-- example: modules/component_lambda_typed_param -->

Until every body writes its marker, an unmarked body keeps its return's effect
(`-> @Iterator<T>` with a `yield` is still a generator).

### Results

A function that can fail returns `@Result<T, E>`; `throw` produces the error,
`return` the value, and `try` propagates the error of a call.

<!-- example: modules/result_throw_try -->

A `throw` in a `case` arm is the enclosing function's: in an expression arm
(`_ -> throw e;`) and in a block arm (`_ { …; throw e; }`), whether the `case` is
returned, bound by a `val`, passed as an argument or written as a statement, the
function answers `Error(e)` on that path and the other arms' value on the rest.

<!-- example: modules/throw_in_case_arm_result -->

A method declared `-> @Result` is a function like any other (decision 304): a record's and an
enum's method, and a behavior's method dispatched through a parameter typed by the behavior —
its `default fn` included — answer `Ok(v)` for `return v` and `Error(e)` for `throw e`, and their
`try` propagates, on every target:

<!-- example: modules/result_method_throw -->
<!-- example: modules/behavior_method_result_dispatch -->

Three ways to consume a `@Result`, and a fourth for when a failure is a bug:

<!-- example: modules/result_four_ways -->

The value a `@Result` holds is whole whatever its type: an `f64` or an `i64` comes back unchanged
through `unwrapOr`, a `case` arm's binder, `try`, `try … catch`, `map` and `flatMap`:

<!-- example: modules/result_wide_payloads -->

<!-- example: modules/result_i64_map_flat_map -->

**`try` and `await` are prefix operators**, binding as the unary `-` does (decision 537).
They stand wherever an operand does: `await t * 2` is `(await t) * 2`, `await x + await y` is
`(await x) + (await y)`, `try load() + 1` is `(try load()) + 1`, and `total + try r`, `-try x`,
`(try r).length` and `!await t` each have one reading. Postfix (`.`, `()`, `[]`) binds tighter than
the prefixes, as `-t.x` is `-(t.x)`: `await t.x` is `await (t.x)` and `await f()` is
`await (f())`. `try await f()` is `try (await f())`. There is no `try-await-operand` refusal:

<!-- example: modules/try_await_prefix_operators -->
<!-- example: modules/await_postfix_binds_tighter -->
<!-- example: modules/result_try_each_operand -->

**`catch` is an infix operator of the lowest precedence**: its right side is evaluated first and is
the fallback, its left side is the whole expression before it. `try await t catch 0 * 2` is
`(try await t) catch (0 * 2)`, and parentheses group as anywhere —
`(try await t catch 0) * 2` doubles the result:

<!-- example: modules/catch_lowest_precedence -->

A `throw` or a propagating `try` needs a `@Result` in some layer of the
enclosing function's return (`@Result<T, E>`, `@Task<@Result<T, E>>`,
`@Iterator<@Result<T, E>>`, …); in a function with none, and in a lambda whose
expected return has none, both are `effect-try-without-fallible-channel`. The
message names the two ways out: `try … catch` handles the failure on the spot,
in any function, and needs no channel; a host binding answers a `@Result` with
`result: true` (§ Host bindings). The refusal is located at the `throw` or the
`try`, and its middle part names the return that lacks the channel — a plain
`fn`, a `@Task<T>`, a `@Component`, the item of an `@Iterator<T>`, a lambda's
expected return:

<!-- example: modules/throw_outside_result -->

<!-- example: modules/try_in_plain_fn -->

<!-- example: modules/task_throw_without_result -->

<!-- example: modules/task_try_await_without_result -->

<!-- example: modules/component_try_element -->

<!-- example: modules/throw_in_generator -->

<!-- example: modules/try_in_generator -->

<!-- example: modules/try_in_lambda_without_result -->

**A crash is contained by `attempt`.** `@panic`, `@todo`, `x!` over `null`, a
failed `assert`, an integer overflow or division by zero, and a raise from a
host binding without `result: true` are defects, never in a signature. std's
`failure.attempt(f)` runs `f` and answers `@Result<T, Failure>`: `Ok` of its
value, or `Error(Failure(message, kind))` for the crash it caught — `kind` is
`"panic"` for the program's own abort, its message the text the program wrote,
`"host"` for a host raise, its message the host's text (a JavaScript
`Error`'s `message`, the erlang reason by `~tp`), and `"crash"` for a raise nothing
marked (a `case` no arm matches, a std binding's raise, a raise of the program's own code). The program goes on after a
contained crash:

<!-- example: modules/std_failure_attempt_abort_kinds -->

A failing `assert` is a `panic` whose message names the
asserted condition and where it failed (decision 527 (2)):

<!-- example: modules/assert_failure_is_panic -->

An integer `/` or `%` by zero is a `panic` too, `integer division by zero: <op>
on <type> at <file>:<line>:<col>`, on every target (527 (3)) — on wasm the division
is checked and raises, so `attempt` catches it:

<!-- example: modules/int_division_by_zero_is_panic -->

A host raise answers `host` where a host raises — commonJS, erlang and beam;
wasm never imitates one (527 (0)). On erlang and beam its message is the reason
printed by `~tp` without the stack, whatever the class (527 (4)), and only a binding
declared outside std without `result: true` — a library's or the program's — marks its
raise `host` (546): std's bindings are audited one by one (495), so a raise of one that
the audit did not list is a `crash`, as is any raise nothing marked:

<!-- example: modules/std_failure_attempt_host -->
<!-- example: modules/std_failure_attempt_crash -->

`try e catch f` handles the `Error` of its operand's `@Result` on the spot (431), and only
that: a host raise or a `@panic` inside the operand is not an `Error`, it leaves the
`try … catch` and only `attempt` contains it. A `result: true` binding answers its
failure as an `Error`, so that one reaches the `catch`:

<!-- example: modules/try_catch_host_raise_propagates -->

On wasm `attempt` runs the thunk under wasm exception
handling (decision 518): a program reaching it raises its aborts as an
exception, which `attempt` catches as `panic` — an `@panic`, an assert, an integer overflow, a
division by zero; a trap is no exception and ends the program.

<!-- example: modules/std_failure_attempt -->

`attempt` answers the same at build: a `comptime` body, a template or a
decorator that calls it gets `Ok` of the thunk's value, or
`Error(Failure(message, "panic"))` for the abort the thunk raised — as a wasm
program does, on every target (decisions 518, 543).

<!-- example: modules/comptime_attempt_at_build -->

`failure.attemptTask(f)` is its `@Task` form: it awaits the task `f` answers,
and is `Error(Failure)` when that task crashed. A task that fails with its own
`E` did not crash — its `@Result` is the value.

<!-- example: modules/std_failure_attempt_task -->

`testing.asserts`' `throws(body)` and `throwsWith(body, needle)` run the body
under `attempt`, generic over what the body answers (decision 493): each is
`Error` when the body completes, and `throwsWith` also when the caught
`Failure`'s message does not contain `needle` — a host raise's message is the
host's text, the erlang reason by `~tp` without its class.

<!-- example: modules/std_asserts_throws_over_attempt -->

### Tasks

`@Task<T>` is a value that has not arrived yet, and `await` unwraps it. A
`@Task<T>` **never fails** (decisions 120, 432): if the operation can go wrong,
the value is a `@Result` — `@Task<@Result<T, E>>` is the task that fails with
`E` — and `await` hands over that `@Result`. To propagate the error, combine it
with `try`:

<!-- example: modules/task_result_await -->

`await` and `try` are separate things — `await t` waits, `try r` propagates.
With `t: @Task<@Result<U, E>>`:

| I write | I get | Legal where |
|---|---|---|
| `await t` | `@Result<U, E>` | with an await channel |
| `try await t` | `U` (the error rises) | with an await channel **and** a `@Result` in the return |
| `try await t catch x` | `U` (or `x`) | with an await channel |

Every way a failing task reaches an `await` reads the same on every target —
a function or a method that throws, a task handed over whole, generic code
awaiting a `@Task<T>`, tasks started before either is awaited, an
`async { }` block that throws:

<!-- example: modules/task_result_rejects -->

A generic function over a thunk answering a task — `work: fn() -> @Task<@Result<T,
E>>`, std's `async.retry` — binds `T` and `E` from the thunk's answer, in its own
module or another, and so does the generic it passes the thunk on to:

<!-- example: modules/generic_thunk_result_binds -->

An `await` may sit in an arm of a `case`, in a branch of an `if` or in a `case` nested in
an arm, in a generic function as in a plain one: the task suspends there and resumes into
the arm, with the same answer on every target:

<!-- example: modules/task_await_in_case_arm -->

An `async { }` block that throws is that failing task wherever it sits — the
body of a lambda, a lambda bound inside a function, a method, a lambda a
method answers:

<!-- example: modules/task_async_block_in_lambda -->

The lambda's type is the same written or not: bound without an annotation
(`val failing = { n -> async { throw "inner"; } }`) it is still a function
answering `@Task<@Result<…>>`, and its `await` reads back as `Error(e)`; a
lambda a function or method returns takes its parameters from the declared
`fn(n: i32) -> …`, so `n.toString()` in it resolves:

<!-- example: modules/task_lambda_result_unannotated -->

<!-- example: modules/task_lambda_method_to_string -->

**A `@Task` has no methods** (decision 523). `map`, `then`, `mapError` and `catch` are
withdrawn from `@Task<T>` and from `@Task<@Result<T, E>>`, so a call to one is refused as
an unknown member:

<!-- example: modules/task_method_refused -->

A task's value is read by `await`, and a failing task is read one way: `try await … catch`,
or `case` on `await`'s `@Result`. Every composition of a task — recover, map, bind, map the
error — is an `async { }` block, itself a `@Task` (decision 375): `val safe = async { try await
load() catch 0 };` is a `@Task<i32>`.

<!-- example: modules/task_compose_by_async_block -->

An **await channel** is a `@Task`, `@Component` or `@Stream` return, an
`async { }` block or a `stream` loop; `await` anywhere else is
`await-without-async`. An ordinary function that holds a Task either
returns a `@Task` too or hands the Task on.

**`async { … }` — a Task in the middle of a function** (decision 124). The block
creates a `@Task` without declaring a separate function, in **any** function:
it waits for nothing, it creates the Task.

<!-- example: modules/async_block_both -->

<!-- example: modules/async_block_tail_value -->

<!-- example: modules/async_block_tail_case -->

<!-- example: modules/await_result_print -->

An awaited `@Result` is the value it is: `@print` of `await f(x)` answers
`Ok(21)` or `Error("negative")` on every target, for a generic `f`, a plain one
and an `async { }` block that fails.

- its value is its last expression written without `;` (decision 525, § Blocks),
  a braced `case` / `if` at its end included, and `return v` **leaves the
  block** with `v`, not the enclosing function — the block is a task of its
  own;
- it is **closed**: inside a `@Component` function an `async { }` cannot `use`,
  and `break :outer` / `continue :outer` across its border are refused;
- `T` comes from its tail and its `return`s. A body with `throw` or `try` makes the value
  `@Result<U, E>` on its own, `E` coming from those `throw` / `try`; two
  different error types are `gen-infer-conflicting-errors`, asking for an
  annotation: `val x: @Task<@Result<User, string>> = async { … };`.

**Per backend.** On commonJS every `@Task` function, and every `@Component`
one whose hooks node is asynchronous (decision 375), is an `async function`
and its caller awaits; `async { }` is `(async () => { … })()`.
**A `@Task<@Result<T, E>>` rejects its Promise with `E` and resolves it with
the bare `T`** (decision 432) — no `{ ok }` / `{ error }` wrapper: JavaScript
that awaits a botopink task writes `try { await t } catch (e) { … }`, and the
`.d.ts` declares `Promise<T>` under `/** @throws {E} */`. A failing task nobody
awaits is not an unhandled rejection.

<!-- example: modules/task_result_caught_by_js -->

<!-- example: modules/task_failure_rejects -->

On erlang and beam a `@Task` is eager, `await` is the identity — a failing
task's value is `{error, E}` — and `async { }` runs the block in place.

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

<!-- example: modules/iterator_yield_break -->

Nothing of the body runs before the first `next`, and nothing past the `yield` that
answered the last one: a print before and after a `yield` comes out between the
items, and an endless generator is consumed by `take(n)` — on every form, an
`iter fn`, an `iter loop` and a marked lambda `iter { -> … }`.

<!-- example: modules/generator_body_lazy -->

A generator handle is stateful, whatever its body: a second `for` over a handle the
first one exhausted reads nothing — on an `iter fn`, whether its body is only
literal `yield`s or runs code, and on an `iter loop`.

<!-- example: modules/generator_handle_stateful -->

A generator's body captures the enclosing scope's variables as a closure (decision 105): a captured
`var` is one variable on both sides. What the function writes after making the generator, or between
two items, is what the body reads next; what the body writes is what the function reads after it — in
the same block, in a nested one, and in a lambda.

<!-- example: modules/generator_captured_var_shared -->

**Items that can fail — `@Iterator<@Result<T, E>>`.** The iterator does not
fail; **each item** may be an error. When the item is `@Result<U, E>` the body
gains the sugar: `yield v` with `v: U` emits `Ok(v)` (with `v: @Result<U, E>` it
emits it as is), `throw e` emits `Error(e)` and ends, and a `try x` that fails
emits `Error(e)` and ends. Whoever iterates receives the `@Result` and decides —
**`for` does no implicit `try`**:

<!-- example: modules/iterator_result_items_handled -->

**`@Stream<T>` — asynchronous, iterated with `for await`.** The rules above
hold, and a failing `try await` also emits `Error(e)` and ends:

<!-- example: modules/stream_pages_count -->

**Iterator or factory.** A function with an `@Iterator` or `@Stream` return is
an iterator if its own body has `yield` or `break v` (not counting closures and
inner `iter` / `stream` loops); otherwise it is an ordinary function that
**returns** a ready-made iterator. Mixing the two in one body is
`iter-mixed-yield-return`.

<!-- example: modules/iterator_vs_factory -->

**A type that is iterated exposes a method** answering an iterator; there is no
iterable behavior, and the consumer calls it — `for (grid.iter())`:

<!-- example: modules/iterator_method -->

The refusals, each located:

<!-- example: modules/iterator_throw_without_result -->

<!-- example: modules/iter_await_refused -->

<!-- example: modules/iter_mixed_yield_return -->

<!-- example: modules/iterator_error_param_removed -->

**Per backend.** On commonJS an `@Iterator` function with `yield` is a
`function*` and a `@Stream` one an `async function*`; a factory is a plain
function. A generator cannot be an arrow function, so `this` and captured
variables get the treatment ordinary closures get.

## Comptime

### Compile-time evaluation

<!-- example: modules/comptime_block_value -->

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
writes its answer back as the enum's constructor, as it writes an enum value in
a record's field (a generic record's field typed by its parameter included). A section path written in a
function the `comptime` reaches is resolved where that function is inferred,
so, as with a template call, the function is declared before the `comptime` —
otherwise the `comptime` is refused, naming the path. A decorator's argument
(`#[mark(.Pad.All.4)]`, read as `tokens`) and the functions a decorator
reaches carry the same values.

<!-- example: modules/comptime_section_value -->

<!-- example: modules/comptime_enum_in_record -->

What a `comptime` computes is what the program computes when it runs, one
answer for every target (decisions 331, 434 (5)): the primitives' methods —
the integer conversions (`1000.toI64()`), strings, floats, arrays, integer
division —, a suffixed number literal (`4500000000l` is the `i64` its suffix
types, lifted back by its digits), a `@Result`'s methods (`unwrapOr`, `isOk`,
`map`, `flatMap`) and a `@Result` function's own `return` / `throw`, and a
function named as a value and passed as an argument (`r.flatMap(half)`,
`xs.map(double)`).

<!-- example: modules/comptime_primitives_at_build -->

<!-- example: modules/comptime_wide_literal -->

<!-- example: modules/comptime_result_methods -->

<!-- example: modules/comptime_function_value_argument -->

A `comptime` whose evaluation raises is refused at the call that raised
(decision 451 (3)) — the innermost of this module's calls the raise leaves,
`@panic` in a function the `comptime` called — not at the `comptime`
expression, which the hint names as the frame that ran it:

<!-- example: modules/typeinfo_all_duplicate_at_entry -->

<!-- example: modules/comptime_random_float_unseeded -->

### Template functions

A template is a function whose first parameter (after an `expr self: R`
receiver) is `expr q: string` — its **template text** — and nothing else
(decisions 577, 578); a template declared with other parameters is refused at
its declaration (`template-signature`). It answers a type `R`, `anyvalue` (the
type of whatever it builds, decided per call) or `anytype`. It is called one
way, its name before a template text `` @`…` ``: `` name @`…` ``,
`` value.name @`…` ``, or as an annotation `` #[name @`…`] ``; `name "…"`,
`name(…)` and the template taken as a value are `expr-call-outside-expr`. The
template text may span lines and holds its bytes as written — no escape but
`` \` `` for a backtick, no interpolation. `q` is opaque in the body, handed
only to `compiler.*` — `compiler.text(q)` answers the raw text,
`compiler.lookup(q, name)` a declaration — or into a tree (decision 576), and
`return e` hands `e` to the call site: a `comptime` value is spliced as a
literal, an `expr` as written.

A `comptime x: T` parameter of a function that is no template is read as `x`
whatever reads it — an operand, or a method's receiver (`names.split(",")`):
each call is specialized with its argument's value, and the specialization
answers what the function declares.

<!-- example: modules/expr_param_value_receiver -->

<!-- example: modules/yamlconf -->

The value a template lifts has the type of what it built, so a label the lifted
tuple does not have is refused where it is read, located:

<!-- example: modules/yamlconf_unknown_label -->

The code a template builds has two authors, and each name in it resolves in
the scope of whoever wrote it (decision 112). Text the library writes in
`compiler.build` resolves in the **library's** module, its private functions
included, and names that declaration wherever the template is expanded; the
text from `compiler.text(e)` resolves at the **call site**, with the consumer's
imports, aliases and locals. So `compiler.build("double(" + compiler.text(e) + ")")` calls
the library's `double` even where the consumer declares its own, and
`` shapesdsl @`surface(4, 5)` `` reaches `area` through the consumer's
`import {area as surface}`. `compiler.lookup(e, name)` resolves at the call site and
answers the declaration — its own name and module, never the alias (below) —,
which is what hover and go-to-definition inside the literal follow.

**A hole is the template's** (decision 577 (1), (5)). `${…}` and `{…}` in a
template text are the sub-language's own syntax: the template finds them in
`compiler.text(q)` and splices each hole's expression into the code it builds,
where it is typed in the caller's scope; the template never reads a hole's
value. The code it builds is then evaluated as any code is: what the compiler
folds at build (decisions 355, 376, 380) it folds, and a value that raises
there is refused at the call that raised (§ Compile-time evaluation), with a
`called from` line for each call of the chain (decision 532):

<!-- example: modules/template_known_at_build -->

<!-- example: modules/template_hole_typed_at_caller -->

A template call expands wherever an expression may stand (decision 425): a
function's or a type's method body, a destructuring initializer
(`` val #(n, total) = f @`…`; ``), a lambda (one a module-level `val` holds
included), an argument, a record field's or a
parameter's default (each call that leaves it out gets the expansion), a
`case` arm, and the code another template builds — a template call in built
code expands in turn, as one written at the call site does. A call the
compiler did not expand is refused where it is written
(`template-call-unexpanded`), never left to run as a call of a function that
exists only at build.

<!-- example: modules/template_in_module_val_lambda -->
<!-- example: modules/template_call_in_built_code -->

A template function's name follows the scope rule: the nearest binding wins,
so a parameter or a local of the name is the value a call there calls
(`fn run(shout: fn(string) -> string) { return shout("x"); }`), and the
template is the name's everywhere else. Named without a call a template
function is no value — it exists only while the program compiles — and
`val f = shout;` is refused where the name is read (`template-function-value`).

<!-- example: modules/template_name_shadowed_by_local -->
<!-- example: modules/template_function_value -->

A template a library exports answers a type of the library's, and the call's
value is that type wherever it was not imported: its fields and their methods
resolve on every target, as they do on the value of an imported function
(`built.size.toString()` after `` val built = shelf @`built` ``).

<!-- example: modules/template_answer_method -->

A library's default handle is also its namespace: after `import {shapes} from
"shapes"`, where the package's default module declares the template `shapes`,
`shapes.twice(21)` calls that module's member `twice`, on every target:

<!-- example: modules/default_handle_member -->

**A call is typed by the code it built** (decision 426). The type of a
template call is the type of the code the template built for that call,
computed at build, so `fn data(expr q: string) -> anyvalue` answers
`string[]` at one call and `i32` at another. The template's answer is a bound
the built code fits — `unknown` holds anything, so `-> unknown[]` keeps the
call's `string[]` —, and code outside it is refused in the template, at its
`compiler.build` (`template-build-outside-bound`). The call then meets the type
expected where it stands as any expression does: `` val n: i32 = names
@`cities`; `` is `type mismatch: expected i32, got string[]`
at the call. The template never reads the expected type, so what it builds is
decided by its text; `compiler.note(message)` gives the reason, attached to an error
reported at its call (`— note: …`).

<!-- example: modules/template_call_typed_by_expansion -->
<!-- example: modules/template_call_expected_mismatch -->
<!-- example: modules/template_build_outside_bound -->
<!-- example: modules/template_note_on_mismatch -->

**A declaration looked up** (decision 415). In a template body a name of the
literal is text, not a name of the template's module: `compiler.lookup(q, name)`
— `name` a word of the literal — resolves it where the call stands and answers
the declaration as a read-only handle, `?unknown`, read only through
`compiler.*` (decision 576 (3), (8)): `compiler.name(d)` (an import's alias
answers the declaration it names), `compiler.kind(d)`, `compiler.moduleOf(d)`,
`compiler.fields(d)`, `compiler.variants(d)`, `compiler.methods(d)`,
`compiler.params(d)`; `null` when nothing of that name is in scope.
`compiler.bindings(q)` lists every declaration a word of the literal names. The
outputs — `compiler.setMeta`, `compiler.addMeta`, `compiler.addMember`,
`compiler.addType` and `compiler.wrapWith` — are a decorator's only, and in a
template body are `compiler-output-outside-decorator`, at the call.

<!-- example: modules/template_lookup_decl -->
<!-- example: modules/template_lookup_decl_members -->
<!-- example: modules/template_lookup_decl_write -->
<!-- example: modules/template_lookup_decl_wrap_with -->

`compiler.bindings(q)` answers those handles (question B-18-b) — one per
declaration, each under its own name and module, an alias's included —, and
`compiler.moduleOf(d)` answers a module for every handle, a decorator's own
too.

<!-- example: modules/template_bindings_decls -->
<!-- example: modules/decorator_decl_module -->

On a handle, `compiler.meta<T>(d)` (`?T`) and `compiler.metaAll<T>(d)` (`T[]`)
answer at build what the declaration's decorators recorded, when the record `T`
is data — each field a string, a number, a `bool`, a variant, an array or an
optional of those; a field the value left out reads its default. A record with
a field that holds a tree (filled from an `expr` parameter, § Typed meta) holds
code the program runs, and its read is refused, naming the field
(`template-lookup-meta-expr-field`); `@typeInfo(X).meta(T)` in a template body
stays `typeinfo-meta-at-build`.

<!-- example: modules/template_lookup_meta -->
<!-- example: modules/template_lookup_meta_expr_field -->

The looked-up declaration's decorators run before the template body. A
declaration of another module carries what its module's decorators recorded;
in one module the decorators run before the bodies and the `val`s, so a call
written above the annotated declaration reads its meta — except a decorator
that reads `compiler.hooks(d)`, which runs after the bodies (decision 372): its meta read
before it ran is refused at the call's literal (`typeinfo-meta-hooks-pending`).

<!-- example: modules/template_lookup_meta_other_module -->
<!-- example: modules/template_lookup_meta_same_module -->
<!-- example: modules/template_lookup_meta_hooks_pending -->

**A template method** (decisions 311 (3), 397 (3), 415 (1)). A template whose
first parameter is `expr self: R` and whose second is `expr q: string` is
called on a value, `` value.method @`…` ``, as `` f @`…` `` is.
The receiver is the call site's code, its type checked against `R` as an
argument's is (a behavior accepts a type that implements it);
`compiler.text(self)` is the receiver as written, so the code the template
builds runs on the receiver where the call stands. The literal is captured as
at any call. The template method is a name of the call site's scope, declared
there or imported; a method of the receiver's own type of that name is the
type's — written in its body, or a method of a behavior it implements, that
behavior's `default fn` included; a value of a behavior has the methods the
behavior declares.

<!-- example: modules/template_method_call -->
<!-- example: modules/template_method_own_method -->
<!-- example: modules/template_method_behavior_method -->

A receiver whose type is not `R` and does not implement it is refused at the
receiver, as an argument would be. The receiver's type imports nothing by
itself (question B-18-a): a template method declared beside a type and not
imported where the call stands is no name there, and `` value.method @`…` `` is
refused as a call of a method the type does not have.

<!-- example: modules/template_method_receiver_mismatch -->
<!-- example: modules/template_method_not_in_scope -->

A template refuses its call with `compiler.fail(message, at: q)`, located at
the literal, or with `compiler.fail(message, at: q, span: Span(start, end,
line))`, located at that span of its text in the caller's file: on the opening
line of a template text the text begins after its `` @` ``.

<!-- example: modules/template_fail_at_column_on_open_line -->

A template whose second parameter is `expr decl: unknown` is written as an
annotation, `` #[f @`…`] `` — § Template annotations below.

The calls a template function's built code makes of the expanding module's
functions build an inline parameter type as the written calls do (decisions
192, 207, 430):

<!-- example: modules/template_builds_inline_props -->

### Decorators

A decorator is a function whose first parameter is `expr` (decisions 575 (4),
576 (10)) — `fn mark<T>(expr decl: T, comptime label: string)`, `expr decl:
unknown` when the declaration has no pattern; `#[name(args)]` runs it at
compile time over the declaration it annotates, the annotation's arguments after
that parameter. `decl` is an opaque handle, read through the keyword `compiler`
(decision 575 (3)): `compiler.kind(decl)`, `compiler.name(decl)!`,
`compiler.fields(decl)`, `compiler.variants(decl)`, `compiler.methods(decl)`,
`compiler.returnType(decl)`, `compiler.annotations(decl)`,
`compiler.owner(decl)`, a function's or a method's own `compiler.params(decl)`,
and a function's `compiler.hooks(decl)` (§ The hooks a function reaches).
`compiler.fail(message, at: decl)` refuses it at the annotation, and what the
decorator produces goes to one of four places (decisions 216, 575 (3), 576),
the outputs a decorator's only (`compiler-output-outside-decorator`):

| Place | Written | Read |
|---|---|---|
| a member of the annotated type | `compiler.addMember("table", fn() -> string { … })` — the member a function expression at the call | `City.table()`, `c.describe()` — run-time code of the type, imported with it |
| comptime meta, a typed value keyed by its type (decision 298) | `compiler.setMeta(Entity(table: "cities"))`, `compiler.addMeta(Index(column: "name"))` | `@typeInfo(City).meta(Entity)` → `?Entity`, `.metaAll(Index)` → `Index[]`, and on a `@TypeInfo.all` entry — the values written back where they are read |
| an associated type | `compiler.addType("Columns", compiler.buildType("(name: string)"))` — a type built from its text (decision 578 (3)) | `City.Columns` in a type position, `City.Columns(name: "n")`, imported with its owner |
| the program's catalogue | (every declaration a decorator runs over) | `@TypeInfo.all(with: entity)` at an entry point (`compiler.catalogue(with: entity)` is the same query) |

An associated type is named `City.Columns` in every diagnostic, as it is
written:

<!-- example: modules/assoc_type_named_by_owner_in_diagnostic -->

A type error inside a member or an associated type a decorator wrote is located
at the annotation on the declaration that added it (decision 567), the
decorator's `compiler.addMember` / `compiler.addType` call its `called from` line; one
error per failing annotation:

<!-- example: modules/decorator_member_type_error_at_annotation -->

<!-- example: modules/decorator_assoc_type_error_at_annotation -->

<!-- example: modules/decorator_output_error_one_per_annotation -->

A member or an associated type from a field's or a method's decorator belongs
to the type that owns it; a function and a module-level `val` have none
(`decorator-member-without-type`, `decorator-type-without-owner`). A decorator
on a `val` runs like one on a `fn` (decision 356): `compiler.kind(decl)` is
`DeclKind.Val`, `compiler.returnType(decl)` the declared type as written (`""`
when none), `compiler.setMeta` is legal, and the `val` is an entry of
`@TypeInfo.all` — one query answers functions, `val`s or types, never two
of them
(`typeinfo-all-mixed`). A decorator adds and never replaces: a name
the type already has is `decorator-member-duplicate` / `decorator-type-duplicate`.
Meta describes a top-level declaration — a `type`, a `behavior`, a `fn` or a `val`
(`decorator-meta-on-member` from a field's or a method's decorator).
A record-shaped type's members are closed: a call through the type names an
associated fn it declares, by hand or through `compiler.addMember`, and any other
name is `unknown-associated-fn` where the call is written.

<!-- example: modules/associated_fn_unknown -->

<!-- example: modules/decorator_entity_table -->

A member's handle names its owner (decision 526): `compiler.owner(decl)` is
the handle of the type or behavior that holds the annotated method or field —
`compiler.name(owner)`, `compiler.moduleOf(owner)` — and `null` for a
module-level declaration. A registration a member's decorator compiles is named
through it (`compiler.name(compiler.owner(decl)!)! + "_" +
compiler.name(decl)!`), so two same-named members of two types never collide.

<!-- example: modules/decl_member_owner -->

A decorator's body runs in its own module wherever it annotates: an imported
decorator may build a record private to that module. A body that raises is
refused at the call that raised, in the file that call is written in
(`src/deco.bp:3:5`), and every call of the chain is a `called from <file>:<line>:<column>`
line under it, innermost first, down to the annotation that ran the body
(decision 532). A template's body runs the same way: one declared in another
module whose body raises is refused at the call that raised, in the template's
file (`src/tpl.bp:3:5`), with the call that expanded it as the `called from`
line. A call inside a template's expansion takes the place of the template's
use, the one line the expansion has in the file.

<!-- example: modules/decorator_imported_builds_private_record -->

<!-- example: modules/decorator_raise_names_body_file -->

<!-- example: modules/template_raise_names_body_file -->

A template declared in the module that uses it is located the same way: its body's raising call is refused in
that module's own file, and the use is its `called from` line.

<!-- example: modules/template_own_raise_located -->

A decorator is reached by its name, an alias or a namespace (decision 386):
`import {markers} from "web";` registers the module's decorators under
`markers.<name>`, as std's are, so `#[markers.tag]` runs `tag` as `#[tag]`
imported by name does, and `markers.serverOnly` is a `Decorator` value
(`a.decorator.same(markers.serverOnly)`).

<!-- example: modules/decorator_through_namespace -->

A body declared in the annotated module that raises is refused at the call that
raised (decisions 451 (3), 532) — the innermost call the raise leaves, in the
body or in a function the body calls, of this module or another — and each call
of the chain is a `called from` line, down to the annotation that ran the body
(``called from src/main.bp:13:13``, ``called from src/main.bp:17:3``):

<!-- example: modules/decorator_helper_raise_located -->

<!-- example: modules/decorator_random_float_unseeded -->

A decorator's body reaches the std modules its module imports, a nested
namespace included (`io.random.seed(7)` after `import {io} from "std"`); a body
whose run fails is checked with them bound, so its answer is its own error —
never the namespace read as unbound:

<!-- example: modules/decorator_nested_std_namespace -->

A member a decorator adds is written as if by hand: a record update in its body
(`Point(..self, y: 0)`) copies every field it does not name. A decorator's body
is an ordinary function body, however many locals a lambda in it holds.

<!-- example: modules/decorator_member_record_update -->

<!-- example: modules/decorator_lambda_many_locals -->

**An annotation's labelled argument is `label: value`** (decision 305), in every
annotation — a decorator's (`#[check(…, at: .confirm)]`), `@BeamMemory`'s
(`keyed: true`), `@external`'s sources (`inline: true`, `body: powBody`) — as a call's
labelled argument is, and `botopink format` prints it so. `label = value` is
refused where it is written, at the label, naming `label:`:

<!-- example: modules/annotation_label_equals -->

<!-- example: modules/annotation_label_equals_decorator -->

A decorator's arguments are typed compile-time values (decision 280), checked
where they are written, as a call's are:

1. **Every parameter after the first is `comptime x: T` or `expr x: T`**
   (decision 575 (4)). A `comptime` parameter is the argument's value, known at
   build, which the body reads as `x`, a `T`; an `expr` parameter is the user's
   expression, checked against `T` where it is written and handed only to
   `compiler.*` or into a tree; what runs later comes from the decorator's
   outputs. A parameter with neither is `decorator-param-not-comptime` at the
   parameter. A `comptime` parameter may take a default, which an annotation
   that leaves it out gets — a literal, `null`, a variant `.Name`, or an array
   or tuple of those; outside a decorator no call fills one, and a `comptime`
   default there is `comptime-default-outside-decorator` at the default — but for a top-level
   function's default that is a `@TypeInfo.all(…)` query (decision 551,
   § Typed meta).
2. **An argument may be of any type** — a string, a number, an array, a
   record built by its constructor (directly or through a module `val`), a
   variant, a function, a type (`comptime t: type<T>`), a field. It is checked
   against its parameter's type at the argument (an integer literal takes the
   integer type asked for, decision 247), positional arguments first and
   labelled ones by name (`at: .confirm`); a variadic last parameter (decision
   267) takes the positional arguments left. The body reads a `comptime`
   argument's value as it is: `[1, 2]`'s has length 2. An argument not known at
   compile time — a function call such as `env("X")`, a module `var` — is
   refused at it (`decorator-value-not-comptime`) when the body reads the
   parameter; a body that never reads it accepts any expression of `T`.
   `compiler.fail("…", at: x)` refuses the declaration at `x`'s argument, not at
   the annotation.
3. **The first parameter's type names the shape of the annotated
   declaration** — a type, a field's type, a function's type — and binds the
   type parameters it names, through a pattern too: `expr decl: fn(e: E) ->
   unknown` binds `E` to the function's parameter type. A declaration that does
   not fit is refused at the annotation, both shapes spelled; `expr decl:
   unknown` fits any.
4. **`Type.Field<T>` and `.name`** — a field of `T` (decision 308, std's
   `types.bp`); `.name` resolves against the `T` the parameter expects, a field
   `T` does not declare is refused at the `.name`, and the body reads it as the
   record `compiler.fields(decl)` hands out (`name`, `typeName`, `annotations`). A
   variant against an enum parameter resolves the same way. Either is named
   exactly as declared, case included: `.custom` against `Custom` is the
   missing-name error. A name that points at botopink code is a reference; a
   name of another system (a table, a URL, a cache key, text for a user) stays
   a string.

<!-- example: modules/decorator_arguments_meta -->

A function or a type argument is checked at the argument and never run at
build (decision 364 (3)). The body hands an `expr` on to the program through a
typed member (decision 370 (2)) — `compiler.addMember(name, fn…)` with the
member written as a function expression at the call, its parameters and its
return typed:

<!-- example: modules/decorator_expr_message_runtime -->

The member is the program's code, a tree (decision 575 (4)): a member holds
run-time code, its `expr` parameters spliced as the annotation wrote them, its
`comptime` parameters and the body's locals spliced as literals (a string, a
number, a `bool`, `null` or an array of those). The type receives `pub fn
validate(self: Self) -> Violation[] { … }` with each `expr` argument spliced
where the member uses it — evaluated at run time, each time that use is
reached, so an argument not known at build (`t("…")`) is accepted. The
decorator's type parameters take what the annotation bound them to (`T` is
`Signup`, written `Self`). The member reads nothing else of the decorator's
body: the handle and a local that is no literal exist only while the program
compiles (`decorator-member-captures`), and `compiler` inside a member is
`expr-captures-build`. Every parameter is typed (`decorator-member-fn-untyped`),
the member is written at the call (`decorator-member-not-fn`), and a `self` is
the type the member joins and every type parameter it writes is bound
(`decorator-member-type`); a typed function expression is legal in every other
position too (decision 408, § Lambdas and method chains). Every other name a
member of a decorator declared in another module writes resolves where the
decorator wrote it (decision 384): its module's types and functions, a private
helper included, never a same-named declaration of the annotated module — a
type of that name declared there is `import-name-collision` at the annotation.
In the member, `@typeInfo(T)` of the decorator's type parameter reads the
annotated type's typed meta (decision 395): typed in the decorator's body,
answered where the member joins the type, the list written under `comptime`
(`for (comptime @typeInfo(T).metaAll(Check)) { c -> … }`). A method or a field
read on an `expr` parameter (`rule.text()`) is `expr-param-method` (370 (3)).
The other channel is typed meta whose record holds a tree filled from an `expr`
parameter (§ Typed meta below).

A decorator on a function or a method may wrap it (decision 316):
`compiler.wrapWith({ call -> … })`, the wrapper a lambda written at the call. It
receives the call value — `call.args`, the arguments as a tuple, and
`call.run()`, which runs the original body with them — and answers the
function's return type. `expr decl: fn(..) -> R` names a function of any
parameters (`call.args` is then `unknown`; a pattern that lists them types it,
`expr decl: fn(id: i32) -> string` gives `#(i32)`); `fn(..)` is written nowhere
else (`any-params-outside-decl`, at the `..`). Several wrappers compose in
annotation order, the first written outermost. The function keeps its name,
signature and annotations: every call of it, an importer's included, runs the
wrapper, and its original body is reachable only through `call.run()`. The
wrapper is a tree, as a member function is: it reads the decorator's `expr`
parameters, spliced, its `comptime` parameters as literals, and the names of
the decorator's module, never the handle or a local that is no literal
(`decorator-member-captures`), nor `compiler` (`expr-captures-build`).

<!-- example: modules/decorator_wraps_function -->

A call written in the wrapped function's own module, the function taken as a
value and called later, and its own recursive call each run the wrapper.

<!-- example: modules/decorator_wraps_function_value -->

<!-- example: modules/decorator_wrap_captures -->

A wrapper answering another type than the pattern's `R` is
`decorator-wrap-type` at the wrapper, in the decorator; `compiler.wrapWith` from a
decorator on anything but a function or a method of a `type`, or on a
`declare fn` (it has no body to wrap), is
`decorator-wrap-without-function` at the annotation; a wrapper that is no
lambda written at the call is `decorator-wrap-not-lambda`, at the argument
(question B-11-a), and a wrapped function (or the type owning a wrapped
method) with type parameters `decorator-wrap-generic`, at the annotation
(question B-11-b).

<!-- example: modules/decorator_wrap_wrong_return -->

<!-- example: modules/decorator_wrap_outside_function -->

<!-- example: modules/decorator_wrap_not_lambda -->

<!-- example: modules/decorator_wrap_generic -->

<!-- example: modules/decorator_wrap_declare_fn -->

<!-- example: modules/decorator_wrap_generic_owner -->

<!-- example: modules/decorator_any_params_outside_decl -->

A decorator compiles run-time code beside the annotated declaration with
`compiler.compile(executor)` (decision 575 (3)): the executor, a function of
no parameter written at the call (`compiler.compile({ -> register(name) })`)
or named there, runs once before `main`, in the program's init list —
modules in dependency order, declarations in source order, the calls in the
order the bodies make them; a declaration takes any number. The executor is
checked against `fn()` (decision 409): a tail that answers a value is refused
at it, a named executor that answers one at its name. The executor is a tree (575 (4)): run-time code whose names
resolve where the decorator wrote it — a private helper of the decorator's
module included, a library's too —, each `expr` parameter spliced as the
expression written, each `comptime` parameter and each `val` of the body
spliced as the literal of its value. A library module's executors run in the
program that imports it, before the program's own.

<!-- example: modules/compile_executor_before_main -->

<!-- example: modules/compile_init_order_modules -->

<!-- example: modules/compile_executor_from_library -->

An executor is a statement of its module's body at the annotated
declaration's position (decision 580): a module's `val`s, `var`s, `_`
statements and executors run in one order, source order, so a `val` written
below an annotated declaration reads what that declaration's executor did.

<!-- example: modules/compile_executor_module_val_order -->

Inside the executor the decorator's `expr decl` handle is the annotated
declaration itself as a run-time value, with its declared type (decision 581
(2)): `add(Module(name: name, lifecycle: lifecycle, make: decl))` is checked
against `make`'s type for each annotated declaration, and a declaration whose
type does not fit is refused at its annotation, the decorator's
`compiler.compile` call its `called from` line (decision 567).

<!-- example: modules/compile_executor_handle_typed -->

<!-- example: modules/compile_executor_handle_mistyped -->

`compiler` inside the executor is `expr-captures-build`, at the keyword, and
`compiler.compile` in a function that is no decorator
`compiler-output-outside-decorator`, at the member.

<!-- example: modules/compile_executor_captures_build -->

<!-- example: modules/compile_executor_answers -->

<!-- example: modules/compile_executor_named_answers -->

<!-- example: modules/compile_output_outside_decorator -->

### Typed meta (decision 298)

A decorator's meta is a typed value keyed by its record type, never by the
decorator's name: `compiler.setMeta(Entity(table: table))` records one
`Entity` on the declaration, `compiler.addMeta(Index(column: c))` one more
`Index` each time. A reader names the type — `@typeInfo(City).meta(Entity)` is
an `?Entity` (`null` when nothing recorded one), `@typeInfo(City).metaAll(Index)`
an `Index[]`, `compiler.meta<Entity>(d)` and `compiler.metaAll<Index>(d)` the
same on a declaration handle —, so a renamed decorator changes no reader, two
decorators may write one type, and who may read is who sees the type. The values are built at
build time and written back as their constructors where they are read: each
field is a string, an integer, a float, a `bool`, a variant of an enum without
payloads, a `Type.Field<T>`, an array, an optional or a tuple of those
(`decorator-meta-field-type`; a record field is not rebuilt yet), and
the value is the record's constructor written at the call
(`decorator-meta-not-record`), in the decorator's own body.

<!-- example: modules/meta_typed_records -->

A tuple is rebuilt as written (`#(1, 9)`) and a `Type.Field<T>` as its key
(`.pages`): a generic meta record whose one parameter types the key
(`Sort<T>(by: Type.Field<T>)`) is read with that parameter the annotated
declaration (`Sort<Book>(by: .pages)`, decision 308).

<!-- example: modules/meta_field_tuple_and_field_key -->

A type is recorded once per declaration with `compiler.setMeta` — a second value of it,
or one added with `compiler.addMeta` beside it, is `decorator-meta-twice` at the
annotation that recorded it —, and `meta(T)` over several values is
`typeinfo-meta-several` (read them with `metaAll(T)`). Meta describes a
top-level declaration (`decorator-meta-on-member` from a field's or a method's
decorator).

<!-- example: modules/meta_twice -->

A meta record's field is written plain (`message: string`, `rule: fn(v: T) ->
bool`); filled from an `expr` parameter it holds the tree (decisions 370 (1),
576 (12)): the decorator hands one of its `expr x: T` parameters on as it is, and
the value is built in the reading program with the expression spliced where the
annotation wrote it — a rule is called, a message evaluated, at run time, never
while the program compiles; filled from a `comptime` parameter it holds the
literal. The expressions resolve their names where the annotation wrote them,
wherever the value is read (decision 385): a private rule of the annotation's
module is reached, a same-named function of the reader is not.

<!-- example: modules/meta_expr_rule -->

`@typeInfo` is the one reflection builtin (decision 248): `.name` reads a
declaration, `.meta(T)` / `.metaAll(T)` its
typed meta (§ Typed meta), the static `@TypeInfo.all(…)` of
its type the program (decision 253; `@typeInfo.all` is `typeinfo-all-on-function`),
and `@typeInfo(T)` used as a value is a `TypeInfo<T>` (decision 253; its members
other than `name` and `meta` are `typeinfo-unknown-member` until they are answered). In a body that runs at build, `compiler.typeInfo(T)` reads the same. The lowercase
`@typeinfo` is `typeinfo-lowercase`, naming `@typeInfo`.

<!-- example: modules/typeinfo_lowercase -->

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
`compiler.catalogue(with: d, member: …)` is the same query spelled through
`compiler`.
A template function's body may read the catalogue too (decision 353): there,
`@TypeInfo.all(with: d)` answers for the program that expands the call — every
module's declarations carrying `d`, every module's decorators applied —, not for
the library that declares the template, so a library's `pub default fn` finds
the application's `#[theme]`. Such a module is no reader (it may be imported); a
query written in a function the template only calls still makes its module one.
A program that declares no `#[theme]` hands such a template an empty catalogue,
and the template's own refusal is located at the literal it expands:

<!-- example: modules/template_catalogue_no_theme -->

The catalogue's rules hold, refused at the expansion; an entry's `name`,
`module`, `meta` and `returnTypeName` are answered. Its `value` is the
declaration's value at build only for a `val` whose initializer is `comptime`
(decision 356): the value the program computed while it compiled, lifted into
the template's module as a literal — a string, a number, a `bool`, `null`, or
an array or a tuple of those (a record's or a variant's build value is not
lifted yet). A body that reads `value` is refused at an expansion whose answer
holds any other entry (`typeinfo-all-template-value`) — at the read when the
template is the expanding module's own, else at the expansion, naming the read.

<!-- example: modules/template_reads_val_build_value -->

<!-- example: modules/template_val_value_not_comptime -->

An import of a reader's default function
(`import pkg from "pkg"`) is `typeinfo-all-imported` at the handle.
`with:` may list several decorators (decision 235):
`@TypeInfo.all(with: [service, repository], member: "make")` answers every
declaration carrying any of them in the same one order, a declaration carrying
two of them once, its `meta` what the listed decorators set; a decorator listed
twice is `typeinfo-all-arguments`.

<!-- example: modules/typeinfo_all_with_decorator -->

**A decorator names the behavior its declarations implement** (decision 564).
`pub fn module(expr decl: Module) { … }`, `Module` a `behavior`:
`#[module]` on a type that does not `implement Module` is refused at the
annotation, naming the type and the behavior (`` `#[module]` needs a type
implementing `Module` — `City` does not ``). `@TypeInfo.all(with: module)`
answers `Declared<Module>[]`, with no `member:`; a query over several
decorators answers the behavior they all name, and `Declared<unknown>[]` when
they name different ones; a decorator whose first parameter names no behavior answers
`Declared<unknown>[]` as above (`member:` still names a type's associated fn
there). The annotation is the opt-in: implementing a behavior catalogues no
type by itself. Calling a function of the behavior on an entry's `value`
(`d.value.make()`) is legal only inside a function expanded at its call site
(decision 562, below), where each entry is a concrete type; elsewhere it is
refused at the call.

<!-- example: modules/decorator_decl_behavior_not_implemented -->

<!-- example: modules/typeinfo_all_behavior_typed -->

<!-- example: modules/typeinfo_all_behavior_shared -->

<!-- example: modules/typeinfo_all_behavior_none_shared -->

<!-- example: modules/typeinfo_all_behavior_call_outside_expansion -->

The catalogue's reach is the build, not the program's imports: a declaration
carrying `d` in a dependency — one the package declares, or one a dependency
declares — is an entry of the program's queries though no module of the program
imports it, so declaring a package in `botopink.json` is all a program does for
what that package contributes to be listed, and removing the dependency removes
its entries. The entry's `module` is the dependency's module path,
`<package>/<module>`, ordered with the others by it. A dependency read back from
the code cache answers the entries its analysis recorded, with their meta, as
one analysed again does: the program's catalogue is the union of every
package's.

<!-- example: modules/typeinfo_all_dependency_declarations -->

A package that does not declare `Declared` reads its fields all the same: `d.name`, `d.module` and `d.meta` of an
entry the program hands it answer the field, directly, through a function, inside `map` and inside `for`.

<!-- example: modules/declared_field_read_other_module -->

A library reads the program's catalogue itself through a `comptime` parameter
whose default is a `@TypeInfo.all(…)` query (decision 551): `pub fn
boot(comptime modules: Declared<unknown>[] = @TypeInfo.all(with: m))`,
and a program writes `boot();`. The names the default writes resolve in the
declaring module, and a call that leaves the parameter out is answered for the
program it is compiled in, as the program's own entry point would answer
`@TypeInfo.all(with: m)` there: every module's declarations carrying `m`, every
package's, every module's decorators applied, each `value` the declaration
itself — never read at build; `modules` hands the array on. The query is
resolved when the library is analysed and travels with its package, a package
read back from the code cache included; the calling package is the program's.
The parameter's type is the answer's, `Declared<unknown>[]`, held at the
default. The declaring module is no reader (its importers stay legal); a
`@TypeInfo.all` anywhere else in a library's body still answers for the
library's own build.

<!-- example: modules/typeinfo_all_default_at_caller -->

A call that leaves such a default out is written only in the package's root —
`src/main.bp`, or the root file the manifest's `entry` names (s23-i (d) (1)):
anywhere else it is `typeinfo-all-default-outside-root` at the call, naming the
root. No module imports a root whose call was answered so.

<!-- example: modules/typeinfo_all_default_outside_root -->

The argument is still the caller's to pass: `boot(@TypeInfo.all(with:
other))` and `boot([])` are answered with what they pass, the first a
catalogue the calling module reads as an entry point.

<!-- example: modules/typeinfo_all_default_override -->

#### The hooks a function reaches — `compiler.hooks`

A function's handle lists every function it reaches through hooks and
components (decision 277), so a framework's decorator checks what a page
activates at build — which markers its hooks carry, which contexts it reads —
without the compiler naming any stage, marker or library. `compiler.hooks(decl):
HookNode[]` is the function's own node first, then the node of every function
reachable through its `use`s and calls of `@Component` functions,
breadth-first, each node's edges in body order, each function once; empty for
a type, a field, a method and a `val`. A node holds only what is written in its
`function`:

| Record | Fields |
|---|---|
| `HookNode` | `function: Declared<unknown>`, `uses: HookUse[]`, `calls: HookCall[]`, `async: bool` (decision 375), `stage: Stage` (decision 376) |
| `HookUse` — one `use h(…)` | `hook: ?Declared<unknown>` (`null` over a function value), `annotations: DeclAnnotation[]` (the hook's own), `at: string`, `typeArgs: TypeInfo<unknown>[]` (`use params<BlogParams>()` → `BlogParams`, its fields as the checker spells them), `context: ?Declared<unknown>` (the `val` that declares the type's default of a `use provide(ctx)` / `use context(T)`, decisions 354 (4), 379; `null` for any other hook) |
| `HookCall` — one call of a `@Component` function | `callee: Declared<unknown>`, `at: string` |

A call a template builds from a tag counts as written. `at` is
`"<module>:<line>:<column>"`, the entry module `main`. A cycle is an edge back
to a listed node; a host function (`declare fn`, an implemented one) and std's
`provide` / `context` get no node. Each node is recorded once, when its
function's body is checked, and an importer reads the nodes of the functions
it reaches in another module. A node is `async` when its body writes `await`
or `async { … }`; when it `use`s an asynchronous hook or calls an asynchronous
component, written `await` or not; when it calls a host function answering
`@Task` (or `@Component`, which extends it); or when it calls what the checker
cannot follow — a function value answering `@Component<R>`, a `use` with
`hook: null`; a call of a method it resolves (a type's, an enum's, a `default fn`
through the adopting type's `implement`) follows that method's own mark. A cycle is asynchronous when any node in it is; every
other node is synchronous (a page may then be rendered without streaming), and
commonJS emits a synchronous component as a plain `function`. In a decorator body a `Declared`'s `value` is
`null` (no function of the program runs while it compiles) and its `meta` is
every entry its declaration's decorators set, keyed `<decorator>.<key>`. A
`DeclAnnotation`'s `decorator` is the `Decorator` its name names — an alias
(`#[srv]` after `import {serverOnly as srv}`) and a namespace give the
declaration, never the spelling.

**Every function's stage** (decision 376). `HookNode.stage` is `Stage.Build`,
`Stage.Run` or `Stage.Any` — every top-level function has one, whether or not
it is a component. A function is `Build` when it reads what exists only while
the program compiles — an `expr` parameter, or a `comptime` parameter
read at build, of a function that also takes a run-time parameter (one whose
every parameter is `comptime` is expanded at its call site instead, below) —
and `Run` when it calls a host function, std's included,
that is not declared `#[@Stage.Any]` (std's `math` is: a pure primitive);
anything else — arithmetic, strings, records, arrays, `case`, loops, a method,
std's `provide` / `context` — is `Any`. A call gives the caller the callee's
stage (`Any` with `Build` is `Build`, `Any` with `Run` is `Run`), across
modules as each published its functions; a decorator's or a template's body is
`Build`. A function reaching both is `build-and-run` at the second, naming the
first. A `comptime` in a body is computed at build into a constant and gives the
function nothing, so `val names = comptime campos("title,body");` beside a
clock read is a `Run` function.

<!-- example: modules/stage_of_functions -->

<!-- example: modules/stage_build_and_run -->

<!-- example: modules/stage_imported -->

<!-- example: modules/stage_comptime_block_in_run -->

**A function expanded at its call site** (decision 562). A function whose
every parameter is `comptime` and whose body reads a `comptime` parameter's value has no
run-time body: each call is replaced by the code its body emits, written where
the call is — for `boot()` in `main`, in `main`. Its loops over a `comptime`
value, its conditions, its `val`s and its calls answered from build data alone
(a `Declared`'s `name`, `module` and `meta`, a literal, another `comptime`
value, a constant `val` of the module, std's functions over them) run at build,
and `compiler.fail(…, at: x)` reports there, at the argument. Each statement that reaches a
run-time value — a `Declared`'s `value`, a host call, a `Stage.Run` function, a
local the expansion emitted — is emitted, in order, once per iteration of the
loop that holds it, its build-known parts written into it as constants:
`say("starting " + d.name); start(d.value);` over three modules emits three
pairs of calls, in the modules' order. Nothing iterates the catalogue when the
program runs, and no entry's `value` is called at build. Reading a `comptime` parameter's value
gives such a function no stage of its own (it amends 376 (1)); its stage is
what the rest of its body reaches.

<!-- example: modules/comptime_expand_boot -->

<!-- example: modules/comptime_expand_banner -->

A constant of the module — a `val` whose value reads no run-time variable — is
build data: it decides a condition and is written into what is emitted.

<!-- example: modules/comptime_expand_constant_at_build -->

A loop's bound or a condition that needs a run-time value is refused at it,
`run-in-build`, naming the value: `if (d.value is fn() -> string)` is decided
at build, where `d.value` is not.

<!-- example: modules/comptime_expand_condition_run_time -->

Such a function meets `comptime` values and constants alone: each argument is
known at build, and a run-time variable passed — a field of one included — is
`comptime-arg-not-known` at the variable (417). A function that also declares
a run-time parameter is never expanded: its `comptime` parameters are its
specialisation, reading one's value keeps it `Build`, and reaching a
run-time value from it is `build-and-run` (`stage_build_and_run` above).

<!-- example: modules/comptime_expand_runtime_argument -->

The code a function of another module emits resolves every name as in the
module that wrote it: its types (a private one too), its functions and values
(private ones too — the module shares its privates) and its namespace imports
(`path` of `import {path} from "std"`) are reached under aliases no source
writes, though the caller imports none of them. A type of the same name the
caller holds from elsewhere is `import-name-collision` at the call: one module
holds one type of a name.

<!-- example: modules/comptime_expand_library_names -->

A refusal of that code is located in the declaring module, where the refused
code is written, and the call it was expanded at is its `called from` line:
`shout(7)` writes `count.toUpper()` over an `i32`.

<!-- example: modules/comptime_expand_library_type_error -->

**A decorator that reads `compiler.hooks` runs last** (decision 372, provisional). A
module's decorators run in two phases: first every decorator that reads no
hooks — the ones that add members and associated types —, then the module's
bodies are checked with every member and type already there, then each
decorator that reads `compiler.hooks` (in its body or a function it reaches) runs over
them. So a page may call a member another decorator of its module adds
(`Account(…).validate()` above `#[check(…)] pub type Account`). Such a
decorator records meta or refuses, nothing else: `@emit`, `compiler.addMember` (a
source or a typed `fn…`) and `compiler.addType` in it are `decorator-hooks-output`, at the call, whether or not
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

<!-- example: modules/decl_hooks_graph -->

<!-- example: modules/decorator_same_refuses_mark -->

A decorator that reads `.hooks` records its meta after its module's bodies, so the page's
meta is read from another module. A component the importing module lowers is lowered against
the checked types of the module that wrote it: the calls on literals in its body (`5.toString()`,
`[1, 2].map(Card)`) resolve there, whether or not the importer calls it. A component value the
checker cannot follow (a parameter, a method, generic code) is an edge with `callee: null`:

<!-- example: modules/decl_hooks_dynamic_call -->

<!-- example: modules/array_map_component_imported -->

### Template annotations (decision 311)

The template call `` f @`…` `` may be written as an annotation, `` #[f @`…`] ``,
alone or in a `#[a, b]` list. `f` is a template function
whose first parameter is the literal, `expr q: string`, and whose second
receives the annotated declaration, `expr decl: unknown` (question `s29-a`).
Such a function is written only as an annotation; a template for a call site
declares no `expr decl`:

- the text is captured unevaluated, as at a call site: `compiler.text(q)`,
  `compiler.lookup(q, name)`;
- code the body builds from the text resolves in the annotated declaration's
  scope — on a function or a method its parameters, by name and type (a
  method's `self` is `Self`) —, every other name in the module's scope, its
  imports included (decision 112);
- what the body records goes where a decorator's does (decision 216): typed
  meta (decision 298), a member, an associated type;
- the value it returns is not used: an annotation has no call site to splice
  it into. `compiler.fail(m, at: q)` / `compiler.fail(m, at: decl)` refuse the
  declaration at the annotation.

Refused at the annotation: a name that is not a template function
(`template-annotation-not-template`), a template that takes no `expr decl`
(`template-annotation-without-decl`) and any other form naming a template
function — `#[f(…)]`, `#[f]`, `#[f "…"]` — (`expr-call-outside-expr`,
decision 577 (3)); a call `` f @`…` `` of a template that takes an `expr decl`
is `template-annotation-only` at the call.

**A method's typed meta, read by its owner's decorator** (question `s29-b`).
A method's decorators — a template annotation and a `#[d(…)]` alike — run
before its owner's, and the typed meta they record (`compiler.setMeta(v)`,
`compiler.addMeta(v)`) is read by the owner's decorator on a
`compiler.methods(decl)` entry: `compiler.meta<T>(m)` is a `?T`,
`compiler.metaAll<T>(m)` a `T[]`, `T` the record written by its declared name.
A field's decorator still records no meta (`decorator-meta-on-member`).

<!-- example: modules/template_annotation -->

#### A tag is a handle (decision 302)

A template function hands each annotated tag of its text to the annotation as
a declaration handle — the same function shape as a declaration's decorator,
named by no library. `compiler.tagDecl(kind, name, attrs)` builds the tag's
handle: `kind` `DeclKind.Element` (a native tag, `<div>`) or
`DeclKind.Component` (a component tag, `<Card>`), `name` the tag's name,
`attrs` its static attributes in written order. `compiler.annotate(d, at:
span)` runs the annotation written at the span `span` of the text — `name` or
`name(args)` — over it (question B-15-a): the name resolves in the caller's
scope to a decorator, its arguments are checked there, and the answer is the
handle with what the annotation recorded. In the annotation,
`compiler.attr(decl, name)` is a static attribute as written (`null` when the
tag has none, and on every declaration) and `compiler.component(decl)` the
component's own handle (`null` on an element). Typed meta is the one channel:
the template body reads it back by type, `compiler.meta<T>(d)` (`?T`) and
`compiler.metaAll<T>(d)` (`T[]`), so one annotation function serves a tag and a
declaration alike.

<!-- example: modules/tag_decl_meta -->
<!-- example: modules/tag_decl_meta_read -->

Refused at the annotation, in the caller's text: `compiler.addMember`,
`compiler.addType` and `@emit`
(`tag-annotation-output`); a second `compiler.setMeta` of one type on the tag (`decorator-meta-twice`); a name the
caller's scope does not declare, and one that names no decorator. Inside an
annotation `compiler.meta<T>(decl)` is refused (question B-15-c): meta is read
by the code that consumes it, after every annotation ran, so annotations do not
depend on their written order.

<!-- example: modules/tag_annotation_add_member -->
<!-- example: modules/tag_annotation_add_type -->
<!-- example: modules/tag_annotation_emit -->
<!-- example: modules/tag_annotation_meta_twice -->
<!-- example: modules/tag_annotation_unknown_name -->
<!-- example: modules/tag_annotation_not_decorator -->
<!-- example: modules/tag_annotation_reads_meta -->

A program's own `type` may take the name of a builtin enum's variant —
`DeclKind.Element`, `DeclKind.Field` — and name itself in its own fields: the
name in a type position is the program's type.

<!-- example: modules/type_named_like_decl_kind -->

#### Host functions at compile time (decision 341)

A body that runs at build — a decorator's, a template's, a `comptime` — may
call a host function: it travels into the comptime module. Comptime runs on
one runtime, wasm (wasmtime inside the compiler, the page's engine in the
browser build), whatever the build's target (decisions 434, 543): a compile
starts no `erl`. A host function reached there
answers by the first of two cells it has: its std-wasm implementation
(std's own host functions, written in Zig and compiled to wasm — the
function its `.Wasm(std: "<module>.<function>")` cell names, below),
or the botopink function its `.Wasm(body: …)` binding names (an `op:`
or `wasi:` binding does not run there, but `wasi: .Attempt`, which runs as
`attempt` answers in a wasm program). A std function is served by std-wasm
only where its `std:` cell says so; there is no match by name.
`.Node` never serves: there is no Node at compile time. An
`.Erlang` cell never runs at build either (decision 452): it binds
the erlang and beam targets alone, and beam-to-wasm — a standalone utility
that translates any `.beam` set to wasm — is no part of the compiler.
std's functions travel too, through a namespace or a leaf import —
`comptime hash.contentHash("hello")` is `"f923099"` on the four targets, one
answer whatever the target.

What a decorator may call is decided when its package is compiled, never at a
consumer's build, and whatever the package's `targets` (decisions 434, 452): a
host function it reaches — in its body, in a function of its module, through a
std or an imported function — needs one of the two cells the comptime runtime
answers by: its `std:` cell (std-wasm) or its `.Wasm(body: …)` cell.
Neither is refused at the call (`comptime-host-cell-unavailable`), naming the
function and both cells; an `.Erlang` cell beside them is ignored,
never tried.

<!-- example: modules/decorator_host_cells -->

<!-- example: modules/comptime_host_cell_unavailable -->
<!-- example: modules/comptime_host_cell_unavailable_erlang_only -->
<!-- example: modules/comptime_expression_erlang_cell_never_runs -->

Each invocation is independent (decision 343): a decorator's answer depends
on the declaration it annotates alone, so a body writing a module-level `var`
— directly or through a function of its module — is refused at the write
(`decorator-writes-module-var`). A catalogue, and a duplicate across
declarations, is read at the entry point with `@TypeInfo.all(with: …)` and
refused there, at compile time, naming both declarations.

### Host bindings

A bodyless `declare fn` — top-level or a type's, static included — names the
code each target runs in its place with `#[@external(…)]` (decision 575 (6)):
one std function, `external(expr decl: unknown, comptime ..sources:
Implementation[])`, whose sources are values of std's enum `Implementation` —
`Erlang(template, body, inline, result)`, `Node(template, body, result)`,
`Typescript(template, result)` and `Wasm(template | op | std | wasi | body,
host, needs, result)`:

```
#[@external(.Erlang("lists:member($1, $0)"), .Node("$0.includes($1)"), .Wasm(op: "f64.floor"))]
```

Inside std the annotation is written `#[external(…)]`. A source is checked as
the enum's constructor is: a label its variant does not declare, a value of
another type, a variant the enum does not declare are the constructor's
refusals, at the argument. `external` hands each source to
`compiler.implement`, and the compiler reads a declaration's implementations
alone, one per target:

<!-- example: modules/implementation_twice -->

An implementation takes the place of a body, so one on a declaration with a body
is refused at the annotation; a behavior's `default fn` keeps its body as the
fallback of a target it has no implementation for:

<!-- example: modules/implement_with_body -->

A bodyless `declare fn` no annotation implements has no code on any target: it
is refused at the declaration, before any call — top-level, a type's method or
a type's static function alike:

<!-- example: modules/declare_without_implementation -->

<!-- example: modules/declare_without_implementation_method -->

<!-- example: modules/declare_without_implementation_static -->

A behavior declares a member's signature, or a `default fn` with a body;
`declare fn` inside one is refused at the member:

<!-- example: modules/declare_in_behavior -->

A library writes its own source annotation the way `external` is written: a
decorator that hands `compiler.implement` an `Implementation`:

<!-- example: modules/external_library_source_annotation -->

<!-- example: modules/external_wasm_host_binding -->

A declaration takes the signature a `fn` does — generic parameters, `comptime`
parameters, any return type — with or without an annotation. A parameter it
has no name for is written `_` (`declare fn typeInfo<T>(comptime _: type<T>) ->
TypeInfo<T>;`); `_` is a bodyless declaration's placeholder, and a
function with a body refuses it (`discard-param-with-body`).

A binding may also be a template, where `$0`, `$1`, … are the declared
parameters — on a method, `self` is `$0`:

<!-- example: modules/external_template_binding -->

`$stringify(…)` is no marker of the language: a template is host code, and the conversion is written in the host's own terms. It is refused as `template-stringify-marker`, located at the template (decisions 164, 239).

<!-- example: modules/template_stringify_marker -->

**A host function that operates on a value of one type is a method of that
type.** It is declared inside the type's body with `declare fn`, `self` first,
and called like any other method — `sock.recv(16, 1000)`, never a free
`recv(sock, 16, 1000)`. The binding's `$0` is the receiver and `$1`, `$2`, … the
arguments after it; a template that calls one host function with the
parameters in order (`"erlang:is_list($0)"`) is that call, the receiver first. A host function with no such owner (`listen(port,
backlog)`, `now()`) stays at module level.

<!-- example: modules/external_method_in_type -->

Every backend lowers such a method as a real method of the type whose body is
the binding: a class member on commonJS (an enum's is a static taking `self`,
like every enum method), a function exported by the type's module on erlang and
beam — so a method on an imported type is answered by its owner exactly as a
bodied one is — and a declaration in the `.d.ts`. A method with no binding for
the active backend is refused where it is **called**, naming `Type.method`
(`` `Meter.plus` has no implementation for the wasm backend ``); a bodyless
method with no implementation at all is refused at its declaration.

A source is a value of `Implementation`: a target written another way
(`@external(node, …)`) is no value of it and is refused at the argument.

<!-- example: modules/external_lowercase_target -->

**An implementation's flags are labelled** (decision 487): `result:` on
every variant, `inline:` on `.Erlang`, each a `bool` read by its label after
the template, as a constructor's labelled arguments are. A bare `true` or
`false` fills the next field the variant declares (`body:`), which a
binding of one cell refuses:

<!-- example: modules/external_flag_bare_bool_refused -->

`inline: true` on `.Erlang` opts the declaration out of the dispatch
table so the backend's hand-coded shape keeps emitting. That variant alone
declares it, because the erlang and beam emitters, which both read
`.Erlang`, alone read it. Written on `Node`, `Wasm` or `Typescript`, or
with a value that is not a bool, it would be a switch nothing reads, so it is
refused at the argument (`` `Implementation.Node` has no parameter named `inline` ``).

<!-- example: modules/external_inline_unread -->

A host call that can fail answers a `@Result` only when its binding writes
`result: true`: the return is then `@Result<T, HostError>` (or a `@Task` of
one), and every way the host fails becomes `Error(HostError(…))`. Without the
flag the binding promises no failure. `effect-try-without-fallible-channel`
names this flag and `try … catch` as the ways out of a `throw` or `try` that
has no `@Result` channel.

The flag has one reading, so the checker holds it to it, at the annotation
(decisions 487, 488, 490, 491):

- `result: true` needs the return `@Result<…, HostError>` or
  `@Task<@Result<…, HostError>>` — a plain value, or a `@Task<T>` that has no
  `@Result` inside it, is refused:

<!-- example: modules/external_result_return -->

<!-- example: modules/external_result_task_plain_value -->

- its `HostError` is std's `failure.HostError`, by module identity: a type the
  module declares under the same name is refused, naming std's:

<!-- example: modules/external_result_own_host_error -->

- `result:` is a `bool`; any other value is refused:

<!-- example: modules/external_result_not_bool -->

- `result:` belongs to a host call that can fail: beside a `body:` cell (a
  botopink function, which fails only through its own `@Result`) or an `op:`
  cell (a wasm instruction) it is refused:

<!-- example: modules/external_result_on_fn_cell -->

<!-- example: modules/external_result_on_wasm_op_cell -->

Accepted, std's `HostError` is named as a leaf or through its module, and the
flag stands anywhere among the arguments, beside `inline:`:

<!-- example: modules/external_result_return_accepted -->

std's `failure` module declares the types (decisions 489, 492):
`HostErrorName` (`Error`, `Throw`, `Exit`), `HostError(message, kind, name,
detail)` with `detail: ?string`, and `Failure(message, kind)`, whose `kind` is
`"panic"`, `"host"` or `"crash"`:

<!-- example: modules/std_failure_types -->

`HostError(message, kind, name, detail)`: `kind` is always `"host"`; `name` is
the same on every target — a JavaScript `Error` and an erlang `error` raise, or an
erlang host answering `{error, R}`, are `HostErrorName.Error`, any other thrown
value and an erlang `throw` are `HostErrorName.Throw`, an erlang `exit` is
`HostErrorName.Exit`; `message` is the host's text (`e.message`, else
`String(e)`; the erlang reason by `~tp`); `detail` is the host's stack, which a
backend may leave empty. An erlang host's `{ok, V}` or plain value is `Ok(V)`.

<!-- example: modules/external_result_host_error -->

An erlang host names the class of each raise, and `exit` is the erlang host's
alone:

<!-- example: modules/external_result_erlang_exit -->

A host function declared as a method of its type answers the same way, a
`@Task` method's failure read back as `Error(HostError(…))` at its `await`:

<!-- example: modules/external_result_host_method -->

**std maps its own host failures** (decisions 431, 486). A std function whose host call can fail answers
`@Result<T, E>`, never a `string`. Where std maps the host's raise — `encoding`, `io.clock`, `io.fs` — the
binding stays private, writes `result: true`, and the public function maps the `HostError` into the
module's own error enum (`EncodingError`, `ClockError`, `FsError`), so the same input is the same variant
on every target; `json`, `regex` and `io.process` answer std's `HostError` itself, its `kind` `"host"`.

<!-- example: modules/std_host_error_variants -->

One annotation binds the BEAM: `.Erlang` serves the erlang and the beam
targets, the same VM and the same OTP calls (decision 437). `.Beam` is
gone; writing it is a located error at the annotation naming the form in force,
never an alias.

<!-- example: modules/external_beam_removed -->

A relative path (`"./helpers.mjs"`, `"helpers"` on erlang) names a **sidecar** the
library keeps beside its sources, in `<src>/sidecars/` or `<src>/`. `botopink
build` and `botopink test` copy it next to the emitted module, from the
directory the dependency resolved to — so it ships the same whether the library
is a workspace member, a `{ "path": … }` package outside every library root, or
one of two checkouts declaring the name. A sidecar the build cannot ship is a
located error on the `dependencies` entry that named the library, never a
silent exit 0. See *The manifest schema* § Host sidecars.

**A host that answers a record may build it either way.** A value knows its own
type (§ *A value knows its own type*), and a host is the one writer the compiler
does not own — a `.erl` sidecar shipped by a library, a template written before
the rule existed. So the boundary accepts both shapes and the declared return
type decides which record the answer becomes: a plain object or map is adopted
into the record the declaration names, field by declared name, and an answer
that already carries its type is left exactly as it is. The same holds one
container deep — `?T`, `T[]`, `@Result<T, E>` and `@Task<T>` are looked
through — and no deeper.

<!-- example: modules/external_returns_record -->

A field the host leaves out is the absent value, not an error — a host is not
asked to fill a record it does not know about.

**A host that answers later** is declared with a `@Task` return (decision 126).
With `result: true` and `-> @Task<@Result<T, HostError>>`, a rejected Promise
(Node) or a raise or `{error, R}` (Erlang) becomes `Error(HostError(…))`;
declared `-> @Task<T>`, a rejection is a fatal host failure — that form is for a
host that guarantees it does not fail.

<!-- example: modules/host_node_task_result -->

**Calling a host binding on a target it does not name is refused where the call
is written, on every backend:**

```
error: `listToBinary` has no `#[@external(.<Target>(…))]` for the wasm backend
  --> src/main.bp:21:12
```

| Target | Reads | A call with no binding for it |
|---|---|---|
| `commonJS` | `.Node` | refused at compile time — "for the node backend" |
| `erlang` | `.Erlang` | refused at compile time — "for the erlang backend" |
| `beam` | `.Erlang` (the same vocabulary) | refused at compile time — "for the beam backend" |
| `wasm` | `.Wasm` — the closed vocabulary below | refused at compile time — "for the wasm backend" |

A declaration nothing calls is free on every target; a **call** is refused
wherever it is written, whether or not anything reaches it. A function whose
body is only a host call is an ordinary function and inherits no restriction:
its call is statically present, so a target the declaration does not name
refuses the program even when nothing calls the wrapper. A project that needs
such a wrapper names its `targets`, or the declaration gains the other
target's binding.

**std is refused at the call, never at the import** (decision 518 (4)). Every
std module is importable on every target; a call of a std function that
reaches a host declaration with no binding for the target — the function
itself, or one its body reaches through its module's own functions — is
`std-unsupported-on-target`, located at the call and naming the function (and
the declaration it reaches, when that is another):

<!-- example: modules/std_unsupported_refused_at_the_call -->

wasm has no host of its own, so `.Wasm` does not name a host symbol
or carry target text: it is **one cell from a closed vocabulary of four**
(decisions 238, 440, 481), each a labelled argument holding a value of the
kind it names, read and checked where the annotation is written — on every
target, not only on a wasm build: a misspelt opcode, an opcode or an adapter
whose types differ from the declaration's, or a `body:` naming no private fn is
refused on erlang, beam and commonJS too. The arguments are always the
declared parameters, in order.

<!-- example: modules/external_wasm_op_type_on_every_target -->

<!-- example: modules/external_wasm_adapter_signature_on_every_target -->

| Cell | Binds the declaration to |
|---|---|
| `op: "<opcode>"` | one numeric wasm instruction, its text a string (`op: "f64.floor"`, `op: "i32.add"`, `op: "f64.lt"`, `op: "f64.convert_i32_s"`); the declared parameter and return types must be exactly the instruction's — a comparison or `eqz` answers `bool` |
| `body: <name>` | a botopink identifier, resolved in the module: a private (not `pub`) `fn` of the same module, with a body, taking the same parameter types in the same order and answering the same type — the algorithm stays in the library, in botopink |
| `wasi: .<Adapter>` | an enum value naming a compiler adapter over the host, one of the list below — each has an implementation per host (WASI preview 2 through the `wasi` component, JavaScript in the `browser` loader), so one list serves both (decision 394) |
| `std: "<module>.<function>"` | a string naming a function std-wasm implements (checked against std-wasm's exports, never resolved as botopink) — std's host functions written in Zig (`modules/std-wasm`) —, which the compiler transpiles into the program; the declared parameter and return types must be exactly the function's. The same cell is what the comptime answers by, on every target (decision 440). std's alone: a `std:` cell outside `libs/std` is refused (decision 445, below) |

<!-- example: modules/external_wasm_op_and_fn -->

Each cell holds a value of the kind it names (decision 481): `op:` and `std:` a string, `wasi:` a
`WasiAdapter`, as `Implementation.Wasm` declares them, so a value of another kind is the
constructor's refusal at the argument — `op: floor`, `std: hash.contentHash` (a name no module
binds), `wasi: "RandomF64"` (a string where a `WasiAdapter` goes); `body:` names a private fn by its
identifier, and `body: "tanBody"` is refused naming that form:

<!-- example: modules/external_wasm_fn_cell_string -->
<!-- example: modules/external_wasm_op_cell_not_string -->
<!-- example: modules/external_wasm_wasi_cell_not_enum -->
<!-- example: modules/external_wasm_std_cell_not_string -->

A binding is **one** cell, beside `host:` (and `inline:`): a label outside the four and a second
cell are refused at the argument that writes them. A cell naming what does not exist — an opcode
the table does not hold, an adapter that is none of the list —, and a `body:` whose body takes
other types than the declaration's, are refused at the annotation:

<!-- example: modules/external_wasm_unknown_label -->
<!-- example: modules/external_wasm_two_cells -->
<!-- example: modules/external_wasm_op_unknown -->
<!-- example: modules/external_wasm_wasi_unknown -->
<!-- example: modules/external_wasm_fn_cell_signature -->

The functions a `std:` binding names, and the std declarations that bind them
— what a program calls:

| Function | Signature | Bound by |
|---|---|---|
| `hash.contentHash` | `(string) -> string` | `hash.contentHash` |
| `text.trim`, `text.trimStart`, `text.trimEnd` | `(string) -> string` | `String.trim`, `trimStart`, `trimEnd` |
| `number.floatToString` | `(f64) -> string` | `Float.toString` — and every float a wasm program turns into text: `@print`, `"${x}"`, `"x" + x` |
| `text.length` | `(string) -> i32` | `String.length` (code points) |
| `text.split`, `text.chars`, `text.lines`, `text.words` | `(string, string) -> string[]`, `(string) -> string[]` | `String.split`, `chars`, `lines`, `words` |
| `text.contains`, `text.startsWith`, `text.endsWith` | `(string, string) -> bool` | the `String` methods of those names |
| `text.indexOf`, `text.lastIndexOf` | `(string, string) -> i32` | `String.indexOf`, `lastIndexOf` |
| `text.at`, `text.charCodeAt` | `(string, i32) -> ?string`, `(string, i32) -> i32` | `String.at`, `charCodeAt` |
| `text.padStart`, `text.padEnd`, `text.repeat` | `(string, i32, string) -> string`, `(string, i32) -> string` | `String.padStart`, `padEnd`, `repeat` |
| `text.replace`, `text.replaceAll` | `(string, string, string) -> string` | `String.replace`, `replaceAll` |
| `text.fromCodepoint` | `(i32) -> string` | `String.fromCodepoint` |
| `text.toUpper`, `text.toLower` | `(string) -> string` | `String.toUpper`, `toLower` — over all of Unicode (decision 443) |

A function of the table is std-wasm's Zig, transpiled into the program, or a hand-written `.wat`
leaf of `modules/std-wasm/wat/` (front 164 s3), which the compiler reads with its own reader and
emits into a WasmGC program as one of its functions — `text.length` and `text.charCodeAt` are
leaves. A leaf names the codegen's GC types (`$str`, `$arr_any`, …) and declares none (decision
549); the answer is the same either way:

<!-- example: modules/string_code_points_every_width -->

**A `std:` cell is std's alone** (decision 445). std-wasm's export names are
internal to std, and std's botopink API is the public contract: a `std:` cell
written anywhere outside `libs/std` is refused at the annotation, on every
target, naming the std function to call instead. std's own `hash.contentHash`
carries one; the same declaration in a program is refused:

<!-- example: modules/external_std_binding_refused -->

<!-- example: modules/external_wasm_std_outside_std -->

**A prefixed string is no binding** (decisions 305, 481). The strings the
vocabulary was once written as — `"fn:tanBody"`, `"op:f64.floor"`,
`"wasi:delay"`, `"std:hash.contentHash"` — are refused at the argument, on
every target, naming the labelled cell to write instead; an unlabelled string
is host code, always:

<!-- example: modules/external_prefixed_fn_refused -->

<!-- example: modules/external_erlang_prefixed_fn_refused -->

<!-- example: modules/external_wasm_prefixed_fn_refused -->

<!-- example: modules/external_wasm_prefixed_op_refused -->

<!-- example: modules/external_wasm_prefixed_wasi_refused -->

<!-- example: modules/external_wasm_prefixed_std_refused -->

`op:` and `wasi:` are `.Wasm`'s cells alone: written as a prefixed
string on `.Node` or `.Erlang`, the refusal names the wasm
cell to write (`#[@external(.Wasm(op: "f64.floor"))]`):

<!-- example: modules/external_node_prefixed_op_refused -->

**Case mapping covers all of Unicode** (decision 443) on the four targets —
`"straße".toUpper()` is `"STRASSE"`, `"É".toLower()` is `"é"`. Every target
answers OTP's where a JS engine's differs (decision 521): no final sigma
(`"ΟΔΟΣ".toLower()` is `"οδοσ"`, where a JS engine answers `"οδος"`).

<!-- example: modules/string_lower_final_sigma -->

**Every target writes std-wasm's text** (decisions 441, 521). Where std-wasm's
answer differs from a JS engine's, a program answers std-wasm's on every
target — the text of erlang, beam and the comptime: a float is OTP's
`float_to_binary(F, [short])`, the shortest digits that read back as the same
`f64`, in fixed notation or as `D.DDDeE` when that is shorter, and as
`D.DDDeE` from 2^53 on (`"${5.0}"` and `5.0.toString()` are `5.0`, `1000.0`
is `1.0e3`, `1e21` is `1.0e21`, `0.000001` is `1.0e-6`,
`9007199254740992.0` is `9.007199254740992e15`; `NaN`, `Infinity`,
`-Infinity`, which only a wasm or commonJS program's arithmetic makes, are
those words), and `trim` removes space, tab, LF, CR, VT and FF (a no-break
space stays). A wasm program and its own comptime agree. commonJS writes the
same text through its helpers, never the JS engine's number text, `trim` or
case mapping — a string method reached through `?.`, or after a `?.` link in
the same chain, included.

<!-- example: modules/float_text_and_trim -->

<!-- example: modules/float_text_at_run_time -->

<!-- example: modules/string_trim_keeps_nbsp -->

<!-- example: modules/optional_chain_string_text -->

**A float written as text keeps its decimal part on every target**, commonJS
included (decision 521): in a template hole, through `toString()`, beside a
string in a `+` and through `@print` — an imported record's `f64` field and an
`f64` a generic method answers included, and a record's `f64` field when the
record prints. An `f64` a generic function's body holds as its type parameter
is written the same way, alone, in an array of the type parameter or as a
record's field.

<!-- example: modules/float_text_everywhere -->
<!-- example: modules/generic_float_text -->
<!-- example: modules/generic_float_record_text -->

| Adapter | Signature | Answers |
|---|---|---|
| `.RandomF64` | `() -> f64` | a uniform `f64` in `[0.0, 1.0)` from 53 bits of `random_get` (an errno from the host traps) |
| `.Delay` | `(i32, T) -> @Task<T>` | a task that settles with the value once the milliseconds have passed on the host's monotonic clock (`wasi:clocks/monotonic-clock` and `wasi:io/poll` on `wasi`, `setTimeout` on `browser`); a negative duration is `0` |
| `.Race` | `(Array<@Task<T>>) -> @Task<T>` | the first of the started tasks to settle — the first settled one in input order when some already are; an empty list traps |
| `.RaceOf` | `(Array<fn() -> @Task<T>>) -> @Task<T>` | each thunk called in order (its task runs to its first `await`), then raced; an empty list traps |
| `.SpawnAll` | `(Array<fn() -> @Task<T>>) -> @Task<Array<T>>` | each thunk called in order; the answers in input order once the last has settled |
| `.GateNew` | `() -> unknown` | a closed gate (std's `async` gates): a pending task no host answers |
| `.GateOpen` | `(unknown) -> void` | the gate opened: every task waiting on it answers `true`, and each wait's own timer is dropped first, so an open gate leaves no timer behind; opening an open gate changes nothing |
| `.GateAwait` | `(unknown, i32) -> @Task<bool>` | a task answering `true` once the gate is open (at once when it already is), `false` when the milliseconds pass first on the host's monotonic clock (`.Delay`'s pollable) |
| `.Attempt` | `(fn() -> T) -> @Result<T, string>` | the thunk called inside a `try_table` catching the program's aborts (wasm exception handling): `Ok` of its value, or `Error` of the abort's message — std's `failure.attempt` and `attemptTask` on wasm; the binding declares `needs: [.Exceptions]` |

`std/io/random`'s seeded stream is std-wasm's (decision 451), bound by the
`std:` cells on `seed` and `seededFloat`: Mulberry32 as the commonJS sidecar
draws it, so a seed gives the same draws there, in a wasm program and at
comptime on every target. Before any seed a wasm program's `seededFloat()`
draws the host's entropy (`.RandomF64`'s); at comptime that draw is refused,
located at the call that drew it, in a `comptime` expression or a decorator body
alike (`comptime_random_float_unseeded`, `decorator_random_float_unseeded`) — a
build has no entropy and never pretends to.

An adapter answering `@Task<T>` (decision 393) is declared over one type
parameter and checked by **shape** at the annotation — the signature in the
table, whatever `T` is — and the compiler makes the pending task the host's
pollable backs:

<!-- example: modules/task_starts_when_made -->

<!-- example: modules/external_wasm_task_adapter_shape -->

The task carries its `T` in one word: a task adapter reached with a float or
an `i64` value is refused at the call.

std's `async` is bound on these adapters on both hosts, its gates on the
three over fixed types, and answers as on every other target — its results
and the order of its answers, never the order of effects between concurrent
tasks (decision 335 (2)):

<!-- example: modules/std_async_on_every_target -->

Anything else — another label, a second cell, a value of another kind than
its label names (`body: "tanBody"`, `op: f64`, `wasi: "delay"`), an opcode the
backend does not bind, an opcode
whose type differs from the signature, a `body:` naming no private bodied fn of
the module (or a `pub` one, or one of another signature), an adapter not in
the list, a `std:` naming a function std-wasm does not implement or declared
with other types, a template with `$` markers — is an error at the
annotation; a `std:` one on every target, since the comptime reads it too. No
runtime-helper name of the backend is part of a binding and nothing a binding
writes names an address: there is no raw memory in the vocabulary. A
`declare fn` with no `.Wasm` keeps the refusal above at its call.

**A wasm build binds to the runtime it runs on** (decision 334). The package
names it in `botopink.json`, `"wasm": { "host": "wasi" }` or `"browser"`
(*The manifest schema*); absent, it is `wasi` — wasmtime and the runtimes
that follow WASI preview 2. A binding may name the host it serves with
`host:` — `#[@external(.Wasm(op: "f64.floor", host: .Wasi))]` beside
`#[@external(.Wasm(body: floorBody, host: .Browser))]` —, and one written without
`host:` serves every host. A build reads the binding serving its host and
checks every other one too; a function with no binding for the build's host
is refused at its call as above, and a std function with none is
`std-unsupported-on-target: … for target 'wasm' on host 'wasi'`. `host:` on
another variant and a value other than `.Wasi` or `.Browser` are the
constructor's refusals at the argument; a second binding for one host (a
binding without `host:` beside a hosted one included) is an error at the
annotation.

**A binding declares the host features it needs** (decision 518):
`#[@external(.Wasm(wasi: .Attempt, needs: [.Exceptions]))]`, each a value of
std's closed enum `WasmNeed { Exceptions, Http }`. The compiler gathers the
needs of the bindings a program reaches into the custom section
`botopink.needs` of the module, and the runner hands the host only the
matching flags — wasmtime's `-W exceptions=y` for `Exceptions`, `-S http` for
`Http`; node runs exceptions by default. A program that needs none runs with
no flag, and no annotation of a program turns a feature on or off: `needs` is
no configuration. A binding that forgets its need fails visibly on the host. A
value outside `WasmNeed`, or `needs:` on another variant, is the constructor's
refusal at the argument, on every target:

<!-- example: modules/external_wasm_needs_unknown -->

On the `wasi` host the file `botopink build --target wasm` writes is a **WASI
preview 2 component** in WebAssembly text, which `botopink run` runs with
`wasmtime run` and the flags its needs ask for: the module the backend lowers, unchanged but for its
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
`conformance` runs its wasm column under both and fails a cell whose
answers differ.

**A private fn binds a declaration on every target** (decisions 238, 263, 305). On
`.Node` and `.Erlang` (which the beam target reads) the
labelled cell `body: <name>` (`#[@external(.Erlang(body: powBody))]`) binds what
wasm's `body: <name>` cell binds — a private `fn` of the same module, with a body, taking the same
parameter types in the same order and answering the same type — and it is
checked the same way, at the annotation. One algorithm written in botopink then
answers the same bits on every target, instead of each host's own library
(`std/math`'s `sin`, `pow`, … run std's bodies on erlang and beam, and `pow` on
commonJS too).

<!-- example: modules/external_fn_body_every_target -->

`<name>` is a botopink identifier, resolved in the module like any other name:
a misspelt one is the ordinary unbound-name error, at the argument, and
renaming the function renames the binding.

<!-- example: modules/external_fn_unbound -->

Until 2026-09-21 wasm lowered such a call to a `wasm trap`, so the program
compiled and then died at run time where the other three refused it; it
refuses too, and there is no flag that restores the trap.

## Builtins

<!-- example: modules/builtin_print_todo -->

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
| `@module` | `module() -> module` | refused at every call (`builtin-not-lowered`) |
| `@embed` | `embed(comptime path: string) -> Asset` — a `Build` builtin, computed where it is written (§ `@embed` and `Asset`) | its own rule (`embed-arguments`, `comptime-arg-not-known`, `embed-path-absolute`, `embed-path-outside-package`, `embed-file-missing`) |
| `@field` | `field<T, F>(obj: T, comptime name: string) -> F` — COMPTIME-ONLY name | the declaration |
| `@src` | `src() -> SourceLocation` — COMPTIME-ONLY (§ `@src()` and `SourceLocation`) | its own rule (`src-takes-no-arguments`) |
| `@typeInfo` | `typeInfo<T>(comptime t: type<T>) -> TypeInfo<T>` — COMPTIME-ONLY (§ Decorators) | its own rule (`typeinfo-unknown-declaration`, `typeinfo-unknown-member`) |
| `@TypeInfo.all` | `all(with: Decorator \| Decorator[], member: ?string = null) -> Declared<unknown>[]` (`Declared<B>[]` when the decorators' `@Decl<B>` share the behavior `B`, decision 564), a static `declare fn` of `TypeInfo<T>` — COMPTIME-ONLY | the declaration — `Decorator` is the type of a decorator's name (decision 268), so anything else in `with:` is the ordinary mismatch at the argument —, after its own shape rule (`typeinfo-all-arguments`) |
| `@TypeOf` | `TypeOf<T>(value: T) -> T` — COMPTIME-ONLY | the declaration |
| `@makeRecord` | `makeRecord<R>(fields: RecordField[]) -> R` — COMPTIME-ONLY | the declaration |
| `@RecordKeys` | `RecordKeys(comptime _: type<T>) -> string[]` — COMPTIME-ONLY | the declaration |
| `@comptimeError` | `comptimeError(comptime message: string) -> noreturn` — COMPTIME-ONLY | its own rule (the message it raises) |
| `@emit` | `emit(source: string)` — COMPTIME-ONLY, a decorator body | the declaration |
| `@compilerError` | `compilerError(message: string) -> noreturn` — COMPTIME-ONLY, a decorator or template body | the declaration |
| `@code` | `code<T>(text: string)` — COMPTIME-ONLY, a template body, answering the code `text` parses | the declaration |

A call the declaration refuses — more arguments than it declares, a parameter
without a default left out, a label naming no parameter — is
`error[builtin-arguments]` at the call, naming the declaration; an argument of
another type is the ordinary type mismatch, at the argument.

<!-- example: modules/builtin_arguments -->

Builtin names are exact: an unrecognised `@name(…)` is `error[unknown-builtin]`
(with the nearest name when one is an edit away), never a silent `void`. `is`
is only an operator (decision 322): `x is T` tests a type, and a hand-written
`@is(…)` is `error[unknown-builtin]` naming the operator.

`Decorator` (declared in `builtins.d.bp`, decision 268) is the type of a
decorator's name: a name has it when it names a function whose first parameter
is `expr` and which has a body — further arguments included —, and
an array literal of such names is a `Decorator[]`. Nothing else is assignable to
it, and it cannot be constructed: `@TypeInfo.all(with: 42)` and
`@TypeInfo.all(with: someOrdinaryFn)` are the ordinary type mismatch, at the
argument.

A decorator parameter typed `Decorator` (`comptime marker: Decorator`)
takes a decorator's name, and one typed `Decorator[]` an array literal of
names; the body reads each as the declaration's identity and compares it with
`same` (decision 371):

<!-- example: modules/decorator_argument_decorator_name -->

The name is resolved where it is written: through the namespace of the module
that declares the decorator (`markers.email`, a `mod` child's namespace read in
an annotation as in a body) and under an import's alias, it is the same
declaration's identity:

<!-- example: modules/decorator_argument_decorator_alias -->

`@panic`, `@todo` and `@trap` never return: they are declared `-> noreturn`, the
bottom type, so a call to one stands wherever a value of any type is expected —
`val x: i32 = @todo();`, `return @panic("…");`, one branch of an `if` whose other
branch has the value. `@module()` is declared but no target lowers it, so it is
`error[builtin-not-lowered]`.

A `@panic(message)` aborts the program with a non-zero status, and its message —
the text it was given, quotes and non-ASCII characters included — reaches stderr
unchanged on every target; what the runtime writes around it (a stack trace, a
trap notice) is the runtime's own. An abort writes to stderr alone — a checked
integer operator's abort as `@panic`'s —, so what the program printed before it
is its whole stdout, on every target:

<!-- example: modules/panic_library_message -->
<!-- example: modules/int_overflow_add_i32 -->

What an uncaught abort writes is the `Failure` an `attempt` would have answered
(decisions 535, 527), one line, `<kind>: <message>`, on every target: `panic: <message>` for
`@panic`, `@todo`, a failed `assert`, an overflow or a division by zero, `host: <message>` for a raise of a
host binding without `result: true`, `crash: <reason>` for any raise nothing marked — a `case` no arm
matches, `badarith`. Never the runtime's raw `Class:Reason` term. A target that does not abort where
another does (a float division by zero: commonJS and wasm answer `Infinity`) declares that departure; the
text of an abort is not one:

<!-- example: modules/abort_text_host -->
<!-- example: modules/abort_text_panic -->
<!-- example: modules/abort_text_overflow -->

A raise nothing marked is `crash` on commonJS too: a binding declared outside std without `result: true` has its
raise marked `host` (546), so the raise of the program's own code — a method called on a value the binding
mistyped — is not:

<!-- example: modules/abort_text_crash -->
<!-- example: modules/case_no_arm_matches_raises -->

### What `@print` writes

A value prints the way the source writes it. A record names its type and its
fields, a variant names its enum, a container separates its elements with
`", "`, and a type implementing `Display` prints its `display()` instead —
nested inside a container too.

<!-- example: modules/print_value_text -->

`@println` writes as `@print` does — its arguments separated by a space, its line ended — on
every target:

<!-- example: modules/println_every_target -->

A field's name changes nothing: a record with a field called `tag` is a record,
printed by its type's name and its fields:

<!-- example: modules/record_field_named_tag -->

A variant with a payload prints as `Enum.Variant(…)` however it reaches
`@print` — built in place, bound by a `val`, in an array, its enum declared in
the module or imported:

<!-- example: modules/enum_payload_value_prints -->

A value of a generic declaration prints each field as the value it holds,
whatever the type argument — a field written as the type parameter or an array of
it, in a record or a variant, built directly or by a generic function:

<!-- example: modules/generic_record_prints_its_arguments -->

A `@Result` prints the way the source writes it — `Ok(81)`, `Error("bad")` — at
the top level and nested in a container or a record, its payload printed as any
nested value is (a string quoted):

<!-- example: modules/print_result -->

A string prints as its text at the top level (`hi`) and quoted inside a
container (`["hi"]`). erlang, BEAM, commonJS and wasm all write the record and
variant text; `Display` is consulted on the first three, and wasm prints the
record's own fields instead.

### A value knows its own type

Two declarations with the same fields are two types, and their values are never
equal:

<!-- example: test/type_identity.bp -->

The declaration is inside the value on every backend: erlang and BEAM tag the
term with the module the type is declared in, commonJS makes it a class.

`is` and a `case` arm read it back — the arm is chosen by the value's own type,
not by the annotation it arrived under:

<!-- example: test/type_identity_case.bp -->

### `@src()` and `SourceLocation`

<!-- example: modules/src_location -->

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

### `@embed` and `Asset`

<!-- example: modules/embed_text_file -->

`@embed(path)` is the file `path` names, read while the program is built
(decision 519), as an `Asset` — a builtin record like `SourceLocation`, with no
import:

| Field | Value |
|---|---|
| `path` | the path as written |
| `bytes` | the file's bytes (`Bytes`) |
| `size` | the number of bytes (`i64`, as a file's size is) |
| `hash` | the SHA-256 of the bytes, 64 lowercase hex digits |

`size` is an `i64` (decision 538), as `stat`'s and a `File`'s are: it binds to an `i64` without a
conversion and sums past the `i32` range.

<!-- example: modules/embed_size_i64 -->

`a.text()` is the bytes as UTF-8 text, computed at build: bytes that are not
UTF-8 are `error[embed-text-not-utf8]` at the call, and an `Asset` whose bytes
are not known where the call is checked — a parameter, a function's answer — is
`error[embed-text-not-at-build]`.

`a.open()` is the `File` of std's file system over the embedded copy (decision 538): the same
`read`, `bytes`, `text`, `chunks`, `lines`, `hash` and `size` as a file on disk, a fallible one answering
`@Result<…, FsError>`, `close` a no-op, and no `@Result` around the `File` itself — the build proved the
file exists. Code that takes a `File` reads one on disk (`fs.open`) and an embedded one alike. The call
hands the `Asset` to std's `io.fs`, so the module that writes it imports `io.fs`; without the import it is
`error[embed-open-needs-fs]`, at the call.

<!-- example: modules/fs_asset_opens_as_file -->

A module that does not declare `Asset` reads its fields all the same: `a.path` is the path, `a.bytes` the
bytes, wherever the value reaches it.

<!-- example: modules/embed_field_read_other_module -->

<!-- example: modules/embed_open_without_fs_import -->

`@embed` is a `Build` builtin (decision 376): a call whose path is known at
build — a literal, a constant `val`, a `comptime`, an `Any` call of those — is
computed where it is written, in a body or in a module-level `val`, with no
`comptime` (decision 380 (1) extended to `Build` calls; a `comptime` written
stays legal). The artifact carries the bytes on every target — an Erlang
binary, a JS `Uint8Array`, a wasm data segment — and the program never reads
the file when it runs, so a file that is not text embeds byte for byte:

<!-- example: modules/embed_binary_file -->

The path is relative to the `botopink.json` of the package that writes it; a
path passed on through a `comptime` parameter is read in the caller's package —
the function takes the caller's `Asset`, read where the call is written:

<!-- example: modules/embed_through_comptime_param -->

An absolute path is `error[embed-path-absolute]` and a path with a `..` segment
`error[embed-path-outside-package]`, at the argument; a path that names no file
of the package is `error[embed-file-missing]`, at the call; a path not known at
build — a parameter, a local — is `error[comptime-arg-not-known]`, at the
argument. The compiler that runs in a browser (`compiler-web`) is handed no
reader: every `@embed` there is `error[embed-no-reader]`, at the call.

<!-- example: modules/embed_path_absolute -->
<!-- example: modules/embed_path_outside_package -->
<!-- example: modules/embed_file_missing -->
<!-- example: modules/embed_path_not_known -->
<!-- example: modules/embed_text_not_utf8 -->

## Tests

<!-- example: test/assert_and_try.bp -->

Test blocks are declared at module level. Run with `botopink test`
(`--target`, `--filter <substring>`). A test that spawns the compiler — to
build a fixture project — reads its path from the `BOTOPINK_BIN` environment
variable: `botopink test` sets it to its own executable for the tests it runs,
unless the caller already set it.

A module's tests are a unit of their own (decision 513): the module's code is
the same under `botopink build`, `run` and `test`, and its `test` blocks are
compiled beside it only under `botopink test` of the package under test — a
dependency's tests are never compiled or run. A test block reads its module's
private functions and module-level `val`s as the module's own code does, on
every target (`botopink test` on wasm runs the `wasi` host):

<!-- example: test/module_init -->

A test body is a **fallible context**: a `try` whose operand is an `Error(e)`
ends the test as `FAIL <name>  (<e>)  at <file>:<line>` — `e` is the message
(a non-string `e` is rendered) and the `at` is the test's own line. The
statements after the failed `try` do not run; a `try` inside a lambda is the
lambda's, not the test's. An assertion helper is therefore an ordinary
`fn … -> @Result<void, string>` whose `ok` position is the empty
`return;`. What the runner prints for the failed test below is the CLI's
contract (`modules/compiler-cli/tests/test_tooling.sh`), not a cell's:

```text
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
commonJS, erlang and beam — its cells are `pub declare fn` with a Node and an
Erlang template each (beam reads the Erlang one), so `import {testing.mocks} from "std"`
is refused on wasm.

<!-- example: test/mocks_handwritten_double -->

`#[mocks.mock]` writes that double for you — it reflects the annotated
`behavior`'s methods through `compiler.methods` and gives the behavior the associated
type `<Name>.Mock` and the factory `<Name>.mock()` (§ Decorators). A std module's decorators come with its namespace
import, under the handle it binds: `import {testing.mocks}` makes `mock`
the annotation `#[mocks.mock]` (an alias `as m` makes it `#[m.mock]`), and the
code it adds reaches the runtime through that same handle (`mocks.invoke(…)`).
A name through the handle that is not one of the module's decorators is
`error[unknown-annotation]`, and a decorator imported as a leaf
(`import {testing.mocks.mock}`) is `error[std-decorator-leaf-import]`: the code
it adds would have no handle to name the runtime by.

<!-- example: test/mocks_decorator_double -->

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
`bpmp install` / `bpmp link` links under `.botopinkbuild/deps/` — run either
again after it — and every build cache (`.botopinkbuild/cache/`: the code cache of
the dependencies' compiled modules, `code/`). In
a workspace member, the workspace root's `.botopinkbuild/cache/` and
`.botopinkbuild/analysis/` (the dependencies' analysis) go too: the members of a
workspace share one cache there.

A dependency's analysis is kept between invocations (the code cache's level B,
decision 509): `botopink build`, `run`, `test`, `check` and `cell check` read
each dependency package's analysis from
`.botopinkbuild/analysis/<target>/<package>.bpa` (std's one file per module,
under `std/`) when it was written under the same closure key — the package's
files, its manifest, its dependencies' keys, the target and the compiler — and
write the ones they analysed once the build's compile returned. The package
being built, run or tested is analysed every time and never stored, and so is a
package whose module reads `@TypeInfo.all` or expands a template that reads it.
`--cold` reads none of it.

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
and every refusal are in *The manifest schema*, below.

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

## The manifest schema — `botopink.json`

Every project, library and workspace carries a `botopink.json` at its root. One
reader parses it for every tool — `modules/manifest/src/root.zig`, imported by
the compiler (`botopink build/check/run/test`), the language server, the lib-test
runner (`botopink-lib-test`, `zig build test-libs`) and `bpmp` — so the fields,
the shapes and the refusals below are the same everywhere. A refusal is always a
**located error**: the message, the manifest file and the line and column of the
entry that is wrong, in the compiler's diagnostic shape:

```text
error: "dependencies" must be an object, not an array — …
 --> botopink.json:2:3
  |
2 |   "dependencies": ["erika"] }
  |   ^^^^^^^^^^^^^^
```

Nothing is parsed and ignored, and no field switches a refusal off (decision 67
of 1.0.5-beta). Two kinds of manifest exist: a **package** and a **workspace**
(decision 75 of 1.0.10-beta).

### A package

```json
{
  "name": "acme-web",
  "version": "0.0.1",
  "description": "Rakun-style web layer — commonJS and erlang",
  "src": "src/",
  "entry": "root.bp",
  "target": "commonJS",
  "targets": ["commonJS", "erlang"],
  "files": ["root.bp", "router.bp"],
  "dependencies": {
    "acme": { "workspace": true },
    "jhonstart": { "git": "https://github.com/botopink/jhonstart.git", "branch": "feat" },
    "local-tool": { "path": "../../tools/local-tool" }
  }
}
```

| Field | Type | Default | Read by | Meaning |
|---|---|---|---|---|
| `name` | string, **required** | — | every reader | The package's **import name**: `from "acme-web"` resolves to the package named so. A workspace member is reached by this name, never by its directory. It also starts every erlang/BEAM module atom of the package (`acme_web@main`, `std@math@@PI` — decision 109 of 1.0.10-beta), so it must start with a lowercase letter, and `bp` (the compiler's own namespace) is refused. |
| `version` | string | `"0.1.0"`; a workspace member's: the workspace's | compiler, `bpmp` (`pack`, the auto-tag) | The package version. A member writes it only when it differs from its workspace's (decision 512). |
| `description` | string | — | — (documentation) | One line. |
| `src` | string | `"src/"` | compiler, LSP, loader | The source directory, relative to the manifest. `"."` roots the module tree at the manifest's own directory; `test/`, hidden directories and nested packages there are not modules of the tree. |
| `entry` | string | detected; a workspace member's: `main.bp` | compiler's resolver (`compiler-cli/src/cli/resolver.zig`) | The module-tree root under `src`: `main.bp` for an application, `root.bp` for a library. When absent, `main.bp` is used if present, else `root.bp` — a workspace member without one is `main.bp` (decision 512), so a library member writes `"entry": "root.bp"`. `entry` is followed when **this** package is built or tested; a consumer never follows it. |
| `target` | string | `"commonJS"` | `botopink build/run/test` | The default target of `botopink build`, `run` and `test`. One of `commonJS`, `erlang`, `beam`, `wasm`; another value is refused (never degraded). |
| `targets` | array of strings | every target | `botopink-lib-test` | The targets the runner may run this package on. Absent: every requested target. A target the list leaves out is not a cell — nothing runs it — and the exclusion is audited on every run: `botopink build --target <excluded>` must be refused for a missing host binding (`has no #[@external(.<Target>(…))]`), so a package may exclude only a target it structurally cannot run on; one that builds there, or fails for another reason, fails the run. A member of a workspace inherits the workspace's `targets` when it declares none, and may only **restrict** them (below). |
| `files` | array of strings | `[]` | the loader (`compiler-cli/src/cli/libs.zig`, `language-server/src/project_graph.zig`), `bpmp pack` | The modules a **consumer** may import, each relative to `src`; shipped as `<name>/<stem>` (`acme-web/router` → `import { … } from "acme-web.router"` / the root `root.bp` → `from "acme-web"`). The only thing a dependency's consumer sees — a library that lists no `files` ships nothing. `libs/std` uses it for the modules the compiler build embeds. |
| `dependencies` | **object** | `{}`; a workspace member's: its workspace's | compiler, LSP, runner, `bpmp` | The object form only — below. A workspace member inherits every dependency its workspace declares and adds its own; it may not declare one the workspace declares (decision 512, § A workspace). |
| `otp` | string | the compiler's | `botopink build/check/run/test` (`compiler-cli/src/cli/config.zig`, `libs.zig`) | The Erlang/OTP release the package is built for (decision 228 of 1.0.11-beta). The compiler emits for one release (`botopink --version` prints it: `otp: 28`), and `otp` may only name that one — another value is refused, located at the value. Every package of a build's closure that declares it must declare the same release; a mismatch is refused at the later value, naming the first manifest. A member of a workspace inherits the workspace's `otp` when it declares none, and may not name another. Absent everywhere: the compiler's release applies. Whatever the manifests say, `botopink build/run/test --target erlang\|beam` refuses an `erl` on `PATH` of another release before writing anything: `` botopink emits Erlang for OTP 28, and `erl` on PATH is OTP 29 — install OTP 28 and put it on PATH ``. |
| `wasm` | object | `{ "host": "wasi" }` | `botopink build/run --target wasm` (`compiler-cli/src/cli/config.zig`) | The runtime a wasm build binds to (decision 334 of 1.0.12-beta), its one field `host`: `"wasi"` — wasmtime and the runtimes that follow WASI preview 2 (`wasi:http`, `wasi:clocks`, `wasi:io/poll`), the default — or `"browser"` — JS imports (`fetch`, `setTimeout`, `Promise` through JSPI), which node runs too. Absent means `"wasi"`; an object without `host`, another field, or a host that is neither is refused. Read on the package being built, never on a dependency; a workspace manifest may not carry it. |
| `bpp` | string | — | `botopink build/check/run/test` (`compiler-cli/src/cli/bpp.zig`, through `libs.zig`) | The package that unfolds the application's `.bpp` files (decision 361 of 1.0.12-beta): `"bpp": "jhonstart"`, one name, an entry of `dependencies` (refused at the value otherwise). The toolchain finds its roles in that package by std's `bpp` annotations — `#[bpp.html]` exactly once, `#[bpp.style]`, `#[bpp.htmlPrelude]`, `#[bpp.stylePrelude]` at most once each, each on a `pub` declaration, a prelude module holding its imports and its marker `val` only; a count that breaks the rule is refused at this key, naming the declarations. The object form `{ "default": …, "style": … }` is refused at the key: `"bpp" is a package name — write "bpp": "jhonstart"`. A project with `.bpp` files under `src` and no key is refused at the first file; with the key and no `#[bpp.style]` in the package, a `.bpp` style section is refused at its `--- style ---` line. The key on a project with no `.bpp` file is accepted. Read on the package being built, never on a dependency; a workspace manifest may not carry it. |
| `botopink`, `requires` | string · object | — | `bpmp` only | `botopink`: the compiler-version constraint. `requires`: the per-dependency version constraint `bpmp install <name>@<spec>` records. The compiler passes both through unread. |

Unknown fields are preserved by `bpmp` (it rewrites the file) and not read by
anyone else.

### `dependencies` — the object form (decision 76)

```json
"dependencies": {
  "<name>": { "path": "<relative directory>" },
  "<name>": { "git": "<url>", "branch": "<b>" | "tag": "<t>" | "rev": "<sha>", "subdir": "<dir>" },
  "<name>": { "workspace": true }
}
```

The key is the dependency's **import name** (`from "<name>"`) and each entry
declares **exactly one source**:

| Source | Resolves to | Notes |
|---|---|---|
| `{ "path": "…" }` | `<project directory>/<path>`, which must hold a `botopink.json` whose `name` is the key | Honoured by the compiler and the LSP directly — no library root is consulted. `bpmp install` links it under `.botopinkbuild/deps/<name>`. |
| `{ "git": "…", pin }` | The library named `<name>` in the first **lookup tier** that carries it (below): `BOTOPINK_LIB_ROOTS`, then the link `<project>/.botopinkbuild/deps/<name>/`, then the library roots of the walk-up | The pin is one of `branch`, `tag` or `rev` — `bpmp install` clones it; `bpmp link` links a local checkout instead; the compiler resolves by name and does not fetch. A pin without `git` is refused. |
| `{ "workspace": true }` | The **sibling member** of the enclosing workspace named `<name>` | The only way a member depends on a sibling (decision 75). Outside a workspace it is refused. |

**`"subdir"` — a package inside a git repository (decision 344).** A `git`
dependency may name a package that is not at the repository's root:

```json
"dependencies": {
  "rakun-web": { "git": "https://github.com/botopink/rakun", "tag": "v1.0", "subdir": "modules/rakun-web" }
}
```

`bpmp install` clones the repository once at the pin into its store and links
`.botopinkbuild/deps/<name>` to `<checkout>/<subdir>`, which must hold a
package (not a workspace) whose `name` is the key. That package's `path` and
`{ "workspace": true }` dependencies resolve from its directory inside the
checkout (the compiler follows the link), so its siblings come at the same pin;
each must stay inside the checkout. Two dependencies on one repository — one
URL once a trailing `/` and `.git` are dropped — share one checkout and must
name one pin. The compiler still resolves the dependency by name.

`std` is embedded in the compiler and is never listed — it is the one package
the compiler ships (decision 326). Every other library is declared here,
`routing` as any other:

```json
"dependencies": {
  "routing": { "git": "https://github.com/botopink/routing.git", "branch": "feat" }
}
```

Without the entry, `from "routing"` is refused at the import:
`unresolved import source "routing" — declare it in botopink.json "dependencies"`.

**Lookup tiers** (where a `git` dependency is found by name — decision 483,
as `node_modules`). The first tier that carries the name answers; a name two
tiers carry is the earlier tier's, never "declared by two libraries":

1. `BOTOPINK_LIB_ROOTS` entries (`:`-separated on POSIX), when set;
2. `<project>/.botopinkbuild/deps/` — one symbolic link per dependency, written
   by `bpmp install` (into its store) or `bpmp link` (into a local checkout's
   `repository/<name>`); for a workspace member, then
   `<workspace root>/.botopinkbuild/deps/` (where `bpmp link` run at the
   workspace root writes one link per name for every member). The link wins
   over the walk-up;
3. the **library roots** of the walk-up, as a fallback: for each ancestor `D`
   of the working directory, nearest first, `D` itself when `D/botopink.json`
   is a workspace (its members), `D/repository/botopink-lang/libs` (the
   embedded `std`), `D/repository` (sibling libraries), `D/libs` — up to the
   first `D` that holds `repository/` (the enclosing checkout, decision 143).

A tier contributes every immediate child directory (or link to one) holding a
`botopink.json` — as a package named by the directory — and every **member** of
a workspace found there, named by its manifest. The same directory reached
through two roots of one tier is one library. Every package of a build — a
dependency's own `git` dependencies included — is looked up in the project's
tiers: one `.botopinkbuild/deps/` serves the whole closure.

**`bpmp link [<checkout>]`** writes those links without cloning anything: for
every `git` dependency of the project's manifests (a workspace's members
included, and, flat, the `git` dependencies of what it links),
`.botopinkbuild/deps/<name>` → `<checkout>/repository/<name>` (a `"subdir"`
dependency: `<checkout>/repository/<repository>/<subdir>`, `<repository>` the
last segment of its `git` URL). `<checkout>` defaults to the nearest directory,
from the working directory up, that holds `repository/`. A dependency whose
local repository holds no `botopink.json` is named — `"x" has no local
repository: <checkout>/repository/x holds no botopink.json — check it out there,
or name another checkout`, located at its entry — and the command exits 1 with
nothing linked; an existing link is replaced. CI keeps `bpmp install`, which
fetches.

#### Refusals

| Manifest | Message |
|---|---|
| `"dependencies": ["erika"]` (the retired string array, empty included) | `"dependencies" must be an object, not an array — write { "<name>": { "path": "…" } \| { "git": "…", "branch"\|"tag"\|"rev": "…" } \| { "workspace": true } }; for example ["erika"] becomes { "erika": { "path": "../erika" } }` |
| `"dependencies": "nope"` | `"dependencies" must be an object — { … }` |
| `"x": "feat"` (an entry that is not an object) | `dependency "x" must be an object — { … }` |
| `"x": { "branch": "feat" }` | `dependency "x" declares no source — one of "git", "path" or "workspace": true is required` |
| `"x": { "path": "../x", "workspace": true }` | `dependency "x" declares more than one source — exactly one of "git", "path" or "workspace": true` |
| `"x": { "git": "…", "branch": "feat", "rev": "…" }` | `dependency "x" declares more than one pin — exactly one of "branch", "tag" or "rev"` |
| `"x": { "path": "../x", "tag": "v1" }` | `dependency "x" pins a ref without a "git" source — a pin applies to a git dependency only` |
| `"x": { "workspace": false }` | `dependency "x": "workspace" can only be true — { "workspace": true } names the sibling member of the enclosing workspace` |
| `"x": { "git": 1 }` (and `path`, `branch`, `tag`, `rev`, `subdir`) | `dependency "x": "git" must be a string` |
| `"x": { "path": "../r", "subdir": "modules/x" }` (a `subdir` beside `path` or `workspace`) | `dependency "x" names a "subdir" without a "git" source — a subdir names a package inside a git repository` |
| `"x": { "git": "…", "subdir": "/modules/x" }` (also `C:/…`) | `dependency "x": "subdir" "/modules/x" is absolute — it names a directory of the repository, relative to its root` |
| `"x": { "git": "…", "subdir": "modules/../../x" }` | `dependency "x": "subdir" "modules/../../x" leaves the repository — ".." is not a segment of a subdir` |
| `"x": { "git": "…", "subdir": "./modules/x" }` (also `modules//x`, a trailing `/`) | `dependency "x": "subdir" "./modules/x" has an empty or "." segment — write the directory as plain segments separated by "/"` |
| `"x": { "git": "…", "subdir": "modules\\x" }` | `dependency "x": "subdir" "modules\x" holds a backslash — segments are separated by "/"` |
| `"x": { "git": "…", "subdir": "" }` | `dependency "x": "subdir" is empty — omit "subdir" for the package at the repository's root` |
| `"a": { "git": "<r>", "tag": "v1" }, "b": { "git": "<r>.git", "branch": "feat" }` | `dependencies "a" and "b" name one repository (<r>.git) at two refs (tag "v1" and branch "feat") — one repository is one checkout; pin both at one ref` (on the second entry) |
| `"wasm": { "host": "deno" }` (a host that is neither `wasi` nor `browser`) | `"wasm": "host" names "deno" — a wasm build runs on "wasi" (wasmtime, WASI preview 2) or "browser" (JS imports, JSPI)` (on the value) |
| `"wasm": "wasi"` (not an object) | `"wasm" must be an object — { "host": "wasi" \| "browser" }` |
| `"wasm": {}` | `"wasm" names no "host" — write { "host": "wasi" \| "browser" }, or omit "wasm" for the default "wasi"` |
| `"wasm": { "host": 1 }` | `"wasm": "host" must be a string — "wasi" or "browser"` |
| `"wasm": { "host": "wasi", "jspi": true }` (any field beside `host`) | `"wasm" has no field "jspi" — its one field is "host": { "host": "wasi" \| "browser" }` (on the field) |
| `"otp": "26"` (any release but the compiler's) | `botopink emits Erlang for OTP 28; "otp" names 26` (on the value) |
| a dependency of the closure whose `"otp"` differs from the project's (or the first pin's) | `"otp" names 29 here, but 28 in <first>/botopink.json — every package of a build pins one OTP release` (on the dependency's value) |

Refusals at resolution time (the compiler and the LSP — and `bpmp install`
where a row names it — located on the project's `dependencies` entry unless a
row says otherwise):

| Situation | Message |
|---|---|
| `{ "workspace": true }` in a project no workspace lists | `"x": { "workspace": true } but <project>/botopink.json is not a member of any workspace — no ancestor botopink.json lists this directory under "workspaces"` |
| `{ "workspace": true }` naming no sibling | `"x": { "workspace": true } names no member of <workspace>/botopink.json (members: a, b, c)` |
| `{ "path": … }` holding no manifest | `"x": path "../x" holds no botopink.json (looked at <abs>/botopink.json)` |
| `{ "path": … }` whose package has another `name` | `"x": path "../y" holds a package named "y" — the dependency key is the import name and must match` |
| `{ "path": … }` pointing at a sibling member | `"x": path "../x" points at the sibling member "x" — use { "workspace": true }` |
| `{ "path": … }` pointing at a workspace | `"x": path "../ws" is a workspace, not a package — depend on one of its members: a, b, c` |
| `{ "git": … }` whose name is a workspace under a root | `"x" is a workspace, not a package — import one of its members: a, b, c` |
| `{ "git": … }` whose name no root carries | `dependency 'x' was not found under any library root` |
| two `files` entries of the resolved dependency naming one module (one file listed twice, or `p.bp` beside `p.bpp`) | `"files" lists p.bp and p.bp, one module (` p `) written twice — keep one of the two files` (located on the dependency's manifest, at the second entry; a package's own manifest is refused the same way) |
| a `files` entry of the resolved dependency that does not exist | `dependency 'x' lists "gone.bp" in ` files `, but <path> does not exist` (located on the dependency's manifest) |
| `bpmp install`: a `subdir` holding no manifest | `"x": subdir "modules/x" holds no botopink.json in <git> at <rev12> (looked at <checkout>/modules/x/botopink.json)` |
| `bpmp install`: a `subdir` holding a workspace | `"x": subdir "modules/ws" is a workspace, not a package — name one of its members' subdirs: modules/ws/a, modules/ws/b` |
| `bpmp install`: a `subdir` holding another package | `"x": subdir "modules/y" holds a package named "y" — the dependency key is the import name and must match` |
| `bpmp install`: a `path` dependency of the package (or of its in-checkout closure) leaving the checkout, by spelling or through a symbolic link | `"y": path "../../../y" leaves the checkout of <git> — a package of a git dependency names by path only packages of its own repository` (on that package's own manifest) |
| `bpmp install`: `botopink.lock` pinning two dependencies on one repository at two commits | `install: botopink.lock pins 'a' and 'b' at two commits of one repository — one repository is one checkout (decision 344)` (`bpmp install --update` re-pins) |
| `bpmp link`: a `git` dependency whose `<checkout>/repository/<name>` holds no manifest | `"x" has no local repository: <checkout>/repository/x holds no botopink.json — check it out there, or name another checkout` (every such dependency named, then exit 1; nothing linked) |
| `bpmp link`: one name linking to two directories (a project's `"subdir"` entry and a linked package's entry by name) | `"x" links to <dirA> here, but to <dirB> for <manifest> — one name is one link` |
| a dependency named like the project, or like a member of its workspace, at another directory (the code cache files a dependency's analysis by its name) | `two packages named "x" in this workspace's build — <dirA> here and <dirB> — one name is one package` (on the `dependencies` entry that brought it in) |
| a host sidecar the resolved dependency does not carry | `dependency 'x' requires "./x.mjs" from module 'x/root', but no such file is in its sources (looked at <src>/sidecars/x.mjs, then <src>/x.mjs)` |

<!-- example: modules/dependency_named_like_its_consumer -->
<!-- example: modules/files_one_module_twice -->

#### Host sidecars

A `#[@external(.Node("./x.mjs", "f"))]` lowers to a relative `require("./x.mjs")`
in the emitted module. The file is the library's, not the consumer's, so
`botopink build` and `botopink test` copy it next to the emitted JS —
`<out>/<name>/x.mjs` for a dependency's module, `<out>/x.mjs` for the project's
own — and rewrite the `require` when the authored path would escape the output
directory. The `.erl` host module of an `#[@external(.Erlang("host", "f"))]` is
copied the same way.

Which directory a sidecar is copied *from* is the dependency this manifest
resolved, by the rules of the table above — **not** a directory of that name
under the library roots. A `{ "path": … }` dependency outside every root, and a
name two checkouts of one library both declare (which the roots refuse to
resolve, deliberately), are therefore shipped correctly. Inside that directory
the file is looked for under the dependency's own `src`, first as
`<src>/sidecars/<file>` and then as `<src>/<file>`. Only a library the project
does not declare as a dependency — the embedded `std` — is found by name across
the roots.

A sidecar a module requires and the build cannot ship ends the build with a
located error on the `dependencies` entry that named the library. There is no
flag, environment variable or manifest field that reduces it to a warning: a
build that exits 0 having shipped nothing is a program that dies on its first
run instead.

### A workspace (decision 75)

```json
{
  "name": "rakun",
  "version": "0.0.1",
  "description": "The rakun libraries",
  "targets": ["commonJS", "erlang"],
  "workspaces": ["modules/*", "examples/*"]
}
```

A manifest with `"workspaces"` is a workspace: it declares **members** and is
never a package. `npm`'s field name, `npm`'s meaning.

A workspace declares what its members share, and a member declares only its own
(decision 512 of 1.0.12-beta). Every `conformance/modules/` is one — its members
are the cells, each named after its directory (decision 511), so a library's cells
share one dependency closure and one code cache (`conformance/modules/.botopinkbuild/cache/`,
decision 509):

```json
{
  "name": "conformance",
  "version": "0.0.1",
  "targets": ["commonJS", "erlang", "beam"],
  "workspaces": ["*"],
  "dependencies": {
    "emilia": { "path": "../../modules/emilia" }
  }
}
```

and a cell that adds nothing is `{ "name": "alpha" }`.

| Field | Meaning |
|---|---|
| `name`, `description` | As for a package. The name is what a lookup answers with when something imports the umbrella by mistake. |
| `version` | As for a package; a member that writes none has it. |
| `targets` | The default every member inherits when it declares none; a member may only **restrict** it. |
| `otp` | The release every member inherits when it declares none; a member may only repeat it. |
| `dependencies` | Every member's: a member inherits each entry, a `path` resolved from the workspace's manifest (not the member's), and adds its own beside them; declaring one the workspace declares is refused — one source per dependency in a workspace. `{ "workspace": true }` names a sibling of the member that writes it and is refused here. |
| `workspaces` | The member globs. Three forms: `"<dir>/*"` — every child directory of `<dir>` that holds a `botopink.json` (a child without one is not a member); `"*"` — every child directory of the workspace's own that holds one; `"<dir>"` — one directory, which **must** hold a `botopink.json`. Paths are inside the workspace (no `..`, no absolute path, no other `*`). |
| `src`, `files`, `entry`, `wasm`, `bpp` | **Refused** — a workspace compiles nothing and ships nothing. |

Each member is a package whose `name` — **required**, and unique in the workspace —
is its import name (`from "rakun-web"`); `src`, `entry` and `version` default to
`src/`, `main.bp` and the workspace's version, so a member writes them only when they
differ.
The runner runs every member — examples included — one row per member, and the
umbrella has no row. A member depends on a sibling with `{ "workspace": true }`
only. Workspaces do not nest.

A member that is a **library** (its module tree is rooted at `root.bp`, not
`main.bp`) and lists no `files` **ships nothing**: `botopink test` inside it
fails, and the runner marks every cell `✗`, with

```text
error: ships nothing: manifest has no "files" — a workspace member that is a library lists every module a consumer may import
 --> modules/rakun-web/botopink.json:2:3
```

An example member (`entry: main.bp`, or `src/main.bp` present) is an
application; nothing is shipped from it by design.

#### Examples and `-test` members (decisions 75, 390)

Every library is a workspace with a core, a `-test` member and its examples as
members. An example member carries a `README.md` beside its `botopink.json`
naming the upstream section it shows and the front that owns it, and reaches its
library by `{ "workspace": true }`, never by `"git"`. A `-test` member exposes at
least one helper `pub fn assert<Subject>(loc: SourceLocation, …) -> @Result<void,
string>`, no more helpers than a consumer uses. `scripts/check-packaging.sh` checks
the four rules across the library repositories — a README per example, a helper
per `-test` member, no `"git"` to an ecosystem library from an example, every
member listed by `botopink-lib-test --list` — and names each path that breaks
one. The `onze` repository is the orchestrator; the mocking library it held is
kept as its tagged history, `mocking-lib-final` (decision 507).

#### Refusals

| Manifest | Message |
|---|---|
| a workspace with `files` (or `src`, `entry`, `wasm`, `bpp`) | `a workspace manifest cannot carry "files" — a workspace declares members, it is not a package; move "files" to the member's own botopink.json` |
| a workspace's `dependencies` naming `{ "workspace": true }` | `"lib": { "workspace": true } names a sibling member, and a workspace's dependencies are every member's — declare it in the members that use it` (on the entry) |
| a member declaring a dependency its workspace declares | `"lib" is a dependency of the workspace (<ws>/botopink.json), which every member inherits — delete this entry: a workspace has one source per dependency` (on the member's entry) |
| `"workspaces": ["modules/**"]` (or `"*/src"`, `"../x"`, `"/abs"`, `""`) | `workspaces entry "modules/**" is not a supported form — use "<dir>/*" (every child of <dir> holding a botopink.json), "*" (every child of the workspace's directory) or a literal "<dir>" inside the workspace` |
| `"modules/*"` when `modules/` does not exist | `workspaces entry "modules/*": <ws>/modules is not a directory that can be read` |
| `"modules/ghost"` with no manifest there | `workspaces entry "modules/ghost": <ws>/modules/ghost/botopink.json does not exist — a literal entry names a directory holding a botopink.json` |
| a member that is itself a workspace | `"inner" is a member of <ws>/botopink.json and cannot itself be a workspace — workspaces do not nest` (on the member's `workspaces`) |
| two members with one `name` | `member name "dup" is declared twice in <ws>/botopink.json: <a>/botopink.json and <b>/botopink.json` (on the second member's `name`) |
| a member naming another `otp` | `"otp" names 29 here, but 28 in <ws>/botopink.json — every package of a build pins one OTP release` (on the member's value) |
| a member widening `targets` | `"erlang" is not one of the workspace's targets ["commonJS"] (<ws>/botopink.json) — a member may only restrict the workspace's targets` (on the member's entry) |
| a member depending on itself | `"web" cannot depend on itself` |
| a member's `{ "workspace": true }` naming no sibling | `"ghost": { "workspace": true } names no member of <ws>/botopink.json (members: a, b)` |
| a member's `path` to a sibling | `"core": path "../core" points at the sibling member "core" — use { "workspace": true }` |
| a member's `path` to the workspace | `"umbrella": path "../../" points at the workspace itself — a workspace is not a package; depend on one of its members with { "workspace": true } (members: a, b)` |
| `botopink build/check/run/test` in the workspace directory | `<ws>/botopink.json is a workspace, not a package — run this command inside one of its members: a, b, c` |
| two **members** with one `name` in different directories across the library roots (or a member and a package) | `"x" is declared by two libraries: <dirA> and <dirB> — a name resolves to one library; rename one of them` — on both, so neither is used (first-root-wins is what decision 75 retires; two plain packages with one name keep first-root-wins). |

### Refusals common to every manifest

The manifest's refusals are the toolchain's, not the language's: `modules/manifest/src/root.zig`'s unit tests
check each one (`zig build test`), never a conformance cell — every cell's manifest is valid, a member of its
`conformance/modules/` workspace (decision 512).

| Manifest | Message |
|---|---|
| not JSON | `botopink.json is not valid JSON` |
| not an object | `botopink.json must be a JSON object` |
| no `name` | `botopink.json has no "name"` |
| `"name": 1` (any string field that is not a string) | `"name" must be a string` |
| `"name": "MyApp"` (a name that does not start with a lowercase letter) | `"name" must start with a lowercase letter — every erlang module atom of the package starts with it` |
| `"name": "bp"` | `"name" cannot be "bp" — it is the compiler's own namespace, the package of a module compiled outside any botopink.json` |
| `"name": "std"`, outside the bundled `libs/std` | `the package name \`std\` is the bundled standard library's — choose another name` (decision 453; the directory decides — `<checkout>/libs/std` of the compiler's own checkout — never the name alone) |
| `"files": "root.bp"` (any array field that is not an array of strings) | `"files" must be an array of strings` · `"files" must be an array of strings — entry 2 is not a string` |

### Where each tool meets the manifest

| Tool | Reads | Path |
|---|---|---|
| `botopink build/check/run/test` | the project's manifest (cwd), the enclosing workspace, each dependency's manifest | `modules/compiler-cli/src/cli/config.zig`, `libs.zig` |
| `botopink-lsp` | the nearest manifest above the open file, the enclosing workspace, each dependency's manifest — refusals are editor diagnostics on the manifest | `modules/language-server/src/project_graph.zig` |
| `botopink-lib-test` | every package and every workspace member under the library roots; `targets`; `files` of a library member | `modules/lib-test-runner/src/discovery.zig` |
| `bpmp` | `dependencies` (to install or link), `files` (to pack), `botopink`, `requires`; writes `dependencies` entries as `{ "git": … }` | `modules/bpmp/src/manifest.zig`, `dep/spec.zig` |
| the shared model | everything above | `modules/manifest/src/root.zig` |

## Migrating from the effect annotations

1.0.10-beta replaced the effect annotations with the return type (decisions
118–128) and kept no compatibility window (decision 127): every old form below
is a located compile error with a fix-it — `effect-annotation-removed` for an
annotation (on a loop it suggests `iter` / `stream`), `effect-type-removed` for
a wrapper name, `iterator-error-param-removed` for `@Iterator<T, E>`. There is
no automatic rewriter: each error names the new spelling, from the table below.

<!-- example: modules/effect_annotation_removed_async_generator -->
<!-- example: modules/effect_annotation_removed_context -->
<!-- example: modules/effect_annotation_removed_future -->
<!-- example: modules/effect_annotation_removed_future_generator -->
<!-- example: modules/effect_annotation_removed_future_generator_loop -->
<!-- example: modules/effect_annotation_removed_generator -->
<!-- example: modules/effect_annotation_removed_generator_loop -->
<!-- example: modules/effect_annotation_removed_iterator -->
<!-- example: modules/effect_annotation_removed_result -->
<!-- example: modules/effect_annotation_removed_result_generator -->
<!-- example: modules/effect_annotation_removed_result_generator_loop -->
<!-- example: modules/effect_annotation_removed_use -->
<!-- example: modules/effect_type_removed_async_iterator -->
<!-- example: modules/effect_type_removed_future -->
<!-- example: modules/effect_type_removed_future_generator -->
<!-- example: modules/effect_type_removed_future_no_error -->
<!-- example: modules/effect_type_removed_generator -->
<!-- example: modules/effect_type_removed_iterable -->
<!-- example: modules/effect_type_removed_iterator_step -->
<!-- example: modules/effect_type_removed_result_generator -->
<!-- example: modules/effect_type_removed_use -->
<!-- example: modules/effect_type_removed_yield -->

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
| `val c = use @getContext(T);` | `T`'s default declared with `createContext(…)`, `use provide(createContext(…))` in the component that renders the reader, `val c = use context(T);` |

Decision 354's three rows have a codemod, `scripts/codemod-component-contexts.py`
(`scripts/AGENTS.md`): it rewrites the first two and reports each `use
@getContext(T)` at its line — which component provides the context is the
author's choice.

Decision 354 leaves one wrapper, `@Component<R>`, and `@Renderable` as a bare marker: `@Component<C, R>` is a type-arity error (`generic-arg-count-exceeded`) naming `@Component<R>`, located on the base; `@Renderable<T>` is the same error at the `<`, naming `@Renderable`; and the owner marker `@Context<C>` is `context-marker-removed`, naming `implement @Renderable`.

<!-- example: modules/component_base_parameter -->
<!-- example: modules/context_marker_removed -->
<!-- example: modules/renderable_type_argument -->

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
| `@embed` in a decorator's or a template's body reads a path its `comptime` parameter passes — a decorator annotating the application's declarations reads the application's file (decisions 342, 519) | `error[comptime-arg-not-known]` at the argument: the body runs on the comptime runtime, which reads no file | 144 B-12 |
| A file `@embed` reads in a dependency joins the dependency's closure key (decision 519, 144 B-60) | a file under the package's `src` tree is in the key; one beside it (`assets/`) is not, so an entry read back can carry a stale copy | 144 B-12 / B-60 |

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

<!-- example: modules/tuple_literal_label -->

<!-- example: modules/implement_clause_for -->

<!-- example: modules/list_spread_dot_dot_dot -->

<!-- example: modules/list_spread_not_last -->

<!-- example: modules/nested_fn_decl -->

<!-- example: modules/char_literal_absent -->

<!-- example: modules/bitwise_operator_absent -->

<!-- example: modules/ternary_absent -->

<!-- example: modules/variant_payload_without_name -->


<!-- example: modules/assert_is_pattern -->