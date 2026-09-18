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

| Target | `botopink test` | `botopink run` | In the suite |
|---|---|---|---|
| commonJS | yes | yes | every kind |
| erlang | yes | yes | every kind |
| wasm | refused — "supports only the commonJS and erlang targets" | yes, it executes | `run/` and `modules/` only |
| beam | refused | writes `out/main.S` and stops — a BEAM Assembly artifact, not a run | **no** |

`test/` cells therefore run on commonJS and erlang; `run/` and `modules/` cells run on those two and
on wasm; `reject/` runs once (target `*`, `botopink check` is target-independent). beam is excluded
because nothing executes: a `run/` cell would compare an empty stdout and pass vacuously. Its
decision-8 coverage stays in `snapshots/codegen/beam/` (01 step 6).

## Running

```bash
zig build test-language                                   # the installed botopink, every target
zig build test-language -- --target erlang
tests/language/run.sh --compiler <botopink> --only test/case_arms.bp
tests/language/run.sh --compiler <botopink> --only modules/two_modules
```

`--lib-root` defaults to `<compiler>/../../libs` (where `from "std"` resolves).

## expected-failures.txt

```
<target: commonJS | erlang | wasm | *> | <path>[::<test name>] | <owner row> | <reason>
```

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

Coverage: **68 cells** besides the three smoke files — front 15's 31, and 37 added by front 17.

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
| modules | 3 `modules/` cells | 3 |

Classification in the front-17 worktree on top of `26d4fdc` (node v25.8.0, OTP 29), every target
together: **196 results pass and 61 are expected failures** — 06 N1, N12, N18, N19–N22, N24, N25, N28,
`06` (the lower-case external annotation, a `fronts.md` unowned item), and 01 step 6 (the §7 formatter
on three backends, the erlang generator protocol, erlang cross-module calls, `String.toUpperCase`,
`ConditionLoopValueUnsupported`, tuple equality on commonJS).

`zig build test-language` is a stage of `scripts/gate.sh` (after `test-libs`) and a step of the CI
`test` job (ubuntu + macos). When a front makes a listed test pass, the gate fails with "now passes:
delete its line" — the landing commit of that front deletes the line.

## Notes for whoever writes the next cell

Shapes that do not parse, found while writing these cells. None is a bug filed against a front; each
is a form the cells route around, and each would change if the maintainer decides it should parse.

- `(sql """ab""").length` — a template call needs a `val` intermediate before a method.
- `adder(3)(4)` — calling the result of a call directly.
- `(a == b).toString()` inside an argument — bind the comparison to a `val` first.
- A bare `if` (no `else`) inside a decorator body must be the **last** statement of the block.
- `??` is not an operator; an optional is read with `if (x) { n -> … }`, `?.` and `== null`.
- A module-level `var` does not parse.
- `case` arms that bind a section (§5.3b) and the whole §5.1 `Pattern { body }` form are 06 N22.

The range pattern `1..9` in a `case` arm: decision 8 does not yet say whether the end is inclusive
(`loop (0..4)` is exclusive). The tests avoid the edge until the maintainer decides.

What cannot be tested from botopink at all, and why: `@Context` / `use` (lowers to React hooks on
commonJS, no erlang lowering — it needs a host framework); `pub default mod` / `pub default fn` and
`@ExprCustom` / `q.custom` (the package handle and the custom-AST carrier are a *dependency*'s
surface); `.d.bp` files shipped through `botopink.json` `files` (same); "no external target for the
active backend" (`reject/` runs `check`, which is target-independent); `@typeInfo` / `@makeRecord` /
`partial` / `omit` / `pick` (they produce types, and asserting on emitted text is the snapshots' job);
`@panic` / `@todo` (a cell that aborts reports no result through `--json`).
