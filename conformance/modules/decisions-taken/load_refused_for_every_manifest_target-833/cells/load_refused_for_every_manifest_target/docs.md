# load_refused_for_every_manifest_target

Decision 833. The loaded package `packages/walks` calls `fs.walk`, a std function with a node and an erlang binding and
none for wasm. The manifest declares no targets, which is every target, so `compiler.load` answers `Error` with the
refusal `botopink build` prints on wasm (its code `std-unsupported-on-target`), on every target the cell is built for.
