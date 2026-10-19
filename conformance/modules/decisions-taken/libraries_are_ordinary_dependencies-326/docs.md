# Decision 326 — The shared libraries leave the compiler: one repository each, ordinary dependencies.

The example imports `cookie` from `http`, one of the shared libraries (`actions`, `http`, `log`, `routing`, `validation`, and `cardume` beside them). Each lives in a repository of its own and is an ordinary dependency, so the compiler embeds and ships std alone. The program's manifest declares no `"http"` dependency, so `import {cookie} from "http";` is refused at the source string: `http` is no package the program can see. The import line itself is the one a program with the dependency writes, since the libraries kept their names, their exports and their import sources when they moved. The fix is in the manifest, `"dependencies": {"http": {"git": "https://github.com/botopink/http", "ref": "…"}}`. The `std` import on the first line needs nothing, because std is the one package every program has.

Cells in this repository that bear on it: none yet.

[draft/main.bp](draft/main.bp)
