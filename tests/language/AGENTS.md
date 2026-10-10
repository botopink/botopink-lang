# tests/language — botopink language tests (fronts 15 and 17)

Tests written in botopink, running the emitted program. Front 15 pinned decision 8
(`specs/1.0.4-beta/08-review-backlog/decision-8-language.md` in the meta workspace): `case` and
patterns (§5), tuples and labels (§6), `loop` (§10), and the parts of `is` (§4), unions (§3),
`unknown` (§2) and printing (§7) those scenarios use. Front 17
(`specs/1.0.4-beta/17-language-test-expansion/README.md`) added the rest of the language surface —
effects (§9), comptime parameters and `@Expr` templates, decorators and `@emit`, host externals (§8),
generics and `behavior` dispatch, optionals, closures, primitive methods, and modules. 1.0.10-beta's
C-16 (`specs/1.0.10-beta/00-compiler-carry-over/README.md`) added front 12's steps 4.2–4.4 — a local
dependency, `@panic`/`@todo`, "no external target for the active backend" — and a cell per decision
63–66, plus the runner's tally (decision 59 (b)).

**Tests describe the language, not today's compiler.** A scenario the compiler gets wrong stays as
written and is red until the compiler passes it — the suite keeps no list of known failures
(§ A red cell is red). Never rewrite a test to match current behaviour.

## Layout

