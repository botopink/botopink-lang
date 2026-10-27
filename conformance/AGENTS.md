# conformance — botopink-lang's conformance suite (decisions 457, 464, 466, 475)

> Path: `conformance/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

The language's conformance cells: what any implementation of botopink must answer, written in
botopink, checked on every target by running the emitted program. Front 15 pinned decision 8
(`specs/08-review-backlog/decision-8-language.md` in the meta workspace): `case` and
patterns (§5), tuples and labels (§6), `loop` (§10), and the parts of `is` (§4), unions (§3),
`unknown` (§2) and printing (§7) those scenarios use. Front 17
(`specs/17-language-test-expansion/README.md`) added the rest of the language surface —
effects (§9), comptime parameters and templates, decorators and `@emit`, host externals (§8),
generics and `behavior` dispatch, optionals, closures, primitive methods, and modules. 1.0.10-beta's
C-16 (`specs/00-compiler-carry-over/README.md`) added front 12's steps 4.2–4.4 — a local
dependency, `@panic`/`@todo`, "no external target for the active backend" — and a cell per decision
63–66, plus the runner's tally (decision 59 (b)). Decision 466 put the suite here, in one cell shape (decisions 457, 475).

**Cells describe the language, not today's compiler.** A scenario the compiler gets wrong stays as
written and is red until the compiler passes it — the suite keeps no list of known failures
(§ A red cell is red). Never rewrite a cell's answer to match current behaviour.

## Layout

```text
conformance/
├── AGENTS.md                ← you are here
├── docs.md                  ← the language reference (decisions 461, 462): its index, the text no one cell owns, the manifest schema; every example a `<!-- example: … -->` line naming a cell or a suite
├── run.sh                   ← the runner: `zig build test-conformance`, the gate's stage 9
├── self-test/library_check/repository/ ← the library check's fixture for `run.sh --self-test` (decision 1004, its
│                              ledger proof): `good` answers, `hard` fails its program's build, `hangs` never ends,
│                              `broken`'s manifest is refused
├── lib/                     ← the shared library of the self-checking modules (decision 989): the sectioned `snapshot/main.snap`, the comparison, the `.new`; a path dependency of every module — see lib/README.md
├── modules/botopink.json    ← the root package (decisions 989, 990 (6), 1006 (1)): a workspace whose members are
│                              `*` and `decisions-taken/*` — the tree is the module list, a directory with a
│                              `botopink.json` is a member (a front-166 draft holds none and is skipped by its shape);
│                              `build` / `run --target <t>` there run one process per member (1006 (5)), one verdict
│                              per member (`ok   <m>` / `FAIL <m> — …`) and `modules: N checked — P passed, F failed`;
│                              the members' code cache and `.bpr` sets under `modules/.botopinkbuild/` (decision 225)
├── libraries/botopink.json  ← the library check's program (decisions 993, 995, 996, 1004): `run.sh` writes its
│                              `src/main.bp` per package of `botopink packages --list` (run from here: the checkout's
│                              walk-up) under `libraries/.run/` on every run, never committed — the package loaded by
│                              name, its tests run by ``m.`test`()`` —, and runs it per target as its own process
├── disabled.txt             ← decision 996's shrink-only list: one `<package> <target> — decision 996` line per
│                              pair that did not run when the libraries joined the suite (beam, wasm); a new line, a
│                              listed pair that passes or is now excluded, are reds; the list empty, the file goes
├── modules/consolidate-homes.txt ← the homes `scripts/consolidate-cells.py` reads before its own rule (decision 765 (2)):
│                              `<cell> <row> [also <row>,<row>]` per line, `outside` for a cell that proves no row it cites
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
| `modules/` (the root package, decisions 990 (6), 1006 (1)) | built once (a bare `botopink build` at the workspace root, one process per member) into each member's `.bpr` set, run on each target from `modules/` (`botopink run --target <t>`, one process per member, which reuses each set while its key is fresh — decisions 1006 (5), 1009) by `run.sh`; each member's verdict is that target's result for `modules/<m>`; a module on disk not in decision 989's shape is a red of its own (`*`) | every module `ok` on every target, the summary's count the lines' |
| `modules/<module>/` (self-checking, decision 989) | a module that checks itself in process, `modules/array` first: `botopink.json` (a path dependency on `lib/`), `src/main.bp` — `pub async fn main() -> Async<Result<void, string>>` whose `runCase(comptime name)` loads `cases/<name>` at build, runs it and turns its answer into records —, `cases/<case>/` a package each (`botopink.json`, `src/main.bp` with `pub fn main`, `docs.md`), and one `snapshot/main.snap`: `botopink-cell 2`, a `== <case>` section per case, a departure as `== <case> on <t>`; a difference writes `snapshot/main.snap.new` through `io.fs` on every target (decision 992) and `main` answers `Error`; run by the root package, or alone by `botopink run --target <t>` in the module's directory (lib/README.md) | `main` answers `Ok` on every target |
| `modules/<module>/run/`, `modules/<module>/refused/` | the old shape, converted by 990 (6)'s codemod and no longer checked by any command (`cell check` left the CLI): a case still in it is held to `conformance/leftover-cases.txt` (decision 1011), and a module's roster red names any case not on the list. A module's two packages of cases (decision 779): `src/cases/<case>/mod.bp` per case (its entry `pub fn runCase()` in `run/`), `src/main.bp` calling the cases of `run/` in `src/cases/mod.bp`'s order and reaching none in `refused/`; `run/`'s answer is one `snapshot/output/main.snap`, the cases' `out` lines in call order, `refused/`'s each case's own `snapshot/output/cases/<case>/mod.snap`; the module holds a `docs.md` linking every case and no `src/`; `scripts/pack-cells.py apply <module>` packs a module's 765 `cases/` (a case packs only when its package's check equals its old answers); | — |
| `modules/<module>/cells/<case>/` | the old shape's full cell (the shape below) for a case that cannot share a package — an abort, a narrowed `"targets"`, a dependency, a departure, an asset, a lone case (decision 779); the cells' residue is converted last (990 (6)) | — |
| `libraries/<name>` (decisions 993, 996, 1004) | every name `botopink packages --list` prints, one job per target: the program `libraries/botopink.json` with a `src/main.bp` loading the package by name and running ``m.`test`()``, `botopink run --target <t>` as its own process under `--lib-timeout` (900 s) — a load that fails the build, a crash or a hang is that pair's red alone; `not-a-package` is that verdict, never loaded; a `disabled.txt` pair that fails is `disabled`, printed with the count `N disabled (shrink-only, decision 996)` | every test `ok`, or no test (`no tests`), or `.Excluded` by a `"targets"` the compiler proves (`excluded`) |
| `test/<area>_<group>.bp` | `test "…" { … assert … }` blocks, run by `botopink test --target <t> --json` in a scratch project on commonJS, erlang, wasm and beam (a single file declares no narrowing, decision 536: a suite that narrows its targets is a project suite below) | every test reports `ok` |
| `test/<project>/` | a whole project with a `test/` tree, run by `botopink test --target <t> --json`; results keyed `test/<project>::<test>`; `"targets"` in its `botopink.json` narrows it (§ Narrowing a cell) | every test reports `ok` |

