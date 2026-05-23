# Botopink for VS Code

Botopink language support for Visual Studio Code:

- Syntax highlighting for `.bp` files (and ```` ```bp ```` fenced code blocks in Markdown).
- Snippets for the most common declarations (`fn`, `val`, `record`, `struct`, `enum`, `case`, `loop`, `comptime`, …).
- Full LSP integration via [`botopink-lsp`](../language-server/): diagnostics, formatting, hover, go-to-definition, completion, references, rename, signature help, inlay hints.

## Requirements

Install the Botopink toolchain first. The extension launches the
`botopink-lsp` binary, so it must be reachable on your `PATH`:

```bash
# from the repo root
zig build
# the resulting binary lives at modules/language-server/zig-out/bin/botopink-lsp
```

Either add that directory to your `PATH`, or set the extension setting
`botopink.path` to the absolute path of the binary.

## Settings

| Setting | Default | Description |
|---|---|---|
| `botopink.path` | `null` | Absolute path (or workspace-relative path) to `botopink-lsp`. When unset, the extension looks it up on `PATH`. |
| `botopink.trace.server` | `"off"` | LSP trace level (`off` / `messages` / `verbose`). |

## Commands

| Command | Title |
|---|---|
| `botopink.restartServer` | `Botopink: Restart Botopink Server` |

## Development

```bash
cd modules/vscode-extension
npm install
npm run compile      # one-off build → out/extension.js
npm run watch        # rebuild on changes
```

Then press <kbd>F5</kbd> in VS Code (with this folder opened) to launch
an *Extension Development Host* — open any `.bp` file there to drive
the extension against your local `botopink-lsp`.

To produce a `.vsix` for sideloading:

```bash
npm run vscode:package
```
