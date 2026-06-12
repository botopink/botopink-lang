# examples/

> Path: `examples/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Standalone `.bp` example programs that show what **language-core** code looks
like — stdlib usage, generic loader patterns, expr-templates, the `mod`
keyword. They are documentation/showcase files — **not** part of any snapshot
harness and do not affect `zig build` / `zig build test`.

> Framework examples live with their framework, not here:
> `repository/erika/examples/`, `repository/jhonstart/examples/`,
> `repository/onze/examples/`, `repository/rakun/examples/`.

## Tree

```text
examples/
├── AGENTS.md          ← you are here
├── hello.bp           ← smallest runnable program (prints a line)
├── stdlib-tour/       ← stdlib showcase (WORKS): `import {dict, queue, sets, order} from "std"`
│   └── src/main.bp        ← qualified module calls (`dict.empty()`, `queue.empty()`…),
│                            Array combinators, an Order-driven sort, a Queue BFS — with `test {}`
├── generic-loader-binding/ ← generic loader showcase (WORKS): the three `from "<lib>"` forms
│   └── src/main.bp        ← bare value (`of`), bare template fn (`erika "…"`), namespace (`erika.of(…)`)
├── modules/           ← `mod` / `pub mod` showcase (WORKS): module tree + cross-mod calls
│   └── src/
│       ├── main.bp          ← top-level entry: imports + drives `shapes.circle` + `geometry`
│       ├── geometry.bp      ← sibling module
│       └── shapes/          ← nested `mod` directory
│           ├── mod.bp       ← `shapes` module entry
│           ├── circle.bp    ← child module
│           └── helpers.bp   ← private helpers
└── yamlconf/          ← expr-templates showcase: config template (model 2)
    ├── yamlconf.bp        ← `conf<T>` lifts a computed `record { … }` structure
    └── main.bp            ← caller gets the structural type (`cfg.server.port`)
```

> `stdlib-tour`, `generic-loader-binding`, `modules` and `yamlconf` **work**
> and carry `.bp` `test {}` blocks (run with `botopink test` from each dir).
> `generic-loader-binding` resolves `from "erika"` across the workspace —
> through the multi-root resolver — to the sibling `repository/erika/` project,
> so it doubles as the cross-root acceptance for the resolver.

## Running an example

The `botopink` CLI is project-based — it reads a `botopink.json` and compiles the
modules under `src/`. To run a single example file, drop it into a throwaway
project:

```bash
botopink new demo            # scaffolds botopink.json + src/main.bp
cp examples/hello.bp demo/src/main.bp
cd demo && botopink run      # → hello, botopink
```

`botopink check` (type-check only) and `botopink build` (emit target code) work
the same way from inside the project.

## Conventions

- Keep each example minimal and self-contained — it must compile with the
  current compiler.
- Do not wire examples into snapshot tests; they are illustrative, not fixtures.
