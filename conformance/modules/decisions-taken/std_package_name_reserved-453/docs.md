# Decision 453 — The package name `std` is the bundled standard library's alone.

The example's manifest, [draft/botopink.json](draft/botopink.json), names the package `std`. That name belongs to the bundled standard library alone, so the manifest is refused at its `name`, located, with `` error: the package name `std` is the bundled standard library's — choose another name ``. `main.bp` imports `io.terminal.print` `from "std"`, and the refusal keeps that import meaning one thing: the bundled std, which is recognised as before (its embedded modules, the prelude, the root package that is `libs/std`), never a package of the program that took its name. `main.bp` never builds, so nothing prints.

Cells in this repository that bear on it: none yet.

[draft/main.bp](draft/main.bp)
