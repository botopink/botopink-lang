# tests/language — botopink language tests (front 15)

Tests written in botopink that pin the language as decision 8 defines it
(`specs/1.0.4-beta/08-review-backlog/decision-8-language.md` in the meta
workspace): `case` and patterns (§5), tuples and labels (§6), `loop` (§10), and
the parts of `is` (§4), unions (§3), `unknown` (§2) and printing (§7) those
scenarios use. The spec is `specs/1.0.4-beta/15-language-tests/README.md`.

**Tests describe decision 8, not today's compiler.** A scenario the compiler gets
wrong stays as written and is listed in `expected-failures.txt` with the row of
the front that makes it pass. Never rewrite a test to match current behaviour.

## Layout

| Path | Kind | Passes when |
|---|---|---|
| `test/<area>_<group>.bp` | `test "…" { … assert … }` blocks, run by `botopink test --target <t> --json` | every test reports `ok` |
| `run/<name>.bp` + `<name>.out` | a whole program (`pub fn main`), run by `botopink run --target <t>` | exit 0 and stdout equals `.out` byte for byte |
| `reject/<name>.bp` + `<name>.expect` | a program that must not compile, run by `botopink check` | exit ≠ 0, stderr contains `.expect` line 1, and ` --> src/main.bp:<line 2>` when line 2 is present |
| `expected-failures.txt` | the list of known failures | — |
| `run.sh` | the runner | — |

Every file is compiled in its own scratch project, so a parse error fails only
that file. `test/` and `run/` run on commonJS and erlang; `reject/` runs once
(target `*`). Test names start with the decision-8 section they pin
(`test "§5.4 …"`), so a failure points at the rule.

Areas: `case_*` / `run/case_*` / `reject/case_*` (§5), `tuple_*` (§6),
`loop_*` (§10). One scenario group per file.

## Running

```bash
zig build test-language                                   # the installed botopink, both targets
zig build test-language -- --target erlang
tests/language/run.sh --compiler <botopink> --only test/case_arms.bp
```

`--lib-root` defaults to `<compiler>/../../libs` (where `from "std"` resolves).

## expected-failures.txt

```
<target: commonJS | erlang | *> | <path>[::<test name>] | <owner row> | <reason>
```

- The owner row must exist in the specs: `12 step 3|4`, `06 N18`…`06 N27`, `01 step 6`, or an
  unowned item of `specs/1.0.4-beta/fronts.md`.
- A path-only entry is for a file that does not compile; a file that compiles lists its failing
  tests by name.
- A `reject/` `.expect` names a short key phrase of the diagnostic decision 8 sketches (`use _ {`,
  `not exhaustive`, `use loop (`…) and the location of the offending token. The front that implements
  the diagnostic fixes its final wording and updates the `.expect` in the same change.
- The runner fails on: an unlisted failure; a listed test that now passes ("delete its line"); a
  listed path or test that does not exist; a path-only entry on a file that compiles; a malformed line.

## Status and the gate

Coverage: 31 files besides the three smoke files — `case` (§5) 6 test + 1 run + 9 reject, tuples (§6)
5 test + 1 run + 2 reject, `loop` (§10) 5 test + 2 reject.

Classification at `botopink-lang` `fix/checker` step 1 (06 G0 plus 01 step 6's D8-6 pulled forward, on
top of `aa24146`): both targets together, 77 results pass and 27 are expected failures — 06 N19–N22
(the `case`-arm syntax, unions, `unknown`, `is`) and 01 step 6 (tuple equality on commonJS, the print
text). `loop (condition)` / `loop { … }` are checked (06 N26) and lowered on all four backends.
Front 12 step 4 closed its two rows (`.N` on erlang, `t.0.1`).

`zig build test-language` is a stage of `scripts/gate.sh` (after `test-libs`) and a step of the CI
`test` job (ubuntu + macos). When a front makes a listed test pass, the gate fails with "now passes:
delete its line" — the landing commit of that front deletes the line.

The range pattern `1..9` in a `case` arm: decision 8 does not yet say whether the end is inclusive
(`loop (0..4)` is exclusive). The tests avoid the edge until the maintainer decides.

beam and wasm are not runnable by `botopink test`/`run`; their decision-8
coverage stays in the codegen snapshots (01 step 6).
