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
`comptime_*` / `decorator_*`, `external_*`, `generic_*`, `string_*` / `array_*`, and the singletons
(`closure_capture`, `recursion`, `optional`, `expr_sugar`, `fn_defaults`). One scenario group per
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
`tests/language/run.sh --target beam` is green: **9 results, 2 passing** (`run/smoke.bp`,
`modules/mod_tree`), 8 expected failures — 7 owned by `03-beam` (steps 2 and 4) and 1 by
`01-checker` step 4; three of the `03` rows name `13 step 18` as well, because a record and a
variant cannot print their names before a value carries one.

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

Counted on disk at `fcc4b5b` + front 12 step 4.1:

```bash
ls test/*.bp    | wc -l   # 44
ls run/*.bp     | wc -l   #  7   (each with its .out)
ls reject/*.bp  | wc -l   # 22   (each with its .expect)
ls -d modules/*/| wc -l   #  3
find . -name '*.bp' | wc -l   # 80 — 76 cells, plus the 4 extra .bp of the modules/ projects
```

**76 cells**, of which three are the `smoke` files (one per single-file kind) — so **73** besides
them, by area:

| Area | Cells | Total |
|---|---|---|
| `case` (§5) | 8 test + 1 run + 9 reject | 18 |
| tuples (§6) | 6 test + 1 run + 2 reject | 9 |
| `loop` (§10) | 6 test + 2 reject | 8 |
| effects (§9) | 5 test + 5 reject | 10 |
| comptime, templates, decorators | 3 test | 3 |
| host externals (§8) | 2 test + 1 reject | 3 |
| generics and behaviors (§1) | 1 test + 2 reject | 3 |
| printing (§7) | 3 run | 3 |
| core: closures, recursion, primitives, optionals, sugar, defaults | 8 test | 8 |
| run-time type identity (§4, §7 — `13-module-identity`) | 4 test + 1 run | 5 |
| modules | 3 `modules/` cells | 3 |

Classification at botopink-lang `19a3b01` (node v25.8.0, OTP 29), `zig build test-language`, every
target of `--target all` together:

```
language tests: 218 passed, 53 expected failures, 0 failed
```

`expected-failures.txt` holds **61** lines: these 53 plus 8 that only `--target beam` exercises (the
11 `*` reject lines are counted by both runs). Every owner cell names a 1.0.5-beta section, re-checked
against `specs/1.0.5-beta/` on 2026-09-18. By the row that comes first on the line —
**01-checker 35 · 02-erlang 10 · 03-beam 7 · 05-wasm 5 · 13-module-identity 4**, and **04-js none**,
because front 04 deleted all seven of its lines in `c253965`, `7b6b5d3` and `17c5f8b`. **19** lines
name a second row that has to land before the line goes (the §7 formatter's record and variant
halves, and the identity cells behind a checker row).
`tests/language/run.sh --target beam` adds 10 results of its own — 2 passing, 8 listed (7 against
`03-beam`, 1 against `01-checker`, 3 of them naming `13 step 18` too); those lines are skipped by
`--target all`. See § the targets.

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
| `adder(3)(4)` — calling the result of a call | "make it parse" (14) | **parses** (15's R2). It does not *check*: `error: unbound variable ''` at the second `(` — the call carries its callee in `calleeExpr` and inference never types it |
| `#(a: i32, b: string)[]` — an array of labeled tuples | "make it parse" (14) | **parses, checks and runs on all four targets** (15's R1), with `@Result<i32, string>[]` and `(i32 \| string)[]` |
| `??` | "deliberately absent (14) — it duplicates `catch` and `?.`" | **parses and runs on all four targets** (15's R8, decision 28). The premise was false as well as the verdict: `catch` is `@Result`-only — `val b = a catch 0;` on an `a: ?i32` reds with `` `try` requires a @Result<D, E> value, found 'optional' `` — so nothing else gives an optional a default |
| `(a == b).toString()`, and `(sql """ab""").length` — a method on a parenthesised expression | open / "needs a dependency to measure" | **one production, and it parses** (15's R3). `(1 == 2).toString()` prints `false` and `("ab").length` prints `2` on commonJS, erlang and wasm; no dependency is needed to measure it |

**And one form that parses where no cell can yet assert it:** `42.toString()` — a method on a number
literal, 15's R3 — checks, and prints `42` on erlang and wasm, but the commonJS emitter writes
`__bp_print(42.toString())`, which node refuses with `SyntaxError: Invalid or unexpected token`
(`42.` reads as a float). No step of `04-js` (`specs/1.0.5-beta/04-js/README.md`) names it;
it is reported to the maintainer rather than listed against an invented row.

**The range pattern in a `case` arm — both halves are decided and neither has landed, so no cell
asserts an endpoint.** Decision 20 settled the spelling (`..` is the only range, in patterns and in
iteration alike; `...` leaves the grammar) and decision 36 settled the meaning (`..` excludes its end
in a pattern exactly as in a loop). Measured at `aab5489`:

- `1..9` in an arm still reds `error[pattern-range-exclusive]: \`..\` is iteration, not a pattern's
  range`, recommending `...` — the diagnostic that inverts. `test/case_arms.bp` is listed against
  `01 step 4` and is right as written.
- `1...9`, the spelling that diagnostic recommends, parses and checks — and **works on no backend**.
  Re-measured here, three backends give three different wrong answers to the same program:
  `val r = case 9 { 1...9 { 1 } _ { 0 } }; @print(r);` prints `undefined` on commonJS, `0` on erlang
  and `256` — a heap address — on wasm. Front 15 measured the first two; the third is this front's.
  Write the same `case` where its type is known (`fn f(n: i32) -> i32 { return case n { 1...9 … } }`)
  and it does not compile at all: `type mismatch: expected i32, got void` at the `case`. A brace-arm
  of `case` is neither typed nor lowered — the defect already filed with `01-checker`.

So an endpoint cell written today would assert nothing on either spelling. Decision 36's sentence is
**not yet in decision 8 §5** and its ~10-line parser edit (`parser/patterns.zig`'s
`finishRangePattern` `:269-274`, plus dropping `dotDotDot` from the lexer) is `01-checker`'s step-4
grammar, deliberately left by front 15 because it re-records that front's `case` snapshots. The cell
is owed once 01 step 4 lands, not before.

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
