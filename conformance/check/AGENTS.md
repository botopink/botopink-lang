# conformance/check — `cell check` as a botopink program (decision 790)

> Path: `conformance/check/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

A botopink package run on commonJS alone (`"targets": ["commonJS"]`) that will replace the CLI's
`botopink cell check` (decision 790): it finds every cell and module package, builds each with
`botopink build --json`, runs every target of its manifest, builds the `.snap` records from what the
program printed, compares them with the accepted snapshots and writes `.new` candidates, never accepting
(decision 67). Its report is the CLI's byte for byte. It lives outside `modules/` and is no cell: it holds
no `snapshot/`, `discover` never takes it for one, and nothing checks it with `botopink cell check` —
botopink-lang's suite is `conformance/modules/` (`run.sh`), which runs its tests (`botopink test --json`
on commonJS).

Nothing calls it yet: the CLI's `cell check`, `scripts/gate.sh` and the CI stay as they are until
`proof.sh` shows the two agree over the whole suite (B-161's switch, 790 (3)).

## Layout

```text
conformance/check/
├── AGENTS.md          ← you are here
├── botopink.json      ← the package: `name` `check`, commonJS only
├── proof.sh           ← the proof of 790 (3): the CLI's `cell check` and the program over the same
│                         paths, their reports and their `.snap.new` candidates diffed; leaves with
│                         the CLI's `cell check` at the switch (798 (6))
├── src/
│   ├── main.bp        ← `main <cell|directory>… [--jobs <N>]`: the paths resolved against the working
│   │                     directory, their cells found (a cell reached twice checked once), `--jobs`
│   │                     workers over one queue (`async.runAll`), the report printed in the cells'
│   │                     order, exit 1 when a cell fails; the compiler is `$BOTOPINK_BIN`, else
│   │                     `botopink` on `PATH`
│   ├── discover.bp    ← `cell.zig`'s `discover`: a directory holding `src/` is a cell, one holding
│   │                     `cases/` and no `src/` a module of cases (765), one holding `botopink.json`
│   │                     and `src/main.bp` beside `cases/` one cell that loads its cases (982 (5),
│   │                     `isLoadingModule`; its cases no cells, its `cells/<case>/` cells, its scratch
│   │                     copy carrying `cases/`),
│   │                     never inside a cell, a hidden directory, `node_modules` or `deps`; never
│   │                     this package (`isTheProgram`)
│   ├── manifest.bp    ← a cell's `"targets"` (its own, else its workspace's; malformed narrowings
│   │                     refused with `cell.zig`'s reasons), whether it writes them, its workspace
│   │                     (`workspaceOf`: the nearest ancestor workspace whose entry lists the cell)
│   │                     and the cache root (the workspace's directory, else the cell's)
│   ├── scratch.bp     ← `cell.zig`'s `Scratch.open` / `close`: a fresh copy of the cell under
│   │                     `.botopinkbuild/tmp/check-<id>/` (a workspace member in a workspace of its own,
│   │                     `soleMember`, `absolutizePathDeps`, a link outside the cell kept a link) and
│   │                     the environment its builds get (`BOTOPINK_LIB_ROOTS`: the command's roots, the
│   │                     cell's `.botopinkbuild/deps/`, the walk-up from the cell)
│   ├── observe.bp     ← one target's answer through the CLI (§ Observing a package); the wasm
│   │                     hosts compared (`sameAnswer`); an excluded target audited
│   ├── compare.bp     ← `cell.zig`'s `readAccepted`, `removeCandidates` and `compare`, line for line:
│   │                     departures under `snapshot/targets/<t>/`, the agreement / majority / one per
│   │                     target candidates, each written as `<file>.snap.new` with its line diff
│   ├── report.bp      ← one cell's check (`checkCell`): the layout refusals, the comptime build, the
│   │                     targets, the build lines filed (`withBuild`), the verdict section; `summary`
│   ├── records.bp     ← the `.snap` records (decisions 457, 475, 485, 789, 868): `parse`, `render`,
│   │                     `matches`, `candidate`, `diff` — the port of
│   │                     `modules/compiler-cli/src/cli/cell_snap.zig`, plus 789's `build` record
│   ├── refusals.bp    ← the port of `cli/refusals.zig`: `refusalsOf`, `firstErrorLine`, `moduleOf`
│   ├── answer.bp      ← what a target answered: each module's `Snap`, the program's stderr
│   └── host.bp        ← the host cells std does not answer (a directory entry's own kind, byte-order
│                         sorting, links, synchronous stdout, a disarmable timer, …)
└── test/
    ├── records_test.bp  ← `cell_snap.zig`'s unit tests ported one for one, then the `build` record's own
    ├── refusals_test.bp ← `refusals.zig`'s unit tests ported one for one
    ├── scratch_test.bp  ← `cell.zig`'s tests of `absolutizePathDeps`, `soleMember`, `memberPath`
    └── discover_test.bp ← `cell.zig`'s tests of `discover` over a tree in the run's scratch directory
                           (982 (5)'s module included), and the program's own package is no cell
```

## Observing a package

Per cell, after its layout checks (`src/main.bp`, `botopink.json`, no `targets` file, a well-formed
`"targets"`) and with its old candidates deleted:

1. **The comptime phase, once** — `botopink build --json --emit-runtime <scratch>/rt --out out-build
   --cache-root <the cell's cache root>` in a copy of the cell: its `build` lines, the targets the
   package holds (`held`, decision 770 — a cell that writes no `"targets"` runs on those), its
   refusals, and the intermediate (`<root>.bpr`) when every module analysed.
2. **Each declared target, in a fresh copy** (a program that writes into its working directory finds
   it as it would alone), its build and run working there (838 (4)): from the intermediate,
   `botopink build --json --target <t> <root>.bpr` (the target's own refusals, decided at emit) and,
   when it builds, `botopink run --target <t> <root>.bpr` — stdout, stderr and status, killed past
   300 s. The comptime phase's own target reuses its events. A package the comptime phase refuses
   (no intermediate) is built directly on each target, as the CLI built every cell.
3. **wasm's second host** (decision 334): unless the manifest names its host, the copy's manifest gets
   `"wasm": { "host": "browser" }` last and is built and run again; two hosts that answer differently
   fail the cell.
4. **An excluded target** is audited: a direct build must refuse the cell on a host binding.

The `build` lines are the package's: the comptime phase prints them once, they are filed in `main`'s
answer (`report.withBuild`, the one place to change when question 789-b is answered), and a target
whose build printed other lines fails the cell with no candidate (789 (3)).

Two readings of the CLI's text stay: `run` refuses an entry module with no `fn main` before any
program starts, located at the intermediate — the program files it at `<src>/main.bp:1:1`, where
`cell check` locates it; and an audit reads the build's stderr for the host-binding phrases.

## The records

The order is `refused` / `at` / `label` / `from` → `build` → `out` / `no-final-newline` → `abort` →
`stderr` (decision 789 (1)); `build <text>` is one line a build body printed, `build` alone an empty one.
A file has one spelling: it parses only when rendering what it parsed gives back its text. Without a
`build` record `records.bp` reads and writes exactly what `cell_snap.zig` does, with the same malformed
line numbers and reasons, except that the unknown-record reason lists `build` too. `Refusal.frames` holds
the `from` records (`from` is a reserved word). `matches` compares the `build` lines exactly.

Text, not bytes: the program runs on commonJS, where a string is UTF-16. Every cut is at an ASCII `\n`
or ` `, which no UTF-8 multi-byte sequence contains, so each piece is the text `cell_snap.zig` cuts
from the file's bytes.

## Run, test, prove

```sh
cd conformance/check && ../../zig-out/bin/botopink test --json      # its tests (run.sh runs them too)
../../zig-out/bin/botopink build --target commonJS --out <dir>        # the program
BOTOPINK_BIN=<botopink> node <dir>/main.js conformance/modules --jobs 8   # from the repository root
conformance/check/proof.sh --jobs 8 conformance/modules               # the CLI and the program, diffed
```

A doc comment here never holds the two characters that close a JavaScript block comment: the commonJS
emitter copies it into one.
