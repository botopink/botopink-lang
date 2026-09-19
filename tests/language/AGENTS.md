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
`tests/language/run.sh --target beam` is green. Re-measured at `b09bf9c6`: **42 results, 19 passed,
23 expected failures, 0 failed** — 18 of them `run/` and `modules/` results (7 passing:
`run/smoke.bp`, `run/tuple_print.bp`, `run/print_nested.bp`, `run/loop_yield_and_break.bp` and all
three `modules/` cells) and 24 `reject/` results, which run once under `targets[0]` and are counted
by both runs. Recounted from the file: the 11 beam lines are owned by `03 step 3` (5), `03 step 2` (3),
`01 step 4` (2) and `03 handover 15` (1) — **no step 4 of `03-beam`, and three of them, not four,
name `13 step 18`** as a second row, because a record and a variant cannot print their names before a
value carries one.

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
<target: commonJS | erlang | wasm | beam | *> | <key> | <owner row> | <reason>
```

A line whose target is not in the current run is skipped, not failed — which is what lets the beam
rows sit in the file while beam stays out of `--target all`.

### The three shapes of `<key>`, and the `\|` escape

Which shape the key is **is part of the claim**, so the three are distinguishable by eye and each is
checked differently. One live example of each:

```
1  erlang | test/case_arms.bp | 01 step 4 | …
2  erlang | test/case_guards.bp::§5.3 a guard reads the variables its pattern bound | 02 step 3 | …
3  erlang | test/case_tuples.bp::§5.1 P6 arms are tried in order ;; §5.1 P7 #(a, ..) binds the first element only | 02 step 3 | …
```

1. **A path alone — the cell does not compile.** Strict in *both* directions: if the cell compiles,
   the run fails with "compiles: list its failing tests by name". Five fronts read the file for that
   reading and nothing below widens it.
2. **A path and one test name — the cell compiles and that test fails.**
3. **A path and several — the cell compiles and each of them fails.** `::` splits the path from the
   first name, ` ;; ` (one space either side) separates the names. Shapes 2 and 3 are the same shape
   and the same check; 2 is the one-name case of it. A named test that now passes fails the run with
   "drop it from the line, and delete the line when it names no other", so a cell that is fixed test
   by test is tracked test by test instead of going dark until the last one lands.

**`\|` is a literal `|`, anywhere on the line.** The line is split on `|` only where the `|` is not
preceded by a backslash, which is the only way a test name that carries the file's own separator can
be written — `test/case_exhaustive.bp::§5.1 P5 a variable bound from Maybe<i32 \| string> is i32 \|
string` is the one line that needs it. Nothing else is escaped, and the escape is greppable:
`grep -nF '\|' tests/language/expected-failures.txt`. The counting command in the file's header
splits the same way (`re.split(r'(?<!\\)\|', l)`); a plain `l.split('|')` miscounts that line's
fields and therefore its owner row.

**A named-test entry whose cell does not compile at all is still honoured** — a cell that does not
compile passes nothing — and the run prints, on that line, "the cell does not compile, so its N
listed tests did not run". That is not a loophole, it is the state the file is in while the front that
makes the cell compile is in flight: seven fronts share this file and their trees differ by hours. The
six lines front 12 converted at `b09bf9c6` read that way on `feat` and read per-test in front 01's
step-4/5 tree, which is what let 01 commit a green gate without rewriting a file it does not own. The
shape a line *cannot* have is the one it had before: path-only on a cell that compiles, which fails
unconditionally and can be neither deleted (its tests fail) nor rewritten (by anyone but front 12).

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
  tests by name, one line or several (§ the three shapes above). A cell may fail differently per
  target and then carries one line per target, with two different owners — `test/tuple_labels.bp`
  is the worked example: `04 step 2` on commonJS, `02 step 4` on erlang, the same test name.
- A `reject/` `.expect` names a short key phrase of the diagnostic decision 8 sketches (`use _ {`,
  `not exhaustive`, `use loop (`…) and the location of the offending token. The front that implements
  the diagnostic fixes its final wording and updates the `.expect` in the same change.
- The runner fails on: an unlisted failure; a listed test that now passes ("delete its line", or
  "drop it from the line" when the line names several); a listed path or test that does not exist; a
  path-only entry on a cell that compiles; and a **malformed line**, which is reported with what is
  wrong with it and never read as a different shape — a missing or empty field, a target that is not
  one of the five, an empty name either side of ` ;; `, the same name twice on one line, or `::` on a
  path that is not a `test/` cell (only a `test/` cell has tests).

## Status and the gate

Counted on disk at `b09bf9c6` — local `feat` after the fronts 12 × 13 merge:

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

Classification at botopink-lang `b09bf9c6` (node v25.8.0, OTP 29), `zig build test-language`, every
target of `--target all` together:

```
language tests: 268 passed, 66 expected failures, 0 failed
```

`expected-failures.txt` holds **77** lines: these 66 plus 11 that only `--target beam` exercises (the
12 `*` reject lines are counted by both runs). **11** of the 77 name tests rather than a path. Every
owner cell names a 1.0.5-beta section, re-checked against `specs/1.0.5-beta/` on 2026-09-18, and the
six re-attributed here on 2026-09-19. By the row that comes first on the line —
**01-checker 36 · 02-erlang 16 · 03-beam 9 · 05-wasm 8 · 04-js 5 · 13-module-identity 3**. **16**
lines name a second row that has to land before the line goes (the §7 formatter's record and variant
halves, and the identity cells behind a checker row).
`tests/language/run.sh --target beam` adds 18 `run/`+`modules/` results of its own — 7 passing, 11
listed — beside the same 24 `reject/` results; those 11 lines are skipped by `--target all`.
See § the targets.

**Two movements are inside those tallies and neither is a line arriving or leaving.** The fronts
12 × 13 merge took 80 lines to 77 and 265 passes to 268: front 13's half 1 made the three `modules/*`
erlang cells run and deleted their lines. Then front 01 proved six owner cells wrong — its step 4 does
unwrap a lambda arm body and does resolve a `.Variant` arm, so neither is what those cells fail on —
and the six were re-attributed: four `erlang | test/case_*.bp` lines from `01 step 4` to `02 step 3`
(erlang's pattern emission, `codegen/erlang.zig` `Emitter.patternNode`) and the two
`test/type_identity_case.bp` lines to `13 step 17` alone. That is 42 → 36, 12 → 16, 1 → 3, and — for
the lines naming a second row — 19 → 16, because three of the six shed a second row they no longer
need. **The second-row figure also had a third mover, the counting command itself.** Split on every
comma the file answers 23 before and 20 after, and both over-count by four: a comma *inside* a
parenthesised owner cell is not a second row, and `02 (no step; decision 55, reported 2026-09-18)` is
one row on four lines. The header's command now splits the owner field on `,(?![^(]*\))`, which
answers 19 before and 16 after. So of 23 → 16, only three are lines moving.

**Every number in this section and in `expected-failures.txt`'s header is recounted from the file,
never adjusted by a delta** — decision 59 of `specs/1.0.5-beta/decisions-taken.md`, taken
2026-09-18 after two fronts re-tallied the same block from different baselines in one merge window
and were individually right and jointly wrong. The header carries the counting command, and since a
test name may carry an escaped `|` that command splits on `(?<!\\)\|`, not on `|`. This section had
been stale by nine results and fourteen lines for that reason when `fe871ed` recounted it, and it was
stale again on arrival here: it read 265 / 69 / **80** lines and `01-checker 42`, measured at
`3cfb65cb`, two merges behind the tree it sat in. Recounted above with that command.

**Where an owner cell is not `<front> step <n>`.** Two of this milestone's rows are *handover
sections* of a front's README — "Handed over by `15-language-surface`", prose with a heading and no
step number; three lines name them, as `01 handover 15` (2) and `03 handover 15` (1). One row has
neither a step nor a handover section and the owner cell says so: `02 (no step; decision 55, reported
2026-09-18)`, on the four collection-loop `break` lines — front 02 owns `erlang.zig`, so the *front*
is certain even though no step names the defect (§ Where front 02 has no row for the collection loop).
Both shapes are reported to the maintainer rather than papered over with an invented step number.
`04 (no step; reported 2026-09-18)` was a third and is **gone**: front 04 fixed the `?.`-into-`??`
defect and deleted its line, so 04's five lines are `04 step 2` (1) and `04 step 3` (4). Recounted
from the file at `b09bf9c6`.

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

**Every per-cell measurement in this section and in the cells' own header comments was re-run after
merging `origin/feat` `3cfb65cb` and none of them moved**, the range table above included — so the
`b5a9b85d` dates in the cell comments are the measurement, not a stale one. In particular the `256`
heap address the range defect used to be recorded with does **not** reproduce on either commit: wasm
answers `0`, and it answers `0` at every endpoint.

**A `.out` may encode a decision no backend implements yet, and that is the point.** Five cells do —
`run/loop_yield_then_break_value.bp`, `run/loop_break_value_then_yield.bp`,
`run/loop_yield_then_bare_break.bp` (decision 55), `run/loop_condition_no_break.bp` (decision 52) and
`run/optional_null_pattern.bp` (decision 54). Each `.out` is the decision's answer, so when the
backends are moved against it **exactly one file per cell** is involved and no `.out` is renegotiated
in the same commit as an emitter. Each cell's header comment carries the per-backend measurement it
was written against, dated and with the commit.

**Never pin an erlang exit status or an `escript` warning as the point of a line.** `run.sh` runs
`botopink run --target erlang`, which today is `escript out/main.erl`: escript compiles the file it is
handed, prints its **compile warnings on stdout** — which the `.out` comparison sees — and answers
`127` when the program crashes. [Decision 56](../../specs/1.0.5-beta/decisions-taken.md) replaces that
with `erlc -o <out>` over every emitted `.erl` and then `erl -pa <out>`, in front 13's `cli/run.zig`:
the crash status becomes **`1`** and an `erlc` warning no longer reaches the program's stdout. So a
reason line may *quote* either as evidence, and four of this front's do, but the defect it names must
be the wrong answer. A front that fixes an erlang lowering and still sees a byte mismatch should check
which of the two moved.

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
