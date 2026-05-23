# vscode-extension · AGENTS.md

> Path: `modules/vscode-extension/`
> Parent: [`../AGENTS.md`](../AGENTS.md)
> Sibling docs: [`./docs.md`](docs.md)

VS Code extension for the `.bp` language. Adapted from
[`gleam-lang/vscode-gleam`](https://github.com/gleam-lang/vscode-gleam).
Thin TypeScript wrapper that:

1. Registers `.bp` as a language (`botopink`).
2. Ships a TextMate grammar + snippets for offline highlighting.
3. Launches the `botopink-lsp` binary (see `../language-server/`) and
   speaks LSP over stdio via `vscode-languageclient`.

## Tree

```text
vscode-extension/
├── AGENTS.md                       ← you are here
├── README.md                       ← user-facing install + dev notes
├── docs.md                         ← deep-dive: design, LSP wiring
├── package.json                    ← extension manifest (contributes/commands/config)
├── tsconfig.json
├── language-configuration.json     ← brackets / auto-close / on-enter rules
├── snippets.json                   ← snippets for fn/val/record/case/loop/…
├── syntaxes/
│   ├── botopink.tmLanguage.json    ← TextMate grammar for `.bp`
│   └── botopink.codeblock.json     ← markdown injection for ```bp blocks
├── images/                         ← extension icon + language icon
└── src/
    └── extension.ts                ← activate() / deactivate() / LSP client
```

## Conventions

- **No compiler-internal knowledge.** The extension does not parse `.bp`
  itself — all semantic features come from `botopink-lsp`. The TextMate
  grammar is a separate, purely lexical view used only for syntax
  colouring.
- **Keywords list must stay in sync** with
  [`../compiler-core/src/lexer/token.zig`](../compiler-core/src/lexer/token.zig).
  When you add or remove a keyword there, update
  `syntaxes/botopink.tmLanguage.json`.
- **`botopink-lsp` is launched with no args** — see
  [`../language-server/src/main.zig`](../language-server/src/main.zig).
  Do not add `lsp`/`serve`/etc. subcommands here.
- **Comment continuation** for `///` and `////` is wired through
  `continueTypingCommentsOnNewline()` in `src/extension.ts`. Keep that
  list aligned with the `commentDoc`/`commentModule` tokens.
- **No telemetry.** Do not add any analytics or auto-update channels.

## Local commands

```bash
npm install                # one-time
npm run compile            # tsc → out/extension.js
npm run watch              # rebuild on change
npm run vscode:package     # produces botopink-<version>.vsix
```

Press <kbd>F5</kbd> in VS Code on this folder to launch the Extension
Development Host. Make sure `botopink-lsp` is on `PATH` (or set
`botopink.path` in the dev-host's settings).

## See also

- LSP server it launches → [`../language-server/AGENTS.md`](../language-server/AGENTS.md).
- Token kinds the grammar mirrors → [`../compiler-core/src/lexer/token.zig`](../compiler-core/src/lexer/token.zig).
- Language reference for snippet bodies → [`../../docs.md`](../../docs.md).
