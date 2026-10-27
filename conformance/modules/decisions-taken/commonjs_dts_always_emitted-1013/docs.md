# Decision 1013 — tsc-check folds into the commonJS conformance row: the row's output is one tree at the workspace root where each dependency exists once, and one `tsc` checks it whole; commonJS always emits a `.d.ts` beside each `.js`; one output file per package is not done on erlang, beam or wasm; answers tsc-a Q1 (a), Q2 (a), Q3 (a); amends 1011 (3), 1006 (5), 1008 (1)–(2), 1004 (2), 326.

A package of two modules of typed `pub` functions is built with no flag and no manifest field asking for typings:
on commonJS each module's `.js` has its `.d.ts` beside it (`<pkg>@main.d.ts`,
`<pkg>@names.d.ts`, the latter declaring `greet(name: string): string`); `--typescript` is no flag and
`"typings"` no manifest field. On erlang, BEAM and wasm no `.d.ts` is written. The program answers the same on
every target (`typed_modules`). The files beside the `.js` are a build's file tree, which no run of the program
observes; the CLI's test `modules/compiler-cli/tests/cli_contract.sh` proves it (every `.js` of a plain commonJS
build has its `.d.ts`, `--typescript` refused).

[cases/typed_modules/src/main.bp](cases/typed_modules/src/main.bp)