| Path | Kind | Passes when |
|---|---|---|
| `test/<area>_<group>.bp` | `test "…" { … assert … }` blocks, run by `botopink test --target <t> --json` | every test reports `ok` |
| `run/<name>.bp` + `<name>.out` | a whole program (`pub fn main`), run by `botopink run --target <t>` | exit 0 and stdout equals `.out` byte for byte — or, with a sidecar, § the sidecars of a `run/` cell |
| `reject/<name>.bp` + `<name>.expect` | a program that must not compile, run by `botopink check` | exit ≠ 0, stderr contains `.expect` line 1, and ` --> src/main.bp:<line 2>` — line 2 is required (C-21: every refusal is located) |
| `modules/<name>/` | a whole **project** — its own `botopink.json`, `src/` tree and `expected.out` — run by `botopink run --target <t>`; a second project inside it can be a `{ "path": "…" }` dependency; `"targets"` in its `botopink.json` narrows it (§ Narrowing a cell) | exit 0 and stdout equals `expected.out` byte for byte — or, with `<target>.expect`, § the sidecars of a `run/` cell |
| `modules/<name>/` with a `test/` tree and no `expected.out` | the `test/` kind over a whole project, run by `botopink test --target <t> --json` on commonJS, erlang and beam; results are keyed `modules/<name>::<test>` | every test reports `ok` |

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
Front 24's type aliases (decision 118 rule 1) add `run/type_alias` — `Id`, `Pair<A, B>`, `Ids` and
an `@Result` alias typing a function that only passes the value along, on all four targets — and
`modules/import_type_alias` — a `pub` alias imported like a type, the types its target names with it.
Decision 137 (`try` / `await` begin an expression) adds `run/try_start_positions` — a `val`
initializer, a call argument, an array and a tuple element, an `if` condition, a `case` subject, a
`for` iterable, `x = …`, a `return` and `try … catch` in an argument, on all four targets — and three `reject/` cells, one per operand
shape: `try_operand_of_operator` (`total + try r`), `try_in_parentheses` (`(try r).toString()`) and
`await_operand_of_unary` (`!await ready()`).
`residual-checker-3` reads decision 137 onto `if`: an `if` expression is never an operand, and
three `reject/` cells refuse it as `if-operand` at the `if` — `if_operand_of_operator`
(`1 + if (c) { 2 } else { 3 }`), `if_in_parentheses` (`(if (c) a else b).v`) and
`if_operand_of_unary` (`-if (c) 1 else 2`). The same front adds `run/narrow_in_logical_operands`
(the right operand of `&&` / `||` and a `while` body read the names the left operand's null test
narrows; a narrowed `var` is assigned its declared type, on all four targets) with
`reject/narrow_or_keeps_optional` and `reject/narrow_ends_at_assignment`, and two cells whose
checker half was right first and whose backend halves `residual-backend-3` closed: `modules/imported_fn_as_value` (an imported `pub fn` bound by a `val` and
passed as an argument) and `run/enum_implements_behavior` (an enum's behavior method called
through a behavior-typed parameter). C-04's last call path adds `run/associated_fn_default` (a
behavior's associated fn filled and reordered by label, generic included) and
`reject/associated_fn_missing_required`; decision 31 (`any` deleted) adds `reject/any_type_removed`
and `run/host_unknown_parameter` (`std/erlang`'s host vocabulary typed `unknown` takes an `i32`,
erlang and beam); C-21 adds `reject/decorator_argument_kind` (the one decorator refusal that had no
location), and the runner now requires every `reject/` cell's `.expect` to carry its `<L:C>` line —
every refusal is located.
Decision 138 (the empty record is `type Name()`) adds `run/type_empty_record` — `type Marker()` and
`type MathOps() { … }` constructed and called on all four targets — and two `reject/` cells,
`type_empty_braces` (`type Marker {}`), `type-without-field-list` where the `()` belongs.
Decision 329 (a namespace type) made `type MathOps { fn … }` legal when no function takes `self`:
`run/namespace_type` (associated functions, a generic one, one calling another, through the type, on
all four targets), `reject/namespace_type_self` (the old `type_without_field_list` cell: a `self`
function, refused `namespace-type-self` at the `self`) and `reject/namespace_type_construction`
(`MathOps()` refused `namespace-type-construction` at the call); the three were refused
`type-without-field-list` by the parent binary.
Decision 307 (a derived type, `01-checker` step 28) adds `run/derived_type_functions` (`Type.pick`,
`omit`, `partial`, `required` and `merge`, chained and nested, each constructed, read, passed as a
parameter, told apart from its source by `is` and printed by its own name, on all four targets),
`run/derived_type_decorated` (a decorator on the `val` sees a type whose fields keep the source's
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
`run/std_type_field_associated` (std's `Type.Field<T>` as a parameter type after `import {types.Type}
from "std"`, four targets) and `reject/assoc_type_named_like_member` (`pub type Point` beside `pub fn
Point`, `assoc-type-duplicate` at the type's name); the three were parse errors or `unknown type` on the
parent binary.
Decision 330 (`?T` read with TypeScript's operators, `01-checker` step 31) adds `run/optional_operators`
(`?.[i]`, `?.` flattened, the postfix `!` over a present value, four targets),
`run/optional_call_operator` (`f?.(args)`; wasm refuses a `?.()` over a function answering a plain
value by `wasm.expect` — `05-wasm`'s row) and `run/optional_bang_aborts` (`find("b")!` aborts after
`found` is printed — `.exit`; commonJS's stderr names `value is null — find("b")! at
src/main.bp:11:12`; erlang and beam abort with the text as an Erlang binary and wasm without it — the
backends' rows), and six `reject/` cells: `optional_operator_never_null` (`s?.length()`
with `s: string`), `nullish_never_null` (`s ?? "fallback"`), `bang_never_null` (`n!`) — each
`optional-operator-never-null` at the operator —, `nullish_beside_logical` (`flag ?? false && true`,
at the `??`), `optional_has_no_methods` (`.unwrapOr` on a `?string`) and `result_namespace_removed`
(`result.isOk(…)` is an unbound `result`). `reject/option_expect_removed` now answers
`optional-has-no-methods`. Every one was refused or accepted otherwise by the parent binary. The
suite's `.unwrapOr` on a `?T` became `??` (`scripts/codemod-optional-operators.py`), and a second
index of an index (`rows[1][0]`, `xs[k]` answering `?T`) is `rows[1]?.[0]` (`run/index_expression`,
`run/array_windows`). A method after a `?.` link continues its chain (`e?.key.length()`,
`run/optional_chain_method`): the chain runs under the `?.`'s guard.
`run/optional_member_default` — `xs.at(k)?.field ?? d` over a present and an absent element, a string
field, an empty array, an array built by `map` and one passed in, four targets (wasm printed the
element's address for the `map`-built array on the parent binary).
Decision 267 (a variadic parameter `..name: T[]`, front 134 step 4) adds `run/variadic_parameter` (a free
function with zero, one and three variadic arguments, a generic one, a method, an associated function, `@print`
with two arguments — four targets), `run/variadic_parameter_host` (a `declare fn` bound to `Math.max` /
`lists:max`; wasm refuses it at the first call by `wasm.expect`), `modules/variadic_across_modules` (an
imported variadic `pub fn`, four targets) and six `reject/` cells: `variadic_not_last`, `variadic_twice`,
`variadic_default`, `variadic_not_array` (parse refusals at the declaration), `variadic_spread_at_call`
(`variadic-spread`) and `variadic_label` (`variadic-label`). Every one was
refused or accepted otherwise by the parent binary. Decision 354 (step 6, contexts — it replaced 269's
`@getContext(T)`, whose `reject/getcontext_without_use` left) adds `run/context_provide_read` (a provider
reaches a component two renders below it; a `@Component` read with `use` reads its caller's map; a body
does not see its own provide), `run/context_nearest_wins` (the nearest provider wins, a sibling does not
see another's) and `run/context_unbound` (`context-unbound` at run time, `.exit` nonzero and the
message on stderr) — erlang, beam and commonJS run them, the wasm backend refuses the `use` where it is
written (`.wasm.expect`, `language-gaps.md`); and the refusals `reject/component_base_parameter`
(`@Component<C, R>` at the base), `reject/context_marker_removed`, `reject/renderable_type_argument`,
`reject/getcontext_removed`, `reject/context_provide_in_hook`, `reject/context_provide_after_render`,
`reject/context_hook_without_use`, `reject/context_hook_as_value`, `reject/context_not_declared`,
`reject/context_val_alias`, `reject/context_read_of_parameter`, `reject/use_in_comptime_block`,
`reject/use_in_decorator_body` and `reject/use_in_template_body` (`use-outside-render-tree`), each red on
the parent binary. Decision 354 took the base out of the wrapper, so `reject/component_two_bases`,
`reject/use_two_bases`, `reject/use_owner_mismatch` (decision 96's one base per body) and the arity
cells `reject/component_one_type_argument` / `reject/context_two_type_arguments` left with it.
Decisions 352 and 354, as `styled` registers through them (`08-bpp/119` step 1), add
`run/context_sheet_registers` — a context whose value holds a writer function, provided at the root; a
component computed at render reads it at its body's top and hands the writer its rule each time it
runs; a component run through a function value under a provider that keeps nothing registers nothing,
one that reads no context registers nothing — and `run/context_sheet_unbound` (`context-unbound`
naming the context, `.exit` and the three `.stderr`s); erlang, beam and commonJS run them, wasm refuses
the first `use` (`.wasm.expect`).
Decision 374 (a host-called `@Component` thunk captures the map) adds `run/context_host_thunk` — a lambda
written as a host argument read below a provider (a host that calls it at once, one that passes its own
argument, a declared component named as the argument, and one the host keeps and `main` calls twice after
the render) — erlang, beam and commonJS, red on the parent (`context-unbound` on commonJS, `badarity` on
erlang and beam); wasm refuses the first `use` (`.wasm.expect`).
Decision 375 (`HookNode.async`) adds `run/decl_hooks_async` (a synchronous `Card` and `Header`, an awaiting
`Comments`, a page `async` through it with no written `await`, a cycle, a function value) and
`modules/decl_hooks_async_imported` (an imported node's mark) on the four targets, and
`run/component_sync_plain_function` (commonJS only, `.targets` — the host `pending` has only a Node binding:
a call of a synchronous `Card` answers no `Promise`, one of the asynchronous `Post` does); each red on the
parent binary.
Decision 357 (the rules of hooks) adds `reject/use_in_if`, `reject/use_in_loop`, `reject/use_in_lambda`
and `reject/use_after_early_return` (`use-not-top-level`, naming the construct or the line) and
`run/use_conditional_argument` (a condition inside `use provide`'s argument, an `if` that does not
return before a `use`); `reject/use_after_return` and `reject/generator_loop_use` now meet
`use-not-top-level`, and `reject/use_inside_branch` / `reject/use_in_closure` left for `use_in_if` /
`use_in_lambda`.
Decision 277 (`decl.hooks`, `01-checker` step 23) adds `run/decl_hooks_direct` (a host hook: one node;
commonJS, erlang and beam — `session` has no wasm binding), `run/decl_hooks_all_nodes` (four nodes, a
component once, calls in body order), `run/decl_hooks_custom_hook` (a hook's own node),
`run/decl_hooks_cycle` (an edge back), `run/decl_hooks_function_value` (`hook: null`),
`run/decl_hooks_type_args` (a `use`'s type arguments with their fields, decision 293),
`run/decl_hooks_context` (each `provide` / `context` with its context object, 354 (4); wasm refuses the
`use`) and `modules/decl_hooks_imported` (another module's nodes, a hook through an alias with its own
annotations), on the four targets but where named; each red on the parent binary (`unknown field 'hooks'`).
Decision 371 (`Decorator.same`) adds `modules/decorator_same` — a package `web` whose `check` compares
each annotation's `decorator` with `serverOnly` and with itself: `#[srv]` under `import {serverOnly as srv}
from "web"` is `web`'s, the project's own `serverOnly` reached as `#[local.serverOnly]` is another
declaration (`other`); four targets — and `reject/decorator_same_not_decorator` (`same("serverOnly")`, a
type mismatch at the argument); the parent binary had no `same`. Decision 372 (a `.hooks` reader runs
after the module's bodies) adds `run/decl_hooks_reads_member` — `#[graph]`'s `Page` calls
`Account(…).validate()`, which `#[check]` adds below it; four targets, red on the parent binary
(`'validate' is not declared`) — and `reject/decorator_hooks_output` (`decl.addMember` in a decorator
reading `decl.hooks`, `decorator-hooks-output` at the call; accepted by the parent binary),
`reject/decorator_hooks_output_member_fn` (the same refusal of decision 370's typed
`decl.addMember(name, fn…)`) and
`reject/typeinfo_all_hooks_reader` (`@TypeInfo.all(with: graph)` in the module of `#[graph]`'s `Page`;
answered by the parent binary).
Decision 139 (a negative index counts from the end) adds `run/index_negative_from_end` — `xs.at(-1)`,
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
1.0.11-beta `01-checker` step 1 (decision 150, D5) adds `run/array_literal_union` (`[1, "a"]` is
`(i32 | string)[]`, an expected union takes its members; four targets), `run/array_literal_numeric_join`
(`[1, 2.5]` is `f64[]` — the `1` is `1.0` on every target — and `[1, null]` is `?i32[]`),
`reject/array_literal_union_misuse` (an element used as an `i32` without narrowing, refused at the use
naming the widening element) and `test/case_value_union` (a `case` whose arms disagree is the union,
read back through `case` narrowing, beside the array literal's union). The `case` half is a `test/`
cell because wasm traps on a union of primitives produced by a `case` (`05-wasm`'s row); each array
cell was refused by the parent binary.
Step 2 (rows 28 and 31) adds `run/case_function_typed_arms` (two arms answering `fn(string) -> string`
join into that type and the result is applied, four targets), `reject/case_function_arms_arity` (arms
whose arity differs are refused at the second) and `test/case_arm_lambda_value` (`A(x) -> { item ->
f(item) }` is a lambda value; a `test/` cell because beam answered `{badfun, ok}` for a lambda a `case`
arm produces — `03-beam`'s row). Each was refused by the parent binary. `03-beam` step 9 moved the
last to `run/case_arm_lambda_value` (four targets print `a?` / `b`) and deleted row 28.
Step 3 (decision 151, row 22) adds `reject/section_body_method` (a `fn` in a section body is
`section-body-method` at the `fn`), `run/section_numeric_leaf_standalone` (`val n: Tok.Percent =
.50;`, a leaf argument, and a section-typed field of a payload variant built with `.100`, four
targets) and `reject/section_numeric_leaf_without_expectation` (`.50` with nothing expected names its
section). A section leaf prints as its mangled name (`__Tok__Percent.__50`) on every target, so the
cell reads it through `==`. Each was refused by the parent binary.
Step 4 (row 32) adds `reject/call_of_record_value` (`val g = G(a: "x"); g()` is
`callee-not-a-function` at `g(`, beside a constructor and a function-typed field that still check)
and `modules/call_of_imported_record_value` (the same through a sibling's `pub val`, by
`<target>.expect` on all four); both were accepted by the parent binary.
Step 5 (decision 152) adds `reject/binding_redeclared_in_body` (a second `var n` in one body) and
`reject/binding_shadows_parameter` (`val x` over the parameter `x`), both `binding-redeclared` at the
second binding and both accepted by the parent binary. Decision 205 (the body is the whole function)
adds `reject/binding_shadows_in_inner_block` (an inner block's `val y` over the function's `y`) and
`reject/case_arm_binder_reuses_name` (a `case` arm's `Square(s)` over the parameter `s`), both
accepted by the parent binary. `04-js` step 4 adds the half decision 205 keeps,
`run/sibling_blocks_bind_one_name`: an `if` and its `else`, two `if`s, two loop bodies and two
`case` arms' binders each binding one name, and a block's `n` followed by the function's own `n`
once the block has closed — four targets, green on the parent binary (it pins that no backend
leaks a block's binding or invents a scope for it).
`run/unwrap_or_literal_width` (another front's finding) — an integer literal as `unwrapOr`'s default
takes the payload's width over `?i64` and `@Result<i64, string>` (refused as `expected i32, got i64`
by the parent binary).
`run/std_type_ctor_through_namespace` (another front's finding) — `url.Url(…)` after `import {url}
from "std"` constructs the type through the module namespace, as the leaf `Url(…)` does (`this "std"
module has no such public function` on the parent binary), four targets.
Decision 170's type half (other fronts' findings) adds `run/std_namespace_beside_own_type` (a
module's own `type Dict` beside `import {collections}` is the module's, four targets),
`modules/std_namespace_beside_aliased_type` (`import {kit.store.Dict as OwnDict}` beside the same
namespace reads `kit/store`'s fields; the cell builds the value through a function of `kit/store`,
because commonJS emits `Dict(5)` without `new` for an imported record constructor beside a std
namespace declaring the same name — `04-js`'s row),
`reject/std_namespace_signature_names_shadowed_type` (a namespace call whose signature names the
shadowed std type), `modules/import_two_types_one_name` and `reject/own_type_beside_std_type_import`
(two types of one declared name in one module, aliased or not, are `import-name-collision`). Each
was accepted wrongly or refused with the wrong type by the parent binary.
`reject/behavior_default_fn_body_checked` and `test/behavior_default_fn_result` (another front's
finding) — a behavior's `default fn` body is checked (an unbound call is refused at it), and a
`-> @Result` default fn wraps its `return` and `throw`, its adopted call answering the `@Result`; a
`test/` cell because beam answers `{unresolved_method, …}` for any adopted default (`03-beam`'s row).
Step 12 (T9) adds `reject/reserved_word_as_binding_name` — `val unknown: i32 = 1;` is
`reserved-word-as-name` at the name; it passes on the parent binary too (the row closed before this
front) and pins the rule.
Step 11 (T11) adds `run/nullish_tuple_operand` (a tuple literal on the right of `??`) and
`run/postfix_on_grouped_nullish` (`(xs.at(0) ?? d)._1`), four targets, integer elements because wasm
reads a `string` element of a tuple through `??` as its address (`05-wasm`'s row); both refused by
the parent binary at the `#`.
Step 8 (decision 45) adds `reject/tuple_label_on_optional` (`rs.at(0).b` names `?.`) and
`run/tuple_label_through_optional` (`rs.at(0)?.b` reads the label through the optional, four
targets); both pass on the parent binary — the checker half landed with decision 45 — and pin it. The
absent half (`?.b` on a `null`) traps on wasm and raises `badarg` on beam (the backends' rows).
Step 15 (report L, R3) adds `modules/imported_type_field_closure` (package `a`'s `Client(life:
Life, …)` with `Life` in a sibling module, imported by package `b` as `Client` alone and called from
the root, four targets) and `modules/imported_declaration_error_location` (a type error inside the
dependency's declaration is located at `a/client.bp`, by `<target>.expect`). Both pass on the parent
binary — the row no longer reproduces at this base, and rakun-metrics' `export_test` passes with its
`CacheLife` workaround removed — and pin it.
Step 6 (decision 147) adds `reject/try_in_lambda_without_result` (`[1, 2].forEach({ x -> try
bad(x); })` refused at the `try`) and `run/lambda_result_return_try` (a lambda under an expected
`fn(x: i32) -> @Result<i32, string>` — a `val` annotation and a parameter — `try`s, `return`s and
`throw`s, four targets); the parent binary accepted the first and refused the second. A
`throw_in_case_arm_result` cell is not added: erlang answers `false` for `isError()` on the arm's
`throw` (`02-erlang`'s row), the other three answer `true`.
`run/generic_ctor_fallible_lambda_fresh` (decision 147 beside a generic constructor) — two methods of
`Box<T>` each build a `Box(run: { … })` under the fallible field, one `Box<?T>`, one
`Box<Array<T>>`, on all four targets; the parent binary refused the second as `expected ?_[], got
?_` (the lambda's expectation was the constructor's registration-time cells).
The cell `modules/shorthand_import_beside_bundled_package` (decision 170) was deleted with decision
326: its subject — a shorthand import beside a bundled package — left when `routing` stopped being
bundled, and the shorthand itself goes with decision 337 (`01-compiler/129`).
Step 7 (decision 148) adds `reject/captured_var_write_in_lambda` (`run({ -> n = n + 1; 1; }, 0)` is
`captured-var-write` at `n =`; accepted by the parent binary) and `run/closure_capture_statement_position`
(a `forEach` body, a local closure called as a statement — directly, in a `for` body and in a
`forEach` body — and a module-level `var` written from any lambda, four targets; it passes on the
parent binary too and pins the legal shapes).
`reject/generic_index_answers_optional` and `run/generic_index_optional_return` (another front's
finding) — `return xs[0];` under `-> T` is the type mismatch naming `T` and `?T` (it was `recursive type
detected`), and the same functions declared `-> ?T` run on four targets.
Decision 207 (an inline parameter type) adds `run/inline_param_type` (built from the call's labels in
any order with a default left out, forwarded, beside an ordinary parameter, four targets), the parser's
refusals `reject/inline_type_in_{return,field,val_annotation}` (`inline-type-outside-parameter`), the
checker's `reject/inline_type_on_method_param`, `reject/inline_type_twice_on_one_fn`,
`reject/inline_type_field_named_like_param` (`inline-type-position`), `reject/inline_type_missing_field`
and `reject/inline_type_unknown_field` (named by the owner, ``the props of `link` ``), and
`modules/inline_type_across_modules` (a call from another module that writes the fields is refused;
the declaring module's own call runs). All sixteen fail on the parent binary.
Decision 208 (`Ok` / `Error` are never constructors) adds `reject/result_ok_constructor` and
`reject/result_error_constructor` — `unbound variable` at the name; both pass on the parent binary and
pin the rule.
Decision 209 adds `run/integer_literal_fits_f64` (an integer literal under an expected `f64` — a
`val`, an `f64[]` element, an argument, a return, an arithmetic operand — prints as the float, four
targets; refused by the parent binary) and `reject/i32_value_never_widens` (an `i32` value passed to an
`f64` parameter is the mismatch; it passes on the parent binary and pins the half that stays).
Decision 215 adds `reject/f64_equals_integer_literal` (`x == 2` with `x: f64`) and
`reject/f64_not_equals_integer_literal` (`3 != x`), refused at the literal naming the float to write;
the beam codegen test `is and == read numbers by value …` no longer prints `2.0 == 2` (it answered
`false`). Both accepted by the parent binary.
Decision 255 (1) (a type application before a member) adds `run/type_application_static_member` —
`Dict<string, unknown>.empty()`, `Dict<string, i32>.empty()` chained, `Box<i32>.make(7)`,
`Opt<string>.None` and `Opt<i32>.Some(3)`, beside `a < b`, `x < y && z > w` and
`both(a < b, y > x)` that stay comparisons, on all four targets — and four `reject/` cells:
`type_application_argument_mismatch` (`Box<i32>.make("x")`, at the argument),
`type_application_argument_count` (`Box<i32, string>`, at the name),
`type_application_variant_payload_mismatch` (`Opt<i32>.Some("a")`) and
`type_application_on_a_field` (`Box<i32>.value` — only a unit variant is read without a call). All
five fail on the parent binary (`unexpected ','` / a comparison).
Decision 255 (2) (`comptime <expr>` is `comptime { break <expr>; }`) adds `run/comptime_expression_is_block`
(a module-level shorthand equal to its block form, and the same in a body) and
`run/comptime_expression_static_call` (the decision's own `val d: Dict<string, unknown> = comptime
Dict.empty();` beside its block form), and `reject/comptime_expression_type_mismatch` (the
expression's type is the form's, located at `comptime` as the block's is).
Decisions 266 and 331 (`01-checker` step 21 — every `comptime` runs on the comptime runtime, BEAM or
WAT by the target, never on the target, and its value is written into the program) give
`run/comptime_expression_static_call` all four targets (its `.wasm.expect` is gone: the `Dict` is
written as its constructor) and add `run/comptime_block_with_loop` (`comptime two()` emits `2`; a
block with a call and a loop answers `6`; a loop pushing strings answers the array — one `.out` on
the four targets; the parent binary refused the block on erlang, read `d` unbound on commonJS and
had no wasm lowering), `run/comptime_val_after_import` (step 20's finding: a module-level
`comptime` `val` after an import, dropped on commonJS by the parent binary; a call and a record at
module level), `run/comptime_function_reference` (a `Dict` of a declared function and a lambda
reading nothing the block declares, written back as the reference and the lambda — rakun's bean
catalogue shape) and `reject/comptime_value_not_liftable` (a lambda capturing the block's `val`,
`comptime-value-not-liftable` at the `comptime`; the resource half is `block_eval.zig`'s unit test —
the WAT runtime has no process to answer, so no one cell refuses it the same way on both runtimes).
06-emilia/34 step 5's two comptime rows (a nested-section enum value at comptime; emilia's dispatcher
at comptime) add `run/comptime_enum_section_value` (`.Pad.All.8` as an argument, in an array, inside
a payload variant, and written back from `comptime first(…)`, `comptime padX()` and an array — four
targets; the parent binary raised `{error,{badmap,'Pad'}}`), `run/comptime_decorator_section_value`
(`#[mark(.Pad.All.4, .Bold, Tok.Pad.All.8)]` read as `tokens.value`, and a function the decorator
reaches writing `.Pad.All.8`; the parent raised `{badmap,'Pad'}` at the annotation),
`modules/comptime_imported_section_path` (an imported enum's section value from an imported function
and back into this module; the parent's comptime module called an undefined `Pad/1`),
`reject/comptime_section_path_declared_after` (a section path in a function declared after the
`comptime` that reaches it, refused naming the path and the function, as a template call there is)
and `run/comptime_record_pattern` (a record matched on the comptime runtime as its untagged map — a
constructor pattern in an arm and in a `val`, `is`, an arm naming `Block`, a record and a section's
variant; the parent's lowering failed `MissingPackage`).
`01-compiler/14` step 8 (decision 355) adds `run/styled_holes_known_at_build` (a template of the
cell's own reads each hole's `known` / `value`: a literal, a `val`, another expansion with no
run-time hole and a `comptime` are written at build, a parameter and a call computed at render —
four targets; the parent binary fails the body at `badkey known`), `modules/comptime_reaches_package_template`
(a `comptime` over a package template's expansion, whose built code calls the package's function
under its alias, and a record of the package's type written back where the module does not import
it — the parent binary aborted the compiler), `run/comptime_interpolation_in_called_fn` (`"${…}"` in
a function a `comptime` calls), `reject/comptime_template_call_declared_after` and
`reject/hole_known_at_build_raises`.
`01-checker` step 41 (decision 429) adds `run/template_two_alike_expansions` (two expansions of one
template whose built code sits at the same offsets — `r.length` over an array and `r.w` over a
record; the parent binary lowered the first with the second's field access on erlang),
`run/template_default_arg_two_expansions` (a call that leaves out a default argument and a call of a
one-parameter function at the same offset of two expansions; the parent binary filled the default
into the second, `footer/2 undefined` on erlang) — four targets, no padding — and
`reject/template_built_code_diagnostic_located` (a diagnostic in built code at the literal's line and
column plus its offset; the parent binary located it at `1:20`).
`test/program_primitive_behavior_extends_std` and `reject/program_primitive_behavior_redeclares_std`
(another front's finding) — a program's own `behavior String` adds members to std's `String` (its
default fns call `slice`, `startsWith`, `length` on `self`, and std's members answer beside them),
and redeclaring a std member is `behavior-member-redeclared`. `run/program_primitive_behavior_extends_std`
is its `run/` twin on all four targets (`botopink test` runs neither wasm nor beam), a
`behavior Number` default beside it; wasm called no program-declared default fn of a primitive
(it trapped) until `05-wasm`'s `lowerPrimDefault`. Both refused by the parent binary.
`run/program_array_behavior_default` does the same for a program's `behavior Array<T>` — defaults
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
Decision 141 adds `run/external_template_refused_on_beam` — an `@External.Erlang` template with a
macro runs on erlang and is a located build error on beam naming the construct (`.beam.expect`); beam
no longer evaluates a template it cannot compile from source at run time.
Decision 216 (front `130-decorator-outputs`, what a decorator produces) adds, for its first place —
`decl.addMember(source)`, a member of the annotated type — `run/decorator_add_member` (an associated
fn and a method added by a type's decorator and one added by a field's, beside a hand-written
member) and `modules/decorator_add_member_import` (the members travel with the type: an importer
calls `City.fromRow(r)` through a plain import and an alias), on all four targets, and three
`reject/` cells at the annotation: `decorator_add_member_on_fn` (`decorator-member-without-type`),
`decorator_add_member_duplicate` (`decorator-member-duplicate`) and `decorator_add_member_not_one`
(`decorator-member-not-one-fn`), and one where the call is written: `decorator_member_unknown`
(`unknown-associated-fn` — a type's members are closed, so `City.revisions()` on a type no
decorator gave it is refused). Its second place — `decl.setMeta(key, value)`, read as
`@typeInfo(X).meta.<decorator>.<key>` — adds `run/decorator_set_meta` (two decorators' keys on a
type, a `fn`'s meta, `.name`, a read held in a typed `val` and continued by `.length`) and
`modules/decorator_meta_import` (meta read through a plain import, an alias and a namespace import),
on all four targets, and four `reject/` cells: `typeinfo_meta_missing` and
`typeinfo_unknown_declaration` where the read is written, `decorator_meta_duplicate` and
`decorator_meta_on_member` at the annotation. Its third place — `decl.addType(name, source)`, an
associated type named `Owner.Name` — adds `run/decorator_add_type` (a record `City.Columns` in type
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
`typeinfo_all_with_number` — are the ordinary type mismatch at the argument; `run/typeinfo_all_decorator_argument`
accepts a decorator with arguments, a single decorator and a list of them); decision 353 (a template function's body reads the catalogue of the program that expands it) adds
`modules/template_reads_program_catalogue` (a package's `pub default fn` counting the application's
`#[theme]` — one, declared in a module analysed after another expands the template — and an empty
`#[palette]`, on all four targets), two project refusals at the expansion, `template_catalogue_two_themes`
(the template's own `e.fail` naming both declarations) and `template_catalogue_private`
(`typeinfo-all-private`), `typeinfo_all_imported_package_default` (`import cat from "cat"` naming a
reader's default fn, `typeinfo-all-imported` at the handle) and `reject/typeinfo_all_template_value`
(a template body reading an entry's `value`); decision 235's list form adds
`run/typeinfo_all_list` (two decorators in one `with:`, declaration order kept, a type carrying two
of them answered once with both decorators' meta) and `reject/typeinfo_all_list_twice`. Decision 248
names the one reflection builtin `@typeInfo` (the structural `TypeInfo` answer of a bare
`@typeInfo(T)` folded in): `reject/typeinfo_lowercase` and `reject/typeinfo_all_lowercase` refuse
the lowercase `@typeinfo(…)` / `@typeinfo.all(…)` where it is written (`typeinfo-lowercase`).
Decision 253 makes the catalogue the static `@TypeInfo.all` of the builtin type:
`reject/typeinfo_all_on_function` refuses `@typeInfo.all(…)` (`typeinfo-all-on-function`).
Decision 356 (a decorator on a `val` runs, and the `val` is catalogued) adds `run/val_decorator_catalogue`
(`DeclKind.Val`, the declared type as `returnType` and `returnTypeName`, `setMeta` read by
`@typeInfo(<val>)`, both `val`s answered by `@TypeInfo.all`, four targets) and five `reject/` cells at the
annotation or the query: `val_decorator_on_var` (a decorator on a module `var`, refused until `116-c` is decided), `val_decorator_runs` (`#[mark] pub val one = 1;` fails with the decorator's
message — the parent binary printed `1`), `val_decorator_add_member` and `val_decorator_add_type`
(`decorator-member-without-type` / `decorator-type-without-owner`, "the val") and
`typeinfo_all_val_and_fn` (`typeinfo-all-mixed`: a `val` and a function under one query). Decision 361
(std's `bpp` annotations; front 116 step 1) adds five `reject/` cells where std's decorators refuse a
role's place — `bpp_html_on_val`, `bpp_style_on_val`, `bpp_html_not_template` (a function not
answering `@ExprCustom<R>`), `bpp_prelude_on_fn`, `bpp_style_prelude_on_fn` — and ten `modules/bpp_*`
projects over a fixture package `markup` (not jhonstart): `bpp_roles_found` (the key, the roles
`#[bpp.html]` and `#[bpp.htmlPrelude]`, no `.bpp` file: accepted, four targets) and nine refused on every
target — at the `"bpp"` key `bpp_key_object_form`, `bpp_key_not_a_dependency`, `bpp_html_missing`,
`bpp_html_twice` and `bpp_prelude_twice` (naming the declarations), in the package's file
`bpp_prelude_holds_declaration` and `bpp_role_not_pub`, at the `.bpp` file `bpp_file_without_key`
(line 1) and `bpp_style_section_without_style` (its `--- style ---` line). Every one was red on the
parent binary.
Decision 254 types the answer `Declared<unknown>[]` whatever the program declares:
`run/typeinfo_all_unknown_value` catalogues two functions of different signatures in one answer
(each naming its declared return type, `returnTypeName` — decision 256; `run/typeinfo_all_list` reads
it `""` for a type), and
`reject/typeinfo_all_value_unknown` refuses an entry's `value` used as a function without a test.
The registration and list cells therefore read `name`, `module` and `meta` only. Front 130 adds
the narrowing (decision 254): `run/is_fn_narrows_unknown` narrows an `unknown` with `is fn(<params>)
-> T` and calls through it — a stored factory, a lambda, a top-level fn, a value of another arity,
a string and a number — on all four targets; `run/is_fn_wrong_arity_fails` (`.exit nonzero`) is a
resolver narrowing a stored `fn(i32) -> i32` with `is fn() -> Clock` and panicking with the entry's
name and the expected type (the message is on stderr; wasm's `@panic` is a trap with no text); and
`reject/call_unknown_without_narrowing` refuses calling an `unknown` that no test narrowed.
`run/fn_local_rebound_call` calls a fn-typed local at its current binding — a `val v` narrowed
by `is fn() -> i32` in two sibling `for` bodies, a reassigned `var f`, a second `val f` lambda —
on all four targets (erlang applied the first binding's `V` where the second was `V@1`).
Decision 252 (every builtin declared, a call held to its declaration) adds
`reject/builtin_arguments` — `@panic` given a second argument its declaration does not have,
`builtin-arguments` at the call. Decision 322 (`is` is only an operator) adds
`reject/hand_written_is_builtin` — `@is(1)` written by hand, `unknown-builtin` at the `@`.
Decision 307 adds `run/std_types_module` — `import {types.Type} from "std"` resolves on all four
targets (std's `types.bp`, exported by `root.bp`).
C-03's beam half adds `run/std_template_host_fns_across_modules` — std host functions whose
`@External.Erlang` body is a template (`fs.exists`, `fs.readText`, `os.eol`, `process.platform`,
`encoding.hexEncode`, `hash.sha256`, `json.quote`, `regex.matches`) called from the program's
module through a folder namespace and a leaf import, on commonJS, erlang and beam (`.targets`: wasm
refuses `io/fs`, decision 241's group 3).
`01-compiler/05-wasm` step 5 adds a cell per std module family, the commonJS answers on four
targets: `run/std_encoding_on_every_target` (base64, base64url, hex, percent and form codecs over
ASCII to astral text, each decoder's refusal) and `run/std_querystring_on_every_target` (query and
form bodies, each refusal); `run/std_json_on_every_target` (writers, `unquote`, `decode` and its
accessors, the host round-trip) runs on three and is refused on wasm by name (`.wasm.expect`) until
`decisions-pending.md` 05w-j binds `json.parse` / `stringify` there; `run/std_unicode_on_every_target`
(`fromCodepoint`, `codepoints`, `firstCodepoint`, the four normalization forms — std's botopink
normalizer, decision 333 (A)) has one `.out` for the four targets. Two cells pin the wrong answers wasm gave those families at exit 0, each failing
on the parent binary: `run/std_namespace_calls_same_name` (`querystring.parse` and `url.parse`
through their namespaces — the mangled one's receiver was dropped) and `run/tuple_optional_element`
(a `?T` in a tuple — printed, read through `._N`, a generic method's `#(Q<T>, ?T)`, and
`o.unwrapOr(d)` keeping a tuple's shape).
The backend rows of `status.md` (`front/backend-rows-2`) add, each failing on the parent binary
on the targets named: `run/case_arm_record_named_like_a_variant` (a `case` over `Block | Vec` naming
a record an enum section also declares as a variant — erlang `case_clause`, wasm a trap, beam the
subject itself), `run/array_last_index_of` (all four; `Array` declared no `lastIndexOf`),
`run/array_pop_removes` (erlang and beam read without removing, wasm trapped),
`modules/module_var_self_registration` and its `_test` twin (a module-level `var` grown by `push` at
module load — erlang and beam dropped the write), `run/index_answer_typed_optional` and
`reject/index_answer_is_optional` (`xs[k]` is `?T`; wasm's `?Color` compare and `??` binder),
`run/integer_literal_labelled_field` (a literal in a labelled `i64` field, every target),
`run/std_unsupported_names_the_call` (STD-001 names the function called, at the call),
`run/behavior_method_dispatch_by_value` (wasm dispatches a behavior-typed call),
`run/string_char_code_non_ascii` (wasm answered bytes), `run/val_assert_variant_pattern` (commonJS
`ReferenceError`, beam `{unassigned, …}`) and `run/is_enum_variant` and
`modules/renderer_record_field_shapes` (shapes the rows measured, which no longer reproduce — pinned).
1.0.11's `01-compiler/05-wasm` step 1 adds one cell per primitive-method group wasm trapped on, each
`.out` shared by four targets: `run/string_lines_words` (`lines` — `\r\n`, a trailing `\r` kept, `""`
one empty line — and `words` over blanks), `run/array_flat_forms` (`flatten`, `flat`, `flatMap`
over integers, strings, a local, a parameter and an annotated empty `i32[][]`), `run/array_windows`
(`chunked`, `sliding`, `n <= 0`, a slice indexed and measured) and `run/array_fill` (a value of
each primitive, an empty receiver). `pop` is `run/array_pop_removes`; `unique`'s cell is
`02-erlang`'s `run/array_unique` (C-35).
`run/generic_field_fn_value` — a top-level fn stored in a generic record's field (`Box<T>(value: T)`)
and called through the field, through an untyped local and through a generic wrapper, and a lambda
stored there typed by those calls, by a `val`'s annotation, by a parameter and by a return type —
answers the fn's own result on commonJS, beam and wasm (wasm printed a string's address, a bool as
`1`, a lambda's string parameter as an integer; front 130's row); erlang refused `h.value("b")` (`function value/2 undefined`) until a field written as a type parameter was applied like a `fn(…)` one (`codegen/AGENTS.md`).
Step 2 adds `run/generic_string_equality` — `==` / `!=` between two type-parameter values bound
to strings built at run time, by a call's arguments, an array's elements, a generic record's
constructor and a generic call answering one, a parameter written `Pair<T>`, a variant's payload,
an array of such records under `map`, and a generic fn handed to a `fn(a: string, b: string) ->
bool` parameter or bound to a `val` of that type — on four targets; wasm compared words for the
record, generic-result, `Pair<T>`, array and fn-value rows.
`00 · 03-beam`'s split row adds `run/string_split_empty_separator` — `split("")` cuts into UTF-8
codepoints (`"%0Aéz"` → 5 pieces, `""` → none) beside a non-empty separator and an empty separator
held in a `val`, on all four targets (beam lowered it to `string:split/3`, wasm cut between bytes).
`01 · 03-beam` step 1 adds `run/ctor_pattern_in_val_binding` — `val Label(t, w) = Tag.Label(…)`, a
one-variant type's constructor in binding position, prints `7` on all four targets (beam bound
nothing: `{unresolved_identifier, t}`), and `modules/import_capitalised_fn` — an imported `pub fn Make`
called with labelled and positional arguments, on all four targets (beam built `Make(n: 4)` as the
record `#{n => 4}`).
01-std step 2 adds `run/std_asserts_on_every_target` — `import {testing.asserts}` and its pure
assertions on commonJS, erlang and beam — and `run/std_asserts_host_cell_on_wasm` — `asserts.deepEquals`
on the same three. wasm refuses both at the import (`.wasm.expect`): `deepEquals` calls `canonical`,
which has no wasm binding, a function reaching such a cell is refused called or not (decision 146),
so `testing.asserts` does not build there and the import that links it says so, naming the cell. The same front's `reject/result_field_read` and
`reject/result_unknown_method` refuse a member of a `@Result` that is not one of its methods
(`result-member-not-a-method`).
The onze front's compiler findings (`specs/1.0.10-beta/06-onze/49-onze-stand-up`, F1–F10) add a
cell each: `modules/pub_val_in_a_test` (F1 — a sibling's `pub val` read by a TEST: the erlang runner
did not load the sibling; the first project cell of the test kind), `modules/import_type_closure_across_modules`
(F2 — `import {Canvas}` from a local dependency whose fields name types of the package's other
modules), `run/unwrap_or_positions.bp` (F4/F9 — `xs.at(i).unwrapOr(d)` in a method, as the branch of
a parenthesised `if` read with `.v`, nested in another `unwrapOr`, over an unannotated `map`),
`modules/src_at_package_root` (F5 — `"src": "."`, a test importing `lib.db`),
`run/string_slice_in_if_branch.bp` (F6 — a one-argument `slice`, an array `slice` and a string
template as the value of an `if` branch), `run/integer_division_truncates.bp` (F7 — integer `/`
truncates toward zero on every target, float `/` stays float) and `modules/lexer_error_in_imported_module`
(F8 — every target refuses the project with `bad string escape` located in the imported module, via
`<target>.expect`). The erlang float-literal item adds `run/float_literal_spellings.bp` (`1e3`,
`2.5E3`, `3e+2`, `5e-1`, `1_000.5` are `f64` on all four targets) and
`run/number_literal_erlang_spellings.bp` (`5e-324`, the largest `f64`, an `f64` record field and
`0xFF + 0b101 + 0o17`, on all four targets — wasm since its float literal is an `f64.const` and its
radix literal a decimal `i32.const`).
The backend and runtime rows of `00` (`front/codegen-rows`) add a cell each, every one failing on the
parent binary: `run/task_await_in_if_block` (an `if` block that `await`s without returning, inside a
`@Task` body — commonJS lowered it into a plain arrow and the module did not load),
`run/task_void_return_in_if_block` (a bare `return;` in an `if` block of a `@Task<void>` body — wasm
emitted a `return` with nothing on the stack), `modules/dependency_files_order` (a dependency whose
`files` lists every importer before what it imports, `import {a.base};` and a bare `import {Leaf};`),
`run/external_erlang_host_module_missing` (`.targets` `erlang beam`: an `@External.Erlang` module that is
neither shipped nor in the Erlang code path is a located build error on both, `.erlang.expect` and
`.beam.expect`),
`modules/erlang_host_sidecar_shipped` (a project's `src/sidecars/*.erl` reached by `botopink run` on
erlang and on beam; `commonJS.expect` / `wasm.expect`), `modules/erlang_sidecar_named_like_a_module` (a
sidecar `text.erl` beside the module `text.bp` is shipped — the shipper skipped a basename match),
`modules/sidecar_called_from_folder_module` (front 26, T16: a sidecar called only from `src/orm/entity.bp`
is shipped on erlang and beam although the cell's own `libs/orm/` — a library root the walk-up finds —
carries a package named like the folder; the shipper took that package for the module's owner) and
`modules/sidecar_named_like_emitted_atom` (front 26, C-25: `src/sidecars/language_tests@text.erl`, named
like the atom `src/text.bp` compiles to, is a located build error on erlang and beam naming both,
`erlang.expect` / `beam.expect`), `reject/bare_print_call` (`println(x)` is unbound
and the refusal names `@println`), `run/float_record_field` (an `f64` record field read, compared,
destructured by name and by constructor, and through a method taking and answering an `f64` — wasm
narrowed and bit-read it, erlang and beam did not lower `val Pt(y, _) = p`) and
`modules/linked_fn_name_collision` (two modules each declaring `parse`, reached by their own calls, a
plain import and an aliased one — wasm's one flat namespace). `run/val_assert_record_pattern` (a
`val assert` over a record's constructor pattern — commonJS destructured the binders' own names,
erlang tested a tag no constructor builds) came out of the same work; wasm and beam followed.
C-04 across a module boundary adds `modules/default_argument_across_modules` — a call omitting
trailing defaulted parameters of a sibling module's and of a path dependency's function, one label
claiming its parameter, on all four targets — and `modules/default_argument_open_across_modules`: a
default that names a private function of its module does not travel, so omitting it from another
module is the arity error, on every target (`<target>.expect`).
The rakun rows of `language-gaps.md` (the language-gaps sweep, `front/compiler-gaps-rakun`) add a
cell each, every one failing on the parent binary: `run/behavior_method_by_receiver_type` and
`run/behavior_method_host_value` (a method a `behavior` declares is the VALUE's, beside another type
declaring the same name — an implementer's, a host-built one, on an unannotated local; the
host-built one's `.targets` is `commonJS erlang beam`, wasm having no host vocabulary for it), `modules/behavior_method_imported` (the
same for an imported behavior; `wasm.expect`), `run/behavior_value_from_implementer` (an implementer
converts to its behavior at an annotated `val` and a `var`), `modules/behavior_across_modules` (an
imported behavior is the same type in its importer; an imported fn-type alias resolves its names in
its own module), `run/return_nested_in_if_block` and `run/return_in_case_arm_statement` (a `return`
at any depth of a statement ends the function), `run/result_method_throw` (a METHOD returning
`@Result` wraps its `throw` / `return`), `modules/test_in_subdirectory` (a test file in `test/unit/`
reaches the project on erlang), `run/record_method_named_length` (a type's `length` method never
answers an array's `length`), `modules/imported_fn_field_call` (a function-typed field of an imported
record is applied), `modules/method_on_unimported_type` (a method on a value whose type the module
never imported: std's `Dict`, and another imported type declaring the same method),
`reject/method_missing_argument`, `reject/method_extra_argument` and `run/method_default_argument` (a
method call's arity), `run/result_pattern_beside_enum_variant` (`Error(e)` over a `@Result` beside an
enum declaring `Error`), `run/decorator_calls_module_function` and
`modules/decorator_imported_calls_module_function` (a decorator body calls its module's
functions), `run/decorator_emitted_proxies_dispatch` (two proxies a decorator emits call their own
types) and `modules/namespace_import_module` (decision 107's namespace form over a dependency's
module and the project's own).
The second language-gaps sweep (`front/gaps-sweep-2`) adds a cell per row it fixed, every one
failing on the parent binary: `reject/result_void_falls_off_end` (decision 2 over an effect return —
a `@Result` in any layer, `@Result<void, E>` included, and a `@Task` / `@Component` whose value is a
value, end with `return`), `modules/narrowed_optional_std_field_across_packages` (a method chain on a
field of a narrowed optional, and of an optional binder, whose type another package declares and
this module never names — its field a std type only that package imports;
`modules/generic_type_through_imported_function` keeps two instances of such a generic type apart),
`modules/decorator_argument_default` and `reject/decorator_default_not_closed` (a decorator
argument the annotation leaves out takes its closed default; one naming a binding is refused at the
annotation), `run/record_update` and `reject/record_update_base_not_a_name` (decision 37's
`Name(..base, f: v)` builds the record it means on every target; the base is a name or a path of
names), `run/explicit_type_arguments_on_a_method` and
`reject/explicit_type_argument_on_a_method_disagrees` (decision 8 §1.3 at a method call,
`ctx.resolve<T>()`), `run/std_module_imports_std_module` (`querystring` imports `encoding`'s
percent codec; on four targets since `01-compiler/05-wasm` step 5) and `run/bodyless_method_without_binding` (a
bodyless method with no host binding is refused at the call on every target, `.<target>.expect`).
The checker rows of `front/checker-rows` add a cell each, every one failing on the parent binary
(or, where noted, pinning a rule the parent already held): `reject/self_param_free_fn` (`self`
outside a type or behavior body is `self-param-outside-type`, at the name — jhonstart's
`repro/self-param-free-fn`), `run/decl_type_name_spelled` (`@Decl`'s type names spell the type:
`Array<string>`, `string[]`, `fn(i32) -> i32`, `#(string, string)`, `?i32`, a method's parameters
and return), `reject/reserved_word_field_name` and `reject/reserved_word_param_name`
(`reserved-word-as-name`, naming `from`), `run/external_wrapper_keeps_refusal` (a wrapper around a
single-target host call inherits no restriction — refused on commonJS and wasm by
`.<target>.expect` even though nothing calls it; the parent held this rule, and decision 146
made wasm hold it — `run/external_wrapper_associated_default` is the same rule on a behavior's
associated `default fn`, which wasm lowered only when a call reached it),
`run/behavior_array_of_implementers` (`Array<Plugin>` of two implementers; `.targets`
`commonJS erlang beam`, wasm answers `a a b b`), `modules/import_from_package_beside_same_name`
(a project `pub fn attempt` beside another module's `import {match.attempt} from "pkg"`; wasm
listed, the flat namespace), `run/host_array_slice_without_start` (commonJS's global `slice`
patch reads a missing start as 0; `.targets commonJS`), `modules/decorator_calls_imported_function`
and `modules/decorator_imported_function_name_conflict` (a decorator carries a function its module
imports, and two functions of one name reaching one decorator are refused where it is applied),
and decision 112's three rows — `modules/dsl_hygiene_private_helper`,
`modules/dsl_hygiene_consumer_alias` and `modules/dsl_hygiene_consumer_double`, each printing `40`
(the third's wasm line is the flat namespace's).
The checker rows of `front/checker-rows-2` add a cell each, every one failing on the parent binary except where noted:
`run/builtin_noreturn_any_position` (`@todo()` / `@panic(…)` are `noreturn`, the bottom type — a
`return` of a `-> i32` function, an annotated `val`, an `if` branch and a call argument; on all four
targets), `reject/builtin_module_not_lowered` (`@module()` is `builtin-not-lowered` at the `@`),
`reject/enum_variant_duplicate` (a variant written twice at one level, at the second),
`modules/enum_section_leaf_beside_variant` (a section leaf `Layout.Break.After` beside a top-level
`After(inner: Token[])`, each reached by its path or its position's type from another module —
the checker half already held; wasm, whose `case` read the leaf's tag, followed),
`run/variant_leading_dot_two_enums_case` (two enums declaring `Red`, `.Red` by the position's type
and a `case` over each — the checker half already held; wasm followed),
`reject/section_path_es4_expected_enum` / `reject/section_path_es4_every_head` (ES4 names the
expected enum, or every enum carrying the head, sorted — it named the hash walk's first),
`modules/labelled_call_by_label` (a complete labelled call by label on the associated, imported,
namespace and `"std"` call paths, and a namespace call filled from its default; the `"std"` path is
`testing.asserts`, which does not build on wasm — `wasm.expect`, the refusal at the import),
`reject/label_on_function_value` (a label in a call of a function value, `label-on-function-value`),
`modules/behavior_from_host_declare` (a host `declare fn -> Greeter`, here and in a third module,
meets a `Greeter` parameter of the behavior's module — the checker half already held; wasm refuses
the host templates by `wasm.expect`), `modules/import_ambiguous_use` (a bare `import {parse};` over two
modules declaring `pub fn parse` — the use is `ambiguous-import-use`, located, naming both, on every
target by `<target>.expect`), `modules/import_ambiguous_unused` (the same import unread compiles),
`run/std_decorator_through_namespace` (`#[mocks.mock]` after `import {testing.mocks} from "std"`
gives `Repo` the factory `Repo.mock()` and its stubs answer; wasm refuses the import by `.wasm.expect`),
`reject/std_decorator_unknown_through_handle` (`#[mocks.mokc]` is `unknown-annotation`),
`reject/std_decorator_leaf_import` (`import {testing.mocks.mock}` is `std-decorator-leaf-import`),
`run/pipeline_call_fill` (`lhs |> f(args…)` is `f(lhs, args…)` on every target, and a pipeline takes
defaults and labels, at expression and statement position) and `run/case_bool_literal_arms` (`true` /
`false` arms are the bool literals, beside a guard — every backend bound them as names). C-16's
`test/case_arms.bp` writes its range arm `1...9` (decision 53) and passes on commonJS and erlang.
The residual backend rows (`front/residual-backend-3`) add a cell each, every one failing on the
parent binary on the targets named: `run/generic_call_result_shape` (a generic `-> T` call answers
its argument's shape, `unwrapOr` its default's — wasm printed a string's address),
`run/unit_enum_print_by_name` (an all-unit enum's value by name, a field, an array, a `?Color` whose
present first variant is not absent — wasm printed the ordinal or trapped),
`run/case_multi_subject_patterns` (a multi-subject `case` over literals, strings, type arms, variant
binders and guards — wasm answered the first arm, beam matched a string or a type arm on anything,
commonJS never bound a variant's payload), `run/case_or_pattern_alternatives` (an or-pattern
over unit variants, numbers, strings, payload variants with a wildcard, a literal or a label and
`..`, a guarded arm, tuples, a range and a block arm — beam tested a number alternative alone, so
`C | D -> true` answered `false` and `A | B` raised `case_clause`), `run/behavior_implemented_by_enum` (an enum implementing a
behavior, called through a value of the behavior — commonJS, erlang and beam),
`run/behavior_method_result_chained` and `reject/behavior_method_result_typed` (a behavior method's
call answers its declared type, so a primitive method chains on it — commonJS called `length`,
wasm trapped), `run/external_template_escaped_quote` (a `\"` in an `@External.Node` template is a
quote of the JavaScript; `.targets` without wasm), `run/std_path_relative` (a std module calling an
`Array` `default fn` — commonJS had no prototype method), `run/if_value_float` (an `f64` value `if`
outside an `f64` function — wasm refused the module, commonJS printed `0`) and
`modules/linked_val_name_collision` (a module-level `val` and `var` two linked modules declare, read,
written, imported under an alias and shadowed by a parameter — wasm read the first one).
`run/val_assert_record_pattern` gained the labelled form (erlang bound it by position).
`modules/hof_named_function` (a local, an imported and a bound function named as an array method's
argument — wasm trapped), `run/generic_body_specialized` (a method on a type-parameter value, a float
through one, a behavior's generic associated fn and `Dict<string, string>.at` over a key built at
run time — wasm answered from one word-typed body) and `modules/imported_fn_as_value` (handed over by
`front/residual-checker-3`: erlang and beam lowered the name as an unbound variable) close the
backend halves the checker front listed.
| `run.sh` | the runner | — |

Decision 280 (`01-checker` step 24, typed comptime decorator arguments) adds, on all four targets,
`run/decorator_arguments_check` (example 1 of `01-checker/examples/decorator-arguments-280.md`: a
function `rule`, a field key `at: .confirm`, a variant `code: .Mismatch` and the function form),
`run/decorator_decl_pattern` (`@Decl<fn(e: E) -> unknown>`), `run/decorator_type_argument`
(`comptime t: @Expr<type>`), `run/decorator_function_arguments` (`paths:` / `head:` typed by the page's
`P`, `D`), `run/decorator_record_argument` (`Cache<T>` through a module `val`),
`run/decorator_field_keys` (`index(.state, .name)`, `unique(.code)`, the field's annotations in the
key) `run/decorator_argument_values` (an array keeps its length, defaults, labels, a variant) and
`modules/decorator_typed_arguments_import` (an imported decorator's `Type.Field<T>` and enum, the
importer importing neither),
and 19 `reject/` cells, each at the argument unless named: `decorator_param_not_comptime` (at the
parameter), `comptime_default_outside_decorator` (at the default), `decorator_value_not_comptime` (renamed by 364),
`decorator_arg_unbound_function`, `decorator_arg_function_mismatch`, `decorator_arg_unknown_field`,
`decorator_arg_label_unknown`, `decorator_variant_case`, `decorator_field_key_{unknown,case,too_many}`,
`decorator_function_argument_mismatch`, `decorator_record_argument_{mismatch,string}`,
`decorator_type_argument_{unknown,string}`, `decorator_decl_pattern_{mismatch,return}` (at the
annotation) and `decorator_check_without_rule_not_bool` (the body's `decl.fail`, at the annotation).
`reject/decorator_argument_kind` now carets the argument with the typed mismatch, and every
decorator of the cells writes its parameters `comptime`.

Decision 364 (`01-checker` step 35, every `comptime` parameter is `comptime x: @Expr<T>`) rewrote
every `comptime` parameter of the suite to `@Expr<T>` and its reads to `x.value` (a value-or-type
parameter keeps `x is type`; a `Box<T>`'s field is `s.value.value`), and adds, on the four targets,
`run/decorator_expr_value` (`.value` of a string, a number, a `bool`, a variant, a record, a field
key and an array in a decorator; an ordinary function's `n.value`, specialised; a template's
`q.value` of a literal without holes) and `run/decorator_expr_unread_argument` (an argument not known
at build whose parameter the body never reads is accepted), and the refusals
`reject/comptime_param_not_expr` and `reject/comptime_param_not_expr_function` (`comptime x: T`, at
the parameter, naming `@Expr<T>`), `reject/decorator_value_not_comptime` (`message.value` of
`env("MSG")`, at the call — the old `decorator_arg_not_comptime`), `reject/decorator_call_expr_fn`
(`rule.value(…)`, `expr-value-of-function`), `reject/decorator_inspect_expr_type` (`t.value`,
`expr-value-of-type`), `reject/decorator_expr_fail_at_argument` (`max.fail(…)` at the argument),
`reject/expr_param_method` (`message.text()`) and `reject/template_value_not_known` (a holed literal's
`q.value`), each red on the parent binary. `run/decorator_arguments_check` and
`reject/decorator_check_without_rule_not_bool` tell the function form by `decl.kind` (an `@Expr` of
a function has no `.value`, question `s35-b`).

Decision 370 (2) (`01-checker` step 35 box 3) — a decorator hands its parameters' `@Expr`s on to the
program through a typed member, `decl.addMember(name, fn(self: T) -> R { … })` — adds, on the four
targets, `run/decorator_expr_rule_called` (`rule` is `passwordsMatch`, called by `validate` at run
time), `run/decorator_expr_message_runtime` (`message` is `t("signup.mismatch")`, evaluated at run
time each time the member reaches it, never at build), `modules/decorator_member_fn_import` (a member
of a decorator in another module, reading only its parameters and locals) and
`modules/decorator_member_fn_imported_name` (one naming a type and a private helper of the
decorator's module — decision 384: each resolves there, the user's own same-named helper is not
captured; it was `decorator-member-fn-imported-name` on the parent binary), and the refusals
`reject/fn_expr_typed`, `reject/decorator_member_not_fn`, `reject/decorator_member_fn_untyped`,
`reject/decorator_member_captures` (a local of the decorator's body),
`reject/decorator_member_captures_handle` (`decl`) and `reject/decorator_member_type` (a field's
`fn(self: T)`, `T` the field's type), each red on the parent binary.

Decision 298 (`01-compiler/130` step 8) — typed meta keyed by its record type — adds, on the four
targets, `run/meta_typed` (`decl.setMeta(Entity(…))` read `@typeInfo(City).meta(Entity)`, two
`decl.addMeta(Index(…))` read `metaAll(Index)`, every field shape written back — string, array,
float, `bool`, variant, optional —, `null` / `[]` for a type nothing recorded),
`modules/meta_typed_catalogue` (`d.meta(Entity)` / `d.metaAll(Index)` on `@TypeInfo.all` entries,
here and in a function of another module the entries are handed to),
`modules/meta_catalogue_private_type` (`typeinfo-all-private` for a private meta record) and
`modules/meta_expr_read_elsewhere` (decision 385: `main` reads `signup`'s `Check` and `Note`, by
`@typeInfo` and through `@TypeInfo.all`, calling `signup`'s private rule and hint, its own
same-named functions not captured; it was `typeinfo-meta-expr-elsewhere` on the parent binary), and the
refusals `reject/meta_twice`, `reject/meta_not_record`, `reject/meta_field_type`,
`reject/meta_several`, `reject/meta_read_not_type`, `reject/meta_add_outside_decorator`,
`reject/meta_read_at_build` and `reject/meta_catalogue_generic` (question `130-s8-d`). Decision 370
(1) adds `run/meta_expr_field` (`decl.addMeta(Check(message: message, rule: rule))`, `Check`'s
fields `@Expr<T>`: the reader calls `rule` and evaluates `message` — `t("signup.mismatch")` — at run
time, never at build) with `reject/meta_expr_field_literal` and
`reject/meta_expr_param_plain_field` (`decorator-meta-expr-arg`). Each red on the parent binary.

Decisions 384 and 395 add, on the four targets, `run/member_reads_own_meta` (`#[validated]`'s
member reads `for (comptime @typeInfo(T).metaAll(Check))`, typed `Check<T>[]` in the decorator's
body and answered with `Conta`'s two `#[check]`s where the member is rendered; the rules and messages
run with the program) and `modules/decorator_member_type_same_name` (a member naming its module's
`Violation` where the annotated module declares one: `import-name-collision` at the annotation until
decision 310 is built), and `modules/decorator_member_type_travels` (an importer of the annotated type calls the member whose signature names the decorator module's `Violation`, which the importer never imports; on wasm the linked module's hygiene alias resolves by `wat.zig` `linkRenames`). Each red on the parent binary.
Decision 311 (`01-checker` step 29 — the template annotation `#[f "…"]`) adds, on the four targets,
`run/template_annotation`: a template `query(comptime q: @Expr<string>, comptime decl: @Decl)`
written on a behavior's methods (`"…"` and `"""…"""`, beside a decorator) and on a function, each
hole resolving to the declaration's parameter by name, the method's typed meta read by the
behavior's `#[repository]` on `decl.methods` (`m.meta(Query)`, `m.meta(Audit)`, question `s29-b`),
the function's by `@typeInfo(logout).meta(Query)`, and `decl.params` on a method;
`modules/template_annotation_imported` (the template, a helper its body calls and the owner's
decorator declared in another module); and the refusals
`reject/template_annotation_call_form` (`#[f(…)]` naming a template), `reject/template_annotation_not_template`
(a decorator at `#[f "…"]`), `reject/template_annotation_unknown_hole` (a hole naming no parameter —
the unbound-name error at the hole), `reject/template_annotation_without_decl` and
`reject/template_annotation_called` (question `s29-a`). Each red on the parent binary.
Decision 425 (a template call expands wherever an expression may stand, `01-checker` step 29) adds,
on the four targets, `run/template_in_type_method`, `run/template_destructuring_init` and
`run/template_in_field_default` (a field's and a parameter's default) — red on the parent binary
(`twice is not defined` at run time) — and `run/template_in_lambda`, `run/template_in_argument`,
`run/template_in_case_arm`, which the parent already expanded.

Every cell is copied into its own scratch project, so a parse error fails only that cell. Test names
start with the decision-8 section they pin (`test "§5.4 …"`) when there is one, so a failure points at
the rule; a capability decision 8 does not legislate gets a plain sentence.

Areas, by filename prefix: `case_*`, `tuple_*`, `loop_*` (decision 8 §5, §6, §10), `effect_*`,
`comptime_*` / `decorator_*`, `external_*`, `generic_*`, `string_*` / `array_*`, `type_identity_*`,
`optional*` (`optional`, decision 54's `optional_null_pattern` / `optional_variant_pattern`, and
1.0.10-beta's `00 · 05-wasm` `run/optional_record_carrier` — § `optional_record_carrier` below),
`context_use` / `use_*` (front 19 of 1.0.10-beta: `use` and `@Context`, two test cells, one run
cell and eleven reject cells), `index_*` (decision 63 as amended: `run/index_dict`,
`run/index_past_the_end_is_null` — renamed from `…_fails` when C-02 landed, because the
amendment makes an index past the end `null` and not a failure — `run/index_at_optional`,
`run/index_tuple` with `reject/index_tuple_computed` and `reject/index_tuple_out_of_range`
for the checker's one special case, and `run/index_user_type` — a `Matrix` and a `Registry`, the
library types that become indexable by answering `at` / `slice` with no compiler change, which is
the whole of what the rule is for), `std_erlang_node` (decision 64),
`panic_aborts` / `todo_aborts` (front 12 step 4.3), `external_erlang_only` (step 4.4),
`external_host_record` (a host-backed `declare fn` whose return type names a record — the erlang
templates deliberately build the pre-decision-21 `#{field => V}` map that an `.erl` sidecar in a
consumer library still builds, and the boundary adopts it; `.targets` is `commonJS erlang beam`
because wasm has no host vocabulary for these templates — beam compiles the erlang templates at build
time and adopts the answer with its own `'__bp_adopt'/3`),
`external_method_*` (host-backed METHODS — a `declare fn` with `#[@External.<Target>(…)]` inside a
`type` body, lowered as a real method of the type: `run/external_method_local` — a record's template
methods naming `$0` and `$1`/`$2`, one called from a bodied method on `self`, the `(module, symbol)`
form, `inline = true`, an enum's host method — on commonJS, erlang and beam, refused on wasm by
`.wasm.expect`; `run/external_method_erlang_only` — bound to Erlang only, refused where it is CALLED on
commonJS and wasm; `run/external_method_on_host_record` — a host method on a record the HOST built,
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
singletons (`closure_capture`, `recursion`, `expr_sugar`, `fn_defaults` (with `run/fn_defaults_values`, the VALUE on all four targets, and `reject/missing_required_argument`, N2 — both 1.0.10-beta's C-04), the two `lambda_*` cells of
1.0.10-beta's `00 · 04-js` — `lambda_expression_body` (a lambda whose whole body is one expression
answers that expression's value) and `lambda_element_method` (a primitive method on a lambda's
parameter is the same method it is anywhere else), both measured by emilia's theme front and both
asserting the VALUE, because each defect was a wrong answer rather than a crash — and the
decision-28/30/33 cells `nullish_default`, `paren_receiver`, `type_suffix`, `bodyless_fn`,
`curried_call`, `index_expression`, and the two 1.0.10-beta `00 · 04-js` cells
`run/labelled_arguments` — a record constructor and an enum variant written out
of declared order, the rule being `docs.md` § Parameters with defaults, "a
parameter the call names by label keeps the argument it was given, whichever
position it is in"; the values are asymmetric so a positional zip is a wrong
ANSWER at exit 0 rather than a crash, which is how it hid — and
`run/effect_method` — an effect annotation on a method, at its three
declaration sites: a record's own body, a record's `implement` block and an
enum's body; the fourth, a `behavior`'s `default fn`, cannot be written at all,
because the checker refuses `effect-on-behavior-method-forbidden`), and
`effect_chain` (1.0.10-beta front 20,
decisions 95 and 98: one `test/`, two `run/` and five `reject/` cells; front 20
also adds `run/use_one_base` to the `use_*` area for
decision 96 (its `reject/use_two_bases` left with decision 354), `run/option_unwrap_or` + `reject/option_expect_removed` to
`optional*` for F11, and `reject/external_inline_unread` to `external_*` for F9 — `inline` on
a variant whose emitter never reads it is refused at the annotation; 1.0.12-beta's front 140 step 2,
decision 334, adds `reject/external_wasm_host_unknown`, `reject/external_host_on_node`,
`reject/external_wasm_host_twice` and `reject/external_wasm_host_beside_unhosted` — `host:` is
`External.Wasm`'s, `.Wasi` or `.Browser`, one binding per host — with `run/external_wasm_host_binding`
(a `.Wasi` and a `.Browser` binding side by side, the `wasi` build lowering the first) and
`modules/wasm_host_from_manifest` (`"wasm": { "host": "browser" }` leaves a `.Wasi`-only binding
unbound, `wasm.expect`); its step 6 adds `modules/wasm_host_browser_runs` (a `browser` build run by
`node` through its loader, the `.Browser` binding read) and makes the wasm column two runs — `run.sh`'s
`exec_run` runs a wasm cell on the `wasi` host (wasmtime) and on the `browser` host (node), and a cell
whose two exit statuses or stdouts differ fails naming both; a project cell whose botopink.json names
`"wasm"` runs on that host alone); its steps 4–5 (decisions 392–394: `@Task` on wasm a resumable
state machine over the scheduler, one adapter list for both hosts) add `run/wasm_host_async` (`delay`,
`race`, `raceOf`, `spawnAll` declared with std's Node and BEAM bindings and the `wasi:` adapters —
`raceOf` answers the first thunk to settle, `"b"` on every target and both hosts),
`run/task_starts_when_made` (a task runs to its first `await` when made, settles once),
`run/task_resumes_in_place` (loops, `if`, `try`, `try … catch`, a method, a generic fn and an
`async { }` block suspending on a real timer), and two wasm refusals with `wasm.expect` —
`run/task_await_after_call_refused_on_wasm` (a call before an `await` in its statement) and
`run/external_wasm_task_adapter_shape` (an adapter declared off its shape), and `enum_section_*` (1.0.10-beta's `00 · 01-checker`: which enum a
leading-dot section path names — `run/enum_section_expected_type`, where two enums carry
`.Color.Red.500` and every spelling is resolved by the type its position expects, and
`reject/enum_section_ambiguous_path`, where the position expects nothing and the refusal names both
candidates, and `run/enum_section_qualified_path`, where `Token.Color.Red.500` names its enum and
needs no expectation at all), `run/case_value_string_arms` (1.0.10-beta's `00 · 05-wasm`: a `case` used as a VALUE with string
arms, in BOTH arm spellings — the two took different paths through `wat.zig` and only the ARROW one
was a string, so `val a = case x { 5 { "five" } … }` printed the arm's heap address `256` on wasm at
exit 0 where the other three printed `five`; the `-> string` function form is `run/case_values`'
question and not this one, because a declared return type registers the shape on its own),
`run/case_arm_name_is_also_a_type` (§5.3b's collision: a
module declaring a record `Block` and an enum section carrying a `Block` leaf — the arm over the
section is the VARIANT, the arm over a union of records is still the type, and the cell asserts
both values on all four targets. commonJS tested only `instanceof`, so the section arm never
fired and the `case` answered `undefined` at exit 0, which is how emilia read 223/2 on commonJS
against 225/0 on erlang from one source), and `narrowing_*` (the same front's
`fix/null-narrowing`: which shapes of a null test rebind the name they test —
§ `narrowing_*` below), and the module-`var` cells of 1.0.10-beta's `00 · 17-beam-memory` (C-05, decisions 28, 38, 41, 43, 51): `run/module_var` — a module-level `var` written twice through a `fn` prints `2` on all four targets (on erlang it was unbound `Hits` and did not compile, on beam the write was dropped and it printed `0` at exit 0 — C-10 lowered both); `test/beam_memory_noop` — the annotation was a no-op off the BEAM (decision 43; deleted when decision 167 made it a refusal there, `run/beam_memory_off_beam`); and seven `reject/` cells, one per diagnostic — `val_assign_module` and `val_assign_local` (a `val` is immutable, the hint names `var`), `beam_memory_unknown_member`, `beam_memory_unknown_argument`, `beam_memory_keyed_scalar`, `beam_memory_keyed_list` (decision 51: `keyed` is `Dict`-only) and `beam_memory_on_val`. C-10 (front 17 step 4) adds the per-mode BEAM cells, each a `run/` cell with `.targets` = `erlang beam` (a `test/` cell cannot be narrowed to a target, and on commonJS the modes are one program-wide value): `run/beam_memory_process_dict` (a value written in `main` is not seen by a process `async.runAll` spawns, and its write does not reach `main` — `[0]` then `5`), `run/beam_memory_ets` (decision 39's fixture: five processes × three increments print `15`) and `run/beam_memory_persistent_term` (put at load, read by a spawned process: `[101]`); and the refusals its lowering needs — `reject/beam_memory_pt_write`, `reject/beam_memory_ets_recompose`, `reject/beam_memory_ets_bump_non_integer` (decision 40) and `reject/beam_memory_ets_initialiser` (a seed that is neither a literal nor `comptime`). 1.0.11 front 17 step 1 (decision 168) adds the keyed cells: `run/beam_memory_ets_keyed` (`.targets` `erlang beam` — two processes writing their own key 20 000 times each print `20000 20000`; the seed's repeated key reads its last value, a key with no row `null`), `reject/beam_memory_ets_keyed_seed` (a seed that is neither `Dict.empty()` nor `Dict.ofEntries([…])` of literals), `reject/beam_memory_ets_keyed_recompose` (a row computed from the var's own rows, decision 40's §5(b) diagnostic) and `reject/beam_memory_ets_keyed_whole_read` (a keyed var named anywhere but as its row read's receiver); none can pass on the parent binary: its seed rule refused `Dict.empty()` with the literal-or-`comptime` message, it refused `keyed = true` on the BEAM, and a `Dict` recompose was exempt. `run/module_var` passes on erlang, and the three `run/beam_memory_*` cells and `run/module_var` on beam (step 5). `01-checker` step 12 replaces `run/variant_name_ambiguous` (an erlang-only emit refusal) with `reject/variant_name_ambiguous` — the checker refuses `.Circle` with no expectation on every target — and adds `run/variant_leading_dot_expected` (the expected type decides `.Circle`; a qualified constructor is the enum written), `run/section_path_resolution` (a section leaf's shorthand, a payload section path through the annotated enum, a qualified section value) and `reject/section_leaf_without_expectation`; each fails on the `feat` binary. `modules/template_name_collision` (two modules exporting a template `tag`; the import from `loud` expands `loud`'s — the bare-name registry expanded `quiet`'s at exit 0) is 01 step 12's registry half. `run/try_catch_null_and_noreturn_narrowing`, `run/component_call_renders`, `run/component_call_awaited` (a written `await` of a component call inside a component body — jhonstart's layout chain) and `reject/try_catch_handler_mismatch` are the maintainer's 24-box-1 rows (the guide's page example): `catch null` is a `?T`, a `noreturn` call narrows, a component called in a component body renders; each fails on the `feat` binary. `run/labelled_arguments_reorder` (a label names the parameter it fills in a complete call — fn, record, method, primitive method, self tail call) and the `run/labelled_arguments.bp` erlang line's removal are 01's labelled-call row. 01 R7 (decision 2) adds `reject/fn_falls_off_end` and `reject/if_without_else_value`, both accepted by the `feat` binary. C-18's decision 45 adds `reject/member_of_optional` (a member read off a `?T` names `?.`) and moves `test/tuple_labels.bp` §6 T4 to `rs.at(0)?.b` — both targets pass it, the label is carried on commonJS and erlang. Decision 15's annotation grammar (front 17 step 3's recorded row) adds `reject/annotation_unknown_family` (`#[@TotallyMadeUp.Nonsense(whatever = 42)]` on a `var`) and `reject/annotation_family_misspelled` (`#[@BeamMemroy.Ets]` names `@BeamMemory`). Pending 0203-a, answered (b), adds `reject/primitive_method_undeclared` (`s.toUpperCase()` names `toUpper`, the method whose host spelling it is) and `reject/primitive_method_unknown` (`"x".fooBar()`, no near name), and re-spells `test/string_case_conversion` to `toUpper` / `toLower` — its erlang line is gone. `01-checker` step 13 adds the two cells of "a local ends with its body": `reject/local_binding_escapes` (a `val` of one `fn` used by the next is refused at the use, naming `holder`) and `run/local_shadow_ends_with_body` (a local `p` shadows the module's `pub fn p` only inside its own `fn` — `3` then `p:x`); each was run with the `feat` binary and fails there as the step describes. One scenario group per
file: a parse error is the blast radius, so nine `#[@External]` declarations in one file mean one
unparseable annotation hides the other eight.

### The erlang backend's cells (1.0.11-beta `01-compiler/02-erlang`)

Each was run with the parent binary and fails there as its row describes.

- `run/module_fn_named_like_bif` (language-gaps T13): a module declaring `element/2`, `apply/2`,
  `length/1` and `hd/1` reads a record field, calls each of its own fns, prints a record and reads
  `Array.at` past the end — on all four targets. The erlang module did not compile (`element/2`
  is illegal in the print helper's guard once it is the module's own fn) and, before the
  `no_auto_import` directive, read `p.y` through the module's `element/2`.
- `run/host_template_binding_inside_while` (language-gaps T14, `.targets` erlang beam — commonJS
  and wasm lack `bump`): an `#[@External.Erlang]` template binding `__Loop`, called in a `while`
  body and in a `for` body. Erlang's `while` recursed through a named fun `__Loop`, and the
  template's `__Loop = …` re-matched it — `{badmatch, 1}`.
- `modules/dependency_module_level_print` (C-34): a dependency's two modules print only from a
  module-level `val`; `main` imports a value from one, its sibling `label` a type only from the
  other, and both bodies run first, on all four targets. Erlang's `'_botopink_init'/0` called a
  `'__bp_print'/1` the module never defined — `erlc` refused both dependency modules.
- `run/string_literal_unicode_escape` (C-36, STD-11 and the locale row): a `\u{…}` escape above
  U+00FF and a raw `ç` print as themselves, alone and inside an array, on all four targets. C-36's
  emitter half (`writeStringFromLexeme` writes a code point's UTF-8 bytes) was already landed, so
  the cell fails on the parent binary only under `LANG=C`, where erlang wrote `é` as `0xE9` and
  `\x{1F600}` as text; beam did too (`03-beam`'s twin, landing with the next integration). `.length()` of such a string is left
  out: commonJS counts UTF-16 units (`2`) and wasm bytes (`4`) — 04's and 05's rows.
- `test/is_truth_table` (C-07's erlang tail, decision 8 §4.1 × §4.2): each form that may follow
  `is` — `i32`, `i8`, `u8`, `f64`, `string`, `bool`, a record, an enum type, `Box<unknown>`,
  `#(i32, string)` — asked of the same ten `unknown` values, and §4.1's conversion inside
  `if (a is i32)`. `run/is_truth_table` is the same table on four targets, with tuple rows by
  arity and by element value (`#(2.0, "a") is #(i32, string)` holds); wasm refused it on the parent
  (`cannot box this value as unknown` for an `unknown[]` element, then no run-time test for a tuple
  type). §11's "erlang stores nothing" is `codegen/tests/control_flow.zig`'s needle (`A = 2.0,`, no
  box) — no program prints a difference, so it has no `run/` cell.
- `run/array_unique` (C-35, decision 217): `unique` keeps each value at its first occurrence over
  integers, strings, floats, bools and an empty receiver. wasm dropped only consecutive duplicates
  on the parent (`[1, 2, 1, 3, 2]`).
- `run/case_no_arm_matches_raises`: a `case` no arm matches raises `case_clause`; the value comes
  from an erlang host function answering an atom no variant is (the checker sees the `case` as
  exhaustive). beam answered the subject at exit 0 on the parent; commonJS and wasm refuse the
  binding (`.commonJS.expect`, `.wasm.expect`).
- `run/lambda_binds_name_of_enclosing_fn` (decision 205): a `forEach` body's `val k` over an outer
  `k`, a lambda parameter `e` over an outer `e`, and a lambda value's parameter `e`; the outer names
  keep their values. erlc refused the module on the parent binary (`K@1` unbound). **Red on wasm**
  (`l l 1 2 6 2`: the inner bindings overwrite the outer ones) — 05's row.
- `run/behavior_default_adopted_by_two_types`: a behavior's `default fn` adopted by two types (one
  declaring the other default itself), called typed, through a default and through a behavior-typed
  parameter. erlc refused the module on the parent binary (`function twice/1 undefined`). **Red on
  beam** until 03's adopted-defaults commit lands and **on wasm** (it traps in `Sq_label`, 05's row).
- `modules/erlang_host_sidecar_in_a_test` (test kind, narrowed to erlang and beam): a `test/` module that
  declares `#[@External.Erlang("lt_greeter", "hello")]` itself and calls it. It imports nothing, so
  its runner loaded no sibling and the call died `{error,undef}` on the parent binary.
- `run/list_pattern_spread_alone` (a row `03-beam` measured): `[..all]` as a `case` arm over three
  elements and over `[]`, and `val assert [..every]`, on all four targets. Erlang wrote the pattern
  `[All]`, a one-element list — `case_clause` and "assert pattern did not match" on the parent
  binary. The plain `val [..rest] = xs;` (which erlang also left unbound) is `01-checker` step 13's
  `run/val_spread_only_list_pattern`, refused by the checker until the backends lower it.
- `run/captured_var_write_threaded` (decision 148, lg-b): the two lambdas that may write a
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
| `run/narrowing_null_check.bp` | `if (x != null)` over a `?Record` field, a `?string`, a `?T[]` and a `?i32`; `null != x`; `&&` narrowing BOTH names; the else side of `== null`; and that the narrowing ENDS with the branch |
| `run/narrowing_null_guard_clause.bp` | `if (x == null) { return …; }` and then the rest of the block — in a top-level `fn` and in a record METHOD, plus the `\|\|` form. Each function is called twice, present and absent |
| `test/narrowing_null.bp` | the same rules inside a `test` block, which is the third statement walk a program has |
| `reject/if_optional_needs_a_binder.bp` | the limit: `if (x)` on a `?T` with no binder is refused ("expected bool, got ?string" — the message spells the type as a source writes it). There is no truthiness on an optional |

**Shapes that do NOT narrow, measured and deliberate.** `while (x != null) { … }` leaves its body
alone: a condition loop reassigns the name it tests (`cur = es.at(i)`), and a narrowed `cur` would
red the assignment — narrowing it would break programs that work today. `if (o.inner != null)`
does not narrow either: only a plain NAME is rebindable. `case x { null { … } v { … } }` and `if (x)
{ v -> … }` narrow already, each through a channel of its own.

`run/narrowing_null_check.bp` passes on all four targets since `00 · 05-wasm` landed the missing
unbox (`fix/wasm-optional`): a name a `!= null` test narrows is its PAYLOAD for the branch on wasm
too, which is what the box needed and what the optional-binding form `if (x) { v -> … }` had always
done. `run/narrowing_null_guard_clause.bp` passes on all four targets; beam was red longest, and not
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
| `run/loop_generator_dobros.bp` | decision 105's own example: `2 4 … 18 20`, then the counter the generator left at `10` |
| `run/loop_range_inclusive.bp` | `for (1..4)` visits `1 2 3`, `for (1...4)` visits `1 2 3 4`, `for (3...2)` nothing |

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
| Return and effect mode | `test/effect_return_result`, `run/task_return_layers` (three layers), `run/effect_alias_passes_value`; `reject/effect_return_ambiguous_nesting`, `reject/effect_wrapper_behind_alias` |
| `@Task` and failure | `run/task_await_no_try`, `run/task_await_result` (`await t` answers the `@Result`, `try await t`, `try await t catch x`), `run/task_throw_resolves_error` (`.targets commonJS`: the Promise resolves with `Error`, never rejects); `reject/task_throw_without_result`, `reject/task_try_await_without_result` |
| Chain and `use` | `run/component_hook_and_component`, `run/component_result_try_await`; `reject/component_try_element`, `reject/await_under_result`, `reject/use_under_task`, `reject/use_of_component` |
| `async { }` | `run/async_block_all_of` (`.targets commonJS erlang beam`: `std/async` has no wasm host), `run/async_block_value_type`, `run/async_block_return`; `reject/async_block_use`, `reject/async_block_conflicting_errors` |
| Iterators | `run/iterator_fibonacci`, `run/iterator_result_item`, `run/iterator_result_items` (step E4), `run/iterator_factory`, `test/yield_step_next` and `run/yield_step_next` (`.next()` by hand on an `@Iterator` and, awaited, on a `@Stream` — the `run/` half reaches beam and wasm, which a `test/` cell cannot, and steps a parameter inside a `while`); `reject/iterator_throw_without_result`, `reject/iter_await`, `reject/iter_mixed_yield_return`, `reject/iterator_error_param_removed` |
| Streams | `run/stream_pages` (a simulated http failing mid-way), `run/stream_loop_no_failure`; `reject/for_await_without_task` |
| Prefixed loops | `run/prefixed_loop_forms`, `run/prefixed_loop_result_item`, `run/prefixed_loop_break_value`, `run/prefixed_loop_nearest_scope`, `test/contextual_words`; `reject/prefixed_loop_break_outer` |
| Host (decision 126) | `run/host_node_task_result` (`.targets commonJS`), `run/host_erlang_task_result` (`.targets erlang beam`) |
| The E3.9 hint (a `@Result` used as its `U`, one hint per source) | `reject/result_hint_await` (`try await t`), `reject/result_hint_for_item` (`try r`), `reject/result_hint_inferred_async` (the `await` hint plus the `try` that made the block's value a `@Result`) and `reject/result_hint_inferred_iter` (the `for`-item hint plus the `throw` that made the `iter` items `@Result`s); the two `for` cells carry no location line — the mismatch is reported at the file |
| Migration (decision 127, guide § 9's "Old names that left") | `effect-annotation-removed`: `reject/effect_annotation_removed_{result,future,use,generator,result_generator,future_generator}`, the three loop forms `…_{generator,result_generator,future_generator}_loop`, and the older `…_{context,iterator,async_generator}`; `effect-type-removed`: `reject/effect_type_removed_{future,future_no_error,use,generator,result_generator,future_generator}` and the older `…_{async_iterator,iterable,iterator_step,yield}`; the arity refusals `reject/component_base_parameter` (`@Component<C, R>`, decision 354), `reject/yield_step_error_param` (`YieldStep<T, E>`); and the existing refusals `reject/loop_condition_parenthesised`, `reject/loop_await_removed`, `reject/component_plain_return` |

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

`run/unknown_by_value.bp` (1.0.10-beta `00 · 05-wasm` step 2) runs decision 8 §2, §4.1 and §5.2
through `unknown` on every target — `test/case_unknown.bp` states the same rules, and `botopink test`
does not reach wasm; it prints no unknown float, because commonJS stores nothing extra (§11) and
prints `2.0` in an `unknown` slot as `2`. `run/optional_chain_method.bp` (05 step 9) is a method on
the rest of a `?.` chain, its absent probes read through `??`; erlang's and beam's halves were 02's
and 03's.

`modules/sibling_import_in_a_dependency` is a local-dependency cell for 1.0.10-beta `00 · 04-js`
step 5: a `mod` sibling imported with no `from` (`pub mod leaf; import {Twig};`), once in the
project and once inside `deps/tree/` (`api.bp`'s `import {Leaf};`). commonJS used to write the
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

`run/variant_name_collision.bp` and `reject/variant_name_ambiguous.bp` are the third axis. Decision
21 puts the ENUM and the enum's module inside a variant's atom, and `variant_enum` answered "which
enum declares `Circle`" by declaration order — first writer wins, mitigated for a `case` SUBJECT
only. The first cell is the spelling that always had an answer (the enum is written) and asserts
six values on every target. The second was an erlang-only `run/` cell the emitter refused; since
`01-checker` step 12 the checker answers both halves for every target: a leading dot whose position
expects an enum is that enum's (`run/variant_leading_dot_expected.bp`), and one whose position
expects nothing is refused naming both enums (`reject/variant_name_ambiguous.bp`).

`modules/variant_positional_payload_same_name` — two modules each declare a payload variant `Item`
with a different field and a third matches both positionally (commonJS printed `null`; beam bound
the whole value, `03-beam`'s row).

`run/variant_payload_wildcard_and_nested` — `Rect(w, _)`, `Rect(_, h)`, `Circle(_)` and a variant
nested in another's payload (`Two(Rect(w, _), _)`, `Two(Circle(r), Rect(_, h))`) in one module, on
all four targets (wasm bound `w` to 0 and answered the nested arms wrong at exit 0, `05-wasm`'s rows).
`run/unsigned_compare_and_divide` — `u32` above 2^31 and `u64` above 2^63 compared and divided, on
all four targets (wasm read a `u64` signed, decision 319); `u64`'s `%` past 2^53 is
`codegen/tests/wat.zig`'s, since commonJS aborts it (`04-js`'s step 9).
`05-wasm`'s printing rows, each on all four targets: `run/bool_field_print` (a `bool` record field
or tuple element read alone printed `1` / `0` on wasm), `run/u64_record_field_print` (a `u64` field
through the record printer printed signed), `run/u64_tuple_slot` (a `u64` / `i64` / `u32` tuple
element — built, read, destructured, bound, compared, nested — was refused on wasm) and
`run/optional_u64_to_string` (a `?u64` printed, narrowed, unwrapped and turned into text signed).

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
| `run/std_default_fn_in_a_std_module.bp` | the VALUE, through four std modules and both interfaces. `botopink run --target erlang` compiles the whole output directory with `erlc` up front, so a dead std module is a hard error on this path. On four targets since `01-compiler/05-wasm` step 5, which closed the two wrong answers wasm gave it at exit 0 (`url.parse` through its namespace called `querystring`'s `parse`; `dequeue`'s `?T` read as its box's address) |
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
node v25.8.0): `tests/language/run.sh` — **547 passed, 42 expected failures, 0 failed**, over
feat's own 541/42. The +6 accounts for itself exactly: these two cells are the `run/` cell on
commonJS and erlang and the `test/` cell's two tests on each. Each was shown to red by planting the
pre-fix behaviour: with `collectPreludeInstanceDefaults` guarded again, the `run/` cell exits 1 with
empty stdout and the `test/` cell does not compile ("`std/path.erl` does not compile — refusing to
run the tests of …"); with the `_ -> ok` skip also back, the same cell reports `{error,undef}` and
says nothing about `std/path`; with only the sibling loader's `std_imports` route removed, it is
`{error,undef}` again on a module that compiles perfectly.

### `std_fs_walk_root_spellings`

`run/std_fs_walk_root_spellings` (1.0.11-beta front 97) builds `walkroot/` in its scratch project and
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

### The sidecars of a `run/` cell

Four optional files beside `run/<name>.bp`, each a claim the cell makes (C-16, front 12 steps 4.3
and 4.4; `.<target>.stderr` decision 264). `run.sh`'s usage block is the reference; this is the why.

| Sidecar | Claim | Passes when |
|---|---|---|
| `<name>.exit` holding `nonzero` | the program **aborts** after printing `.out` (`@panic`, `@todo`, a failed index under decision 63) | stdout equals `.out` **and** the status is not 0. The number is never pinned: node 1, erl 1, wasmtime 134 are the runtimes' (§ Never pin an erlang exit status) |
| `<name>.<target>.stderr` | with `.exit`: on that target the abort **names its cause** — what the program died of, not only that it died | the `.exit` claim holds **and** the program's stderr contains line 1 (`integer overflow: + on i32 at src/main.bp:7:14`). Per target, because a runtime that writes no text of its own (a wasm trap) has nothing to compare; a `.stderr` without an `.exit` is a malformed claim and fails the cell |
| `<name>.<target>.expect` | on that target the compiler **refuses** the program — `reject/`'s shape, per target | exit ≠ 0 and the diagnostic contains line 1 (and ` --> src/main.bp:<L:C>` when line 2 is present). `run/external_erlang_only.{commonJS,wasm}.expect` and `run/std_erlang_node.{commonJS,wasm}.expect` are the live ones |
| `<name>.targets` | the cell is scheduled only on these targets, **because every other target refuses it on a host binding** | the cell passes on each target it names, and `botopink build --target <t>` refuses it on a host binding on each target it leaves out — § Narrowing a cell |
| `modules/<name>/<target>.expect` | the `.<target>.expect` claim for a whole project: that target **refuses** it | exit ≠ 0 and the diagnostic contains line 1 (and ` --> <line 2>` when present — `src/<file>.bp:<L:C>`, the file named because a project has several). `modules/external_method_imported/wasm.expect` is the live one |

Any other content in `.exit` is a malformed claim and fails the cell. The cells that carry
`.targets`, and what each excluded target lacks, are listed in § Narrowing a cell.

`front/gate-wasm-wrong-answers` (`compiler-core/src/codegen/wat/AGENTS.md` § Numbers) adds three
four-target cells for numbers wasm answered wrongly at exit 0 — `run/float_shortest_text` (a
float's shortest round-trip text, where erlang and beam agree with commonJS), `run/float_slot_keeps_f64`
(a float in an array, a tuple, a payload, a record field, a `?f64`, a capture), `run/i64_full_width`
(`i64` locals, parameters, fields, `?i64`, `u32`, a literal past `i32`) — and five cells refused on
wasm by a `.wasm.expect`, each a value wasm has no reader for yet: `run/optional_index_arithmetic`
(`xs[i] + 1`), `run/i64_in_array_slot`, `run/fn_value_float_argument`, `run/generic_field_float`,
`run/untyped_array_float_push`.

`front/int-overflow` (decision 264: an integer result outside its type aborts on every target) adds
eight abort cells, each `.exit` plus `.<target>.stderr` naming `integer overflow: <op> on <type> at
src/main.bp:<L:C>` on commonJS, erlang and beam: `run/int_overflow_add_i32`, `run/int_overflow_mul_i64`
(past `2^63 − 1`; commonJS reaches the bound through `BigInt`, decision 319),
`run/int_overflow_negate_i32`, `run/int_overflow_plus_assign`, `run/int_division_min_by_minus_one`,
`run/int_overflow_sub_u32`, `run/int_overflow_add_i8` and `run/int_division_by_zero` (commonJS's
`integer division by zero`; erlang and beam raise `badarith`, wasm traps) — and
`run/int_arith_at_bounds`, every type's bound reached by arithmetic and printed, never an abort. wasm
traps with no text, so its half is `.exit` alone; `u32` and the narrower types check their own range
there too (`wat.zig` `emitRangeCheck`).

`04-js` steps 9 and 10 (decision 319: `i64` / `u64` hold their full range on commonJS too, a number
below 2^53 and a `BigInt` beyond; decision 320: a string index counts codepoints there) add
`run/i64_full_range` (past 2^53 both ways, `2^63 − 1`, `−2^63`, `/` `%` unary `-` `+=` and `==` across
the edge, then a sum past the top that aborts), `run/int_overflow_sub_i64_min`,
`run/int_overflow_add_u64_max` (the `u64` top, `%` and `/` past 2^53, a sum past the top; red on wasm,
which prints the top as `-1` and traps on `18446744073709551614ul + 1ul`), `run/i64_dict_key_across_safe_edge`
(a `Dict` and a `Set` keyed across 2^53; wasm refuses the `i64` element, `.wasm.expect`) and
`run/string_codepoint_slice_and_code` (a negative `slice` bound, `s[-2]`, `s[4..]` and `charCodeAt`
over `"a👍bX👍c"`); `run/wide_literal_past_js_safe_integer` lost its `.commonJS.expect` and answers
on the four targets.

`02/97` step 13 (decision 319, std's half) adds `run/i64_number_methods_past_js_safe` — `min`, `max`,
`clamp`, `abs`, `isEven`, `isOdd` on `i64` and `u64` values past 2^53 (commonJS threw
`big.isEven is not a function`: the methods were patched on `Number.prototype` alone) —,
`run/string_parse_int_i64_range` (`parseInt` reads −2^63 … 2^63 − 1 and refuses one past either end;
the parent refused past ±(2^53 − 1)), `run/integer_conversions_exact` (`toI32`, `toI64`, `toU32`,
`toU64`, `toF64` at the bounds and past 2^53) and two aborts, `run/integer_conversion_to_i32_aborts`
and `run/integer_conversion_to_f64_inexact_aborts` (`.exit` plus a `.stderr` per target naming the
value). They answer on commonJS, erlang and beam; wasm refuses each by `.wasm.expect` — its integer
methods are `i32`'s, the conversions have no row, and `parseInt`'s `stringSlice0/2` is unresolved
(that one's location points into std, so its `.expect` holds line 1 alone) — `05-wasm` rows.
Its `io` half adds `run/std_io_i64_canonical` — `fs.stat`'s `size`, kind and `mtime` (the Node
form reads `statSync` with `bigint: true` and answers the canonical form) and `clock.hours` /
`clock.add` past 2^53 (`clock`'s `wide` is std's `toI64()` now, no host cell), printed as the same
digits on commonJS, erlang and beam; wasm refuses `io/fs` by `.wasm.expect`. Its `recent` helper
holds the `l` literal outside the `case` arm: an `l`-suffixed literal inside a `case` arm is
emitted with its suffix on commonJS, erlang and beam (`s.mtime > 1577836800000l`, a JS
`SyntaxError`, an `erlc` syntax error, `illegal integer` in the beam assembler) — a compiler row,
not std's.

`front/block-backends` (decision 2: an `@block`'s `return` is the block's value) adds
`run/block_return_is_block_value` — `val x = @block { return 3; }`, a branch's `return`, a string,
an `f64`, a `case` arm's `return`, a nested `@block`, a block inside a `for` and a statement block
ending in `return;`, on all four targets. The parent returned from the enclosing function on beam
and wasm and, from a block inside a loop, on erlang.

`fix-js-gaps` (gaps `libs/validation` met) adds `modules/imported_variant_positional_payload` —
`Circle(r)`, `Rect(w, h)`, `Two(l, r)` and a `val assert Circle(r)` over enums of a sibling module, on
all four targets (commonJS read a property named after the binding and died on `undefined`).
`run/method_named_like_module_fn` — a module declaring `startsWith(comptime decl: @Decl, …)` and
`endsWith(a, b)` calls the string methods of those names (erlang refused the module with
`PrimOpArgIndexOutOfRange`, commonJS answered `false`), on all four targets.
`test/type_method_prim_default` — a `type`'s method calls `String.parseInt`, whose body calls
`self.startsWith`; erlang emitted `startsWith(Self, …)` into the type's module, undefined. A `test/`
cell: wasm has no `String.parseInt` (`stringSlice0/2`, `05-wasm`).
`fix-121-gaps` (the gaps front 121's `onze-content` met) adds three cells on all four targets:
`run/var_written_in_branch_read_after` — a `var` written in the arms of a statement `case` inside a
`for`, in an `if` block ending in `return` (and in one holding a nested `return`), two `var k` in
sibling `else if` branches of a `while` body, and `val kids = case c { Box(kids) -> kids; … }` (erlang
refused the module, `Out@1` unbound; beam lost the arms' writes at the end of each round; commonJS ran
a `_` arm after an arm whose block answered nothing); `run/case_arm_ending_in_for` — a statement
`case` arm whose block ends in a `for` (commonJS fell into the next arm, erlang refused the module,
beam dropped a `push` that was an arm's last statement); `run/record_update_on_lambda_parameter` —
`xs.map({ b -> Brk(..b, active: false) })` and a block lambda ending in the update (commonJS, erlang
and beam built `Brk(b, false)`, wasm trapped).

## The targets

Measured at front `111-gate-beam-and-targets` of 1.0.11-beta (`specs/1.0.11-beta/00-gate/` in the
meta workspace), OTP 28, node v25.

| Target | `botopink test` | `botopink run` | In the suite |
|---|---|---|---|
| commonJS | yes | yes | every kind |
| erlang | yes | yes | every kind |
| wasm | refused — "supports only the commonJS, erlang and beam targets" | yes, it executes | `run/` and `modules/` only |
| beam | yes: every module of the run assembled beside itself (`erlc +from_asm`), each test module's runner run with `erl -pa` (`01 · 03-beam`) | yes: it builds `out/beam/*.S`, assembles each beside itself (`erlc +from_asm -o out/beam`) and runs the entry with `erl -pa out/beam` | every kind |

`--target all` is the four of them. A machine without `erlc` or `erl` fails the run before any cell
starts (`run.sh: the beam target needs erlc`); it never runs three targets and reports "all"
(decision 67). The tool set is the gate's own — `node`, `erl`, `erlc`, `wasmtime` — and nothing
else: the four-target run is green with `PATH=/usr/bin:/bin:~/.wasmtime/bin` and no other variable
but `HOME` and `LANG=C.UTF-8` (front `01-compiler/12-language-tests`). Under a locale that is not
UTF-8 (`LANG=C`, or none) `run/string_split_empty_separator` is red on erlang and beam: `erl` writes
`é` as the latin-1 byte `0xE9` where commonJS writes UTF-8 — a program's stdout that depends on the
host locale is a backend defect, not a reason to pin a locale in the runner.

The `run/` sidecars (§ above) apply on every target the cell reaches, beam included: `botopink run`
returns the assembled program's status, so an `.exit` claim is checked there too
(`run/panic_aborts.bp` and `run/todo_aborts.bp` pass on beam — the second for a different reason,
§ Notes).

`test/` cells therefore run on commonJS, erlang and beam; `run/` and `modules/` cells run on all four;
`reject/` runs once (target `*`, `botopink check` is target-independent).

Every cell's `botopink.json` is named `language_tests`, and an erlang/BEAM module atom starts with
its package (decision 109 of 1.0.10-beta): the entry is `language_tests@main`, and a host template
that builds a record's tag spells it `'language_tests@main@@Point'` (`run/external_host_record.bp`).

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

A cell runs on every target its kind has — unless it narrows itself: `run/<name>.targets`
(space-separated), or `"targets"` in a `modules/<name>/botopink.json`. A narrowing is a claim about
the compiler, and `run.sh` checks it on every run (gate-d of `specs/1.0.11-beta/00-gate`): for each
target of the run the cell leaves out, `botopink build --target <t>` in the cell must **refuse** the
program on a host binding —

```
`f` has no `#[@External.<Target>(…)]` for the <t> backend
std-unsupported-on-target: std/<m> has no `#[@External.<Target>]` for target '<t>'
```

— the one reason a program structurally has no row on a target. A target the build accepts, or
refuses for another reason, fails the run and names the cell: the narrowing was hiding a gap of that
backend, and a gap is a row of the backend's front, never a line in a `.targets` file. So does a
narrowing that names an unknown target, a target its kind does not have, the same target twice, or
every target of its kind (it narrows nothing — delete it). No flag, list or environment variable
turns the audit off (decision 67).

A third refusal stands a narrowing too — decision 167 (amending 43): a module `var` under
`#[@BeamMemory.<mode>]` binds BEAM storage, and commonJS and wasm refuse the annotation where it is
written,

```
`#[@BeamMemory]` has no meaning on the <t> backend
```

so a cell that declares one leaves those two out on the compiler's word, never on its own source's
(the structural exemption the runner used to read off the source is gone). erlang and beam accept
the annotation, so it never excuses either. `run/beam_memory_off_beam` pins the refusal itself
(`.commonJS.expect`, `.wasm.expect`, located at the annotation) and prints `2` on the BEAM.

A target on which the cell must be refused for a reason that *is the cell's claim* is not narrowed
away — it is pinned with `<name>.<t>.expect` (`modules/<name>/<t>.expect`), which runs the cell
there and compares the diagnostic.

The narrowed cells, and what each excluded target lacks (re-derived by the runner on every run; the
refusal lines are in the front's README):

| Cell | Runs on | Excluded — the binding it lacks |
|---|---|---|
| `run/async_block_all_of` | commonJS erlang beam | wasm — `std/async` |
| `run/beam_memory_ets`, `run/beam_memory_persistent_term` | erlang beam | wasm — `std/async`; commonJS — `#[@BeamMemory]` (decision 167) |
| `run/beam_memory_process_dict`, `run/beam_memory_ets_keyed` | erlang beam | wasm — `std/async`; commonJS — `#[@BeamMemory]` (decision 167) |
| `run/behavior_method_host_value` | commonJS erlang beam | wasm — `makeGreeter` |
| `run/external_erlang_host_module_missing` | erlang beam (each by `.expect`) | commonJS, wasm — `total` |
| `run/external_host_record` | commonJS erlang beam | wasm — `hostPoint` |
| `run/external_method_on_host_record` | commonJS erlang beam | wasm — `Pair.at` |
| `run/external_template_escaped_quote` | commonJS erlang beam | wasm — `say` |
| `run/external_template_refused_on_beam` | erlang beam | commonJS, wasm — `moduleNamed` |
| `run/host_array_slice_without_start` | commonJS | erlang, wasm, beam — `copyAll` |
| `run/host_template_binding_inside_while` | erlang beam | commonJS, wasm — `bump` |
| `run/host_erlang_task_result` | erlang beam | commonJS, wasm — `hostDouble` |
| `run/host_node_task_result` | commonJS | erlang, wasm, beam — `hostDouble` |
| `run/host_unknown_parameter` | erlang beam | commonJS, wasm — `std/erlang.element` |
| `run/std_template_host_fns_across_modules` | commonJS erlang beam | wasm — `std/io/fs.exists` |
| `run/task_throw_resolves_error` | commonJS | erlang, wasm, beam — `observe` |
| `modules/manifest_targets_host_binding` | erlang beam (`"targets"`) | commonJS, wasm — `magnitude` |
| `modules/erlang_host_sidecar_in_a_test` (test kind) | erlang beam (`"targets"`) | commonJS — `hello` |

Thirty-six exclusions; the run prints `narrowings: 36 exclusions audited — each stands on a host binding
the target does not have`. No other `modules/` manifest carries `"targets"`: the field used to be
boilerplate (`["commonJS", "erlang", "wasm"]` in 33 cells, `["commonJS", "erlang"]` in 14) that the
runner ignored — honoured as written it would have taken beam away from 33 passing cells — and a
project that must be refused on a target says so with `<t>.expect`.

**The runner proves its own audit.** `tests/language/run.sh --self-test` runs a synthetic suite
through the same script (`--suite <dir>`): three narrowings that stand on a host binding, which must
be scheduled on their declared targets alone, and one of each way a narrowing is refused — a target
the build accepts, a refusal that is not a host binding, `#[@BeamMemory]` used to leave beam out, a
list that narrows nothing, an unknown target, a manifest `"targets"` the build accepts, a test-kind
project naming wasm. Its report must hold each refusal's line and the tally
`11 passed, 11 failed`. A whole run of the suite (no `--only`) starts with it
and stops there if it fails — a green run from a runner that no longer refuses says nothing.

## Running

```bash
zig build test-language                                   # the installed botopink, every target
zig build test-language -- --target erlang
tests/language/run.sh --compiler <botopink> --only test/case_arms.bp
tests/language/run.sh --compiler <botopink> --only modules/two_modules
tests/language/run.sh --target beam                       # one target; `all` includes it
tests/language/run.sh --self-test                         # § Narrowing a cell — the runner's own audit
tests/language/run.sh --list                              # the plan: one `<path>\t<target>\t<run|audit>` line per job, nothing spawned
tests/language/run.sh --cold                              # every job runs; the result store is not read, the passes are written
```

`--lib-root` defaults to `<compiler>/../../libs` (where `from "std"` resolves).

The report is every `FAIL` line, the narrowing audit's count, a per-target line — `by target:
commonJS <passed>/<ran> · erlang … · wasm … · beam … · * …`, where `*` is `reject/` (one `botopink
check`) and a narrowing refused before any target ran — and the total. A claim such as "every cell
of X has a beam result" quotes the per-target line; `--self-test` pins it on the synthetic suite.

Cells run in parallel on `../../scripts/lib/pool.sh` — `botopink-lib-test`'s rule: `--jobs`
defaults to one per CPU bounded by `MemAvailable / 768 MiB`, and a cell is admitted only while
`procs_running` ≤ CPUs when another cell of the run is in flight (`run.sh` § parallel cells). Every
cell writes its verdict to its own file and the verdicts are sorted before the report, so
`--jobs 1` prints the same bytes and exits with the same status — checked on the whole suite, on
`--target beam`, and with red cells planted (front `00 · 25-gate-perf` step 1).

A whole run also prints `cells: <J> jobs — <R> run, <A> audits`: the jobs that wrote a verdict
(every job writes exactly one file; a malformed narrowing writes its `FAIL` without a job). `--list`
prints the same plan without running it, one line per job (a `reject/` cell's target is `*`), and
`scripts/gate.sh` holds `J` and `A` to it — stage 9 cannot run fewer jobs than the tree declares.

### The result store (decisions 229 and 249)

A run without `--cold` answers a job from a stored **pass** when the job's key is equal, and runs
every other job (`run.sh` § the result store; front `00-gate/133-gate-speed`). The key is the
SHA-256 of every byte the job reads, computed by `../../scripts/lib/result-store.js`:

| Part | What |
|---|---|
| compiler | `--compiler`'s build configuration (`botopink --version`'s `build:` line) and its sources partitioned by backend (`modules/compiler-core/src/codegen/backend-partition.txt`, `scripts/AGENTS.md` § Warm and cold): the shared files and the job's target's own — every target's for a `reject/` job |
| harness | `run.sh`, `scripts/lib/pool.sh`, `scripts/lib/result-store.js` |
| toolchain | `node --version`; the OTP release, its erts version and `OTP_VERSION`; `wasmtime --version`; the platform; `BOTOPINK_LIB_ROOTS`, `BPMP_HOME`, `ERL_*FLAGS`, `ERL_LIBS`, `ERL_COMPILER_OPTIONS`, `NODE_OPTIONS`, `NODE_PATH`, `HOME`, `LANG`, `LC_ALL`, `TZ`, `XDG_CACHE_HOME` — every runtime in every key, whatever the target (the comptime node is an `erl` on every target) |
| library root | every file under `--lib-root` (`.git` and `.botopinkbuild` left out) |
| the cell | `test/<n>.bp`; every `run/<n>.*` or `reject/<n>.*` file (source, `.out`, `.exit`, `.<t>.expect`, `.targets`); the whole `modules/<n>/` tree — each path, directory, executable bit and content |
| the job | the target and the job's kind (`run`, or the audit and the file that narrows) |

No analysis decides what a change can affect: one byte anywhere in the key runs the job. A verdict
is written only when every line of it is `ok` (or an audited exclusion) and the job's key is the
same after the run as before it; a failure is never stored and always runs. A job whose inputs
cannot be enumerated with certainty is never stored and is named on a `result store: <n> jobs never
stored — <why>` line: a symbolic link in the cell, a `git` dependency or a `path` dependency that
leaves the cell, and — for every job of the run — a library root the compiler would find by walking
up from the scratch directory (`botopink.json`, `libs/` or `repository/` above it), a binary
not built from the sources its key reads, a partition that fails its audit. The store is
`<repo>/.botopinkbuild/cache/results/language/<kk>/<key>` (decision 225; `--store-root` names
another directory), entries unused for 7 days are deleted, `rm -rf .botopinkbuild` wipes it, and
`--cold` (passed by `scripts/gate.sh --cold`) never reads it and writes its passes. The
`--self-test` suite always runs cold, into a store of its own deleted with the run. Every run prints `result store: <J> jobs — <R> run, <S> from store`, and
`scripts/gate.sh` holds `R + S` to the plan. `modules/compiler-cli/tests/result_store.sh` (`zig build
test-cli`) holds the rule end to end: a byte of a cell, of the library root, a wasm emitter line
(wasm cells only), a checker line (every cell), an unlisted emitter file (shared), a stale binary,
a failed partition audit, another `node` / OTP / `wasmtime` version, `--cold` and a deleted store.

## A red cell is red

The suite keeps no list of known failures (gate-b of `specs/1.0.11-beta/00-gate`, decision 154): the
file that held one reached zero lines and was deleted with the runner's reader of it. A cell passes
or it fails, the report prints `language tests: <n> passed, <m> failed`, and a run with a `FAIL`
exits 1. A scenario the compiler gets wrong is fixed in the compiler; a cell that must be tolerated
is a decision to delete the cell, not a line somewhere.

What a cell may still say about a target, each checked on every run:

- **the target refuses the program** — `<name>.<t>.expect` / `modules/<name>/<t>.expect`
  (§ The sidecars of a `run/` cell): the claim is the diagnostic, located;
- **the target has no host binding for it** — `<name>.targets` / a manifest `"targets"`
  (§ Narrowing a cell): the claim is audited against the compiler's host-binding refusal.

A `reject/` `.expect` names a short key phrase of the diagnostic decision 8 sketches (`use _ {`,
`not exhaustive`, `removed-loop-parenthesised`…) and the location of the offending token. The front
that implements the diagnostic fixes its final wording and updates the `.expect` in the same change.

## Who adds a cell — the owner rule

A cell is added **in the commit of the front whose fix it asserts**: one new file per cell (its
`.out` / `.expect` / `.exit` / `.targets` beside it, or one `modules/<name>/` directory), no edit to a
cell another front added, no shared file to append to. The commit message says the cell was **red on
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

**The suite on four targets, every cell green** (fronts `111-gate-beam-and-targets` and
`110-gate-wasm` of 1.0.11-beta). `--target all` is commonJS, erlang, wasm and beam; every narrowing
is audited (§ Narrowing a cell); the report is the runner's tally (§ Running, § A red cell is red).
Measured on the integration of the 1.0.11-beta compiler fronts `01-checker`, `02-erlang`,
`03-beam`, `04-js`, `05-wasm`, `12-language-tests`, `14-comptime-on-beam` and `26-cli-tooling`:

```
$ tests/language/run.sh --target all
self-test: 8 malformed or unbacked narrowings refused, 3 backed ones scheduled on their declared targets alone
FAIL     [wasm] modules/method_on_unimported_type — exit 1; stdout:  ; error: `quote` has no `#[@External.<Target>(…)]` for the wasm backend
narrowings: 33 exclusions audited — each stands on a host binding the target does not have
by target: commonJS 499/499 · erlang 503/503 · wasm 254/255 · beam 503/503 · * 205/205
language tests: 1964 passed, 1 failed
```

The one red cell is the cell's own module `log` read as the bundled `log` package, whose
`json.quote` has no wasm binding; front 129 owns it.

Recounted on disk:

```
$ ls test/*.bp | wc -l          # 68
$ ls run/*.bp | wc -l           # 200 — 18 with a .targets, 25 .<target>.expect files, 2 .exit
$ ls reject/*.bp | wc -l        # 205
$ ls -d modules/*/ | wc -l      # 79 — 4 of the test kind, 55 <target>.expect files, 2 "targets"
```

Decision 146 on wasm (a function whose body calls a host function with no binding for the target is
refused called or not, on every target): `run/external_wrapper_keeps_refusal` passes on wasm by its
`.wasm.expect`; `run/std_asserts_on_every_target` and `modules/labelled_call_by_label` are refused
there at the import of `testing.asserts` (`.wasm.expect` / `wasm.expect`), and so is
`run/std_asserts_host_cell_on_wasm`; `run/std_decorator_through_namespace` pins the import's STD-001
line; `run/external_wrapper_associated_default` runs on four targets.

`zig build test-language` is a stage of `scripts/gate.sh` (after `test-libs`) and a step of the CI
`test` job (ubuntu + macos). A red cell fails the gate.

## Notes for whoever writes the next cell

**Shapes that do not parse: none is known.** Every row this list carried parses. Re-measured with
`botopink check` and `botopink run` by front `01-compiler/12-language-tests` of 1.0.11-beta; each
row is pinned by a cell that passes on every target its kind has:

| Shape | Was listed as | Now | Cell |
|---|---|---|---|
| a module-level `var` | absent | `var` and `pub var`, with or without a `#[@BeamMemory.<member>]` above it; a `val` assigned anywhere is a located error naming `var` (decision 38) | `run/module_var`, `run/beam_memory_off_beam`, `reject/val_assign_module` |
| §5.1 `Pattern { body }` arms, §5.3b section arms | `06 N22` | parse, check and run | `test/case_arms.bp`, `test/case_sections.bp` |
| a block-shaped statement not last in its block (`if (1 > 0) { … }` then `@print("b");`) | decision 29 — "the `;` goes" | parses and runs since C-13 made the `;` after a braced block optional; the formatter writes no `;` there | every cell `botopink format` rewrote (FC-4) |
| `adder(3)(4)` — calling the result of a call | "make it parse" (14) | parses, checks and runs | `test/curried_call.bp` |
| `#(a: i32, b: string)[]` — an array of labeled tuples | "make it parse" (14) | parses, checks and runs, with `@Result<i32, string>[]` and `(i32 \| string)[]` | `test/type_suffix.bp` |
| `??` | deliberately absent (14) | parses and runs (decision 28); `catch` is `@Result`-only, so nothing else gives an optional a default | `test/nullish_default.bp` |
| `xs[0]`, `xs[0..2]`, `d["k"]` — an index expression | "no index expression in the grammar" | parses, checks and runs (decisions 30, 63, 139) | `run/index_expression.bp`, `run/index_dict.bp`, `run/index_past_the_end_is_null.bp`, `run/index_negative_from_end.bp` |
| a bodyless `fn` with `-> void` | no rule | parses and runs (decision 33); without a return type it is `bodyless-fn-needs-return-type` | `test/bodyless_fn.bp`, `reject/bodyless_fn_no_return_type.bp` |
| a method on a parenthesised expression or a number literal — `(a == b).toString()`, `("ab").length`, `42.toString()` | open | one production; `42.toString()` prints `42` on all four targets (commonJS once wrote `42.toString()` into the program, which node reads as a float) | `test/paren_receiver.bp`, `run/method_on_number_literal.bp` |

**The range pattern — decision 53.** `...` is inclusive in a pattern; `..` is exclusive in a slice
and in `for (a..b)`, Zig's split. `1..9` in an arm is `error[pattern-range-exclusive]` located at
the `..`, with `1...9` as the hint (`reject/pattern_range_exclusive`). `1...9` matches both endpoints
and nothing outside them on all four targets — in a `case` used as a value (`run/case_range_value.bp`,
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
§ structural equality). `run/record_structural_equality.bp` pins it on four targets — a
record, a nested record, a tuple, an array of records, enum variants with payloads,
two types with the same fields, `!=`, a generic `same<T>` and an `equals` method `==`
does not call. `test/type_identity.bp` keeps asserting the other half, two
different types with the same fields.

**`f64` under `==` is a total order — decision 214**, as Java's `Double.compare` and
Kotlin's data class: `0.0 == -0.0` is `false` and `NaN == NaN` is `true`, bare and
inside a record, tuple, array or variant, while `<`, `>`, `<=`, `>=` keep IEEE
ordering. erlang and BEAM already separate the zeros (`=:=`); commonJS lowers a
float `==` to `Object.is` and wasm to `$__f64_eq` / `$__f32_eq` (NaN canonicalised,
then the bits). `run/f64_equality_total_order.bp` pins the zeros on all four
targets, with `-0.0` built at run time as `zero() * -1.0`. **The NaN rows are not a
`run/` cell**: erlang and BEAM never produce a NaN (`z / z` raises `badarith` at run
time), and § Narrowing a cell lets a cell leave a target out only when the build
refuses it on a host binding, which a division is not — a `.targets commonJS wasm`
would fail the audit. Each backend that has NaN pins that half in a RUN LOG fixture of
its own: `codegen/tests/commonjs.zig` and `codegen/tests/wat.zig`, `f64 ---- NaN
equals NaN under ==`.
`run/integer_never_negative_zero.bp` is the premise commonJS needs for it: an integer
is never `-0` (`0 * -1`, `-x`, `-4 % 2` and `0 / -3` print `0` and compare equal to
`0`), so a generic `same<T>` answers `true` for two integer zeros and `false` for
`0.0` against `-0.0` on four targets — commonJS printed `-0` and answered `true`.

**The identity is asserted on three backends and RUN on four.** `botopink test` refuses wasm,
so a `test/` cell reaches commonJS, erlang and beam. `run/type_identity_equality.bp` is the same
statement as a `run/`: `Person(name: "a", age: 1) == Vec(name: "a", age: 1)` prints `false` on all
four since `13-module-identity` half 3 put the declaration inside the value.

**`use` is tested from botopink since front 19 of 1.0.10-beta**, spelled to decisions 102/104
(front 21): `test/context_use.bp`, `run/context_use.bp` and the `reject/use_*.bp` cells declare
their own owner type (`type Element(…) implement @Renderable`, decision 354), hooks as
`fn … -> @Component<T>` and components as `fn … -> @Component<Element>`, and
pin the binding of `T`, field and positional destructuring, a custom hook composing hooks, a bare
void `use`, an unannotated `fn … -> Element` as an ordinary function, the rules of hooks (decision 357,
`use-not-top-level`; rows 4b and 4c were parse errors of the static prefix before it),
`use-without-context-effect` (a `-> Element` body, a plain `-> string` body, a `#[@future]` body —
`reject/use_future_without_owner.bp`, decisions 89/90 revoked) and `use-of-non-context-fn` (a
module-level `val`, decision 87). A component's caller awaits it:
`run/context_use.bp` drives the components from a `#[@future] fn run`, and the `test/` cells await
them (a `test` body is a future context). `test/use_future_context.bp` is the server component that
`use`s and `await`s under a `@Component` return. Front 24 (decision 118) deleted
`reject/use_future_context_duplicate.bp`, `reject/two_effect_markers.bp`,
`reject/wrapper_without_annotation.bp` and `reject/result_without_wrapper.bp` with the annotation
rules they pinned — a function has one return, so it has one effect.
`reject/use_tuple_arity.bp` and `reject/use_tuple_of_non_tuple.bp` are front 19 step 3's
`use-tuple-arity` refusals, located at the binding.

**Decisions 63–66, one cell or one sentence each (C-16).**

- **63** (an index is a method call, amended 2026-09-19: the index answers what `at` answers, `?V`)
  — `run/index_dict.bp` (present key → `1`; `Dict<string, ?i32>` → `null`; absent key → `null`, and
  the program goes on), `run/index_past_the_end_is_null.bp` (`xs[9]` is decision 47's `null`) and
  `run/index_at_optional.bp` (`Dict.at` / `String.at` by name answer `?V`, `null` for absent), with
  `run/string_at.bp` for the present-index reader — all on four targets. The fixture C-16 names
  `index_an_index_past_the_end_answers_zero` is a `src/codegen/tests` fixture, not a cell of this
  suite.
- **64** (a wrapper per host-bound std `declare fn`) — `run/std_erlang_node.bp`: `erlang.node()`
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
  `tests/language` is one of its `TREES`: `test/`, `run/` and `modules/` are canonical — a cell
  is written formatted (`botopink format <file>`), and an unformatted one is a red gate. Two
  things are outside the walk, both by structure (`format_cmd.zig`), never by a list: every
  `reject/<n>.bp` beside its `<n>.expect`, and
  `modules/lexer_error_in_imported_module/src/pattern.bp` — the bad escape the cell exists to
  refuse — by the second arm (gate-c: a `.bp` under `modules/<cell>/` that the cell's `.expect`
  files name and that does not lex or parse). A `modules/<cell>/<target>.expect` pins a
  `<file>:<L>:<C>`: reformatting the file it names moves the pinned line with it, in the same
  change (`modules/decorator_imported_function_name_conflict` pins `src/main.bp:21:3`, the
  `#[tag]` under an `@emit(…)` argument the formatter opens over four lines).

1.0.11 front 14 step 1 adds `reject/comptime_method_nothing_answers` — a decorator body (untyped)
calling `.frobnicate(1, 2)` on a string, which no primitive type and no host function answers: the
compiler refuses it before any comptime runtime runs, the message names the call by its `line:col`
in the body and the caret is the annotation that ran it.

**`@panic` and `@todo` abort with stdout intact and a non-zero status on all four backends**
(`run/panic_aborts.bp`, `run/todo_aborts.bp`, `.exit` = `nonzero`). On beam a function whose whole
body is `@todo()` is emitted and raises the builtin's own `{todo, <<"not implemented">>}` —
re-measured by front 12 of 1.0.11-beta (it used to be dropped, and the abort was `undef`).

What cannot be tested from botopink at all, and why: `@typeInfo` / `@makeRecord` / `partial` / `omit`
/ `pick` (they produce types, and asserting on emitted text is the snapshots' job). Struck from this
list by C-16, each with the cell that covers it: `pub default mod` / `pub default fn`, `@ExprCustom` /
`q.custom` and `.d.bp` via `files` (`modules/local_dependency`, a local dependency needs no network);
"no external target for the active backend" (`run/external_erlang_only.bp`, a `run/` cell refused on
two targets through a `.<target>.expect` sidecar each — `botopink run --target <t>` is not
target-independent, which is what `reject/` lacked); `@panic` / `@todo` (`run/` compares stdout **and**
the status through `.exit`, so an aborting program is exactly what it can assert).
