# Botopink

A statically-typed, multi-target language that compiles to JavaScript, Erlang, BEAM, and WebAssembly.

```botopink
fn greet(name: string) -> string {
    return "Hello, " ++ name ++ "!";
}

val result = greet("world");
@print(result);             // Hello, world!
```

## Why Botopink

- **One language, four targets.** Compile the same source to CommonJS (Node.js), Erlang (OTP), BEAM bytecode, or WASM.
- **Hindley-Milner type inference.** Full type safety with minimal annotations.
- **First-class comptime.** Macros, code generation, and compile-time evaluation without a separate meta-language.
- **Integrated toolchain.** CLI compiler, LSP language server, package manager (`bpmp`), and test runner — all in a single `zig build`.

## Quick start

```bash
# Clone and build
git clone git@github.com:botopink/botopink-lang.git
cd botopink-lang
zig build

# Run a program
echo 'val x = 42; @print(x);' | zig-out/bin/botopink run --stdin

# Or create a project
zig-out/bin/botopink new hello && cd hello
zig-out/bin/botopink run --target commonJS
```

## Backends

| Target     | Runtime         |
|------------|-----------------|
| `commonJS` | Node.js ≥ 20    |
| `erlang`   | escript (OTP)   |
| `beam`     | erlc + escript  |
| `wasm`     | wasmtime        |

## Project structure

```
botopink-lang/
├── modules/               Zig packages
│   ├── compiler-cli/      botopink CLI
│   ├── compiler-core/     lexer, parser, type inference, codegen
│   ├── language-server/   botopink-lsp
│   └── lib-test-runner/   cross-backend lib test runner
├── libs/                  bundled .bp libraries
│   └── std/               standard library
├── examples/              example .bp programs
├── build.zig              workspace build graph
└── AGENTS.md              contributor guide
```

## Commands

```bash
zig build              # compile everything
zig build test         # compiler-core + language-server tests
zig build test-libs    # cross-backend lib ecosystem tests
zig build run          # run the CLI
```

## VS Code

Install the [Botopink extension](https://marketplace.visualstudio.com/items?itemName=botopink.botopink-vscode) for syntax highlighting, diagnostics, completion, hover, go-to-definition, and formatting.

## License

MIT
