# Examples — `botopink` CLI commands

> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md) · Docs: [`./docs.md`](docs.md)

Practical recipes for every `botopink` subcommand. All examples assume a
project root with a `botopink.json` and a `src/` directory.

## `botopink new`

Scaffold a new project tree:

```bash
botopink new hello
cd hello
ls
# botopink.json  src/  .gitignore
cat src/main.bp
# fn main() {
#     println("hello, world");
# }
```

Refuses to overwrite an existing directory — delete or pick a different
name.

## `botopink build`

Type-check **and** emit target source under `out/`:

```bash
botopink build
# ✓ compiled 3 modules
ls out/
# main.js   main.d.ts
```

Honours the `target` field of `botopink.json`. Switch targets without a
flag — change the JSON instead, so CI and editors stay in agreement:

```json
{
  "target": "erlang",
  "entry":  "src/main.bp"
}
```

```bash
botopink build
ls out/
# main.erl   main.beam
```

## `botopink check`

Same pipeline as `build` but stops after type inference (no emission). Use
for fast feedback in editors or CI:

```bash
botopink check
# ✓ no type errors
```

Exit code `0` on success, non-zero on any type error. The diagnostic format
is the same as `build`.

## `botopink run`

Build, then execute the emitted entry point. Picks the right runtime based
on `target`:

```bash
botopink run
# (compiles, then runs `node out/main.js`)
# hello, world
```

For Erlang it invokes `escript out/main.erl` (or `erl -noshell ...` when the
project compiles to `.beam`).

## `botopink test`

Compile in test mode, then run every `test { … }` block in the project.
Test artifacts go to `.botopinkbuild/test-out/` (the normal `out/` build is
untouched); `fn main/0` is not auto-invoked.

```bash
botopink test
# running 3 tests
#   ok   addition works
#   FAIL map doubles  (map should double each element)  at main.bp:12
#   ok   test_2
# 2 passed, 1 failed
```

Exit code `0` when every test passes, `1` otherwise. A failing `assert`
records the failure and the runner continues with the next test.

```bash
botopink test --filter "addition"   # only tests whose name contains "addition"
```

The `commonJS` (node) and `erlang` (escript) targets run tests; the WASM
runner is a pending phase of the `test-blocks` spec.

## `botopink format`

Format every `.bp` file in `src/` in place:

```bash
botopink format
# ✓ formatted 4 files
```

Check mode — fail CI if anything is not formatted (does not write files):

```bash
botopink format --check
# error: src/foo.bp is not formatted
# hint: run `botopink format` to fix
# (exit 1)
```

`format` is round-trip stable: running it twice produces identical output.

## `botopink clean`

Remove generated artefacts:

```bash
botopink clean
# ✓ removed out/ and .botopinkbuild/
```

Idempotent — safe to run when nothing exists.

## `botopink version` / `botopink --help`

```bash
botopink version
# botopink 0.0.13-beta

botopink --help
# usage: botopink <command> [options]
# commands:
#   new <name>          create a new project
#   build [--target X]  compile to target
#   check               type-check only
#   run                 build then execute
#   test [--filter X]   compile in test mode + run test blocks
#   format [--check]    pretty-print .bp files
#   clean               remove out/ and .botopinkbuild/
```

## Common workflows

| Goal | Commands |
|---|---|
| Bootstrap a new project | `botopink new app && cd app && botopink run` |
| CI: lint + check + tests | `botopink format --check && botopink check && botopink test` |
| Swap target | edit `botopink.json` → `"target": "erlang"` → `botopink build` |
| Reset everything | `botopink clean && botopink build` |

## See also

- CLI design notes → [`./docs.md`](docs.md).
- `.bp` language reference → [`../../../../docs.md`](../../../../docs.md).
