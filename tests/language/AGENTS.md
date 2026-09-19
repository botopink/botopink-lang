# tests/language — botopink language tests (fronts 15 and 17)

Tests written in botopink, running the emitted program. Front 15 pinned decision 8
(`specs/1.0.4-beta/08-review-backlog/decision-8-language.md` in the meta workspace): `case` and
patterns (§5), tuples and labels (§6), `loop` (§10), and the parts of `is` (§4), unions (§3),
`unknown` (§2) and printing (§7) those scenarios use. Front 17
(`specs/1.0.4-beta/17-language-test-expansion/README.md`) added the rest of the language surface —
effects (§9), comptime parameters and `@Expr` templates, decorators and `@emit`, host externals (§8),
generics and `behavior` dispatch, optionals, closures, primitive methods, and modules.

**Tests describe the language, not today's compiler.** A scenario the compiler gets wrong stays as
written and is listed in `expected-failures.txt` with the row of the front that makes it pass. Never
rewrite a test to match current behaviour.

## Layout

| Path | Kind | Passes when |
|---|---|---|
| `test/<area>_<group>.bp` | `test "…" { … assert … }` blocks, run by `botopink test --target <t> --json` | every test reports `ok` |
| `run/<name>.bp` + `<name>.out` | a whole program (`pub fn main`), run by `botopink run --target <t>` | exit 0 and stdout equals `.out` byte for byte |
| `reject/<name>.bp` + `<name>.expect` | a program that must not compile, run by `botopink check` | exit ≠ 0, stderr contains `.expect` line 1, and ` --> src/main.bp:<line 2>` when line 2 is present |
| `modules/<name>/` | a whole **project** — its own `botopink.json`, `src/` tree and `expected.out` — run by `botopink run --target <t>` | exit 0 and stdout equals `expected.out` byte for byte |
| `expected-failures.txt` | the list of known failures | — |
| `run.sh` | the runner | — |

Every cell is copied into its own scratch project, so a parse error fails only that cell. Test names
start with the decision-8 section they pin (`test "§5.4 …"`) when there is one, so a failure points at
the rule; a capability decision 8 does not legislate gets a plain sentence.

