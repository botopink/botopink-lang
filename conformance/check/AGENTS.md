# conformance/check — `cell check` as a botopink program (decision 790)

> Path: `conformance/check/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

A botopink package run on commonJS alone (`"targets": ["commonJS"]`) that will replace the CLI's
`botopink cell check` (decision 790): it finds every cell and module package, builds each with
`botopink build --json`, runs every target of its manifest, builds the `.snap` records from what the
program printed, compares them with the accepted snapshots and writes `.new` candidates, never accepting
(decision 67). It lives outside `modules/` and is no cell: it holds no `snapshot/`, and nothing checks it
with `botopink cell check` — botopink-lang's suite is `conformance/modules/` (`run.sh`). Its own tests run
with `botopink test --json` here.

Written so far: the records module alone. `main` does nothing yet — `discover`, `observe`, `compare` and
`report` are the next piece of B-161.

## Layout

```text
conformance/check/
├── AGENTS.md          ← you are here
├── botopink.json      ← the package: `name` `check`, commonJS only
├── src/
│   ├── main.bp        ← `pub fn main` — empty until the next piece
│   └── records.bp     ← the `.snap` records (decisions 457, 475, 485, 789, 868): `parse`, `render`,
│                         `matches`, `candidate`, `diff` — the port of
│                         `modules/compiler-cli/src/cli/cell_snap.zig`, plus 789's `build` record
└── test/
    └── records_test.bp ← `cell_snap.zig`'s unit tests ported one for one (same inputs, same expected
                          texts), then the `build` record's own
```

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

## Test

```sh
cd conformance/check && ../../zig-out/bin/botopink test --json
```
