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
| `modules/<name>/` with a `test/` tree and no `expected.out` | the `test/` kind over a whole project, run by `botopink test --target <t> --json` on commonJS and erlang; results are keyed `modules/<name>::<test>` | every test reports `ok` |

1.0.10-beta's `00 · 23-std-purity` step 1 (decision 107, the import tree) adds `modules/import_tree`
— a dotted path and a braced group over the package's own tree and over std, aliases bound, only the
leaves in scope, on commonJS/erlang/wasm — and three `reject/` cells: `import_name_collision` (the
second item) and `import_group_modifier` (`*` on a node that opens braces); the third,
`import_alias_on_type`, is now `modules/import_alias_on_type` — decision 110 made `as` legal on a type
and a type alias (`01-checker`), and the cell imports `Point as P`, `Pair as Two` and std's
`Dict as D` and runs on all four targets; `modules/import_alias_static_call` covers the alias in
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
`type_empty_braces` (`type Marker {}`) and `type_without_field_list` (`type MathOps { fn … }`), both
`type-without-field-list` where the `()` belongs.
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
declare `pub fn title`; `main` imports it `from "app.page"` and a third module `from
"app.blog.page"`, and the two answers differ; `import {page} from "app.blog"` binds the namespace
`app/blog/page` (an unbound `page` on the parent binary). `import_same_fn_name_two_aliases` — `NotFound` from
`app.not_found` and from `app.blog.not_found` in one module, each under its own alias, both called
(a generated route table's shape). `import_same_fn_name_in_dependency` — the same inside a
dependency, whose own module names a sibling by the path below the package (`from "app.page"` for
`site/app/page`), beside a consumer naming the other by the package-qualified path (`from
"site.app.blog.page"`). The three were refused as `ambiguous-import-use` on the parent binary: a
dotted source was compared byte for byte with the module's `/` path and named nothing, and a path
below the importer's package had no reading.
`import_ambiguous_from_package` is the refusal that stays — `import {NotFound} from "site"` names a
package two of whose modules declare the name, so the use is `ambiguous-import-use`, located, naming
both, by `<target>.expect`. `import_sibling_path_beside_std_name` — a dependency's module imports a
type and two functions `from "sort/queue"` (its sibling, `kit/sort/queue`) in a program that also
loads `std/collections`, which declares the three names: the dependency was refused ("`Queue` is
declared `pub` by `std/collections` and by `kit/sort/queue`, and this import does not say which") while
a path of several segments below the importer's package named nothing.
`import_own_module_over_dependency_path` is that reading's boundary: the project's own `app/page` is
what `from "app/page"` names although the dependency's `site/app/page` declares the name too — the
full path is read first (it passes on the parent binary; it guards the order of the two readings).
`import_same_name_twice_unaliased` is the use that cannot tell: `import {title} from "app.page";
import {title} from "app.blog.page";` is `import-name-collision` at the second item, naming both
modules, by `<target>.expect` — the second import used to replace the first and commonJS answered
`app` where erlang and wasm answered `blog`. `import_same_fn_name_std_and_package_aliases` — a package
and `std/collections` both declare `lt` and `reverse`; one module imports each under an alias and
calls the four (it passes on the parent binary; it pins the rule).
Decision 141 adds `run/external_template_refused_on_beam` — an `@External.Erlang` template with a
macro runs on erlang and is a located build error on beam naming the construct (`.beam.expect`); beam
no longer evaluates a template it cannot compile from source at run time.
C-03's beam half adds `run/std_template_host_fns_across_modules` — std host functions whose
`@External.Erlang` body is a template (`fs.exists`, `fs.readText`, `os.eol`, `process.platform`,
`encoding.hexEncode`, `hash.sha256`, `json.quote`, `regex.matches`) called from the program's
module through a folder namespace and a leaf import, on commonJS, erlang and beam (`.targets`: wasm
refuses std's own call sites of those cells).
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
`00 · 03-beam`'s split row adds `run/string_split_empty_separator` — `split("")` cuts into UTF-8
codepoints (`"%0Aéz"` → 5 pieces, `""` → none) beside a non-empty separator and an empty separator
held in a `val`, on all four targets (beam lowered it to `string:split/3`, wasm cut between bytes).
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
`files` lists every importer before what it imports, `from "a"` and a bare `import {Leaf};`),
`run/external_erlang_host_module_missing` (`.targets` `erlang beam`: an `@External.Erlang` module that is
neither shipped nor in the Erlang code path is a located build error on both, `.erlang.expect` and
`.beam.expect`),
`modules/erlang_host_sidecar_shipped` (a project's `src/sidecars/*.erl` reached by `botopink run` on
erlang and on beam; `commonJS.expect` / `wasm.expect`), `modules/erlang_sidecar_named_like_a_module` (a
sidecar `text.erl` beside the module `text.bp` is shipped — the shipper skipped a basename match), `reject/bare_print_call` (`println(x)` is unbound
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
percent codec; `.wasm.expect` — STD-001 at the import) and `run/bodyless_method_without_binding` (a
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
synthesizes `mockRepo()` and its stubs answer; wasm refuses the import by `.wasm.expect`),
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
commonJS never bound a variant's payload), `run/behavior_implemented_by_enum` (an enum implementing a
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
also adds `run/use_one_base` and `reject/use_two_bases` to the `use_*` area for
decision 96, `run/option_unwrap_or` + `reject/option_expect_removed` to
`optional*` for F11, and `reject/external_inline_unread` to `external_*` for F9 — `inline` on
a variant whose emitter never reads it is refused at the annotation), and `enum_section_*` (1.0.10-beta's `00 · 01-checker`: which enum a
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
§ `narrowing_*` below), and the module-`var` cells of 1.0.10-beta's `00 · 17-beam-memory` (C-05, decisions 28, 38, 41, 43, 51): `run/module_var` — a module-level `var` written twice through a `fn` prints `2` on commonJS and wasm and is listed against C-10 on erlang (unbound `Hits`, does not compile) and beam (the write is dropped and it prints `0` at exit 0 — the silent one); `test/beam_memory_noop` — the annotation is a no-op off the BEAM, each test writing and reading back through the binding (erlang listed against C-10 for the same reason); and seven `reject/` cells, one per diagnostic — `val_assign_module` and `val_assign_local` (a `val` is immutable, the hint names `var`), `beam_memory_unknown_member`, `beam_memory_unknown_argument`, `beam_memory_keyed_scalar`, `beam_memory_keyed_list` (decision 51: `keyed` is `Dict`-only) and `beam_memory_on_val`. C-10 (front 17 step 4) adds the per-mode BEAM cells, each a `run/` cell with `.targets` = `erlang beam` (a `test/` cell cannot be narrowed to a target, and on commonJS the modes are one program-wide value): `run/beam_memory_process_dict` (a value written in `main` is not seen by a process `async.runAll` spawns, and its write does not reach `main` — `[0]` then `5`), `run/beam_memory_ets` (decision 39's fixture: five processes × three increments print `15`) and `run/beam_memory_persistent_term` (put at load, read by a spawned process: `[101]`); and the refusals its lowering needs — `reject/beam_memory_pt_write`, `reject/beam_memory_ets_recompose`, `reject/beam_memory_ets_bump_non_integer` (decision 40) and `reject/beam_memory_ets_initialiser` (a seed that is neither a literal nor `comptime`). `test/beam_memory_noop` no longer writes a `PersistentTerm` var (refused on every target) nor carries the `Ets(keyed = true)` `Dict` (no literal `Dict` seed exists; `keyed` is refused on the BEAM until it is lowered). `run/module_var` and `test/beam_memory_noop` pass on erlang, and the three `run/beam_memory_*` cells and `run/module_var` on beam (step 5). `01-checker` step 12 replaces `run/variant_name_ambiguous` (an erlang-only emit refusal) with `reject/variant_name_ambiguous` — the checker refuses `.Circle` with no expectation on every target — and adds `run/variant_leading_dot_expected` (the expected type decides `.Circle`; a qualified constructor is the enum written), `run/section_path_resolution` (a section leaf's shorthand, a payload section path through the annotated enum, a qualified section value) and `reject/section_leaf_without_expectation`; each fails on the `feat` binary. `modules/template_name_collision` (two modules exporting a template `tag`; the import from `loud` expands `loud`'s — the bare-name registry expanded `quiet`'s at exit 0) is 01 step 12's registry half. `run/try_catch_null_and_noreturn_narrowing`, `run/component_call_renders`, `run/component_call_awaited` (a written `await` of a component call inside a component body — jhonstart's layout chain) and `reject/try_catch_handler_mismatch` are the maintainer's 24-box-1 rows (the guide's page example): `catch null` is a `?T`, a `noreturn` call narrows, a component called in a component body renders; each fails on the `feat` binary. `run/labelled_arguments_reorder` (a label names the parameter it fills in a complete call — fn, record, method, primitive method, self tail call) and the `run/labelled_arguments.bp` erlang line's removal are 01's labelled-call row. 01 R7 (decision 2) adds `reject/fn_falls_off_end` and `reject/if_without_else_value`, both accepted by the `feat` binary. C-18's decision 45 adds `reject/member_of_optional` (a member read off a `?T` names `?.`) and moves `test/tuple_labels.bp` §6 T4 to `rs.at(0)?.b` — both targets pass it, the label is carried on commonJS and erlang. Decision 15's annotation grammar (front 17 step 3's recorded row) adds `reject/annotation_unknown_family` (`#[@TotallyMadeUp.Nonsense(whatever = 42)]` on a `var`) and `reject/annotation_family_misspelled` (`#[@BeamMemroy.Ets]` names `@BeamMemory`). Pending 0203-a, answered (b), adds `reject/primitive_method_undeclared` (`s.toUpperCase()` names `toUpper`, the method whose host spelling it is) and `reject/primitive_method_unknown` (`"x".fooBar()`, no near name), and re-spells `test/string_case_conversion` to `toUpper` / `toLower` — its erlang line is gone. `01-checker` step 13 adds the two cells of "a local ends with its body": `reject/local_binding_escapes` (a `val` of one `fn` used by the next is refused at the use, naming `holder`) and `run/local_shadow_ends_with_body` (a local `p` shadows the module's `pub fn p` only inside its own `fn` — `3` then `p:x`); each was run with the `feat` binary and fails there as the step describes. One scenario group per
file: a parse error is the blast radius, so nine `#[@External]` declarations in one file mean one
unparseable annotation hides the other eight.

### The erlang backend's cells (1.0.11-beta `01-compiler/02-erlang`)

Each was run with the parent binary and fails there as its row describes.

- `run/module_fn_named_like_bif` (language-gaps T13): a module declaring `element/2`, `apply/2`,
  `length/1` and `hd/1` reads a record field, calls each of its own fns, prints a record and reads
  `Array.at` past the end — on all four targets. The erlang module did not compile (`element/2`
  is illegal in the print helper's guard once it is the module's own fn) and, before the
  `no_auto_import` directive, read `p.y` through the module's `element/2`.

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
| Chain and `use` | `run/component_hook_and_component`, `run/component_result_try_await`; `reject/component_try_element`, `reject/await_under_result`, `reject/use_under_task`, `reject/component_two_bases`, `reject/use_of_component` |
| `async { }` | `run/async_block_all_of` (`.targets commonJS erlang beam`: `std/async` has no wasm host), `run/async_block_value_type`, `run/async_block_return`; `reject/async_block_use`, `reject/async_block_conflicting_errors` |
| Iterators | `run/iterator_fibonacci`, `run/iterator_result_item`, `run/iterator_result_items` (step E4), `run/iterator_factory`, `test/yield_step_next` and `run/yield_step_next` (`.next()` by hand on an `@Iterator` and, awaited, on a `@Stream` — the `run/` half reaches beam and wasm, which a `test/` cell cannot, and steps a parameter inside a `while`); `reject/iterator_throw_without_result`, `reject/iter_await`, `reject/iter_mixed_yield_return`, `reject/iterator_error_param_removed` |
| Streams | `run/stream_pages` (a simulated http failing mid-way), `run/stream_loop_no_failure`; `reject/for_await_without_task` |
| Prefixed loops | `run/prefixed_loop_forms`, `run/prefixed_loop_result_item`, `run/prefixed_loop_break_value`, `run/prefixed_loop_nearest_scope`, `test/contextual_words`; `reject/prefixed_loop_break_outer` |
| Host (decision 126) | `run/host_node_task_result` (`.targets commonJS`), `run/host_erlang_task_result` (`.targets erlang beam`) |
| The E3.9 hint (a `@Result` used as its `U`, one hint per source) | `reject/result_hint_await` (`try await t`), `reject/result_hint_for_item` (`try r`), `reject/result_hint_inferred_async` (the `await` hint plus the `try` that made the block's value a `@Result`) and `reject/result_hint_inferred_iter` (the `for`-item hint plus the `throw` that made the `iter` items `@Result`s); the two `for` cells carry no location line — the mismatch is reported at the file |
| Migration (decision 127, guide § 9's "Old names that left") | `effect-annotation-removed`: `reject/effect_annotation_removed_{result,future,use,generator,result_generator,future_generator}`, the three loop forms `…_{generator,result_generator,future_generator}_loop`, and the older `…_{context,iterator,async_generator}`; `effect-type-removed`: `reject/effect_type_removed_{future,future_no_error,use,generator,result_generator,future_generator}` and the older `…_{async_iterator,iterable,iterator_step,yield}`; the arity refusals `reject/component_one_type_argument` (`@Component<T>`), `reject/context_two_type_arguments` (`@Context<B, R>`), `reject/yield_step_error_param` (`YieldStep<T, E>`); and the existing refusals `reject/loop_condition_parenthesised`, `reject/loop_await_removed`, `reject/component_plain_return` |

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
from "shapesdsl"` and expands `shapesdsl "4, 5"` at compile time. Green on all four targets, measured
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
| `run/std_default_fn_in_a_std_module.bp` | the VALUE, through four std modules and both interfaces. `botopink run --target erlang` compiles the whole output directory with `erlc` up front, so a dead std module is a hard error on this path. `.targets` is `commonJS erlang beam`: wasm refuses the program — `std/encoding.percentEncode`, which `querystring` reaches, has no wasm binding |
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
template back reds lines 3, 4, 8 and 9 on erlang and beam and leaves commonJS green.

### The sidecars of a `run/` cell

Three optional files beside `run/<name>.bp`, each a claim the cell makes (C-16, front 12 steps 4.3
and 4.4). `run.sh`'s usage block is the reference; this is the why.

| Sidecar | Claim | Passes when |
|---|---|---|
| `<name>.exit` holding `nonzero` | the program **aborts** after printing `.out` (`@panic`, `@todo`, a failed index under decision 63) | stdout equals `.out` **and** the status is not 0. The number is never pinned: node 1, erl 1, wasmtime 134 are the runtimes' (§ Never pin an erlang exit status) |
| `<name>.<target>.expect` | on that target the compiler **refuses** the program — `reject/`'s shape, per target | exit ≠ 0 and the diagnostic contains line 1 (and ` --> src/main.bp:<L:C>` when line 2 is present). `run/external_erlang_only.{commonJS,wasm}.expect` and `run/std_erlang_node.{commonJS,wasm}.expect` are the live ones |
| `<name>.targets` | the cell is scheduled only on these targets, **because every other target refuses it on a host binding** | the cell passes on each target it names, and `botopink build --target <t>` refuses it on a host binding on each target it leaves out — § Narrowing a cell |
| `modules/<name>/<target>.expect` | the `.<target>.expect` claim for a whole project: that target **refuses** it | exit ≠ 0 and the diagnostic contains line 1 (and ` --> <line 2>` when present — `src/<file>.bp:<L:C>`, the file named because a project has several). `modules/external_method_imported/wasm.expect` is the live one |

Any other content in `.exit` is a malformed claim and fails the cell. The cells that carry
`.targets`, and what each excluded target lacks, are listed in § Narrowing a cell.

## The targets

Measured at front `111-gate-beam-and-targets` of 1.0.11-beta (`specs/1.0.11-beta/00-gate/` in the
meta workspace), OTP 28, node v25.

| Target | `botopink test` | `botopink run` | In the suite |
|---|---|---|---|
| commonJS | yes | yes | every kind |
| erlang | yes | yes | every kind |
| wasm | refused — "supports only the commonJS and erlang targets" | yes, it executes | `run/` and `modules/` only |
| beam | refused — the same message | yes: it builds `out/beam/*.S`, assembles each beside itself (`erlc +from_asm -o out/beam`) and runs the entry with `erl -pa out/beam` | `run/` and `modules/` only |

`--target all` is the four of them. A machine without `erlc` or `erl` fails the run before any cell
starts (`run.sh: the beam target needs erlc`); it never runs three targets and reports "all"
(decision 67).

The `run/` sidecars (§ above) apply on every target the cell reaches, beam included: `botopink run`
returns the assembled program's status, so an `.exit` claim is checked there too
(`run/panic_aborts.bp` and `run/todo_aborts.bp` pass on beam — the second for a different reason,
§ Notes).

`test/` cells therefore run on commonJS and erlang; `run/` and `modules/` cells run on all four;
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
std-unsupported-on-target: std/<m> has no `@external` for target '<t>'
```

— the one reason a program structurally has no row on a target. A target the build accepts, or
refuses for another reason, fails the run and names the cell: the narrowing was hiding a gap of that
backend, and a gap is a row of the backend's front, never a line in a `.targets` file. So does a
narrowing that names an unknown target, a target its kind does not have, the same target twice, or
every target of its kind (it narrows nothing — delete it). No flag, list or environment variable
turns the audit off (decision 67).

One host binding the compiler does not refuse: a module `var` under `#[@BeamMemory.<mode>]` binds
BEAM storage, and decision 43 makes the annotation a silent no-op off the BEAM. A cell that declares
one may leave out commonJS and wasm on its own source's evidence — never erlang or beam.
`run/beam_memory_process_dict` is the one cell that does: its `.out` is the BEAM's by construction
(one value per process), and `test/beam_memory_noop` pins the no-op.

A target on which the cell must be refused for a reason that *is the cell's claim* is not narrowed
away — it is pinned with `<name>.<t>.expect` (`modules/<name>/<t>.expect`), which runs the cell
there and compares the diagnostic.

The narrowed cells, and what each excluded target lacks (re-derived by the runner on every run; the
refusal lines are in the front's README):

| Cell | Runs on | Excluded — the binding it lacks |
|---|---|---|
| `run/async_block_all_of` | commonJS erlang beam | wasm — `std/async` |
| `run/beam_memory_ets`, `run/beam_memory_persistent_term` | commonJS erlang beam | wasm — `std/async` |
| `run/beam_memory_process_dict` | erlang beam | wasm — `std/async`; commonJS — `#[@BeamMemory.ProcessDict]` (decision 43) |
| `run/behavior_method_host_value` | commonJS erlang beam | wasm — `makeGreeter` |
| `run/external_erlang_host_module_missing` | erlang beam (each by `.expect`) | commonJS, wasm — `total` |
| `run/external_host_record` | commonJS erlang beam | wasm — `hostPoint` |
| `run/external_method_on_host_record` | commonJS erlang beam | wasm — `Pair.at` |
| `run/external_template_escaped_quote` | commonJS erlang beam | wasm — `say` |
| `run/external_template_refused_on_beam` | erlang beam | commonJS, wasm — `moduleNamed` |
| `run/host_array_slice_without_start` | commonJS | erlang, wasm, beam — `copyAll` |
| `run/host_erlang_task_result` | erlang beam | commonJS, wasm — `hostDouble` |
| `run/host_node_task_result` | commonJS | erlang, wasm, beam — `hostDouble` |
| `run/host_unknown_parameter` | erlang beam | commonJS, wasm — `std/erlang.element` |
| `run/std_default_fn_in_a_std_module` | commonJS erlang beam | wasm — `std/encoding.percentEncode` |
| `run/std_template_host_fns_across_modules` | commonJS erlang beam | wasm — `std/io/fs.exists` |
| `run/task_throw_resolves_error` | commonJS | erlang, wasm, beam — `observe` |
| `modules/manifest_targets_host_binding` | erlang beam (`"targets"`) | commonJS, wasm — `magnitude` |

Thirty exclusions; the run prints `narrowings: 30 exclusions audited — each stands on a host binding
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
`13 passed, 11 failed`. A whole run of the suite (no `--only`) starts with it
and stops there if it fails — a green run from a runner that no longer refuses says nothing.

## Running

```bash
zig build test-language                                   # the installed botopink, every target
zig build test-language -- --target erlang
tests/language/run.sh --compiler <botopink> --only test/case_arms.bp
tests/language/run.sh --compiler <botopink> --only modules/two_modules
tests/language/run.sh --target beam                       # one target; `all` includes it
tests/language/run.sh --self-test                         # § Narrowing a cell — the runner's own audit
```

`--lib-root` defaults to `<compiler>/../../libs` (where `from "std"` resolves).

Cells run in parallel on `../../scripts/lib/pool.sh` — `botopink-lib-test`'s rule: `--jobs`
defaults to one per CPU bounded by `MemAvailable / 768 MiB`, and a cell is admitted only while
`procs_running` ≤ CPUs when another cell of the run is in flight (`run.sh` § parallel cells). Every
cell writes its verdict to its own file and the verdicts are sorted before the report, so
`--jobs 1` prints the same bytes and exits with the same status — checked on the whole suite, on
`--target beam`, and with red cells planted (front `00 · 25-gate-perf` step 1).

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

## Status and the gate

**Fronts `111-gate-beam-and-targets` and `110-gate-wasm` of 1.0.11-beta — the suite on four
targets, every cell green.** `--target all` is commonJS, erlang, wasm and beam; every narrowing is
audited (§ Narrowing a cell); the report is two numbers (§ A red cell is red):

```
$ tests/language/run.sh --target all
self-test: 8 malformed or unbacked narrowings refused, 3 backed ones scheduled on their declared targets alone
narrowings: 30 exclusions audited — each stands on a host binding the target does not have
language tests: 1483 passed, 0 failed

$ tests/language/run.sh --target beam
narrowings: 3 exclusions audited — each stands on a host binding the target does not have
language tests: 395 passed, 0 failed
```

Recounted on disk: `ls test/*.bp | wc -l` 64 · `ls run/*.bp | wc -l` 169 (17 with a `.targets`,
25 `.<target>.expect` files) · `ls reject/*.bp | wc -l` 173 · `ls -d modules/*/ | wc -l` 60 (25
`<target>.expect` files, one `"targets"`). Decision 146 on wasm (a function whose body calls a host
function with no binding for the target is refused called or not, on every target) moved four cells
and added one: `run/external_wrapper_keeps_refusal` passes on wasm by its `.wasm.expect`;
`run/std_asserts_on_every_target` and `modules/labelled_call_by_label` ran on wasm and are refused
there now, at the import of `testing.asserts` (`.wasm.expect` / `wasm.expect`);
`run/std_asserts_host_cell_on_wasm` was refused at the call of `deepEquals` and is refused at the
import; `run/std_decorator_through_namespace` pins the import's STD-001 line where it pinned the
first host cell `testing.mocks` named; `run/external_wrapper_associated_default` is new (four
results).

`zig build test-language` is a stage of `scripts/gate.sh` (after `test-libs`) and a step of the CI
`test` job (ubuntu + macos). A red cell fails the gate.

## Notes for whoever writes the next cell

Shapes that do not parse — **re-measured at `aab5489`** with `botopink check`, after front 15
(`specs/1.0.5-beta/15-language-surface/README.md`) landed (`109f6c9`). Five of the seven rows this
table carried are gone: they parse, and so does the sixth since C-13. What is left is one row and one
correction.

| Shape | At `aab5489` | Decision |
|---|---|---|
| a module-level `var` | parses since front 17 (`8146d2b6`): `var` and `pub var`, with or without a `#[@BeamMemory.<member>]` above it; a `val` assigned anywhere is a located error naming `var` (decision 38) | **landed.** `run/module_var` and `test/beam_memory_noop` pin it; what is still absent is the erlang/beam lowering (C-10), which is why both carry an erlang line and the first a beam line |

**Struck, because they now parse.** Each was measured at `aab5489`:

| Shape | Was listed as | Now |
|---|---|---|
| §5.1 `Pattern { body }` arms, and §5.3b section arms | `06 N22` | parse; `test/case_sections.bp` fails in inference like every other `case` cell (`expected string, got void`), not at the `{` |
| a block-shaped statement not last in its block (`if (1 > 0) { … }` then `@print("b");`) | "decision 29 — the `;` goes", `error: this token cannot appear here` at the next statement | **parses and runs** since C-13 made the `;` after a braced block optional: the program prints both lines on commonJS (re-measured by front 111 of 1.0.11-beta) |
| `adder(3)(4)` — calling the result of a call | "make it parse" (14) | **parses** (15's R2) and **checks** (01 handover 15: inference types the `calleeExpr` and applies it). No backend reads `calleeExpr` yet — commonJS emits `(4)`, erlang `''(4)` — so `test/curried_call.bp` carries two `C-09 (backend half)` lines |
| `#(a: i32, b: string)[]` — an array of labeled tuples | "make it parse" (14) | **parses, checks and runs on all four targets** (15's R1), with `@Result<i32, string>[]` and `(i32 \| string)[]`. `test/type_suffix.bp` |
| `??` | "deliberately absent (14) — it duplicates `catch` and `?.`" | **parses and runs on all four targets** (15's R8, decision 28). The premise was false as well as the verdict: `catch` is `@Result`-only — `val b = a catch 0;` on an `a: ?i32` reds with `` `try` requires a @Result<D, E> value, found 'optional' `` — so nothing else gives an optional a default. `test/nullish_default.bp` |
| `xs[0]`, `xs[0..2]`, `d["k"]` — an index expression | "there is no index expression in the grammar" | **parses and checks** (15's R5, decision 30). **No backend lowers it**: the form reaches the unrecognised-builtin path, so `run/index_expression.bp` is listed against all four — and beam is the one that fails *silently*, exit 0 with the index dropped |
| a bodyless `fn` with `-> void` | "a bodyless top-level fn with no return type" — a form nobody wrote a rule for | **parses and runs** (15's R7, decision 33), and the missing return type is now its own named error, `bodyless-fn-needs-return-type`. `test/bodyless_fn.bp` and `reject/bodyless_fn_no_return_type.bp` |
| `(a == b).toString()`, and `(sql """ab""").length` — a method on a parenthesised expression | open / "needs a dependency to measure" | **one production, and it parses** (15's R3). `(1 == 2).toString()` prints `false` and `("ab").length` prints `2` on commonJS, erlang and wasm; no dependency is needed to measure it. `test/paren_receiver.bp` |

**Two commonJS defects these cells turned up that no step of `04-js`
(`specs/1.0.5-beta/04-js/README.md`) named.** Both were reported to the maintainer; front 04 owns
`commonJS.zig`, so the front was certain and only the row was missing. **The second is fixed** —
recounted at `b09bf9c6`: `test/nullish_default.bp` carries no line and the suite is green, so its
`04 (no step; reported 2026-09-18)` cell is gone from the file and only the first is still open.

1. **`42.toString()` — a method on a number literal** (15's R3) checks, and prints `42` on erlang and
   wasm, but the emitter writes `__bp_print(42.toString())` and node refuses it with
   `SyntaxError: Invalid or unexpected token`, because `42.` reads as a float. `(42).toString()` is
   the emitted form that would work. No cell asserts it — `test/paren_receiver.bp` records it in a
   comment instead, because a listed line needs a row.
2. **The optional-binding `if` tests `!== null`, and `?.` answers `undefined`.** `if (x) { n -> … }`
   emits `(() => { const n = …; if (n !== null) { … } })()`, so an absent value arriving from a `?.`
   chain takes the present branch and binds `undefined`. `o.inner?.v ?? 9` answers `undefined` on
   commonJS and `9` on erlang and wasm. `test/optional.bp` does not see it because its optionals are
   explicit `null`s. This one **was** asserted — `test/nullish_default.bp::?? chains after ?.` — with
   an owner cell that said outright that it had no step, and **it passes at `b09bf9c6`**: front 04
   fixed it and deleted the line. The paragraph is kept because the shape of the report is the thing
   worth copying, not because the defect survives.

**A third, with owners.** A tuple label does not survive a generic array method: `rs.at(0).b` on an
`rs: #(a: i32, b: string)[]` answers `undefined` on commonJS, raises `bad map: {1,<<"x">>}` in
`map_get/2` on erlang, and answers `0` on wasm. That is §6 T4 and the rows exist — `04 step 2`,
`02 step 4` — so `test/tuple_labels.bp` asserts it and carries the two lines.

**The range pattern in a `case` arm — decision 53 settled the spelling and `run/case_range_value.bp`
now pins the endpoints.** Decision 53 (2026-09-18) **amended** decisions 20 and 36 to Zig's split:
`...` is inclusive in a **pattern**, `..` is exclusive in a **slice** and in `for (a..b)`, and no
emitter moves. `zig version` 0.16.0 has both spellings in those two positions and `1..9` inside a
`switch` does not exist there at all, so the compiler was the Zig-consistent side all along.

- `1..9` in an arm still reds `error[pattern-range-exclusive]: \`..\` is iteration, not a pattern's
  range`, recommending `...`. Under decision 53 that recommendation is now **right** and it is the
  decision text that moved; `test/case_arms.bp` is still listed against `01 step 4`, because the
  parser has to accept `..` in the slice position it already refuses — verify before deleting.
- `1...9` parses, checks, and **is wrong on three of the four backends**. Re-measured at `b5a9b85d`
  with the endpoints, which is what `run/case_range_value.bp` prints:

  | `case n { 1...9 { 1 } _ { 0 } }` | n=5 | n=1 | n=9 | n=0 | n=10 |
  |---|---|---|---|---|---|
  | commonJS | 1 | 1 | 1 | 0 | 0 | ← correct |
  | erlang | 0 | 0 | 0 | 0 | 0 | ← the arm never matches |
  | wasm | 0 | 0 | 0 | 0 | 0 | ← the same |
  | beam | 1 | 1 | 1 | 1 | 1 | ← the arm always matches |

  **The single-value probe every earlier measurement used is misleading**: at `n=9` it reads
  `1 / 0 / 0 / 1`, which makes beam look right when its `1` is a false positive, and it was recorded
  as `1 / 0 / 256` with "beam emits only `out/main.S`" — neither the `256` nor the `.S`-only half
  reproduces at `b5a9b85d`. An endpoint probe is the minimum a range cell may print.
- Written where its type is known (`fn f(n: i32) -> i32 { return case n { 1...9 … } }`) the same
  `case` does not compile: `type mismatch: expected i32, got void`. A brace-arm of `case` is neither
  typed nor lowered — already filed with `01-checker` step 4, which owns pattern **grammar** as well
  as arm resolution (decision 36's ~10-line `parser/patterns.zig` `finishRangePattern` edit lands
  there too).

**Every per-cell measurement in this section and in the cells' own header comments was re-run after
merging `origin/feat` `3cfb65cb` and none of them moved**, the range table above included — so the
`b5a9b85d` dates in the cell comments are the measurement, not a stale one. In particular the `256`
heap address the range defect used to be recorded with does **not** reproduce on either commit: wasm
answers `0`, and it answers `0` at every endpoint.

**A `.out` may encode a decision no backend implements yet, and that is the point.**
`run/optional_null_pattern.bp` (decision 54) does. (The four decision-55 cells and the decision-52
cell that used to sit beside it were superseded by decision 105 — no loop has a value — and left with
front 22; `reject/loop_break_value.bp` and `reject/loop_yield_plain_fn.bp` are what the language says
now.) Each `.out` is the decision's answer, so when the backends are moved against it **exactly one
file per cell** is involved and no `.out` is renegotiated in the same commit as an emitter. Each
cell's header comment carries the per-backend measurement it was written against, dated and with
the commit.

**Never pin an erlang exit status or an `escript` warning as the point of a line.** `run.sh` runs
`botopink run --target erlang`, which today is `escript out/main.erl`: escript compiles the file it is
handed, prints its **compile warnings on stdout** — which the `.out` comparison sees — and answers
`127` when the program crashes. [Decision 56](../../../../specs/1.0.5-beta/decisions-taken.md) replaces that
with `erlc -o <out>` over every emitted `.erl` and then `erl -pa <out>`, in front 13's `cli/run.zig`:
the crash status becomes **`1`** and an `erlc` warning no longer reaches the program's stdout. So a
reason line may *quote* either as evidence, and four of this front's do, but the defect it names must
be the wrong answer. A front that fixes an erlang lowering and still sees a byte mismatch should check
which of the two moved.

**Read a collected result as `length` + `join(",")`, not as a printed array.** `@print` of an array
is decision 8 §7's separator row and erlang and wasm still get it wrong (`[20,40,60]` for
`[20, 40, 60]`), so a cell that prints the array carries a §7 line on two backends and the rule it
means to assert is hidden behind it.

**C-06's wasm half is verified by running, not by reading the diff.** `8594e4ba` landed
`.tasks/wasm` as-is — the `A...B` range-pattern arm and `emitRangeBound` in `wat.zig`, a value `break`
as `emitYield` then `br $__break`, six `loop_*` wasm snapshots' RUN LOGs moved (`[20]` where
`[20, 40, 60]` was), three expected-failure lines deleted — without its verification. C-16
compiled each of the six fixtures' `SOURCE CODE` as a fresh project, ran it with `botopink run
--target wasm` (wasmtime), and compared stdout with the snapshot's RUN LOG **byte for byte**: all six
match (`1 2 3 [20]`, `[15]`, `[0]`, `[250]`, `[115.0]`, `[20]`), and `run/case_range_value.bp` and
the three decision-55 cells (since deleted by front 22) passed on wasm in the suite, so the three
deleted lines stay deleted.
No defect was found and `wat.zig` was not touched. One note carried from the landing: a range pattern
over a **string** bound has no wasm ordering and answers `0` (`emitRangeBound`'s `else` arm) — no cell
asserts it, since decision 53 legislates numeric endpoints only.

**Decision 55 turned a cell that passed on all four backends into one that fails on all four.**
`test/loop_collection.bp`'s last test asserted `for ([1, 2, 3]) { x -> break x * 2; }` → `[2, 4, 6]`,
and every backend agreed, because they share one accumulator shape and none of them stops at a
`break`. Decision 55 says `break <value>` contributes its value **and ends the loop**, so the answer
is `[2]`; the assertion was rewritten to the language and now carries two lines. This is the rule at
the top of this file working in the direction it is usually not noticed in: four backends agreeing is
not evidence, and a decision can make a green cell red.

**Where front 02 has no row for the collection loop** — now moot: the rows are C-06's. Decision 55
says outright that the cell comes first and "then one row per backend against it". `04 step 3` and
`05 step 4` were both titled `break <value>` and `03 step 3`'s D7 asked for exactly this measurement;
front 02 had no §10 collection-loop step — its step 5 is the *condition* loop used as a value — so its
four lines read `02 (no step; decision 55, reported 2026-09-18)`, the shape the suite's list of
expected failures used for a certain front with a missing row. 1.0.10-beta gathered the three decisions into
`C-06`, and since 2026-09-20 every 52/53/55 line names `C-06 (<backend> half not landed)`; wasm's
half is the one that landed.

**Structural equality of two values of the same type is not legislated, so no cell asserts it.**
`Person(name: "Ana", age: 30) == Person(name: "Ana", age: 30)` answers `false` on commonJS (reference
equality on the class instance) and `true` on erlang and BEAM (one term, now a tagged tuple). No
decision of this milestone settles it and no front owns it, so `test/type_identity.bp` states the
omission in a comment and asserts only what **is** settled — that two *different* types with the same
fields are different values. Reported to the maintainer; a sentence would turn the comment into two
assertions.

**The identity is asserted on two backends and RUN on four.** `botopink test` refuses beam and wasm,
so a `test/` cell reaches only commonJS and erlang. `run/type_identity_equality.bp` is the same
statement as a `run/`: `Person(name: "a", age: 1) == Vec(name: "a", age: 1)` prints `false` on all
four since `13-module-identity` half 3 put the declaration inside the value — it answered `true` on
erlang and BEAM before, where two bare maps with the same keys were one term.

**`use` is tested from botopink since front 19 of 1.0.10-beta**, spelled to decisions 102/104
(front 21): `test/context_use.bp`, `run/context_use.bp` and the `reject/use_*.bp` cells declare
their own owner type (`type Element(…) implement @Context<Element>`), hooks as
`#[@use] fn … -> @Component<Element, T>` and components as `#[@use] fn … -> @Component<Element, Element>`, and
pin the binding of `T`, field and positional destructuring, a custom hook composing hooks, a bare
void `use`, an unannotated `fn … -> Element` as an ordinary function, the static prefix (rows 4b and
4c as parse errors), `use-without-context-effect` (a `-> Element` body without `#[@use]`, a plain
`-> string` body, a `#[@future]` body — `reject/use_future_without_owner.bp`, decisions 89/90
revoked — and a `use` in a nested closure, `reject/use_in_closure.bp`), `use-of-non-context-fn` (a
module-level `val`, decision 87) and `context-anchor-violation`. A component's caller awaits it:
`run/context_use.bp` drives the components from a `#[@future] fn run`, and the `test/` cells await
them (a `test` body is a future context). `test/use_future_context.bp` is the server component that
`use`s and `await`s under a `@Component` return. Front 24 (decision 118) deleted
`reject/use_future_context_duplicate.bp`, `reject/two_effect_markers.bp`,
`reject/wrapper_without_annotation.bp` and `reject/result_without_wrapper.bp` with the annotation
rules they pinned — a function has one return, so it has one effect.
`reject/use_tuple_arity.bp` and `reject/use_tuple_of_non_tuple.bp` are front 19 step 3's
`use-tuple-arity` refusals, located at the binding.

**Decisions 63–66, one cell or one sentence each (C-16).**

- **63** (an index is a method call, amended 2026-09-19) — `run/index_dict.bp` (present key → `1`;
  `Dict<string, ?i32>` → `null`; absent key → the program **fails**, `.exit` = `nonzero`),
  `run/index_past_the_end_fails.bp` (`xs[9]` fails after `10`) and `run/index_at_optional.bp`
  (`Dict.at` / `String.at` by name answer `?V`, `null` for absent). The first two are C-02 on all four
  backends — the compiler half is not landed: commonJS answers `undefined` even for the **present**
  dict key, erlang dies at the present key (`bp_unsupported_index`), wasm traps there, and `xs[9]` is
  `undefined` / `undefined` / `0` with exit 0. The third passes on commonJS (the `libs/std` half,
  `e065b564`) and is C-18 (decision 47's `null` spelling) on erlang, wasm and beam. Two more defects
  it turned up, reported rather than listed: `Array.at` past the end answers `undefined` on commonJS
  (decision 47, C-18 — kept out of the cell so it would not hide the rename), and `String.at` had **no
  wasm lowering** — `s.at(1)` trapped, exit 134. The second is **closed** (`fix/wasm-refusals`, front
  `05-wasm`): `$__str_at` lowers it, `run/string_at.bp` pins the present-index reader on all four
  targets, and wasm's `index_at_optional` line is now decision 47's spelling alone. The cell C-16 names as
  `index_an_index_past_the_end_answers_zero` is a `src/codegen/tests` fixture, not a cell of this suite;
  `run/index_past_the_end_fails.bp` is this suite's statement of the same rule, third spelling.
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

**Two step-4.3 measurements worth keeping.** `@panic` and `@todo` abort with stdout intact and a
non-zero status on all four backends (`run/panic_aborts.bp`, `run/todo_aborts.bp`, `.exit` =
`nonzero`), so both cells pass everywhere — but on beam `@todo` passes for the wrong reason: a
function whose whole body is `@todo()` is **not emitted**, and the abort is `{undef, main:notReady/0}`
rather than the builtin's. Same observable pair, different cause; reported, no row.

What cannot be tested from botopink at all, and why: `@typeInfo` / `@makeRecord` / `partial` / `omit`
/ `pick` (they produce types, and asserting on emitted text is the snapshots' job). Struck from this
list by C-16, each with the cell that covers it: `pub default mod` / `pub default fn`, `@ExprCustom` /
`q.custom` and `.d.bp` via `files` (`modules/local_dependency`, a local dependency needs no network);
"no external target for the active backend" (`run/external_erlang_only.bp`, a `run/` cell refused on
two targets through a `.<target>.expect` sidecar each — `botopink run --target <t>` is not
target-independent, which is what `reject/` lacked); `@panic` / `@todo` (`run/` compares stdout **and**
the status through `.exit`, so an aborting program is exactly what it can assert).
