# examples/

> Path: `examples/`
> Parent: [`../AGENTS.md`](../AGENTS.md)

Standalone `.bp` example programs showing **language-core** code — stdlib usage,
the generic library loader, expr-templates, the module tree. They are
documentation, **not** part of any snapshot harness, and do not affect
`zig build` / `zig build test`.

> Library examples live with each library (`repository/<lib>/examples/`).

## Tree

```text
examples/
├── AGENTS.md               ← you are here
├── hello.bp                ← smallest runnable program (prints a line)
├── stdlib-tour/            ← `import {dict, queue, sets, order} from "std"` + qualified calls,
│   ├── botopink.json          Array combinators, an Order-driven sort, a Queue BFS — with `test {}` blocks
│   └── src/main.bp
├── generic-loader-binding/ ← the three `from "<lib>"` forms against `erika` — with `test {}` blocks
│   ├── botopink.json          (object-form `dependencies` on erika)
│   └── src/main.bp            bare value (`of`), bare template fn (`erika "…"`), namespace (`erika.of(…)`)
├── modules/                ← `mod` / `pub mod` module tree + cross-module calls (see its README.md)
│   ├── botopink.json
│   ├── README.md
│   └── src/
│       ├── main.bp            entry: declares `geometry` + `shapes`
│       ├── geometry.bp        leaf module
│       └── shapes/
│           ├── mod.bp         folder index
│           ├── circle.bp      public submodule
│           └── helpers.bp     private submodule
└── yamlconf/               ← expr-template config (no botopink.json)
    ├── yamlconf.bp            `conf<T>` lifts a computed labeled tuple `#(server, debug)`
    └── main.bp                caller gets the structural type (`cfg.server.port`)
```

`yamlconf` lifts a tuple through `@expr(#(server, debug))`: the tuple crosses the comptime bridge
(`'__bp_json'/1` → `{"$tuple": [...]}`) and takes the labels its template body gives it
(`liftShapeOf`), so `cfg.server.port` resolves and `cfg.server.prot` is a located compile error.

`generic-loader-binding` resolves `from "erika"` through the multi-root lib
resolver to the sibling `repository/erika/` project, so it needs that submodule
checked out.

## Running an example

Projects with a `botopink.json` run from their own directory:

```bash
cd examples/modules && botopink run
cd examples/stdlib-tour && botopink test
```

For a single file (`hello.bp`, `yamlconf/`), drop it into a throwaway project:

```bash
botopink new demo            # scaffolds botopink.json + src/main.bp
cp examples/hello.bp demo/src/main.bp
cd demo && botopink run      # → hello, botopink
```

`botopink check` (type-check only) and `botopink build` (emit target code) work
the same way from inside a project.

## Conventions

- Keep each example minimal and self-contained — it must compile with the
  current compiler.
- Do not wire examples into snapshot tests; they are illustrative, not fixtures.
