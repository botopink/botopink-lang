# Botopink

A statically-typed, multi-target language that compiles to JavaScript, Erlang, BEAM assembly, and WebAssembly text.

```botopink
fn greet(name: string) -> string {
    return "Hello, " + name + "!";
}

fn main() {
    @print(greet("world"));   // Hello, world!
}
```

## Why Botopink

- **One language, four targets.** Compile the same source to CommonJS (Node.js), Erlang source, BEAM assembly, or WAT.
- **Hindley-Milner type inference.** Full type safety with minimal annotations.
- **First-class comptime.** Templates, decorators, and compile-time evaluation without a separate meta-language (evaluated in a persistent `erl` process).
- **Integrated toolchain.** CLI compiler, LSP language server, package manager (`bpmp`), and lib test runner — all built by one `zig build`.

## Quick start

```bash
git clone git@github.com:botopink/botopink-lang.git
cd botopink-lang
zig build

zig-out/bin/botopink new hello && cd hello
../zig-out/bin/botopink run --target commonJS
```

## Backends

| Target     | Output | Runner                          |
|------------|--------|---------------------------------|
| `commonJS` | `.js`  | `node` ≥ 20                     |
| `erlang`   | `.erl` | `escript` (OTP)                 |
| `beam`     | `.S`   | artifact — `erlc +from_asm`     |
| `wasm`     | `.wat` | `wasmtime`                      |

## Project structure

```
botopink-lang/
├── modules/               Zig packages
│   ├── bpmp/              package manager
│   ├── compiler-cli/      botopink CLI
│   ├── compiler-core/     lexer, parser, type inference, comptime, codegen
│   ├── language-server/   botopink-lsp
│   ├── lib-test-runner/   cross-backend lib test runner
│   └── manifest/          the shared botopink.json model (std only)
├── libs/std/              standard library
├── docs/                  botopink-json.md — the manifest schema (packages, workspaces, dependencies)
├── examples/              example .bp programs
├── scripts/               installers, release packing, test wrappers
├── build.zig              workspace build graph
└── AGENTS.md              contributor guide
```

## Commands

```bash
zig build              # compile everything
zig build test         # compiler-core, language-server, CLI and lib-test-runner unit tests
zig build test-libs    # cross-backend lib tests
zig build test-docs    # every botopink fence of README.md and docs.md compiles
zig build run          # run the CLI
```

## VS Code

Install the [Botopink extension](https://marketplace.visualstudio.com/items?itemName=botopink.botopink-vscode) for syntax highlighting, diagnostics, completion, hover, go-to-definition, and formatting.

## License

MIT — see [`LICENSE`](LICENSE).
