# Decision 703 — `botopink.json`'s `files` is gone: what a consumer may import is the tree (every module under `src/` outside `src/internal/`, 592 (8)); once B-69 / B-75 land, a manifest still writing `files` is refused, located, naming `src/internal/`; `workspaces` stays (512).

The example imports `greet.hello` from the dependency `greeter`. `greet.bp` is importable because it sits in `greeter`'s `src/` tree outside `src/internal/`, and no `files` list in `greeter`'s manifest is consulted. A manifest that still writes `files` is refused at the key, naming `src/internal/` as the way to keep a module private. A draft carries no manifest and no dependency, so the example waits for the promoted cell's `greeter` package.

Cells in this repository that also bear on it: `modules/dependency/cases/dependency_files_order`.

[draft/main.bp](draft/main.bp)
