# Decision 733 — (a): a library has no `"entry"` — the key is an executable's alone, refused in a library's manifest.

The example is a library: [draft/botopink.json](draft/botopink.json) declares no executable, and `main.bp` holds no `pub fn main`. The manifest also writes `"entry": "src/start.bp"`. `"entry"` is an executable's key alone: it says only where `main` starts, `main.bp` when absent. A library has no entry, and every file under its `src/` is a module of it, so the key names nothing there. The manifest is refused at the key, `manifest-entry-in-library`, located, naming the package. The fix is to delete the line.

Cells in this repository that bear on it: none yet.

[draft/main.bp](draft/main.bp)