Areas, by filename prefix: `case_*`, `tuple_*`, `loop_*` (decision 8 §5, §6, §10), `effect_*`,
`comptime_*` / `decorator_*`, `external_*`, `generic_*`, `string_*` / `array_*`, `type_identity_*`,
`optional*` (`optional`, and decision 54's `optional_null_pattern` / `optional_variant_pattern`),
and the singletons (`closure_capture`, `recursion`, `expr_sugar`, `fn_defaults`, and the
decision-28/30/33 cells `nullish_default`, `paren_receiver`, `type_suffix`, `bodyless_fn`,
`curried_call`, `index_expression`). One scenario group per
file: a parse error is the blast radius, so nine `#[@External]` declarations in one file mean one
unparseable annotation hides the other eight.

### The `modules/` kind

The kind for what a single file cannot express: `pub mod`, `import … from "<module>"`, a folder index
(`shapes/mod.bp`), a private `mod` leaf, and `from "std"` used from a *user* project rather than from
inside `libs/std`. The directory **is** the project; the runner copies it whole and compares stdout
with `expected.out`. A cell that needs a git dependency is deliberately out of scope — that is
`zig build test-libs`' job, and this suite must not need the network.

## The targets

Measured at `c2dd780`, OTP 29, node v25.8.0.

| Target | `botopink test` | `botopink run` | In the suite |
|---|---|---|---|
| commonJS | yes | yes | every kind |
| erlang | yes | yes | every kind |
| wasm | refused — "supports only the commonJS and erlang targets" | yes, it executes | `run/` and `modules/` only |
| beam | refused — the same message | writes `out/*.S` and stops — BEAM Assembly is an artifact, not a run | `run/` and `modules/`, via `--target beam`; **not in `--target all` yet** |

`test/` cells therefore run on commonJS and erlang; `run/` and `modules/` cells run on those two and
on wasm, and on beam when asked for; `reject/` runs once (target `*`, `botopink check` is
target-independent).

**beam executes, in two more commands** — decision 8 of `specs/1.0.5-beta/decisions-taken.md`,
re-measured here:

```bash
$ botopink run --target beam
wrote out/main.S — BEAM Assembly is an artifact; compile with `erlc +from_asm out/main.S` …
$ find out -name '*.S' | while read s; do erlc +from_asm -o out "$s"; done
$ erl -noshell -pa out -eval 'main:main(), halt().'
hi
```

`run.sh`'s `exec_run` is exactly that path (see its `§ beam` comment). Every `.S` is assembled, not
only `out/*.S`: a `mod` tree and a `from "std"` import emit nested directories today
(`out/shapes/circle.S`, `out/std/…`), and a module left unassembled is an `undef` at run time rather
than a compile error — `modules/mod_tree` passes only because of it. `erlc` and `erl` are already
gate dependencies (every erlang cell; stage 5 `scripts/beam_export_audit.sh`), so beam costs the gate
no new tool.

beam is **not** in `--target all`, and that is scheduling rather than doubt: front 13's policy 3
changes how many `.S` files a program emits and where they live, so a default-on runner would be
written against a layout that is about to move. Flipping it on is one line of `run.sh`
(`all) targets=(commonJS erlang wasm beam)`) plus a re-run of the beam cells; it belongs to 13's
closing step. The beam rows of `expected-failures.txt` already exist and
`tests/language/run.sh --target beam` is green. Re-measured at `b5a9b85d` plus this front's
decision-52/53/54/55 cells: **42 results, 19 passed, 23 expected failures, 0 failed** — 18 of
them `run/` and `modules/` results (7 passing) and 24 `reject/` results, which run once under
`targets[0]` and are counted by both runs. The 11 beam lines are owned by `03-beam` (steps 2, 3
and 4), `01-checker` step 4 and `03 handover 15`; four of them name `13 step 18` as well, because
a record and a variant cannot print their names before a value carries one.

## Running

```bash
zig build test-language                                   # the installed botopink, every target
zig build test-language -- --target erlang
tests/language/run.sh --compiler <botopink> --only test/case_arms.bp
tests/language/run.sh --compiler <botopink> --only modules/two_modules
tests/language/run.sh --target beam                       # opt-in; needs erlc + erl
```

`--lib-root` defaults to `<compiler>/../../libs` (where `from "std"` resolves).

## expected-failures.txt

```
<target: commonJS | erlang | wasm | beam | *> | <path>[::<test name>] | <owner row> | <reason>
```

A line whose target is not in the current run is skipped, not failed — which is what lets the beam
rows sit in the file while beam stays out of `--target all`.

- The owner row must exist in the specs: a front of the current milestone
  (`specs/1.0.5-beta/fronts.md`) and one of its numbered steps, written `<front> step <n>` —
  `01 step 4`, `02 step 6`, `04 step 1`, `05 step 3`, `13 step 18`. A line may name more than one
  row, comma-separated, when the failure needs both to land (`04 step 1, 13 step 18`: the separator
  half is the backend's, the record and variant halves need a value that knows its own type).
  **A cell whose owner is nobody is reported to the maintainer, not listed against an invented
  row** — and not committed until the row exists. When a milestone closes, the next milestone's
  first landing repoints every line before any front deletes one, so that two commits never touch
  the same line.
- A path-only entry is for a cell that does not compile; a cell that compiles lists its failing
  tests by name. A cell may fail differently per target and then carries one line per target, with
  two different owners (`test/loop_break_value.bp` is the worked example).
- A `reject/` `.expect` names a short key phrase of the diagnostic decision 8 sketches (`use _ {`,
  `not exhaustive`, `use loop (`…) and the location of the offending token. The front that implements
  the diagnostic fixes its final wording and updates the `.expect` in the same change.
- The runner fails on: an unlisted failure; a listed test that now passes ("delete its line"); a
  listed path or test that does not exist; a path-only entry on a cell that compiles; a malformed line.

## Status and the gate

Counted on disk at `b5a9b85d` + the decision-52/53/54/55 cells:

```bash
ls test/*.bp    | wc -l   # 49
ls run/*.bp     | wc -l   # 15   (each with its .out)
ls reject/*.bp  | wc -l   # 24   (each with its .expect)
ls -d modules/*/| wc -l   #  3
find . -name '*.bp' | wc -l   # 95 — 91 cells, plus the 4 extra .bp of the modules/ projects
```

**91 cells**, of which three are the `smoke` files (one per single-file kind) — so **88** besides
them, by area:

| Area | Cells | Total |
|---|---|---|
| `case` (§5) | 8 test + 2 run + 9 reject | 19 |
| tuples (§6) | 6 test + 1 run + 2 reject | 9 |
| `loop` (§10) | 6 test + 5 run + 2 reject | 13 |
| effects (§9) | 5 test + 5 reject | 10 |
| comptime, templates, decorators | 3 test | 3 |
| host externals (§8) | 2 test + 1 reject | 3 |
| generics and behaviors (§1) | 1 test + 2 reject | 3 |
| printing (§7) | 3 run | 3 |
| core: closures, recursion, primitives, optionals (decision 54), sugar, defaults | 8 test + 1 run + 1 reject | 10 |
| run-time type identity (§4, §7 — `13-module-identity`) | 4 test + 1 run | 5 |
| the forms `109f6c9` landed (decisions 28, 30, 33; 15's R1–R3, R5, R8) | 5 test + 1 run + 1 reject | 7 |
| modules | 3 `modules/` cells | 3 |

Classification at botopink-lang `b5a9b85d` + these cells (node v25.8.0, OTP 29),
`zig build test-language`, every target of `--target all` together:

```
language tests: 265 passed, 69 expected failures, 0 failed
```

`expected-failures.txt` holds **80** lines: these 69 plus 11 that only `--target beam` exercises (the
12 `*` reject lines are counted by both runs). Every owner cell names a 1.0.5-beta section, re-checked
against `specs/1.0.5-beta/` on 2026-09-18. By the row that comes first on the line —
**01-checker 42 · 02-erlang 12 · 03-beam 9 · 05-wasm 8 · 04-js 5 · 13-module-identity 4**. **23**
lines name a second row that has to land before the line goes (the §7 formatter's record and variant
halves, and the identity cells behind a checker row).
`tests/language/run.sh --target beam` adds 18 `run/`+`modules/` results of its own — 7 passing, 11
listed — beside the same 24 `reject/` results; those 11 lines are skipped by `--target all`.
See § the targets.

**Every number in this section and in `expected-failures.txt`'s header is recounted from the file,
never adjusted by a delta** — decision 59 of `specs/1.0.5-beta/decisions-taken.md`, taken
2026-09-18 after two fronts re-tallied the same block from different baselines in one merge window
and were individually right and jointly wrong. The header carries the counting command. This section
had been stale by nine results and fourteen lines for that reason when `fe871ed` recounted it, and by
the cells below it again here.

**Where an owner cell is not `<front> step <n>`.** Two of this milestone's rows are *handover
sections* of a front's README — "Handed over by `15-language-surface`", prose with a heading and no
step number. The cells that name them read `<front> handover 15`. One row has neither a step nor a
handover section and the owner cell says so (`04 (no step; reported 2026-09-18)`): front 04 owns
`commonJS.zig`, so the *front* is certain even though no step names the defect. Both shapes are
reported to the maintainer rather than papered over with an invented step number.

`zig build test-language` is a stage of `scripts/gate.sh` (after `test-libs`) and a step of the CI
`test` job (ubuntu + macos). When a front makes a listed test pass, the gate fails with "now passes:
delete its line" — the landing commit of that front deletes the line.

## Notes for whoever writes the next cell

Shapes that do not parse — **re-measured at `aab5489`** with `botopink check`, after front 15
(`specs/1.0.5-beta/15-language-surface/README.md`) landed (`109f6c9`). Five of the seven rows this
table carried are gone: they parse. What is left is two rows and one correction.

| Shape | At `aab5489` | Decision |
|---|---|---|
| a module-level `var` | `error: this token cannot appear here` at `1:1`, `var` and `pub var` alike | **still absent.** decision 28 of `specs/1.0.5-beta/decisions-taken.md` lists it as landed at `109f6c9`; it did not — front 15's own closeout says "module-level `var` — measured only", and `fronts.md`'s front-15 row repeats that. It needs a `.@"var"` arm in `parser.zig:441` **and** a `mutable` field on `ast.ValDecl`. A module-level `val` does parse |
| a block-shaped statement not last in its block | `error: this token cannot appear here` at the statement **after** it — in any block, not only a decorator body: `if (1 > 0) { … }` then `@print("b");` reds at the `@print`. With a `;` after the `}` it checks | **decision 29** — the `;` goes. Front 15 wrote the 76-line parser half and deliberately did not commit it: rejecting the trailing `;` rejects `libs/std`'s embedded prelude, so no single front can land it green. 44 sites in this suite, counted by front 15 |

**Struck, because they now parse.** Each was measured at `aab5489`:

| Shape | Was listed as | Now |
|---|---|---|
| §5.1 `Pattern { body }` arms, and §5.3b section arms | `06 N22` | parse; `test/case_sections.bp` fails in inference like every other `case` cell (`expected string, got void`), not at the `{` |
| `adder(3)(4)` — calling the result of a call | "make it parse" (14) | **parses** (15's R2). It does not *check*: `error: unbound variable ''` at the second `(` — the call carries its callee in `calleeExpr` and inference never types it. `test/curried_call.bp` asserts it and carries the two lines |
| `#(a: i32, b: string)[]` — an array of labeled tuples | "make it parse" (14) | **parses, checks and runs on all four targets** (15's R1), with `@Result<i32, string>[]` and `(i32 \| string)[]`. `test/type_suffix.bp` |
| `??` | "deliberately absent (14) — it duplicates `catch` and `?.`" | **parses and runs on all four targets** (15's R8, decision 28). The premise was false as well as the verdict: `catch` is `@Result`-only — `val b = a catch 0;` on an `a: ?i32` reds with `` `try` requires a @Result<D, E> value, found 'optional' `` — so nothing else gives an optional a default. `test/nullish_default.bp` |
| `xs[0]`, `xs[0..2]`, `d["k"]` — an index expression | "there is no index expression in the grammar" | **parses and checks** (15's R5, decision 30). **No backend lowers it**: the form reaches the unrecognised-builtin path, so `run/index_expression.bp` is listed against all four — and beam is the one that fails *silently*, exit 0 with the index dropped |
| a bodyless `fn` with `-> void` | "a bodyless top-level fn with no return type" — a form nobody wrote a rule for | **parses and runs** (15's R7, decision 33), and the missing return type is now its own named error, `bodyless-fn-needs-return-type`. `test/bodyless_fn.bp` and `reject/bodyless_fn_no_return_type.bp` |
| `(a == b).toString()`, and `(sql """ab""").length` — a method on a parenthesised expression | open / "needs a dependency to measure" | **one production, and it parses** (15's R3). `(1 == 2).toString()` prints `false` and `("ab").length` prints `2` on commonJS, erlang and wasm; no dependency is needed to measure it. `test/paren_receiver.bp` |

**Two commonJS defects these cells turned up that no step of `04-js`
(`specs/1.0.5-beta/04-js/README.md`) names.** Both are reported to the maintainer; front 04 owns
`commonJS.zig`, so the front is certain and only the row is missing.

1. **`42.toString()` — a method on a number literal** (15's R3) checks, and prints `42` on erlang and
   wasm, but the emitter writes `__bp_print(42.toString())` and node refuses it with
   `SyntaxError: Invalid or unexpected token`, because `42.` reads as a float. `(42).toString()` is
   the emitted form that would work. No cell asserts it — `test/paren_receiver.bp` records it in a
   comment instead, because a listed line needs a row.
2. **The optional-binding `if` tests `!== null`, and `?.` answers `undefined`.** `if (x) { n -> … }`
   emits `(() => { const n = …; if (n !== null) { … } })()`, so an absent value arriving from a `?.`
   chain takes the present branch and binds `undefined`. `o.inner?.v ?? 9` answers `undefined` on
   commonJS and `9` on erlang and wasm. `test/optional.bp` does not see it because its optionals are
   explicit `null`s. This one **is** asserted — `test/nullish_default.bp::?? chains after ?.` — with
   an owner cell that says outright that it has no step.

**A third, with owners.** A tuple label does not survive a generic array method: `rs.at(0).b` on an
`rs: #(a: i32, b: string)[]` answers `undefined` on commonJS, raises `bad map: {1,<<"x">>}` in
`map_get/2` on erlang, and answers `0` on wasm. That is §6 T4 and the rows exist — `04 step 2`,
`02 step 4` — so `test/tuple_labels.bp` asserts it and carries the two lines.

**The range pattern in a `case` arm — decision 53 settled the spelling and `run/case_range_value.bp`
now pins the endpoints.** Decision 53 (2026-09-18) **amended** decisions 20 and 36 to Zig's split:
`...` is inclusive in a **pattern**, `..` is exclusive in a **slice** and in `loop (a..b)`, and no
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

**A `.out` may encode a decision no backend implements yet, and that is the point.** Five cells do —
`run/loop_yield_then_break_value.bp`, `run/loop_break_value_then_yield.bp`,
`run/loop_yield_then_bare_break.bp` (decision 55), `run/loop_condition_no_break.bp` (decision 52) and
`run/optional_null_pattern.bp` (decision 54). Each `.out` is the decision's answer, so when the
backends are moved against it **exactly one file per cell** is involved and no `.out` is renegotiated
in the same commit as an emitter. Each cell's header comment carries the per-backend measurement it
was written against, dated and with the commit.

**Read a loop's result as `length` + `join(",")`, not as a printed array.** `@print` of an array is
decision 8 §7's separator row and erlang and wasm still get it wrong (`[20,40,60]` for
`[20, 40, 60]`), so a cell that prints the array carries a §7 line on two backends and the §10 rule
it means to assert is hidden behind it. The five `loop` cells above read the result instead — and it
is what makes `run/loop_yield_then_bare_break.bp` show that **wasm alone already answers decision
55's fifth row**, as a pass, rather than as a §7 near-miss.

**Decision 55 turned a cell that passed on all four backends into one that fails on all four.**
`test/loop_collection.bp`'s last test asserted `loop ([1, 2, 3]) { x -> break x * 2; }` → `[2, 4, 6]`,
and every backend agreed, because they share one accumulator shape and none of them stops at a
`break`. Decision 55 says `break <value>` contributes its value **and ends the loop**, so the answer
is `[2]`; the assertion was rewritten to the language and now carries two lines. This is the rule at
the top of this file working in the direction it is usually not noticed in: four backends agreeing is
not evidence, and a decision can make a green cell red.

**Where front 02 has no row for the collection loop.** Decision 55 says outright that the cell comes
first and "then one row per backend against it". `04 step 3` and `05 step 4` are both titled
`break <value>` and `03 step 3`'s D7 asks for exactly this measurement, so those three lines name
steps. Front 02 has no §10 collection-loop step — its step 5 is the *condition* loop used as a value,
a different shape — so its four lines read `02 (no step; decision 55, reported 2026-09-18)`, the shape
§ expected-failures.txt documents for a certain front with a missing row. Reported to the maintainer.

**Structural equality of two values of the same type is not legislated, so no cell asserts it.**
`Person(name: "Ana", age: 30) == Person(name: "Ana", age: 30)` answers `false` on commonJS (reference
equality on the class instance) and `true` on erlang (one map). No decision of this milestone settles
it and no front owns it, so `test/type_identity.bp` states the omission in a comment and asserts only
what **is** settled — that two *different* types with the same fields are different values. Reported
to the maintainer; a sentence would turn the comment into two assertions.

What cannot be tested from botopink at all, and why: `@Context` / `use` (lowers to React hooks on
commonJS, no erlang lowering — it needs a host framework); `pub default mod` / `pub default fn` and
`@ExprCustom` / `q.custom` (the package handle and the custom-AST carrier are a *dependency*'s
surface); `.d.bp` files shipped through `botopink.json` `files` (same); "no external target for the
active backend" (`reject/` runs `check`, which is target-independent); `@typeInfo` / `@makeRecord` /
`partial` / `omit` / `pick` (they produce types, and asserting on emitted text is the snapshots' job);
`@panic` / `@todo` (a cell that aborts reports no result through `--json`).