A cell's `.snap` (decision 475 (2); `lib/src/records.bp` holds the records, read in the sectioned `botopink-cell 2` file): `botopink-cell 1`, then
`refused <the compiler's error… line>` / `at <file>:<line>:<col>` / `label <text>` / `from <file>:<line>:<col>` (decision 485: the text the
compiler prints beside the caret, as printed — absent when the caret has none, refused in an output file;
the `hint` lines are not claimed; decision 532: a `from` per `called from` line of a raise at build, innermost first) for a refused module, or `out <line>`
(`out` alone for an empty line), `no-final-newline`, `abort` (the exit status never pinned) and
`stderr <text>` (with `abort`: the stderr contains the text). A refusal is filed under the module its
location names (`src/shapes/circle.bp` → `shapes/circle.snap`; `botopink.json:1:3` →
`botopink.json.snap`; a std module's location → `std/io/fs.snap`); an unlocated one is `main`'s.
A departure replaces the module's whole answer on that target (475 (3)).

**What a cell's answer is made of.** One record per claim, in `snapshot/output/<module>.snap` (every target) and
`snapshot/targets/<t>/<module>.snap` (a departure): the program's `out` lines (`no-final-newline` when its
output did not end in `\n`), `abort` when it exits nonzero, `stderr <line 1>` for what it writes to stderr
(in `output/` when the targets that claim it outnumber those that do not, else a departure), and for a
refusal `refused <the whole error… line>` / `at src/main.bp:<L:C>`. A cell's `"targets"` is its manifest's.
A `refused` record holds the compiler's whole `error…` line, a loaded case's `Diagnostic`. Single-file
cells are packages named after the cell. **A cell's package name is its directory's name** (decision 511; a workspace
member's `name` is required and unique, 512 (1)).
Throughout this file, `modules/<n>` is a cell and `test/<n>` a suite; a sentence about "the parent binary"
names the compiler a cell was first red on.

1.0.10-beta's `00 · 23-std-purity` step 1 (decision 107, the import tree) adds `modules/decisions-taken/import_dotted_and_braced_paths_one_tree-107/cases/import_tree`
— a dotted path and a braced group over the package's own tree and over std, aliases bound, only the
leaves in scope, on commonJS/erlang/wasm — and three refusal cells: `import_name_collision` (the
second item) and `import_group_modifier` (`*` on a node that opens braces); the third,
`import_alias_on_type`, is now `modules/decisions-taken/import_alias_on_type_and_folder_namespace-110/cases/import_alias_on_type` — decision 110 made `as` legal on a type
and a type alias (`01-checker`), and the cell imports `Point as P`, `Pair as Two` and std's
`Dict as D` and runs on all four targets; `modules/decisions-taken/import_dotted_and_braced_paths_one_tree-107/cases/import_alias_fn_value_beside_local` an aliased import's function value beside a local
function of the leaf's name (wasm read the bare name, the local one, until front 140's thread resolved
the alias to the owner's mangled declaration); `modules/decisions-taken/import_alias_on_type_and_folder_namespace-110/cases/import_alias_static_call` covers the alias in
expression position — an associated call (`P.origin()`) and a unit and a payload variant (`S.Dark`,
`S.Custom(9)`) — which inference renames to the declared type for the backends.
Step 6 (decision 110 rule 2, 111 through the namespace) adds `modules/decisions-taken/import_alias_on_type_and_folder_namespace-110/cases/import_std_folder_namespace`
— the leaf `io.clock as clock` and `clock.nowMillis()` (`import {io}` is refused, decision 919: `modules/decisions-taken/folder_import_refused-919`), on
commonJS, erlang and beam, refused on wasm by STD-001 (`snapshot/targets/wasm/`) as the leaf form is — and
`modules/decisions-taken/collections_constructors_type_scoped-111/cases/import_std_type_through_module` — `collections.Dict.empty()`, `collections.Set.fromList`,
`collections.Queue.fromList` after `import {collections}`, beside `collections.lt()` and an alias
`D`, on all four targets.
`00 · 01-checker` step 8 R2 adds `modules/import/cases/import_type_closure` — `import { User, makeUser }` where
`User(role: Role)`, `Role` not named, on commonJS/erlang.
Front 24's type aliases (decision 118 rule 1) add `modules/decisions-taken/body_marker_whole_return_type-553/cases/type_alias` — `Id`, `Pair<A, B>`, `Ids` and
an `@Result` alias typing a function that only passes the value along, on all four targets — and
`modules/import/cases/import_type_alias` — a `pub` alias imported like a type, the types its target names with it.
Decision 137 (`try` / `await` begin an expression) added `modules/try/cases/try_start_positions` — a `val`
initializer, a call argument, an array and a tuple element, an `if` condition, a `case` subject, a
`for` iterable, `x = …`, a `return` and `try … catch` in an argument, on all four targets — and three refusal cells, one per operand
shape; decision 537 withdrew the refusal (`try` and `await` are prefix operators binding as the unary `-` does, `catch`
an infix operator of the lowest precedence) and those three became `modules/decisions-taken/await_try_prefix_catch_infix-537/cells/try_await_prefix_operators` (`total + try r`,
`try r + 1`, `-try r`, `(try r).toString()`, `await t * 2`, `await x + await y`, `!await ready()`),
`modules/decisions-taken/await_try_prefix_catch_infix-537/cells/await_postfix_binds_tighter` (`await box.task`, `await make(3)`, `await box.again()` — postfix binds tighter)
and `modules/decisions-taken/await_try_prefix_catch_infix-537/cells/catch_lowest_precedence` (`try await t catch 7 * 2`, `(try await t catch 7) * 2`, 523's
`async { (try await t catch 0) * 2 }`).
`residual-checker-3` reads decision 137 onto `if`: an `if` expression is never an operand, and
three refusal cells refuse it as `if-operand` at the `if` — `if_operand_of_operator`
(`1 + if (c) { 2 } else { 3 }`), `if_in_parentheses` (`(if (c) a else b).v`) and
`if_operand_of_unary` (`-if (c) 1 else 2`). The same front adds `modules/narrow/cases/narrow_in_logical_operands`
(the right operand of `&&` / `||` and a `while` body read the names the left operand's null test
narrows; a narrowed `var` is assigned its declared type, on all four targets) with
`modules/narrow/cases/narrow_or_keeps_optional` and `modules/narrow/cases/narrow_ends_at_assignment`, and two cells whose
checker half was right first and whose backend halves `residual-backend-3` closed: `modules/imported/cases/imported_fn_as_value` (an imported `pub fn` bound by a `val` and
passed as an argument) and `modules/enum/cases/enum_implements_behavior` (an enum's behavior method called
through a behavior-typed parameter). C-04's last call path adds `modules/associated/cases/associated_fn_default` (a
behavior's associated fn filled and reordered by label, generic included) and
`modules/associated/cases/associated_fn_missing_required`; decision 31 (`any` deleted) adds `modules/decisions-taken/any_type_absent-31/cases/any_type_removed`
and `modules/decisions-taken/any_type_absent-31/cases/host_unknown_parameter` (`std/erlang`'s host vocabulary typed `unknown` takes an `i32`,
erlang and beam); C-21 adds `modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_argument_kind` (the one decorator refusal that had no
location), and the runner now requires every refusal cell's `main.snap` to carry its `<L:C>` line —
every refusal is located.
Decision 138 (the empty record is `type Name()`) adds `modules/decisions-taken/empty_record_written_with_parens-138/cases/type_empty_record` — `type Marker()` and
`type MathOps() { … }` constructed and called on all four targets — and two refusal cells,
`type_empty_braces` (`type Marker {}`), `type-without-field-list` where the `()` belongs.
Decision 329 (a namespace type) made `type MathOps { fn … }` legal when no function takes `self`:
`modules/decisions-taken/namespace_type_without_fields-329/cases/namespace_type` (associated functions, a generic one, one calling another, through the type, on
all four targets), `modules/decisions-taken/namespace_type_without_fields-329/cases/namespace_type_self` (the old `type_without_field_list` cell: a `self`
function, refused `namespace-type-self` at the `self`) and `modules/decisions-taken/namespace_type_without_fields-329/cases/namespace_type_construction`
(`MathOps()` refused `namespace-type-construction` at the call); the three were refused
`type-without-field-list` by the parent binary.
Decision 307 (a derived type, `01-checker` step 28) adds `modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_functions` (`Type.pick`,
`omit`, `partial`, `required` and `merge`, chained and nested, each constructed, read, passed as a
parameter, told apart from its source by `is` and printed by its own name, on all four targets),
`modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_decorated` (a decorator on the `val` sees a type whose fields keep the source's
annotations, `partial`'s typed `?T`) and `modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_imported` (an exported
`Type.merge` as a parameter type and a constructor, a module deriving from an imported record and
from an imported derived type), with eleven `modules/derived/{run,refused}/src/cases/derived_type_*` and `modules/derived/cells/derived_type_*` cells — a string field, an
unknown field, a field named twice, no field, an `omit` leaving none, an enum and a primitive
source, a field on both sides of a `merge`, the call in a body, a `var`, and the bare `partial(…)`
(an unbound name); every one red on the parent binary.
Decision 529 (2) (a record parameter `..props: R`) adds `modules/decisions-taken/component_props_plain_or_rest-529/cases/record_param` (a component-like function with
`..props: R` beside another parameter, called by label, by position for the other parameter and by a spread of the
record's own type and of a `Type.pick` type, a default left out; the same answer on commonJS, erlang, beam and wasm), `record_param_across_modules` (declared in one module, called from another)
and seven refusals, each at the declaration or the call that breaks one rule: `record_param_twice` (a second
record parameter), `record_param_not_record` (an enum as `R`), `record_param_clash` (a parameter named as a
field), `record_param_variadic` (beside a variadic), `record_param_default` (a default, a parse error at the `=`),
`record_param_unknown_label` (a label that is no parameter and no field), `record_param_spread_other_type` (a
spread of another record's value, `record-spread-type`); a spread into a function of plain parameters is
`call_spread`'s.

Decision 506 (1) (a CLI's host primitives, 144 B-27 step 6) adds five cells on commonJS, erlang and beam (the wasm audit refuses them on
their host bindings): `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_stdin_eof` (`readLine()` / `readChunk()` answer `null` at the end of input, repeatedly, and `isTTY()` is
`false` — a cell's standard input is `/dev/null`), `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_terminal_not_a_tty` (`stdoutIsTTY()` `false`, `size()` `null`,
`setRaw` `NotATerminal`, `keys()` ending at once), `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_signal_handlers` (`onSignal` for `Term`, `Hup` and `Winch`, two
handlers on one signal in order), `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_process_spawn` (`spawn`'s `NotFound` and `PermissionDenied`, `Child.wait()` — a status, `128 + n` for a signal, repeatable —
and `kill`, `NoSuchProcess` after the end) and `modules/decisions-taken/std_cli_host_primitives-506/cells/std_io_process_forward_signals` (the parent's `SIGTERM` reaches a child that prints
when it gets it, asserted by the child's line in the output). A cell has no terminal and no input; what needs one (the lines of a piped
input, a terminal's size, raw mode, the keys) was run by hand under a pty and a pipe on the three targets.

Decision 359 (a spread copies a record's fields, 144 B-14) adds `modules/decisions-taken/record_spread_copies_fields-359/cases/record_spread` (`..src` beside
labels, several spreads left to right with the later winning, a `Type.pick` / `omit` / `merge` source, a
field left to its default, a call as the source evaluated once, a trailing comma, a generic record — four
targets, the source printed unchanged) and four refusals: `record_spread_other_type` (a record of the
same fields, `record-spread-type` at the `...`), `record_spread_partial` (a `Type.partial` value,
`record-spread-partial` at the `...`), `record_spread_missing_field` (a field nothing supplies,
`record-spread-missing-field` at the call) and `call_spread` (a function call, `call-spread` at the
`...`); every one red on the parent binary, where `...` at an argument's start did not parse.
`modules/decisions-taken/record_spread_copies_fields-359/cases/record_spread_import_alias` follows an import alias: a source typed `C` (`pessoas.Contato as C`), a
type derived here from an aliased record (`Type.pick(P, .nome)`) or an aliased derived type spread into
`Pessoa` and `Contato` and through their aliases, on the four targets — red on the parent, whose lineage
held the alias's name.
Its Conformance step adds `modules/decisions-taken/record_spread_copies_fields-359/cases/record_spread_across_modules` (types derived in one module from another's
record, and from an imported derived type, spread in each), `record_spread_nested` (a spread as a field's value,
as a spread's source, an array element, a lambda's and a function's result; a field path as the source),
`record_spread_call_source` (a method call, an associated function's call, a chained call, a call answering a
derived type — each evaluated once), `record_spread_evaluation_order` (a source before the labelled values,
question B-14-b as built; an overridden labelled value still evaluated), `record_spread_beside_record_update`
(`..base` written in both orders, question B-14-a as built) and the refusals `record_spread_optional`
(`?Pessoa`), `record_spread_derived_partial` and `record_spread_required` (question B-14-c as built),
`record_spread_label_twice`, `record_spread_positional_argument` and `record_spread_overridden_label_type`
(an overridden label's value is typed) — each red on B-14's base, where `...` at an argument's start did not
parse; `record_spread_nested`, `record_spread_evaluation_order`, `record_spread_optional` and
`record_spread_overridden_label_type` red on `feat` too, until the fix beside them (an untyped lambda
parameter as the source, an overridden labelled value dropped unevaluated and untyped, `optional` named for
`?Pessoa`).
Decision 305 (an annotation speaks botopink, 144 B-02) adds `modules/decisions-taken/compiler_annotation_labelled_arguments-305/cases/annotation_label_equals` (`keyed = true`
on `beamMemory(.Ets)`, `annotation-label-equals` at the label, naming `keyed:`), `modules/decisions-taken/compiler_annotation_labelled_arguments-305/cases/external_fn_unbound`
(a misspelt `fn: <name>` is the unbound-name error at the argument) and `modules/decisions-taken/compiler_annotation_labelled_arguments-305/cases/external_prefixed_fn_refused`
(`.JavaScript("fn:mixBody")` refused, naming `fn: mixBody`); its Conformance step adds
`modules/decisions-taken/compiler_annotation_labelled_arguments-305/cases/annotation_label_equals_decorator` (the same refusal on a decorator's `at = .confirm`),
`modules/decisions-taken/compiler_annotation_labelled_arguments-305/cases/external_erlang_prefixed_fn_refused` (`.Erlang("fn:mixBody")`, the cell the erlang and beam
targets read) and `modules/decisions-taken/external_wasm_labelled_cells-481/cases/external_node_prefixed_op_refused` (`.JavaScript("op:f64.floor")` names the wasm
cell `#[@external(.Wasm(op: "f64.floor"))]`) — each red on B-02's parent, which ran the `=` label's program,
refused `fn: mixBody` beside the prefixed string and passed `"op:f64.floor"` to node as host code.
Decision 316 (`decl.wrapWith`, 144 B-11) added `modules/decisions-taken/compiler_wrap_with_removed-714/cases/decorator_any_params_outside_decl`; its wrapper cells went with
`wrapWith` (decision 714).
Decision 302 (a tag is a declaration handle, 144 B-15) adds `modules/decisions-taken/tag_annotation_is_decorator-302/cases/tag_decl_meta`, `tag_annotation_add_member`,
`tag_annotation_meta_twice` and `type_named_like_decl_kind`; its Conformance step adds `modules/decisions-taken/tag_annotation_is_decorator-302/cases/tag_decl_meta_read`
(`compiler.meta(d, T)` read back, `compiler.attr(d, name)` absent and `compiler.component(d)` on an element `null`, four targets),
`tag_annotation_add_type` (`tag-annotation-output`), `tag_annotation_unknown_name`
and `tag_annotation_not_decorator` (no decorator named, at the annotation) and `tag_annotation_reads_meta`
(`compiler.meta(decl, T)` in an annotation, question B-15-c as built) — each red on B-15's parent, which had no `compiler.tagDecl`.
Decisions 311 (3), 415 and 426 (templates, 144 B-18) add `modules/decisions-taken/query_template_assembled_at_build-415/cases/template_method_call`, the `template_lookup_*`
cells and the `template_call_*` / `template_build_outside_bound` / `template_note_on_mismatch` cells; its
Conformance step adds `modules/decisions-taken/query_template_assembled_at_build-415/cases/template_lookup_decl_members` (`variants`, `methods`, `params` of a looked-up
declaration),
`template_bindings_decls` and `decorator_decl_module` (`compiler.bindings(q)` as declaration handles, `compiler.moduleOf(decl)` on a decorator's own
handle, question B-18-b as built), `template_method_own_method` (the receiver type's own method of the name wins —
red on `feat` too, `template-call-unexpanded`, until the fix beside it), `template_method_receiver_mismatch` and
`template_method_not_in_scope` (question B-18-a as built) — each red on B-18's parent.
The cells those three Conformance steps proposed: `tag_annotation_emit` (`@emit` in a tag's annotation, `tag-annotation-output`) and
`template_method_behavior_method` (a method the receiver's type adopts from a behavior, its `default fn` included,
and a behavior-typed receiver's method, win over a template method of the name — red on `feat` too, until the fix
beside it).
`modules/decisions-taken/derived_type_static_methods-307/cases/derived_type_two_packages` derives over two packages' same-named modules: dependencies `a`
and `b` each hold `shape` with a record `Box` of different fields, each package's `user` derives
from its own `Box` (`Type.pick` in `a`, `Type.omit` in `b`) and the project has a `shape` of its
own — the imported source is found by its module's key (the package plus the path, decisions 170
and 337), four targets; read by basename, `b`'s `omit(Box, .depth)` met `a`'s `Box` (`unknown field
'depth'`).
Decision 330 (7) (a type in a type is its associated type) adds `modules/decisions-taken/optional_typescript_operators-330/cases/assoc_type_declared_in_body` (a
sibling's `Shape` declares `Point` with a method, the enum `Kind` and the generic `Box<T>` in its body;
`main` constructs, annotates, matches and prints them through `Shape.`, four targets),
`modules/decisions-taken/optional_typescript_operators-330/cases/std_type_field_associated` (std's `Type.Field<T>` as a parameter type after `import {types.Type}
from "std"`, four targets) and `modules/decisions-taken/optional_typescript_operators-330/cases/assoc_type_named_like_member` (`pub type Point` beside `pub fn
Point`, `assoc-type-duplicate` at the type's name); the three were parse errors or `unknown type` on the
parent binary.
Decision 330 (`?T` read with TypeScript's operators, `01-checker` step 31) adds `modules/decisions-taken/optional_typescript_operators-330/cases/optional_operators`
(`?.[i]`, `?.` flattened, the postfix `!` over a present value, four targets),
`modules/decisions-taken/optional_typescript_operators-330/cases/optional_call_operator` (`f?.(args)`, four targets) and `modules/decisions-taken/optional_typescript_operators-330/cases/optional_bang_aborts`
(`find("b")!` aborts after `found` is printed, its stderr naming `value is null — find("b")! at
src/main.bp:11:12` on the four targets — the panic text decision 430 prints alike), and six refusal cells: `optional_operator_never_null` (`s?.length()`
with `s: string`), `nullish_never_null` (`s ?? "fallback"`), `bang_never_null` (`n!`) — each
`optional-operator-never-null` at the operator —, `nullish_beside_logical` (`flag ?? false && true`,
at the `??`), `optional_has_no_methods` (`.unwrapOr` on a `?string`) and `result_namespace_removed`
(`result.isOk(…)` is an unbound `result`). `modules/option/cases/option_expect_removed` now answers
`optional-has-no-methods`. Every one was refused or accepted otherwise by the parent binary. The
suite's `.unwrapOr` on a `?T` became `??` (`scripts/codemod-optional-operators.py`), and a second
index of an index (`rows[1][0]`, `xs[k]` answering `?T`) is `rows[1]?.[0]` (`modules/decisions-taken/record_field_assignment_refused-37/cases/index_expression`,
`modules/array/cases/array_windows`). A method after a `?.` link continues its chain (`e?.key.length()`,
`modules/optional/cases/optional_chain_method`): the chain runs under the `?.`'s guard.
`modules/decisions-taken/optional_typescript_operators-330/cases/optional_method_absent_receiver` — `recv?.m(args)` with the optional itself as the receiver (a
local, a call, an array element; `length`, `toUpper`, `contains`, `slice`), absent and present, four
targets (erlang raised `bp_unsupported_method`, beam `unresolved_method`, wasm read a length off address
0, and commonJS called `contains` on a string, on the parent binary).
`modules/decisions-taken/optional_typescript_operators-330/cases/optional_call_plain_answers` — `f?.(args)` over a `?fn(…) -> T` answering an integer (a present
`0` included), a string, a bool and a record, four targets (wasm refused a link answering a plain value on
the parent binary).
`modules/decisions-taken/optional_typescript_operators-330/cases/optional_float_function_value` — a function taking or answering an `f64` / `i64` bound out of a
`?fn(…)`, called through `?.()`, held by a typed local and named as a top-level function, four targets
(wasm refused the float argument as a narrowing to `i32` on the parent binary).
`modules/decisions-taken/optional_typescript_operators-330/cases/optional_if_null_initializer` — an `if` with a `null` arm into a `?T` `val`, `var` and `return`,
an `else if` chain and a `?f64`, four targets (wasm read an absent value as a present `0` on the parent
binary).
`modules/decisions-taken/optional_typescript_operators-330/cases/nullish_default_namespace_call` — `a ?? ns.f()` with a std module's and a package module's
namespace call as the default, four targets.
144 B-20's Conformance step adds `modules/decisions-taken/optional_typescript_operators-330/cases/optional_record_method_absent_receiver` — `recv?.m()` over a
record's methods (answering an `i32`, an `f64`, a `bool`, a `?i32`, a record) and an all-unit enum's, absent
and present, four targets (on the parent binary wasm ran the method on address `0`, read a present `0` as
absent and refused the all-unit enum's dispatch; erlang and beam failed the absent receiver) —,
`modules/decisions-taken/optional_typescript_operators-330/cases/optional_enum_method_absent_receiver` — `x?.m()` over an absent payload enum, and a method
continuing it (`find(0)?.str().length()`), four targets (commonJS read `.length` off `undefined` and wasm's
dispatcher trapped on `feat`; all four failed on the parent binary) —, `modules/decisions-taken/optional_typescript_operators-330/cases/nullish_optional_call_default`
(`a ?? f?.(x) ?? d`, the defaults run only when what precedes them is absent; wasm refused the `?.()` default
on the parent binary) and two pins that held on the parent binary: `modules/decisions-taken/optional_typescript_operators-330/cases/optional_chain_record_fields`
(`?.` along optional record fields, a member and a method after a link) and `modules/decisions-taken/optional_typescript_operators-330/cases/optional_bang_in_lambda`
(`x!` in a lambda's body, its abort naming the expression inside the lambda).
144 B-22 adds `modules/fn/cases/fn_empty_main` (`pub fn main() -> void {}` builds and prints nothing) and
`modules/fn/cases/fn_empty_body_call` (a `fn` written `{}` called between two prints), four targets (wasm took an
empty body for a bodyless `declare fn` on the parent binary: no `main` emitted, `compilation failed
UndefinedCall`, and the call refused).
144 B-22 adds `modules/decisions-taken/optional_typescript_operators-330/cases/optional_chain_field_after_call` — a field read after a `?.` method link and
after a `?.` field link, and a method after the read, present and absent, four targets (refused as a
member read off an optional on the parent binary).
`modules/decisions-taken/optional_typescript_operators-330/cases/optional_member_default` — `xs.at(k)?.field ?? d` over a present and an absent element, a string
field, an empty array, an array built by `map` and one passed in, four targets (wasm printed the
element's address for the `map`-built array on the parent binary).
Decision 267 (a variadic parameter `..name: T[]`, front 134 step 4) adds `modules/decisions-taken/variadic_last_parameter-267/cases/variadic_parameter` (a free
function with zero, one and three variadic arguments, a generic one, a method, an associated function, `@print`
with two arguments — four targets), `modules/decisions-taken/variadic_last_parameter-267/cells/variadic_parameter_host` (a `declare fn` bound to `Math.max` /
`lists:max`; wasm refuses it at the first call by `snapshot/targets/wasm/`), `modules/decisions-taken/variadic_last_parameter-267/cases/variadic_across_modules` (an
imported variadic `pub fn`, four targets) and six refusal cells: `variadic_not_last`, `variadic_twice`,
`variadic_default`, `variadic_not_array` (parse refusals at the declaration), `variadic_spread_at_call`
(`variadic-spread`) and `variadic_label` (`variadic-label`). Every one was
refused or accepted otherwise by the parent binary. Decision 354 (step 6, contexts — it replaced 269's
`@getContext(T)`, whose `getcontext_without_use` refusal cell left) adds `modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_provide_read` (a provider
reaches a component two renders below it; a `@Component` read with `use` reads its caller's map; a body
does not see its own provide), `modules/decisions-taken/context_named_by_value_type-379/cases/context_nearest_wins` (the nearest provider wins, a sibling does not
see another's) and `modules/context_unbound` (`context-unbound` at run time, `abort` nonzero and the
message on stderr) — erlang, beam and commonJS run them, the wasm backend refuses the `use` where it is
written (`snapshot/targets/wasm/`, `language-gaps.md`); and the refusals `modules/decisions-taken/component_wrapper_and_contexts-354/cases/component_base_parameter`
(`@Component<C, R>` at the base), `modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_marker_removed`, `modules/decisions-taken/component_wrapper_and_contexts-354/cases/renderable_type_argument`,
`modules/decisions-taken/context_named_by_value_type-379/cases/getcontext_removed`, `modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_provide_in_hook`, `modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_provide_after_render`,
`modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_hook_without_use`, `modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_hook_as_value`, `modules/context_not_declared`,
`modules/decisions-taken/context_named_by_value_type-379/cases/context_val_alias`, `modules/decisions-taken/context_provide_made_in_body-723/cases/context_read_of_parameter`, `modules/decisions-taken/component_wrapper_and_contexts-354/cases/use_in_comptime_block`,
`modules/decisions-taken/component_wrapper_and_contexts-354/cases/use_in_decorator_body` and `modules/decisions-taken/component_wrapper_and_contexts-354/cases/use_in_template_body` (`use-outside-render-tree`), each red on
the parent binary. Decision 354 took the base out of the wrapper, so the cells `component_two_bases`,
`use_two_bases`, `use_owner_mismatch` (decision 96's one base per body), `component_one_type_argument` and
`context_two_type_arguments` left with it.
Decisions 352 and 354, as `styled` registers through them (`08-bpp/119` step 1), add
`modules/decisions-taken/component_wrapper_and_contexts-354/cases/context_sheet_registers` — a context whose value holds a writer function, provided at the root; a
component computed at render reads it at its body's top and hands the writer its rule each time it
runs; a component run through a function value under a provider that keeps nothing registers nothing,
one that reads no context registers nothing — and `modules/context_sheet_unbound` (`context-unbound`
naming the context, `abort` and the three `stderr` lines); erlang, beam and commonJS run them, wasm refuses
the first `use` (`snapshot/targets/wasm/`).
Decisions 378 and 379 (a context is named by its value's type and declares its default; 144 B-17) removed
`context_unbound`, `context_not_declared` and `context_sheet_unbound` (no read is unbound) and added
`modules/decisions-taken/context_named_by_value_type-379/cases/context_default`, `modules/decisions-taken/context_read_by_value-722/cases/context_default_imported` and
`modules/decisions-taken/context_named_by_value_type-379/cases/context_declared_twice`; decision 416 (dependency injection) added `modules/decisions-taken/inject_rides_context_tree-416/cells/inject_record`,
`modules/decisions-taken/inject_rides_context_tree-416/cells/inject_behavior_keyed`, `modules/decisions-taken/inject_rides_context_tree-416/cases/inject_test_root_fake`, `modules/decisions-taken/inject_rides_context_tree-416/cases/inject_field_undeclared`,
`modules/decisions-taken/inject_rides_context_tree-416/cases/inject_behavior` and `modules/decisions-taken/inject_rides_context_tree-416/cases/context_behavior_not_implemented`. B-17's Conformance step adds
`modules/decisions-taken/context_named_by_value_type-379/cases/context_declared_twice_across_modules` (the second declaration in another module, refused in it naming
the first), `modules/decisions-taken/context_named_by_value_type-379/cases/context_enum_default` (`comptime createContext(Mode.Light)` — the comptime lift wrote no
enum value in a record's field, `comptime-value-not-liftable`), `modules/comptime/cases/comptime_enum_in_record` (the same lift
in a record and a generic record), `modules/decisions-taken/inject_rides_context_tree-416/cases/inject_default_imported` (an `inject` field's default declared in its
type's own module) and `modules/decisions-taken/inject_rides_context_tree-416/cases/inject_not_record_enum` (`inject-not-record` for an enum); the first two and the
last two red on the parent, where std's `context` had no `createContext` or `inject`, `comptime_enum_in_record`
red on the group's tip.
Decisions 722 and 723 (a context is read through a context value the reader imports, matched to the provider by
the context's type; `use provide(ctx)` alone) rewrote every `use context(<Type>)` as `use context(<its context
value>)`, removed `context_undeclared_type` and `context_behavior_undeclared` (a read names a value, which always
carries its default) and added `modules/decisions-taken/context_provide_made_in_body-723/cells/context_read_by_value` (an imported handle: its default, then a provided
context of its type), `modules/decisions-taken/context_provide_made_in_body-723/cases/context_provide_made_in_body` (`val c = comptime createContext(…)` then `use
provide(c)`) and `modules/decisions-taken/context_read_by_value-722/cases/context_read_by_type_refused` (`context-read-by-type` at the argument), red on the parent.
Decision 388 (a `@Component` is a lambda over a `RenderScope`, `01-compiler/134` step 6 box 4b) replaced
374's capture: the cell `context_host_thunk` left with it, and `modules/decisions-taken/component_is_lambda_over_render_scope-388/cases/render_scope_library` holds the scope in
the library instead — a renderer that runs the root with `RenderScope.root()` and each child with the
scope its parent's `run` answered, hands a host a thunk `{ -> c.run(scope) }` at once and keeps one the
host runs twice after the render. `modules/decisions-taken/component_is_lambda_over_render_scope-388/cases/component_is_lambda` (a call runs nothing; `itens.map(Card)`
answers lambdas a tree's runner runs with `Lista`'s scope; generic code keeps them), `modules/decisions-taken/component_is_lambda_over_render_scope-388/cells/component_run_root`
(`c.run(scope)` answers the result and the children's scope; `await c` outside every body runs it with
`RenderScope.root()`), `modules/decisions-taken/component_is_lambda_over_render_scope-388/cells/component_try_in_body` (a bare `try` in a `@Component<@Result<…>>` body),
`modules/decisions-taken/body_marker_whole_return_type-553/cases/component_alias_answers_value` (a function typed by an alias of `@Component` is no component body, 118:
it answers the lambda another body made — `styled`'s `-> StyledView`) and
`modules/decisions-taken/component_is_lambda_over_render_scope-388/cases/render_scope_construction` (`RenderScope(…)` refused, `render-scope-construction`) cover the rest;
all four targets run them (on wasm since decision 504: the scope's values typed by the checker's type the lowering
carries; `decl_hooks_direct` and `render_scope_library` are narrowed to commonJS, erlang and beam, their hosts having
no wasm binding), and `modules/decisions-taken/components_compose_by_data-504/cases/component_awaits_host_task` pins 504's rule (a component awaiting a host `delay` is a
state machine, a sibling that awaits nothing stays direct; red on the parent, whose wasm refused every component),
`modules/decisions-taken/components_compose_by_data-504/cases/component_try_then_awaits_host_task` the same through a bare `try` (the tail the lowering runs as an inner
closure waits on the host too; wasm trapped) and `modules/decisions-taken/component_is_lambda_over_render_scope-388/cases/context_wide_number_through_scope` an `f64` and an `i64`
provided and rendered through the scope (wasm refused them, no word holding one); B-25's Conformance step proposed
two pins beside them, `modules/decisions-taken/component_is_lambda_over_render_scope-388/cases/context_optional_wide_number_through_scope` (a `?f64` and a `?i64` provided with
their number and with `null`) and `modules/decisions-taken/components_compose_by_data-504/cases/component_try_catch_then_awaits_host_task` (a `try … catch` then a host
`await` in a component). A
component called as a statement outside a body runs nothing now, so `modules/decisions-taken/body_marker_whole_return_type-553/cases/effect_chain`,
`modules/decisions-taken/body_marker_whole_return_type-553/cases/effect_context_await`, `modules/use/cases/use_one_base`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_result_try_await` and
`modules/decisions-taken/body_marker_whole_return_type-553/cases/component_hook_and_component` `await` it in `main`, and `modules/decisions-taken/async_marked_by_hooks_list-375/cases/component_sync_plain_function` reads
375's mark through `run`. Decision 389 (a component named as a value is a reached node; a value the checker
cannot follow an edge with `callee: null`) adds `modules/decisions-taken/component_value_is_hooks_node-389/cells/decl_hooks_component_value` (`map(Card)`, a `val`, a
record field, a lambda answering one) and `modules/decisions-taken/component_value_is_hooks_node-389/cells/decl_hooks_dynamic_call` (in the module `pages` that `main` imports, its meta a typed `Graph` record; a parameter, a method and a
generic answer as `null` edges, the node asynchronous), each red on the parent binary; the `decl.hooks`
readers of the other cells read `HookCall.callee` as the `?Declared<unknown>` it is now.
144 B-141 adds `modules/meta/cases/meta_list_method_on_optional` and `modules/meta/cases/meta_list_coalesced_method` (a method on an
optional's list, a coalesced list) and `modules/array/cases/array_map_component_imported` (a component of an imported module),
each red on wasm on the parent binary and green on the four targets.
Decision 375 (`HookNode.async`) adds `modules/decisions-taken/async_marked_by_hooks_list-375/cases/decl_hooks_async` (a synchronous `Card` and `Header`, an awaiting
`Comments`, a page `async` through it with no written `await`, a cycle, a function value) and
`modules/decisions-taken/async_marked_by_hooks_list-375/cells/decl_hooks_async_imported` (an imported node's mark) on the four targets, and
`modules/decisions-taken/async_marked_by_hooks_list-375/cases/component_sync_plain_function` (commonJS only, `"targets"` — the host `pending` has only a Node binding:
a call of a synchronous `Card` answers no `Promise`, one of the asynchronous `Post` does); each red on the
parent binary.
Decision 357 (the rules of hooks) adds `modules/decisions-taken/use_at_component_top_level-357/cases/use_in_if`, `modules/decisions-taken/use_at_component_top_level-357/cases/use_in_loop`, `modules/decisions-taken/use_at_component_top_level-357/cases/use_in_lambda`
and `modules/decisions-taken/use_at_component_top_level-357/cases/use_after_early_return` (`use-not-top-level`, naming the construct or the line) and
`modules/decisions-taken/use_at_component_top_level-357/cases/use_conditional_argument` (a condition inside `use provide`'s argument, an `if` that does not
return before a `use`); `modules/decisions-taken/use_at_component_top_level-357/cases/use_after_return` and `modules/decisions-taken/use_at_component_top_level-357/cases/generator_loop_use` now meet
`use-not-top-level`, and the cells `use_inside_branch` / `use_in_closure` left for `use_in_if` /
`use_in_lambda`.
Decision 277 (`decl.hooks`, `01-checker` step 23) adds `modules/decisions-taken/decl_hooks_reachable_components-277/cells/decl_hooks_direct` (a host hook: one node;
commonJS, erlang and beam — `session` has no wasm binding), `modules/decisions-taken/decl_hooks_reachable_components-277/cells/decl_hooks_all_nodes` (four nodes, a
component once, calls in body order), `modules/decisions-taken/decl_hooks_reachable_components-277/cells/decl_hooks_custom_hook` (a hook's own node),
`modules/decisions-taken/decl_hooks_reachable_components-277/cells/decl_hooks_cycle` (an edge back), `modules/decisions-taken/decl_hooks_reachable_components-277/cases/decl_hooks_function_value` (`hook: null`),
`modules/decisions-taken/route_read_through_hooks-293/cells/decl_hooks_type_args` (a `use`'s type arguments with their fields, decision 293),
`modules/decisions-taken/context_named_by_value_type-379/cells/decl_hooks_context` (each `provide` / `context` with its context object, 354 (4); wasm refuses the
`use`) and `modules/decisions-taken/decl_hooks_reachable_components-277/cells/decl_hooks_imported` (another module's nodes, a hook through an alias with its own
annotations), on the four targets but where named; each red on the parent binary (`unknown field 'hooks'`).
Decision 371 (`Decorator.same`) adds `modules/decisions-taken/compiler_same_compares_declaration_handles-666/cases/decorator_same` — a package `web` whose `check` compares
each annotation's `decorator` with `serverOnly` and with itself: `#[srv]` under `import {serverOnly as srv}
from "web"` is `web`'s, the project's own `serverOnly` reached as `#[local.serverOnly]` is another
declaration (`other`); four targets — and `modules/decisions-taken/compiler_same_compares_declaration_handles-666/cases/decorator_same_not_decorator` (`same("serverOnly")`, a
type mismatch at the argument); the parent binary had no `same`. Decision 372 (a `.hooks` reader runs
after the module's bodies) adds `modules/decisions-taken/hooks_decorator_runs_last-372/cases/decl_hooks_reads_member` — `#[graph]`'s `Page` calls
`Account(…).validate()`, which `#[check]` adds below it; four targets, red on the parent binary
(`'validate' is not declared`) — and `modules/decisions-taken/hooks_decorator_runs_last-372/cases/decorator_hooks_output` (`decl.addMember` in a decorator
reading `decl.hooks`, `decorator-hooks-output` at the call; accepted by the parent binary),
`modules/decisions-taken/hooks_decorator_runs_last-372/cases/decorator_hooks_output_member_fn` (the same refusal of decision 370's typed
`decl.addMember(name, fn…)`) and
`modules/decisions-taken/hooks_decorator_runs_last-372/cases/typeinfo_all_hooks_reader` (`@TypeInfo.all(with: graph)` in the module of `#[graph]`'s `Page`;
answered by the parent binary).
Decision 139 (a negative index counts from the end) adds `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_negative_from_end` — `xs.at(-1)`,
`xs.at(-3)`, `xs.at(-4)` / `xs.at(3)` absent, `xs[-2]`, a negative index held in a `val`, the same for
`String.at` / `s[-2]`, and a string array — on all four targets.
Decision 140 adds `modules/pub/cases/pub_val_across_modules` — a module-level `pub val` of a record, an enum,
an array, a primitive and a lambda imported from a sibling, one under an alias, read from `main`, a
function and a method; the module bodies of `base` (imported only by `config`) and `config` run
before `main`, dependencies first, and a val read twice is evaluated once — on all four targets.
`modules/import/cases/import_same_name_from_two_packages` — two dependencies (`web`, and `ui`) each declare
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
both, by its snapshot. `transitive_package_import` (front 26 step 3, decision 242) — the
package declares `starter`, `starter` declares `core`, and `from "core"` in the package is refused
`unresolved import source "core" — declare it in botopink.json "dependencies"` at the source
string, by its snapshot on all four targets: only a direct dependency is importable.
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
modules, by its snapshot — the second import used to replace the first and commonJS answered
`app` where erlang and wasm answered `blog`. `import_same_fn_name_std_and_package_aliases` — a package
and `std/collections` both declare `lt` and `reverse`; one module imports each under an alias and
calls the four (it passes on the parent binary; it pins the rule).
1.0.11-beta `01-checker` step 1 (decision 150, D5) adds `modules/decisions-taken/mixed_literals_infer_union-150/cases/array_literal_union` (`[1, "a"]` is
`(i32 | string)[]`, an expected union takes its members; four targets), `modules/decisions-taken/mixed_literals_infer_union-150/cases/array_literal_numeric_join`
(`[1, 2.5]` is `f64[]` — the `1` is `1.0` on every target — and `[1, null]` is `?i32[]`),
`modules/decisions-taken/mixed_literals_infer_union-150/cases/array_literal_union_misuse` (an element used as an `i32` without narrowing, refused at the use
naming the widening element) and `test/case_value_union` (a `case` whose arms disagree is the union,
read back through `case` narrowing, beside the array literal's union). The `case` half is a `test/`
cell because wasm traps on a union of primitives produced by a `case` (`05-wasm`'s row); each array
cell was refused by the parent binary.
Step 2 (rows 28 and 31) adds `modules/case/cases/case_function_typed_arms` (two arms answering `fn(string) -> string`
join into that type and the result is applied, four targets), `modules/case/cases/case_function_arms_arity` (arms
whose arity differs are refused at the second) and `test/case_arm_lambda_value` (`A(x) -> { item ->
f(item) }` is a lambda value; a `test/` cell because beam answered `{badfun, ok}` for a lambda a `case`
arm produces — `03-beam`'s row). Each was refused by the parent binary. `03-beam` step 9 moved the
last to `modules/case/cases/case_arm_lambda_value` (four targets print `a?` / `b`) and deleted row 28.
Step 3 (decision 151, row 22) adds `modules/decisions-taken/enum_section_body_method_refused-151/cases/section_body_method` (a `fn` in a section body is
`section-body-method` at the `fn`), `modules/section/cases/section_numeric_leaf_standalone` (`val n: Tok.Percent =
.50;`, a leaf argument, and a section-typed field of a payload variant built with `.100`, four
targets) and `modules/section/cases/section_numeric_leaf_without_expectation` (`.50` with nothing expected names its
section). A section leaf prints as its mangled name (`__Tok__Percent.__50`) on every target, so the
cell reads it through `==`. Each was refused by the parent binary.
Step 4 (row 32) adds `modules/call/cases/call_of_record_value` (`val g = G(a: "x"); g()` is
`callee-not-a-function` at `g(`, beside a constructor and a function-typed field that still check)
and `modules/call/cases/call_of_imported_record_value` (the same through a sibling's `pub val`, by
its snapshot on all four); both were accepted by the parent binary.
Step 5 (decision 152) adds `modules/decisions-taken/binding_redeclared_refused-152/cases/binding_redeclared_in_body` (a second `var n` in one body) and
`modules/decisions-taken/binding_redeclared_refused-152/cases/binding_shadows_parameter` (`val x` over the parameter `x`), both `binding-redeclared` at the
second binding and both accepted by the parent binary. Decision 205 (the body is the whole function)
adds `modules/decisions-taken/shadowing_in_inner_blocks_refused-205/cases/binding_shadows_in_inner_block` (an inner block's `val y` over the function's `y`) and
`modules/decisions-taken/shadowing_in_inner_blocks_refused-205/cases/case_arm_binder_reuses_name` (a `case` arm's `Square(s)` over the parameter `s`), both
accepted by the parent binary. `04-js` step 4 adds the half decision 205 keeps,
`modules/decisions-taken/shadowing_in_inner_blocks_refused-205/cases/sibling_blocks_bind_one_name`: an `if` and its `else`, two `if`s, two loop bodies and two
`case` arms' binders each binding one name, and a block's `n` followed by the function's own `n`
once the block has closed — four targets, green on the parent binary (it pins that no backend
leaks a block's binding or invents a scope for it).
`modules/unwrap/cases/unwrap_or_literal_width` (another front's finding) — an integer literal as `unwrapOr`'s default
takes the payload's width over `?i64` and `@Result<i64, string>` (refused as `expected i32, got i64`
by the parent binary).
`modules/std/run/src/cases/std_type_ctor_through_namespace` (another front's finding) — `url.Url(…)` after `import {url}
from "std"` constructs the type through the module namespace, as the leaf `Url(…)` does (`this "std"
module has no such public function` on the parent binary), four targets.
Decision 170's type half (other fronts' findings) adds `modules/decisions-taken/aliased_imports_from_two_sources-170/cases/std_namespace_beside_own_type` (a
module's own `type Dict` beside `import {collections}` is the module's, four targets),
`modules/decisions-taken/aliased_imports_from_two_sources-170/cases/std_namespace_beside_aliased_type` (`import {kit.store.Dict as OwnDict}` beside the same
namespace reads `kit/store`'s fields; the cell builds the value through a function of `kit/store`,
because commonJS emits `Dict(5)` without `new` for an imported record constructor beside a std
namespace declaring the same name — `04-js`'s row),
`modules/decisions-taken/aliased_imports_from_two_sources-170/cases/std_namespace_signature_names_shadowed_type` (a namespace call whose signature names the
shadowed std type) and `modules/own/cases/own_type_beside_std_type_import` (a type of this module beside an
aliased import of a same-named std type — refused then, two types since decision 603's std half). Each
was accepted wrongly or refused with the wrong type by the parent binary.
Decision 310 (144 B-23) turns `modules/decisions-taken/aliased_same_named_types-310/cases/import_two_types_one_name` and
`modules/decisions-taken/aliased_same_named_types-310/cases/import_same_type_name_two_packages_one_aliased` into accept cells and adds
`modules/decisions-taken/aliased_same_named_types-310/cases/import_two_enums_one_name`, on the four targets: two same-named types of two modules, each
imported under an alias (or one of the two), are two types — each constructs, prints as declared,
answers its own method and is told apart by `is`, and a function of either module takes and answers
its own. Each refused (`import-name-collision`) by the parent binary. It adds
`modules/decisions-taken/aliased_same_named_types-310/cases/import_two_types_one_name_reached_indirectly` (the alias's type answered through a
namespace call, an imported template's built code and a decorator's member) and
`modules/decisions-taken/aliased_same_named_types-310/cases/import_std_type_beside_aliased_type` (std's `Dict` beside another module's, each aliased),
each refused or mistyped by the parent binary. B-23's Conformance step pins the two refusals 310
leaves, each green on the group's base: `modules/decisions-taken/aliased_same_named_types-310/cases/import_two_types_one_name_unaliased` (two
un-aliased items of two modules' `Policy`, decision 170) and
`modules/decisions-taken/local_type_beside_aliased_import-603/cases/import_alias_beside_local_type` (a type of this module beside an aliased same-named
import — refused while question B-23-a was open, two types by decision 603: it prints, constructs,
answers its own method and is told apart by `is` from the alias).
`modules/behavior/cases/behavior_default_fn_body_checked` and `test/behavior_default_fn_result` (another front's
finding) — a behavior's `default fn` body is checked (an unbound call is refused at it), and a
`-> @Result` default fn wraps its `return` and `throw`, its adopted call answering the `@Result`; a
`test/` cell because beam answers `{unresolved_method, …}` for any adopted default (`03-beam`'s row).
Step 12 (T9) adds `modules/reserved/cases/reserved_word_as_binding_name` — `val unknown: i32 = 1;` is
`reserved-word-as-name` at the name; it passes on the parent binary too (the row closed before this
front) and pins the rule.
Step 11 (T11) adds `modules/nullish/cases/nullish_tuple_operand` (a tuple literal on the right of `??`) and
`modules/postfix/cases/postfix_on_grouped_nullish` (`(xs.at(0) ?? d)._1`), four targets, integer elements because wasm
reads a `string` element of a tuple through `??` as its address (`05-wasm`'s row); both refused by
the parent binary at the `#`.
Step 8 (decision 45) adds `modules/decisions-taken/optional_member_access_needs_safe_call-45/cases/tuple_label_on_optional` (`rs.at(0).b` names `?.`) and
`modules/decisions-taken/optional_member_access_needs_safe_call-45/cases/tuple_label_through_optional` (`rs.at(0)?.b` reads the label through the optional, four
targets); both pass on the parent binary — the checker half landed with decision 45 — and pin it. The
absent half (`?.b` on a `null`) is `modules/decisions-taken/optional_member_access_needs_safe_call-45/cases/tuple_label_through_absent_optional` (144 B-22), four
targets.
Step 15 (report L, R3) adds `modules/imported/cases/imported_type_field_closure` (package `a`'s `Client(life:
Life, …)` with `Life` in a sibling module, imported by package `b` as `Client` alone and called from
the root, four targets) and `modules/imported/cells/imported_declaration_error_location` (a type error inside the
dependency's declaration is located at `a/client.bp`, by its snapshot). Both pass on the parent
binary — the row no longer reproduces at this base, and rakun-metrics' `export_test` passes with its
`CacheLife` workaround removed — and pin it.
Step 6 (decision 147) adds `modules/decisions-taken/lambda_return_is_expected_type-147/cases/try_in_lambda_without_result` (`[1, 2].forEach({ x -> try
bad(x); })` refused at the `try`) and `modules/decisions-taken/lambda_return_is_expected_type-147/cases/lambda_result_return_try` (a lambda under an expected
`fn(x: i32) -> @Result<i32, string>` — a `val` annotation and a parameter — `try`s, `return`s and
`throw`s, four targets); the parent binary accepted the first and refused the second. A
`throw_in_case_arm_result` cell is not added: erlang answers `false` for `isError()` on the arm's
`throw` (`02-erlang`'s row), the other three answer `true`.
`modules/decisions-taken/lambda_return_is_expected_type-147/cases/generic_ctor_fallible_lambda_fresh` (decision 147 beside a generic constructor) — two methods of
`Box<T>` each build a `Box(run: { … })` under the fallible field, one `Box<?T>`, one
`Box<Array<T>>`, on all four targets; the parent binary refused the second as `expected ?_[], got
?_` (the lambda's expectation was the constructor's registration-time cells).
The cell `modules/shorthand_import_beside_bundled_package` (decision 170) was deleted with decision
326: its subject — a shorthand import beside a bundled package — left when `routing` stopped being
bundled, and the shorthand itself goes with decision 337 (`01-compiler/129`).
Decision 337 (`01-compiler/129` steps 1–2) adds `modules/decisions-taken/shorthand_import_refused-337/cells/mod_binds_namespace` (`mod config;` binds
`config`: a call, a function as a value, a type in a signature, a constructor and a variant path,
no import), `modules/decisions-taken/shorthand_import_refused-337/cases/mod_namespace_cascade` (`mod geo;` alone reaches `geo.plane.distance(…)` and
`geo.plane.Point` through `geo/mod.bp`'s `pub mod plane;`), `modules/decisions-taken/shorthand_import_refused-337/cases/mod_reexport_by_val` (a
folder's `mod.bp` re-exports by value and by type — `pub val splitPath = split.splitPath;`, `pub
type Pair = split.Pair;` — the submodule private, the type `split`'s own), and
`modules/import/cases/import_nested_module_namespace` (`import {store.cache};` in a sibling binds `cache`), all
four targets; four refusals on every target by its snapshot — `private_module_through_namespace`
(`geo.plane` through a plain `mod plane;`, `private-module` at `plane`), `redundant_module_import`
(`import {config};` beside `pub mod config;`), `declaration_named_like_module` (`fn config()` beside
`mod config;`, `module-item-collision`, decision 582 (4)) and `shorthand_import_one_candidate` (`import {splitPath};`,
`shorthand-import`, the fix `import {config.splitPath};`) — and `modules/decisions-taken/shorthand_import_refused-337/cases/shorthand_import` (no module
declares the name: `unresolved import`). They are `modules/` cells, not refusal ones: each needs a
second module. The shorthands the suite wrote are their module paths now (`dependency_files_order`,
`sibling_import_in_a_dependency`); an `import {m};` beside `pub mod m;` is gone (`decl_hooks_imported`,
`decl_hooks_async_imported`, `decorator_meta_import`, `decorator_same`, `labelled_call_by_label`,
`namespace_import_module`), and an item named like the module `mod` binds is aliased
(`default_argument_across_modules`' `pad.pad as padTo`, `default_argument_open_across_modules`'
`greet.greet as greetFrom`, `external_method_imported`'s `meter.meter as newMeter`) — the second
binding of one name is `import-name-collision`.
Step 7 (decision 148) adds `modules/decisions-taken/lambda_captured_var_write_refused-148/cases/captured_var_write_in_lambda` (`run({ -> n = n + 1; 1; }, 0)` is
`captured-var-write` at `n =`; accepted by the parent binary) and `modules/decisions-taken/lambda_captured_var_write_refused-148/cases/closure_capture_statement_position`
(a `forEach` body, a local closure called as a statement — directly, in a `for` body and in a
`forEach` body — and a module-level `var` written from any lambda, four targets; it passes on the
parent binary too and pins the legal shapes).
`modules/decisions-taken/negative_index_counts_from_end-139/cases/generic_index_answers_optional` and `modules/decisions-taken/negative_index_counts_from_end-139/cases/generic_index_optional_return` (another front's
finding) — `return xs[0];` under `-> T` is the type mismatch naming `T` and `?T` (it was `recursive type
detected`), and the same functions declared `-> ?T` run on four targets.
Decision 207 (an inline parameter type) adds `modules/decisions-taken/inline_parameter_record_type-207/cases/inline_param_type` (built from the call's labels in
any order with a default left out, forwarded, beside an ordinary parameter, four targets), the parser's
refusals `modules/inline_type_in_{return,field,val_annotation}` (`inline-type-outside-parameter`), the
checker's `modules/decisions-taken/inline_parameter_record_type-207/cases/inline_type_on_method_param`, `modules/decisions-taken/inline_parameter_record_type-207/cases/inline_type_twice_on_one_fn`,
`modules/decisions-taken/inline_parameter_record_type-207/cases/inline_type_field_named_like_param` (`inline-type-position`), `modules/decisions-taken/inline_parameter_record_type-207/cases/inline_type_missing_field`
and `modules/decisions-taken/inline_parameter_record_type-207/cases/inline_type_unknown_field` (named by the owner, ``the props of `link` ``), and
`modules/decisions-taken/inline_parameter_record_type-207/cases/inline_type_across_modules` (a call from another module that writes the fields is refused;
the declaring module's own call runs). All sixteen fail on the parent binary.
Decision 208 (`Ok` / `Error` are never constructors) adds `modules/decisions-taken/ok_error_not_constructors-208/cases/result_ok_constructor` and
`modules/decisions-taken/ok_error_not_constructors-208/cases/result_error_constructor` — `unbound variable` at the name; both pass on the parent binary and
pin the rule.
Decision 209 adds `modules/integer_literal_fits_f64` (an integer literal under an expected `f64` — a
`val`, an `f64[]` element, an argument, a return, an arithmetic operand — prints as the float, four
targets; refused by the parent binary) and `modules/i32/cases/i32_value_never_widens` (an `i32` value passed to an
`f64` parameter is the mismatch; it passes on the parent binary and pins the half that stays).
Decision 215 adds `modules/decisions-taken/f64_vs_integer_literal_refused-215/cases/f64_equals_integer_literal` (`x == 2` with `x: f64`) and
`modules/decisions-taken/f64_vs_integer_literal_refused-215/cases/f64_not_equals_integer_literal` (`3 != x`), refused at the literal naming the float to write;
the beam codegen test `is and == read numbers by value …` no longer prints `2.0 == 2` (it answered
`false`). Both accepted by the parent binary.
Decision 255 (1) (a type application before a member) adds `modules/decisions-taken/type_application_versus_comparison-255/cases/type_application_static_member` —
`Dict<string, unknown>.empty()`, `Dict<string, i32>.empty()` chained, `Box<i32>.make(7)`,
`Opt<string>.None` and `Opt<i32>.Some(3)`, beside `a < b`, `x < y && z > w` and
`both(a < b, y > x)` that stay comparisons, on all four targets — and four refusal cells:
`type_application_argument_mismatch` (`Box<i32>.make("x")`, at the argument),
`type_application_argument_count` (`Box<i32, string>`, at the name),
`type_application_variant_payload_mismatch` (`Opt<i32>.Some("a")`) and
`type_application_on_a_field` (`Box<i32>.value` — only a unit variant is read without a call). All
five fail on the parent binary (`unexpected ','` / a comparison). Through a module namespace
(144 B-23) it adds `modules/decisions-taken/type_application_versus_comparison-255/cases/type_application_through_namespace` — `collections.Dict<string,
i32>.empty()` chained, `shapes.Box<i32>.make(7)`, `shapes.Opt<string>.None` on all four targets —
and `modules/decisions-taken/type_application_versus_comparison-255/cases/type_application_through_namespace_mismatch` (`shapes.Box<i32>.make("x")`, at the
argument); both `unexpected ','` / a comparison on the parent binary.
144 B-23 (a comptime body's diagnostic names the body's file) adds
`modules/decorator/cases/decorator_raise_names_body_file` — a decorator declared in `src/deco.bp` whose body
`@panic`s, refused at the annotation in `src/main.bp` with the message naming
`src/deco.bp:3:5`; the parent binary named no file. Its Conformance step's proposal adds
`modules/template/cases/template_raise_names_body_file` — a template declared in `src/tpl.bp` whose body `@panic`s, refused at
the call in `src/main.bp` with the message naming `src/tpl.bp:3:5` (the parent binary named no file) — and B-27's
the project suite `test/bpp_header_test` (a `test` written in a `.bpp` header, found and run by `botopink test`
on commonJS, erlang and beam; a pin).
144 B-48 (decision 451 (3): a raise in a body of this module is located at the call that raised) re-records
`decorator_random_float_unseeded`, `comptime_random_float_unseeded`, `hole_known_at_build_raises` and
`typeinfo_all_duplicate_at_entry`; its Conformance step adds `modules/decisions-taken/seeded_random_std_wasm-451/refused/src/cases/decorator_helper_raise_located` — a decorator
body calling a helper of its module whose `@panic` raises, refused at that `@panic` (8:28), red on B-48's parent,
which located it at the annotation (17:3).
Decision 255 (2) (`comptime <expr>` is `comptime { break <expr>; }`) adds `modules/decisions-taken/type_application_versus_comparison-255/cases/comptime_expression_is_block`
(a module-level shorthand equal to its block form, and the same in a body) and
`modules/decisions-taken/comptime_evaluated_and_lifted-266/cases/comptime_expression_static_call` (the decision's own `val d: Dict<string, unknown> = comptime
Dict.empty();` beside its block form), and `modules/decisions-taken/type_application_versus_comparison-255/cases/comptime_expression_type_mismatch` (the
expression's type is the form's, located at `comptime` as the block's is).
Decisions 266 and 331 (`01-checker` step 21 — every `comptime` runs on the comptime runtime, BEAM or
WAT by the target, never on the target, and its value is written into the program) give
`modules/decisions-taken/comptime_evaluated_and_lifted-266/cases/comptime_expression_static_call` all four targets (its `snapshot/targets/wasm/` departure is gone: the `Dict` is
written as its constructor) and add `modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_block_with_loop` (`comptime two()` emits `2`; a
block with a call and a loop answers `6`; a loop pushing strings answers the array — one `snapshot/output/` answer on
the four targets; the parent binary refused the block on erlang, read `d` unbound on commonJS and
had no wasm lowering), `modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_val_after_import` (step 20's finding: a module-level
`comptime` `val` after an import, dropped on commonJS by the parent binary; a call and a record at
module level), `modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_function_reference` (a `Dict` of a declared function and a lambda
reading nothing the block declares, written back as the reference and the lambda — rakun's bean
catalogue shape) and `modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_value_not_liftable` (a lambda capturing the block's `val`,
`comptime-value-not-liftable` at the `comptime`; the resource half is `block_eval.zig`'s unit test —
the WAT runtime has no process to answer, so no one cell refuses it the same way on both runtimes).
06-emilia/34 step 5's two comptime rows (a nested-section enum value at comptime; emilia's dispatcher
at comptime) add `modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_enum_section_value` (`.Pad.All.8` as an argument, in an array, inside
a payload variant, and written back from `comptime first(…)`, `comptime padX()` and an array — four
targets; the parent binary raised `{error,{badmap,'Pad'}}`), `modules/decisions-taken/comptime_parameter_is_expression-364/cases/comptime_decorator_section_value`
(`#[mark(.Pad.All.4, .Bold, Tok.Pad.All.8)]` read as `tokens.value`, and a function the decorator
reaches writing `.Pad.All.8`; the parent raised `{badmap,'Pad'}` at the annotation),
`modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_imported_section_path` (an imported enum's section value from an imported function
and back into this module; the parent's comptime module called an undefined `Pad/1`),
`modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_section_path_declared_after` (a section path in a function declared after the
`comptime` that reaches it, refused naming the path and the function, as a template call there is)
and `modules/decisions-taken/comptime_runs_at_build-331/cases/comptime_record_pattern` (a record matched on the comptime runtime as its untagged map — a
constructor pattern in an arm and in a `val`, `is`, an arm naming `Block`, a record and a section's
variant; the parent's lowering failed `MissingPackage`).
`01-compiler/14` step 6 (decisions 341, 343) adds `modules/decisions-taken/libraries_run_at_build_on_wasm-594/cases/decorator_host_cells` (a decorator body calls
a host function with both cells and std's `hash.contentHash` through its namespace and a leaf
import — the wasm comptime runtime runs `bang`'s `.Wasm(body: …)` cell (its Erlang cell never runs at
build, decision 452) and `contentHash` as std-wasm's, for every target; four targets, one output; the parent binary was `call to undefined function bang/1`),
`modules/decisions-taken/decorator_calls_host_comptime_cell-341/cases/decorator_imported_host_function` (the same through an imported function and an imported
decorator: the export carries its host and std functions),
`modules/decisions-taken/comptime_never_translates_erlang-452/cases/comptime_host_cell_unavailable` (decisions 434 (4), 452: a host function with neither a `std:` nor a
`fn:` cell, refused at the call naming both — was the cell `decorator_host_cell_missing`),
`modules/decisions-taken/comptime_never_translates_erlang-452/cases/comptime_host_cell_unavailable_erlang_only` (decision 452: a host function with an `.Erlang`
cell alone is refused the same way, the cell never run at build — was the cell `comptime_beam_call_not_converted`;
`modules/decorator_erlang_cell_only` is this refusal),
`modules/decisions-taken/comptime_never_translates_erlang-452/cases/comptime_erlang_cell_ignored_fn_serves` (decision 452: an Erlang cell beside a `fn:` cell is ignored, the
`fn:` body answers on the four targets — was the cell `comptime_beam_call_not_converted_fn_after`, decision 439,
which no longer applies),
`modules/decisions-taken/std_cell_is_std_only-445/cases/external_wasm_std_outside_std` (decision 445: a `std:` cell is std's alone — outside
`libs/std` it is refused at the annotation on every target, naming the std function to call
instead; it replaced `external_wasm_std_unknown` and `external_wasm_std_types`, whose refusals —
a name std-wasm lacks, other types — only std can now meet, pinned in `codegen/tests/wat.zig`
over a module of std's own),
`modules/decisions-taken/seeded_random_std_wasm-451/refused/src/cases/comptime_random_unseeded` (decision 451 (3): at comptime a draw of `io/random`'s seeded
stream before any `seed` is refused at the `comptime` that reached it — a build has no entropy)
beside `modules/decisions-taken/libraries_run_at_build_on_wasm-594/cases/comptime_random_seeded` (the seeded draws at comptime, std-wasm's Mulberry32, the
same text on all four targets),
`modules/decisions-taken/decorator_invocations_independent-343/cases/decorator_writes_module_var` (`decorator-writes-module-var` at the write, through a function
of the module; the parent binary said `unbound variable`) and `modules/decisions-taken/decorator_invocations_independent-343/cases/typeinfo_all_duplicate_at_entry`
(two commands of one name refused at the entry point's `@TypeInfo.all`, naming both). Step 8 adds
`modules/decisions-taken/libraries_run_at_build_on_wasm-594/cases/comptime_std_host_function` (`comptime hash.contentHash(…)`, T19, four targets — the parent
binary refused `.contentHash(…)`) and `modules/hole_imported_val_known_at_build` (a hole naming an
imported `val` known at build is written at build; the parent binary computed it at render), and
`modules/decisions-taken/component_wrapper_and_contexts-354/cases/comptime_reaches_use` (question `14s8-e` (a): a `comptime` calling a component that reads a
context is refused naming the `use`).
`01-compiler/14` step 8 (decision 355) adds `modules/styled_holes_known_at_build` (a template of the
cell's own reads each hole's `known` / `value`: a literal, a `val`, another expansion with no
run-time hole and a `comptime` are written at build, a parameter and a call computed at render —
four targets; the parent binary fails the body at `badkey known`), `modules/decisions-taken/dsl_names_resolve_in_author_scope-112/cases/comptime_reaches_package_template`
(a `comptime` over a package template's expansion, whose built code calls the package's function
under its alias, and a record of the package's type written back where the module does not import
it — the parent binary aborted the compiler), `modules/comptime/cases/comptime_interpolation_in_called_fn` (`"${…}"` in
a function a `comptime` calls), `modules/comptime/cases/comptime_template_call_declared_after` and
`modules/hole_known_at_build_raises`.
`01-checker` step 41 (decision 429) adds `modules/template/cases/template_two_alike_expansions` (two expansions of one
template whose built code sits at the same offsets — `r.length` over an array and `r.w` over a
record; the parent binary lowered the first with the second's field access on erlang),
`modules/template/cases/template_default_arg_two_expansions` (a call that leaves out a default argument and a call of a
one-parameter function at the same offset of two expansions; the parent binary filled the default
into the second, `footer/2 undefined` on erlang) — four targets, no padding — and
`modules/decisions-taken/template_code_located_by_expansion-429/cases/template_built_code_diagnostic_located` (a diagnostic in built code at the place in the
caller's text the code copies, after the two-byte `` @` ``; the parent binary located it at `1:20`).
`test/program_primitive_behavior_extends_std` and `modules/program/cases/program_primitive_behavior_redeclares_std`
— a program's own contract implemented for `string` (`StringShout implement Shout for string {}`,
decision 799) adds its members to `string` (its default fns call `slice`, `startsWith`, `length` on
`self`, the contract declaring the ones it calls and `string`'s own members meeting them, and std's
members answer beside them), and a contract member `string` already has is
`behavior-member-redeclared` at the implementation. `modules/program/cases/program_primitive_behavior_extends_std`
is its running twin on all four targets, a
`behavior Number` default beside it; wasm called no program-declared default fn of a primitive
(it trapped) until `05-wasm`'s `lowerPrimDefault`.
`modules/program/cases/program_array_behavior_default` does the same for a contract implemented for `array<T>`
(`ArrPick<T> implement Pick<T> for array<T> {}`) — defaults
calling std's `at` / `length` / `filter` / `all` / `contains` / `join` on `self`, taking a `T` and a
`Self<T>`, answering `?T`, `T`, `Self<T>`, a bool and a string over integers, strings and records —
on all four targets (wasm trapped: the copy did not substitute `Self<T>`; beam aborted on `ys.all(…)`
over a `Self<T>` parameter until a program's default read its recorded lowering). Decision 799's own
cells: `modules/decisions-taken/primitive_member_by_contract-799/cells/primitive_member_by_contract` (`"a+b".tailShout()` is `a+b!`, a contract of another
module, `array<T>`'s `second`, four targets), `modules/decisions-taken/primitive_member_by_contract-799/cases/primitive_behavior_named_like_type_refused`
(`behavior string`, `primitive-type-redeclared` at the name) and `modules/decisions-taken/primitive_member_by_contract-799/cases/primitive_extend_refused`
(`extend string` keeps its refusal, naming `implement <Behavior> for string`; green on the parent
binary, the kept rule). All but the last refused by the parent binary.
Decision 641 (every primitive type lowercase, a capitalised name a contract several types share)
adds two cells under `modules/decisions-taken/primitive_types_lowercase-641/cells/`:
`primitive_static_on_type` (`string.fromCodepoint(65)`, `array.range(0, 3)`, `array.repeat`,
`bytes.fromUtf8`, `bigint.of` called through the type's name, four targets) and
`primitive_contract_dissolved` (`String.fromCodepoint(65)` refused as an unknown name), both red on
the parent binary. The cells and std were respelled by `scripts/codemod/primitive_names.py`; a cell's
local named like a type (`val bytes = …`) shadows that type's statics where it is in scope, so
`fs_read_text_not_utf8`'s local is `written`.
Decision 206 (`from` names a package — std or a declared dependency — and a
module of the importing package is imported by its path inside the braces) adds three `modules/`
cells. `import_own_module_with_from` is the refusal: `import {area, perimeter as around} from
"geometry";` over the package's own `geometry` is `error[module-import-with-from]` at the source
string, writing the brace form, by its snapshot on all four targets (it compiled and ran on the
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
Decision 141 adds `modules/external/cells/external_template_refused_on_beam` — an `.Erlang` template with a
macro runs on erlang and is a located build error on beam naming the construct (`snapshot/targets/beam/`); beam
no longer evaluates a template it cannot compile from source at run time.
Decision 216 (front `130-decorator-outputs`, what a decorator produces) adds, for its first place —
`decl.addMember(source)`, a member of the annotated type — `modules/decisions-taken/decorator_four_output_places-216/cases/decorator_add_member` (an associated
fn and a method added by a type's decorator and one added by a field's, beside a hand-written
member) and `modules/decisions-taken/decorator_four_output_places-216/cases/decorator_add_member_import` (the members travel with the type: an importer
calls `City.fromRow(r)` through a plain import and an alias), on all four targets, and three
refusal cells at the annotation: `decorator_add_member_on_fn` (`decorator-member-without-type`),
`decorator_add_member_duplicate` (`decorator-member-duplicate`) and `decorator_add_member_not_one`
(`decorator-member-not-one-fn`), and one where the call is written: `decorator_member_unknown`
(`unknown-associated-fn` — a type's members are closed, so `City.revisions()` on a type no
decorator gave it is refused). Its second place — meta, a typed record per decorator since decision
576 (11) (`decl.setMeta(Entity(…))`, read `@typeInfo(X).meta(Entity)`) — adds
`modules/decisions-taken/decorator_four_output_places-216/cases/decorator_meta_import` (meta read through a plain import, an alias and a namespace import),
on all four targets, and two refusal cells: `typeinfo_unknown_declaration` where the read is
written and `decorator_meta_on_member` at the annotation. Its third place — `decl.addType(name, source)`, an
associated type named `Owner.Name` — adds `modules/decisions-taken/decorator_four_output_places-216/cases/decorator_add_type` (a record `City.Columns` in type
positions, constructed by its path and returned by an added member, an enum `City.Size` whose
variants are reached as `City.Size.Large`, both printed under the owner's path) and `modules/decisions-taken/decorator_four_output_places-216/cases/decorator_add_type_import` (imported with its
owner, under an alias too, and `Greeter.Mock` — a double implementing the annotated behavior — passed
where a `Greeter` is expected), on all four targets, and four refusal cells at the annotation:
`decorator_add_type_duplicate`, `decorator_add_type_not_one`, `decorator_add_type_without_owner`
and `decorator_add_type_name`. Its fourth place — `@TypeInfo.all(with: d)`, the program's
declarations carrying `d` — adds `modules/decisions-taken/typeinfo_all_declared_type-254/cells/typeinfo_all_registration` (an entry point that imports
neither page module catalogues their `#[route]` functions with their meta, in module-path then
declaration order, and its own and another module's `#[component]` types through `member:`; a
decorator nothing carries answers `[]`), on all four targets, and
`modules/decisions-taken/aliased_imports_from_two_sources-170/cells/typeinfo_all_type_also_imported` (catalogued types of a dependency and of a nested module
of the package, each also imported by the entry point — plain, under an alias, by its path — are
one declaration reached twice, not decision 170's two types of one name), on all four targets, two project refusals by
its snapshot — `typeinfo_all_imported` (a module importing the reader, at the import) and
`typeinfo_all_private` (a private declaration the query would answer) — `modules/decisions-taken/decorator_four_output_places-216/cells/typeinfo_all_spelled_in_string`
(a module whose string literal only spells `@TypeInfo.all` is no reader: the entry point imports it and
catalogues its tagged function, on all four targets), and four refusal cells
where the query is written: `typeinfo_all_mixed`, `typeinfo_all_needs_member`,
`typeinfo_all_with_ordinary_fn` and `typeinfo_all_arguments` (decision 268: `with:` is declared
`Decorator | Decorator[]`, so an ordinary function — `typeinfo_all_with_ordinary_fn` — and a literal —
`typeinfo_all_with_number` — are the ordinary type mismatch at the argument; `modules/decisions-taken/compiler_same_compares_declaration_handles-666/cases/typeinfo_all_decorator_argument`
accepts a decorator with arguments, a single decorator and a list of them); decision 353 (a template function's body reads the catalogue of the program that expands it) adds
`modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/template_reads_program_catalogue` (a package's `pub default fn` counting the application's
`#[theme]` — one, declared in a module analysed after another expands the template — and an empty
`#[palette]`, on all four targets), two project refusals at the expansion, `template_catalogue_two_themes`
(the template's own `e.fail` naming both declarations) and `template_catalogue_private`
(`typeinfo-all-private`), `typeinfo_all_imported_package_default` (`import cat from "cat"` naming a
reader's default fn, `typeinfo-all-imported` at the handle) and `modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cases/typeinfo_all_template_value`
(a template body reading an entry's `value`); decision 235's list form adds
`modules/decisions-taken/typeinfo_all_with_list-235/cases/typeinfo_all_list` (two decorators in one `with:`, declaration order kept, a type carrying two
of them answered once with both decorators' meta) and `modules/decisions-taken/typeinfo_all_with_list-235/cases/typeinfo_all_list_twice`; the catalogue's
reach (144 B-86) adds `modules/decisions-taken/decorator_four_output_places-216/cells/typeinfo_all_dependency_declarations` (a dependency's `#[m]` declaration and its
own dependency's, imported by no module of the program, listed beside the package's own by module path, the
same answer when the dependencies are read back from the code cache); decision 551 (a `comptime` parameter whose
default is a `@TypeInfo.all(…)` query, answered for the program the call is compiled in) adds
`modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/typeinfo_all_default_at_caller` (a library's `boot()` with no argument listing the program's `#[m]`
declarations of every package, the library's own, the program's and a dependency no module imports, on commonJS,
erlang and beam), `modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cases/typeinfo_all_default_outside_root` (the call in a module that is not the package's root,
`typeinfo-all-default-outside-root` at the call) and `modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/typeinfo_all_default_override` (the argument passed:
another catalogue and an empty array, on all four targets). Decision 562 (a function whose every parameter is
`comptime` and whose body reads one's `.value` is expanded at its call site) adds `modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/comptime_expand_boot`
(a library's `boot()` starting the program's three `#[module(n)]` functions in their `meta` order, each one's `say`
and `start` written in `main`), `modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_banner` (`banner(3)`: a range over a number unrolled, the
row written into each emitted host call), `modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_constant_at_build` (a module constant deciding a
condition and written into the emitted call), all three on all four targets, and two refusals:
`modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_condition_run_time` (`if (d.value is …)`, `run-in-build` at `d.value`) and
`modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_runtime_argument` (a field of a run-time variable passed, `comptime-arg-not-known` at the
variable); `modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_library_names` (a library's expanded function naming its private type, its private
function and a std namespace the caller does not import, on all four targets) and
`modules/decisions-taken/comptime_parameter_call_expanded-562/cases/comptime_expand_library_type_error` (a refusal of the emitted code located in the library, the call as its
`from` line). `modules/decisions-taken/function_stage_propagated-376/cases/stage_build_and_run`, `modules/decisions-taken/function_stage_propagated-376/cases/stage_of_functions` and `modules/decisions-taken/function_stage_propagated-376/cases/stage_imported` give their
`Build` function a run-time parameter (an all-`comptime` one is expanded instead), and `stage_of_functions` lists
one that is expanded, `Any`. Decision 564 (a decorator's `syntax decl: B` names the behavior its declarations
implement) adds `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decorator_decl_behavior_not_implemented` (`#[module]` on a type that does not
`implement Module`, refused at the annotation naming both), `modules/typeinfo/cases/typeinfo_all_behavior_typed` (the answer bound
and handed on as `Declared<Module>[]`, no `member:`), `modules/decisions-taken/typeinfo_all_with_list-235/cases/typeinfo_all_behavior_shared` (two decorators naming
one behavior answer `Declared<Component>[]`), `modules/typeinfo/cases/typeinfo_all_behavior_none_shared` (two naming different
ones answer `Declared<unknown>[]`, the ordinary mismatch at the binding) and
`modules/decisions-taken/comptime_parameter_call_expanded-562/cases/typeinfo_all_behavior_call_outside_expansion` (`d.value.make()` in `main`, refused at the call); the
`meta_catalogue_private_type`, `meta_typed_catalogue` and `meta_expr_read_elsewhere` cells catalogue their types
through such a behavior instead of `member:`. A `behavior` named like a prelude declaration is the module's
(§ behavior of `docs.md`): `modules/behavior/cases/behavior_named_like_prelude_value` (`behavior Component` and `behavior Any`, names
the prelude also binds as bare variants, in a decorator's `syntax decl: Component`, a parameter and an `implement` clause),
`modules/behavior/run/src/cases/behavior_named_like_prelude_type` (`behavior Field` and `behavior Result`, names of prelude types) and
`modules/import/cases/import_behavior_named_like_prelude` (the same imported from a sibling module). Decision 248
names the one reflection builtin `@typeInfo` (the structural `TypeInfo` answer of a bare
`@typeInfo(T)` folded in): `modules/decisions-taken/one_typeinfo_reflection_builtin-248/cases/typeinfo_lowercase` and `modules/decisions-taken/one_typeinfo_reflection_builtin-248/cases/typeinfo_all_lowercase` refuse
the lowercase `@typeinfo(…)` / `@typeinfo.all(…)` where it is written (`typeinfo-lowercase`).
Decision 253 makes the catalogue the static `@TypeInfo.all` of the builtin type:
`modules/decisions-taken/typeinfo_all_catalogue-253/cases/typeinfo_all_on_function` refuses `@typeInfo.all(…)` (`typeinfo-all-on-function`).
Decision 356 (a decorator on a `val` runs, and the `val` is catalogued) adds `modules/decisions-taken/val_decorator_runs_catalogued-356/cases/val_decorator_catalogue`
(`DeclKind.Val`, the declared type as `returnType` and `returnTypeName`, `setMeta` read by
`@typeInfo(<val>)`, both `val`s answered by `@TypeInfo.all`, four targets) and five refusal cells at the
annotation or the query: `val_decorator_on_var` (a decorator on a module `var`, refused until `116-c` is decided), `val_decorator_runs` (`#[mark] pub val one = 1;` fails with the decorator's
message — the parent binary printed `1`), `val_decorator_add_member` and `val_decorator_add_type`
(`decorator-member-without-type` / `decorator-type-without-owner`, "the val") and
`typeinfo_all_val_and_fn` (`typeinfo-all-mixed`: a `val` and a function under one query). Decision 361
(std's `bpp` annotations; front 116 step 1) adds five refusal cells where std's decorators refuse a
role's place — `bpp_html_on_val`, `bpp_style_on_val`, `bpp_html_not_template` (a function that is no template answering `R`), `bpp_prelude_on_fn`, `bpp_style_prelude_on_fn` — and eight `modules/bpp/{run,refused}/src/cases/bpp_*` and `modules/bpp/cells/bpp_*`
projects over a fixture package `markup` (not jhonstart): `bpp_roles_found` (the key, the roles
`#[bpp.html]` and `#[bpp.htmlPrelude]`, no `.bpp` file: accepted, four targets) and seven refused on every
target — at the `"bpp"` key `bpp_html_missing`,
`bpp_html_twice` and `bpp_prelude_twice` (naming the declarations), in the package's file
`bpp_prelude_holds_declaration` and `bpp_role_not_pub`, at the `.bpp` file `bpp_file_without_key`
(line 1) and `bpp_style_section_without_style` (its `--- style ---` line). Every one was red on the
parent binary.
Decision 561 (a name between backticks is an identifier, 144 B-27) adds one cell per name position, each
the same answer on commonJS, erlang, beam and wasm: `backtick_name_binding` (`` `not-found` `` beside
`not - found`, a keyword `` `fn` ``, UTF-8 and spaces), `backtick_name_parameter` (by position, by label,
a lambda's), `backtick_name_function` (a keyword `` `if` ``, recursion, a function value),
`backtick_name_type` (a record with a method, an enum and its variants, matched and printed as written),
`backtick_name_field`, `backtick_name_module_segment` (`` mod `my-utils`; `` and a nested
`` `report-pages`.`not-found` ``), `backtick_name_import_item` (an item and an alias each way) and
`backtick_name_in_diagnostic` (the backtick form in a refusal); `bpp_not_found_aliased` and
`bpp_not_found_unaliased` import `not-found.bpp` over the `markup` fixture with and without an alias;
`backtick_name_empty` and `backtick_name_line_break` are the two lexer refusals. Every one was red on the
parent binary.
Decision 254 types the answer `Declared<unknown>[]` whatever the program declares:
`modules/decisions-taken/bean_registry_built_at_comptime-256/cells/typeinfo_all_unknown_value` catalogues two functions of different signatures in one answer
(each naming its declared return type, `returnTypeName` — decision 256; `modules/decisions-taken/typeinfo_all_with_list-235/cases/typeinfo_all_list` reads
it `""` for a type), and
`modules/decisions-taken/typeinfo_all_declared_type-254/cases/typeinfo_all_value_unknown` refuses an entry's `value` used as a function without a test.
The registration and list cells therefore read `name`, `module` and `meta` only. Front 130 adds
the narrowing (decision 254): `modules/decisions-taken/typeinfo_all_declared_type-254/cases/is_fn_narrows_unknown` narrows an `unknown` with `is fn(<params>)
-> T` and calls through it — a stored factory, a lambda, a top-level fn, a value of another arity,
a string and a number — on all four targets; `modules/decisions-taken/typeinfo_all_declared_type-254/cases/is_fn_wrong_arity_fails` (`abort`) is a
resolver narrowing a stored `fn(i32) -> i32` with `is fn() -> Clock` and panicking with the entry's
name and the expected type (the message is on stderr on every target, wasm's included, which writes it before the trap); and
`modules/decisions-taken/typeinfo_all_declared_type-254/cases/call_unknown_without_narrowing` refuses calling an `unknown` that no test narrowed.
`modules/fn/cases/fn_local_rebound_call` calls a fn-typed local at its current binding — a `val v` narrowed
by `is fn() -> i32` in two sibling `for` bodies, a reassigned `var f`, a second `val f` lambda —
on all four targets (erlang applied the first binding's `V` where the second was `V@1`).
Decision 252 (every builtin declared, a call held to its declaration) adds
`modules/decisions-taken/builtins_declared_in_d_bp-252/cases/builtin_arguments` — `@panic` given a second argument its declaration does not have,
`builtin-arguments` at the call. Decision 322 (`is` is only an operator) adds
`modules/decisions-taken/is_only_an_operator-322/cases/hand_written_is_builtin` — `@is(1)` written by hand, `unknown-builtin` at the `@`.
Decision 307 adds `modules/decisions-taken/derived_type_static_methods-307/cases/std_types_module` — `import {types.Type} from "std"` resolves on all four
targets (std's `types.bp`, exported by `root.bp`).
C-03's beam half adds `modules/decisions-taken/wasm_clock_fs_refused-241/cells/std_template_host_fns_across_modules` — std host functions whose
`.Erlang` body is a template (`fs.exists`, `fs.readText`, `os.eol`, `process.platform`,
`encoding.hexEncode`, `hash.sha256`, `json.quote`, `regex.matches`) called from the program's
module through a folder namespace and a leaf import, on commonJS, erlang and beam (`"targets"`: wasm
refuses `io/fs`, decision 241's group 3).
`01-compiler/05-wasm` step 5 adds a cell per std module family, the commonJS answers on four
targets: `modules/std/run/src/cases/std_encoding_on_every_target` (base64, base64url, hex, percent and form codecs over
ASCII to astral text, each decoder's refusal) and `modules/std/run/src/cases/std_querystring_on_every_target` (query and
form bodies, each refusal); `modules/decisions-taken/wasm_attempt_by_exception_handling-518/cells/std_json_on_every_target` (writers, `unquote`, `decode` and its
accessors, the host round-trip) runs on three and is refused on wasm by name (`snapshot/targets/wasm/`) until
`decisions-pending.md` 05w-j binds `json.parse` / `stringify` there; `modules/decisions-taken/unicode_normalize_in_botopink-333/cases/std_unicode_on_every_target`
(`fromCodepoint`, `codepoints`, `firstCodepoint`, the four normalization forms — std's botopink
normalizer, decision 333 (A)) has one `snapshot/output/` answer for the four targets. Two cells pin the wrong answers wasm gave those families at exit 0, each failing
on the parent binary: `modules/std/run/src/cases/std_namespace_calls_same_name` (`querystring.parse` and `url.parse`
through their namespaces — the mangled one's receiver was dropped) and `modules/tuple/cases/tuple_optional_element`
(a `?T` in a tuple — printed, read through `._N`, a generic method's `#(Q<T>, ?T)`, and
`o.unwrapOr(d)` keeping a tuple's shape).
The backend rows of `status.md` (`front/backend-rows-2`) add, each failing on the parent binary
on the targets named: `modules/case/cases/case_arm_record_named_like_a_variant` (a `case` over `Block | Vec` naming
a record an enum section also declares as a variant — erlang `case_clause`, wasm a trap, beam the
subject itself), `modules/array/cases/array_last_index_of` (all four; `Array` declared no `lastIndexOf`),
`modules/array/cases/array_pop_removes` (erlang and beam read without removing, wasm trapped),
`modules/module/cases/module_var_self_registration` and its `_test` twin (a module-level `var` grown by `push` at
module load — erlang and beam dropped the write), `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_answer_typed_optional` and
`modules/decisions-taken/negative_index_counts_from_end-139/cases/index_answer_is_optional` (`xs[k]` is `?T`; wasm's `?Color` compare and `??` binder),
`modules/integer/cases/integer_literal_labelled_field` (a literal in a labelled `i64` field, every target),
`modules/std/cells/std_unsupported_names_the_call` (STD-001 names the function called, at the call),
`modules/behavior/cases/behavior_method_dispatch_by_value` (wasm dispatches a behavior-typed call),
`modules/string/cases/string_char_code_non_ascii` (wasm answered bytes), `modules/val/cases/val_assert_variant_pattern` (commonJS
`ReferenceError`, beam `{unassigned, …}`) and `modules/is/cases/is_enum_variant` and
`modules/renderer/cases/renderer_record_field_shapes` (shapes the rows measured, which no longer reproduce — pinned).
1.0.11's `01-compiler/05-wasm` step 1 adds one cell per primitive-method group wasm trapped on, each
`snapshot/output/` answer shared by four targets: `modules/string/cases/string_lines_words` (`lines` — `\r\n`, a trailing `\r` kept, `""`
one empty line — and `words` over blanks), `modules/array/cases/array_flat_forms` (`flatten`, `flat`, `flatMap`
over integers, strings, a local, a parameter and an annotated empty `i32[][]`), `modules/array/cases/array_windows`
(`chunked`, `sliding`, `n <= 0`, a slice indexed and measured) and `modules/array/cases/array_fill` (a value of
each primitive, an empty receiver). `pop` is `modules/array/cases/array_pop_removes`; `unique`'s cell is
`02-erlang`'s `modules/decisions-taken/array_unique_keeps_first-217/cases/array_unique` (C-35).
`modules/generic/cases/generic_field_fn_value` — a top-level fn stored in a generic record's field (`Box<T>(value: T)`)
and called through the field, through an untyped local and through a generic wrapper, and a lambda
stored there typed by those calls, by a `val`'s annotation, by a parameter and by a return type —
answers the fn's own result on commonJS, beam and wasm (wasm printed a string's address, a bool as
`1`, a lambda's string parameter as an integer; front 130's row); erlang refused `h.value("b")` (`function value/2 undefined`) until a field written as a type parameter was applied like a `fn(…)` one (`codegen/AGENTS.md`).
Step 2 adds `modules/generic/cases/generic_string_equality` — `==` / `!=` between two type-parameter values bound
to strings built at run time, by a call's arguments, an array's elements, a generic record's
constructor and a generic call answering one, a parameter written `Pair<T>`, a variant's payload,
an array of such records under `map`, and a generic fn handed to a `fn(a: string, b: string) ->
bool` parameter or bound to a `val` of that type — on four targets; wasm compared words for the
record, generic-result, `Pair<T>`, array and fn-value rows.
`00 · 03-beam`'s split row adds `modules/string/cases/string_split_empty_separator` — `split("")` cuts into UTF-8
codepoints (`"%0Aéz"` → 5 pieces, `""` → none) beside a non-empty separator and an empty separator
held in a `val`, on all four targets (beam lowered it to `string:split/3`, wasm cut between bytes).
144 B-22 step 13 adds `modules/val/cases/val_spread_only_list_pattern` — `val [..rest] = xs;` binds the whole list,
over a literal, a parameter and the empty list (the checker admitted it and bound nothing: `unbound
variable 'rest'`) — and `modules/val/cases/val_nested_ctor_pattern` — `val Pair(Circle(r), n) = p;`, three levels
deep, beside a `_` and inside a record's own constructor (refused `refutable-val-pattern`, and on wasm
"no lowering for this constructor pattern in a binding"), both on all four targets.
`01 · 03-beam` step 1 adds `modules/ctor/cases/ctor_pattern_in_val_binding` — `val Label(t, w) = Tag.Label(…)`, a
one-variant type's constructor in binding position, prints `7` on all four targets (beam bound
nothing: `{unresolved_identifier, t}`), and `modules/import/cases/import_capitalised_fn` — an imported `pub fn Make`
called with labelled and positional arguments, on all four targets (beam built `Make(n: 4)` as the
record `#{n => 4}`).
01-std step 2 adds `modules/decisions-taken/asserts_throws_generic-493/cases/std_asserts_on_every_target` — `import {testing.asserts}` and its pure
assertions on commonJS, erlang and beam — and `modules/decisions-taken/wasm_attempt_by_exception_handling-518/cells/std_asserts_host_cell_on_wasm` — `asserts.deepEquals`
on the same three. On wasm the first runs too — the module's functions that reach `canonical`, which has no
wasm binding, are not lowered and stop nothing while the program does not call them (decision 531) — and the
second is refused at the call of `deepEquals` (STD-001, decision 518 (4); `snapshot/targets/wasm/`). The same front's `modules/result/cases/result_field_read` and
`modules/result/cases/result_unknown_method` refuse a member of a `@Result` that is not one of its methods
(`result-member-not-a-method`).
The onze front's compiler findings (`specs/1.0.10-beta/06-onze/49-onze-stand-up`, F1–F10) add a
cell each: `modules/pub_val_in_a_test` (F1 — a sibling's `pub val` read by a TEST: the erlang runner
did not load the sibling; the first project cell of the test kind), `modules/import/cases/import_type_closure_across_modules`
(F2 — `import {Canvas}` from a local dependency whose fields name types of the package's other
modules), `modules/unwrap/cases/unwrap_or_positions` (F4/F9 — `xs.at(i).unwrapOr(d)` in a method, as the branch of
a parenthesised `if` read with `.v`, nested in another `unwrapOr`, over an unannotated `map`),
`modules/src_at_package_root` (F5 — `"src": "."`, a test importing `lib.db`),
`modules/string/cases/string_slice_in_if_branch` (F6 — a one-argument `slice`, an array `slice` and a string
template as the value of an `if` branch), `modules/integer/cases/integer_division_truncates` (F7 — integer `/`
truncates toward zero on every target, float `/` stays float) and `modules/lexer/cases/lexer_error_in_imported_module`
(F8 — every target refuses the project with `bad string escape` located in the imported module, via
its snapshot). The erlang float-literal item adds `modules/float/cases/float_literal_spellings` (`1e3`,
`2.5E3`, `3e+2`, `5e-1`, `1_000.5` are `f64` on all four targets) and
`modules/number/cases/number_literal_erlang_spellings` (`5e-324`, the largest `f64`, an `f64` record field and
`0xFF + 0b101 + 0o17`, on all four targets — wasm since its float literal is an `f64.const` and its
radix literal a decimal `i32.const`).
144's cascading-diagnostic row adds `modules/import/cases/import_of_failed_module` (`shapes.bp` holds a type error,
`main` imports `area` from it): `shapes.snap` claims the type error and `main.snap` the one
`import-of-failed-module` refusal at the import item, naming `shapes` (`` `area` comes from `shapes`,
which failed to check ``) — the parent binary refused
`main` with `unbound variable 'area'` at the use, and an importer of `main` would have done the same.
The importer snapshots of `lexer_error_in_imported_module`, `imported_declaration_error_location`
(`b/b` and `main`), `bpp_decorator_last_line` and `bpp_diagnostics_located` moved with it — each
claimed the cascade's `unbound variable`; the refused module's own snapshot is unchanged.
The backend and runtime rows of `00` (`front/codegen-rows`) add a cell each, every one failing on the
parent binary: `modules/task/cases/task_await_in_if_block` (an `if` block that `await`s without returning, inside a
`@Async` body — commonJS lowered it into a plain arrow and the module did not load),
`modules/task/cases/task_void_return_in_if_block` (a bare `return;` in an `if` block of a `@Async<void>` body — wasm
emitted a `return` with nothing on the stack), `modules/dependency/cells/dependency_files_order` (a dependency whose
`files` lists every importer before what it imports, `import {a.base};` and `import {leaf.Leaf};`),
`modules/external/cells/external_erlang_host_module_missing` (`"targets"` `erlang beam`: an `.Erlang` module that is
neither shipped nor in the Erlang code path is a located build error on both, `snapshot/targets/erlang/` and
`snapshot/targets/beam/`),
`modules/erlang/cells/erlang_host_sidecar_shipped` (a project's `src/sidecars/*.erl` reached by `botopink run` on
erlang and on beam; `snapshot/targets/commonJS/` and `snapshot/targets/wasm/`), `modules/erlang/cells/erlang_sidecar_named_like_a_module` (a
sidecar `text.erl` beside the module `text.bp` is shipped — the shipper skipped a basename match),
`modules/sidecar/cells/sidecar_called_from_folder_module` (front 26, T16: a sidecar called only from `src/orm/entity.bp`
is shipped on erlang and beam although the cell's own `libs/orm/` — a library root the walk-up finds —
carries a package named like the folder; the shipper took that package for the module's owner) and
`modules/sidecar/cells/sidecar_named_like_emitted_atom` (front 26, C-25: `src/sidecars/sidecar_named_like_emitted_atom@text.erl`, named
like the atom `src/text.bp` compiles to, is a located build error on erlang and beam naming both,
`snapshot/targets/erlang/` and `snapshot/targets/beam/`), `modules/decisions-taken/prelude_is_primitives-606/cases/bare_print_call` (`print(x)` without its import is unbound
and the refusal names `import {io.terminal.print} from "std"`, decision 606 (2)), `modules/float/cases/float_record_field` (an `f64` record field read, compared,
destructured by name and by constructor, and through a method taking and answering an `f64` — wasm
narrowed and bit-read it, erlang and beam did not lower `val Pt(y, _) = p`) and
`modules/linked/cases/linked_fn_name_collision` (two modules each declaring `parse`, reached by their own calls, a
plain import and an aliased one — wasm's one flat namespace). `modules/val/cases/val_assert_record_pattern` (a
`val assert` over a record's constructor pattern — commonJS destructured the binders' own names,
erlang tested a tag no constructor builds) came out of the same work; wasm and beam followed.
C-04 across a module boundary adds `modules/default/cases/default_argument_across_modules` — a call omitting
trailing defaulted parameters of a sibling module's and of a path dependency's function, one label
claiming its parameter, on all four targets — and `modules/default/cases/default_argument_open_across_modules`: a
default that names a private function of its module does not travel, so omitting it from another
module is the arity error, on every target (its snapshot).
The rakun rows of `language-gaps.md` (the language-gaps sweep, `front/compiler-gaps-rakun`) add a
cell each, every one failing on the parent binary: `modules/behavior/cases/behavior_method_by_receiver_type` and
`modules/behavior/cases/behavior_method_host_value` (a method a `behavior` declares is the VALUE's, beside another type
declaring the same name — an implementer's, a host-built one, on an unannotated local; the
host-built one's `"targets"` is `commonJS erlang beam`, wasm having no host vocabulary for it), `modules/behavior/cases/behavior_method_imported` (the
same for an imported behavior; `snapshot/targets/wasm/`), `modules/behavior/cases/behavior_value_from_implementer` (an implementer
converts to its behavior at an annotated `val` and a `var`), `modules/behavior/cases/behavior_across_modules` (an
imported behavior is the same type in its importer; an imported fn-type alias resolves its names in
its own module), `modules/return/cases/return_nested_in_if_block` and `modules/return/cases/return_in_case_arm_statement` (a `return`
at any depth of a statement ends the function), `modules/result/cases/result_method_throw` (a METHOD returning
`@Result` wraps its `throw` / `return`), `modules/test_in_subdirectory` (a test file in `test/unit/`
reaches the project on erlang), `modules/record/cases/record_method_named_length` (a type's `length` method never
answers an array's `length`), `modules/imported/cases/imported_fn_field_call` (a function-typed field of an imported
record is applied), `modules/method/cases/method_on_unimported_type` (a method on a value whose type the module
never imported: std's `Dict`, and another imported type declaring the same method),
`modules/method/cases/method_missing_argument`, `modules/method/cases/method_extra_argument` and `modules/method/cases/method_default_argument` (a
method call's arity), `modules/result/cases/result_pattern_beside_enum_variant` (`Error(e)` over a `@Result` beside an
enum declaring `Error`), `modules/decorator/cases/decorator_calls_module_function` and
`modules/decorator/cases/decorator_imported_calls_module_function` (a decorator body calls its module's
functions), `modules/decorator/cases/decorator_emitted_proxies_dispatch` (two proxies a decorator emits call their own
types) and `modules/decisions-taken/shorthand_import_refused-337/cells/namespace_import_module` (decision 107's namespace form over a dependency's
module and the project's own).
The second language-gaps sweep (`front/gaps-sweep-2`) adds a cell per row it fixed, every one
failing on the parent binary: `modules/result/cases/result_void_falls_off_end` (decision 2 over an effect return —
a `@Result` in any layer, `@Result<void, E>` included, and a `@Async` / `@Component` whose value is a
value, end with `return`), `modules/narrowed/cases/narrowed_optional_std_field_across_packages` (a method chain on a
field of a narrowed optional, and of an optional binder, whose type another package declares and
this module never names — its field a std type only that package imports;
`modules/generic/cases/generic_type_through_imported_function` keeps two instances of such a generic type apart),
`modules/decorator/cases/decorator_argument_default` and `modules/decorator/cases/decorator_default_not_closed` (a decorator
argument the annotation leaves out takes its closed default; one naming a binding is refused at the
annotation), `modules/decisions-taken/record_field_assignment_refused-37/cases/record_update` and `modules/decisions-taken/component_props_plain_or_rest-529/cases/record_update_base_not_a_name` (decision 37's
`Name(..base, f: v)` builds the record it means on every target; the base is a name or a path of
names), `modules/explicit/cases/explicit_type_arguments_on_a_method` and
`modules/explicit/cases/explicit_type_argument_on_a_method_disagrees` (decision 8 §1.3 at a method call,
`ctx.resolve<T>()`), `modules/decisions-taken/package_imports_itself_by_path-309/cases/std_module_imports_std_module` (`querystring` imports `encoding`'s
percent codec; on four targets since `01-compiler/05-wasm` step 5) and `modules/bodyless/cases/bodyless_method_without_binding` (a
bodyless method with no host binding is refused at the call on every target, its snapshot).
The checker rows of `front/checker-rows` add a cell each, every one failing on the parent binary
(or, where noted, pinning a rule the parent already held): `modules/self/cases/self_param_free_fn` (`self`
outside a type or behavior body is `self-param-outside-type`, at the name — jhonstart's
`repro/self-param-free-fn`), `modules/decl/cases/decl_type_name_spelled` (the declaration handle's type names spell the type:
`Array<string>`, `string[]`, `fn(i32) -> i32`, `#(string, string)`, `?i32`, a method's parameters
and return), `modules/reserved/cases/reserved_word_field_name` and `modules/reserved/cases/reserved_word_param_name`
(`reserved-word-as-name`, naming `from`), `modules/external/cells/external_wrapper_keeps_refusal` (a wrapper around a
single-target host call inherits no restriction — refused on commonJS and wasm by
its snapshot even though nothing calls it; the parent held this rule, and decision 146
made wasm hold it — `modules/external/cells/external_wrapper_associated_default` is the same rule on a behavior's
associated `default fn`, which wasm lowered only when a call reached it),
`modules/behavior/cases/behavior_array_of_implementers` (`Array<Plugin>` of two implementers; `"targets"`
`commonJS erlang beam`, wasm answers `a a b b`), `modules/import/cases/import_from_package_beside_same_name`
(a project `pub fn attempt` beside another module's `import {match.attempt} from "pkg"`; wasm
listed, the flat namespace), `modules/host/cells/host_array_slice_without_start` (commonJS's global `slice`
patch reads a missing start as 0; `"targets"` `commonJS`), `modules/decorator/cases/decorator_calls_imported_function`
and `modules/decorator/cases/decorator_imported_function_name_conflict` (a decorator carries a function its module
imports, and two functions of one name reaching one decorator are refused where it is applied),
and decision 112's three rows — `modules/decisions-taken/dsl_names_resolve_in_author_scope-112/cases/dsl_hygiene_private_helper`,
`modules/decisions-taken/dsl_names_resolve_in_author_scope-112/cases/dsl_hygiene_consumer_alias` and `modules/decisions-taken/dsl_names_resolve_in_author_scope-112/cases/dsl_hygiene_consumer_double`, each printing `40`
(the third's wasm line is the flat namespace's).
The checker rows of `front/checker-rows-2` add a cell each, every one failing on the parent binary except where noted:
`modules/builtin/cases/builtin_noreturn_any_position` (`@todo()` / `@panic(…)` are `noreturn`, the bottom type — a
`return` of a `-> i32` function, an annotated `val`, an `if` branch and a call argument; on all four
targets), `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/builtin_module_not_lowered` (`@module()` is `builtin-not-lowered` at the `@`),
`modules/enum/cases/enum_variant_duplicate` (a variant written twice at one level, at the second),
`modules/enum/cases/enum_section_leaf_beside_variant` (a section leaf `Layout.Break.After` beside a top-level
`After(inner: Token[])`, each reached by its path or its position's type from another module —
the checker half already held; wasm, whose `case` read the leaf's tag, followed),
`modules/variant/cases/variant_leading_dot_two_enums_case` (two enums declaring `Red`, `.Red` by the position's type
and a `case` over each — the checker half already held; wasm followed),
`modules/section/cases/section_path_es4_expected_enum` / `modules/section/cases/section_path_es4_every_head` (ES4 names the
expected enum, or every enum carrying the head, sorted — it named the hash walk's first),
`modules/labelled/cases/labelled_call_by_label` (a complete labelled call by label on the associated, imported,
namespace and `"std"` call paths, and a namespace call filled from its default; the `"std"` path is
`testing.asserts`, which does not build on wasm — `snapshot/targets/wasm/`, the refusal at the import),
`modules/label/cases/label_on_function_value` (a label in a call of a function value, `label-on-function-value`),
`modules/behavior/cases/behavior_from_host_declare` (a host `declare fn -> Greeter`, here and in a third module,
meets a `Greeter` parameter of the behavior's module — the checker half already held; wasm refuses
the host templates by `snapshot/targets/wasm/`), `modules/decisions-taken/shorthand_import_refused-337/cases/shorthand_import_several_candidates` (a bare `import {parse};` over two
modules declaring `pub fn parse` — decision 337's `shorthand-import` at the item, both candidates
written, on every target by its snapshot; it was `import_ambiguous_use`, the use refused, and
its sibling `import_ambiguous_unused` — the import unread compiled — is gone with the shorthand),
`modules/std/cells/std_decorator_through_namespace` (`#[mocks.mock]` after `import {testing.mocks} from "std"`
gives `Repo` the factory `Repo.mock()` and its stubs answer; wasm refuses the import by `snapshot/targets/wasm/`),
`modules/std/cells/std_decorator_unknown_through_handle` (`#[mocks.mokc]` is `unknown-annotation`), `modules/annotation_not_decorator_{unbound,namespace,value}` (a bare `#[name]` naming no decorator is `annotation-not-a-decorator`),
`modules/std/cells/std_decorator_leaf_import` (`import {testing.mocks.mock}` is `std-decorator-leaf-import`),
`modules/pipeline/cases/pipeline_call_fill` (`lhs |> f(args…)` is `f(lhs, args…)` on every target, and a pipeline takes
defaults and labels, at expression and statement position) and `modules/case/cases/case_bool_literal_arms` (`true` /
`false` arms are the bool literals, beside a guard — every backend bound them as names). C-16's
`test/case_arms.bp` writes its range arm `1...9` (decision 53) and passes on commonJS and erlang.
The residual backend rows (`front/residual-backend-3`) add a cell each, every one failing on the
parent binary on the targets named: `modules/generic/cases/generic_call_result_shape` (a generic `-> T` call answers
its argument's shape, `unwrapOr` its default's — wasm printed a string's address),
`modules/unit/cases/unit_enum_print_by_name` (an all-unit enum's value by name, a field, an array, a `?Color` whose
present first variant is not absent — wasm printed the ordinal or trapped),
`modules/decisions-taken/multi_subject_bare_name_refused-602/cases/case_multi_subject_patterns` (a multi-subject `case` over literals, strings, type arms, variant
payloads and guards over the subjects (a bare name is refused, `modules/decisions-taken/multi_subject_bare_name_refused-602/cases/case_multi_subject_bare_name`, decision 602) — wasm answered the first arm, beam matched a string or a type arm on anything,
commonJS never bound a variant's payload), `modules/case/cases/case_or_pattern_alternatives` (an or-pattern
over unit variants, numbers, strings, payload variants with a wildcard, a literal or a label and
`..`, a guarded arm, tuples, a range and a block arm — beam tested a number alternative alone, so
`C | D -> true` answered `false` and `A | B` raised `case_clause`), `modules/behavior/cases/behavior_implemented_by_enum` (an enum implementing a
behavior, called through a value of the behavior — commonJS, erlang and beam),
`modules/behavior/cases/behavior_method_result_chained` and `modules/behavior/cases/behavior_method_result_typed` (a behavior method's
call answers its declared type, so a primitive method chains on it — commonJS called `length`,
wasm trapped), `modules/external/cases/external_template_escaped_quote` (a `\"` in an `.JavaScript` template is a
quote of the JavaScript; `"targets"` without wasm), `modules/std/run/src/cases/std_path_relative` (a std module calling an
`Array` `default fn` — commonJS had no prototype method), `modules/if/cases/if_value_float` (an `f64` value `if`
outside an `f64` function — wasm refused the module, commonJS printed `0`) and
`modules/linked/cases/linked_val_name_collision` (a module-level `val` and `var` two linked modules declare, read,
written, imported under an alias and shadowed by a parameter — wasm read the first one).
`modules/val/cases/val_assert_record_pattern` gained the labelled form (erlang bound it by position).
`modules/hof/cases/hof_named_function` (a local, an imported and a bound function named as an array method's
argument — wasm trapped), `modules/generic/cases/generic_body_specialized` (a method on a type-parameter value, a float
through one, a behavior's generic associated fn and `Dict<string, string>.at` over a key built at
run time — wasm answered from one word-typed body) and `modules/imported/cases/imported_fn_as_value` (handed over by
`front/residual-checker-3`: erlang and beam lowered the name as an unbound variable) close the
backend halves the checker front listed.
| `run.sh` | the runner | — |

Decision 280 (`01-checker` step 24, typed comptime decorator arguments) adds, on all four targets,
`modules/decisions-taken/comptime_parameter_is_expression-364/cases/decorator_arguments_check` (example 1 of `01-checker/examples/decorator-arguments-280.md`: a
function `rule`, a field key `at: .confirm`, a variant `code: .Mismatch` and the function form),
`modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_decl_pattern` (`syntax decl: fn(e: E) -> unknown`), `modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_type_argument`
(`comptime t: anytype`), `modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_function_arguments` (`paths:` / `head:` typed by the page's
`P`, `D`), `modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_record_argument` (`Cache<T>` through a module `val`),
`modules/decisions-taken/field_type_from_std_types-308/cases/decorator_field_keys` (`index(.state, .name)`, `unique(.code)`, the field's annotations in the
key) `modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_argument_values` (an array keeps its length, defaults, labels, a variant) and
`modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_typed_arguments_import` (an imported decorator's `Type.Field<T>` and enum, the
importer importing neither),
and 19 refusal cells, each at the argument unless named: `decorator_param_not_comptime` (at the
parameter), `comptime_default_outside_decorator` (at the default), `decorator_value_not_comptime` (renamed by 364),
`decorator_arg_unbound_function`, `decorator_arg_function_mismatch`, `decorator_arg_unknown_field`,
`decorator_arg_label_unknown`, `decorator_variant_case`, `decorator_field_key_{unknown,case,too_many}`,
`decorator_function_argument_mismatch`, `decorator_record_argument_{mismatch,string}`,
`decorator_type_argument_{unknown,string}`, `decorator_decl_pattern_{mismatch,return}` (at the
annotation) and `decorator_check_without_rule_not_bool` (the body's `decl.fail`, at the annotation).
`modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_argument_kind` now carets the argument with the typed mismatch, and every
decorator of the cells writes its parameters `comptime`.

Decision 364 (`01-checker` step 35) gave every `comptime` parameter a value read (`x.value`; since decision 575 (4) a `comptime x: T` is written and read
bare, a `syntax x: T` holds a tree), rewrote every `comptime` parameter of the suite to it (a value-or-type
parameter keeps `x is type`; a `Box<T>`'s field is `s.value.value`), and adds, on the four targets,
`modules/decisions-taken/comptime_parameter_is_expression-364/cases/decorator_expr_value` (`.value` of a string, a number, a `bool`, a variant, a record, a field
key and an array in a decorator; an ordinary function's `n.value`, specialised; a template's
`compiler.text(q)` of a literal) and `modules/decisions-taken/comptime_parameter_is_expression-364/cases/decorator_expr_unread_argument` (an argument not known
at build whose parameter the body never reads is accepted), and the refusals
`modules/decisions-taken/comptime_parameter_is_expression-364/cases/decorator_value_not_comptime` (`message.value` of
`env("MSG")`, at the call — the old `decorator_arg_not_comptime`), `modules/decorator_call_expr_fn`
(`rule.value(…)`, `expr-value-of-function` — the cell and the code went with decision 735), `modules/decisions-taken/comptime_parameter_is_expression-364/cases/decorator_inspect_expr_type` (`t.value`,
`expr-value-of-type`), `modules/decisions-taken/comptime_parameter_is_expression-364/cases/decorator_expr_fail_at_argument` (`max.fail(…)` at the argument),
`modules/decisions-taken/expr_decl_removed_compiler_templates-576/cases/expr_param_method` (`message.text()` on a `syntax` parameter, decision 576 (2)), each red
on the parent binary; `template_value_not_known` went with the holes (decision 577 (5)). Decision 577 (5) also deletes the cells that read a hole's
value at build (decision 355): `hole_any_call_at_build`, `hole_any_call_raises`, `hole_known_at_build_raises`,
`hole_imported_val_known_at_build`, `styled_holes_known_at_build`; `modules/decisions-taken/template_called_with_raw_text-577/refused/src/cases/template_hole_typed_at_caller` holds
14s8-a (e)'s remaining rule (a hole the template parses is spliced and typed at the caller, a mistyped one refused
at the hole through its `CustomNode` span, `infer.zig` `parseCodeTextAt`); `modules/decisions-taken/template_hole_error_at_column-691/cases/template_hole_error_at_column`,
`modules/decisions-taken/template_called_with_raw_text-577/refused/src/cases/template_hole_error_on_later_line` and `modules/decisions-taken/template_called_with_raw_text-577/refused/src/cases/template_hole_error_far_in_built_code` pin where an error in
code built from a hole lands — at the hole's expression in the caller's text, after the two-byte `` @` ``, on its own
line of a multi-line text, wherever the code puts it (`copiedAt`), each red on the parent binary. `modules/decisions-taken/comptime_parameter_is_expression-364/cases/decorator_arguments_check` and
`modules/decisions-taken/decorator_arguments_typed_comptime-280/cases/decorator_check_without_rule_not_bool` tell the function form by `decl.kind` (a `syntax` parameter
of a function has no value, question `s35-b`).

Decision 370 (2) (`01-checker` step 35 box 3) — a decorator hands its parameters' trees on to the
program through a typed member, `decl.addMember(name, fn(self: T) -> R { … })` — adds, on the four
targets, `modules/decisions-taken/decorator_expr_typed_channels-370/cases/decorator_expr_rule_called` (`rule` is `passwordsMatch`, called by `validate` at run
time), `modules/decisions-taken/decorator_expr_typed_channels-370/cases/decorator_expr_message_runtime` (`message` is `t("signup.mismatch")`, evaluated at run
time each time the member reaches it, never at build), `modules/decisions-taken/decorator_expr_typed_channels-370/cases/decorator_member_fn_import` (a member
of a decorator in another module, reading only its parameters and locals) and
`modules/decisions-taken/member_names_resolve_where_written-384/cases/decorator_member_fn_imported_name` (one naming a type and a private helper of the
decorator's module — decision 384: each resolves there, the user's own same-named helper is not
captured; it was `decorator-member-fn-imported-name` on the parent binary), and the refusals
`modules/decisions-taken/decorator_expr_typed_channels-370/cases/decorator_member_not_fn`, `modules/decisions-taken/decorator_expr_typed_channels-370/cases/decorator_member_fn_untyped`,
`modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decorator_member_captures_handle` (`decl`, a run cell since decision 716 (3): the member's
`decl.title()` is `Signup.title()`) and `modules/decisions-taken/decorator_expr_typed_channels-370/cases/decorator_member_type` (a field's
`fn(self: T)`, `T` the field's type), each red on the parent binary. Decision 575 (4)'s tree rule
turns `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/decorator_member_captures` (a local of the decorator's body) from a refusal into the
literal the member holds (`member_fn.capturedLocals`).
Decision 669 — the names of a member a decorator writes as text, `compiler.addMember(source)`, resolve in the
decorator's module, its imports included: `modules/decisions-taken/decorator_code_resolves_in_decorator_module-669/cases/decorator_member_reaches_decorator_imports` (the member calls
`panic` and `print`, which only the decorator's module imports — `unbound variable 'panic'` on the parent binary,
four targets).
Decision 575 (3) (`compiler.init`, 144 B-137) adds `modules/decisions-taken/no_declaration_files_compiler_value-575/cases/init_executor_before_main` (executors of a
function, a type with two annotations and a `val`, two calls per body, one named and one a `syntax` parameter,
each run before `main`, four targets), `init_order_modules` (dependency order across two modules and
`main`, an executor writing a registry `var`), `init_executor_from_library` (a library's decorator whose
executor calls a private helper of its module, and a library module's own executor run in the program) and the
refusals `init_executor_captures_build` (`compiler` inside an executor, `syntax-captures-build`; decision 614 made it
`init_executor_reads_compiler`, the read evaluated at build, `out home`) and
`init_output_outside_decorator` (`compiler-output-outside-decorator`) — each red on the parent binary, where
`compile` was no member of `Compiler`. Decision 615 renamed the member `compiler.init` and these cells, and their
siblings, from `compile_executor_*` / `compile_init_order_modules` / `compile_output_outside_decorator` to
`init_executor_*` / `init_order_modules` / `init_output_outside_decorator`.
Decisions 610 and 621 (144 B-138, a source's fields) add the refusals `modules/decisions-taken/body_cell_botopink_body-610/cases/external_body_not_a_fn`
(`.Wasm(body: f)` naming a `pub` fn, at the argument), `external_source_empty` (`.Erlang()`, at the argument),
`external_all_bodies` (every source a `body:`, at the annotation) and `external_flag_bare_fn_refused`
(`.Erlang("…", f)`, `external-field-unlabelled` at the argument); `external_flag_bare_bool_refused` answers
`external-field-unlabelled` on `.JavaScript`; `external_wasm_fn_cell_string` and `external_wasm_fn_cell_signature` answer
`external-body-not-a-fn` at the argument; `external_fn_body_every_target` and `external_result_on_fn_cell` write a
template on one target beside their `body:` cells, so neither is all bodies. Decision 618 renamed `.JavaScript` to
`.JavaScript` in every cell (`scripts/codemod/implementation_javascript.py`).
Decision 642 (144 B-137) extends 614's fold to every tree a decorator hands the compiler: `modules/decisions-taken/compiler_call_in_tree_evaluated_at_build-642/cases/member_reads_compiler_name`
(`out Users`), `modules/decisions-taken/compiler_call_in_tree_evaluated_at_build-642/cases/member_names_its_parameter` (`compiler.name(x)`
over the member's own parameter, `out x`) and `modules/decisions-taken/compiler_call_in_tree_evaluated_at_build-642/cases/member_reads_compiler_text` (`out always`; it was
`expr_captures_build`, a `syntax-captures-build` refusal that decision 642 removed); `modules/decisions-taken/compiler_call_in_tree_evaluated_at_build-642/cases/init_executor_compiler_arg_at_run_time`
refuses a `comptime` position (`compiler.typeInfo(s)`), where `compiler.text(s)` is accepted, and
`modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decorator_member_captures_handle` reads the handle itself, the annotated type as code (decision 716 (3)).
Decision 716 (144 B-137) makes the `syntax decl` parameter's declared type the contract: `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decl_unknown_no_member`
(`unknown` gives no member, refused at the decorator), `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decl_behavior_contract_refused` (refused at the annotation),
`modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/decl_behavior_member_typed`, `modules/decisions-taken/decorator_decl_parameter_type_is_contract-716/cases/member_decl_as_code`; the `init_executor_handle_*` cells write
`syntax decl: fn() -> string` (or the behavior `Service`), and `_mistyped` / `_on_type_as_value` are refused at the
annotation by the contract. Decision 759 names the refusal of a body local whose value is no literal, read in a member or an executor,
`decorator-member-local-not-literal` (`modules/decisions-taken/decorator_member_local_not_literal-759/cases/decorator_member_local_not_literal`); the wrapper's `decorator-member-captures`
goes with the wrapper (B-139).

Decision 408 (144 B-21, `01-checker` step 37) made the typed function expression legal in every
position — `modules/fn_expr_typed`, its refusal anywhere but `decl.addMember`, is gone — and adds
`modules/decisions-taken/typed_fn_expression_any_position-408/cases/fn_expr_typed_anywhere` (a `val`, a `var` assigned twice, a `map` argument, a `fn`-typed
parameter's argument, a return, an annotated `val`, one answering nothing — four targets; beam
lowered every `fn(…) { … }` expression to `undefined` on the parent binary) and
`modules/decisions-taken/typed_fn_expression_any_position-408/cases/fn_expr_typed_mismatch` (a `string` parameter where `fn(x: i32) -> i32` is expected, refused
at the expression naming both function types). Decision 409 (step 38) — a function body's last
expression written without `;` is its value — adds `modules/decisions-taken/function_return_type_written-622/cases/fn_tail_value` (a tail, an early `return`
before one, an `if` / `else` tail, a generic one, a `val` before one, a `return x;` body beside them),
`modules/decisions-taken/fn_tail_value-409/cases/method_tail_value` (a method, an associated function, a generic type's method),
`modules/decisions-taken/fn_tail_value-409/cases/fn_expr_tail_value` (typed and untyped function expressions, a lambda) and the refusals
`modules/decisions-taken/fn_tail_value-409/cases/fn_tail_type_mismatch` (`"a"` where `-> i32` is declared, at the tail),
`modules/decisions-taken/function_return_type_written-622/cases/fn_tail_in_void` (an `i32` tail in a body declaring no return, at the tail) and
`modules/decisions-taken/fn_tail_value-409/cases/fn_expr_tail_semicolon` (`fn(x: i32) -> i32 { x + 1; }`, at the expression); each red on
the parent binary. B-21's Conformance step adds, red on the group's base: `modules/decisions-taken/fn_tail_value-409/cases/fn_tail_after_loop_return`
(a tail after an early `return` from a `for`, a statement `case` and a `while`),
`modules/decisions-taken/fn_tail_value-409/cases/fn_tail_if_else_chain` (an `if` / `else if` / `else` tail), `modules/decisions-taken/fn_tail_value-409/cases/fn_tail_case_arm_block` (a
tail naming a `case` bound by a `val`, an arm answering a typed function expression with a tail),
`modules/decisions-taken/fn_tail_value-409/cases/fn_tail_void_call` (a `void` tail in a function, a `-> void` function, a method and a lambda),
`modules/decisions-taken/fn_tail_value-409/cases/method_tail_in_void` (an `i32` tail in a method answering nothing, at the tail),
`modules/decisions-taken/fn_tail_value-409/cases/fn_tail_comptime` (tails evaluated by `comptime`), `modules/decisions-taken/fn_tail_value-409/cases/fn_tail_result` (a tail in a
`-> @Result<i32, string>` function after a `throw` and a `try`), `modules/decisions-taken/typed_fn_expression_any_position-408/cases/fn_expr_typed_in_record_field`
(a record field's value and an array element beside a lambda), `modules/decisions-taken/typed_fn_expression_any_position-408/cases/fn_expr_typed_field_mismatch`
(refused at the expression), `modules/decisions-taken/fn_tail_value-409/cases/decorator_member_fn_tail` (a `decl.addMember(name, fn…)` member
answering its tail) and `modules/decisions-taken/lambda_answers_last_expression-541/cases/lambda_last_statement_semicolon` (decision 541 (1): a lambda answers its last
expression written without `;`, one with `;` answers nothing and stands where `fn(i32) -> void` is expected; an
untyped `fn(x) { … }` keeps the value of its last statement — beam lowered the untyped `fn` expression to
`undefined` on the base), with its refusal `modules/decisions-taken/lambda_answers_last_expression-541/cases/lambda_semicolon_not_a_value` (`fn(i32) -> i32` expected, at the lambda).
B-22 adds `modules/fn/cases/fn_value_in_tuple` (a function value read out of a tuple by position and called, its
arguments staged first — beam's frame did not count the stack slot the arguments park in while
`erlang:element/2` reads the function, `invalid_store` on the base).
`modules/fn/cases/fn_value_tuple_string_answer` (each element of `#(g, h)` keeps its function type — wasm printed
the string's address on the base) and `modules/fn/cases/fn_field_call_in_for` (`op.run(5).toString()` on a
`for` loop's element — wasm could not resolve `toString/0` on the base).

Decision 298 (`01-compiler/130` step 8) — typed meta keyed by its record type — adds, on the four
targets, `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_typed` (`decl.setMeta(Entity(…))` read `@typeInfo(City).meta(Entity)`, two
`decl.addMeta(Index(…))` read `metaAll(Index)`, every field shape written back — string, array,
float, `bool`, variant, optional —, `null` / `[]` for a type nothing recorded),
`modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_typed_catalogue` (`d.meta(Entity)` / `d.metaAll(Index)` on `@TypeInfo.all` entries,
here and in a function of another module the entries are handed to),
`modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_catalogue_private_type` (`typeinfo-all-private` for a private meta record) and
`modules/decisions-taken/meta_expr_names_resolve_where_written-385/cases/meta_expr_read_elsewhere` (decision 385: `main` reads `signup`'s `Check` and `Note`, by
`@typeInfo` and through `@TypeInfo.all`, calling `signup`'s private rule and hint, its own
same-named functions not captured; it was `typeinfo-meta-expr-elsewhere` on the parent binary), and the
refusals `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_twice`, `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_not_record`, `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_field_type`,
`modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_several`, `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_read_not_type`, `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_add_outside_decorator`,
`modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_read_at_build` and `modules/decisions-taken/decorator_meta_keyed_by_type-298/cases/meta_catalogue_generic` (question `130-s8-d`). Decision 370
(1) adds `modules/decisions-taken/decorator_expr_typed_channels-370/cases/meta_expr_field` (`decl.addMeta(Check(message: message, rule: rule))`, `Check`'s
fields `syntax x: T`: the reader calls `rule` and evaluates `message` — `t("signup.mismatch")` — at run
time, never at build) with `modules/decisions-taken/expr_decl_removed_compiler_templates-576/cases/meta_expr_field_literal` and
`modules/decisions-taken/expr_decl_removed_compiler_templates-576/cases/meta_expr_param_plain_field` (`decorator-meta-expr-arg`). Each red on the parent binary.

Decisions 384 and 395 add, on the four targets, `modules/decisions-taken/typed_member_reads_own_meta-395/cases/member_reads_own_meta` (`#[validated]`'s
member reads `for (comptime @typeInfo(T).metaAll(Check))`, typed `Check<T>[]` in the decorator's
body and answered with `Conta`'s two `#[check]`s where the member is rendered; the rules and messages
run with the program) and `modules/decisions-taken/local_type_beside_aliased_import-603/cases/decorator_member_type_same_name` (a member naming its module's
`Violation` where the annotated module declares one: two types, the member's under its hygiene alias
— refused at the annotation, question B-23-a, until decision 603), and `modules/decisions-taken/member_names_resolve_where_written-384/cases/decorator_member_type_travels` (an importer of the annotated type calls the member whose signature names the decorator module's `Violation`, which the importer never imports; on wasm the linked module's hygiene alias resolves by `wat.zig` `linkRenames`). Each red on the parent binary.
Decision 311 (`01-checker` step 29 — the template annotation `` #[f @`…`] ``) adds, on the four targets,
`modules/decisions-taken/template_called_with_raw_text-577/cases/template_annotation`: a template `query(syntax q: string, syntax decl: unknown)`
written on a behavior's methods (`` @`…` ``, beside a decorator) and on a function, each
hole resolving to the declaration's parameter by name, the method's typed meta read by the
behavior's `#[repository]` on `decl.methods` (`m.meta(Query)`, `m.meta(Audit)`, question `s29-b`),
the function's by `typeInfo(logout).meta(Query)`, and `decl.params` on a method;
`modules/decisions-taken/bodyless_type_method_is_host_binding-311/cases/template_annotation_imported` (the template, a helper its body calls and the owner's
decorator declared in another module); and the refusals
`modules/decisions-taken/template_called_with_raw_text-577/refused/src/cases/template_annotation_call_form` (`#[f(…)]` naming a template), `modules/decisions-taken/bodyless_type_method_is_host_binding-311/cases/template_annotation_not_template`
(a decorator at `` #[f @`…`] ``), `modules/decisions-taken/template_called_with_raw_text-577/refused/src/cases/template_annotation_unknown_hole` (a hole naming no parameter —
the unbound-name error at the hole), `modules/decisions-taken/bodyless_type_method_is_host_binding-311/cases/template_annotation_without_decl` and
`modules/decisions-taken/bodyless_type_method_is_host_binding-311/cases/template_annotation_called` (question `s29-a`). Each red on the parent binary.
Decision 425 (a template call expands wherever an expression may stand, `01-checker` step 29) adds,
on the four targets, `modules/decisions-taken/template_call_expands_any_expression-425/cases/template_in_type_method`, `modules/decisions-taken/template_call_expands_any_expression-425/cases/template_destructuring_init` and
`modules/decisions-taken/template_call_expands_any_expression-425/cases/template_in_field_default` (a field's and a parameter's default) — red on the parent binary
(`twice is not defined` at run time) — and `modules/decisions-taken/template_call_expands_any_expression-425/cases/template_in_lambda`, `modules/decisions-taken/template_call_expands_any_expression-425/cases/template_in_argument`,
`modules/decisions-taken/template_call_expands_any_expression-425/cases/template_in_case_arm`, which the parent already expanded.
144 B-68 adds `modules/template/cases/template_answer_method` (a library template's answer, a type the consumer does not import: a method on its field),
red on the parent binary (erlang aborted, wasm refused `toString/0`).

Every cell is copied into its own scratch project, so a parse error fails only that cell. Test names
start with the decision-8 section they pin (`test "§5.4 …"`) when there is one, so a failure points at
the rule; a capability decision 8 does not legislate gets a plain sentence.

Areas, by filename prefix: `case_*`, `tuple_*`, `loop_*` (decision 8 §5, §6, §10), `effect_*`,
`comptime_*` / `decorator_*`, `external_*`, `generic_*`, `string_*` / `array_*`, `type_identity_*`,
`optional*` (`optional`, decision 980's `optional_case_null_and_binder` / `case_optional_variant_pattern_refused`, and
1.0.10-beta's `00 · 05-wasm` `modules/decisions-taken/shorthand_import_refused-337/cases/optional_record_carrier` — § `optional_record_carrier` below),
`context_use` / `use_*` (front 19 of 1.0.10-beta: `use` and `@Context`, two test cells, one run
cell and eleven reject cells), `index_*` (decision 63 as amended: `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_dict`,
`modules/decisions-taken/negative_index_counts_from_end-139/cases/index_past_the_end_is_null` — renamed from `…_fails` when C-02 landed, because the
amendment makes an index past the end `null` and not a failure — `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_at_optional`,
`modules/decisions-taken/negative_index_counts_from_end-139/cases/index_tuple` with `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_tuple_computed` and `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_tuple_out_of_range`
for the checker's one special case, and `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_user_type` — a `Matrix` and a `Registry`, the
library types that become indexable by answering `at` / `slice` with no compiler change, which is
the whole of what the rule is for), `std_erlang_node` (decision 64),
`panic_aborts` / `todo_aborts` (front 12 step 4.3), `external_erlang_only` (step 4.4),
`external_host_record` (a host-backed `declare fn` whose return type names a record — the erlang
templates deliberately build the pre-decision-21 `#{field => V}` map that an `.erl` sidecar in a
consumer library still builds, and the boundary adopts it; `"targets"` is `commonJS erlang beam`
because wasm has no host vocabulary for these templates — beam compiles the erlang templates at build
time and adopts the answer with its own `'__bp_adopt'/3`),
`external_method_*` (host-backed METHODS — a `declare fn` with `#[@external(.<Target>(…))]` inside a
`type` body, lowered as a real method of the type: `modules/decisions-taken/commonjs_variant_is_subclass_of_its_type-5/cells/external_method_local` — a record's template
methods naming `$0` and `$1`/`$2`, one called from a bodied method on `self`, the `(module, symbol)`
form, `inline: true`, an enum's host method — on commonJS, erlang and beam, refused on wasm by
`snapshot/targets/wasm/`; `modules/external/cells/external_method_erlang_only` — bound to Erlang only, refused where it is CALLED on
commonJS and wasm; `modules/external/cases/external_method_on_host_record` — a host method on a record the HOST built,
adopted directly, through `@Result` and through an array, and a lambda-parameter receiver whose
method shares `name/arity` with a module function (`"targets"` `commonJS erlang beam`, as
`external_host_record`'s); `modules/external/cases/external_method_imported` — the method on an IMPORTED type,
answered by its owner, with `snapshot/targets/wasm/`),
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
`from "std"` compiled as an ordinary dependency; one `modules/` cell and one `test/` suite,
§ `std_default_fn_in_a_std_module` below), and the
singletons (`closure_capture`, `recursion`, `expr_sugar`, `fn_defaults` (with `modules/decisions-taken/defaults_are_trailing-244/cases/fn_defaults_values`, the VALUE on all four targets, and `modules/missing/cases/missing_required_argument`, N2 — both 1.0.10-beta's C-04), the two `lambda_*` cells of
1.0.10-beta's `00 · 04-js` — `lambda_expression_body` (a lambda whose whole body is one expression
answers that expression's value) and `lambda_element_method` (a primitive method on a lambda's
parameter is the same method it is anywhere else), both measured by emilia's theme front and both
asserting the VALUE, because each defect was a wrong answer rather than a crash — and the
decision-28/30/33 cells `nullish_default`, `paren_receiver`, `type_suffix`, `bodyless_fn`,
`curried_call`, `index_expression`, and the two 1.0.10-beta `00 · 04-js` cells
`modules/labelled/cases/labelled_arguments` — a record constructor and an enum variant written out
of declared order, the rule being `conformance/docs.md` § Parameters with defaults, "a
parameter the call names by label keeps the argument it was given, whichever
position it is in"; the values are asymmetric so a positional zip is a wrong
ANSWER at exit 0 rather than a crash, which is how it hid — and
`modules/effect/cases/effect_method` — an effect annotation on a method, at its three
declaration sites: a record's own body, a record's `implement` block and an
enum's body; the fourth, a `behavior`'s `default fn`, cannot be written at all,
because the checker refuses `effect-on-behavior-method-forbidden`), and
`effect_chain` (1.0.10-beta front 20,
decisions 95 and 98: one `test/` suite, two running cells and five refusal cells; front 20
also adds `modules/use/cases/use_one_base` to the `use_*` area for
decision 96 (its `use_two_bases` refusal cell left with decision 354), `modules/option/cases/option_unwrap_or` + `modules/option/cases/option_expect_removed` to
`optional*` for F11, and `modules/decisions-taken/external_erlang_binds_beam-437/cases/external_inline_unread` to `external_*` for F9 — `inline` on
a variant whose emitter never reads it is refused at the annotation; 1.0.12-beta's front 140 step 2,
decision 334, adds `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cases/external_wasm_host_unknown`, `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cases/external_host_on_node`,
`modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cases/external_wasm_host_twice` and `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cases/external_wasm_host_beside_unhosted` — `host:` is
`.Wasm`'s, `.Wasi` or `.Browser`, one binding per host — with `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cases/external_wasm_host_binding`
(a `.Wasi` and a `.Browser` binding side by side, the `wasi` build lowering the first) and
`modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cells/wasm_host_from_manifest` (`"wasm": { "host": "browser" }` leaves a `.Wasi`-only binding
unbound, `snapshot/targets/wasm/`); its step 6 adds `modules/decisions-taken/wasm_host_profiles_wasi_browser-334/cells/wasm_host_browser_runs` (a `browser` build run by
`node` through its loader, the `.Browser` binding read) and makes the wasm column two runs — `run.sh`'s
`exec_run` runs a wasm cell on the `wasi` host (wasmtime) and on the `browser` host (node), and a cell
whose two exit statuses or stdouts differ fails naming both; a project cell whose botopink.json names
`"wasm"` runs on that host alone); its steps 4–5 (decisions 392–394: `@Async` on wasm a resumable
state machine over the scheduler, one adapter list for both hosts) add `modules/decisions-taken/one_adapter_list_both_hosts-394/cases/wasm_host_async` (`delay`,
`race`, `raceOf`, `spawnAll` declared with std's Node and BEAM bindings and the `wasi:` adapters —
`raceOf` answers the first thunk to settle, `"b"` on every target and both hosts),
`modules/decisions-taken/task_behaves_as_promise-392/cases/task_starts_when_made` (a task runs to its first `await` when made, settles once),
`modules/decisions-taken/task_behaves_as_promise-392/cases/task_resumes_in_place` (loops, `if`, `try`, `try … catch`, a method, a generic fn and an
`async { }` block suspending on a real timer), and two wasm refusals with `snapshot/targets/wasm/` —
`modules/decisions-taken/task_behaves_as_promise-392/cases/task_await_after_call_refused_on_wasm` (a call before an `await` in its statement) and
`modules/decisions-taken/host_adapter_answers_generic_task-393/cases/external_wasm_task_adapter_shape` (an adapter declared off its shape — refused on every
target since 144 B-23 read every `.Wasm` binding in the checker, beside
`modules/decisions-taken/external_wasm_binding_forms-238/cases/external_wasm_op_type_on_every_target` and
`modules/decisions-taken/external_wasm_binding_forms-238/cases/external_wasm_adapter_signature_on_every_target`, both run by the other targets' own
bindings on the parent binary); 144 B-25 (decision 334, `02/97` step 17) binds std's `async` on both
wasm hosts — `delay`, `race`, `raceOf`, `spawnAll` on the adapters, the gates on `.GateNew`,
`.GateOpen`, `.GateAwait`, `millisAsFloat` / `wholeMillis` on `op:` — and adds
`modules/decisions-taken/std_async_on_every_target-690/cases/std_async_on_every_target` (every combinator through the `async` namespace, results and answer
order only, 335 (2)), widening `modules/decisions-taken/async_block_is_closed_task_expression-124/cases/async_block_all_of` to wasm; and `enum_section_*` (1.0.10-beta's `00 · 01-checker`: which enum a
leading-dot section path names — `modules/enum/cases/enum_section_expected_type`, where two enums carry
`.Color.Red.500` and every spelling is resolved by the type its position expects, and
`modules/enum/cases/enum_section_ambiguous_path`, where the position expects nothing and the refusal names both
candidates, and `modules/enum/cases/enum_section_qualified_path`, where `Token.Color.Red.500` names its enum and
needs no expectation at all), `modules/case/cases/case_value_string_arms` (1.0.10-beta's `00 · 05-wasm`: a `case` used as a VALUE with string
arms, in BOTH arm spellings — the two took different paths through `wat.zig` and only the ARROW one
was a string, so `val a = case x { 5 { "five" } … }` printed the arm's heap address `256` on wasm at
exit 0 where the other three printed `five`; the `-> string` function form is `modules/case/cases/case_values`'
question and not this one, because a declared return type registers the shape on its own),
`modules/case/cases/case_arm_name_is_also_a_type` (§5.3b's collision: a
module declaring a record `Block` and an enum section carrying a `Block` leaf — the arm over the
section is the VARIANT, the arm over a union of records is still the type, and the cell asserts
both values on all four targets. commonJS tested only `instanceof`, so the section arm never
fired and the `case` answered `undefined` at exit 0, which is how emilia read 223/2 on commonJS
against 225/0 on erlang from one source), and `narrowing_*` (the same front's
`fix/null-narrowing`: which shapes of a null test rebind the name they test —
§ `narrowing_*` below), and the module-`var` cells of 1.0.10-beta's `00 · 17-beam-memory` (C-05, decisions 28, 38, 41, 43, 51): `modules/decisions-taken/reported_surface_forms_all_parse-28/cases/module_var` — a module-level `var` written twice through a `fn` prints `2` on all four targets (on erlang it was unbound `Hits` and did not compile, on beam the write was dropped and it printed `0` at exit 0 — C-10 lowered both); `test/beam_memory_noop` — the annotation was a no-op off the BEAM (decision 43; deleted when decision 167 made it a refusal there, `modules/decisions-taken/beam_memory_refused_off_beam-167/cases/beam_memory_off_beam`); and seven refusal cells, one per diagnostic — `val_assign_module` and `val_assign_local` (a `val` is immutable, the hint names `var`), `beam_memory_unknown_member`, `beam_memory_unknown_argument`, `beam_memory_keyed_scalar`, `beam_memory_keyed_list` (decision 51: `keyed` is `Dict`-only) and `beam_memory_on_val`. C-10 (front 17 step 4) adds the per-mode BEAM cells, each a `run/` cell with `"targets"` = `erlang beam` (a `test/` cell cannot be narrowed to a target, and on commonJS the modes are one program-wide value): `modules/decisions-taken/beam_memory_refused_off_beam-167/cells/beam_memory_process_dict` (a value written in `main` is not seen by a process `async.runAll` spawns, and its write does not reach `main` — `[0]` then `5`), `modules/decisions-taken/module_var_one_program_value-547/cases/beam_memory_ets` (decision 39's fixture: five processes × three increments print `15`) and `modules/beam/cases/beam_memory_persistent_term` (put at load, read by a spawned process: `[101]`); and the refusals its lowering needs — `modules/beam/cases/beam_memory_pt_write`, `modules/beam/cases/beam_memory_ets_recompose`, `modules/decisions-taken/module_var_one_program_value-547/cases/beam_memory_ets_bump_non_integer` (decision 40) and `modules/beam/cells/beam_memory_ets_initialiser` (a seed that is neither a literal nor `comptime`). 1.0.11 front 17 step 1 (decision 168) adds the keyed cells: `modules/decisions-taken/beam_memory_dict_literal_seeds-168/cells/beam_memory_ets_keyed` (`"targets"` `erlang beam` — two processes writing their own key 20 000 times each print `20000 20000`; the seed's repeated key reads its last value, a key with no row `null`), `modules/decisions-taken/beam_memory_dict_literal_seeds-168/cells/beam_memory_ets_keyed_seed` (a seed that is neither `Dict.empty()` nor `Dict.ofEntries([…])` of literals), `modules/decisions-taken/beam_memory_dict_literal_seeds-168/cells/beam_memory_ets_keyed_recompose` (a row computed from the var's own rows, decision 40's §5(b) diagnostic) and `modules/decisions-taken/beam_memory_dict_literal_seeds-168/cells/beam_memory_ets_keyed_whole_read` (a keyed var named anywhere but as its row read's receiver); none can pass on the parent binary: its seed rule refused `Dict.empty()` with the literal-or-`comptime` message, it refused `keyed: true` on the BEAM, and a `Dict` recompose was exempt. `modules/decisions-taken/reported_surface_forms_all_parse-28/cases/module_var` passes on erlang, and the three `run/beam_memory_*` cells and `modules/decisions-taken/reported_surface_forms_all_parse-28/cases/module_var` on beam (step 5). `01-checker` step 12 replaces `modules/variant/cases/variant_name_ambiguous` (an erlang-only emit refusal) with `modules/variant/cases/variant_name_ambiguous` — the checker refuses `.Circle` with no expectation on every target — and adds `modules/variant/cases/variant_leading_dot_expected` (the expected type decides `.Circle`; a qualified constructor is the enum written), `modules/section/cases/section_path_resolution` (a section leaf's shorthand, a payload section path through the annotated enum, a qualified section value) and `modules/section/cases/section_leaf_without_expectation`; each fails on the `feat` binary. `modules/template/cases/template_name_collision` (two modules exporting a template `tag`; the import from `loud` expands `loud`'s — the bare-name registry expanded `quiet`'s at exit 0) is 01 step 12's registry half. `modules/try/cases/try_catch_null_and_noreturn_narrowing`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_call_renders`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_call_awaited` (a written `await` of a component call inside a component body — jhonstart's layout chain) and `modules/try/cases/try_catch_handler_mismatch` are the maintainer's 24-box-1 rows (the guide's page example): `catch null` is a `?T`, a `noreturn` call narrows, a component called in a component body renders; each fails on the `feat` binary. `modules/labelled/cases/labelled_arguments_reorder` (a label names the parameter it fills in a complete call — fn, record, method, primitive method, self tail call) and the `modules/labelled/cases/labelled_arguments` erlang line's removal are 01's labelled-call row. 01 R7 (decision 2) adds `modules/fn/cases/fn_falls_off_end` and `modules/if/cases/if_without_else_value`, both accepted by the `feat` binary. C-18's decision 45 adds `modules/decisions-taken/optional_member_access_needs_safe_call-45/cases/member_of_optional` (a member read off a `?T` names `?.`) and moves `test/tuple_labels.bp` §6 T4 to `rs.at(0)?.b` — both targets pass it, the label is carried on commonJS and erlang. Decision 15's annotation grammar (front 17 step 3's recorded row) adds `modules/annotation/cases/annotation_unknown_family` (`#[@TotallyMadeUp.Nonsense(whatever: 42)]` on a `var`) and `modules/annotation/cases/annotation_family_misspelled` (`#[@BeamMemroy.Ets]` names `beamMemory`). Pending 0203-a, answered (b), adds `modules/primitive/cases/primitive_method_undeclared` (`s.toUpperCase()` names `toUpper`, the method whose host spelling it is) and `modules/primitive/cases/primitive_method_unknown` (`"x".fooBar()`, no near name), and re-spells `test/string_case_conversion` to `toUpper` / `toLower` — its erlang line is gone. `01-checker` step 13 adds the two cells of "a local ends with its body": `modules/local/cases/local_binding_escapes` (a `val` of one `fn` used by the next is refused at the use, naming `holder`) and `modules/local/cases/local_shadow_ends_with_body` (a local `p` shadows the module's `pub fn p` only inside its own `fn` — `3` then `p:x`); each was run with the `feat` binary and fails there as the step describes. One scenario group per
file: a parse error is the blast radius, so nine `#[@External]` declarations in one file mean one
unparseable annotation hides the other eight.

### The erlang backend's cells (1.0.11-beta `01-compiler/02-erlang`)

Each was run with the parent binary and fails there as its row describes.

- `modules/module/cases/module_fn_named_like_bif` (language-gaps T13): a module declaring `element/2`, `apply/2`,
  `length/1` and `hd/1` reads a record field, calls each of its own fns, prints a record and reads
  `Array.at` past the end — on all four targets. The erlang module did not compile (`element/2`
  is illegal in the print helper's guard once it is the module's own fn) and, before the
  `no_auto_import` directive, read `p.y` through the module's `element/2`.
- `modules/host/cells/host_template_binding_inside_while` (language-gaps T14, `"targets"` erlang beam — commonJS
  and wasm lack `bump`): an `.Erlang(…)` template binding `__Loop`, called in a `while`
  body and in a `for` body. Erlang's `while` recursed through a named fun `__Loop`, and the
  template's `__Loop = …` re-matched it — `{badmatch, 1}`.
- `modules/dependency/cells/dependency_module_level_print` (C-34): a dependency's two modules print only from a
  module-level `val`; `main` imports a value from one, its sibling `label` a type only from the
  other, and both bodies run first, on all four targets. Erlang's `'_botopink_init'/0` called a
  `'__bp_print'/1` the module never defined — `erlc` refused both dependency modules.
- `modules/string/cases/string_literal_unicode_escape` (C-36, STD-11 and the locale row): a `\u{…}` escape above
  U+00FF and a raw `ç` print as themselves, alone and inside an array, on all four targets. C-36's
  emitter half (`writeStringFromLexeme` writes a code point's UTF-8 bytes) was already landed, so
  the cell fails on the parent binary only under `LANG=C`, where erlang wrote `é` as `0xE9` and
  `\x{1F600}` as text; beam did too (`03-beam`'s twin, landing with the next integration). `.length()` of such a string is left
  out: commonJS counts UTF-16 units (`2`) and wasm bytes (`4`) — 04's and 05's rows.
- `test/is_truth_table` (C-07's erlang tail, decision 8 §4.1 × §4.2): each form that may follow
  `is` — `i32`, `i8`, `u8`, `f64`, `string`, `bool`, a record, an enum type, `Box<unknown>`,
  `#(i32, string)` — asked of the same ten `unknown` values, and §4.1's conversion inside
  `if (a is i32)`. `modules/is/cases/is_truth_table` is the same table on four targets, with tuple rows by
  arity and by element value (`#(2.0, "a") is #(i32, string)` holds); wasm refused it on the parent
  (`cannot box this value as unknown` for an `unknown[]` element, then no run-time test for a tuple
  type). §11's "erlang stores nothing" is `codegen/tests/control_flow.zig`'s needle (`A = 2.0,`, no
  box) — no program prints a difference, so it has no cell.
- `modules/decisions-taken/array_unique_keeps_first-217/cases/array_unique` (C-35, decision 217): `unique` keeps each value at its first occurrence over
  integers, strings, floats, bools and an empty receiver. wasm dropped only consecutive duplicates
  on the parent (`[1, 2, 1, 3, 2]`).
- `modules/case/cells/case_no_arm_matches_raises`: a `case` no arm matches raises `case_clause`; the value comes
  from a host function answering a value no variant is (the checker sees the `case` as exhaustive): an
  atom on erlang and beam, `({ tag: "Square" })` on commonJS. beam answered the subject at exit 0 and
  commonJS `undefined` on the parent (144 B-101: commonJS ends the `case` in an unmarked throw, `crash`).
  `output/` claims `stderr crash:` alone (question 546-a); wasm refuses the binding
  (`snapshot/targets/wasm/`).
- `modules/decisions-taken/shadowing_in_inner_blocks_refused-205/cases/lambda_binds_name_of_enclosing_fn` (decision 205): a `forEach` body's `val k` over an outer
  `k`, a lambda parameter `e` over an outer `e`, and a lambda value's parameter `e`; the outer names
  keep their values. erlc refused the module on the parent binary (`K@1` unbound). **Red on wasm**
  (`l l 1 2 6 2`: the inner bindings overwrite the outer ones) — 05's row.
- `modules/behavior/cases/behavior_default_adopted_by_two_types`: a behavior's `default fn` adopted by two types (one
  declaring the other default itself), called typed, through a default and through a behavior-typed
  parameter. erlc refused the module on the parent binary (`function twice/1 undefined`). **Red on
  beam** until 03's adopted-defaults commit lands and **on wasm** (it traps in `Sq_label`, 05's row).
- `test/erlang_host_sidecar_in_a_test` (test kind, narrowed to erlang and beam): a `test/` module that
  declares `#[@external(.Erlang("lt_greeter", "hello"))]` itself and calls it. It imports nothing, so
  its runner loaded no sibling and the call died `{error,undef}` on the parent binary.
- `modules/list/cases/list_pattern_spread_alone` (a row `03-beam` measured): `[..all]` as a `case` arm over three
  elements and over `[]`, and `val assert [..every]`, on all four targets. Erlang wrote the pattern
  `[All]`, a one-element list — `case_clause` and "assert pattern did not match" on the parent
  binary. The plain `val [..rest] = xs;` (which erlang also left unbound) is `01-checker` step 13's
  `modules/val/cases/val_spread_only_list_pattern`, refused by the checker until the backends lower it.
- `modules/decisions-taken/lambda_captured_var_write_refused-148/cases/captured_var_write_threaded` (decision 148, lg-b): the two lambdas that may write a
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
| `modules/narrowing/cases/narrowing_null_check` | `if (x != null)` over a `?Record` field, a `?string`, a `?T[]` and a `?i32`; `null != x`; `&&` narrowing BOTH names; the else side of `== null`; and that the narrowing ENDS with the branch |
| `modules/narrowing/cases/narrowing_null_guard_clause` | `if (x == null) { return …; }` and then the rest of the block — in a top-level `fn` and in a record METHOD, plus the `\|\|` form. Each function is called twice, present and absent |
| `test/narrowing_null.bp` | the same rules inside a `test` block, which is the third statement walk a program has |
| `modules/if/cases/if_optional_needs_a_binder` | the limit: `if (x)` on a `?T` with no binder is refused ("expected bool, got ?string" — the message spells the type as a source writes it). There is no truthiness on an optional |

**Shapes that do NOT narrow, measured and deliberate.** `while (x != null) { … }` leaves its body
alone: a condition loop reassigns the name it tests (`cur = es.at(i)`), and a narrowed `cur` would
red the assignment — narrowing it would break programs that work today. `if (o.inner != null)`
does not narrow either: only a plain NAME is rebindable. `case x { null { … } _ { … x! … } }` and `if (x)
{ v -> … }` narrow already, each through a channel of its own.

`modules/narrowing/cases/narrowing_null_check` passes on all four targets since `00 · 05-wasm` landed the missing
unbox (`fix/wasm-optional`): a name a `!= null` test narrows is its PAYLOAD for the branch on wasm
too, which is what the box needed and what the optional-binding form `if (x) { v -> … }` had always
done. `modules/narrowing/cases/narrowing_null_guard_clause` passes on all four targets; beam was red longest, and not
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

1.0.10-beta's `00 · 04-js` adds three more cells, every one of them measured by rakun's front
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
narrowing's row). It carried `"targets"` `commonJS erlang` until `00 · 05-wasm` fixed wasm's optional
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
| `modules/loop/cases/loop_generator_dobros` | decision 105's own example: `2 4 … 18 20`, then the counter the generator left at `10` |
| `modules/generator/cases/generator_body_lazy` | 144 B-128: a generator's body runs one step per item asked for — on an `iter fn`, an `iter loop` and a marked lambda `{ iter -> … }`, a print before and after the first `yield` comes out between the items, and an endless generator is consumed by `take(3)`; wasm does not answer it until B-128's wasm half lands, and no target mark says so: the cell is red there, no departure recorded |
| `modules/generator/cases/generator_handle_stateful` | 144 B-134: a generator handle is stateful whatever its body — a second `for` over an exhausted handle reads nothing, on an `iter fn` of only literal `yield`s, an `iter fn` that runs code and an `iter loop`; wasm does not answer it until B-128's wasm half lands, and no target mark says so: the cell is red there, no departure recorded |
| `modules/loop/cases/loop_range_inclusive` | `for (1..4)` visits `1 2 3`, `for (1...4)` visits `1 2 3 4`, `for (3...2)` nothing |

The refusal cells name one refusal each: `loop_break_value`, `loop_yield_plain_fn`,
`for_over_condition`, `for_future_generator_without_await` (`for-over-stream` since front 24),
`generator_loop_use`, `generator_loop_await`, `generator_loop_break_outer`, `continue_outside_loop`,
`yield_label_loop`, plus the parser's `loop_parenthesised` and `loop_condition_parameter`.

### Effects by return (front 24, decisions 118–128)

The § *Cells* suite of `specs/1.0.10-beta/00-compiler-carry-over/24-effects-by-return/README.md`,
written against its `guide.md`: the return type is the annotation (`@Result`, `@Async`,
`@Component<C, T>`, `@Iter`, `@AsyncIter`), only `@Result` fails, `async { }` and the `iter` /
`stream` loop prefixes. Written before the compiler lands them, so each fails on today's compiler
until the front's steps do; every header names the decision and the guide row it pins. A cell
that awaits prints from inside its one `@Async` / `@Component` body (`run`, or the component
`main` calls): commonJS hands a plain caller a Promise (decision 120), the other backends run the
Async eagerly, and inside one body the order is the same everywhere.

| Group | Cells |
|---|---|
| Return and effect mode | `test/effect_return_result`, `modules/decisions-taken/body_marker_whole_return_type-553/cells/task_return_layers` (three layers), `modules/decisions-taken/body_marker_whole_return_type-553/cases/effect_alias_passes_value`; `modules/decisions-taken/effect_return_wraps_each_layer-119/cases/effect_return_ambiguous_nesting`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/effect_wrapper_behind_alias` |
| `@Async` and failure | `modules/decisions-taken/body_marker_whole_return_type-553/cells/task_await_no_try`, `modules/decisions-taken/body_marker_whole_return_type-553/cells/task_await_result` (`await t` answers the `@Result`, `try await t`, `try await t catch x`), `modules/decisions-taken/task_methods_withdrawn_async_block-523/cases/task_failure_rejects` (`"targets"` `commonJS`: the Promise rejects with the thrown value and resolves with the bare one), `modules/decisions-taken/task_result_rejects_with_error-432/cases/task_result_rejects` (432 on every target: every way a failing task reaches an `await` reads `Error(e)`), `modules/decisions-taken/task_methods_withdrawn_async_block-523/cells/task_method_refused` (decision 523: `map`, `then`, `mapError` and `catch` are withdrawn from a task, a call is refused as an unknown member), `modules/decisions-taken/task_methods_withdrawn_async_block-523/cases/task_compose_by_async_block` (every composition of a task is an `async { }` block, four targets), `modules/decisions-taken/task_result_rejects_with_error-432/cases/task_result_caught_by_js` (`"targets"` `commonJS`: a JavaScript `try`/`catch` around a botopink task, and a dropped failing task is no unhandled rejection); `modules/decisions-taken/body_marker_whole_return_type-553/cases/task_throw_without_result`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/task_try_await_without_result` |
| Chain and `use` | `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_hook_and_component`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_result_try_await`; `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_try_element`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/await_under_result`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/use_under_task`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/use_of_component` |
| `async { }` | `modules/decisions-taken/async_block_is_closed_task_expression-124/cases/async_block_all_of`, `modules/decisions-taken/async_block_is_closed_task_expression-124/cells/async_block_value_type`, `modules/decisions-taken/async_block_is_closed_task_expression-124/cells/async_block_return`; `modules/decisions-taken/async_block_is_closed_task_expression-124/cases/async_block_use`, `modules/decisions-taken/async_block_is_closed_task_expression-124/cases/async_block_conflicting_errors` |
| Iterators | `modules/decisions-taken/body_marker_whole_return_type-553/run/src/cases/iterator_fibonacci`, `modules/decisions-taken/body_marker_whole_return_type-553/run/src/cases/iterator_result_item`, `modules/decisions-taken/body_marker_whole_return_type-553/run/src/cases/iterator_result_items` (step E4), `modules/decisions-taken/body_marker_whole_return_type-553/run/src/cases/iterator_factory`, `test/yield_step_next` and `modules/decisions-taken/body_marker_whole_return_type-553/cases/yield_step_next` (`.next()` by hand on an `@Iter` and, awaited, on a `@AsyncIter` — the `run/` half reaches beam and wasm, which a `test/` cell cannot, and steps a parameter inside a `while`); `modules/decisions-taken/body_marker_whole_return_type-553/cases/iterator_throw_without_result`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/iter_await`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/iter_mixed_yield_return`, `modules/decisions-taken/effect_annotation_removed_refused-127/cases/iterator_error_param_removed` |
| Streams | `modules/decisions-taken/body_marker_whole_return_type-553/run/src/cases/stream_pages` (a simulated http failing mid-way), `modules/decisions-taken/iter_prefix_makes_loop_an_iterator-125/cases/stream_loop_no_failure`; `modules/decisions-taken/body_marker_whole_return_type-553/cases/for_await_without_task` |
| Prefixed loops | `modules/decisions-taken/iter_prefix_makes_loop_an_iterator-125/cases/prefixed_loop_forms`, `modules/decisions-taken/iter_prefix_makes_loop_an_iterator-125/cases/prefixed_loop_result_item`, `modules/decisions-taken/iter_prefix_makes_loop_an_iterator-125/cases/prefixed_loop_break_value`, `modules/decisions-taken/iter_prefix_makes_loop_an_iterator-125/cases/prefixed_loop_nearest_scope`, `test/contextual_words`; `modules/decisions-taken/iter_prefix_makes_loop_an_iterator-125/cases/prefixed_loop_break_outer` |
| Host (decisions 126, 431, 490) | `modules/decisions-taken/binding_result_true_maps_host_errors-490/cells/host_node_task_result` (`"targets"` `commonJS`; `result: true`, a rejection is `Error(HostError(…))`), `modules/decisions-taken/external_async_result_rejection_is_error-126/cells/host_erlang_task_result` (`"targets"` `erlang beam`), `modules/decisions-taken/binding_result_true_maps_host_errors-490/cases/external_result_host_error` (`result: true` on a sync and a `@Async` binding, every way the host fails — an `Error`, another thrown value, an erlang `{error, R}` — `Error(HostError(…))` with the same `name` on every target; wasm binds each by `fn:`), `modules/decisions-taken/host_error_fields-489/cells/external_result_erlang_exit` (`"targets"` `erlang beam`: `error`, `throw` and `exit` named `Error`, `Throw`, `Exit`), `modules/decisions-taken/binding_result_true_maps_host_errors-490/cells/external_result_host_method` (`"targets"` `commonJS erlang beam`: a host method, sync and `@Async`, answers the same); the checker's refusals of the flag (decisions 487, 488, 491) — `modules/decisions-taken/external_fields_written_by_label-621/cases/external_flag_bare_bool_refused`, `modules/decisions-taken/binding_result_true_maps_host_errors-490/cases/external_result_return`, `modules/decisions-taken/binding_result_true_maps_host_errors-490/cases/external_result_task_plain_value`, `modules/decisions-taken/host_error_by_module_identity-488/cases/external_result_own_host_error`, `modules/decisions-taken/binding_result_true_maps_host_errors-490/cases/external_result_not_bool`, `modules/decisions-taken/result_refused_on_op_fn-491/cases/external_result_on_fn_cell`, `modules/decisions-taken/result_refused_on_op_fn-491/cases/external_result_on_wasm_op_cell` — and the accepted shapes `modules/decisions-taken/binding_result_true_maps_host_errors-490/cells/external_result_return_accepted`; std's types `modules/decisions-taken/failure_kinds-492/cases/std_failure_types` |
| The E3.9 hint (a `@Result` used as its `U`, one hint per source) | `modules/decisions-taken/body_marker_whole_return_type-553/cases/result_hint_await` (`try await t`), `modules/decisions-taken/body_marker_whole_return_type-553/cases/result_hint_for_item` (`try r`), `modules/decisions-taken/async_block_is_closed_task_expression-124/cases/result_hint_inferred_async` (the `await` hint plus the `try` that made the block's value a `@Result`) and `modules/decisions-taken/body_marker_whole_return_type-553/cases/result_hint_inferred_iter` (the `for`-item hint plus the `throw` that made the `iter` items `@Result`s); the two `for` cells carry no location line — the mismatch is reported at the file |
| Migration (decision 127, guide § 9's "Old names that left") | `effect-annotation-removed`: `modules/effect_annotation_removed_{result,future,use,generator,result_generator,future_generator}`, the three loop forms `…_{generator,result_generator,future_generator}_loop`, and the older `…_{context,iterator,async_generator}`; `effect-type-removed`: `modules/effect_type_removed_{future,future_no_error,use,generator,result_generator,future_generator}` and the older `…_{async_iterator,iterable,iterator_step,yield}`; the arity refusals `modules/decisions-taken/component_wrapper_and_contexts-354/cases/component_base_parameter` (`@Component<C, R>`, decision 354), `modules/decisions-taken/body_marker_whole_return_type-553/cases/yield_step_error_param` (`YieldStep<T, E>`); and the existing refusals `modules/decisions-taken/effect_annotation_removed_refused-127/cases/loop_condition_parenthesised`, `modules/decisions-taken/effect_annotation_removed_refused-127/cases/loop_await_removed`, `modules/decisions-taken/body_marker_whole_return_type-553/cases/component_plain_return` |

Every row of guide § 9 has a new-form cell above and an old-form refusal cell. Two
`refused` first lines are a code's shared tail on purpose: `without-fallible-channel`
(`task_throw_without_result`, `iterator_throw_without_result`) holds both the README's
`effect-try-without-fallible-channel` and today's `effect-throw-…` for a `throw` (the README's
open point 2). The alias cells spell the guide's `type Name<T> = …;`, which does not parse at
`82e32e36`.

### Decided-against forms and the step-4b forms (1.0.10-beta `00 · 15-language-surface`)

Eight refusal cells, one per form the language decided against, each pinning the named kind and
the location of the one site every spelling reaches: `ternary_absent` (`c ? 1 : 2`),
`bitwise_operator_absent` (`1 << 2`), `char_literal_absent` (`'a'`), `nested_fn_decl` (a `fn` in a
body), `list_spread_not_last` (`[..a, 3]`), `list_spread_dot_dot_dot` (`[...a]`),
`implement_clause_for` (`implement A for P` after a bodyless `type P(…)`) and `tuple_literal_label`
(`#(x: 1, y: 2)`). Two cells for forms that were parse errors and now run on all four
targets: `decorator_negative_argument` (`#[mark(-20)]` — the decorator receives the number) and
`loop_one_line_body` (a one-statement body in `for (xs) { x -> … }` and in a trailing lambda needs
no `;` before its `}`).

### The `modules/` kind

The kind for what a single file cannot express: `pub mod`, `import … from "<module>"`, a folder index
(`shapes/mod.bp`), a private `mod` leaf, and `from "std"` used from a *user* project rather than from
inside `libs/std`. The directory **is** the project; the runner copies it whole and compares its stdout
with `snapshot/output/main.snap`. A cell that needs a **git** dependency is deliberately out of scope — that is
the libraries' job (`libraries/<name>`, decision 996), and this suite must not need the network. A **local** dependency is in
scope since C-16 (front 12 step 4.2): a second project inside the cell, named by the manifest's
object-form dependency `"<lib>": { "path": "deps/<lib>" }` (decisions 75/76, the workspaces landing
`aa80e30b` — an array `"dependencies"` is refused since then), resolves from disk relative to the
project, and the runner does nothing special for it. `modules/decisions-taken/dependency_modules_kept_by_build-515/cases/local_dependency` is the one
cell of that shape: `deps/shapesdsl/` ships `root.bp` (`pub default mod shapesdsl;`), `shapesdsl.bp`
(`pub default fn shapesdsl<T>(syntax e: string) -> T`, the handler attaching its tree with `compiler.custom(ast)`) and `shapes.bp`
(a record declared in a module listed in `files`); the program does `import shapesdsl, {area, Rect}
from "shapesdsl"` and expands `` shapesdsl @`area(4, 5)` `` at compile time (the text spells `area`, the
name the handler's `e.lookup` asks for — decision 237: a capture carries only the bindings its text
names, and `lookup` of any other name is a located error). Green on all four targets, measured
at `361d255d` — the cell was written against the array `"dependencies"` of `85f883bd` and moved to the
object form when the workspaces manifest (`aa80e30b`) started refusing the array. A dependency ships
only what `files` lists — `root.bp` included, or the handle never reaches the consumer.

The `embed_*` cells (decision 519, 144 B-12) carry the files their program embeds beside their
`botopink.json` (`assets/…`; a loaded package reads them from its own directory): `modules/decisions-taken/embed_returns_asset-519/cases/embed_text_file` and `modules/decisions-taken/unicode_case_tables_embedded-559/cases/embed_binary_file` (an `Asset`'s path, size,
SHA-256 and bytes on the four targets, a file with a zero byte and bytes past 0x7f included),
`modules/decisions-taken/embed_returns_asset-519/cases/embed_through_comptime_param` (a local dependency and the project each hold an
`assets/note.txt`: the path a `comptime` parameter passes is read in the caller's package, the
library's own `@embed` in the library's), and the refusals `embed_path_absolute`,
`embed_path_outside_package`, `embed_file_missing`, `embed_path_not_known` and `embed_text_not_utf8`.
`modules/decisions-taken/bytes_build_constant_only-520/cases/bytes_comptime` answers `1` since decision 520 (a `Bytes` value exists at build).

`modules/package/cases/package_variant_identity` is the second local-dependency cell, and it is here because the
defect it pins is **invisible in one package**: the value is built in the consumer and the `case`
that reads it lives in the dependency. commonJS tested a payload-less arm with `instanceof` whenever
the variant's bare name was unique in the module; an enum SECTION desugars into an inner enum no
module exports, so its classes are re-emitted per module and the consumer's value was never
`instanceof` the library's class — the `case` fell through every arm and printed `undefined`, at
exit 0. The cell prints four values through one dispatcher: a uniquely-named variant, a repeated one
(`Lg` is declared twice, which is why it always worked), and one of each section head.

`modules/unknown/cases/unknown_by_value` (1.0.10-beta `00 · 05-wasm` step 2) runs decision 8 §2, §4.1 and §5.2
through `unknown` on every target — `test/case_unknown.bp` states the same rules, and `botopink test`
does not reach wasm; it prints no unknown float, because commonJS stores nothing extra (§11) and
prints `2.0` in an `unknown` slot as `2`. `modules/optional/cases/optional_chain_method` (05 step 9) is a method on
the rest of a `?.` chain, its absent probes read through `??`; erlang's and beam's halves were 02's
and 03's.

`modules/sibling/cases/sibling_import_in_a_dependency` is a local-dependency cell for 1.0.10-beta `00 · 04-js`
step 5: a `mod` sibling imported with no `from` (`pub mod leaf; import {leaf.Twig};`), once in the
project and once inside `deps/tree/` (`api.bp`'s `import {leaf.Leaf};`). commonJS used to write the
literal word `module` as the path — `require("./module")` / `require("../module")` — so such a
program built and then died with `Cannot find module`. Green on all four targets.

`modules/two/cases/two_packages_one_module_name` pins decisions 170 and 337's module identity — a module is
its package plus its path. Dependencies `a` and `b` each hold `theme` (`Ns` with different fields,
`make`, a template `tag`), each package's `user` imports its own `theme` by path (`b`'s without
importing `Ns`) and evaluates a `comptime make().show()`, and the project has a `theme` of its own:
the checker, the four backends' module names and cross-module calls, the `.d.ts` and the comptime
runtime keep the three apart. The parent binary refused `a/user`'s import on commonJS, erlang and
beam (`make` is declared `pub` by `a/theme` and by `b/theme`) and wasm (`cannot resolve the call
make/0`); four targets now (the real case: `emilia/theme` beside `styled/theme` under
`jhonstart-emilia`, where erlang tagged emilia's `Ns` with `styled@theme@@Ns__v__…`).

`modules/field/cases/field_name_collision` is the third cell that needs two modules to say anything, and the
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

`modules/method/cases/method_name_collision` is the same defect one axis over, and the fourth cell that needs two
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

`modules/export/cases/export_name_collision` and `modules/type/cases/type_name_collision` are the fifth and sixth cells that
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

`modules/variant/cases/variant_name_collision` and `modules/variant/cases/variant_name_ambiguous` are the third axis. Decision
21 puts the ENUM and the enum's module inside a variant's atom, and `variant_enum` answered "which
enum declares `Circle`" by declaration order — first writer wins, mitigated for a `case` SUBJECT
only. The first cell is the spelling that always had an answer (the enum is written) and asserts
six values on every target. The second was an erlang-only cell the emitter refused; since
`01-checker` step 12 the checker answers both halves for every target: a leading dot whose position
expects an enum is that enum's (`modules/variant/cases/variant_leading_dot_expected`), and one whose position
expects nothing is refused naming both enums (`modules/variant/cases/variant_name_ambiguous`).

`modules/variant/cases/variant_positional_payload_same_name` — two modules each declare a payload variant `Item`
with a different field and a third matches both positionally (commonJS printed `null`; beam bound
the whole value, `03-beam`'s row).

`modules/variant/cases/variant_positional_payload_same_name_packages` — the same across two dependency packages, each declaring
`Text` with another field (commonJS read `$0` off a class that carried none).

`modules/variant/cases/variant_payload_wildcard_and_nested` — `Rect(w, _)`, `Rect(_, h)`, `Circle(_)` and a variant
nested in another's payload (`Two(Rect(w, _), _)`, `Two(Circle(r), Rect(_, h))`) in one module, on
all four targets (wasm bound `w` to 0 and answered the nested arms wrong at exit 0, `05-wasm`'s rows).
`modules/unsigned/cases/unsigned_compare_and_divide` — `u32` above 2^31 and `u64` above 2^63 compared and divided, on
all four targets (wasm read a `u64` signed, decision 319); `u64`'s `%` past 2^53 is
`codegen/tests/wat.zig`'s, since commonJS aborts it (`04-js`'s step 9).
`05-wasm`'s printing rows, each on all four targets: `modules/bool/cases/bool_field_print` (a `bool` record field
or tuple element read alone printed `1` / `0` on wasm), `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/u64_record_field_print` (a `u64` field
through the record printer printed signed), `modules/u64/cases/u64_tuple_slot` (a `u64` / `i64` / `u32` tuple
element — built, read, destructured, bound, compared, nested — was refused on wasm) and
`modules/optional/cases/optional_u64_to_string` (a `?u64` printed, narrowed, unwrapped and turned into text signed).

### `std_default_fn_in_a_std_module`

Two cells of 1.0.10-beta's `00 · 02-erlang` (`fix/std-slice-shim`), and the reason they are a group
rather than an addition to `std_erlang_node`: what they pin is a `libs/std` module compiled as a
**dependency**, which is a different compile unit from the one the libraries' job gives it.

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
| `modules/std/run/src/cases/std_default_fn_in_a_std_module` | the VALUE, through four std modules and both interfaces. `botopink run --target erlang` compiles the whole output directory with `erlc` up front, so a dead std module is a hard error on this path. On four targets since `01-compiler/05-wasm` step 5, which closed the two wrong answers wasm gave it at exit 0 (`url.parse` through its namespace called `querystring`'s `parse`; `dequeue`'s `?T` read as its box's address) |
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

Each half was shown red by planting the pre-fix behaviour: with `collectPreludeInstanceDefaults` guarded again, the
`modules/` cell exits 1 with empty stdout and the `test/` suite does not compile ("`std/path.erl` does not compile — refusing to
run the tests of …"); with the `_ -> ok` skip also back, the same suite reports `{error,undef}` and says nothing about
`std/path`; with only the sibling loader's `std_imports` route removed, it is `{error,undef}` again on a module that compiles
perfectly.

### `std_fs_walk_root_spellings`

`modules/decisions-taken/fs_walk_dangling_link_not_found-711/cells/std_fs_walk_root_spellings` (1.0.11-beta front 97) builds `walkroot/` in its scratch project and
prints `fs.walk` of it under nine spellings of the root — `walkroot`, `walkroot/`, `walkroot/.`,
`path.join(["walkroot", "."])`, `./walkroot`, `walkroot/app/..`, the absolute path with and without a
trailing `.`, and `walkroot/app/.` — expecting the same relative paths each time, on commonJS, erlang
and beam; wasm refuses the import (`snapshot/targets/wasm/`, STD-001: `io/fs` has no wasm binding). The erlang
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
the behaviour landed with B-00e / B-00g and no cell held it, because one `snapshot/output/` answer could not hold two
answers): `modules/decisions-taken/commonjs_text_matches_std_wasm-521/cases/float_text_at_run_time` (`"${5.0}"`, `1.0e21`, `1.0e-7` print `5.0`, `1.0e21`,
`1.0e-7` on every target, commonJS since 144 B-78),
`modules/decisions-taken/commonjs_text_matches_std_wasm-521/cases/string_trim_keeps_nbsp` (`trim` keeps a NBSP on every target, commonJS through its helper),
`modules/decisions-taken/commonjs_text_matches_std_wasm-521/cases/string_lower_final_sigma` (`ΟΔΟΣ` lowers to `οδοσ` on every target, commonJS through its helper) and
`modules/decisions-taken/float_division_by_zero_panics_on_beam-675/cells/float_nan_infinity_words` (`Infinity`, `-Infinity`, `NaN` on commonJS and wasm; erlang and
beam abort, `stderr panic: division by zero: / on f64 at <file>:<l>:<c>`, decision 675; `modules/decisions-taken/float_division_by_zero_panics_on_beam-675/cells/float_division_by_zero_panic`). The fifth row, an unseeded `random.float()` reached from a decorator
body, is `modules/decisions-taken/unseeded_random_refused_at_build-456/refused/src/cases/decorator_random_float_unseeded` since 144 B-46 made a decorator body reach a nested
std namespace: refused at build on every target with decision 451's message (434 (5): one comptime, one
answer — no departure). Each departure is the language's, never a defect recorded (458): erlang's and
beam's abort on a float division by zero is their arithmetic by decision 444, worded as the integer one's `panic` (675). commonJS keeps no departure of text: decision 521
gives it std-wasm's float text, `trim` and case mapping (144 B-78), a string method reached through `?.`
included (`modules/decisions-taken/commonjs_text_matches_std_wasm-521/cases/optional_chain_string_text`).

**The language half of `test-cli`** (144 B-29 step H): `modules/tail/cases/tail_recursive_sum` (the numeric
program of `backend_exec.sh`, `0 1 55`, beam included), `modules/record/cases/record_enum_case_lambda` (its
records / enum / `case` / lambda program, wasm included), `modules/mutual/cases/mutual_recursion_forward_reference`
(`mutual_recursion.sh`'s forward reference and `isEven` ↔ `isOdd`), `modules/assert/cases/assert_message_aborts`
(a failing `assert cond, "msg"` aborts naming its message on every target) and
`test/assert_and_try.bp` (`assert` with a message and `try` in a `test` block). How the runner
reports a failed test stays `modules/compiler-cli/tests/test_tooling.sh`'s.

**botopink-lang's `examples/`** (144 B-29 step H, decisions 457, 461): `modules/hello/cases/hello`,
`modules/modules/cases/modules` (the `mod` / `pub mod` tree; its `docs.md` is the example's README),
`modules/yamlconf/cases/yamlconf` (a config template lifting the labelled tuple `#(server, debug)`: `8038`,
`true`) and `modules/yamlconf/cases/yamlconf_unknown_label` (the example's commented-out `cfg.server.prot`,
refused at the label, `this tuple has no element labeled \`prot\``), and the suite
`test/stdlib-tour/` (its `test {}` blocks). No gate ran them before: `yamlconf`'s
`import {conf} from "yamlconf"` is `import {yamlconf.conf}` since decision 337, and
`stdlib-tour`'s two record tests asserted the identity `==` decision 210 replaced, so they now
assert structural keys and dedup. The move found two defects, both fixed since: `modules/yamlconf/cases/yamlconf`
on wasm printed `1` for the lifted tuple's `bool` (`@print(cfg.debug)`), and `test/stdlib-tour`'s
`Set.fromList` of structurally-equal records kept three members on commonJS where erlang and beam
keep two; both answer their snapshots on every target. `generic-loader-binding` (three `from "erika"` forms — a library, not the language) moved to erika's
`conformance/modules/generic_loader_binding` (rule 10's consumer commit); its three forms answer alike on
every target since 144 B-45, B-50 and `modules/generic/cases/generic_method_array_join`.

`front/gate-wasm-wrong-answers` (`compiler-core/src/codegen/wat/AGENTS.md` § Numbers) adds three
four-target cells for numbers wasm answered wrongly at exit 0 — `modules/decisions-taken/wasm_prints_std_wasm_text-441/cases/float_shortest_text` (a
float's shortest round-trip text, where erlang and beam agree with commonJS), `modules/float/cases/float_slot_keeps_f64`
(a float in an array, a tuple, a payload, a record field, a `?f64`, a capture), `modules/i64/cases/i64_full_width`
(`i64` locals, parameters, fields, `?i64`, `u32`, a literal past `i32`) — and four cells refused on
wasm by a snapshot departure, each a value wasm has no reader for yet: `modules/optional/cases/optional_index_arithmetic`
(`xs[i] + 1`), `modules/i64/cases/i64_in_array_slot`, `modules/fn/cases/fn_value_float_argument`,
`modules/untyped/cases/untyped_array_float_push` (`modules/generic/cases/generic_field_float` answers `1.5` on wasm since 164 s2 P3: a
float goes into a generic slot in its box in a GC module).

`front/int-overflow` (decision 264: an integer result outside its type aborts on every target) adds
eight abort cells, each `abort` plus `stderr` naming `integer overflow: <op> on <type> at
src/main.bp:<L:C>` on commonJS, erlang and beam: `modules/decisions-taken/integer_overflow_aborts-264/cases/int_overflow_add_i32`, `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/int_overflow_mul_i64`
(past `2^63 − 1`; commonJS reaches the bound through `BigInt`, decision 319),
`modules/decisions-taken/integer_overflow_aborts-264/cases/int_overflow_negate_i32`, `modules/decisions-taken/integer_overflow_aborts-264/cases/int_overflow_plus_assign`, `modules/decisions-taken/integer_overflow_aborts-264/cases/int_division_min_by_minus_one`,
`modules/decisions-taken/integer_overflow_aborts-264/cases/int_overflow_sub_u32`, `modules/decisions-taken/integer_overflow_aborts-264/cases/int_overflow_add_i8` and `modules/int/cases/int_division_by_zero` (commonJS's
`integer division by zero`; erlang and beam raise `badarith`, wasm traps) — and
`modules/decisions-taken/integer_overflow_aborts-264/cases/int_arith_at_bounds`, every type's bound reached by arithmetic and printed, never an abort. wasm
traps with no text, so its half is `abort` alone; `u32` and the narrower types check their own range
there too (`wat.zig` `emitRangeCheck`).

144 B-00g (decision 443: case mapping over all of Unicode) adds `modules/decisions-taken/wasm_unicode_case_mapping-443/cases/string_case_unicode` — `é`,
`ß` → `SS`, `ǆ`, `ﬁ` → `FI`, `İ` → `i̇`, Greek and Cyrillic upper- and lower-cased with one `snapshot/output/` answer on
the four targets (wasm printed `é` unchanged at exit 0). The one place the targets part, the final
sigma (a JS engine lowers a word-final `Σ` to `ς`; OTP, and so erlang, beam and wasm, to `σ`), is
not printed here — one `snapshot/output/` answer cannot hold both —; `codegen/tests/wat.zig` pins wasm's.

144 B-00k (the B-00 group's Conformance step, decisions 458, 459) adds four cells, each red on the
group's parent `239f789f`: `modules/decisions-taken/wasm_unicode_case_mapping-443/cases/comptime_text_one_answer` (decisions 434 (5), 441, 443 — a text
computed at comptime is std-wasm's on every target: `5.0`, `1.0e21`, `1.0e-7`, `trim` keeping a NBSP,
`é` → `É`, `straße` → `STRASSE`, `ΟΔΟΣ` → `οδοσ` — the final sigma that one runtime `snapshot/output/` answer cannot
hold; the parent's wat comptime refused the non-ASCII case mapping on commonJS and wasm),
`modules/decisions-taken/comptime_never_translates_erlang-452/cases/comptime_erlang_cell_never_runs_at_build` (decision 452 — `tag`'s Node, Erlang and `fn:` cells
answer three texts, and the decorator's call prints `Point:fn` on the four targets; the parent's BEAM
comptime printed `Point:erlang` on erlang and beam), `modules/decisions-taken/comptime_never_translates_erlang-452/cases/comptime_expression_erlang_cell_never_runs`
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
`modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/i64_full_range` (past 2^53 both ways, `2^63 − 1`, `−2^63`, `/` `%` unary `-` `+=` and `==` across
the edge, then a sum past the top that aborts), `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/int_overflow_sub_i64_min`,
`modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/int_overflow_add_u64_max` (the `u64` top, `%` and `/` past 2^53, a sum past the top; red on wasm,
which prints the top as `-1` and traps on `18446744073709551614ul + 1ul`), `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/i64_dict_key_across_safe_edge`
(a `Dict` and a `Set` keyed across 2^53; wasm refuses the `i64` element, `snapshot/targets/wasm/`) and
`modules/decisions-taken/string_index_counts_codepoints-320/cases/string_codepoint_slice_and_code` (a negative `slice` bound, `s[-2]`, `s[4..]` and `charCodeAt`
over `"a👍bX👍c"`); `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/wide_literal_past_js_safe_integer` lost its `snapshot/targets/commonJS/` departure and answers
on the four targets.

`02/97` step 13 (decision 319, std's half) adds `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/i64_number_methods_past_js_safe` — `min`, `max`,
`clamp`, `abs`, `isEven`, `isOdd` on `i64` and `u64` values past 2^53 (commonJS threw
`big.isEven is not a function`: the methods were patched on `Number.prototype` alone) —,
`modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/string_parse_int_i64_range` (`parseInt` reads −2^63 … 2^63 − 1 and refuses one past either end;
the parent refused past ±(2^53 − 1)), `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/integer_conversions_exact` (`toI32`, `toI64`, `toU32`,
`toU64`, `toF64` at the bounds and past 2^53) and two aborts, `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/integer_conversion_to_i32_aborts`
and `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/integer_conversion_to_f64_inexact_aborts` (`abort` plus a `stderr` line per target naming the
value). They answer on commonJS, erlang and beam, and `string_parse_int_i64_range` on wasm too (144
B-22: std-wasm's `text` and `number` cells behind `primitives.bp`'s host helpers), and the three
conversion cells on wasm too since 144 B-22 (`lowerIntConversion`: the range test on the receiver's
carrier, the abort text built from its digits); B-22 adds `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/integer_conversion_u64_to_i64_aborts`
(a `u64` past `i64`'s top read unsigned in the abort) and `modules/decisions-taken/task_result_rejects_with_error-432/cases/async_retry_policy`
(`async.retry(policy, { -> … })` answering `Ok` and the last `Error`, its pause converted by `toI32()`),
both red on wasm on the parent. wasm refuses `i64_number_methods_past_js_safe` by `snapshot/targets/wasm/` — its
integer methods are `i32`'s — a `05-wasm` row.
Its `io` half adds `modules/decisions-taken/i64_is_64_bit_everywhere-319/cases/std_io_i64_canonical` — `fs.stat`'s `size`, kind and `mtime` (the Node
form reads `statSync` with `bigint: true` and answers the canonical form) and `clock.hours` /
`clock.add` past 2^53 (`clock`'s `wide` is std's `toI64()` now, no host cell), printed as the same
digits on commonJS, erlang and beam; wasm refuses `io/fs` by `snapshot/targets/wasm/`. Its `recent` helper
holds the `l` literal outside the `case` arm: an `l`-suffixed literal inside a `case` arm is
emitted with its suffix on commonJS, erlang and beam (`s.mtime > 1577836800000l`, a JS
`SyntaxError`, an `erlc` syntax error, `illegal integer` in the beam assembler) — a compiler row,
not std's.

`01-compiler/139` (decision 332: `bigint`, an integer of any size, one value on the four targets)
adds `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_arithmetic` (2^101 by a loop, a product of two 40-digit numbers, `/` and `%` with
negative operands, the comparisons, `toString`, `+=`, unary `-`, `bigint.of` past `i64`,
`bigint.parse` of a numeral and of four non-numerals, `toI64`, `toF64`, hex and `_` literals —
checked against Python's integers), `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_in_containers` (a record field, a `?bigint` field, a
tuple, an array, `xs[i]`, a fold, an `if` answering a `?bigint`, `==` over each built apart, a number
pattern and a range), `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_to_i64_aborts` (`abort`, and `toI64: 9223372036854775808 does not
fit i64` on commonJS, erlang and beam), `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_division_by_zero` (`abort`, commonJS's
`integer division by zero: / on bigint at src/main.bp:10:14`), `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_across_modules` (a
sibling's `pub fn`, `pub` record and `pub val` holding `bigint`s; its `.d.ts` through
the commonJS row's `tsc` over the tree, `run.sh`), and the refusals `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_literal_fraction` (`1.5n`, at the suffix),
`modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_plus_int_literal` (`2n + 1`, at the `1`), `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_unsuffixed_literal`
(`val x: bigint = 2`), `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_into_i64` (`val x: i64 = 2n`) and, question 139-a's answer,
`modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_type_test` (`x is i32` over a `bigint`), `modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_into_unknown` and
`modules/decisions-taken/bigint_decimal_strict_json-332/cases/bigint_comptime`. Every one was refused by the parent binary (`number-suffix-unknown`).

144 B-24 (decisions 497, 499: std's `io` over the full `i64`) adds `modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_rfc3339_domain` —
`formatIso8601`, `toCivil` and `offsetMinutes` at both ends of RFC 3339's epochs, −62167219200000 and
253402300799999 (erlang aborted at year 0: `calendar` read the host's local time, which ERTS refuses before
1902) — and three aborts naming the value past it, `modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_format_past_rfc3339_aborts` (an epoch past
2^53, a `BigInt` on commonJS), `modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_civil_past_rfc3339_aborts` and
`modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_offset_past_rfc3339_aborts` (the parent answered year 10000 and an offset);
`modules/decisions-taken/stat_mtime_whole_seconds-499/cells/fs_stat_mtime_whole_seconds` (`mtime % 1000 == 0` on every target; commonJS floored to the
millisecond). Each runs on commonJS, erlang and beam (`"targets"`: `io` has no wasm binding).
It adds std's `decimal` (decision 332 (2)) with `modules/decisions-taken/bigint_decimal_strict_json-332/cases/decimal_exact_arithmetic` — `add`, `sub`,
`mul`, `div` at a scale under each `Rounding` (the javadoc's table of `RoundingMode`), `compare`, the
plain `toString()` and `Decimal.parse`, on all four targets — and two aborts,
`modules/decisions-taken/bigint_decimal_strict_json-332/cases/decimal_div_rounding_necessary_aborts` and `modules/decisions-taken/bigint_decimal_strict_json-332/cases/decimal_div_by_zero_aborts` (wasm traps
with no text: `abort` alone there). The parent refused the import (`unknown "std" module`).

Decision 525 (blocks: a `{` without `->` is a block, never a closure; `@block` removed) turns the
`@block` cells into blocks' cells: `modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_tail_value` (a block's value is its tail),
`modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_return_leaves_function` (a `return` in a block leaves the enclosing function — from
the block, a `case` arm at its end, a nested block, a block in a `for` body, a statement block),
`modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_for_return_leaves_function`, `modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_partial_return`,
`modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_reassigns_enclosing_var` and `modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_value_reassigns_enclosing_var` (a plain
reassignment on every target, from the body, an `if` / `else` at its end and a loop), on all four
targets; and its refusals, each located: `modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_builtin_removed` (`removed-block-builtin`),
`modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_trailing_not_function` and `modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_argument_not_function`
(`block-not-function`, "missing `->`?"), `modules/decisions-taken/brace_without_arrow_is_block-525/cases/block_void_value_refused` (`block-void-value`),
`modules/decisions-taken/brace_without_arrow_is_block-525/cases/comptime_block_break_value` (`block-break-value`) and `modules/decisions-taken/brace_without_arrow_is_block-525/cases/case_arm_no_value`
(`case-arm-no-value`). `modules/decisions-taken/brace_without_arrow_is_block-525/cases/async_block_tail_value` and `modules/decisions-taken/brace_without_arrow_is_block-525/cases/async_block_tail_case` pin an
`async { … }` block's tail as its task's value: the parent dropped it (commonJS printed `null`,
erlang raised `case_clause` on a `case` at the end). The cells whose `comptime { …; break v; }` or
value `case` arm ended in `;` are rewritten in the new spelling, their answers unchanged.
Decision 541 adds `modules/decisions-taken/lambda_answers_last_expression-541/cases/case_arm_break_value_removed` (a `case` arm's `break <value>`, `block-break-value` at the `break`)
and the cells of a block as a scope of the enclosing function: `modules/decisions-taken/lambda_answers_last_expression-541/cases/block_await_reaches_function` (an `await` in a block and
in an arm's block), `modules/decisions-taken/lambda_answers_last_expression-541/cases/block_yield_reaches_generator` (a `yield` in a block, an arm and a value block),
`modules/decisions-taken/lambda_answers_last_expression-541/cases/block_break_reaches_loop` (a bare `break` in a block and in an arm of a `while`) and
`modules/decisions-taken/lambda_answers_last_expression-541/cases/block_ends_function_body_is_tail` (a block ending a function body is its tail); all four targets.
`modules/decisions-taken/lambda_answers_last_expression-541/cases/block_jump_label_reaches_loop` (a `break :outer` from a `case` arm's block and from a plain block, to a loop two levels out)
and `modules/decisions-taken/lambda_answers_last_expression-541/cases/case_arm_return_in_yielding_arm` (a bare `return` in a yielding arm ends the generator). The first is red on beam
and wasm (both ignore the label); the second on wasm (the `return` ends only the arm). A cell cannot leave a target out for a gap
(§ Narrowing a cell), so each stays red there until its backend's step lands.
`modules/decisions-taken/brace_without_arrow_is_block-525/cases/trailing_lambda_call` pins the trailing lambda as the call's last argument (decision 525): a method's and a plain
function's, with one parameter and with none (`b.run { -> 10 }`, `twice { -> 4 }`, `apply(3) { k -> k * 3 }`), on all four
targets — the parent refused the parameters as unbound and the plain function's lambda as an arity error, and wasm and beam
lowered a method's trailing lambda wrong.

Decision 539 (`defer`) adds nine cells on all four targets and five refusals. `modules/defer/cases/defer_block_end_reverse_order`
(the end of the block, reverse order), `modules/defer/cases/defer_scope_is_block` (a bare block runs its own), `modules/defer/cases/defer_reads_latest_value`
(the expression is evaluated when it runs), `modules/value/cases/value_if_reassigns_var` (a `var` a value `if` reassigns in a branch, `else if` included, holds it after the `if`), `modules/decisions-taken/defer_runs_at_block_end-539/cases/defer_reads_var_set_in_arm` (a reassignment inside a nested arm, a value `case`'s or `if`'s included, reaches the defer when the arm panics), `modules/defer/cases/defer_return_value_before_defers` (`return n` is computed before a defer
that changes `n`), `modules/defer/cases/defer_in_loop_break_continue` (the end of the round, `continue`, `break`),
`modules/defer/cases/defer_try_catch_inside` (a `try … catch` region written in the body is handled there, decision 866),
`modules/defer/cases/defer_panic_attempt_catches` (a panic `attempt` catches; wasm runs with exceptions on, decision 518),
`modules/defer/cases/defer_async_after_awaits` (a `@Async` body: after its awaits) and `modules/defer/cases/defer_stream_consumer_stops` (a `@AsyncIter`: the
consumer's `break` and the end of the stream both end in the same two lines, so a lazy producer and an eager one answer alike);
the refusals, each located at the jump, are `modules/defer/cases/defer_refuses_return` (`defer-return`), `defer_refuses_break`
(`defer-break`), `defer_refuses_continue` (`defer-continue`), `defer_refuses_yield` (`defer-yield`) and `defer_refuses_await`
(`defer-await`), `defer_refuses_throw` (`defer-throw`) and `defer_refuses_try` (`defer-try`, a `try` whose region is not written in the body; decision 866).
Decision 539 (6) (`Closeable` ambient, 144 B-96) adds `modules/decisions-taken/defer_runs_at_block_end-539/cases/ambient_behavior_parameter` (`Closeable` and `Display`
as a parameter's type and an array's element type with no import, each call answered by the implementer, on all four
targets — refused `unknown type` on the parent), `modules/decisions-taken/defer_runs_at_block_end-539/cases/ambient_behavior_implement_missing_method` (an inline
`implement Closeable` with no `close`, refused at the type — accepted on the parent) and
`modules/behavior/cases/behavior_method_no_return_by_value` (a method declared with no return dispatched by value as a function's last
statement — wasm's module was refused at load on the parent).
144 B-107 (every public behavior of `primitives.bp` no compiler rule reads is ambient) adds
`modules/decisions-taken/negative_index_counts_from_end-139/cases/ambient_index_parameter` (`Index<string, i32>` and `Slice<i32[]>` as parameters' types, each call answered
by the implementer, on all four targets — wasm read `at`'s box as its payload and took `slice` for a string's on the
parent) and `modules/decisions-taken/negative_index_counts_from_end-139/cases/ambient_index_implement_missing_method` (an inline `implement Index<string, i32>` with no `at`,
refused at the type — accepted on the parent).

`fix-js-gaps` (gaps `libs/validation` met) adds `modules/imported/cases/imported_variant_positional_payload` —
`Circle(r)`, `Rect(w, h)`, `Two(l, r)` and a `val assert Circle(r)` over enums of a sibling module, on
all four targets (commonJS read a property named after the binding and died on `undefined`).
`modules/method/cases/method_named_like_module_fn` — a module declaring `startsWith(syntax decl: unknown, …)` and
`endsWith(a, b)` calls the string methods of those names (erlang refused the module with
`PrimOpArgIndexOutOfRange`, commonJS answered `false`), on all four targets.
`test/type_method_prim_default` — a `type`'s method calls `String.parseInt`, whose body calls
`self.startsWith`; erlang emitted `startsWith(Self, …)` into the type's module, undefined. A `test/`
cell: wasm has no `String.parseInt` (`stringSlice0/2`, `05-wasm`).
`fix-121-gaps` (the gaps front 121's `onze-content` met) adds three cells on all four targets:
`modules/var/cases/var_written_in_branch_read_after` — a `var` written in the arms of a statement `case` inside a
`for`, in an `if` block ending in `return` (and in one holding a nested `return`), two `var k` in
sibling `else if` branches of a `while` body, and `val kids = case c { Box(kids) -> kids; … }` (erlang
refused the module, `Out@1` unbound; beam lost the arms' writes at the end of each round; commonJS ran
a `_` arm after an arm whose block answered nothing); `modules/case/cases/case_arm_ending_in_for` — a statement
`case` arm whose block ends in a `for` (commonJS fell into the next arm, erlang refused the module,
beam dropped a `push` that was an arm's last statement); `modules/record/cases/record_update_on_lambda_parameter` —
`xs.map({ b -> Brk(..b, active: false) })` and a block lambda ending in the update (commonJS, erlang
and beam built `Brk(b, false)`, wasm trapped).


## The reference — `docs.md` (decisions 461, 462)

`docs.md` is botopink-lang's language reference, moved here from the repository root by 144 B-29
step I with the manifest schema (`docs/botopink-json.md` until then, now § The manifest schema) and
the language example of `README.md` (`modules/greet/cases/greet`). It holds no example of its own: an example is
a line `<!-- example: modules/<cell> -->` or `<!-- example: test/<suite> -->`, alone on its line, its
path relative to this directory, rendered from the cell's `src/` and `snapshot/`. Beside each cell
the reference names, the cell's `docs.md` quotes the reference text it shows.

- A fence of the reference that showed a program is a cell (or names an existing one that shows the
  same thing); its answer is what the compiler answers, read against the text — where the two
  disagreed, the defect is a `1-botopink-lang/144` row and the cell stays red until it lands, or the
  stale text was rewritten. A table, a grammar, a layout sample or a runner's report is ```` ```text ````.
- `zig build test-docs` (`scripts/check-docs.sh`, the gate's stage 10) checks that every example names
  a cell (`botopink.json`, `src/main.bp` and a `docs.md` that is not empty) or a suite, and refuses an inline ```` ```botopink ````
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
| wasm | yes on the `wasi` host (decision 513: each test unit a `.wat` component under `wasmtime`; a failing `assert` traps the module's run) | yes, it executes | cells and test suites |
| beam | yes: every module of the run assembled beside itself (`erlc +from_asm`), each test module's runner run with `erl -pa` (`01 · 03-beam`) | yes: it builds `out/beam/*.S`, assembles each beside itself (`erlc +from_asm -o out/beam`) and runs the entry with `erl -pa out/beam` | cells and test suites |

The root package runs on the targets `run.sh --target` names (one job each), its loaded cases on
those their manifests declare (an excluded one answers `.Excluded`, decision 989 (3)). `--target all` is the
four targets of the plan (`TEST_TARGETS` in `run.sh`: commonJS, erlang, wasm, beam); `--target` also
takes a comma list (`wasm,beam`) — a subset in canonical order, a name twice or unknown refused —
which is what the step gate (`scripts/AGENTS.md` § Step gate and full gate) passes for a change that
reaches those backends only. A machine without `erlc`, `erl` or `wasmtime` fails the run before any
job starts (`run.sh: the beam target needs erlc`); it never runs fewer targets and reports "all"
(decision 67). The tool set is the gate's own — `node`, `erl`, `erlc`, `wasmtime` — and nothing
else: the four-target run is green with `PATH=/usr/bin:/bin:~/.wasmtime/bin` and no other variable
but `HOME` and `LANG=C.UTF-8` (front `01-compiler/12-language-tests`). Under a locale that is not
UTF-8 (`LANG=C`, or none) `modules/string/cases/string_split_empty_separator` is red on erlang and beam: `erl` writes
`é` as the latin-1 byte `0xE9` where commonJS writes UTF-8 — a program's stdout that depends on the
host locale is a backend defect, not a reason to pin a locale in the runner.

A cell's claims apply on every target it reaches, beam included: the assembled program's status is
read there too (`modules/panic/cases/panic_aborts` and `modules/todo/cases/todo_aborts` abort on beam — the second for a
different reason, § Notes). A cell that every target refuses is built on
all four, and its `refused` line is the same on each.

An erlang/BEAM module atom starts with its package (decision 109 of 1.0.10-beta): a cell's entry
is `<cell>@main`, and a host
template that builds a record's tag spells it (`'external_host_record@main@@Point'`,
`modules/external/cases/external_host_record`).

**A beam program's host modules.** `botopink build --target beam` ships the `.erl` of every
`#[@external(.Erlang("<host>", …))]` a package keeps under `src/sidecars/` (or `src/`) into `out/beam/`,
beside the `.S` files — the files the erlang build ships into `out/erlang/` — and a host module that is
neither shipped nor on the Erlang code path is the same located refusal on both
(`modules/external/cells/external_erlang_host_module_missing`). Nothing assembles an `.erl`: the
entry's `'__bp_load_siblings'/0` compiles and loads every `.erl` beside its own `.beam` before the
module body runs, so the built program runs wherever `out/beam/` is put on the code path, with no
runner in between. `modules/erlang/cells/erlang_host_sidecar_shipped` and
`modules/erlang/cells/erlang_sidecar_named_like_a_module` pin it (`hello, sidecar`, `HELLO, SIDECAR`).

### `io.fs` (decisions 538, 540)

`io.fs` was redesigned on Rust's, Java's, Erlang's and Node's common shape (144 fs-a): every function that
can fail answers `@Result<…, FsError>`, the same OS error the same `FsError` variant on every target, and a
`File` handle joins the whole-file shortcuts. Its cells run on commonJS, erlang and beam and are narrowed
away from wasm (the `wasi:filesystem` bindings are front 164's; the table above names `utf8Offset`, the first
host cell a body of `std/io/fs` calls with no binding):

- `modules/decisions-taken/fs_walk_dangling_link_not_found-711/cases/fs_error_variants` — six of the seven variants (`PermissionDenied` is std's own test, which
  reaches it as a user who is not root): `NotFound`, `IsDirectory`, `NotDirectory`, `AlreadyExists`,
  `InvalidUtf8` and `Other` (a dangling link under `walk`, decision 178's text its `message`), met through
  `readText`, `list`, `mkdir`, `rm`, `copy`, `stat`, `open`, `create`, `writeText` and `walk`, each with the
  path the caller wrote.
- `modules/decisions-taken/fs_typed_error_shape-540/cases/fs_read_text_not_utf8` — `readText` of valid text (a four-byte sequence, U+10FFFF, U+FFFE, a byte
  order mark) and of sixteen byte strings that are not UTF-8 (a stray continuation, an overlong form, a
  surrogate, past U+10FFFF, a sequence cut short), the same `InvalidUtf8` offset on every target, the bytes
  still readable.
- `modules/decisions-taken/fs_typed_error_shape-540/cases/fs_whole_file_shortcuts` — `writeBytes` / `readBytes` keep every byte, `appendText` creates and
  adds, `copy`, `rm`, `removeTree` (a missing path is `Ok`), `mkdirRecursive`, `stat`, `list`, `walk`, `glob`.
- `modules/decisions-taken/fs_typed_error_shape-540/cases/fs_file_handle` — `create` / `open`, `path`, `size`, `read(n)`, `bytes`, `text`, `hash` (the whole
  file whatever the position), `write`, a file opened for reading refusing `write` and one created for writing
  refusing `read`, `close` twice, `create` truncating. Written without `defer`: `close` is called by hand; `modules/decisions-taken/fs_typed_error_shape-540/cases/fs_file_defer_close` is the same handle closed with `defer` (539) on every exit of a block, a program type that writes `implement Closeable`, a closed file refusing a read.
- `modules/decisions-taken/fs_typed_error_shape-540/cells/fs_file_streams` — `chunks(size)` and `lines()`: `\n` and `\r\n` stripped, an empty line, a last line
  with no terminator, an empty file, `lines` after `read`, and a line that is not UTF-8 ending the stream with
  `InvalidUtf8` at its offset in what the call read.
- `modules/decisions-taken/asset_size_hash_open-538/cases/fs_asset_opens_as_file` — `@embed(…).open()` answers the same text, size, hash and lines as the
  copy on disk, through one function that takes a `File`; `modules/decisions-taken/asset_size_hash_open-538/cases/embed_open_without_fs_import` — the call
  with no `import {io.fs}` is `embed-open-needs-fs` (every target refuses alike).

Found while writing them, each a defect of another front and not recorded as a departure (458), both
since fixed (144 B-94, B-95): `Bytes.length` read as a property is the byte count on every target
(`modules/bytes/cases/bytes_length_property`), and a field read on a type the module does not declare (`asset.path` in std,
`Asset` being the compiler's record) answers the field on beam as on erlang (`modules/embed/cases/embed_field_read_other_module`,
a dependency reading an `Asset`'s fields; wasm places it too, front 164 s2c). 144 B-97 widens the beam
fix to every record the compiler splices (`Declared`, `DeclaredMeta`, `DeclaredTypedMeta` beside `Asset` and
`SourceLocation`): `modules/declared/cells/declared_field_read_other_module` — a dependency reading `name`, `module` and `meta` off
the `@TypeInfo.all` entries the program hands it, directly, through a function, inside `map` and `for` — answers the
fields on beam (the whole record on the parent binary), and on wasm.

### Narrowing a cell

A cell runs on all four targets, and a `test/` suite on commonJS, erlang, wasm and beam —
unless it narrows itself: a cell or a project suite with `"targets"` in its `botopink.json`
(decisions 475 (1), 536; a cell's `targets` file is refused). A single file declares no narrowing — a
`// targets:` line in it is a comment (decision 536: one place for a restriction, the manifest; the
compiler reads no configuration from a comment) — so a `test/` suite that narrows is a directory with a
`botopink.json` and its test files under `test/`. A narrowing is a claim about the compiler, checked on every run —
the compiler's audit at `emit` for a loaded case (decision 989 (3): `.Excluded`, else
`load-excluded-target-compiles`), `run.sh` for a suite: for each target the suite leaves out,
`botopink build --target <t>` must **refuse** the program on a host binding —

```
`f` has no `#[@external(.<Target>(…))]` for the <t> backend
std-unsupported-on-target: std/<m> has no `#[@external(…)]` for target '<t>'
```

— the one reason a program structurally has no row on a target. A target the build accepts, or
refuses for another reason, fails the run and names the cell: the narrowing was hiding a gap of that
backend, and a gap is a row of the backend's front, never an entry in `"targets"`. So does a
narrowing that names an unknown target, the same target twice, or every target of its kind (it narrows nothing — delete the field). No flag,
list or environment variable turns the audit off (decision 67).

A third stands one too — decisions 676 and 770: a build for a target one of the cell's dependencies
does not hold is refused at the dependant's manifest, on that dependency's line,

```
error[dependency-target-missing]: <dependency> holds no <target> target — a package that writes no "targets" holds its dependencies' (decision 770)
error[dependency-target-missing]: <dependency> declares no <target> target — a dependency's "targets" hold every target of the package that declares it
```

so no dependency is compiled for a target it does not hold. A cell that writes no `"targets"` holds its
dependencies' (770): it runs on those and the others are audited
(`decisions-taken/dependency_target_missing_refused-676/cases/narrowing_on_dependency_target_missing`,
`decisions-taken/targets_default_is_dependencies_intersection-770/cases/targets_default_is_dependencies_intersection`).

A target on which the cell must be refused for a reason that *is the cell's claim* is not narrowed
away — its refusal is its answer, `snapshot/targets/<t>/<module>.snap`.

The narrowed cells whose excluded targets' missing binding is named here (re-derived on every check):

| Cell | Runs on | Excluded — the binding it lacks |
|---|---|---|
| `modules/behavior/cases/behavior_method_host_value` | commonJS erlang beam | wasm — `makeGreeter` |
| `modules/external/cells/external_erlang_host_module_missing` | erlang beam (each refuses it: `output/main.snap`) | commonJS, wasm — `total` |
| `modules/external/cases/external_host_record`, `modules/external/cases/external_returns_record` | commonJS erlang beam | wasm — `hostPoint` |
| `modules/decisions-taken/host_error_fields-489/cells/external_result_erlang_exit` | erlang beam | commonJS, wasm — `host` |
| `modules/decisions-taken/binding_result_true_maps_host_errors-490/cells/external_result_host_method`, `modules/external/cases/external_method_in_type` | commonJS erlang beam | wasm — `Meter.plus` |
| `modules/external/cases/external_method_on_host_record` | commonJS erlang beam | wasm — `Pair.at` |
| `modules/external/cases/external_template_binding` | commonJS erlang beam | wasm — `shout` |
| `modules/external/cases/external_template_escaped_quote` | commonJS erlang beam | wasm — `say` |
| `modules/external/cells/external_template_refused_on_beam` | erlang beam | commonJS, wasm — `moduleNamed` |
| `modules/host/cells/host_array_slice_without_start` | commonJS | erlang, wasm, beam — `copyAll` |
| `modules/host/cells/host_template_binding_inside_while` | erlang beam | commonJS, wasm — `bump` |
| `modules/decisions-taken/external_async_result_rejection_is_error-126/cells/host_erlang_task_result` | erlang beam | commonJS, wasm — `hostDouble` |
| `modules/decisions-taken/binding_result_true_maps_host_errors-490/cells/host_node_task_result` | commonJS | erlang, wasm, beam — `hostDouble` |
| `modules/decisions-taken/any_type_absent-31/cases/host_unknown_parameter` | erlang beam | commonJS, wasm — `std/erlang.element` |
| `modules/decisions-taken/wasm_clock_fs_refused-241/cells/std_template_host_fns_across_modules`, `modules/import/cases/import_std_groups`, `modules/decisions-taken/stat_mtime_whole_seconds-499/cells/fs_stat_mtime_whole_seconds` | commonJS erlang beam | wasm — `utf8Offset` (the first host cell a body of `std/io/fs` calls with no wasm binding; decision 540) |
| `modules/decisions-taken/decorator_registry_gathers_marked_declarations-665/cells/typeinfo_all_default_at_caller` | commonJS erlang beam | wasm — `through` |
| `modules/decisions-taken/fs_walk_dangling_link_not_found-711/cases/fs_error_variants`, `modules/decisions-taken/fs_typed_error_shape-540/cases/fs_whole_file_shortcuts`, `modules/decisions-taken/fs_typed_error_shape-540/cases/fs_read_text_not_utf8`, `modules/decisions-taken/fs_typed_error_shape-540/cases/fs_file_handle`, `modules/decisions-taken/fs_typed_error_shape-540/cells/fs_file_streams`, `modules/decisions-taken/asset_size_hash_open-538/cases/fs_asset_opens_as_file` | commonJS erlang beam | wasm — `utf8Offset` (the same; front 164 binds `wasi:filesystem`) |
| `modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_rfc3339_domain`, `modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_civil_past_rfc3339_aborts`, `modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_format_past_rfc3339_aborts`, `modules/decisions-taken/clock_rfc3339_domain-497/cases/clock_offset_past_rfc3339_aborts`, `modules/std/cells/std_generic_primitives`, `modules/decisions-taken/function_stage_propagated-376/cases/stage_build_and_run`, `modules/decisions-taken/function_stage_propagated-376/cases/stage_comptime_block_in_run`, `modules/decisions-taken/function_stage_propagated-376/cases/stage_imported`, `modules/decisions-taken/function_stage_propagated-376/cases/stage_of_functions` | commonJS erlang beam | wasm — `systemTimeWithUnit` |
| `modules/decisions-taken/decl_hooks_reachable_components-277/cells/decl_hooks_direct` | commonJS erlang beam | wasm — `session` |
| `modules/decisions-taken/component_is_lambda_over_render_scope-388/cases/render_scope_library` | commonJS erlang beam | wasm — `hostStash` |
| `modules/decisions-taken/failure_kinds_exact_every_target-527/cases/std_failure_attempt_host` | commonJS erlang beam | wasm — `raiseError` |
| `modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_host` | commonJS erlang beam | wasm — `explode` |
| `modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_panic` | every target | none |
| `modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_crash` | commonJS | erlang, wasm, beam — `notText` |
| `modules/decisions-taken/failure_kinds_exact_every_target-527/cases/std_failure_attempt_crash` | commonJS erlang beam | wasm — `shapeNamed` |
| `modules/decisions-taken/failure_kinds_exact_every_target-527/cases/std_asserts_throws_over_attempt` | commonJS erlang beam | wasm — `raiseBoom`, `std/testing/asserts.canonical` |
| `modules/decisions-taken/async_marked_by_hooks_list-375/cases/component_default_fn_sync`, `modules/decisions-taken/async_marked_by_hooks_list-375/cases/component_method_sync`, `modules/decisions-taken/async_marked_by_hooks_list-375/cases/component_sync_plain_function` | commonJS | erlang, wasm, beam — `pending` |
| `modules/decisions-taken/task_methods_withdrawn_async_block-523/cases/task_failure_rejects` | commonJS | erlang, wasm, beam — `observe` |
| `modules/decisions-taken/task_result_rejects_with_error-432/cases/task_result_caught_by_js` | commonJS | erlang, wasm, beam — `callFromJs` |
| `modules/manifest/cells/manifest_targets_host_binding` | erlang beam (`"targets"`) | commonJS, wasm — `magnitude` |
| `test/erlang_host_sidecar_in_a_test` (a project suite) | erlang beam (`"targets"`) | commonJS, wasm — `hello` |
| `test/behavior_host_dispatch` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `makeGreeter` |
| `test/bodyless_fn` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `hostMin` |
| `test/external_host` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `hostMax` |
| `test/external_markers` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `biggest` |
| `test/mocks_decorator_double` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `pushMatcher`, `std/testing/mocks.newMock` |
| `test/mocks_handwritten_double` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `pushMatcher`, `std/testing/mocks.invoke` |
| `test/module_init` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `mark` |
| `test/running_test_name` (a project suite) | commonJS erlang beam (`"targets"`) | wasm — `std/io/env.read` |

In all, 60 narrowings (51 cells, 9 project suites) and 88 exclusions. No other
manifest or suite carries a narrowing: a project that must be refused on a target says so with its
departure.

**The audits prove themselves.** A loaded case's narrowing is the compiler's audit at `emit`
(decision 989 (3)), held by the cell `load_excluded_target_compiles_refused`. A suite's narrowing is
`run.sh`'s: `conformance/run.sh --self-test` runs a synthetic suite through the same script
(`--suite <dir>`) — one narrowing that stands on a host binding, which must be scheduled on its
declared targets alone, one of each way a narrowing is refused (a target the build accepts, a
refusal that is not a host binding, one that narrows nothing, an unknown
target), and a root workspace — the real `modules/botopink.json` — over a green and a red module and a
member under `decisions-taken/`, beside a module still in the old shape. Its report must hold
each refusal's line, the red module's verdict on each target and its message, the roster reds and
the tally `25 passed, 15 failed`. A whole run of the suite (no `--only`) starts with it
and stops there if it fails — a green run from a runner that no longer refuses says nothing.

**An abnormal end of `botopink test --json` is a red** (`run.sh`'s `test_project`): a `module_crashed`
record (a wasm trap, a runner that died), no `summary` record, fewer results than the suite declares
(`test "…"` blocks under `src/` and `test/`), or a non-zero exit with every test `ok` adds one `fail` line
keyed by the suite, so the report names the suite and the target whatever tests printed before the end.
The self-test runs a stub compiler through five shapes (crash, no summary, fewer results, bare non-zero
exit, clean) and each abnormal one must exit 1 naming `[commonJS] test/trap_mid.bp`.

## Running

```bash
zig build test-conformance                                 # the installed botopink: the root package on every target, every suite
zig build test-conformance -- --target erlang              # the root package and the suites on erlang alone
conformance/run.sh --compiler <botopink> --only modules    # the root package alone
conformance/run.sh --compiler <botopink> --only test/case_arms.bp
conformance/run.sh --self-test                         # § Narrowing a cell — the runner's own audit
conformance/run.sh --list                              # the plan: one `<path>\t<target>\t<run|audit>` line per job, nothing spawned
cd conformance/modules/array && ../../../zig-out/bin/botopink run --target erlang   # one module, by its path
```

`--lib-root` defaults to `<compiler>/../../libs` (where `from "std"` resolves). **The root package**
(decisions 989, 990 (6), 1006 (1)) is a workspace whose members are the modules; it is built once,
before the pool starts, with a bare `botopink build --jobs <run's jobs>` in `modules/` — one process per
member (1006 (5)), each member's comptime compile (its cases loaded inside it) into its `.bpr` set and
key under `modules/.botopinkbuild/runtime/<member>/` (target-independent, decisions 798, 1006 (2)); a
member that does not build is that member's red on each target. Each target of the run is one job,
`botopink run --target <t> --jobs <share>` in `modules/` — one process per member over one
`<out>/<t>/` folder (1015 (4)), each reusing its set while its key is fresh (`run` takes no `.bpr` path,
1009) —, its share the run's jobs over its targets. `--cold` rebuilds the sets (`build --cold`) and the
runs reuse them with no code cache read (1006 (4)). A member's crash or hang is that member's red alone
(`--timeout`, 900 s), and a run that ends without its summary, or with fewer verdicts than the members,
is a red of its own. Before the build `run.sh`'s `roster` reds a module on disk not in decision 989's
shape (`*`). A front-166 draft (`decisions-taken/<slug>-<N>/` holding
`docs.md` and `draft/` alone) is no module until it is promoted (decision 1002 (a)): the roster skips it.

The roster also keeps decision 1011's coverage, per module in the shape: each `cases/<c>` needs a
`runCase("<c>")` in `src/main.bp`, and each literal `runCase("<x>")` needs its directory (`cases/<x>`,
or the path from the module when it holds a `/`) — a comment line does not count; each a `*` red naming
the module and the case. The cases still in a leftover `cells/`, `run/src/cases/` or `refused/src/cases/`
are held to `conformance/leftover-cases.txt` (`<module> <path from the module>`, one per line, generated
once from the tree, frozen and shrink-only): a leftover case not on the list is a red; a listed case that
a `runCase("<path>")` now runs, or that is gone from the disk, is a red until its line is deleted. The
report prints `<N> cases outside 989's shape (shrink-only)`, N the listed cases not run. `--self-test`
carries a fixture module of each: an unrun case, a call without a directory, a listed leftover, a covered
one (the cells `case_on_disk_not_run_refused` and `case_call_without_directory_refused` wait on the 1011
row in the generated ledger).

A red module's `main` answers `Error` (its red cases and their line diff) and writes its candidate,
`snapshot/main.snap.new`, through `io.fs`; the report prints, under its `FAIL` line, what the root
program printed under the module's verdict. A person accepts a candidate by renaming it (decision
464: no update flag), and only when the new answer is the language's.

The report is every `FAIL` line, the narrowing audit's count, a per-target line — `by target:
commonJS <passed>/<ran> · erlang … · beam … · * …`, a module counted once per target and `*` a
narrowing refused before any target ran or a roster red —, a `target runs:` line — `commonJS built N, reused M · erlang …` (decision 1043): per target, the package runs (the root package's, each library's; a by-name library set once) that wrote a file under their runtime or output directory after a stamp `run.sh` touched in its work directory (built) and those that wrote none (reused), read from the file system with no CLI signal; a `--cold` run whose first reach of a package reads `reused` is a red naming the package and the target —, and the total,
`conformance: <passed> passed, <failed> failed`.

Jobs run in parallel on `../scripts/lib/pool.sh` — the library runner's former rule: `--jobs`
defaults to one per CPU bounded by `MemAvailable / 768 MiB`, and a job is admitted only while
`procs_running` ≤ CPUs when another job of the run is in flight (`run.sh` § parallel jobs). Every
job writes its verdict to its own file and the verdicts are sorted before the report, so
`--jobs 1` prints the same bytes and exits with the same status.

A whole run also prints `cells: <J> jobs — <R> run, <A> audits`: the jobs that wrote a verdict
(every job writes exactly one file; a malformed narrowing and a roster red write their `FAIL` without
a job). `--list` prints the same plan without running it, one line per job (the root package's path
is `modules`, one line per target), and `scripts/gate.sh` holds `J` and `A` to it — stage 9 cannot
run fewer jobs than the tree declares.

### What runs in process

Decision 989 — the suite checks itself in process:

| What | How it runs | Why |
|---|---|---|
| every case of every module | loaded at build by its module's `runCase` (`compiler.load`), run in the root's process by `Module.run()` (its printed text, or a `RunFailure`) | no `botopink` process per case or module: the build is one comptime compile, the run one process per target |
| the comparison and the candidate | in the module's `main`, through `conformance/lib/` | the records are the module's to compare; nothing outside the program reads them |
| a `test/` suite | `botopink test --json`, one process per suite and target | the test runner is the path the suite states (decision 457 (2)) |

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
the front that changes a diagnostic's wording re-reads every case that holds it and renames each
candidate its module writes, in the same change.

## Who adds a cell — the owner rule

A cell is added **in the commit of the front whose fix it asserts**: one new `modules/<cell>/`
directory (its `botopink.json`, `src/main.bp` and `docs.md`, written by hand — `cell new` left the
CLI with 990 (6); its module's run writes the candidate, which a person reads and renames), no edit to a cell another front added, no shared file to append to. The commit message says the cell was **red on
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

On disk:

```text
$ ls -d modules/*/ | wc -l      # 1382 cells
$ ls test/*.bp | wc -l          # 64 single-file suites
$ ls -d test/*/ | wc -l         # 15 project suites
```

Refusals whose text sits under the diagnostic's caret — `case_bare_name_arm`, `case_constant_pattern`,
`reserved_word_field_name` and `reserved_word_param_name` — state it as a `label` record (decision 485).

Decision 146 (a function whose body calls a host function with no binding for the target is
refused called or not, on every target): `modules/external/cells/external_wrapper_keeps_refusal` and
`modules/external/cells/external_wrapper_associated_default` are refused on commonJS and wasm by their
`snapshot/targets/<t>/` departures (`otpRelease` has no binding there); `modules/decisions-taken/asserts_throws_generic-493/cases/std_asserts_on_every_target`,
`modules/labelled/cases/labelled_call_by_label` and `modules/decisions-taken/wasm_attempt_by_exception_handling-518/cells/std_asserts_host_cell_on_wasm` are refused on wasm at the
import of `testing.asserts` (a `snapshot/targets/wasm/` departure); `modules/std/cells/std_decorator_through_namespace`
pins the import's `std-unsupported-on-target` line on wasm.

## Notes for whoever writes the next cell

**Shapes that do not parse: none is known.** Every row this list carried parses. Re-measured with
`botopink check` and `botopink run` by front `01-compiler/12-language-tests` of 1.0.11-beta; each
row is pinned by a cell that passes on every target its kind has:

| Shape | Was listed as | Now | Cell |
|---|---|---|---|
| a module-level `var` | absent | `var` and `pub var`, with or without a `#[compiler.beamMemory(.<member>)]` above it; a `val` assigned anywhere is a located error naming `var` (decision 38) | `modules/decisions-taken/reported_surface_forms_all_parse-28/cases/module_var`, `modules/decisions-taken/beam_memory_refused_off_beam-167/cases/beam_memory_off_beam`, `modules/decisions-taken/val_assignment_refused-38/cases/val_assign_module` |
| §5.1 `Pattern { body }` arms, §5.3b section arms | `06 N22` | parse, check and run | `test/case_arms.bp`, `test/case_sections.bp` |
| a block-shaped statement not last in its block (`if (1 > 0) { … }` then `@print("b");`) | decision 29 — "the `;` goes" | parses and runs: the parser accepts a `;` after a braced block statement and `botopink format` removes it (C-13, decision 524) | every cell `botopink format` rewrote (FC-4) |
| `adder(3)(4)` — calling the result of a call | "make it parse" (14) | parses, checks and runs | `test/curried_call.bp` |
| `#(a: i32, b: string)[]` — an array of labeled tuples | "make it parse" (14) | parses, checks and runs, with `@Result<i32, string>[]` and `(i32 \| string)[]` | `test/type_suffix.bp` |
| `??` | deliberately absent (14) | parses and runs (decision 28); `catch` is `@Result`-only, so nothing else gives an optional a default | `test/nullish_default.bp` |
| `xs[0]`, `xs[0..2]`, `d["k"]` — an index expression | "no index expression in the grammar" | parses, checks and runs (decisions 30, 63, 139) | `modules/decisions-taken/record_field_assignment_refused-37/cases/index_expression`, `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_dict`, `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_past_the_end_is_null`, `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_negative_from_end` |
| a bodyless `fn` with `-> void` | no rule | parses and runs (decision 33); without a return type it is `bodyless-fn-needs-return-type` | `test/bodyless_fn`, `modules/bodyless/cases/bodyless_fn_no_return_type` |
| a method on a parenthesised expression or a number literal — `(a == b).toString()`, `("ab").length`, `42.toString()` | open | one production; `42.toString()` prints `42` on all four targets (commonJS once wrote `42.toString()` into the program, which node reads as a float) | `test/paren_receiver.bp`, `modules/method/cases/method_on_number_literal` |

**The range pattern — decision 53.** `...` is inclusive in a pattern; `..` is exclusive in a slice
and in `for (a..b)`, Zig's split. `1..9` in an arm is `error[pattern-range-exclusive]` located at
the `..`, with `1...9` as the hint (`modules/pattern/cases/pattern_range_exclusive`). `1...9` matches both endpoints
and nothing outside them on all four targets — in a `case` used as a value (`modules/case/cases/case_range_value`,
five probes) and as a typed function's return (`fn f(n: i32) -> i32 { return case n { 1...9 … } }`
prints `0 1 1 0` for 0, 1, 9 and 10). **An endpoint probe is the minimum a range cell may print**: a
single value inside the range cannot tell an arm that matches from one that always matches — beam
once answered `1` for every `n`, 0 and 10 included, and a probe at 9 read it as right. Decision 53
legislates numeric endpoints only, so no cell asserts a string bound.

**A `snapshot/output/` answer may encode a decision no backend implements yet, and that is the point.** The `snapshot/output/` answer is
the decision's answer, so when the backends are moved against it **exactly one file per cell** is
involved and no `snapshot/output/` answer is renegotiated in the same commit as an emitter. A cell's header comment
carries the per-backend measurement it was written against.

**Never pin an exit status or a runtime's diagnostic as the point of a line.** `botopink run --target
erlang` compiles every emitted `.erl` with `erlc` and runs `erl -pa <out>` (decision 56; `beam`
assembles the `.S` files the same way); a crash is status `1` and the runtime's report goes to
stderr, which no `snapshot/output/` answer sees. node answers `1` and wasmtime `134`. An aborting program is asserted by
`abort` (§ What a cell's answer is made of), never by a number.

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
§ structural equality). `modules/decisions-taken/equality_is_structural-210/cases/record_structural_equality` pins it on four targets — a
record, a nested record, a tuple, an array of records, enum variants with payloads,
two types with the same fields, `!=`, a generic `same<T>` and an `equals` method `==`
does not call. `test/type_identity.bp` keeps asserting the other half, two
different types with the same fields.

**`f64` under `==` is a total order — decision 214**, as Java's `Double.compare` and
Kotlin's data class: `0.0 == -0.0` is `false` and `NaN == NaN` is `true`, bare and
inside a record, tuple, array or variant, while `<`, `>`, `<=`, `>=` keep IEEE
ordering. erlang and BEAM already separate the zeros (`=:=`); commonJS lowers a
float `==` to `Object.is` and wasm to `$__f64_eq` / `$__f32_eq` (NaN canonicalised,
then the bits). `modules/decisions-taken/f64_equality_total_order-214/cases/f64_equality_total_order` pins the zeros on all four
targets, with `-0.0` built at run time as `zero() * -1.0`. **The NaN rows are not a
cell**: erlang and BEAM never produce a NaN (`z / z` aborts with the division `panic` at run
time), and § Narrowing a cell lets a cell leave a target out only when the build
refuses it on a host binding, which a division is not — a `"targets"` `commonJS wasm`
would fail the audit. Each backend that has NaN pins that half in a RUN LOG fixture of
its own: `codegen/tests/commonjs.zig` and `codegen/tests/wat.zig`, `f64 ---- NaN
equals NaN under ==`.
`modules/decisions-taken/f64_equality_total_order-214/cases/integer_never_negative_zero` is the premise commonJS needs for it: an integer
is never `-0` (`0 * -1`, `-x`, `-4 % 2` and `0 / -3` print `0` and compare equal to
`0`), so a generic `same<T>` answers `true` for two integer zeros and `false` for
`0.0` against `-0.0` on four targets — commonJS printed `-0` and answered `true`.

**The identity is asserted on three backends and RUN on four.** `botopink test --target wasm` (decision 513) runs
a `test/` suite on wasm too, and the suite's assertions are the four targets'. `modules/decisions-taken/equality_is_structural-210/cases/type_identity_equality` is the same
statement as a cell: `Person(name: "a", age: 1) == Vec(name: "a", age: 1)` prints `false` on all
four since `13-module-identity` half 3 put the declaration inside the value.

**`use` is tested from botopink since front 19 of 1.0.10-beta**, spelled to decisions 102/104
(front 21): `test/context_use.bp`, `modules/decisions-taken/body_marker_whole_return_type-553/cells/context_use` and the `use_*` refusal cells declare
their own owner type (`type Element(…) implement @Renderable`, decision 354), hooks as
`fn … -> @Component<T>` and components as `fn … -> @Component<Element>`, and
pin the binding of `T`, field and positional destructuring, a custom hook composing hooks, a bare
void `use`, an unannotated `fn … -> Element` as an ordinary function, the rules of hooks (decision 357,
`use-not-top-level`; rows 4b and 4c were parse errors of the static prefix before it),
`use-without-component` (a `-> Element` body, a plain `-> string` body, a `#[@future]` body —
`modules/use/cases/use_future_without_owner`, decisions 89/90 revoked) and `use-of-non-context-fn` (a
module-level `val`, decision 87). A component's caller awaits it:
`modules/decisions-taken/body_marker_whole_return_type-553/cells/context_use` drives the components from a `#[@future] fn run`, and the `test/` cells await
them (a `test` body is a future context). `test/use_future_context.bp` is the server component that
`use`s and `await`s under a `@Component` return. A function has one return, so it has one
effect (front 24, decision 118): the annotation rules a duplicate-effect or wrapper-without-annotation cell would pin
are gone.
`modules/use/cases/use_tuple_arity` and `modules/use/cases/use_tuple_of_non_tuple` are front 19 step 3's
`use-tuple-arity` refusals, located at the binding.

**Decisions 63–66, one cell or one sentence each (C-16).**

- **63** (an index is a method call, amended 2026-09-19: the index answers what `at` answers, `?V`)
  — `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_dict` (present key → `1`; `Dict<string, ?i32>` → `null`; absent key → `null`, and
  the program goes on), `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_past_the_end_is_null` (`xs[9]` is decision 47's `null`) and
  `modules/decisions-taken/negative_index_counts_from_end-139/cases/index_at_optional` (`Dict.at` / `String.at` by name answer `?V`, `null` for absent), with
  `modules/decisions-taken/negative_index_counts_from_end-139/cases/string_at` for the present-index reader — all on four targets. The fixture C-16 names
  `index_an_index_past_the_end_answers_zero` is a `src/codegen/tests` fixture, not a cell of this
  suite.
- **64** (a wrapper per host-bound std `declare fn`) — `modules/std/cells/std_erlang_node`: `erlang.node()`
  prints `nonode@nohost` on erlang (C-03's erlang half, `a8db11e4`); commonJS and wasm **refuse** it
  with `std-unsupported-on-target` (two `snapshot/targets/<t>/` departures); beam prints it too since front 17 step 5
  wired `beam_asm.zig`'s wrapper for a plain `module:symbol` target (C-03's beam half, for
  that form only). The commonJS/wasm diagnostic names the function called, at the call
  (`std/erlang.node`, at `erlang.node()`); a namespace import none of whose unsupported functions is called
  is refused at the import, naming the module and the functions it lacks
  (`modules/decisions-taken/import_alias_on_type_and_folder_namespace-110/cases/import_std_folder_namespace/snapshot/targets/wasm/`).
- **65** (the formatter measures width) — **no cell here**, and none can be: the suite runs programs,
  and decision 65 is about the text `botopink format` writes. Its evidence lives in the formatter's
  own tests (`modules/compiler-core/src/format/`, C-12's rows). This suite meets it only as a
  consumer: `deps/shapesdsl/src/shapesdsl.bp`'s `CustomNode(…)` line is broken the way today's
  formatter breaks it (`fits` stops at the first `concat`), and will be re-broken when C-12 lands.
- **66** (`format --check` over the whole project) — the three `modules/*` cells decision 66 named as
  red (`mod_tree`, `std_import`, `two_modules`) are **formatted**: `botopink format` inside each
  (brace bodies expanded, `import {a, b}` spacing) and `botopink format --check` exits 0 in all four
  `modules/*` roots and in `deps/shapesdsl`. The cells' output did not move. Nothing in this suite
  *calls* `format --check`, and no gate stage does (decision 524, amending 66): the commit hook
  formats each staged `.bp` (`scripts/git-hooks/lib/format-staged.sh`), so `test/` and `modules/`
  are committed canonical — a cell is written formatted (`botopink format <file>`) before its
  snapshot is recorded, since the hook's reformat would move a pinned `<file>:<L>:<C>`. Two
  things are outside the walk, both by structure (`format_cmd.zig`), never by a list: `modules/lexer/cases/lexer_error_in_imported_module/src/pattern.bp` — the bad escape the cell exists to
  refuse — by the second arm (gate-c: a `.bp` under `modules/<cell>/` that the cell's `snapshot`
  files name and that does not lex or parse). A `modules/<cell>/snapshot/` record pins a
  `<file>:<L>:<C>`: reformatting the file it names moves the pinned line with it, in the same
  change (`modules/decorator/cases/decorator_imported_function_name_conflict` pins `src/main.bp:21:3`, the
  `#[tag]` under an `@emit(…)` argument the formatter opens over four lines).

1.0.11 front 14 step 1 adds `modules/comptime/cases/comptime_method_nothing_answers` — a decorator body (untyped)
calling `.frobnicate(1, 2)` on a string, which no primitive type and no host function answers: the
compiler refuses it before any comptime runtime runs, the message names the call by its `line:col`
in the body and the caret is the annotation that ran it.

**`@panic` and `@todo` abort with stdout intact and a non-zero status on all four backends**
(`modules/panic/cases/panic_aborts`, `modules/todo/cases/todo_aborts`, `abort`). On beam a function whose whole
body is `@todo()` is emitted and raises the builtin's own `{todo, <<"not implemented">>}` —
re-measured by front 12 of 1.0.11-beta (it used to be dropped, and the abort was `undef`).
A `@panic`'s message reaches stderr unchanged on all four (`modules/panic/cases/panic_library_message`, a
library-built message with quotes and a non-ASCII dash, `stderr` in `output/`, decision 430, 144 B-41):
erlang and beam write the message itself, not the term with its bytes as numbers; wasm writes it
before the trap.

The Conformance steps of 144 B-13, B-26, B-31 … B-35, B-37 … B-41 (boxes 3, 4) add, each red on its
step's base and green on the tip unless named a pin: `modules/decisions-taken/store_answers_result_store_error-304/cases/behavior_method_result_dispatch` (a
behavior method `-> @Result` through a behavior-typed parameter, its `default fn` included — a pin:
B-13 changed no code); `modules/decisions-taken/dict_bump_counts-340/cases/dict_bump` (`Dict.bump` on a plain dict, four targets),
`modules/decisions-taken/dict_bump_counts-340/cases/dict_bump_on_module_var` (`Dict.bump` on a module `var`, atomic on the BEAM, decision 547 (ii)) for B-26; `modules/decisions-taken/comptime_badarith_message-472/cases/comptime_integer_division_by_zero` (`7 / 0` at build is
`comptime-badarith`) for B-32; the wasm cell refusals of decision 481 for B-33 —
`modules/decisions-taken/external_wasm_labelled_cells-481/cases/external_wasm_fn_cell_string`, `external_wasm_op_cell_not_string`,
`external_wasm_wasi_cell_not_enum`, `external_wasm_std_cell_not_string` (a value of another kind, at
the argument), `external_wasm_unknown_label`, `external_wasm_two_cells` (at the argument),
`external_wasm_op_unknown` and `external_wasm_wasi_unknown` (at the annotation),
`external_wasm_fn_cell_signature` (at the argument, decision 610); and `modules/if/cases/if_binding_before_loop_closure` (an explicit `if (x) { v -> … }`
before a `for` body binding `v` again — the OTP compiler refused beam's `make_fun3` on B-34's base).

144 B-10 (decision 430, the gaps a library works around) adds `modules/two/cases/two_modules_one_type_name` —
two modules each declaring `pub type Order` with members of one name, each reaching its own (erlang
called into the other module's unit: the link index keys an export by its bare name) — and its test
twin `test/two_test_modules_one_type_name`, two test modules of one project doing the same under
`botopink test`. The same step's `modules/associated/cases/associated_fn_as_value` names an associated fn without a
call — `apply(1, Box.wrap)`, `val w = Box.wrap;`, an imported type's and an enum's — a function value
of its declared signature (it was a fresh variable to the checker, an unbound variable on erlang, an
abort on beam, unplaced on wasm). `modules/decorator/cases/decorator_member_record_update` pins a record update
in a member `decl.addMember` adds — `Point(..self, y: 0)`, `Point(..v, z: z)` — on every target (it was
emitted `new T(v, x)` on commonJS before 144 B-14).
`modules/package/cases/package_module_namespace` reads a dependency's module through its namespace — a type, a
constructor, a call, a function value (`unknown type 'shapes.Pt'` before).

`modules/method/cases/method_behavior_parameter_implementer` passes an implementer to a method's and an
associated fn's behavior-typed parameter (`expected Styleable, got Prop` before).

`modules/decisions-taken/compiler_same_compares_declaration_handles-666/cases/decorator_argument_decorator_name` hands a decorator's name, and an array of names, to a
`Decorator` / `Decorator[]` parameter of a decorator in a submodule (`expects Decorator, got fn(Decl)
-> void` before).

`modules/decisions-taken/compiler_same_compares_declaration_handles-666/cases/decorator_argument_decorator_alias` (144 B-10 Conformance) hands the names through the
declaring module's namespace (`markers.email`, a `mod` child read only in an annotation's argument)
and under an import's alias (`unbound variable 'markers'` before: the namespace's item was added
for a read in a body alone).

`modules/dot/cases/dot_shorthand_enum_not_imported` writes `.Top` and `.Two("x")` where a dependency's `Mode` is
expected and the module never names `Mode` (commonJS and erlang emitted it unbound, the checker refused
the payload form `unbound variable 'Mode'`); the transformed program imports the enum
(`Env.implicitEnumImports`).

`modules/decisions-taken/inline_parameter_record_type-207/cases/template_builds_inline_props` — a template's built `Greeting(name: "…")` against `props:
type(…)` in the declaring module (`inline-type-position` before).

`modules/decorator/cases/decorator_lambda_many_locals` pins a decorator lambda with 120 locals on the comptime
runtime.

`modules/decisions-taken/dict_bump_integer_values_only-534/cases/dict_bump_non_integer` (decision 534) — `Dict.bump` on a plain `Dict<string, f64>` is refused,
located at the call (it was accepted and answered `1.5`).

What cannot be tested from botopink at all, and why: `@typeInfo` / `@makeRecord` / `partial` / `omit`
/ `pick` (they produce types, and asserting on emitted text is the snapshots' job). Struck from this
list by C-16, each with the cell that covers it: `pub default mod` / `pub default fn`, `compiler.custom` and a module shipped via `files` (`modules/decisions-taken/dependency_modules_kept_by_build-515/cases/local_dependency`, a local dependency needs no network);
"no external target for the active backend" (`modules/external/cases/external_erlang_only`, a cell refused on
two targets through a `snapshot/targets/<t>/` departure each — `botopink run --target <t>` is not
target-independent, which is what a refusal snapshot lacked); `@panic` / `@todo` (a cell compares stdout **and**
the status through `abort`, so an aborting program is exactly what it can assert).

Decision 536 (144 B-64-a): a `// targets:` line in a single-file `test/` suite is a comment — the runner
reads a project suite's `botopink.json` `"targets"` alone — and the seven suites that carried one
(`behavior_host_dispatch`, `bodyless_fn`, `external_host`, `external_markers`, `mocks_decorator_double`,
`mocks_handwritten_double`, `module_init`) are project suites, each `test/<name>/botopink.json` naming
`"targets": ["commonJS", "erlang", "beam"]` and its file under `test/<name>/test/`. `run.sh --self-test`
proves a single file's `// targets:` line narrows nothing (`comment_is_no_narrowing`), and an excluded
target's audit builds the suite and then compiles its tests for that target, since these suites carry the
host binding in a test file.

`modules/decisions-taken/asset_size_hash_open-538/cases/embed_size_i64` (decision 538, 144 B-12-c) — `Asset.size` binds to an `i64` and sums past the `i32`
range (`expected i64, got i32` on the parent); `hash` stays the SHA-256 in lowercase hex. `Asset.open()` (an
`Asset` read as fs-a's `File`) waits for that `File` (decision 540): it has no cell here yet.

Decision 530's cell `modules/decisions-taken/template_hole_writes_print_text-530/run/src/cases/template_hole_prints_every_value` (a template hole of a record, an array, a tuple,
`null`, an optional, an enum, a `Display` type and a parameter, written as the `@print` beside it, on the four
targets): erlang and beam already answered it, commonJS since 530, wasm since front 164 s2 — a hole that is no
string, number or boolean writes its value's printed text through the capture (`codegen/wat/AGENTS.md`
§ `text_capture`), where it wrote the value's address (an optional's absence wrote `undefined`).

Decision 545 (`import-of-failed-module` names the failed module's file at its end, in parentheses) moves the five
cells that quote it — `import_of_failed_module`, `imported_declaration_error_location` (`b/b` and `main`),
`lexer_error_in_imported_module`, `bpp_decorator_last_line` and `bpp_diagnostics_located`: each importer's snapshot
ends `(src/shapes.bp)`, the label the failed module's own refusal is printed at (`Reflection.diagLabels`); a
dependency's module is labelled by its module path, `(a/client.bp)` and `(b/b.bp)` in `imported_declaration_error_location`.
Group 431 (144 B-07)'s Conformance step adds `modules/decisions-taken/failure_kinds-492/cases/std_failure_attempt_abort_kinds` — `@todo` and `x!` over `null` under
`attempt` are `panic` (492), on the four targets — and
`modules/decisions-taken/failure_kinds_exact_every_target-527/cases/std_asserts_throws_over_attempt` — `testing.asserts`' `throws` / `throwsWith` generic over the body (493),
a host raise's message without its erlang class (527 (4)); narrowed to commonJS, erlang and beam.
Decision 546 adds `modules/decisions-taken/failure_kinds_exact_every_target-527/cases/std_failure_attempt_crash` — a `case` no arm matches under `attempt` answers `crash` on
erlang and beam, where a raise of a binding outside std is `host` (`modules/decisions-taken/failure_kinds_exact_every_target-527/cases/std_failure_attempt_host`); the cell is
narrowed to erlang and beam, commonJS and wasm lacking the host binding it calls. 144 B-90 widens it to commonJS (a
Node form of the binding answers `null`, which the emitted `case` raises on reading its tag: `crash`, the engine's
message in `snapshot/targets/commonJS/`) and adds the commonJS half of 546: a binding declared outside std without
`result: true` is a function of its module whose call runs through `__bp_host_mark`, which marks its raise `host`
(`__bp_host`); std's `failure` forms and the abort guard read an unmarked raise as `crash`
(`modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_crash`: a binding answering a number where a `string` is declared, whose `trim()` raises in the
program's own code). `modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_panic` claims `panic: boom` for an uncaught `@panic` on commonJS, erlang and
beam, and on wasm too (164 s2c); `modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_overflow` claims `panic: integer overflow: + on i32 at
src/main.bp:7:14` for an uncaught overflow on the four targets, and `modules/decisions-taken/failure_kinds-492/cases/std_failure_attempt_abort_kinds` and
`modules/decisions-taken/failure_kinds_exact_every_target-527/cases/int_division_by_zero_is_panic` answer `Error(panic)` for an overflow and a division by zero under `attempt`
on wasm as on the others (527 (3), 492).
Decision 535 (an uncaught abort writes the `Failure` an `attempt` would answer, `<kind>: <message>`) adds
`modules/decisions-taken/runtime_abort_prints_failure-535/cells/abort_text_host` (an uncaught host raise writes `host: boom` on commonJS, erlang and beam) and tightens
`case_no_arm_matches_raises` and `float_nan_infinity_words` to the whole text of their erlang and beam aborts
(`crash: {case_clause,'Square'}`, `crash: badarith`). The `panic:` text of an uncaught abort is claimed by
`modules/compiler-core/src/codegen/tests/builtins.zig` on commonJS, erlang and beam; wasm writes the message alone
until its codegen writes the `Failure` (front 164).
Decision 532 (a raise at build is located at the call that raised, in its own file, with the calls that led to it)
moves `decorator_raise_names_body_file` and `template_raise_names_body_file` — the refusal is now `deco.snap` /
`tpl.snap` (`at src/deco.bp:3:5`, `from src/main.bp:9:3`), `main.snap` holds the header alone, the message no longer
ends with `— raised at … while … ran the body` — and adds the `from <file>:<line>:<col>` record (`called from`
lines, innermost first, after `at` and `label`; the CLI's former `cell_snap.zig`, now `lib/src/records.bp`) to
`decorator_helper_raise_located` (`from src/main.bp:13:13`, `from src/main.bp:17:3`), the three `*_unseeded` cells (the `comptime` or the annotation that ran the build is
the last frame).
Decision 533 (every division and remainder by zero at build reads `(division by zero)`, located at the operator)
adds `modules/decisions-taken/division_by_zero_at_operator-533/cases/comptime_remainder_by_zero`, `comptime_nested_division_by_zero` and
`comptime_division_by_zero_in_helper`, and moves `comptime_float_division_by_zero`,
`comptime_integer_division_by_zero` and `hole_any_call_raises` from the expression's first token to the operator
(`hole_any_call_raises` gains the cause too).
Decision 545's file is the label the failed module's own diagnostics print, so `imported_declaration_error_location`
answers `(a/client.bp)` and `(b/b.bp)` (a dependency's module is labelled by its module path), a program module's cells
unchanged. Decision 532 is finished by `modules/decisions-taken/build_raise_located_with_frames-532/cases/template_own_raise_located` (a template its own module declares is
located at the raising call in that module's file, the use as `from`) and by a call's frame being pushed only after its
receiver and arguments are evaluated: `hole_any_call_raises` loses its `from src/main.bp:47:12` (`(a / b).toString()`
was never entered).
