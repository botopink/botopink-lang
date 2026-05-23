# vscode-extension — Botopink VS Code extension

> Path: `modules/vscode-extension/`
> Sibling (AGENTS): [`./AGENTS.md`](AGENTS.md)
> Parent: [`../docs.md`](../docs.md)

Design notes and rationale for the VS Code extension. For install / dev
instructions see [`README.md`](README.md); for file-by-file conventions
see [`AGENTS.md`](AGENTS.md).

## What lives in this package

The extension does only two things that the LSP cannot:

1. **Static / lexical view** — TextMate grammar + snippets, used by
   VS Code's tokenizer for colouring and IntelliSense suggestions
   before the language server reports its analysis. Lives entirely in
   `syntaxes/` and `snippets.json`.
2. **LSP launcher** — TypeScript glue (`src/extension.ts`) that
   resolves `botopink-lsp` and connects it via
   `vscode-languageclient/node`. Everything semantic (diagnostics,
   hover, completion, rename, …) is served by the LSP, not by this
   package.

## TextMate grammar shape

The grammar mirrors `compiler-core/src/lexer/token.zig`:

| Group | Patterns |
|---|---|
| Control keywords | `if`, `else`, `case`, `loop`, `for`, `break`, `continue`, `yield`, `return`, `try`, `catch`, `throw` |
| Declaration keywords | `fn`, `val`, `var`, `pub`, `private`, `struct`, `record`, `enum`, `interface`, `type`, `implement`, `implementations`, `extends`, `delegate`, `declare`, `macro`, `use`, `from`, `import`, `new`, `opaque`, `const`, `default`, `derive`, `test`, `assert`, `syntax`, `typeinfo`, `comptime`, `auto`, `echo`, `set`, `get`, `as` |
| Language constants | `true`, `false`, `null`, `todo`, `Self` |
| Operators | `->`, `\|>`, `..`, comparison, logical, bitwise, assignment, arithmetic, `?`, `\|` |
| Numbers | binary `0b…`, octal `0o…`, hex `0x…`, float (mantissa + `[eE][+-]?…` exponent), decimal — all support `_` separators |
| Strings | triple-quoted `"""…"""` (multiline) and `"…"` with `\u{…}`, `\n`, `\r`, `\t`, `\\`, `\"`, `\0` escapes |
| Builtins | `@identifier` |
| Comments | `////` module-level, `///` doc, `//` line |

Keep the grammar **purely lexical** — no parser semantics. If a future
feature needs scope-aware highlighting (e.g. semantic tokens for
inferred types), implement it server-side in `botopink-lsp` and consume
it via the LSP `semanticTokens` capability rather than complicating the
TextMate file.

## LSP wiring (`src/extension.ts`)

```text
activate(ctx)
  ├── setLanguageConfiguration   → onEnter rules for /// and ////
  ├── register `botopink.restartServer`
  └── createLanguageClient()
        ├── getBotopinkLspPath()
        │     ├── reads botopink.path setting
        │     ├── resolves relative paths against workspace folders
        │     └── falls back to "botopink-lsp" on PATH
        └── new LanguageClient(serverOptions, clientOptions)
              ├── serverOptions: { command, args: [], env: process.env }
              └── clientOptions:
                   ├── documentSelector: file/botopink
                   └── synchronize: watches **/*.bp + **/build.zig
```

Notes:

- The server is invoked **with no args**; see
  [`../language-server/src/main.zig`](../language-server/src/main.zig).
  Do not add subcommands here.
- `documentSelector` uses `scheme: "file"` only — untitled buffers will
  not currently bind to the LSP. Revisit if/when the LSP supports
  in-memory virtual documents.
- The file watcher includes `build.zig` so the server can re-resolve
  workspace boundaries when the build graph changes (the LSP does not
  yet act on this, but the wiring is in place).

## Why not bundle the binary?

Following the same model as `gleam-vscode`: keeping the binary out of
the extension means a single source of truth — whatever `botopink-lsp`
the user has on `PATH` (or pointed to via `botopink.path`) is what
runs. That keeps language-server fixes and grammar fixes on
independent release cadences and avoids shipping platform-specific
binaries inside the `.vsix`.

## Packaging

```bash
npm run vscode:package
```

Produces `botopink-<version>.vsix` at the repo root of this package.
Sideload via *Extensions → ⋯ → Install from VSIX…* in VS Code. Once
the language is stable enough for public release, publish with
`npx vsce publish` under the `botopink` publisher.

## Adding a new editor feature

| You want to add… | Where it goes |
|---|---|
| A new keyword to highlight | `syntaxes/botopink.tmLanguage.json` (`keywords` repo) + `AGENTS.md` |
| A new snippet | `snippets.json` |
| A new LSP feature consumed by the client | nothing here — implement in `../language-server/src/engine.zig` and the standard LSP capability negotiation will surface it |
| A new VS Code command (e.g. "compile current file") | `package.json` `contributes.commands` + a handler in `src/extension.ts` |
| A new user-tunable setting | `package.json` `contributes.configuration.properties` + read it in `src/extension.ts` |

## See also

- Language server it talks to → [`../language-server/docs.md`](../language-server/docs.md).
- Token kinds reflected in the grammar → [`../compiler-core/src/lexer/docs.md`](../compiler-core/src/lexer/docs.md).
- Snippet bodies follow the surface syntax in → [`../../docs.md`](../../docs.md).
