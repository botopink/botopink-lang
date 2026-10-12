# conformance — botopink-lang's conformance suite (decisions 457, 464, 466, 475)

> Path: `conformance/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The language's conformance cells: what any implementation of botopink must answer, written in
botopink, checked on every target by running the emitted program. Front 15 pinned decision 8
(`specs/1.0.4-beta/08-review-backlog/decision-8-language.md` in the meta workspace): `case` and
patterns (§5), tuples and labels (§6), `loop` (§10), and the parts of `is` (§4), unions (§3),
`unknown` (§2) and printing (§7) those scenarios use. Front 17
(`specs/1.0.4-beta/17-language-test-expansion/README.md`) added the rest of the language surface —
effects (§9), comptime parameters and `@Expr` templates, decorators and `@emit`, host externals (§8),
generics and `behavior` dispatch, optionals, closures, primitive methods, and modules. 1.0.10-beta's
C-16 (`specs/1.0.10-beta/00-compiler-carry-over/README.md`) added front 12's steps 4.2–4.4 — a local
dependency, `@panic`/`@todo`, "no external target for the active backend" — and a cell per decision
63–66, plus the runner's tally (decision 59 (b)). 144 B-29 step H moved the suite here from
`tests/language/` (decision 466) and into one cell shape (decisions 457, 475).

**Cells describe the language, not today's compiler.** A scenario the compiler gets wrong stays as
written and is red until the compiler passes it — the suite keeps no list of known failures
(§ A red cell is red). Never rewrite a cell's answer to match current behaviour.

## Layout

```text
conformance/
├── AGENTS.md                ← you are here
├── docs.md                  ← the language reference (decisions 461, 462): its index, the text no one cell owns, the manifest schema; every example a `<!-- example: … -->` line naming a cell or a suite
├── run.sh                   ← the runner: `zig build test-conformance`, the gate's stage 9
├── modules/botopink.json    ← the workspace whose members are the cells (decision 512 (5), `"workspaces": ["*"]`):
│                              what every cell shares — here the version alone; a library's declares its cells'
│                              dependencies and targets — so a cell writes only what is its own, and every cell's
│                              dependencies share one code cache, `modules/.botopinkbuild/cache/` (decision 509)
├── modules/<cell>/          ← one cell (decisions 457, 475)
│   ├── botopink.json           its own manifest: `name` (the directory's name), `"targets"` when narrowed, path dependencies, a wasm host — no `version`, `src` or `entry` unless they differ from the workspace's defaults (the cells whose answer is located in their manifest keep it as written)
│   ├── src/main.bp             the program (`pub fn main`); more modules beside it (`mod` tree, `src/sidecars/*.erl`)
│   ├── snapshot/output/<module>.snap        the answer on every target
│   ├── snapshot/targets/<t>/<module>.snap   target <t>'s departure — only where it departs
│   ├── deps/<lib>/             a local dependency, named by a `{ "path": "deps/<lib>" }` entry
│   └── docs.md                 the reference text the cell shows, quoted from ../docs.md (decision 462)
└── test/
    ├── <area>_<group>.bp    ← `test "…" { … assert … }` blocks, run by `botopink test --json`
    └── <project>/           ← a project with a `test/` tree, run by `botopink test --json`
```

| Path | Kind | Passes when |
|---|---|---|
| `modules/<cell>/` | a cell: `botopink cell check <cell>` builds and runs it in process on every target its manifest declares (`modules/compiler-cli/AGENTS.md` § Cells) | every module's answer on every target is its accepted snapshot — `snapshot/targets/<t>/<m>.snap` where it exists, else `snapshot/output/<m>.snap`, else empty — and every target its `"targets"` leaves out refuses it on a host binding (§ Narrowing a cell) |
| `test/<area>_<group>.bp` | `test "…" { … assert … }` blocks, run by `botopink test --target <t> --json` in a scratch project on commonJS, erlang and beam | every test reports `ok` |
| `test/<project>/` | a whole project with a `test/` tree, run by `botopink test --target <t> --json`; results keyed `test/<project>::<test>`; `"targets"` in its `botopink.json` narrows it (§ Narrowing a cell) | every test reports `ok` |

A cell's `.snap` (`compiler-cli/src/cli/cell_snap.zig`, decision 475 (2)): `botopink-cell 1`, then
`refused <the compiler's error… line>` / `at <file>:<line>:<col>` / `label <text>` (decision 485: the text the
compiler prints beside the caret, as printed — absent when the caret has none, refused in an output file;
the `hint` lines are not claimed) for a refused module, or `out <line>`
(`out` alone for an empty line), `no-final-newline`, `abort` (the exit status never pinned) and
`stderr <text>` (with `abort`: the stderr contains the text). A refusal is filed under the module its
location names (`src/shapes/circle.bp` → `shapes/circle.snap`; `botopink.json:1:3` →
`botopink.json.snap`; a std module's location → `std/io/fs.snap`); an unlocated one is `main`'s.
A departure replaces the module's whole answer on that target (475 (3)).

**Where the old suite went** (144 B-29 step H, `scripts/codemod-conformance-cells.py`). Every
`run/<n>.bp`, `reject/<n>.bp` and `modules/<n>/` of `tests/language/` is `modules/<n>/` here
(`reject/smoke`, which shared its name with `run/smoke`, is `modules/smoke_refused`); a test-kind
project (`modules/<n>/` with a `test/` tree and no `expected.out`) is `test/<n>/`; `test/<n>.bp` is
`test/<n>.bp`. Each sidecar is a record:

| Old claim | Now |
|---|---|
| `run/<n>.out`, `modules/<n>/expected.out` | `out` lines (`no-final-newline` when it did not end in `\n`) in `main.snap` |
| `run/<n>.exit` (`nonzero`) | `abort` |
| `run/<n>.<t>.stderr` | `stderr <line 1>` in `main.snap` on that target — in `output/` when the targets that claim it outnumber those that do not, else a departure |
| `reject/<n>.expect` (line 1 a part of the message, line 2 `<L:C>`) | `refused <the whole error… line>` / `at src/main.bp:<L:C>` in `output/main.snap` — every target refuses |
| `run/<n>.<t>.expect`, `modules/<n>/<t>.expect` | the same records in `targets/<t>/<module>.snap` (or `output/` when every target refuses alike) |
| `run/<n>.targets`, a manifest's `"targets"` | the cell manifest's `"targets"` |

A `.expect` named a *part* of the diagnostic; a `refused` record holds the compiler's whole `error…`
line, so the migration read each refusal off `botopink cell check` and accepted it only where it
contains the old text at the old location (`codemod-conformance-cells.py accept`); its `audit`
subcommand checks every old claim against the new snapshots, cell by cell. Single-file cells are
packages named after the cell. **A cell's package name is its directory's name** (decision 511; a workspace
member's `name` is required and unique, 512 (1)): `botopink cell check` refuses a manifest with no `name`, or
whose `name` differs from the directory, located at the manifest and naming the expected name, and
`botopink cell new` writes it.
Throughout this file, `run/<n>`, `reject/<n>` and a sidecar name (`.out`, `.exit`, `.<t>.expect`,
`.<t>.stderr`, `.targets`) are how a cell's history was written; the cell is `modules/<n>`.

1.0.10-beta's `00 · 23-std-purity` step 1 (decision 107, the import tree) adds `modules/import_tree`
— a dotted path and a braced group over the package's own tree and over std, aliases bound, only the
leaves in scope, on commonJS/erlang/wasm — and three `reject/` cells: `import_name_collision` (the
second item) and `import_group_modifier` (`*` on a node that opens braces); the third,
`import_alias_on_type`, is now `modules/import_alias_on_type` — decision 110 made `as` legal on a type
and a type alias (`01-checker`), and the cell imports `Point as P`, `Pair as Two` and std's
`Dict as D` and runs on all four targets; `modules/import_alias_fn_value_beside_local` an aliased import's function value beside a local
function of the leaf's name (wasm read the bare name, the local one, until front 140's thread resolved
the alias to the owner's mangled declaration); `modules/import_alias_static_call` covers the alias in
expression position — an associated call (`P.origin()`) and a unit and a payload variant (`S.Dark`,
`S.Custom(9)`) — which inference renames to the declared type for the backends.
Step 6 (decision 110 rule 2, 111 through the namespace) adds `modules/import_std_folder_namespace`
— `import {io} from "std"` and `io.clock.nowMillis()` beside the leaf `io.clock as clock`, on
commonJS, erlang and beam, refused on wasm by STD-001 (`wasm.expect`) as the leaf form is — and
`modules/import_std_type_through_module` — `collections.Dict.empty()`, `collections.Set.fromList`,
`collections.Queue.fromList` after `import {collections}`, beside `collections.lt()` and an alias
`D`, on all four targets.
`00 · 01-checker` step 8 R2 adds `modules/import_type_closure` — `import { User, makeUser }` where
`User(role: Role)`, `Role` not named, on commonJS/erlang.
Front 24's type aliases (decision 118 rule 1) add `modules/type_alias` — `Id`, `Pair<A, B>`, `Ids` and
an `@Result` alias typing a function that only passes the value along, on all four targets — and
`modules/import_type_alias` — a `pub` alias imported like a type, the types its target names with it.
Decision 137 (`try` / `await` begin an expression) adds `modules/try_start_positions` — a `val`
initializer, a call argument, an array and a tuple element, an `if` condition, a `case` subject, a
`for` iterable, `x = …`, a `return` and `try … catch` in an argument, on all four targets — and three `reject/` cells, one per operand
shape: `try_operand_of_operator` (`total + try r`), `try_in_parentheses` (`(try r).toString()`) and
`await_operand_of_unary` (`!await ready()`).
`residual-checker-3` reads decision 137 onto `if`: an `if` expression is never an operand, and
three `reject/` cells refuse it as `if-operand` at the `if` — `if_operand_of_operator`
(`1 + if (c) { 2 } else { 3 }`), `if_in_parentheses` (`(if (c) a else b).v`) and
`if_operand_of_unary` (`-if (c) 1 else 2`). The same front adds `modules/narrow_in_logical_operands`
(the right operand of `&&` / `||` and a `while` body read the names the left operand's null test
narrows; a narrowed `var` is assigned its declared type, on all four targets) with
`modules/narrow_or_keeps_optional` and `modules/narrow_ends_at_assignment`, and two cells whose
checker half was right first and whose backend halves `residual-backend-3` closed: `modules/imported_fn_as_value` (an imported `pub fn` bound by a `val` and
passed as an argument) and `modules/enum_implements_behavior` (an enum's behavior method called
through a behavior-typed parameter). C-04's last call path adds `modules/associated_fn_default` (a
behavior's associated fn filled and reordered by label, generic included) and
`modules/associated_fn_missing_required`; decision 31 (`any` deleted) adds `modules/any_type_removed`
and `modules/host_unknown_parameter` (`std/erlang`'s host vocabulary typed `unknown` takes an `i32`,
erlang and beam); C-21 adds `modules/decorator_argument_kind` (the one decorator refusal that had no
location), and the runner now requires every `reject/` cell's `.expect` to carry its `<L:C>` line —
every refusal is located.
Decision 138 (the empty record is `type Name()`) adds `modules/type_empty_record` — `type Marker()` and
`type MathOps() { … }` constructed and called on all four targets — and two `reject/` cells,
`type_empty_braces` (`type Marker {}`), `type-without-field-list` where the `()` belongs.
Decision 329 (a namespace type) made `type MathOps { fn … }` legal when no function takes `self`:
`modules/namespace_type` (associated functions, a generic one, one calling another, through the type, on
all four targets), `modules/namespace_type_self` (the old `type_without_field_list` cell: a `self`
function, refused `namespace-type-self` at the `self`) and `modules/namespace_type_construction`
(`MathOps()` refused `namespace-type-construction` at the call); the three were refused
`type-without-field-list` by the parent binary.
Decision 307 (a derived type, `01-checker` step 28) adds `modules/derived_type_functions` (`Type.pick`,
`omit`, `partial`, `required` and `merge`, chained and nested, each constructed, read, passed as a
parameter, told apart from its source by `is` and printed by its own name, on all four targets),
`modules/derived_type_decorated` (a decorator on the `val` sees a type whose fields keep the source's
annotations, `partial`'s typed `?T`) and `modules/derived_type_imported` (an exported
`Type.merge` as a parameter type and a constructor, a module deriving from an imported record and
from an imported derived type), with eleven `reject/derived_type_*` cells — a string field, an
unknown field, a field named twice, no field, an `omit` leaving none, an enum and a primitive
source, a field on both sides of a `merge`, the call in a body, a `var`, and the bare `partial(…)`
(an unbound name); every one red on the parent binary.
`modules/derived_type_two_packages` derives over two packages' same-named modules: dependencies `a`
and `b` each hold `shape` with a record `Box` of different fields, each package's `user` derives
from its own `Box` (`Type.pick` in `a`, `Type.omit` in `b`) and the project has a `shape` of its
own — the imported source is found by its module's key (the package plus the path, decisions 170
and 337), four targets; read by basename, `b`'s `omit(Box, .depth)` met `a`'s `Box` (`unknown field
'depth'`).
Decision 330 (7) (a type in a type is its associated type) adds `modules/assoc_type_declared_in_body` (a
sibling's `Shape` declares `Point` with a method, the enum `Kind` and the generic `Box<T>` in its body;
`main` constructs, annotates, matches and prints them through `Shape.`, four targets),
`modules/std_type_field_associated` (std's `Type.Field<T>` as a parameter type after `import {types.Type}
from "std"`, four targets) and `modules/assoc_type_named_like_member` (`pub type Point` beside `pub fn
Point`, `assoc-type-duplicate` at the type's name); the three were parse errors or `unknown type` on the
parent binary.
Decision 330 (`?T` read with TypeScript's operators, `01-checker` step 31) adds `modules/optional_operators`
(`?.[i]`, `?.` flattened, the postfix `!` over a present value, four targets),
`modules/optional_call_operator` (`f?.(args)`; wasm refuses a `?.()` over a function answering a plain
value by `wasm.expect` — `05-wasm`'s row) and `modules/optional_bang_aborts` (`find("b")!` aborts after
`found` is printed — `.exit`; commonJS's stderr names `value is null — find("b")! at
src/main.bp:11:12`; erlang and beam abort with the text as an Erlang binary and wasm without it — the
backends' rows), and six `reject/` cells: `optional_operator_never_null` (`s?.length()`
with `s: string`), `nullish_never_null` (`s ?? "fallback"`), `bang_never_null` (`n!`) — each
`optional-operator-never-null` at the operator —, `nullish_beside_logical` (`flag ?? false && true`,
at the `??`), `optional_has_no_methods` (`.unwrapOr` on a `?string`) and `result_namespace_removed`
(`result.isOk(…)` is an unbound `result`). `modules/option_expect_removed` now answers
`optional-has-no-methods`. Every one was refused or accepted otherwise by the parent binary. The
suite's `.unwrapOr` on a `?T` became `??` (`scripts/codemod-optional-operators.py`), and a second
index of an index (`rows[1][0]`, `xs[k]` answering `?T`) is `rows[1]?.[0]` (`modules/index_expression`,
`modules/array_windows`). A method after a `?.` link continues its chain (`e?.key.length()`,
`modules/optional_chain_method`): the chain runs under the `?.`'s guard.
`modules/optional_member_default` — `xs.at(k)?.field ?? d` over a present and an absent element, a string
field, an empty array, an array built by `map` and one passed in, four targets (wasm printed the
element's address for the `map`-built array on the parent binary).
Decision 267 (a variadic parameter `..name: T[]`, front 134 step 4) adds `modules/variadic_parameter` (a free
function with zero, one and three variadic arguments, a generic one, a method, an associated function, `@print`
with two arguments — four targets), `modules/variadic_parameter_host` (a `declare fn` bound to `Math.max` /
`lists:max`; wasm refuses it at the first call by `wasm.expect`), `modules/variadic_across_modules` (an
imported variadic `pub fn`, four targets) and six `reject/` cells: `variadic_not_last`, `variadic_twice`,
`variadic_default`, `variadic_not_array` (parse refusals at the declaration), `variadic_spread_at_call`
(`variadic-spread`) and `variadic_label` (`variadic-label`). Every one was
refused or accepted otherwise by the parent binary. Decision 354 (step 6, contexts — it replaced 269's
`@getContext(T)`, whose `reject/getcontext_without_use` left) adds `modules/context_provide_read` (a provider
reaches a component two renders below it; a `@Component` read with `use` reads its caller's map; a body
does not see its own provide), `modules/context_nearest_wins` (the nearest provider wins, a sibling does not
see another's) and `modules/context_unbound` (`context-unbound` at run time, `.exit` nonzero and the
message on stderr) — erlang, beam and commonJS run them, the wasm backend refuses the `use` where it is
written (`.wasm.expect`, `language-gaps.md`); and the refusals `modules/component_base_parameter`
(`@Component<C, R>` at the base), `modules/context_marker_removed`, `modules/renderable_type_argument`,
`modules/getcontext_removed`, `modules/context_provide_in_hook`, `modules/context_provide_after_render`,
`modules/context_hook_without_use`, `modules/context_hook_as_value`, `modules/context_not_declared`,
`modules/context_val_alias`, `modules/context_read_of_parameter`, `modules/use_in_comptime_block`,
`modules/use_in_decorator_body` and `modules/use_in_template_body` (`use-outside-render-tree`), each red on
the parent binary. Decision 354 took the base out of the wrapper, so `reject/component_two_bases`,
`reject/use_two_bases`, `reject/use_owner_mismatch` (decision 96's one base per body) and the arity
cells `reject/component_one_type_argument` / `reject/context_two_type_arguments` left with it.
Decisions 352 and 354, as `styled` registers through them (`08-bpp/119` step 1), add
`modules/context_sheet_registers` — a context whose value holds a writer function, provided at the root; a
component computed at render reads it at its body's top and hands the writer its rule each time it
runs; a component run through a function value under a provider that keeps nothing registers nothing,
one that reads no context registers nothing — and `modules/context_sheet_unbound` (`context-unbound`
naming the context, `.exit` and the three `.stderr`s); erlang, beam and commonJS run them, wasm refuses
the first `use` (`.wasm.expect`).
Decision 388 (a `@Component` is a lambda over a `RenderScope`, `01-compiler/134` step 6 box 4b) replaced
374's capture: `run/context_host_thunk` left with it, and `modules/render_scope_library` holds the scope in
the library instead — a renderer that runs the root with `RenderScope.root()` and each child with the
scope its parent's `run` answered, hands a host a thunk `{ -> c.run(scope) }` at once and keeps one the
host runs twice after the render. `modules/component_is_lambda` (a call runs nothing; `itens.map(Card)`
answers lambdas a tree's runner runs with `Lista`'s scope; generic code keeps them), `modules/component_run_root`
(`c.run(scope)` answers the result and the children's scope; `await c` outside every body runs it with
`RenderScope.root()`), `modules/component_try_in_body` (a bare `try` in a `@Component<@Result<…>>` body),
`modules/component_alias_answers_value` (a function typed by an alias of `@Component` is no component body, 118:
it answers the lambda another body made — `styled`'s `-> StyledView`) and
`modules/render_scope_construction` (`RenderScope(…)` refused, `render-scope-construction`) cover the rest;
erlang, beam and commonJS run them, and the wasm backend refuses every module the scope lowering reached
at its first component (`.wasm.expect` on every component cell, `language-gaps.md` row 354-wasm). A
component called as a statement outside a body runs nothing now, so `modules/effect_chain`,
`modules/effect_context_await`, `modules/use_one_base`, `modules/component_result_try_await` and
`modules/component_hook_and_component` `await` it in `main`, and `modules/component_sync_plain_function` reads
375's mark through `run`. Decision 389 (a component named as a value is a reached node; a value the checker
cannot follow an edge with `callee: null`) adds `modules/decl_hooks_component_value` (`map(Card)`, a `val`, a
record field, a lambda answering one) and `modules/decl_hooks_dynamic_call` (a parameter, a method and a
generic answer as `null` edges, the node asynchronous), each red on the parent binary; the `decl.hooks`
readers of the other cells read `HookCall.callee` as the `?Declared<unknown>` it is now.
Decision 375 (`HookNode.async`) adds `modules/decl_hooks_async` (a synchronous `Card` and `Header`, an awaiting
`Comments`, a page `async` through it with no written `await`, a cycle, a function value) and
`modules/decl_hooks_async_imported` (an imported node's mark) on the four targets, and
`modules/component_sync_plain_function` (commonJS only, `.targets` — the host `pending` has only a Node binding:
a call of a synchronous `Card` answers no `Promise`, one of the asynchronous `Post` does); each red on the
parent binary.
Decision 357 (the rules of hooks) adds `modules/use_in_if`, `modules/use_in_loop`, `modules/use_in_lambda`
and `modules/use_after_early_return` (`use-not-top-level`, naming the construct or the line) and
`modules/use_conditional_argument` (a condition inside `use provide`'s argument, an `if` that does not
return before a `use`); `modules/use_after_return` and `modules/generator_loop_use` now meet
`use-not-top-level`, and `reject/use_inside_branch` / `reject/use_in_closure` left for `use_in_if` /
`use_in_lambda`.
Decision 277 (`decl.hooks`, `01-checker` step 23) adds `modules/decl_hooks_direct` (a host hook: one node;
commonJS, erlang and beam — `session` has no wasm binding), `modules/decl_hooks_all_nodes` (four nodes, a
component once, calls in body order), `modules/decl_hooks_custom_hook` (a hook's own node),
`modules/decl_hooks_cycle` (an edge back), `modules/decl_hooks_function_value` (`hook: null`),
`modules/decl_hooks_type_args` (a `use`'s type arguments with their fields, decision 293),
`modules/decl_hooks_context` (each `provide` / `context` with its context object, 354 (4); wasm refuses the
`use`) and `modules/decl_hooks_imported` (another module's nodes, a hook through an alias with its own
annotations), on the four targets but where named; each red on the parent binary (`unknown field 'hooks'`).
Decision 371 (`Decorator.same`) adds `modules/decorator_same` — a package `web` whose `check` compares
each annotation's `decorator` with `serverOnly` and with itself: `#[srv]` under `import {serverOnly as srv}
from "web"` is `web`'s, the project's own `serverOnly` reached as `#[local.serverOnly]` is another
declaration (`other`); four targets — and `modules/decorator_same_not_decorator` (`same("serverOnly")`, a
type mismatch at the argument); the parent binary had no `same`. Decision 372 (a `.hooks` reader runs
after the module's bodies) adds `modules/decl_hooks_reads_member` — `#[graph]`'s `Page` calls
`Account(…).validate()`, which `#[check]` adds below it; four targets, red on the parent binary
(`'validate' is not declared`) — and `modules/decorator_hooks_output` (`decl.addMember` in a decorator
reading `decl.hooks`, `decorator-hooks-output` at the call; accepted by the parent binary),
`modules/decorator_hooks_output_member_fn` (the same refusal of decision 370's typed
`decl.addMember(name, fn…)`) and
`modules/typeinfo_all_hooks_reader` (`@TypeInfo.all(with: graph)` in the module of `#[graph]`'s `Page`;
answered by the parent binary).
Decision 139 (a negative index counts from the end) adds `modules/index_negative_from_end` — `xs.at(-1)`,
`xs.at(-3)`, `xs.at(-4)` / `xs.at(3)` absent, `xs[-2]`, a negative index held in a `val`, the same for
`String.at` / `s[-2]`, and a string array — on all four targets.
Decision 140 adds `modules/pub_val_across_modules` — a module-level `pub val` of a record, an enum,
an array, a primitive and a lambda imported from a sibling, one under an alias, read from `main`, a
function and a method; the module bodies of `base` (imported only by `config`) and `config` run
before `main`, dependencies first, and a val read twice is evaluated once — on all four targets.
`modules/import_same_name_from_two_packages` — two dependencies (`web`, and `ui`) each declare
`Response` and `ok`, a third (`webapp`) imports `{Response, ok} from "web"`, and `main` imports
`served` from `webapp` and `ok` from `ui`: a package handle narrows a name to the one module of that
package declaring it, in the consumer and inside a dependency, on commonJS and erlang (both modules
were refused as `ambiguous-import-use` on the parent binary).
`01-checker` (an import that names its module says which declaration it means) adds eight `modules/`
cells, on all four targets. `import_same_fn_name_by_module` — `app/page` and `app/blog/page` each
declare `pub fn title`; `main` imports it as `app.page.title` and a third module as
`app.blog.page.title` (decision 206's brace form — they were `from "app.page"` / `from
"app.blog.page"`), and the two answers differ; `import {app.blog.page};` binds the namespace
`app/blog/page` (an unbound `page` on the parent binary). `import_same_fn_name_two_aliases` — `NotFound` from
`app.not_found` and from `app.blog.not_found` in one module, each under its own alias, both called
(a generated route table's shape). `import_same_fn_name_in_dependency` — the same inside a
dependency, whose own module names a sibling by the path below the package (`app.page.title` for
`site/app/page`), beside a consumer naming the other by the package-qualified path (`from
"site.app.blog.page"`). The three were refused as `ambiguous-import-use` on the parent binary: a
dotted source was compared byte for byte with the module's `/` path and named nothing, and a path
below the importer's package had no reading.
`import_ambiguous_from_package` is the refusal that stays — `import {NotFound} from "site"` names a
package two of whose modules declare the name, so the use is `ambiguous-import-use`, located, naming
both, by `<target>.expect`. `transitive_package_import` (front 26 step 3, decision 242) — the
package declares `starter`, `starter` declares `core`, and `from "core"` in the package is refused
`unresolved import source "core" — declare it in botopink.json "dependencies"` at the source
string, by `<target>.expect` on all four targets: only a direct dependency is importable.
`dependency_imports_undeclared_package` — the same refusal inside a dependency: `starter` imports
`from "core"` without declaring it (the package declares both), and the build refuses it at
`deps/starter/src/root.bp:1:21`, as `starter`'s own build does, where it used to compile the
import with nothing bound and answer `unbound variable 'greet'`.
Decision 309 adds `import_own_package_with_from` — the package `shapes` imports its module
`geometry` as `from "shapes"`, refused `error[module-import-with-from]: "shapes" is this package —
write import {geometry.area};` at the source string on all four targets (the parent answered
`unresolved import source "shapes"`) — and `dependency_imports_itself_with_from`, the same refusal
inside a dependency (`starter`'s `root.bp` imports `from "starter"`, located at
`deps/starter/src/root.bp:2:27`). A `test/` module importing its own package by name is
`modules/compiler-cli/tests/cli_contract.sh`'s (a project cell with a `test/` tree has no refusal
form).
`import_sibling_path_beside_std_name` — a dependency's module imports a
type and two functions as `sort.queue.…` (its sibling, `kit/sort/queue`) in a program that also
loads `std/collections`, which declares the three names: the dependency was refused ("`Queue` is
declared `pub` by `std/collections` and by `kit/sort/queue`, and this import does not say which") while
a path of several segments below the importer's package named nothing.
`import_own_module_over_dependency_path` is that reading's boundary: the project's own `app/page` is
what `import {app.page.title};` names although the dependency's `site/app/page` declares the name too — the
full path is read first (it passes on the parent binary; it guards the order of the two readings).
`import_same_name_twice_unaliased` is the use that cannot tell: `import {app.page.title};
import {app.blog.page.title};` is `import-name-collision` at the second item, naming both
modules, by `<target>.expect` — the second import used to replace the first and commonJS answered
`app` where erlang and wasm answered `blog`. `import_same_fn_name_std_and_package_aliases` — a package
and `std/collections` both declare `lt` and `reverse`; one module imports each under an alias and
calls the four (it passes on the parent binary; it pins the rule).
1.0.11-beta `01-checker` step 1 (decision 150, D5) adds `modules/array_literal_union` (`[1, "a"]` is
`(i32 | string)[]`, an expected union takes its members; four targets), `modules/array_literal_numeric_join`
(`[1, 2.5]` is `f64[]` — the `1` is `1.0` on every target — and `[1, null]` is `?i32[]`),
`modules/array_literal_union_misuse` (an element used as an `i32` without narrowing, refused at the use
naming the widening element) and `test/case_value_union` (a `case` whose arms disagree is the union,
read back through `case` narrowing, beside the array literal's union). The `case` half is a `test/`
cell because wasm traps on a union of primitives produced by a `case` (`05-wasm`'s row); each array
cell was refused by the parent binary.
Step 2 (rows 28 and 31) adds `modules/case_function_typed_arms` (two arms answering `fn(string) -> string`
join into that type and the result is applied, four targets), `modules/case_function_arms_arity` (arms
whose arity differs are refused at the second) and `test/case_arm_lambda_value` (`A(x) -> { item ->
f(item) }` is a lambda value; a `test/` cell because beam answered `{badfun, ok}` for a lambda a `case`
arm produces — `03-beam`'s row). Each was refused by the parent binary. `03-beam` step 9 moved the
last to `modules/case_arm_lambda_value` (four targets print `a?` / `b`) and deleted row 28.
Step 3 (decision 151, row 22) adds `modules/section_body_method` (a `fn` in a section body is
`section-body-method` at the `fn`), `modules/section_numeric_leaf_standalone` (`val n: Tok.Percent =
.50;`, a leaf argument, and a section-typed field of a payload variant built with `.100`, four
targets) and `modules/section_numeric_leaf_without_expectation` (`.50` with nothing expected names its
section). A section leaf prints as its mangled name (`__Tok__Percent.__50`) on every target, so the
cell reads it through `==`. Each was refused by the parent binary.
Step 4 (row 32) adds `modules/call_of_record_value` (`val g = G(a: "x"); g()` is
`callee-not-a-function` at `g(`, beside a constructor and a function-typed field that still check)
and `modules/call_of_imported_record_value` (the same through a sibling's `pub val`, by
`<target>.expect` on all four); both were accepted by the parent binary.
Step 5 (decision 152) adds `modules/binding_redeclared_in_body` (a second `var n` in one body) and
`modules/binding_shadows_parameter` (`val x` over the parameter `x`), both `binding-redeclared` at the
second binding and both accepted by the parent binary. Decision 205 (the body is the whole function)
adds `modules/binding_shadows_in_inner_block` (an inner block's `val y` over the function's `y`) and
`modules/case_arm_binder_reuses_name` (a `case` arm's `Square(s)` over the parameter `s`), both
accepted by the parent binary. `04-js` step 4 adds the half decision 205 keeps,
`modules/sibling_blocks_bind_one_name`: an `if` and its `else`, two `if`s, two loop bodies and two
`case` arms' binders each binding one name, and a block's `n` followed by the function's own `n`
once the block has closed — four targets, green on the parent binary (it pins that no backend
leaks a block's binding or invents a scope for it).
`modules/unwrap_or_literal_width` (another front's finding) — an integer literal as `unwrapOr`'s default
takes the payload's width over `?i64` and `@Result<i64, string>` (refused as `expected i32, got i64`
by the parent binary).
`modules/std_type_ctor_through_namespace` (another front's finding) — `url.Url(…)` after `import {url}
from "std"` constructs the type through the module namespace, as the leaf `Url(…)` does (`this "std"
module has no such public function` on the parent binary), four targets.
Decision 170's type half (other fronts' findings) adds `modules/std_namespace_beside_own_type` (a
module's own `type Dict` beside `import {collections}` is the module's, four targets),
`modules/std_namespace_beside_aliased_type` (`import {kit.store.Dict as OwnDict}` beside the same
namespace reads `kit/store`'s fields; the cell builds the value through a function of `kit/store`,
because commonJS emits `Dict(5)` without `new` for an imported record constructor beside a std
namespace declaring the same name — `04-js`'s row),
`modules/std_namespace_signature_names_shadowed_type` (a namespace call whose signature names the
shadowed std type), `modules/import_two_types_one_name` and `modules/own_type_beside_std_type_import`
(two types of one declared name in one module, aliased or not, are `import-name-collision`). Each
was accepted wrongly or refused with the wrong type by the parent binary.
`modules/behavior_default_fn_body_checked` and `test/behavior_default_fn_result` (another front's
finding) — a behavior's `default fn` body is checked (an unbound call is refused at it), and a
`-> @Result` default fn wraps its `return` and `throw`, its adopted call answering the `@Result`; a
`test/` cell because beam answers `{unresolved_method, …}` for any adopted default (`03-beam`'s row).
Step 12 (T9) adds `modules/reserved_word_as_binding_name` — `val unknown: i32 = 1;` is
`reserved-word-as-name` at the name; it passes on the parent binary too (the row closed before this
front) and pins the rule.
Step 11 (T11) adds `modules/nullish_tuple_operand` (a tuple literal on the right of `??`) and
`modules/postfix_on_grouped_nullish` (`(xs.at(0) ?? d)._1`), four targets, integer elements because wasm
reads a `string` element of a tuple through `??` as its address (`05-wasm`'s row); both refused by
the parent binary at the `#`.
Step 8 (decision 45) adds `modules/tuple_label_on_optional` (`rs.at(0).b` names `?.`) and
`modules/tuple_label_through_optional` (`rs.at(0)?.b` reads the label through the optional, four
targets); both pass on the parent binary — the checker half landed with decision 45 — and pin it. The
absent half (`?.b` on a `null`) traps on wasm and raises `badarg` on beam (the backends' rows).
Step 15 (report L, R3) adds `modules/imported_type_field_closure` (package `a`'s `Client(life:
Life, …)` with `Life` in a sibling module, imported by package `b` as `Client` alone and called from
the root, four targets) and `modules/imported_declaration_error_location` (a type error inside the
dependency's declaration is located at `a/client.bp`, by `<target>.expect`). Both pass on the parent
binary — the row no longer reproduces at this base, and rakun-metrics' `export_test` passes with its
`CacheLife` workaround removed — and pin it.
Step 6 (decision 147) adds `modules/try_in_lambda_without_result` (`[1, 2].forEach({ x -> try
bad(x); })` refused at the `try`) and `modules/lambda_result_return_try` (a lambda under an expected
`fn(x: i32) -> @Result<i32, string>` — a `val` annotation and a parameter — `try`s, `return`s and
`throw`s, four targets); the parent binary accepted the first and refused the second. A
`throw_in_case_arm_result` cell is not added: erlang answers `false` for `isError()` on the arm's
`throw` (`02-erlang`'s row), the other three answer `true`.
`modules/generic_ctor_fallible_lambda_fresh` (decision 147 beside a generic constructor) — two methods of
`Box<T>` each build a `Box(run: { … })` under the fallible field, one `Box<?T>`, one
`Box<Array<T>>`, on all four targets; the parent binary refused the second as `expected ?_[], got
?_` (the lambda's expectation was the constructor's registration-time cells).
The cell `modules/shorthand_import_beside_bundled_package` (decision 170) was deleted with decision
326: its subject — a shorthand import beside a bundled package — left when `routing` stopped being
bundled, and the shorthand itself goes with decision 337 (`01-compiler/129`).
Decision 337 (`01-compiler/129` steps 1–2) adds `modules/mod_binds_namespace` (`mod config;` binds
`config`: a call, a function as a value, a type in a signature, a constructor and a variant path,
no import), `modules/mod_namespace_cascade` (`mod geo;` alone reaches `geo.plane.distance(…)` and
`geo.plane.Point` through `geo/mod.bp`'s `pub mod plane;`), `modules/mod_reexport_by_val` (a
folder's `mod.bp` re-exports by value and by type — `pub val splitPath = split.splitPath;`, `pub
type Pair = split.Pair;` — the submodule private, the type `split`'s own), and
`modules/import_nested_module_namespace` (`import {store.cache};` in a sibling binds `cache`), all
four targets; four refusals on every target by `<target>.expect` — `private_module_through_namespace`
(`geo.plane` through a plain `mod plane;`, `private-module` at `plane`), `redundant_module_import`
(`import {config};` beside `pub mod config;`), `declaration_named_like_module` (`fn config()` beside
`mod config;`, `import-name-collision`) and `shorthand_import_one_candidate` (`import {splitPath};`,
`shorthand-import`, the fix `import {config.splitPath};`) — and `modules/shorthand_import` (no module
declares the name: `unresolved import`). They are `modules/` cells, not `reject/` ones: each needs a
second module. The shorthands the suite wrote are their module paths now (`dependency_files_order`,
`sibling_import_in_a_dependency`); an `import {m};` beside `pub mod m;` is gone (`decl_hooks_imported`,
`decl_hooks_async_imported`, `decorator_meta_import`, `decorator_same`, `labelled_call_by_label`,
`namespace_import_module`), and an item named like the module `mod` binds is aliased
(`default_argument_across_modules`' `pad.pad as padTo`, `default_argument_open_across_modules`'
`greet.greet as greetFrom`, `external_method_imported`'s `meter.meter as newMeter`) — the second
binding of one name is `import-name-collision`.
Step 7 (decision 148) adds `modules/captured_var_write_in_lambda` (`run({ -> n = n + 1; 1; }, 0)` is
`captured-var-write` at `n =`; accepted by the parent binary) and `modules/closure_capture_statement_position`
(a `forEach` body, a local closure called as a statement — directly, in a `for` body and in a
`forEach` body — and a module-level `var` written from any lambda, four targets; it passes on the
parent binary too and pins the legal shapes).
`modules/generic_index_answers_optional` and `modules/generic_index_optional_return` (another front's
finding) — `return xs[0];` under `-> T` is the type mismatch naming `T` and `?T` (it was `recursive type
detected`), and the same functions declared `-> ?T` run on four targets.
Decision 207 (an inline parameter type) adds `modules/inline_param_type` (built from the call's labels in
any order with a default left out, forwarded, beside an ordinary parameter, four targets), the parser's
refusals `reject/inline_type_in_{return,field,val_annotation}` (`inline-type-outside-parameter`), the
checker's `modules/inline_type_on_method_param`, `modules/inline_type_twice_on_one_fn`,
`modules/inline_type_field_named_like_param` (`inline-type-position`), `modules/inline_type_missing_field`
and `modules/inline_type_unknown_field` (named by the owner, ``the props of `link` ``), and
`modules/inline_type_across_modules` (a call from another module that writes the fields is refused;
the declaring module's own call runs). All sixteen fail on the parent binary.
Decision 208 (`Ok` / `Error` are never constructors) adds `modules/result_ok_constructor` and
`modules/result_error_constructor` — `unbound variable` at the name; both pass on the parent binary and
pin the rule.
Decision 209 adds `run/integer_literal_fits_f64` (an integer literal under an expected `f64` — a
`val`, an `f64[]` element, an argument, a return, an arithmetic operand — prints as the float, four
targets; refused by the parent binary) and `modules/i32_value_never_widens` (an `i32` value passed to an
`f64` parameter is the mismatch; it passes on the parent binary and pins the half that stays).
Decision 215 adds `modules/f64_equals_integer_literal` (`x == 2` with `x: f64`) and
`modules/f64_not_equals_integer_literal` (`3 != x`), refused at the literal naming the float to write;
the beam codegen test `is and == read numbers by value …` no longer prints `2.0 == 2` (it answered
`false`). Both accepted by the parent binary.
Decision 255 (1) (a type application before a member) adds `modules/type_application_static_member` —
`Dict<string, unknown>.empty()`, `Dict<string, i32>.empty()` chained, `Box<i32>.make(7)`,
`Opt<string>.None` and `Opt<i32>.Some(3)`, beside `a < b`, `x < y && z > w` and
`both(a < b, y > x)` that stay comparisons, on all four targets — and four `reject/` cells:
`type_application_argument_mismatch` (`Box<i32>.make("x")`, at the argument),
`type_application_argument_count` (`Box<i32, string>`, at the name),
`type_application_variant_payload_mismatch` (`Opt<i32>.Some("a")`) and
`type_application_on_a_field` (`Box<i32>.value` — only a unit variant is read without a call). All
five fail on the parent binary (`unexpected ','` / a comparison).
Decision 255 (2) (`comptime <expr>` is `comptime { break <expr>; }`) adds `modules/comptime_expression_is_block`
(a module-level shorthand equal to its block form, and the same in a body) and
`modules/comptime_expression_static_call` (the decision's own `val d: Dict<string, unknown> = comptime
Dict.empty();` beside its block form), and `modules/comptime_expression_type_mismatch` (the
expression's type is the form's, located at `comptime` as the block's is).
Decisions 266 and 331 (`01-checker` step 21 — every `comptime` runs on the comptime runtime, BEAM or
WAT by the target, never on the target, and its value is written into the program) give
`modules/comptime_expression_static_call` all four targets (its `.wasm.expect` is gone: the `Dict` is
written as its constructor) and add `modules/comptime_block_with_loop` (`comptime two()` emits `2`; a
block with a call and a loop answers `6`; a loop pushing strings answers the array — one `.out` on
the four targets; the parent binary refused the block on erlang, read `d` unbound on commonJS and
had no wasm lowering), `modules/comptime_val_after_import` (step 20's finding: a module-level
`comptime` `val` after an import, dropped on commonJS by the parent binary; a call and a record at
module level), `modules/comptime_function_reference` (a `Dict` of a declared function and a lambda
reading nothing the block declares, written back as the reference and the lambda — rakun's bean
catalogue shape) and `modules/comptime_value_not_liftable` (a lambda capturing the block's `val`,
`comptime-value-not-liftable` at the `comptime`; the resource half is `block_eval.zig`'s unit test —
the WAT runtime has no process to answer, so no one cell refuses it the same way on both runtimes).
06-emilia/34 step 5's two comptime rows (a nested-section enum value at comptime; emilia's dispatcher
at comptime) add `modules/comptime_enum_section_value` (`.Pad.All.8` as an argument, in an array, inside
a payload variant, and written back from `comptime first(…)`, `comptime padX()` and an array — four
targets; the parent binary raised `{error,{badmap,'Pad'}}`), `modules/comptime_decorator_section_value`
(`#[mark(.Pad.All.4, .Bold, Tok.Pad.All.8)]` read as `tokens.value`, and a function the decorator
reaches writing `.Pad.All.8`; the parent raised `{badmap,'Pad'}` at the annotation),
`modules/comptime_imported_section_path` (an imported enum's section value from an imported function
and back into this module; the parent's comptime module called an undefined `Pad/1`),
`modules/comptime_section_path_declared_after` (a section path in a function declared after the
`comptime` that reaches it, refused naming the path and the function, as a template call there is)
and `modules/comptime_record_pattern` (a record matched on the comptime runtime as its untagged map — a
constructor pattern in an arm and in a `val`, `is`, an arm naming `Block`, a record and a section's
variant; the parent's lowering failed `MissingPackage`).
`01-compiler/14` step 6 (decisions 341, 343) adds `modules/decorator_host_cells` (a decorator body calls
a host function with both cells and std's `hash.contentHash` through its namespace and a leaf
import — the wasm comptime runtime runs `bang`'s `@External.Wasm("fn:…")` cell (its Erlang cell never runs at
build, decision 452) and `contentHash` as std-wasm's, for every target; four targets, one output; the parent binary was `call to undefined function bang/1`),
`modules/decorator_imported_host_function` (the same through an imported function and an imported
decorator: the export carries its host and std functions),
`modules/comptime_host_cell_unavailable` (decisions 434 (4), 452: a host function with neither a `std:` nor a
`fn:` cell, refused at the call naming both — was `reject/decorator_host_cell_missing`),
`modules/comptime_host_cell_unavailable_erlang_only` (decision 452: a host function with an `@External.Erlang`
cell alone is refused the same way, the cell never run at build — was `reject/comptime_beam_call_not_converted`;
the former run cell `modules/decorator_erlang_cell_only` is this reject),
`modules/comptime_erlang_cell_ignored_fn_serves` (decision 452: an Erlang cell beside a `fn:` cell is ignored, the
`fn:` body answers on the four targets — was `reject/comptime_beam_call_not_converted_fn_after`, decision 439,
which no longer applies),
`modules/external_wasm_std_outside_std` (decision 445: a `std:` cell is std's alone — outside
`libs/std` it is refused at the annotation on every target, naming the std function to call
instead; it replaced `external_wasm_std_unknown` and `external_wasm_std_types`, whose refusals —
a name std-wasm lacks, other types — only std can now meet, pinned in `codegen/tests/wat.zig`
over a module of std's own),
`modules/comptime_random_unseeded` (decision 451 (3): at comptime a draw of `io/random`'s seeded
stream before any `seed` is refused at the `comptime` that reached it — a build has no entropy)
beside `modules/comptime_random_seeded` (the seeded draws at comptime, std-wasm's Mulberry32, the
same text on all four targets),
`modules/decorator_writes_module_var` (`decorator-writes-module-var` at the write, through a function
of the module; the parent binary said `unbound variable`) and `modules/typeinfo_all_duplicate_at_entry`
(two commands of one name refused at the entry point's `@TypeInfo.all`, naming both). Step 8 adds
`modules/comptime_std_host_function` (`comptime hash.contentHash(…)`, T19, four targets — the parent
binary refused `.contentHash(…)`) and `modules/hole_imported_val_known_at_build` (a hole naming an
imported `val` known at build is written at build; the parent binary computed it at render), and
`modules/comptime_reaches_use` (question `14s8-e` (a): a `comptime` calling a component that reads a
context is refused naming the `use`).
`01-compiler/14` step 8 (decision 355) adds `modules/styled_holes_known_at_build` (a template of the
cell's own reads each hole's `known` / `value`: a literal, a `val`, another expansion with no
run-time hole and a `comptime` are written at build, a parameter and a call computed at render —
four targets; the parent binary fails the body at `badkey known`), `modules/comptime_reaches_package_template`
(a `comptime` over a package template's expansion, whose built code calls the package's function
under its alias, and a record of the package's type written back where the module does not import
it — the parent binary aborted the compiler), `modules/comptime_interpolation_in_called_fn` (`"${…}"` in
a function a `comptime` calls), `modules/comptime_template_call_declared_after` and
`modules/hole_known_at_build_raises`.
`01-checker` step 41 (decision 429) adds `modules/template_two_alike_expansions` (two expansions of one
template whose built code sits at the same offsets — `r.length` over an array and `r.w` over a
record; the parent binary lowered the first with the second's field access on erlang),
`modules/template_default_arg_two_expansions` (a call that leaves out a default argument and a call of a
one-parameter function at the same offset of two expansions; the parent binary filled the default
into the second, `footer/2 undefined` on erlang) — four targets, no padding — and
`modules/template_built_code_diagnostic_located` (a diagnostic in built code at the literal's line and
column plus its offset; the parent binary located it at `1:20`).
`test/program_primitive_behavior_extends_std` and `modules/program_primitive_behavior_redeclares_std`
(another front's finding) — a program's own `behavior String` adds members to std's `String` (its
default fns call `slice`, `startsWith`, `length` on `self`, and std's members answer beside them),
and redeclaring a std member is `behavior-member-redeclared`. `modules/program_primitive_behavior_extends_std`
is its `run/` twin on all four targets (`botopink test` runs neither wasm nor beam), a
`behavior Number` default beside it; wasm called no program-declared default fn of a primitive
(it trapped) until `05-wasm`'s `lowerPrimDefault`. Both refused by the parent binary.
`modules/program_array_behavior_default` does the same for a program's `behavior Array<T>` — defaults
calling std's `at` / `length` / `filter` / `all` / `contains` / `join` on `self`, taking a `T` and a
`Self<T>`, answering `?T`, `T`, `Self<T>`, a bool and a string over integers, strings and records —
on all four targets (wasm trapped: the copy did not substitute `Self<T>`).
Decision 206 (`from` names a package — std or a declared dependency — and a
module of the importing package is imported by its path inside the braces) adds three `modules/`
cells. `import_own_module_with_from` is the refusal: `import {area, perimeter as around} from
"geometry";` over the package's own `geometry` is `error[module-import-with-from]` at the source
string, writing the brace form, by `<target>.expect` on all four targets (it compiled and ran on the
parent binary). `import_bundled_package_beside_own_module` — a package with a module `log` of its own
imports `{Level, levelName} from "log"` and reaches the dependency `log` (a `deps/log` fixture
declared by `path` since decision 326 took `log` out of the compiler), and `log.levelName as
ownLevelName` reaches its module; on all four targets — the fixture is pure, so the wasm
narrowing the bundled `log`'s host functions needed went with it (refused on the parent binary:
`Level` "not exported by the named module" `log`).
`import_module_path_in_braces` — nested paths (`components.card.Card`,
`reliability.policy.nextDelay as policyDelay`) beside a local `nextDelay`, on all four targets. The
suite's own imports of a module of their package were migrated by
`scripts/codemod-import-without-from.py`; `method_on_unimported_type` is the case that showed the
need: its `import {logger} from "log";`, meant for its own `log.bp`, loaded the then-bundled `log`.
Decision 141 adds `modules/external_template_refused_on_beam` — an `@External.Erlang` template with a
macro runs on erlang and is a located build error on beam naming the construct (`.beam.expect`); beam
no longer evaluates a template it cannot compile from source at run time.
Decision 216 (front `130-decorator-outputs`, what a decorator produces) adds, for its first place —
`decl.addMember(source)`, a member of the annotated type — `modules/decorator_add_member` (an associated
fn and a method added by a type's decorator and one added by a field's, beside a hand-written
member) and `modules/decorator_add_member_import` (the members travel with the type: an importer
calls `City.fromRow(r)` through a plain import and an alias), on all four targets, and three
`reject/` cells at the annotation: `decorator_add_member_on_fn` (`decorator-member-without-type`),
`decorator_add_member_duplicate` (`decorator-member-duplicate`) and `decorator_add_member_not_one`
(`decorator-member-not-one-fn`), and one where the call is written: `decorator_member_unknown`
(`unknown-associated-fn` — a type's members are closed, so `City.revisions()` on a type no
decorator gave it is refused). Its second place — `decl.setMeta(key, value)`, read as
`@typeInfo(X).meta.<decorator>.<key>` — adds `modules/decorator_set_meta` (two decorators' keys on a
type, a `fn`'s meta, `.name`, a read held in a typed `val` and continued by `.length`) and
`modules/decorator_meta_import` (meta read through a plain import, an alias and a namespace import),
on all four targets, and four `reject/` cells: `typeinfo_meta_missing` and
`typeinfo_unknown_declaration` where the read is written, `decorator_meta_duplicate` and
`decorator_meta_on_member` at the annotation. Its third place — `decl.addType(name, source)`, an
associated type named `Owner.Name` — adds `modules/decorator_add_type` (a record `City.Columns` in type
positions, constructed by its path and returned by an added member, an enum `City.Size` whose
variants are reached as `City.Size.Large`, both printed under the owner's path) and `modules/decorator_add_type_import` (imported with its
owner, under an alias too, and `Greeter.Mock` — a double implementing the annotated behavior — passed
where a `Greeter` is expected), on all four targets, and four `reject/` cells at the annotation:
`decorator_add_type_duplicate`, `decorator_add_type_not_one`, `decorator_add_type_without_owner`
and `decorator_add_type_name`. Its fourth place — `@TypeInfo.all(with: d)`, the program's
declarations carrying `d` — adds `modules/typeinfo_all_registration` (an entry point that imports
neither page module catalogues their `#[route]` functions with their meta, in module-path then
declaration order, and its own and another module's `#[component]` types through `member:`; a
decorator nothing carries answers `[]`), on all four targets, and
`modules/typeinfo_all_type_also_imported` (catalogued types of a dependency and of a nested module
of the package, each also imported by the entry point — plain, under an alias, by its path — are
one declaration reached twice, not decision 170's two types of one name), on all four targets, two project refusals by
`<target>.expect` — `typeinfo_all_imported` (a module importing the reader, at the import) and
`typeinfo_all_private` (a private declaration the query would answer) — `modules/typeinfo_all_spelled_in_string`
(a module whose string literal only spells `@TypeInfo.all` is no reader: the entry point imports it and
catalogues its tagged function, on all four targets), and four `reject/` cells
where the query is written: `typeinfo_all_mixed`, `typeinfo_all_needs_member`,
`typeinfo_all_with_ordinary_fn` and `typeinfo_all_arguments` (decision 268: `with:` is declared
`Decorator | Decorator[]`, so an ordinary function — `typeinfo_all_with_ordinary_fn` — and a literal —
`typeinfo_all_with_number` — are the ordinary type mismatch at the argument; `modules/typeinfo_all_decorator_argument`
accepts a decorator with arguments, a single decorator and a list of them); decision 353 (a template function's body reads the catalogue of the program that expands it) adds
`modules/template_reads_program_catalogue` (a package's `pub default fn` counting the application's
`#[theme]` — one, declared in a module analysed after another expands the template — and an empty
`#[palette]`, on all four targets), two project refusals at the expansion, `template_catalogue_two_themes`
(the template's own `e.fail` naming both declarations) and `template_catalogue_private`
(`typeinfo-all-private`), `typeinfo_all_imported_package_default` (`import cat from "cat"` naming a
reader's default fn, `typeinfo-all-imported` at the handle) and `modules/typeinfo_all_template_value`
(a template body reading an entry's `value`); decision 235's list form adds
`modules/typeinfo_all_list` (two decorators in one `with:`, declaration order kept, a type carrying two
of them answered once with both decorators' meta) and `modules/typeinfo_all_list_twice`. Decision 248
names the one reflection builtin `@typeInfo` (the structural `TypeInfo` answer of a bare
`@typeInfo(T)` folded in): `modules/typeinfo_lowercase` and `modules/typeinfo_all_lowercase` refuse
the lowercase `@typeinfo(…)` / `@typeinfo.all(…)` where it is written (`typeinfo-lowercase`).
Decision 253 makes the catalogue the static `@TypeInfo.all` of the builtin type:
`modules/typeinfo_all_on_function` refuses `@typeInfo.all(…)` (`typeinfo-all-on-function`).
Decision 356 (a decorator on a `val` runs, and the `val` is catalogued) adds `modules/val_decorator_catalogue`
(`DeclKind.Val`, the declared type as `returnType` and `returnTypeName`, `setMeta` read by
`@typeInfo(<val>)`, both `val`s answered by `@TypeInfo.all`, four targets) and five `reject/` cells at the
annotation or the query: `val_decorator_on_var` (a decorator on a module `var`, refused until `116-c` is decided), `val_decorator_runs` (`#[mark] pub val one = 1;` fails with the decorator's
message — the parent binary printed `1`), `val_decorator_add_member` and `val_decorator_add_type`
(`decorator-member-without-type` / `decorator-type-without-owner`, "the val") and
`typeinfo_all_val_and_fn` (`typeinfo-all-mixed`: a `val` and a function under one query). Decision 361
(std's `bpp` annotations; front 116 step 1) adds five `reject/` cells where std's decorators refuse a
role's place — `bpp_html_on_val`, `bpp_style_on_val`, `bpp_html_not_template` (a function not
answering `@ExprCustom<R>`), `bpp_prelude_on_fn`, `bpp_style_prelude_on_fn` — and eight `modules/bpp_*`
projects over a fixture package `markup` (not jhonstart): `bpp_roles_found` (the key, the roles
`#[bpp.html]` and `#[bpp.htmlPrelude]`, no `.bpp` file: accepted, four targets) and seven refused on every
target — at the `"bpp"` key `bpp_html_missing`,
`bpp_html_twice` and `bpp_prelude_twice` (naming the declarations), in the package's file
`bpp_prelude_holds_declaration` and `bpp_role_not_pub`, at the `.bpp` file `bpp_file_without_key`
(line 1) and `bpp_style_section_without_style` (its `--- style ---` line). Every one was red on the
parent binary.
Decision 254 types the answer `Declared<unknown>[]` whatever the program declares:
`modules/typeinfo_all_unknown_value` catalogues two functions of different signatures in one answer
(each naming its declared return type, `returnTypeName` — decision 256; `modules/typeinfo_all_list` reads
it `""` for a type), and
`modules/typeinfo_all_value_unknown` refuses an entry's `value` used as a function without a test.
The registration and list cells therefore read `name`, `module` and `meta` only. Front 130 adds
the narrowing (decision 254): `modules/is_fn_narrows_unknown` narrows an `unknown` with `is fn(<params>)
-> T` and calls through it — a stored factory, a lambda, a top-level fn, a value of another arity,
a string and a number — on all four targets; `modules/is_fn_wrong_arity_fails` (`.exit nonzero`) is a
resolver narrowing a stored `fn(i32) -> i32` with `is fn() -> Clock` and panicking with the entry's
name and the expected type (the message is on stderr on every target, wasm's included, which writes it before the trap); and
`modules/call_unknown_without_narrowing` refuses calling an `unknown` that no test narrowed.
`modules/fn_local_rebound_call` calls a fn-typed local at its current binding — a `val v` narrowed
by `is fn() -> i32` in two sibling `for` bodies, a reassigned `var f`, a second `val f` lambda —
on all four targets (erlang applied the first binding's `V` where the second was `V@1`).
Decision 252 (every builtin declared, a call held to its declaration) adds
`modules/builtin_arguments` — `@panic` given a second argument its declaration does not have,
`builtin-arguments` at the call. Decision 322 (`is` is only an operator) adds
`modules/hand_written_is_builtin` — `@is(1)` written by hand, `unknown-builtin` at the `@`.
Decision 307 adds `modules/std_types_module` — `import {types.Type} from "std"` resolves on all four
targets (std's `types.bp`, exported by `root.bp`).
C-03's beam half adds `modules/std_template_host_fns_across_modules` — std host functions whose
`@External.Erlang` body is a template (`fs.exists`, `fs.readText`, `os.eol`, `process.platform`,
`encoding.hexEncode`, `hash.sha256`, `json.quote`, `regex.matches`) called from the program's
module through a folder namespace and a leaf import, on commonJS, erlang and beam (`.targets`: wasm
refuses `io/fs`, decision 241's group 3).
`01-compiler/05-wasm` step 5 adds a cell per std module family, the commonJS answers on four
targets: `modules/std_encoding_on_every_target` (base64, base64url, hex, percent and form codecs over
ASCII to astral text, each decoder's refusal) and `modules/std_querystring_on_every_target` (query and
form bodies, each refusal); `modules/std_json_on_every_target` (writers, `unquote`, `decode` and its
accessors, the host round-trip) runs on three and is refused on wasm by name (`.wasm.expect`) until
`decisions-pending.md` 05w-j binds `json.parse` / `stringify` there; `modules/std_unicode_on_every_target`
(`fromCodepoint`, `codepoints`, `firstCodepoint`, the four normalization forms — std's botopink
normalizer, decision 333 (A)) has one `.out` for the four targets. Two cells pin the wrong answers wasm gave those families at exit 0, each failing
on the parent binary: `modules/std_namespace_calls_same_name` (`querystring.parse` and `url.parse`
through their namespaces — the mangled one's receiver was dropped) and `modules/tuple_optional_element`
(a `?T` in a tuple — printed, read through `._N`, a generic method's `#(Q<T>, ?T)`, and
`o.unwrapOr(d)` keeping a tuple's shape).
The backend rows of `status.md` (`front/backend-rows-2`) add, each failing on the parent binary
on the targets named: `modules/case_arm_record_named_like_a_variant` (a `case` over `Block | Vec` naming
a record an enum section also declares as a variant — erlang `case_clause`, wasm a trap, beam the
subject itself), `modules/array_last_index_of` (all four; `Array` declared no `lastIndexOf`),
`modules/array_pop_removes` (erlang and beam read without removing, wasm trapped),
`modules/module_var_self_registration` and its `_test` twin (a module-level `var` grown by `push` at
module load — erlang and beam dropped the write), `modules/index_answer_typed_optional` and
`modules/index_answer_is_optional` (`xs[k]` is `?T`; wasm's `?Color` compare and `??` binder),
`modules/integer_literal_labelled_field` (a literal in a labelled `i64` field, every target),
`modules/std_unsupported_names_the_call` (STD-001 names the function called, at the call),
`modules/behavior_method_dispatch_by_value` (wasm dispatches a behavior-typed call),
`modules/string_char_code_non_ascii` (wasm answered bytes), `modules/val_assert_variant_pattern` (commonJS
`ReferenceError`, beam `{unassigned, …}`) and `modules/is_enum_variant` and
`modules/renderer_record_field_shapes` (shapes the rows measured, which no longer reproduce — pinned).
1.0.11's `01-compiler/05-wasm` step 1 adds one cell per primitive-method group wasm trapped on, each
`.out` shared by four targets: `modules/string_lines_words` (`lines` — `\r\n`, a trailing `\r` kept, `""`
one empty line — and `words` over blanks), `modules/array_flat_forms` (`flatten`, `flat`, `flatMap`
over integers, strings, a local, a parameter and an annotated empty `i32[][]`), `modules/array_windows`
(`chunked`, `sliding`, `n <= 0`, a slice indexed and measured) and `modules/array_fill` (a value of
each primitive, an empty receiver). `pop` is `modules/array_pop_removes`; `unique`'s cell is
`02-erlang`'s `modules/array_unique` (C-35).
`modules/generic_field_fn_value` — a top-level fn stored in a generic record's field (`Box<T>(value: T)`)
and called through the field, through an untyped local and through a generic wrapper, and a lambda
stored there typed by those calls, by a `val`'s annotation, by a parameter and by a return type —
answers the fn's own result on commonJS, beam and wasm (wasm printed a string's address, a bool as
`1`, a lambda's string parameter as an integer; front 130's row); erlang refused `h.value("b")` (`function value/2 undefined`) until a field written as a type parameter was applied like a `fn(…)` one (`codegen/AGENTS.md`).
Step 2 adds `modules/generic_string_equality` — `==` / `!=` between two type-parameter values bound
to strings built at run time, by a call's arguments, an array's elements, a generic record's
constructor and a generic call answering one, a parameter written `Pair<T>`, a variant's payload,
an array of such records under `map`, and a generic fn handed to a `fn(a: string, b: string) ->
bool` parameter or bound to a `val` of that type — on four targets; wasm compared words for the
record, generic-result, `Pair<T>`, array and fn-value rows.
`00 · 03-beam`'s split row adds `modules/string_split_empty_separator` — `split("")` cuts into UTF-8
codepoints (`"%0Aéz"` → 5 pieces, `""` → none) beside a non-empty separator and an empty separator
held in a `val`, on all four targets (beam lowered it to `string:split/3`, wasm cut between bytes).
`01 · 03-beam` step 1 adds `modules/ctor_pattern_in_val_binding` — `val Label(t, w) = Tag.Label(…)`, a
one-variant type's constructor in binding position, prints `7` on all four targets (beam bound
nothing: `{unresolved_identifier, t}`), and `modules/import_capitalised_fn` — an imported `pub fn Make`
called with labelled and positional arguments, on all four targets (beam built `Make(n: 4)` as the
record `#{n => 4}`).
01-std step 2 adds `modules/std_asserts_on_every_target` — `import {testing.asserts}` and its pure
assertions on commonJS, erlang and beam — and `modules/std_asserts_host_cell_on_wasm` — `asserts.deepEquals`
on the same three. wasm refuses both at the import (`.wasm.expect`): `deepEquals` calls `canonical`,
which has no wasm binding, a function reaching such a cell is refused called or not (decision 146),
so `testing.asserts` does not build there and the import that links it says so, naming the cell. The same front's `modules/result_field_read` and
`modules/result_unknown_method` refuse a member of a `@Result` that is not one of its methods
(`result-member-not-a-method`).
The onze front's compiler findings (`specs/1.0.10-beta/06-onze/49-onze-stand-up`, F1–F10) add a
cell each: `modules/pub_val_in_a_test` (F1 — a sibling's `pub val` read by a TEST: the erlang runner
did not load the sibling; the first project cell of the test kind), `modules/import_type_closure_across_modules`
(F2 — `import {Canvas}` from a local dependency whose fields name types of the package's other
modules), `modules/unwrap_or_positions` (F4/F9 — `xs.at(i).unwrapOr(d)` in a method, as the branch of
a parenthesised `if` read with `.v`, nested in another `unwrapOr`, over an unannotated `map`),
`modules/src_at_package_root` (F5 — `"src": "."`, a test importing `lib.db`),
`modules/string_slice_in_if_branch` (F6 — a one-argument `slice`, an array `slice` and a string
template as the value of an `if` branch), `modules/integer_division_truncates` (F7 — integer `/`
truncates toward zero on every target, float `/` stays float) and `modules/lexer_error_in_imported_module`
(F8 — every target refuses the project with `bad string escape` located in the imported module, via
`<target>.expect`). The erlang float-literal item adds `modules/float_literal_spellings` (`1e3`,
`2.5E3`, `3e+2`, `5e-1`, `1_000.5` are `f64` on all four targets) and
`modules/number_literal_erlang_spellings` (`5e-324`, the largest `f64`, an `f64` record field and
`0xFF + 0b101 + 0o17`, on all four targets — wasm since its float literal is an `f64.const` and its
radix literal a decimal `i32.const`).
The backend and runtime rows of `00` (`front/codegen-rows`) add a cell each, every one failing on the
parent binary: `modules/task_await_in_if_block` (an `if` block that `await`s without returning, inside a
`@Task` body — commonJS lowered it into a plain arrow and the module did not load),
`modules/task_void_return_in_if_block` (a bare `return;` in an `if` block of a `@Task<void>` body — wasm
emitted a `return` with nothing on the stack), `modules/dependency_files_order` (a dependency whose
`files` lists every importer before what it imports, `import {a.base};` and `import {leaf.Leaf};`),
`modules/external_erlang_host_module_missing` (`.targets` `erlang beam`: an `@External.Erlang` module that is
neither shipped nor in the Erlang code path is a located build error on both, `.erlang.expect` and
`.beam.expect`),
`modules/erlang_host_sidecar_shipped` (a project's `src/sidecars/*.erl` reached by `botopink run` on
erlang and on beam; `commonJS.expect` / `wasm.expect`), `modules/erlang_sidecar_named_like_a_module` (a
sidecar `text.erl` beside the module `text.bp` is shipped — the shipper skipped a basename match),
`modules/sidecar_called_from_folder_module` (front 26, T16: a sidecar called only from `src/orm/entity.bp`
is shipped on erlang and beam although the cell's own `libs/orm/` — a library root the walk-up finds —
carries a package named like the folder; the shipper took that package for the module's owner) and
`modules/sidecar_named_like_emitted_atom` (front 26, C-25: `src/sidecars/sidecar_named_like_emitted_atom@text.erl`, named
like the atom `src/text.bp` compiles to, is a located build error on erlang and beam naming both,
`erlang.expect` / `beam.expect`), `modules/bare_print_call` (`println(x)` is unbound
and the refusal names `@println`), `modules/float_record_field` (an `f64` record field read, compared,
destructured by name and by constructor, and through a method taking and answering an `f64` — wasm
narrowed and bit-read it, erlang and beam did not lower `val Pt(y, _) = p`) and
`modules/linked_fn_name_collision` (two modules each declaring `parse`, reached by their own calls, a
plain import and an aliased one — wasm's one flat namespace). `modules/val_assert_record_pattern` (a
`val assert` over a record's constructor pattern — commonJS destructured the binders' own names,
erlang tested a tag no constructor builds) came out of the same work; wasm and beam followed.
C-04 across a module boundary adds `modules/default_argument_across_modules` — a call omitting
trailing defaulted parameters of a sibling module's and of a path dependency's function, one label
claiming its parameter, on all four targets — and `modules/default_argument_open_across_modules`: a
default that names a private function of its module does not travel, so omitting it from another
module is the arity error, on every target (`<target>.expect`).
The rakun rows of `language-gaps.md` (the language-gaps sweep, `front/compiler-gaps-rakun`) add a
cell each, every one failing on the parent binary: `modules/behavior_method_by_receiver_type` and
`modules/behavior_method_host_value` (a method a `behavior` declares is the VALUE's, beside another type
declaring the same name — an implementer's, a host-built one, on an unannotated local; the
host-built one's `.targets` is `commonJS erlang beam`, wasm having no host vocabulary for it), `modules/behavior_method_imported` (the
same for an imported behavior; `wasm.expect`), `modules/behavior_value_from_implementer` (an implementer
converts to its behavior at an annotated `val` and a `var`), `modules/behavior_across_modules` (an
imported behavior is the same type in its importer; an imported fn-type alias resolves its names in
its own module), `modules/return_nested_in_if_block` and `modules/return_in_case_arm_statement` (a `return`
at any depth of a statement ends the function), `modules/result_method_throw` (a METHOD returning
`@Result` wraps its `throw` / `return`), `modules/test_in_subdirectory` (a test file in `test/unit/`
reaches the project on erlang), `modules/record_method_named_length` (a type's `length` method never
answers an array's `length`), `modules/imported_fn_field_call` (a function-typed field of an imported
record is applied), `modules/method_on_unimported_type` (a method on a value whose type the module
never imported: std's `Dict`, and another imported type declaring the same method),
`modules/method_missing_argument`, `modules/method_extra_argument` and `modules/method_default_argument` (a
method call's arity), `modules/result_pattern_beside_enum_variant` (`Error(e)` over a `@Result` beside an
enum declaring `Error`), `modules/decorator_calls_module_function` and
`modules/decorator_imported_calls_module_function` (a decorator body calls its module's
functions), `modules/decorator_emitted_proxies_dispatch` (two proxies a decorator emits call their own
types) and `modules/namespace_import_module` (decision 107's namespace form over a dependency's
module and the project's own).
The second language-gaps sweep (`front/gaps-sweep-2`) adds a cell per row it fixed, every one
failing on the parent binary: `modules/result_void_falls_off_end` (decision 2 over an effect return —
a `@Result` in any layer, `@Result<void, E>` included, and a `@Task` / `@Component` whose value is a
value, end with `return`), `modules/narrowed_optional_std_field_across_packages` (a method chain on a
field of a narrowed optional, and of an optional binder, whose type another package declares and
this module never names — its field a std type only that package imports;
`modules/generic_type_through_imported_function` keeps two instances of such a generic type apart),
`modules/decorator_argument_default` and `modules/decorator_default_not_closed` (a decorator
argument the annotation leaves out takes its closed default; one naming a binding is refused at the
annotation), `modules/record_update` and `modules/record_update_base_not_a_name` (decision 37's
`Name(..base, f: v)` builds the record it means on every target; the base is a name or a path of
names), `modules/explicit_type_arguments_on_a_method` and
`modules/explicit_type_argument_on_a_method_disagrees` (decision 8 §1.3 at a method call,
`ctx.resolve<T>()`), `modules/std_module_imports_std_module` (`querystring` imports `encoding`'s
percent codec; on four targets since `01-compiler/05-wasm` step 5) and `modules/bodyless_method_without_binding` (a
bodyless method with no host binding is refused at the call on every target, `.<target>.expect`).
The checker rows of `front/checker-rows` add a cell each, every one failing on the parent binary
(or, where noted, pinning a rule the parent already held): `modules/self_param_free_fn` (`self`
outside a type or behavior body is `self-param-outside-type`, at the name — jhonstart's
`repro/self-param-free-fn`), `modules/decl_type_name_spelled` (`@Decl`'s type names spell the type:
`Array<string>`, `string[]`, `fn(i32) -> i32`, `#(string, string)`, `?i32`, a method's parameters
and return), `modules/reserved_word_field_name` and `modules/reserved_word_param_name`
(`reserved-word-as-name`, naming `from`), `modules/external_wrapper_keeps_refusal` (a wrapper around a
single-target host call inherits no restriction — refused on commonJS and wasm by
`.<target>.expect` even though nothing calls it; the parent held this rule, and decision 146
made wasm hold it — `modules/external_wrapper_associated_default` is the same rule on a behavior's
associated `default fn`, which wasm lowered only when a call reached it),
`modules/behavior_array_of_implementers` (`Array<Plugin>` of two implementers; `.targets`
`commonJS erlang beam`, wasm answers `a a b b`), `modules/import_from_package_beside_same_name`
(a project `pub fn attempt` beside another module's `import {match.attempt} from "pkg"`; wasm
listed, the flat namespace), `modules/host_array_slice_without_start` (commonJS's global `slice`
patch reads a missing start as 0; `.targets commonJS`), `modules/decorator_calls_imported_function`
and `modules/decorator_imported_function_name_conflict` (a decorator carries a function its module
imports, and two functions of one name reaching one decorator are refused where it is applied),
and decision 112's three rows — `modules/dsl_hygiene_private_helper`,
`modules/dsl_hygiene_consumer_alias` and `modules/dsl_hygiene_consumer_double`, each printing `40`
(the third's wasm line is the flat namespace's).
The checker rows of `front/checker-rows-2` add a cell each, every one failing on the parent binary except where noted:
`modules/builtin_noreturn_any_position` (`@todo()` / `@panic(…)` are `noreturn`, the bottom type — a
`return` of a `-> i32` function, an annotated `val`, an `if` branch and a call argument; on all four
targets), `modules/builtin_module_not_lowered` (`@module()` is `builtin-not-lowered` at the `@`),
`modules/enum_variant_duplicate` (a variant written twice at one level, at the second),
`modules/enum_section_leaf_beside_variant` (a section leaf `Layout.Break.After` beside a top-level
`After(inner: Token[])`, each reached by its path or its position's type from another module —
the checker half already held; wasm, whose `case` read the leaf's tag, followed),
`modules/variant_leading_dot_two_enums_case` (two enums declaring `Red`, `.Red` by the position's type
and a `case` over each — the checker half already held; wasm followed),
`modules/section_path_es4_expected_enum` / `modules/section_path_es4_every_head` (ES4 names the
expected enum, or every enum carrying the head, sorted — it named the hash walk's first),
`modules/labelled_call_by_label` (a complete labelled call by label on the associated, imported,
namespace and `"std"` call paths, and a namespace call filled from its default; the `"std"` path is
`testing.asserts`, which does not build on wasm — `wasm.expect`, the refusal at the import),
`modules/label_on_function_value` (a label in a call of a function value, `label-on-function-value`),
`modules/behavior_from_host_declare` (a host `declare fn -> Greeter`, here and in a third module,
meets a `Greeter` parameter of the behavior's module — the checker half already held; wasm refuses
the host templates by `wasm.expect`), `modules/shorthand_import_several_candidates` (a bare `import {parse};` over two
modules declaring `pub fn parse` — decision 337's `shorthand-import` at the item, both candidates
written, on every target by `<target>.expect`; it was `import_ambiguous_use`, the use refused, and
its sibling `import_ambiguous_unused` — the import unread compiled — is gone with the shorthand),
`modules/std_decorator_through_namespace` (`#[mocks.mock]` after `import {testing.mocks} from "std"`
gives `Repo` the factory `Repo.mock()` and its stubs answer; wasm refuses the import by `.wasm.expect`),
`modules/std_decorator_unknown_through_handle` (`#[mocks.mokc]` is `unknown-annotation`),
`modules/std_decorator_leaf_import` (`import {testing.mocks.mock}` is `std-decorator-leaf-import`),
`modules/pipeline_call_fill` (`lhs |> f(args…)` is `f(lhs, args…)` on every target, and a pipeline takes
defaults and labels, at expression and statement position) and `modules/case_bool_literal_arms` (`true` /
`false` arms are the bool literals, beside a guard — every backend bound them as names). C-16's
`test/case_arms.bp` writes its range arm `1...9` (decision 53) and passes on commonJS and erlang.
The residual backend rows (`front/residual-backend-3`) add a cell each, every one failing on the
parent binary on the targets named: `modules/generic_call_result_shape` (a generic `-> T` call answers
its argument's shape, `unwrapOr` its default's — wasm printed a string's address),
`modules/unit_enum_print_by_name` (an all-unit enum's value by name, a field, an array, a `?Color` whose
present first variant is not absent — wasm printed the ordinal or trapped),
`modules/case_multi_subject_patterns` (a multi-subject `case` over literals, strings, type arms, variant
binders and guards — wasm answered the first arm, beam matched a string or a type arm on anything,
commonJS never bound a variant's payload), `modules/case_or_pattern_alternatives` (an or-pattern
over unit variants, numbers, strings, payload variants with a wildcard, a literal or a label and
`..`, a guarded arm, tuples, a range and a block arm — beam tested a number alternative alone, so
`C | D -> true` answered `false` and `A | B` raised `case_clause`), `modules/behavior_implemented_by_enum` (an enum implementing a
behavior, called through a value of the behavior — commonJS, erlang and beam),
`modules/behavior_method_result_chained` and `modules/behavior_method_result_typed` (a behavior method's
call answers its declared type, so a primitive method chains on it — commonJS called `length`,
wasm trapped), `modules/external_template_escaped_quote` (a `\"` in an `@External.Node` template is a
quote of the JavaScript; `.targets` without wasm), `modules/std_path_relative` (a std module calling an
`Array` `default fn` — commonJS had no prototype method), `modules/if_value_float` (an `f64` value `if`
outside an `f64` function — wasm refused the module, commonJS printed `0`) and
`modules/linked_val_name_collision` (a module-level `val` and `var` two linked modules declare, read,
written, imported under an alias and shadowed by a parameter — wasm read the first one).
`modules/val_assert_record_pattern` gained the labelled form (erlang bound it by position).
`modules/hof_named_function` (a local, an imported and a bound function named as an array method's
argument — wasm trapped), `modules/generic_body_specialized` (a method on a type-parameter value, a float
through one, a behavior's generic associated fn and `Dict<string, string>.at` over a key built at
run time — wasm answered from one word-typed body) and `modules/imported_fn_as_value` (handed over by
`front/residual-checker-3`: erlang and beam lowered the name as an unbound variable) close the
backend halves the checker front listed.
| `run.sh` | the runner | — |

Decision 280 (`01-checker` step 24, typed comptime decorator arguments) adds, on all four targets,
`modules/decorator_arguments_check` (example 1 of `01-checker/examples/decorator-arguments-280.md`: a
function `rule`, a field key `at: .confirm`, a variant `code: .Mismatch` and the function form),
`modules/decorator_decl_pattern` (`@Decl<fn(e: E) -> unknown>`), `modules/decorator_type_argument`
(`comptime t: @Expr<type>`), `modules/decorator_function_arguments` (`paths:` / `head:` typed by the page's
`P`, `D`), `modules/decorator_record_argument` (`Cache<T>` through a module `val`),
`modules/decorator_field_keys` (`index(.state, .name)`, `unique(.code)`, the field's annotations in the
key) `modules/decorator_argument_values` (an array keeps its length, defaults, labels, a variant) and
`modules/decorator_typed_arguments_import` (an imported decorator's `Type.Field<T>` and enum, the
importer importing neither),
and 19 `reject/` cells, each at the argument unless named: `decorator_param_not_comptime` (at the
parameter), `comptime_default_outside_decorator` (at the default), `decorator_value_not_comptime` (renamed by 364),
`decorator_arg_unbound_function`, `decorator_arg_function_mismatch`, `decorator_arg_unknown_field`,
`decorator_arg_label_unknown`, `decorator_variant_case`, `decorator_field_key_{unknown,case,too_many}`,
`decorator_function_argument_mismatch`, `decorator_record_argument_{mismatch,string}`,
`decorator_type_argument_{unknown,string}`, `decorator_decl_pattern_{mismatch,return}` (at the
annotation) and `decorator_check_without_rule_not_bool` (the body's `decl.fail`, at the annotation).
`modules/decorator_argument_kind` now carets the argument with the typed mismatch, and every
decorator of the cells writes its parameters `comptime`.

Decision 364 (`01-checker` step 35, every `comptime` parameter is `comptime x: @Expr<T>`) rewrote
every `comptime` parameter of the suite to `@Expr<T>` and its reads to `x.value` (a value-or-type
parameter keeps `x is type`; a `Box<T>`'s field is `s.value.value`), and adds, on the four targets,
`modules/decorator_expr_value` (`.value` of a string, a number, a `bool`, a variant, a record, a field
key and an array in a decorator; an ordinary function's `n.value`, specialised; a template's
`q.value` of a literal without holes) and `modules/decorator_expr_unread_argument` (an argument not known
at build whose parameter the body never reads is accepted), and the refusals
`modules/comptime_param_not_expr` and `modules/comptime_param_not_expr_function` (`comptime x: T`, at
the parameter, naming `@Expr<T>`), `modules/decorator_value_not_comptime` (`message.value` of
`env("MSG")`, at the call — the old `decorator_arg_not_comptime`), `modules/decorator_call_expr_fn`
(`rule.value(…)`, `expr-value-of-function`), `modules/decorator_inspect_expr_type` (`t.value`,
`expr-value-of-type`), `modules/decorator_expr_fail_at_argument` (`max.fail(…)` at the argument),
`modules/expr_param_method` (`message.text()`) and `modules/template_value_not_known` (a holed literal's
`q.value`), each red on the parent binary. `modules/decorator_arguments_check` and
`modules/decorator_check_without_rule_not_bool` tell the function form by `decl.kind` (an `@Expr` of
a function has no `.value`, question `s35-b`).

Decision 370 (2) (`01-checker` step 35 box 3) — a decorator hands its parameters' `@Expr`s on to the
program through a typed member, `decl.addMember(name, fn(self: T) -> R { … })` — adds, on the four
targets, `modules/decorator_expr_rule_called` (`rule` is `passwordsMatch`, called by `validate` at run
time), `modules/decorator_expr_message_runtime` (`message` is `t("signup.mismatch")`, evaluated at run
time each time the member reaches it, never at build), `modules/decorator_member_fn_import` (a member
of a decorator in another module, reading only its parameters and locals) and
`modules/decorator_member_fn_imported_name` (one naming a type and a private helper of the
decorator's module — decision 384: each resolves there, the user's own same-named helper is not
captured; it was `decorator-member-fn-imported-name` on the parent binary), and the refusals
`modules/fn_expr_typed`, `modules/decorator_member_not_fn`, `modules/decorator_member_fn_untyped`,
`modules/decorator_member_captures` (a local of the decorator's body),
`modules/decorator_member_captures_handle` (`decl`) and `modules/decorator_member_type` (a field's
`fn(self: T)`, `T` the field's type), each red on the parent binary.

Decision 298 (`01-compiler/130` step 8) — typed meta keyed by its record type — adds, on the four
targets, `modules/meta_typed` (`decl.setMeta(Entity(…))` read `@typeInfo(City).meta(Entity)`, two
`decl.addMeta(Index(…))` read `metaAll(Index)`, every field shape written back — string, array,
float, `bool`, variant, optional —, `null` / `[]` for a type nothing recorded),
`modules/meta_typed_catalogue` (`d.meta(Entity)` / `d.metaAll(Index)` on `@TypeInfo.all` entries,
here and in a function of another module the entries are handed to),
`modules/meta_catalogue_private_type` (`typeinfo-all-private` for a private meta record) and
`modules/meta_expr_read_elsewhere` (decision 385: `main` reads `signup`'s `Check` and `Note`, by
`@typeInfo` and through `@TypeInfo.all`, calling `signup`'s private rule and hint, its own
same-named functions not captured; it was `typeinfo-meta-expr-elsewhere` on the parent binary), and the
refusals `modules/meta_twice`, `modules/meta_not_record`, `modules/meta_field_type`,
`modules/meta_several`, `modules/meta_read_not_type`, `modules/meta_add_outside_decorator`,
`modules/meta_read_at_build` and `modules/meta_catalogue_generic` (question `130-s8-d`). Decision 370
(1) adds `modules/meta_expr_field` (`decl.addMeta(Check(message: message, rule: rule))`, `Check`'s
fields `@Expr<T>`: the reader calls `rule` and evaluates `message` — `t("signup.mismatch")` — at run
time, never at build) with `modules/meta_expr_field_literal` and
`modules/meta_expr_param_plain_field` (`decorator-meta-expr-arg`). Each red on the parent binary.

Decisions 384 and 395 add, on the four targets, `modules/member_reads_own_meta` (`#[validated]`'s
member reads `for (comptime @typeInfo(T).metaAll(Check))`, typed `Check<T>[]` in the decorator's
body and answered with `Conta`'s two `#[check]`s where the member is rendered; the rules and messages
run with the program) and `modules/decorator_member_type_same_name` (a member naming its module's
`Violation` where the annotated module declares one: `import-name-collision` at the annotation until
decision 310 is built), and `modules/decorator_member_type_travels` (an importer of the annotated type calls the member whose signature names the decorator module's `Violation`, which the importer never imports; on wasm the linked module's hygiene alias resolves by `wat.zig` `linkRenames`). Each red on the parent binary.
Decision 311 (`01-checker` step 29 — the template annotation `#[f "…"]`) adds, on the four targets,
`modules/template_annotation`: a template `query(comptime q: @Expr<string>, comptime decl: @Decl)`
written on a behavior's methods (`"…"` and `"""…"""`, beside a decorator) and on a function, each
hole resolving to the declaration's parameter by name, the method's typed meta read by the
behavior's `#[repository]` on `decl.methods` (`m.meta(Query)`, `m.meta(Audit)`, question `s29-b`),
the function's by `@typeInfo(logout).meta(Query)`, and `decl.params` on a method;
`modules/template_annotation_imported` (the template, a helper its body calls and the owner's
decorator declared in another module); and the refusals
`modules/template_annotation_call_form` (`#[f(…)]` naming a template), `modules/template_annotation_not_template`
(a decorator at `#[f "…"]`), `modules/template_annotation_unknown_hole` (a hole naming no parameter —
the unbound-name error at the hole), `modules/template_annotation_without_decl` and
`modules/template_annotation_called` (question `s29-a`). Each red on the parent binary.
Decision 425 (a template call expands wherever an expression may stand, `01-checker` step 29) adds,
on the four targets, `modules/template_in_type_method`, `modules/template_destructuring_init` and
`modules/template_in_field_default` (a field's and a parameter's default) — red on the parent binary
(`twice is not defined` at run time) — and `modules/template_in_lambda`, `modules/template_in_argument`,
`modules/template_in_case_arm`, which the parent already expanded.
144 B-68 adds `modules/template_answer_method` (a library template's answer, a type the consumer does not import: a method on its field),
red on the parent binary (erlang aborted, wasm refused `toString/0`).

Every cell is copied into its own scratch project, so a parse error fails only that cell. Test names
start with the decision-8 section they pin (`test "§5.4 …"`) when there is one, so a failure points at
the rule; a capability decision 8 does not legislate gets a plain sentence.

Areas, by filename prefix: `case_*`, `tuple_*`, `loop_*` (decision 8 §5, §6, §10), `effect_*`,
`comptime_*` / `decorator_*`, `external_*`, `generic_*`, `string_*` / `array_*`, `type_identity_*`,
`optional*` (`optional`, decision 54's `optional_null_pattern` / `optional_variant_pattern`, and
1.0.10-beta's `00 · 05-wasm` `modules/optional_record_carrier` — § `optional_record_carrier` below),
`context_use` / `use_*` (front 19 of 1.0.10-beta: `use` and `@Context`, two test cells, one run
cell and eleven reject cells), `index_*` (decision 63 as amended: `modules/index_dict`,
`modules/index_past_the_end_is_null` — renamed from `…_fails` when C-02 landed, because the
amendment makes an index past the end `null` and not a failure — `modules/index_at_optional`,
`modules/index_tuple` with `modules/index_tuple_computed` and `modules/index_tuple_out_of_range`
for the checker's one special case, and `modules/index_user_type` — a `Matrix` and a `Registry`, the
library types that become indexable by answering `at` / `slice` with no compiler change, which is
the whole of what the rule is for), `std_erlang_node` (decision 64),
`panic_aborts` / `todo_aborts` (front 12 step 4.3), `external_erlang_only` (step 4.4),
`external_host_record` (a host-backed `declare fn` whose return type names a record — the erlang
templates deliberately build the pre-decision-21 `#{field => V}` map that an `.erl` sidecar in a
consumer library still builds, and the boundary adopts it; `.targets` is `commonJS erlang beam`
because wasm has no host vocabulary for these templates — beam compiles the erlang templates at build
time and adopts the answer with its own `'__bp_adopt'/3`),
`external_method_*` (host-backed METHODS — a `declare fn` with `#[@External.<Target>(…)]` inside a
`type` body, lowered as a real method of the type: `modules/external_method_local` — a record's template
methods naming `$0` and `$1`/`$2`, one called from a bodied method on `self`, the `(module, symbol)`
form, `inline = true`, an enum's host method — on commonJS, erlang and beam, refused on wasm by
`.wasm.expect`; `modules/external_method_erlang_only` — bound to Erlang only, refused where it is CALLED on
commonJS and wasm; `modules/external_method_on_host_record` — a host method on a record the HOST built,
adopted directly, through `@Result` and through an array, and a lambda-parameter receiver whose
method shares `name/arity` with a module function (`.targets commonJS erlang beam`, as
`external_host_record`'s); `modules/external_method_imported` — the method on an IMPORTED type,
answered by its owner, with `wasm.expect`),
`string_at` (`05-wasm`: the `String.at` reader, on all four targets),
`lambda_rebinds_case_binders` (front 24, beam: a lambda's own `case` binder, `val` and `for`
element are not captured from the enclosing frame — `make_fun3` had read the unassigned y-register
of `main`'s earlier `Ok(v)` / `Error(e)`, and `erlc +from_asm` refused the module; the long-`main`
shape `result_string_payloads` had to split, on all four targets),
`result_string_payloads` (`05-wasm`: a `@Result`'s payload keeps its declared type through a
`case` — a string in `Ok` / `Error`, a record payload's string fields, a record nested in one, an
array of strings, from a call, a parameter, an annotated `val`, a `for` element and a record field
with `try` on it; wasm printed each string as its heap address before, on all four targets),
`std_default_fn_in_a_std_module` (1.0.10-beta `00 · 02-erlang`: a primitive-interface
`default fn` — `String.slice`, `Array.slice` — reached INSIDE a `libs/std` module that
`from "std"` compiled as an ordinary dependency; one `run/` cell and one `test/` cell,
§ `std_default_fn_in_a_std_module` below), and the
singletons (`closure_capture`, `recursion`, `expr_sugar`, `fn_defaults` (with `modules/fn_defaults_values`, the VALUE on all four targets, and `modules/missing_required_argument`, N2 — both 1.0.10-beta's C-04), the two `lambda_*` cells of
1.0.10-beta's `00 · 04-js` — `lambda_expression_body` (a lambda whose whole body is one expression
answers that expression's value) and `lambda_element_method` (a primitive method on a lambda's
parameter is the same method it is anywhere else), both measured by emilia's theme front and both
asserting the VALUE, because each defect was a wrong answer rather than a crash — and the
decision-28/30/33 cells `nullish_default`, `paren_receiver`, `type_suffix`, `bodyless_fn`,
`curried_call`, `index_expression`, and the two 1.0.10-beta `00 · 04-js` cells
`modules/labelled_arguments` — a record constructor and an enum variant written out
of declared order, the rule being `conformance/docs.md` § Parameters with defaults, "a
parameter the call names by label keeps the argument it was given, whichever
position it is in"; the values are asymmetric so a positional zip is a wrong
ANSWER at exit 0 rather than a crash, which is how it hid — and
`modules/effect_method` — an effect annotation on a method, at its three
declaration sites: a record's own body, a record's `implement` block and an
enum's body; the fourth, a `behavior`'s `default fn`, cannot be written at all,
because the checker refuses `effect-on-behavior-method-forbidden`), and
`effect_chain` (1.0.10-beta front 20,
decisions 95 and 98: one `test/`, two `run/` and five `reject/` cells; front 20
also adds `modules/use_one_base` to the `use_*` area for
decision 96 (its `reject/use_two_bases` left with decision 354), `modules/option_unwrap_or` + `modules/option_expect_removed` to
`optional*` for F11, and `modules/external_inline_unread` to `external_*` for F9 — `inline` on
a variant whose emitter never reads it is refused at the annotation; 1.0.12-beta's front 140 step 2,
decision 334, adds `modules/external_wasm_host_unknown`, `modules/external_host_on_node`,
`modules/external_wasm_host_twice` and `modules/external_wasm_host_beside_unhosted` — `host:` is
`External.Wasm`'s, `.Wasi` or `.Browser`, one binding per host — with `modules/external_wasm_host_binding`
(a `.Wasi` and a `.Browser` binding side by side, the `wasi` build lowering the first) and
`modules/wasm_host_from_manifest` (`"wasm": { "host": "browser" }` leaves a `.Wasi`-only binding
unbound, `wasm.expect`); its step 6 adds `modules/wasm_host_browser_runs` (a `browser` build run by
`node` through its loader, the `.Browser` binding read) and makes the wasm column two runs — `run.sh`'s
`exec_run` runs a wasm cell on the `wasi` host (wasmtime) and on the `browser` host (node), and a cell
whose two exit statuses or stdouts differ fails naming both; a project cell whose botopink.json names
`"wasm"` runs on that host alone); its steps 4–5 (decisions 392–394: `@Task` on wasm a resumable
state machine over the scheduler, one adapter list for both hosts) add `modules/wasm_host_async` (`delay`,
`race`, `raceOf`, `spawnAll` declared with std's Node and BEAM bindings and the `wasi:` adapters —
`raceOf` answers the first thunk to settle, `"b"` on every target and both hosts),
`modules/task_starts_when_made` (a task runs to its first `await` when made, settles once),
`modules/task_resumes_in_place` (loops, `if`, `try`, `try … catch`, a method, a generic fn and an
`async { }` block suspending on a real timer), and two wasm refusals with `wasm.expect` —
`modules/task_await_after_call_refused_on_wasm` (a call before an `await` in its statement) and
`modules/external_wasm_task_adapter_shape` (an adapter declared off its shape), and `enum_section_*` (1.0.10-beta's `00 · 01-checker`: which enum a
leading-dot section path names — `modules/enum_section_expected_type`, where two enums carry
`.Color.Red.500` and every spelling is resolved by the type its position expects, and
`modules/enum_section_ambiguous_path`, where the position expects nothing and the refusal names both
candidates, and `modules/enum_section_qualified_path`, where `Token.Color.Red.500` names its enum and
needs no expectation at all), `modules/case_value_string_arms` (1.0.10-beta's `00 · 05-wasm`: a `case` used as a VALUE with string
arms, in BOTH arm spellings — the two took different paths through `wat.zig` and only the ARROW one
was a string, so `val a = case x { 5 { "five" } … }` printed the arm's heap address `256` on wasm at
exit 0 where the other three printed `five`; the `-> string` function form is `modules/case_values`'
question and not this one, because a declared return type registers the shape on its own),
`modules/case_arm_name_is_also_a_type` (§5.3b's collision: a
module declaring a record `Block` and an enum section carrying a `Block` leaf — the arm over the
section is the VARIANT, the arm over a union of records is still the type, and the cell asserts
both values on all four targets. commonJS tested only `instanceof`, so the section arm never
fired and the `case` answered `undefined` at exit 0, which is how emilia read 223/2 on commonJS
against 225/0 on erlang from one source), and `narrowing_*` (the same front's
`fix/null-narrowing`: which shapes of a null test rebind the name they test —
§ `narrowing_*` below), and the module-`var` cells of 1.0.10-beta's `00 · 17-beam-memory` (C-05, decisions 28, 38, 41, 43, 51): `modules/module_var` — a module-level `var` written twice through a `fn` prints `2` on all four targets (on erlang it was unbound `Hits` and did not compile, on beam the write was dropped and it printed `0` at exit 0 — C-10 lowered both); `test/beam_memory_noop` — the annotation was a no-op off the BEAM (decision 43; deleted when decision 167 made it a refusal there, `modules/beam_memory_off_beam`); and seven `reject/` cells, one per diagnostic — `val_assign_module` and `val_assign_local` (a `val` is immutable, the hint names `var`), `beam_memory_unknown_member`, `beam_memory_unknown_argument`, `beam_memory_keyed_scalar`, `beam_memory_keyed_list` (decision 51: `keyed` is `Dict`-only) and `beam_memory_on_val`. C-10 (front 17 step 4) adds the per-mode BEAM cells, each a `run/` cell with `.targets` = `erlang beam` (a `test/` cell cannot be narrowed to a target, and on commonJS the modes are one program-wide value): `modules/beam_memory_process_dict` (a value written in `main` is not seen by a process `async.runAll` spawns, and its write does not reach `main` — `[0]` then `5`), `modules/beam_memory_ets` (decision 39's fixture: five processes × three increments print `15`) and `modules/beam_memory_persistent_term` (put at load, read by a spawned process: `[101]`); and the refusals its lowering needs — `modules/beam_memory_pt_write`, `modules/beam_memory_ets_recompose`, `modules/beam_memory_ets_bump_non_integer` (decision 40) and `modules/beam_memory_ets_initialiser` (a seed that is neither a literal nor `comptime`). 1.0.11 front 17 step 1 (decision 168) adds the keyed cells: `modules/beam_memory_ets_keyed` (`.targets` `erlang beam` — two processes writing their own key 20 000 times each print `20000 20000`; the seed's repeated key reads its last value, a key with no row `null`), `modules/beam_memory_ets_keyed_seed` (a seed that is neither `Dict.empty()` nor `Dict.ofEntries([…])` of literals), `modules/beam_memory_ets_keyed_recompose` (a row computed from the var's own rows, decision 40's §5(b) diagnostic) and `modules/beam_memory_ets_keyed_whole_read` (a keyed var named anywhere but as its row read's receiver); none can pass on the parent binary: its seed rule refused `Dict.empty()` with the literal-or-`comptime` message, it refused `keyed = true` on the BEAM, and a `Dict` recompose was exempt. `modules/module_var` passes on erlang, and the three `run/beam_memory_*` cells and `modules/module_var` on beam (step 5). `01-checker` step 12 replaces `modules/variant_name_ambiguous` (an erlang-only emit refusal) with `modules/variant_name_ambiguous` — the checker refuses `.Circle` with no expectation on every target — and adds `modules/variant_leading_dot_expected` (the expected type decides `.Circle`; a qualified constructor is the enum written), `modules/section_path_resolution` (a section leaf's shorthand, a payload section path through the annotated enum, a qualified section value) and `modules/section_leaf_without_expectation`; each fails on the `feat` binary. `modules/template_name_collision` (two modules exporting a template `tag`; the import from `loud` expands `loud`'s — the bare-name registry expanded `quiet`'s at exit 0) is 01 step 12's registry half. `modules/try_catch_null_and_noreturn_narrowing`, `modules/component_call_renders`, `modules/component_call_awaited` (a written `await` of a component call inside a component body — jhonstart's layout chain) and `modules/try_catch_handler_mismatch` are the maintainer's 24-box-1 rows (the guide's page example): `catch null` is a `?T`, a `noreturn` call narrows, a component called in a component body renders; each fails on the `feat` binary. `modules/labelled_arguments_reorder` (a label names the parameter it fills in a complete call — fn, record, method, primitive method, self tail call) and the `modules/labelled_arguments` erlang line's removal are 01's labelled-call row. 01 R7 (decision 2) adds `modules/fn_falls_off_end` and `modules/if_without_else_value`, both accepted by the `feat` binary. C-18's decision 45 adds `modules/member_of_optional` (a member read off a `?T` names `?.`) and moves `test/tuple_labels.bp` §6 T4 to `rs.at(0)?.b` — both targets pass it, the label is carried on commonJS and erlang. Decision 15's annotation grammar (front 17 step 3's recorded row) adds `modules/annotation_unknown_family` (`#[@TotallyMadeUp.Nonsense(whatever = 42)]` on a `var`) and `modules/annotation_family_misspelled` (`#[@BeamMemroy.Ets]` names `@BeamMemory`). Pending 0203-a, answered (b), adds `modules/primitive_method_undeclared` (`s.toUpperCase()` names `toUpper`, the method whose host spelling it is) and `modules/primitive_method_unknown` (`"x".fooBar()`, no near name), and re-spells `test/string_case_conversion` to `toUpper` / `toLower` — its erlang line is gone. `01-checker` step 13 adds the two cells of "a local ends with its body": `modules/local_binding_escapes` (a `val` of one `fn` used by the next is refused at the use, naming `holder`) and `modules/local_shadow_ends_with_body` (a local `p` shadows the module's `pub fn p` only inside its own `fn` — `3` then `p:x`); each was run with the `feat` binary and fails there as the step describes. One scenario group per
file: a parse error is the blast radius, so nine `#[@External]` declarations in one file mean one
unparseable annotation hides the other eight.

### The erlang backend's cells (1.0.11-beta `01-compiler/02-erlang`)

Each was run with the parent binary and fails there as its row describes.

- `modules/module_fn_named_like_bif` (language-gaps T13): a module declaring `element/2`, `apply/2`,
  `length/1` and `hd/1` reads a record field, calls each of its own fns, prints a record and reads
  `Array.at` past the end — on all four targets. The erlang module did not compile (`element/2`
  is illegal in the print helper's guard once it is the module's own fn) and, before the
  `no_auto_import` directive, read `p.y` through the module's `element/2`.
- `modules/host_template_binding_inside_while` (language-gaps T14, `.targets` erlang beam — commonJS
  and wasm lack `bump`): an `#[@External.Erlang]` template binding `__Loop`, called in a `while`
  body and in a `for` body. Erlang's `while` recursed through a named fun `__Loop`, and the
  template's `__Loop = …` re-matched it — `{badmatch, 1}`.
- `modules/dependency_module_level_print` (C-34): a dependency's two modules print only from a
  module-level `val`; `main` imports a value from one, its sibling `label` a type only from the
  other, and both bodies run first, on all four targets. Erlang's `'_botopink_init'/0` called a
  `'__bp_print'/1` the module never defined — `erlc` refused both dependency modules.
- `modules/string_literal_unicode_escape` (C-36, STD-11 and the locale row): a `\u{…}` escape above
  U+00FF and a raw `ç` print as themselves, alone and inside an array, on all four targets. C-36's
  emitter half (`writeStringFromLexeme` writes a code point's UTF-8 bytes) was already landed, so
  the cell fails on the parent binary only under `LANG=C`, where erlang wrote `é` as `0xE9` and
  `\x{1F600}` as text; beam did too (`03-beam`'s twin, landing with the next integration). `.length()` of such a string is left
  out: commonJS counts UTF-16 units (`2`) and wasm bytes (`4`) — 04's and 05's rows.
- `test/is_truth_table` (C-07's erlang tail, decision 8 §4.1 × §4.2): each form that may follow
  `is` — `i32`, `i8`, `u8`, `f64`, `string`, `bool`, a record, an enum type, `Box<unknown>`,
  `#(i32, string)` — asked of the same ten `unknown` values, and §4.1's conversion inside
  `if (a is i32)`. `modules/is_truth_table` is the same table on four targets, with tuple rows by
  arity and by element value (`#(2.0, "a") is #(i32, string)` holds); wasm refused it on the parent
  (`cannot box this value as unknown` for an `unknown[]` element, then no run-time test for a tuple
  type). §11's "erlang stores nothing" is `codegen/tests/control_flow.zig`'s needle (`A = 2.0,`, no
  box) — no program prints a difference, so it has no `run/` cell.
- `modules/array_unique` (C-35, decision 217): `unique` keeps each value at its first occurrence over
  integers, strings, floats, bools and an empty receiver. wasm dropped only consecutive duplicates
  on the parent (`[1, 2, 1, 3, 2]`).
- `modules/case_no_arm_matches_raises`: a `case` no arm matches raises `case_clause`; the value comes
  from an erlang host function answering an atom no variant is (the checker sees the `case` as
  exhaustive). beam answered the subject at exit 0 on the parent; commonJS and wasm refuse the
  binding (`.commonJS.expect`, `.wasm.expect`).
- `modules/lambda_binds_name_of_enclosing_fn` (decision 205): a `forEach` body's `val k` over an outer
  `k`, a lambda parameter `e` over an outer `e`, and a lambda value's parameter `e`; the outer names
  keep their values. erlc refused the module on the parent binary (`K@1` unbound). **Red on wasm**
  (`l l 1 2 6 2`: the inner bindings overwrite the outer ones) — 05's row.
- `modules/behavior_default_adopted_by_two_types`: a behavior's `default fn` adopted by two types (one
  declaring the other default itself), called typed, through a default and through a behavior-typed
  parameter. erlc refused the module on the parent binary (`function twice/1 undefined`). **Red on
  beam** until 03's adopted-defaults commit lands and **on wasm** (it traps in `Sq_label`, 05's row).
- `modules/erlang_host_sidecar_in_a_test` (test kind, narrowed to erlang and beam): a `test/` module that
  declares `#[@External.Erlang("lt_greeter", "hello")]` itself and calls it. It imports nothing, so
  its runner loaded no sibling and the call died `{error,undef}` on the parent binary.
- `modules/list_pattern_spread_alone` (a row `03-beam` measured): `[..all]` as a `case` arm over three
  elements and over `[]`, and `val assert [..every]`, on all four targets. Erlang wrote the pattern
  `[All]`, a one-element list — `case_clause` and "assert pattern did not match" on the parent
  binary. The plain `val [..rest] = xs;` (which erlang also left unbound) is `01-checker` step 13's
  `run/val_spread_only_list_pattern`, refused by the checker until the backends lower it.
- `modules/captured_var_write_threaded` (decision 148, lg-b): the two lambdas that may write a
  captured `var` — a `forEach` body and a local closure called at statement position — thread the
  write out on all four targets (a pin: green on the parent binary too). Every other lambda's
  write is the checker's refusal, so erlang lowers nothing more.

### `narrowing_*`

Four cells of 1.0.10-beta's `00 · 01-checker` (`fix/null-narrowing`), and the reason they are a group
rather than an addition to `optional*`: what they pin is the CHECKER rebinding a name, not what an
optional does. `if (first != null)` did not rebind `first`, so a field read off a `?Record` stayed a
fresh type variable and commonJS — which needs the receiver's type to know `.length()` is
JavaScript's `length` PROPERTY — emitted a call on a number (`TypeError: first.key.length is not a
function`, exit 1) where erlang and beam, dispatching dynamically, printed `3`. Four library fronts
of this milestone wrote a workaround and a local gotcha instead of the null check, which is why the
front exists; every cell here asserts the VALUE, because the defect is a crash on one backend and a
right answer on another.

| Cell | Pins |
|---|---|
| `modules/narrowing_null_check` | `if (x != null)` over a `?Record` field, a `?string`, a `?T[]` and a `?i32`; `null != x`; `&&` narrowing BOTH names; the else side of `== null`; and that the narrowing ENDS with the branch |
| `modules/narrowing_null_guard_clause` | `if (x == null) { return …; }` and then the rest of the block — in a top-level `fn` and in a record METHOD, plus the `\|\|` form. Each function is called twice, present and absent |
| `test/narrowing_null.bp` | the same rules inside a `test` block, which is the third statement walk a program has |
| `modules/if_optional_needs_a_binder` | the limit: `if (x)` on a `?T` with no binder is refused ("expected bool, got ?string" — the message spells the type as a source writes it). There is no truthiness on an optional |

**Shapes that do NOT narrow, measured and deliberate.** `while (x != null) { … }` leaves its body
alone: a condition loop reassigns the name it tests (`cur = es.at(i)`), and a narrowed `cur` would
red the assignment — narrowing it would break programs that work today. `if (o.inner != null)`
does not narrow either: only a plain NAME is rebindable. `case x { null { … } v { … } }` and `if (x)
{ v -> … }` narrow already, each through a channel of its own.

`modules/narrowing_null_check` passes on all four targets since `00 · 05-wasm` landed the missing
unbox (`fix/wasm-optional`): a name a `!= null` test narrows is its PAYLOAD for the branch on wasm
too, which is what the box needed and what the optional-binding form `if (x) { v -> … }` had always
done. `modules/narrowing_null_guard_clause` passes on all four targets; beam was red longest, and not
for the checker's reason either — it did not compile a module holding an optional reader in a record
method AND one in a top-level `fn` (`UnknownFunction`, no location — the same program written with
`??` failed identically).

### `optional_record_carrier`

One cell of 1.0.10-beta's `00 · 05-wasm` (`fix/wasm-optional`), green on all four targets, and
here rather than in `narrowing_*` because what it pins is the wasm **carrier** of a `?T` and not
the checker rebinding a name. A `?T` is an i32 offset there and `0` is absence (decision 3), so a
scalar payload goes in a box and a pointer payload — a string, a record, an array — is its own
offset; a RECORD element of an array was written into a box and read as a bare pointer, one
indirection short at every reader. `es.at(0)?.key.length()` answered `276` where the other three
answered `3`, `val k: string = first.key;` inside `if (first != null)` answered `272` where they
answered `abc`, and `@print(es.at(0))` answered `296` where they printed the record — all at exit 0
with nothing said, which is why every line asserts the VALUE. The cell walks the readers in order:
the optional printed whole, `?.` on a field and a primitive method on what `?.` answered, the name a
`!= null` test narrows, `??` with a record default, the same `.at()` reached through a record FIELD
declared `Entry[]`, and a `?T[]` — an element that is itself a pointer for the same reason.

Two shapes are left out and the header says why. `@print` of an ABSENT optional: every backend
spells absence differently today (`null` on commonJS, the atom `undefined` on erlang and beam) and
decision 47's row owns that disagreement, so the cell reads the absent value through `??` instead.
And `.toString()` after a `?.` chain: `es.at(1)?.key.length().toString()` traps on wasm
(`unresolved call: toString/0` — the chain loses the receiver's type for the SECOND method), a gap
of its own.

1.0.10-beta's `00 · 04-js` adds three more `run/` cells, every one of them measured by rakun's front
05 while it wrote a configuration reader, and every one asserting the VALUE — each defect made
commonJS answer differently from erlang, or not answer at all, with nothing said about it.
`self_tail_recursion` (D6) walks 20 000 rounds of a tail-recursive function: commonJS emitted a
plain JS call and node has no tail-call elimination, so the program died with `RangeError: Maximum
call stack size exceeded` while erlang, a tail-recursive VM, printed the sum. Its bound is a
VARIABLE on purpose — a literal one could be folded and hide the depth — and the cell's header
records the ceiling each backend still has. `loop_item_method` (D7/D8) calls `.length()` on what a
`for` binds — the item, a field of it, and a `val` bound from it inside the body: the loop
parameter used to bind a fresh type variable, and commonJS, which needs the receiver's type to know
that `.length()` is JavaScript's `length` PROPERTY, emitted a CALL on a number.
`optional_length_method` (D7) is the same rename one layer deeper — `.length()` on a `?string` from
`.at()`, on a `?string` field reached with `?.`, and on one a `!= null` test has just checked; its
header names the shape it deliberately leaves out (a field read off a `?Record`, which is
narrowing's row). It carried `.targets commonJS erlang` until `00 · 05-wasm` fixed wasm's optional
carrier; the sidecar is gone and the cell runs on all four targets. `comment_in_braced_block` (D9) puts a `//`
comment inside a braced `if` and inside a condition loop's body: commonJS writes some blocks on one
line, so the comment ran on and swallowed the closing brace and everything after it, and the module
did not parse.

### `loop_*` (decision 105)

Front 22 of 1.0.10-beta: `loop { }` / `while (c) { }` / `for (xs) { x -> }` / `for await (g) { x -> }`
are statements, and `#[@generator] loop { }` (with `#[@resultGenerator]` / `#[@futureGenerator]`) is the one
loop that is a value — a generator whose body is a closed generator scope.

| Cell | Pins |
|---|---|
| `test/loop_generator_expr.bp` | an annotated loop typed `@Generator<i32>`: `yield v` emits, `break v` emits and ends, a bare `break` ends, a captured `var` is the generator's state, and a `for` inside the loop feeds it |
| `test/loop_future_generator_expr.bp` | a `#[@futureGenerator] loop` awaiting in a plain `fn` body, consumed by a `#[@future]` body's `for await` |
| `test/loop_yield_nearest_scope.bp` | `yield :out` from inside a `for` names the generator fn; an unannotated `loop` inside a generator fn is an ordinary loop |
| `modules/loop_generator_dobros` | decision 105's own example: `2 4 … 18 20`, then the counter the generator left at `10` |
| `modules/loop_range_inclusive` | `for (1..4)` visits `1 2 3`, `for (1...4)` visits `1 2 3 4`, `for (3...2)` nothing |

The `reject/` cells name one refusal each: `loop_break_value`, `loop_yield_plain_fn`,
`for_over_condition`, `for_future_generator_without_await` (`for-over-stream` since front 24),
`generator_loop_use`, `generator_loop_await`, `generator_loop_break_outer`, `continue_outside_loop`,
`yield_label_loop`, plus the parser's `loop_parenthesised` and `loop_condition_parameter`.

### Effects by return (front 24, decisions 118–128)

The § *Cells* suite of `specs/1.0.10-beta/00-compiler-carry-over/24-effects-by-return/README.md`,
written against its `guide.md`: the return type is the annotation (`@Result`, `@Task`,
`@Component<C, T>`, `@Iterator`, `@Stream`), only `@Result` fails, `async { }` and the `iter` /
`stream` loop prefixes. Written before the compiler lands them, so each fails on today's compiler
until the front's steps do; every header names the decision and the guide row it pins. A `run/`
cell that awaits prints from inside its one `@Task` / `@Component` body (`run`, or the component
`main` calls): commonJS hands a plain caller a Promise (decision 120), the other backends run the
Task eagerly, and inside one body the order is the same everywhere.

| Group | Cells |
|---|---|
| Return and effect mode | `test/effect_return_result`, `modules/task_return_layers` (three layers), `modules/effect_alias_passes_value`; `modules/effect_return_ambiguous_nesting`, `modules/effect_wrapper_behind_alias` |
| `@Task` and failure | `modules/task_await_no_try`, `modules/task_await_result` (`await t` answers the `@Result`, `try await t`, `try await t catch x`), `modules/task_throw_resolves_error` (`.targets commonJS`: the Promise resolves with `Error`, never rejects); `modules/task_throw_without_result`, `modules/task_try_await_without_result` |
| Chain and `use` | `modules/component_hook_and_component`, `modules/component_result_try_await`; `modules/component_try_element`, `modules/await_under_result`, `modules/use_under_task`, `modules/use_of_component` |
| `async { }` | `modules/async_block_all_of` (`.targets commonJS erlang beam`: `std/async` has no wasm host), `modules/async_block_value_type`, `modules/async_block_return`; `modules/async_block_use`, `modules/async_block_conflicting_errors` |
| Iterators | `modules/iterator_fibonacci`, `modules/iterator_result_item`, `modules/iterator_result_items` (step E4), `modules/iterator_factory`, `test/yield_step_next` and `modules/yield_step_next` (`.next()` by hand on an `@Iterator` and, awaited, on a `@Stream` — the `run/` half reaches beam and wasm, which a `test/` cell cannot, and steps a parameter inside a `while`); `modules/iterator_throw_without_result`, `modules/iter_await`, `modules/iter_mixed_yield_return`, `modules/iterator_error_param_removed` |
| Streams | `modules/stream_pages` (a simulated http failing mid-way), `modules/stream_loop_no_failure`; `modules/for_await_without_task` |
| Prefixed loops | `modules/prefixed_loop_forms`, `modules/prefixed_loop_result_item`, `modules/prefixed_loop_break_value`, `modules/prefixed_loop_nearest_scope`, `test/contextual_words`; `modules/prefixed_loop_break_outer` |
| Host (decision 126) | `modules/host_node_task_result` (`.targets commonJS`), `modules/host_erlang_task_result` (`.targets erlang beam`) |
| The E3.9 hint (a `@Result` used as its `U`, one hint per source) | `modules/result_hint_await` (`try await t`), `modules/result_hint_for_item` (`try r`), `modules/result_hint_inferred_async` (the `await` hint plus the `try` that made the block's value a `@Result`) and `modules/result_hint_inferred_iter` (the `for`-item hint plus the `throw` that made the `iter` items `@Result`s); the two `for` cells carry no location line — the mismatch is reported at the file |
| Migration (decision 127, guide § 9's "Old names that left") | `effect-annotation-removed`: `reject/effect_annotation_removed_{result,future,use,generator,result_generator,future_generator}`, the three loop forms `…_{generator,result_generator,future_generator}_loop`, and the older `…_{context,iterator,async_generator}`; `effect-type-removed`: `reject/effect_type_removed_{future,future_no_error,use,generator,result_generator,future_generator}` and the older `…_{async_iterator,iterable,iterator_step,yield}`; the arity refusals `modules/component_base_parameter` (`@Component<C, R>`, decision 354), `modules/yield_step_error_param` (`YieldStep<T, E>`); and the existing refusals `modules/loop_condition_parenthesised`, `modules/loop_await_removed`, `modules/component_plain_return` |

Every row of guide § 9 has a new-form cell above and an old-form `reject/` cell. Two
`.expect` first lines are a code's shared tail on purpose: `without-fallible-channel`
(`task_throw_without_result`, `iterator_throw_without_result`) holds both the README's
`effect-try-without-fallible-channel` and today's `effect-throw-…` for a `throw` (the README's
open point 2). The alias cells spell the guide's `type Name<T> = …;`, which does not parse at
`82e32e36`.

### Decided-against forms and the step-4b forms (1.0.10-beta `00 · 15-language-surface`)

Eight `reject/` cells, one per form the language decided against, each pinning the named kind and
the location of the one site every spelling reaches: `ternary_absent` (`c ? 1 : 2`),
`bitwise_operator_absent` (`1 << 2`), `char_literal_absent` (`'a'`), `nested_fn_decl` (a `fn` in a
body), `list_spread_not_last` (`[..a, 3]`), `list_spread_dot_dot_dot` (`[...a]`),
`implement_clause_for` (`implement A for P` after a bodyless `type P(…)`) and `tuple_literal_label`
(`#(x: 1, y: 2)`). Two `run/` cells for forms that were parse errors and now run on all four
targets: `decorator_negative_argument` (`#[mark(-20)]` — the decorator receives the number) and
`loop_one_line_body` (a one-statement body in `for (xs) { x -> … }` and in a trailing lambda needs
no `;` before its `}`).

### The `modules/` kind

The kind for what a single file cannot express: `pub mod`, `import … from "<module>"`, a folder index
(`shapes/mod.bp`), a private `mod` leaf, and `from "std"` used from a *user* project rather than from
inside `libs/std`. The directory **is** the project; the runner copies it whole and compares stdout
with `expected.out`. A cell that needs a **git** dependency is deliberately out of scope — that is
`zig build test-libs`' job, and this suite must not need the network. A **local** dependency is in
scope since C-16 (front 12 step 4.2): a second project inside the cell, named by the manifest's
object-form dependency `"<lib>": { "path": "deps/<lib>" }` (decisions 75/76, the workspaces landing
`aa80e30b` — an array `"dependencies"` is refused since then), resolves from disk relative to the
project, and the runner does nothing special for it. `modules/local_dependency` is the one
cell of that shape: `deps/shapesdsl/` ships `root.bp` (`pub default mod shapesdsl;`), `shapesdsl.bp`
(`pub default fn … -> @ExprCustom<T>`, the handler returning `e.custom(ast, code)`) and `shapes.d.bp`
(a record declared in a `.d.bp` listed in `files`); the program does `import shapesdsl, {area, Rect}
from "shapesdsl"` and expands `shapesdsl "area(4, 5)"` at compile time (the text spells `area`, the
name the handler's `e.lookup` asks for — decision 237: a capture carries only the bindings its text
names, and `lookup` of any other name is a located error). Green on all four targets, measured
at `361d255d` — the cell was written against the array `"dependencies"` of `85f883bd` and moved to the
object form when the workspaces manifest (`aa80e30b`) started refusing the array. A dependency ships
only what `files` lists — `root.bp` included, or the handle never reaches the consumer.

`modules/package_variant_identity` is the second local-dependency cell, and it is here because the
defect it pins is **invisible in one package**: the value is built in the consumer and the `case`
that reads it lives in the dependency. commonJS tested a payload-less arm with `instanceof` whenever
the variant's bare name was unique in the module; an enum SECTION desugars into an inner enum no
module exports, so its classes are re-emitted per module and the consumer's value was never
`instanceof` the library's class — the `case` fell through every arm and printed `undefined`, at
exit 0. The cell prints four values through one dispatcher: a uniquely-named variant, a repeated one
(`Lg` is declared twice, which is why it always worked), and one of each section head.

`modules/unknown_by_value` (1.0.10-beta `00 · 05-wasm` step 2) runs decision 8 §2, §4.1 and §5.2
through `unknown` on every target — `test/case_unknown.bp` states the same rules, and `botopink test`
does not reach wasm; it prints no unknown float, because commonJS stores nothing extra (§11) and
prints `2.0` in an `unknown` slot as `2`. `modules/optional_chain_method` (05 step 9) is a method on
the rest of a `?.` chain, its absent probes read through `??`; erlang's and beam's halves were 02's
and 03's.

`modules/sibling_import_in_a_dependency` is a local-dependency cell for 1.0.10-beta `00 · 04-js`
step 5: a `mod` sibling imported with no `from` (`pub mod leaf; import {leaf.Twig};`), once in the
project and once inside `deps/tree/` (`api.bp`'s `import {leaf.Leaf};`). commonJS used to write the
literal word `module` as the path — `require("./module")` / `require("../module")` — so such a
program built and then died with `Cannot find module`. Green on all four targets.

`modules/two_packages_one_module_name` pins decisions 170 and 337's module identity — a module is
its package plus its path. Dependencies `a` and `b` each hold `theme` (`Ns` with different fields,
`make`, a template `tag`), each package's `user` imports its own `theme` by path (`b`'s without
importing `Ns`) and evaluates a `comptime make().show()`, and the project has a `theme` of its own:
the checker, the four backends' module names and cross-module calls, the `.d.ts` and the comptime
runtime keep the three apart. The parent binary refused `a/user`'s import on commonJS, erlang and
beam (`make` is declared `pub` by `a/theme` and by `b/theme`) and wasm (`cannot resolve the call
make/0`); four targets now (the real case: `emilia/theme` beside `styled/theme` under
`jhonstart-emilia`, where erlang tagged emilia's `Ns` with `styled@theme@@Ns__v__…`).

`modules/field_name_collision` is the third cell that needs two modules to say anything, and the
defect it pins is **invisible in one file**. A record is a tagged tuple on erlang, so a field read is
a POSITION, and the position comes from the field's NAME alone when the receiver's type was lost —
at the optional binder of `if (hitOf()) { h -> … }`, for one. The name only identifies a record when
nothing else declares it, and the emitter was counting "nothing else" over the records the FILE
imports: `main` imports `Ctx` (whose `rest` is field 1) and never imports `Hit` (whose `rest` is
field 0), so `rest` looked unique and the read landed one slot over — erlang printed `1`, the length
of a neighbouring field, where commonJS printed `2`, at exit 0 with nothing said. Put the two
declarations one slot further apart and the same guess reads past the tuple and the program dies with
`{error, badarg}`; the cell keeps the quieter half, because a wrong answer is the harder one to
notice. wasm passes since 1.0.10-beta `00 · 05-wasm`: its optional binder takes the payload's record
type, where it used to answer `0` for a field read off it whatever the names were.

`modules/method_name_collision` is the same defect one axis over, and the fourth cell that needs two
modules. Policy 3 puts a method in its TYPE's module on erlang, so a call on a receiver inference
left untyped needs an OWNER, and the owner came from the method's NAME alone — keyed by the name
with no arity, first writer wins, over the modules the file happens to import from, so the export
index's hash iteration order picked it. `Query<T>` and `Grouping<K, V>` both declare `toArray`, and
`main` reaches each through a generic return from the other module, which is where the type is lost.
Both defect shapes follow from the one guess: `Grouping`'s body over a `Query` reads past the tuple
and dies with `{error, badarg}` — which is how it was measured here, on the first line — while
`Query`'s body over a `Grouping` reads the neighbouring `key` and answers `1` where commonJS answers
`2`. The third line is the control: the same collision declared LOCALLY has always been counted by
`name/arity` and cleared on dissent, and it is right on every row. wasm passes since 1.0.10-beta
`00 · 05-wasm`: a method on a value an imported fn answered is resolved through the receiver's record
type, where inference records no note — it used to answer `0` whatever the names were. The library measurement behind the cell is erika's
`examples/erika-linq`, 1 passed / 8 failed → 9 / 0 on erlang.

`modules/export_name_collision` and `modules/type_name_collision` are the fifth and sixth cells that
need two modules, and they pin the root the two above sit on: **an exported name resolves by walk
order**. Every index that answers "which module emits this name" was keyed by the bare symbol NAME
— `CrossModule.exports`, the erlang / commonJS / beam / wasm import walks that read it, the
checker's registry scan in `comptime.zig`, and the CLI's topological sort — and a name is unique
inside a module, never over a program: `libs/std` declares `parse` in `json`, in `querystring` and
in `url` today. The `from "<mod>"` clause, which is the answer, was consulted by none of them.

`export_name_collision` is the `pub fn` half: `one` declares `parse/1` answering `1`, `two` declares
`parse/2` answering `2`, and `main` imports `one`'s. commonJS emitted `require("./two.js")` and
printed `2` at exit 0; wasm linked `two`'s body in and printed `2` at exit 0; erlang emitted a
remote call into the other module and died with `undef`. Reversed — the consumer naming `two` — all
four REFUSED the program quoting `one`'s arity ("'parse' expects 1 argument(s), got 2"), because
the CLI drew its dependency edge to `one` and `two` was ordered after its own importer. The cell
deliberately leaves `two` imported by nobody: wasm links every module of a program into one flat
namespace, so a second module importing `two`'s `parse` as well would collide there for a reason
that is wasm's and not this index's.

`type_name_collision` is the `pub type` half, where a NAME is the whole identity (a record has no
arity to tell two apart). `parser` and `net` each declare `pub type Outcome` with the same two field
names in the OTHER order and a `describe` of its own, so the wrong declaration answers rather than
crashes: erlang printed the NEIGHBOURING field (`net-note` for `.tag`, and `404` through the typed
method call) at exit 0, where commonJS and wasm printed the right one. The cell walks all three
axes — the field read, the method call and the construction — and every line asserts the VALUE.

`modules/variant_name_collision` and `modules/variant_name_ambiguous` are the third axis. Decision
21 puts the ENUM and the enum's module inside a variant's atom, and `variant_enum` answered "which
enum declares `Circle`" by declaration order — first writer wins, mitigated for a `case` SUBJECT
only. The first cell is the spelling that always had an answer (the enum is written) and asserts
six values on every target. The second was an erlang-only `run/` cell the emitter refused; since
`01-checker` step 12 the checker answers both halves for every target: a leading dot whose position
expects an enum is that enum's (`modules/variant_leading_dot_expected`), and one whose position
expects nothing is refused naming both enums (`modules/variant_name_ambiguous`).

`modules/variant_positional_payload_same_name` — two modules each declare a payload variant `Item`
with a different field and a third matches both positionally (commonJS printed `null`; beam bound
the whole value, `03-beam`'s row).

`modules/variant_payload_wildcard_and_nested` — `Rect(w, _)`, `Rect(_, h)`, `Circle(_)` and a variant
nested in another's payload (`Two(Rect(w, _), _)`, `Two(Circle(r), Rect(_, h))`) in one module, on
all four targets (wasm bound `w` to 0 and answered the nested arms wrong at exit 0, `05-wasm`'s rows).
`modules/unsigned_compare_and_divide` — `u32` above 2^31 and `u64` above 2^63 compared and divided, on
all four targets (wasm read a `u64` signed, decision 319); `u64`'s `%` past 2^53 is
`codegen/tests/wat.zig`'s, since commonJS aborts it (`04-js`'s step 9).
`05-wasm`'s printing rows, each on all four targets: `modules/bool_field_print` (a `bool` record field
or tuple element read alone printed `1` / `0` on wasm), `modules/u64_record_field_print` (a `u64` field
through the record printer printed signed), `modules/u64_tuple_slot` (a `u64` / `i64` / `u32` tuple
element — built, read, destructured, bound, compared, nested — was refused on wasm) and
`modules/optional_u64_to_string` (a `?u64` printed, narrowed, unwrapped and turned into text signed).

### `std_default_fn_in_a_std_module`

Two cells of 1.0.10-beta's `00 · 02-erlang` (`fix/std-slice-shim`), and the reason they are a group
rather than an addition to `std_erlang_node`: what they pin is a `libs/std` module compiled as a
**dependency**, which is a different compile unit from the one `zig build test-libs` gives it.

`String.slice` and `Array.slice` are bodied instance `default fn`s of `libs/std/src/primitives.bp`,
not bare-symbol prim-ops, so the erlang backend reaches them through
`collectPreludeInstanceDefaults` — which was called only for a **comptime** module. A std module
reached through `from "std"` is neither a comptime module nor a unit that carries `primitives.bp`'s
own `behavior` decls, so `query.slice(1, query.length)` fell through to a bare local `slice/3` the
module never defines. Five std modules were dead on the erlang row at once — `path`, `querystring`,
`queue`, `snapshots`, `url` — and the same expression in a PROJECT module has always lowered to the
emitted `string_slice/3`, which is why the defect needs a std module to say anything at all.

| Cell | Pins |
|---|---|
| `modules/std_default_fn_in_a_std_module` | the VALUE, through four std modules and both interfaces. `botopink run --target erlang` compiles the whole output directory with `erlc` up front, so a dead std module is a hard error on this path. On four targets since `01-compiler/05-wasm` step 5, which closed the two wrong answers wasm gave it at exit 0 (`url.parse` through its namespace called `querystring`'s `parse`; `dequeue`'s `?T` read as its box's address) |
| `test/std_default_fn_in_a_std_module.bp` | the `botopink test` path, which does NOT run `erlc` over the output: the entry runs under `escript` and its emitted runner loads its own siblings. Its imports are namespace-only on purpose (`querystring`, `path` — no imported fn, no imported type), because the sibling loader was emitted for `imported_fns` / `imported_types` / a type module only and `from "std"` fills none of them |

Both halves were invisible rather than red, and in different ways. The lowering half was invisible
because `botopink build --target erlang` exits 0 — it transpiles and never invokes `erlc`. The
runner half was invisible because the sibling loader **skipped** a module that did not compile
(`_ -> ok`), on the reading that its own cell reports the error — true for a module of the project
under test, never true for a dependency, which has no cell. So the first call into the dead module
died `{error,undef}` pinned to the TEST, and a library that does not compile was indistinguishable
from one that is merely absent. A sibling `compile:file/2` refuses now refuses the run, named, with
`erlc`'s own diagnostic on `standard_error`, and `halt(1)`s before a single test runs (decision 67 —
no flag turns it into a warning).

Measured on `fix/std-slice-shim` merged onto `origin/feat` `1f41990c` (this compiler, OTP 29,
node v25.8.0): `conformance/run.sh` — **547 passed, 42 expected failures, 0 failed**, over
feat's own 541/42. The +6 accounts for itself exactly: these two cells are the `run/` cell on
commonJS and erlang and the `test/` cell's two tests on each. Each was shown to red by planting the
pre-fix behaviour: with `collectPreludeInstanceDefaults` guarded again, the `run/` cell exits 1 with
empty stdout and the `test/` cell does not compile ("`std/path.erl` does not compile — refusing to
run the tests of …"); with the `_ -> ok` skip also back, the same cell reports `{error,undef}` and
says nothing about `std/path`; with only the sibling loader's `std_imports` route removed, it is
`{error,undef}` again on a module that compiles perfectly.

### `std_fs_walk_root_spellings`

`modules/std_fs_walk_root_spellings` (1.0.11-beta front 97) builds `walkroot/` in its scratch project and
prints `fs.walk` of it under nine spellings of the root — `walkroot`, `walkroot/`, `walkroot/.`,
`path.join(["walkroot", "."])`, `./walkroot`, `walkroot/app/..`, the absolute path with and without a
trailing `.`, and `walkroot/app/.` — expecting the same relative paths each time, on commonJS, erlang
and beam; wasm refuses the import (`.wasm.expect`, STD-001: `io/fs` has no wasm binding). The erlang
template cut the root off each full path by its written length while `filename:join/2` had already
dropped a trailing `.` segment, so a root ending in `/.` answered every path minus its first two
characters (`app/layout.bp` → `p/layout.bp`) and the read that followed was `enoent`; planting the old
template back reds lines 3, 4, 8 and 9 on erlang and beam and leaves commonJS green. Its last two
lines plant a dangling link (through a private `linkTo` cell — std has no public one) and print the
`Error` naming it by its relative path, `fs.walk: dangling link "app/gone.bp"`, the same text on the
three targets (decision 178).

### The claims a cell makes about a target

Every claim is a snapshot record (§ Layout): what a target prints and whether it aborts (`out`,
`no-final-newline`, `abort`), what an abort names on a target whose runtime writes its cause
(`stderr`, a containment claim: the rest of a runtime's stderr — a stack trace, a crash-dump notice —
is not the language's answer; wasm writes a `@panic`'s message before its trap and otherwise traps with
no text, so its answer there is `abort` alone), and what a
target refuses (`refused` / `at`). The exit status is never pinned: node 1, erl 1, wasmtime 134 are
the runtimes' (§ Never pin an erlang exit status). A narrowing (`"targets"`) is the one claim that a
target has no answer at all, audited on every check — § Narrowing a cell.

**The per-target answers B-00k left waiting** (144 B-29 step H; decisions 441, 443, 444 — each a pin:
the behaviour landed with B-00e / B-00g and no cell held it, because one `.out` could not hold two
answers): `modules/float_text_at_run_time` (`"${5.0}"`, `1.0e21`, `1.0e-7` print `5.0`, `1.0e21`,
`1.0e-7` on every target, commonJS since 144 B-78),
`modules/string_trim_keeps_nbsp` (`trim` keeps a NBSP; commonJS's engine trims it),
`modules/string_lower_final_sigma` (`ΟΔΟΣ` lowers to `οδοσ`; commonJS's engine to `οδος`) and
`modules/float_nan_infinity_words` (`Infinity`, `-Infinity`, `NaN` on commonJS and wasm; erlang and
beam abort, `stderr badarith`). The fifth row, an unseeded `random.float()` reached from a decorator
body, has no cell: a decorator body cannot reach `io.random` today (`unbound variable
'__bp_ns_io_random'` on every target, a leaf import `unbound variable`), so the answer decision 451
gives it cannot be read off the compiler — a row for the front that makes a decorator body reach a
nested std namespace.

**The language half of `test-cli`** (144 B-29 step H): `modules/tail_recursive_sum` (the numeric
program of `backend_exec.sh`, `0 1 55`, beam included), `modules/record_enum_case_lambda` (its
records / enum / `case` / lambda program, wasm included), `modules/mutual_recursion_forward_reference`
(`mutual_recursion.sh`'s forward reference and `isEven` ↔ `isOdd`), `modules/assert_message_aborts`
(a failing `assert cond, "msg"` aborts naming its message on every target) and
`test/assert_and_try.bp` (`assert` with a message and `try` in a `test` block). How the runner
reports a failed test stays `modules/compiler-cli/tests/test_tooling.sh`'s.

**botopink-lang's `examples/`** (144 B-29 step H, decisions 457, 461): `modules/hello`,
`modules/modules` (the `mod` / `pub mod` tree; its `docs.md` is the example's README),
`modules/yamlconf` (a config template lifting the labelled tuple `#(server, debug)`: `8038`,
`true`) and `modules/yamlconf_unknown_label` (the example's commented-out `cfg.server.prot`,
refused at the label, `this tuple has no element labeled \`prot\``), and the suite
`test/stdlib-tour/` (its `test {}` blocks). No gate ran them before: `yamlconf`'s
`import {conf} from "yamlconf"` is `import {yamlconf.conf}` since decision 337, and
`stdlib-tour`'s two record tests asserted the identity `==` decision 210 replaced, so they now
assert structural keys and dedup. Two are red, each a defect the move found: `modules/yamlconf`
on wasm prints `1` for the lifted tuple's `bool` (`@print(cfg.debug)`; through `val d: bool =
cfg.debug` it prints `true`), and `test/stdlib-tour`'s `Set.fromList` of structurally-equal
records keeps three members on commonJS (and wasm, which no suite reaches) where erlang and beam
keep two. `generic-loader-binding` (three `from "erika"` forms — a library, not the language) stays
in botopink-lang's `examples/` until it can move to erika (`../examples/AGENTS.md`).

`front/gate-wasm-wrong-answers` (`compiler-core/src/codegen/wat/AGENTS.md` § Numbers) adds three
four-target cells for numbers wasm answered wrongly at exit 0 — `modules/float_shortest_text` (a
float's shortest round-trip text, where erlang and beam agree with commonJS), `modules/float_slot_keeps_f64`
(a float in an array, a tuple, a payload, a record field, a `?f64`, a capture), `modules/i64_full_width`
(`i64` locals, parameters, fields, `?i64`, `u32`, a literal past `i32`) — and five cells refused on
wasm by a `.wasm.expect`, each a value wasm has no reader for yet: `modules/optional_index_arithmetic`
(`xs[i] + 1`), `modules/i64_in_array_slot`, `modules/fn_value_float_argument`, `modules/generic_field_float`,
`modules/untyped_array_float_push`.

`front/int-overflow` (decision 264: an integer result outside its type aborts on every target) adds
eight abort cells, each `.exit` plus `.<target>.stderr` naming `integer overflow: <op> on <type> at
src/main.bp:<L:C>` on commonJS, erlang and beam: `modules/int_overflow_add_i32`, `modules/int_overflow_mul_i64`
(past `2^63 − 1`; commonJS reaches the bound through `BigInt`, decision 319),
`modules/int_overflow_negate_i32`, `modules/int_overflow_plus_assign`, `modules/int_division_min_by_minus_one`,
`modules/int_overflow_sub_u32`, `modules/int_overflow_add_i8` and `modules/int_division_by_zero` (commonJS's
`integer division by zero`; erlang and beam raise `badarith`, wasm traps) — and
`modules/int_arith_at_bounds`, every type's bound reached by arithmetic and printed, never an abort. wasm
traps with no text, so its half is `.exit` alone; `u32` and the narrower types check their own range
there too (`wat.zig` `emitRangeCheck`).

144 B-00g (decision 443: case mapping over all of Unicode) adds `modules/string_case_unicode` — `é`,
`ß` → `SS`, `ǆ`, `ﬁ` → `FI`, `İ` → `i̇`, Greek and Cyrillic upper- and lower-cased with one `.out` on
the four targets (wasm printed `é` unchanged at exit 0). The one place the targets part, the final
sigma (a JS engine lowers a word-final `Σ` to `ς`; OTP, and so erlang, beam and wasm, to `σ`), is
not printed here — one `.out` cannot hold both —; `codegen/tests/wat.zig` pins wasm's.

144 B-00k (the B-00 group's Conformance step, decisions 458, 459) adds four cells, each red on the
group's parent `239f789f`: `modules/comptime_text_one_answer` (decisions 434 (5), 441, 443 — a text
computed at comptime is std-wasm's on every target: `5.0`, `1.0e21`, `1.0e-7`, `trim` keeping a NBSP,
`é` → `É`, `straße` → `STRASSE`, `ΟΔΟΣ` → `οδοσ` — the final sigma that one runtime `.out` cannot
hold; the parent's wat comptime refused the non-ASCII case mapping on commonJS and wasm),
`modules/comptime_erlang_cell_never_runs_at_build` (decision 452 — `tag`'s Node, Erlang and `fn:` cells
answer three texts, and the decorator's call prints `Point:fn` on the four targets; the parent's BEAM
comptime printed `Point:erlang` on erlang and beam), `modules/comptime_expression_erlang_cell_never_runs`
(decision 452 from a `comptime` expression rather than a decorator — an Erlang-only host function
refused `comptime-host-cell-unavailable` at the `comptime`; the parent ran its Erlang cell on erlang
and beam and refused it with decision 341's message on the wat runtime). A manifest's own refusals (the name `std`, decision 453; the `"bpp"` key's object form and a name
that is no dependency, decision 361) are the toolchain's, tested by `modules/manifest/src/root.zig`'s unit
tests, never by a cell: every manifest under `modules/` is valid, the members of its workspace (decision 512). A wasm program's own float text, `trim` and
final sigma (decisions 441, 443) and `NaN` / `Infinity` (444) part from commonJS's — or, for `NaN`,
from erlang's abort — so they wait for decision 457's per-target answer (step H); `codegen/tests/wat.zig`
pins them meanwhile, all but the NBSP `trim` keeps on wasm.

`04-js` steps 9 and 10 (decision 319: `i64` / `u64` hold their full range on commonJS too, a number
below 2^53 and a `BigInt` beyond; decision 320: a string index counts codepoints there) add
`modules/i64_full_range` (past 2^53 both ways, `2^63 − 1`, `−2^63`, `/` `%` unary `-` `+=` and `==` across
the edge, then a sum past the top that aborts), `modules/int_overflow_sub_i64_min`,
`modules/int_overflow_add_u64_max` (the `u64` top, `%` and `/` past 2^53, a sum past the top; red on wasm,
which prints the top as `-1` and traps on `18446744073709551614ul + 1ul`), `modules/i64_dict_key_across_safe_edge`
(a `Dict` and a `Set` keyed across 2^53; wasm refuses the `i64` element, `.wasm.expect`) and
`modules/string_codepoint_slice_and_code` (a negative `slice` bound, `s[-2]`, `s[4..]` and `charCodeAt`
over `"a👍bX👍c"`); `modules/wide_literal_past_js_safe_integer` lost its `.commonJS.expect` and answers
on the four targets.

`02/97` step 13 (decision 319, std's half) adds `modules/i64_number_methods_past_js_safe` — `min`, `max`,
`clamp`, `abs`, `isEven`, `isOdd` on `i64` and `u64` values past 2^53 (commonJS threw
`big.isEven is not a function`: the methods were patched on `Number.prototype` alone) —,
`modules/string_parse_int_i64_range` (`parseInt` reads −2^63 … 2^63 − 1 and refuses one past either end;
the parent refused past ±(2^53 − 1)), `modules/integer_conversions_exact` (`toI32`, `toI64`, `toU32`,
`toU64`, `toF64` at the bounds and past 2^53) and two aborts, `modules/integer_conversion_to_i32_aborts`
and `modules/integer_conversion_to_f64_inexact_aborts` (`.exit` plus a `.stderr` per target naming the
value). They answer on commonJS, erlang and beam; wasm refuses each by `.wasm.expect` — its integer
methods are `i32`'s, the conversions have no row, and `parseInt`'s `stringSlice0/2` is unresolved
(that one's location points into std, so its `.expect` holds line 1 alone) — `05-wasm` rows.
Its `io` half adds `modules/std_io_i64_canonical` — `fs.stat`'s `size`, kind and `mtime` (the Node
form reads `statSync` with `bigint: true` and answers the canonical form) and `clock.hours` /
`clock.add` past 2^53 (`clock`'s `wide` is std's `toI64()` now, no host cell), printed as the same
digits on commonJS, erlang and beam; wasm refuses `io/fs` by `.wasm.expect`. Its `recent` helper
holds the `l` literal outside the `case` arm: an `l`-suffixed literal inside a `case` arm is
emitted with its suffix on commonJS, erlang and beam (`s.mtime > 1577836800000l`, a JS
`SyntaxError`, an `erlc` syntax error, `illegal integer` in the beam assembler) — a compiler row,
not std's.

`01-compiler/139` (decision 332: `bigint`, an integer of any size, one value on the four targets)
adds `modules/bigint_arithmetic` (2^101 by a loop, a product of two 40-digit numbers, `/` and `%` with
negative operands, the comparisons, `toString`, `+=`, unary `-`, `bigint.of` past `i64`,
`bigint.parse` of a numeral and of four non-numerals, `toI64`, `toF64`, hex and `_` literals —
checked against Python's integers), `modules/bigint_in_containers` (a record field, a `?bigint` field, a
tuple, an array, `xs[i]`, a fold, an `if` answering a `?bigint`, `==` over each built apart, a number
pattern and a range), `modules/bigint_to_i64_aborts` (`.exit`, and `toI64: 9223372036854775808 does not
fit i64` on commonJS, erlang and beam), `modules/bigint_division_by_zero` (`.exit`, commonJS's
`integer division by zero: / on bigint at src/main.bp:10:14`), `modules/bigint_across_modules` (a
sibling's `pub fn`, `pub` record and `pub val` holding `bigint`s; its `.d.ts` through
`scripts/tsc-check.sh`), and the refusals `modules/bigint_literal_fraction` (`1.5n`, at the suffix),
`modules/bigint_plus_int_literal` (`2n + 1`, at the `1`), `modules/bigint_unsuffixed_literal`
(`val x: bigint = 2`), `modules/bigint_into_i64` (`val x: i64 = 2n`) and, question 139-a's answer,
`modules/bigint_type_test` (`x is i32` over a `bigint`), `modules/bigint_into_unknown` and
`modules/bigint_comptime`. Every one was refused by the parent binary (`number-suffix-unknown`).

`front/block-backends` (decision 2: an `@block`'s `return` is the block's value) adds
`modules/block_return_is_block_value` — `val x = @block { return 3; }`, a branch's `return`, a string,
an `f64`, a `case` arm's `return`, a nested `@block`, a block inside a `for` and a statement block
ending in `return;`, on all four targets. The parent returned from the enclosing function on beam
and wasm and, from a block inside a loop, on erlang.

`fix-js-gaps` (gaps `libs/validation` met) adds `modules/imported_variant_positional_payload` —
`Circle(r)`, `Rect(w, h)`, `Two(l, r)` and a `val assert Circle(r)` over enums of a sibling module, on
all four targets (commonJS read a property named after the binding and died on `undefined`).
`modules/method_named_like_module_fn` — a module declaring `startsWith(comptime decl: @Decl, …)` and
`endsWith(a, b)` calls the string methods of those names (erlang refused the module with
`PrimOpArgIndexOutOfRange`, commonJS answered `false`), on all four targets.
`test/type_method_prim_default` — a `type`'s method calls `String.parseInt`, whose body calls
`self.startsWith`; erlang emitted `startsWith(Self, …)` into the type's module, undefined. A `test/`
cell: wasm has no `String.parseInt` (`stringSlice0/2`, `05-wasm`).
`fix-121-gaps` (the gaps front 121's `onze-content` met) adds three cells on all four targets:
`modules/var_written_in_branch_read_after` — a `var` written in the arms of a statement `case` inside a
`for`, in an `if` block ending in `return` (and in one holding a nested `return`), two `var k` in
sibling `else if` branches of a `while` body, and `val kids = case c { Box(kids) -> kids; … }` (erlang
refused the module, `Out@1` unbound; beam lost the arms' writes at the end of each round; commonJS ran
a `_` arm after an arm whose block answered nothing); `modules/case_arm_ending_in_for` — a statement
`case` arm whose block ends in a `for` (commonJS fell into the next arm, erlang refused the module,
beam dropped a `push` that was an arm's last statement); `modules/record_update_on_lambda_parameter` —
`xs.map({ b -> Brk(..b, active: false) })` and a block lambda ending in the update (commonJS, erlang
and beam built `Brk(b, false)`, wasm trapped).


## The reference — `docs.md` (decisions 461, 462)

`docs.md` is botopink-lang's language reference, moved here from the repository root by 144 B-29
step I with the manifest schema (`docs/botopink-json.md` until then, now § The manifest schema) and
the language example of `README.md` (`modules/greet`). It holds no example of its own: an example is
a line `<!-- example: modules/<cell> -->` or `<!-- example: test/<suite> -->`, alone on its line, its
path relative to this directory, rendered from the cell's `src/` and `snapshot/`. Beside each cell
the reference names, the cell's `docs.md` quotes the reference text it shows.

- A fence of the reference that showed a program is a cell (or names an existing one that shows the
  same thing); its answer is what the compiler answers, read against the text — where the two
  disagreed, the defect is a `1-botopink-lang/144` row and the cell stays red until it lands, or the
  stale text was rewritten. A table, a grammar, a layout sample or a runner's report is ```` ```text ````.
- `zig build test-docs` (`scripts/check-docs.sh`, the gate's stage 10) checks that every example names
  a cell (`botopink.json` and `src/main.bp`) or a suite, and refuses an inline ```` ```botopink ````
  fence and a `<!-- docs-check: … -->` line.
- § The manifest schema is kept in sync with
  [`../modules/manifest/src/root.zig`](../modules/manifest/AGENTS.md): a field is documented only when a
  named parser reads it, a refusal with the message a test shows; a table row per field or refusal.

## The targets

Measured at front `111-gate-beam-and-targets` of 1.0.11-beta (`specs/1.0.11-beta/00-gate/` in the
meta workspace), OTP 28, node v25.

| Target | `botopink test` | `botopink run` | In the suite |
|---|---|---|---|
| commonJS | yes | yes | cells and test suites |
| erlang | yes | yes | cells and test suites |
| wasm | refused — "supports only the commonJS, erlang and beam targets" | yes, it executes | cells only |
| beam | yes: every module of the run assembled beside itself (`erlc +from_asm`), each test module's runner run with `erl -pa` (`01 · 03-beam`) | yes: it builds `out/beam/*.S`, assembles each beside itself (`erlc +from_asm -o out/beam`) and runs the entry with `erl -pa out/beam` | cells and test suites |

A cell runs on every target its manifest declares, whatever `run.sh --target` says: `botopink cell
check` has no target option, and a cell is one job (target `*` in the plan). `--target all` is the
four targets of the `test/` suites' plan (wasm never: `botopink test` refuses it); `--target` also
takes a comma list (`wasm,beam`) — a subset in canonical order, a name twice or unknown refused —
which is what the step gate (`scripts/AGENTS.md` § Step gate and full gate) passes for a change that
reaches those backends only. A machine without `erlc`, `erl` or `wasmtime` fails the run before any
job starts (`run.sh: the beam target needs erlc`); it never runs fewer targets and reports "all"
(decision 67). The tool set is the gate's own — `node`, `erl`, `erlc`, `wasmtime` — and nothing
else: the four-target run is green with `PATH=/usr/bin:/bin:~/.wasmtime/bin` and no other variable
but `HOME` and `LANG=C.UTF-8` (front `01-compiler/12-language-tests`). Under a locale that is not
UTF-8 (`LANG=C`, or none) `modules/string_split_empty_separator` is red on erlang and beam: `erl` writes
`é` as the latin-1 byte `0xE9` where commonJS writes UTF-8 — a program's stdout that depends on the
host locale is a backend defect, not a reason to pin a locale in the runner.

A cell's claims apply on every target it reaches, beam included: the assembled program's status is
read there too (`modules/panic_aborts` and `modules/todo_aborts` abort on beam — the second for a
different reason, § Notes). A cell that every target refuses (a former `reject/` cell) is built on
all four, and its `refused` line is the same on each.

An erlang/BEAM module atom starts with its package (decision 109 of 1.0.10-beta): a cell's entry
is `<cell>@main`, and a host
template that builds a record's tag spells it (`'external_host_record@main@@Point'`,
`modules/external_host_record`).

**A beam program's host modules.** `botopink build --target beam` ships the `.erl` of every
`#[@External.Erlang("<host>", …)]` a package keeps under `src/sidecars/` (or `src/`) into `out/beam/`,
beside the `.S` files — the files the erlang build ships into `out/erl/` — and a host module that is
neither shipped nor on the Erlang code path is the same located refusal on both
(`run/external_erlang_host_module_missing.{erlang,beam}.expect`). Nothing assembles an `.erl`: the
entry's `'__bp_load_siblings'/0` compiles and loads every `.erl` beside its own `.beam` before the
module body runs, so the built program runs wherever `out/beam/` is put on the code path, with no
runner in between. `modules/erlang_host_sidecar_shipped` and
`modules/erlang_sidecar_named_like_a_module` pin it (`hello, sidecar`, `HELLO, SIDECAR`).

### Narrowing a cell

A cell runs on all four targets, and a project suite under `test/` on commonJS, erlang and beam —
unless it narrows itself with `"targets"` in its `botopink.json` (decision 475 (1); a cell's
`targets` file is refused). A narrowing is a claim about the compiler, checked on every run —
`botopink cell check` for a cell, `run.sh` for a project suite: for each target the cell leaves out,
`botopink build --target <t>` must **refuse** the program on a host binding —

```
`f` has no `#[@External.<Target>(…)]` for the <t> backend
std-unsupported-on-target: std/<m> has no `#[@External.<Target>]` for target '<t>'
```

— the one reason a program structurally has no row on a target. A target the build accepts, or
refuses for another reason, fails the run and names the cell: the narrowing was hiding a gap of that
backend, and a gap is a row of the backend's front, never an entry in `"targets"`. So does a
narrowing that names an unknown target, a target its kind does not have (wasm, for a test suite),
the same target twice, or every target of its kind (it narrows nothing — delete the field). No flag,
list or environment variable turns the audit off (decision 67).

A third refusal stands a narrowing too — decision 167 (amending 43): a module `var` under
`#[@BeamMemory.<mode>]` binds BEAM storage, and commonJS and wasm refuse the annotation where it is
written,

```
`#[@BeamMemory]` has no meaning on the <t> backend
```

so a cell that declares one leaves those two out on the compiler's word, never on its own source's
(the structural exemption the runner used to read off the source is gone). erlang and beam accept
the annotation, so it never excuses either. `modules/beam_memory_off_beam` pins the refusal itself
(its commonJS and wasm departures, located at the annotation) and prints `2` on the BEAM.

A target on which the cell must be refused for a reason that *is the cell's claim* is not narrowed
away — its refusal is its answer, `snapshot/targets/<t>/<module>.snap`.

The narrowed cells, and what each excluded target lacks (re-derived on every check; the refusal
lines are in the front's README):

| Cell | Runs on | Excluded — the binding it lacks |
|---|---|---|
| `modules/async_block_all_of` | commonJS erlang beam | wasm — `std/async` |
| `modules/beam_memory_ets`, `modules/beam_memory_persistent_term` | erlang beam | wasm — `std/async`; commonJS — `#[@BeamMemory]` (decision 167) |
| `modules/beam_memory_process_dict`, `modules/beam_memory_ets_keyed` | erlang beam | wasm — `std/async`; commonJS — `#[@BeamMemory]` (decision 167) |
| `modules/behavior_method_host_value` | commonJS erlang beam | wasm — `makeGreeter` |
| `modules/external_erlang_host_module_missing` | erlang beam (each refuses it: `output/main.snap`) | commonJS, wasm — `total` |
| `modules/external_host_record` | commonJS erlang beam | wasm — `hostPoint` |
| `modules/external_method_on_host_record` | commonJS erlang beam | wasm — `Pair.at` |
| `modules/external_template_escaped_quote` | commonJS erlang beam | wasm — `say` |
| `modules/external_template_refused_on_beam` | erlang beam | commonJS, wasm — `moduleNamed` |
| `modules/host_array_slice_without_start` | commonJS | erlang, wasm, beam — `copyAll` |
| `modules/host_template_binding_inside_while` | erlang beam | commonJS, wasm — `bump` |
| `modules/host_erlang_task_result` | erlang beam | commonJS, wasm — `hostDouble` |
| `modules/host_node_task_result` | commonJS | erlang, wasm, beam — `hostDouble` |
| `modules/host_unknown_parameter` | erlang beam | commonJS, wasm — `std/erlang.element` |
| `modules/std_template_host_fns_across_modules` | commonJS erlang beam | wasm — `std/io/fs.exists` |
| `modules/task_throw_resolves_error` | commonJS | erlang, wasm, beam — `observe` |
| `modules/manifest_targets_host_binding` | erlang beam (`"targets"`) | commonJS, wasm — `magnitude` |
| `test/erlang_host_sidecar_in_a_test` (a project suite) | erlang beam (`"targets"`) | commonJS — `hello` |

Thirty-six exclusions. No other manifest carries `"targets"`: the field used to be boilerplate
(`["commonJS", "erlang", "wasm"]` in 33 cells, `["commonJS", "erlang"]` in 14) that the runner
ignored — honoured as written it would have taken beam away from 33 passing cells — and a project
that must be refused on a target says so with its departure.

**The audits prove themselves.** A cell's narrowing is `botopink cell check`'s, and
`modules/compiler-cli/tests/cli_contract.sh` (§ botopink cell) holds each way it is refused — a
target the build accepts, a refusal that is not a host binding, `#[@BeamMemory]` used to leave beam
out, a list that narrows nothing, an unknown target, a target named twice, a field that is not an
array, a leftover `targets` file, a cell with no manifest. A project suite's narrowing is
`run.sh`'s: `conformance/run.sh --self-test` runs a synthetic suite through the same script
(`--suite <dir>`) — one narrowing that stands on a host binding, which must be scheduled on its
declared targets alone, one of each way a narrowing is refused (a target the build accepts, a
refusal that is not a host binding, a list naming wasm, one that narrows nothing, an unknown
target), and a green and a red cell. Its report must hold each refusal's line, the red cell's
candidate and the tally `5 passed, 8 failed`. A whole run of the suite (no `--only`) starts with it
and stops there if it fails — a green run from a runner that no longer refuses says nothing.

## Running

```bash
zig build test-conformance                                 # the installed botopink: every cell, every suite
zig build test-conformance -- --target erlang              # the suites on erlang alone; every cell still runs
zig-out/bin/botopink cell check conformance/modules/case_range_value   # one cell, in process
zig-out/bin/botopink cell check conformance/modules       # every cell, one after another, in process
conformance/run.sh --compiler <botopink> --only modules/two_modules
conformance/run.sh --compiler <botopink> --only test/case_arms.bp
conformance/run.sh --self-test                         # § Narrowing a cell — the runner's own audit
conformance/run.sh --list                              # the plan: one `<path>\t<target>\t<run|audit>` line per job, nothing spawned
```

`--lib-root` defaults to `<compiler>/../../libs` (where `from "std"` resolves). `run.sh` runs each
cell's `botopink cell check` from a scratch directory of its own, so no library root above the
checkout is found, and exports `BOTOPINK_LIB_ROOTS=<lib-root>`.

A red cell writes its candidates beside its accepted snapshots (`<file>.snap.new`, never committed:
the gate's stage 1 refuses one staged) and the report prints, under its `FAIL` line, what `botopink
cell check` printed — the candidate and its difference. A person accepts a candidate by renaming it
(decision 464: no update flag), and only when the new answer is the language's.

The report is every `FAIL` line, the narrowing audit's count, a per-target line — `by target:
commonJS <passed>/<ran> · erlang … · beam … · * …`, where `*` is a cell (one `botopink cell check`
over every target it declares) and a narrowing refused before any target ran — and the total,
`conformance: <passed> passed, <failed> failed`.

Jobs run in parallel on `../scripts/lib/pool.sh` — `botopink-lib-test`'s rule: `--jobs`
defaults to one per CPU bounded by `MemAvailable / 768 MiB`, and a job is admitted only while
`procs_running` ≤ CPUs when another job of the run is in flight (`run.sh` § parallel jobs). Every
job writes its verdict to its own file and the verdicts are sorted before the report, so
`--jobs 1` prints the same bytes and exits with the same status.

A whole run also prints `cells: <J> jobs — <R> run, <A> audits`: the jobs that wrote a verdict
(every job writes exactly one file; a malformed narrowing writes its `FAIL` without a job). `--list`
prints the same plan without running it, one line per job (a cell's target is `*`), and
`scripts/gate.sh` holds `J` and `A` to it — stage 9 cannot run fewer jobs than the tree declares.

### No result is cached (decision 510)

Every job runs on every run: `run.sh` stores no verdict and answers none from a store, and takes
no `--cold` or `--store-root`. The `--self-test` suite runs like any other. `scripts/gate.sh`
holds the jobs the run does to the plan `--list` prints. The backend partition
(`modules/compiler-core/src/codegen/backend-partition.txt`) decides which cells a step gate runs
(`scripts/AGENTS.md` § Step gate and full gate), never whether one runs.

## A red cell is red

The suite keeps no list of known failures (gate-b of `specs/1.0.11-beta/00-gate`, decision 154): the
file that held one reached zero lines and was deleted with the runner's reader of it. A cell passes
or it fails, the report prints `conformance: <n> passed, <m> failed`, and a run with a `FAIL`
exits 1. A scenario the compiler gets wrong is fixed in the compiler; a cell that must be tolerated
is a decision to delete the cell, not a line somewhere.

What a cell may still say about a target, each checked on every run:

- **the target refuses the program** — a `refused` / `at` record in `snapshot/targets/<t>/` (or in
  `output/` when every target does): the claim is the diagnostic's `error…` line, located;
- **the target has no host binding for it** — the manifest's `"targets"` (§ Narrowing a cell): the
  claim is audited against the compiler's host-binding refusal.

A refusal's `refused` line is the compiler's whole `error[<code>]: <message>` line, compared exactly:
the front that changes a diagnostic's wording re-reads every cell that holds it and renames each
candidate `botopink cell check` writes, in the same change.

## Who adds a cell — the owner rule

A cell is added **in the commit of the front whose fix it asserts**: one new `modules/<cell>/`
directory (`botopink cell new conformance/modules/<cell>` scaffolds its `botopink.json`,
`src/main.bp` and `docs.md`; `botopink cell check` writes its candidates, which a person reads and
renames), no edit to a cell another front added, no shared file to append to. The commit message says the cell was **red on
the parent binary** — the compiler built at that commit's parent — with the line that failed: a cell
that never failed proves nothing. A **pin** (a rule that already holds, a defect that no longer
reproduces) says so in the message instead, and names what it guards.

The cell's header comment (`////`) names where it comes from, spelled by milestone:

- **1.0.11-beta** — the front's directory below `specs/1.0.11-beta/` in the meta workspace and its
  step (`01-compiler/02-erlang step 1`, `00-gate/111-gate-beam-and-targets`), a decision by its
  number, a language gap by its row in `language-gaps.md` (`T10`);
- **1.0.10-beta and earlier** — frozen: the spellings cells already carry (`00 · 01-checker`, `C-16`,
  `01 step 4`) resolve against that milestone's record and are not respelled.

A cell that cannot pass is never tolerated here (§ A red cell is red): the front that owes the fix
lands it with the cell, or a decision deletes the cell. The cells the milestone's area fronts owe are
listed in `specs/1.0.11-beta/01-compiler/12-language-tests/README.md` § Step 2 and audited at the
close — each exists, passes on every target it declares, and its commit says it was red on the
parent.

## Status and the gate

`zig build test-conformance` is stage 9 of `scripts/gate.sh` — skipped by the commit hook's
`--no-conformance` (decision 470), run by a front's Conformance step, its landing and the GitHub
pipeline — and a step of the CI `test` job (ubuntu + macos). A red cell fails the gate.

Recounted on disk after 144 B-29 step H:

```
$ ls -d modules/*/ | wc -l      # 943 cells: 382 former run/, 405 former reject/, 144 former modules/,
                                #   4 from test-cli, 4 per-target answers, 4 from examples/
$ ls test/*.bp | wc -l          # 69 test suites
$ ls -d test/*/ | wc -l         # 6 project suites
```

Every cell and suite green on every target it declares but these, each named for the maintainer:
four former `reject/` cells — `case_bare_name_arm`, `case_constant_pattern`,
`reserved_word_field_name` and `reserved_word_param_name` — whose `.expect` named the text under
the diagnostic's caret (`use _ { n -> … }`, `reserved word \`from\``), which no `.snap` record
states: their snapshots hold the old claim as written (`refused use _ {`, located) and stay red
until the maintainer decides how a cell states a diagnostic's label; `modules/yamlconf` on wasm
and `test/stdlib-tour` on commonJS (§ The claims a cell makes about a target, the examples).

Decision 146 on wasm (a function whose body calls a host function with no binding for the target is
refused called or not, on every target): `modules/external_wrapper_keeps_refusal` passes on wasm by its
`.wasm.expect`; `modules/std_asserts_on_every_target` and `modules/labelled_call_by_label` are refused
there at the import of `testing.asserts` (`.wasm.expect` / `wasm.expect`), and so is
`modules/std_asserts_host_cell_on_wasm`; `modules/std_decorator_through_namespace` pins the import's STD-001
line; `modules/external_wrapper_associated_default` runs on four targets.

## Notes for whoever writes the next cell

**Shapes that do not parse: none is known.** Every row this list carried parses. Re-measured with
`botopink check` and `botopink run` by front `01-compiler/12-language-tests` of 1.0.11-beta; each
row is pinned by a cell that passes on every target its kind has:

| Shape | Was listed as | Now | Cell |
|---|---|---|---|
| a module-level `var` | absent | `var` and `pub var`, with or without a `#[@BeamMemory.<member>]` above it; a `val` assigned anywhere is a located error naming `var` (decision 38) | `modules/module_var`, `modules/beam_memory_off_beam`, `modules/val_assign_module` |
| §5.1 `Pattern { body }` arms, §5.3b section arms | `06 N22` | parse, check and run | `test/case_arms.bp`, `test/case_sections.bp` |
| a block-shaped statement not last in its block (`if (1 > 0) { … }` then `@print("b");`) | decision 29 — "the `;` goes" | parses and runs since C-13 made the `;` after a braced block optional; the formatter writes no `;` there | every cell `botopink format` rewrote (FC-4) |
| `adder(3)(4)` — calling the result of a call | "make it parse" (14) | parses, checks and runs | `test/curried_call.bp` |
| `#(a: i32, b: string)[]` — an array of labeled tuples | "make it parse" (14) | parses, checks and runs, with `@Result<i32, string>[]` and `(i32 \| string)[]` | `test/type_suffix.bp` |
| `??` | deliberately absent (14) | parses and runs (decision 28); `catch` is `@Result`-only, so nothing else gives an optional a default | `test/nullish_default.bp` |
| `xs[0]`, `xs[0..2]`, `d["k"]` — an index expression | "no index expression in the grammar" | parses, checks and runs (decisions 30, 63, 139) | `modules/index_expression`, `modules/index_dict`, `modules/index_past_the_end_is_null`, `modules/index_negative_from_end` |
| a bodyless `fn` with `-> void` | no rule | parses and runs (decision 33); without a return type it is `bodyless-fn-needs-return-type` | `test/bodyless_fn.bp`, `modules/bodyless_fn_no_return_type` |
| a method on a parenthesised expression or a number literal — `(a == b).toString()`, `("ab").length`, `42.toString()` | open | one production; `42.toString()` prints `42` on all four targets (commonJS once wrote `42.toString()` into the program, which node reads as a float) | `test/paren_receiver.bp`, `modules/method_on_number_literal` |

**The range pattern — decision 53.** `...` is inclusive in a pattern; `..` is exclusive in a slice
and in `for (a..b)`, Zig's split. `1..9` in an arm is `error[pattern-range-exclusive]` located at
the `..`, with `1...9` as the hint (`modules/pattern_range_exclusive`). `1...9` matches both endpoints
and nothing outside them on all four targets — in a `case` used as a value (`modules/case_range_value`,
five probes) and as a typed function's return (`fn f(n: i32) -> i32 { return case n { 1...9 … } }`
prints `0 1 1 0` for 0, 1, 9 and 10). **An endpoint probe is the minimum a range cell may print**: a
single value inside the range cannot tell an arm that matches from one that always matches — beam
once answered `1` for every `n`, 0 and 10 included, and a probe at 9 read it as right. Decision 53
legislates numeric endpoints only, so no cell asserts a string bound.

**A `.out` may encode a decision no backend implements yet, and that is the point.** The `.out` is
the decision's answer, so when the backends are moved against it **exactly one file per cell** is
involved and no `.out` is renegotiated in the same commit as an emitter. A cell's header comment
carries the per-backend measurement it was written against.

**Never pin an exit status or a runtime's diagnostic as the point of a line.** `botopink run --target
erlang` compiles every emitted `.erl` with `erlc` and runs `erl -pa <out>` (decision 56; `beam`
assembles the `.S` files the same way); a crash is status `1` and the runtime's report goes to
stderr, which no `.out` sees. node answers `1` and wasmtime `134`. An aborting program is asserted by
`.exit` = `nonzero` (§ The sidecars of a `run/` cell), never by a number.

**Four backends agreeing is not evidence.** A decision can make a green cell red: decision 55 once
turned `for ([1, 2, 3]) { x -> break x * 2; }` → `[2, 4, 6]`, which every backend printed because they
shared one accumulator shape, into a red cell on all four (and decision 105 later deleted value loops
altogether). The cell is written to the language; the backends follow.

**Structural equality is decision 210: `==` compares by value on every target.**
`Person(name: "Ana", age: 30) == Person(name: "Ana", age: 30)` is `true` on all four:
records, tuples, arrays and enum variants compare field by field, recursively, two
values of different types are never equal (decision 21), and `!=` is the negation.
Decision 211 adds that `==` never calls user code — a method named `equals` has no
special role. erlang and BEAM compare one term (`=:=`); commonJS answered `false` (the
class instance's reference) and wasm `false` (the pointer) until each lowered `==` by
the operands' static type: a primitive keeps its instruction, a composite calls an
equality generated per compared type (`codegen/js/AGENTS.md`, `codegen/wat/AGENTS.md`
§ structural equality). `modules/record_structural_equality` pins it on four targets — a
record, a nested record, a tuple, an array of records, enum variants with payloads,
two types with the same fields, `!=`, a generic `same<T>` and an `equals` method `==`
does not call. `test/type_identity.bp` keeps asserting the other half, two
different types with the same fields.

**`f64` under `==` is a total order — decision 214**, as Java's `Double.compare` and
Kotlin's data class: `0.0 == -0.0` is `false` and `NaN == NaN` is `true`, bare and
inside a record, tuple, array or variant, while `<`, `>`, `<=`, `>=` keep IEEE
ordering. erlang and BEAM already separate the zeros (`=:=`); commonJS lowers a
float `==` to `Object.is` and wasm to `$__f64_eq` / `$__f32_eq` (NaN canonicalised,
then the bits). `modules/f64_equality_total_order` pins the zeros on all four
targets, with `-0.0` built at run time as `zero() * -1.0`. **The NaN rows are not a
`run/` cell**: erlang and BEAM never produce a NaN (`z / z` raises `badarith` at run
time), and § Narrowing a cell lets a cell leave a target out only when the build
refuses it on a host binding, which a division is not — a `.targets commonJS wasm`
would fail the audit. Each backend that has NaN pins that half in a RUN LOG fixture of
its own: `codegen/tests/commonjs.zig` and `codegen/tests/wat.zig`, `f64 ---- NaN
equals NaN under ==`.
`modules/integer_never_negative_zero` is the premise commonJS needs for it: an integer
is never `-0` (`0 * -1`, `-x`, `-4 % 2` and `0 / -3` print `0` and compare equal to
`0`), so a generic `same<T>` answers `true` for two integer zeros and `false` for
`0.0` against `-0.0` on four targets — commonJS printed `-0` and answered `true`.

**The identity is asserted on three backends and RUN on four.** `botopink test` refuses wasm,
so a `test/` cell reaches commonJS, erlang and beam. `modules/type_identity_equality` is the same
statement as a `run/`: `Person(name: "a", age: 1) == Vec(name: "a", age: 1)` prints `false` on all
four since `13-module-identity` half 3 put the declaration inside the value.

**`use` is tested from botopink since front 19 of 1.0.10-beta**, spelled to decisions 102/104
(front 21): `test/context_use.bp`, `modules/context_use` and the `reject/use_*.bp` cells declare
their own owner type (`type Element(…) implement @Renderable`, decision 354), hooks as
`fn … -> @Component<T>` and components as `fn … -> @Component<Element>`, and
pin the binding of `T`, field and positional destructuring, a custom hook composing hooks, a bare
void `use`, an unannotated `fn … -> Element` as an ordinary function, the rules of hooks (decision 357,
`use-not-top-level`; rows 4b and 4c were parse errors of the static prefix before it),
`use-without-context-effect` (a `-> Element` body, a plain `-> string` body, a `#[@future]` body —
`modules/use_future_without_owner`, decisions 89/90 revoked) and `use-of-non-context-fn` (a
module-level `val`, decision 87). A component's caller awaits it:
`modules/context_use` drives the components from a `#[@future] fn run`, and the `test/` cells await
them (a `test` body is a future context). `test/use_future_context.bp` is the server component that
`use`s and `await`s under a `@Component` return. Front 24 (decision 118) deleted
`reject/use_future_context_duplicate.bp`, `reject/two_effect_markers.bp`,
`reject/wrapper_without_annotation.bp` and `reject/result_without_wrapper.bp` with the annotation
rules they pinned — a function has one return, so it has one effect.
`modules/use_tuple_arity` and `modules/use_tuple_of_non_tuple` are front 19 step 3's
`use-tuple-arity` refusals, located at the binding.

**Decisions 63–66, one cell or one sentence each (C-16).**

- **63** (an index is a method call, amended 2026-09-19: the index answers what `at` answers, `?V`)
  — `modules/index_dict` (present key → `1`; `Dict<string, ?i32>` → `null`; absent key → `null`, and
  the program goes on), `modules/index_past_the_end_is_null` (`xs[9]` is decision 47's `null`) and
  `modules/index_at_optional` (`Dict.at` / `String.at` by name answer `?V`, `null` for absent), with
  `modules/string_at` for the present-index reader — all on four targets. The fixture C-16 names
  `index_an_index_past_the_end_answers_zero` is a `src/codegen/tests` fixture, not a cell of this
  suite.
- **64** (a wrapper per host-bound std `declare fn`) — `modules/std_erlang_node`: `erlang.node()`
  prints `nonode@nohost` on erlang (C-03's erlang half, `a8db11e4`); commonJS and wasm **refuse** it
  with `std-unsupported-on-target` (two `.expect` sidecars); beam prints it too since front 17 step 5
  wired `beam_asm.zig`'s wrapper for a plain `module:symbol` target (C-03's beam half, for
  that form only). The commonJS/wasm diagnostic names the function called, at the call
  (`std/erlang.node`, at `erlang.node()`); a namespace import none of whose unsupported functions is called
  is refused at the import, naming the module and the functions it lacks
  (`modules/import_std_folder_namespace/wasm.expect`).
- **65** (the formatter measures width) — **no cell here**, and none can be: the suite runs programs,
  and decision 65 is about the text `botopink format` writes. Its evidence lives in the formatter's
  own tests (`modules/compiler-core/src/format/`, C-12's rows). This suite meets it only as a
  consumer: `deps/shapesdsl/src/shapesdsl.bp`'s `CustomNode(…)` line is broken the way today's
  formatter breaks it (`fits` stops at the first `concat`), and will be re-broken when C-12 lands.
- **66** (`format --check` over the whole project) — the three `modules/*` cells decision 66 named as
  red (`mod_tree`, `std_import`, `two_modules`) are **formatted**: `botopink format` inside each
  (brace bodies expanded, `import {a, b}` spacing) and `botopink format --check` exits 0 in all four
  `modules/*` roots and in `deps/shapesdsl`. The cells' output did not move. Nothing in this suite
  *calls* `format --check`: the caller is `scripts/format-check.sh`, stage 3 of `scripts/gate.sh`.
  `conformance` is one of its `TREES`: `test/`, `run/` and `modules/` are canonical — a cell
  is written formatted (`botopink format <file>`), and an unformatted one is a red gate. Two
  things are outside the walk, both by structure (`format_cmd.zig`), never by a list: every
  `reject/<n>.bp` beside its `<n>.expect`, and
  `modules/lexer_error_in_imported_module/src/pattern.bp` — the bad escape the cell exists to
  refuse — by the second arm (gate-c: a `.bp` under `modules/<cell>/` that the cell's `.expect`
  files name and that does not lex or parse). A `modules/<cell>/<target>.expect` pins a
  `<file>:<L>:<C>`: reformatting the file it names moves the pinned line with it, in the same
  change (`modules/decorator_imported_function_name_conflict` pins `src/main.bp:21:3`, the
  `#[tag]` under an `@emit(…)` argument the formatter opens over four lines).

1.0.11 front 14 step 1 adds `modules/comptime_method_nothing_answers` — a decorator body (untyped)
calling `.frobnicate(1, 2)` on a string, which no primitive type and no host function answers: the
compiler refuses it before any comptime runtime runs, the message names the call by its `line:col`
in the body and the caret is the annotation that ran it.

**`@panic` and `@todo` abort with stdout intact and a non-zero status on all four backends**
(`modules/panic_aborts`, `modules/todo_aborts`, `.exit` = `nonzero`). On beam a function whose whole
body is `@todo()` is emitted and raises the builtin's own `{todo, <<"not implemented">>}` —
re-measured by front 12 of 1.0.11-beta (it used to be dropped, and the abort was `undef`).
A `@panic`'s message reaches stderr unchanged on all four (`modules/panic_library_message`, a
library-built message with quotes and a non-ASCII dash, `stderr` in `output/`, decision 430, 144 B-41):
erlang and beam write the message itself, not the term with its bytes as numbers; wasm writes it
before the trap.

What cannot be tested from botopink at all, and why: `@typeInfo` / `@makeRecord` / `partial` / `omit`
/ `pick` (they produce types, and asserting on emitted text is the snapshots' job). Struck from this
list by C-16, each with the cell that covers it: `pub default mod` / `pub default fn`, `@ExprCustom` /
`q.custom` and `.d.bp` via `files` (`modules/local_dependency`, a local dependency needs no network);
"no external target for the active backend" (`modules/external_erlang_only`, a `run/` cell refused on
two targets through a `.<target>.expect` sidecar each — `botopink run --target <t>` is not
target-independent, which is what `reject/` lacked); `@panic` / `@todo` (`run/` compares stdout **and**
the status through `.exit`, so an aborting program is exactly what it can assert).
