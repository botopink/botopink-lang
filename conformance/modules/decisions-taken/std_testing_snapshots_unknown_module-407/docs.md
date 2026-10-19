# Decision 407 — For now, `import {testing.snapshots} from "std"` keeps the checker's plain unknown-module error; the pointer to `snap` is documentation.

The example imports `testing.snapshots` from std, a module that has left std for the `snap` library. The import fails with the same error any missing std module gives, `unknown "std" module` at the import item, and the compiler names no library. The way to `snap` (`import {assertAs} from "snap";` with `"snap"` in `"dependencies"`) is written in std's and snap's documentation, not in the error.

Cells in this repository that also bear on it: none.

[draft/main.bp](draft/main.bp)
