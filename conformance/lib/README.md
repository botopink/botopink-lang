# conformance/lib — the shared library of the self-checking modules (decision 989)

A botopink package (`conformance-lib`), a path dependency of every conformance module. A module's
`src/main.bp` loads its cases, runs them, turns each answer into records, compares them with its
`snapshot/main.snap` and writes `snapshot/main.snap.new`; this package is everything of that which is not the
module's own cases.

## The snapshot

`snapshot/main.snap`: line 1 `botopink-cell 2`, then one section per case, `== <case>` followed by its records
(`out` / `no-final-newline` / `abort` / `stderr` / `refused` / `at` / `label` / `from` / `build`, the grammar of
decisions 475, 485, 532, 789, 904), and a departure as `== <case> on <t>` (`<t>` one of commonJS, erlang, beam, wasm). A case with no departure for the
target it runs on answers its plain section there.

## API

| Module | Function | Does |
|---|---|---|
| `records` | `parseBody(text)` / `renderBody(snap)` | one section's records to a `Snap` and back; a body parses only when it is the records' one spelling |
| `sections` | `parseFile(text)` | the file into `Section(name, target, body)`s, or `Malformed(line, reason)` |
| `sections` | `renderFile(file)` | the sections back to text; `renderFile(parseFile(t)) == t` byte for byte |
| `sections` | `find(file, case, target)` | the section the case answers on `target`: its departure there, else its plain one |
| `sections` | `same(file, case, target, observed, stderr)` | whether the observed records equal the accepted ones (`stderr` claims contained) |
| `sections` | `renderCandidate(file, case, target, observed, stderr)` | the candidate section of one case (header line and records) |
| `observe` | `refusalOf(…)` / `refusedAnswer(…)` / `ranAnswer(…)` | a diagnostic, a refused load, a run, as an `Observed` |
| `observe` | `reds(file, observed, target)` | the cases that differ, in module order |
| `observe` | `assemble(file, observed, target)` | the module's whole candidate file: unchanged sections byte for byte, a changed case replaced in the section it answered on `target`, a new case appended, a vanished one dropped |
| `candidate` | `deliver(path, text)` | `io.fs` writes `path`, on every target (decision 992) |
| `candidate` | `finish(accepted, observed, target)` | the module's verdict: `Ok`, or the candidate delivered and an `Error` naming the red cases with a line diff. Never writes `snapshot/main.snap` (decision 67) |
| `adapter` | `target()`, `frames(d)`, `buildOutput(m)`, `ranOf(r)` | the features of 989 built in parallel, below |

## What waits on what

`adapter.bp` is the one place a landing changes.

| Function | State |
|---|---|
| `frames(d)` | built: ``d.`from` `` (989 (4), piece 4, decision 991) |
| `buildOutput(m)` | built: `Module.buildOutput()` (piece 4) |
| `target()` | built: `io.os.target()` (989 (7), piece 3) |
| `ranOf(r)` | built: `Module.run()` answers `Result<string, RunFailure>` (989 (1), piece 2); `Ok(text)` the printed text, `Error(f)` `f.output` and `f.message`; `m.run()` is written in the `compiler.init` body itself (`run-outside-init`), so the adapter takes its answer |

## wasm

`candidate.bp` writes through `io.fs` on wasm as on the other targets (decision 992: std's `io.fs` has a wasm binding,
machine 2's 990 piece); until it lands a module that reaches `finish` is refused on wasm at build
(`std-unsupported-on-target`). The rest of the library (`records`, `sections`, `observe`) builds and passes on wasm.

## Tests

`test/sections_test.bp` and `test/candidate_test.bp`, run by `botopink test --target <t>` from this directory:
the round trip, a departure chosen on its target, a changed case yielding a candidate with every other section
unchanged, malformed files, the `.new` written (commonJS, erlang, beam).
