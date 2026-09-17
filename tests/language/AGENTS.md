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

Coverage and classification at `fe72c0e`: 29 test/run/reject files — `case` (§5) 6 test + 1 run +
9 reject, tuples (§6) 5 test + 1 run + 2 reject, `loop` (§10) 5 test + 2 reject; 53 results pass,
40 are expected failures (06 N19–N22 and N26: the new syntax; 12 step 4: `.N` on erlang and `t.0.1`;
01 step 6: tuple equality on commonJS, the print text).

Authored before front 12 lands, against the compiler of `fix/surface-cutover`
at `fe72c0e` (the 1.0.3 surface). `zig build test-language` is **not** in
`scripts/gate.sh` yet: the gate runs the old-surface compiler until 12 lands,
where every file here fails to parse. The gate stage is added when this front
lands, after 12 — at that point `expected-failures.txt` is re-classified against
the landed compiler.

beam and wasm are not runnable by `botopink test`/`run`; their decision-8
coverage stays in the codegen snapshots (01 step 6).
