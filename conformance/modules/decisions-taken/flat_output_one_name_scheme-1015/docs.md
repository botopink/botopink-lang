# Decision 1015 — Every target's output is one flat folder, each module once, its file named `<pkg>@<path>` as erlang's module atoms already are (109): `std@math.js` and `std@math.d.ts`, `std@math.erl`, `std@math.S`; at a workspace root one such folder per target holds every member and every dependency once; answers 1013-a (b); amends 1013 (2), 326, the commonJS layout (mirrored subfolders).

A package of two modules with a dependency of two modules — each package holding a module named `util` — is
written to one flat folder per target, each module once under its `<pkg>@<path>` name: on commonJS
`<app>@main.js`, `<app>@util.js`, `flat_output_dep@root.js` and `flat_output_dep@util.js`, each `.d.ts` beside its
`.js`, each `require` naming its sibling (`require("./flat_output_dep@util")`); on erlang and BEAM the same names
with `.erl` / `.S`, as before. The program answers as it did with the mirrored subfolders: the two `util`s never
meet (`two_modules_and_dependency`). The folder's listing itself is a build's file tree, which no run of the program
observes; the CLI's test `modules/compiler-cli/tests/flat_output_names.sh` proves it.

[cases/two_modules_and_dependency/src/main.bp](cases/two_modules_and_dependency/src/main.bp)
