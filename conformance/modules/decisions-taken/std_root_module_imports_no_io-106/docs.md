# Decision 106 — std in three categories: a pure root, `io/` and `testing/`

The example imports from both sides of std's line. `collections.Dict`, `collections.Set`, `hash.sha256` and `encoding.base64Encode` come from root modules: the types are their own namespaces (`Dict.empty()`, `Set.fromList(words)`), and each call answers the same thing on every run. `tally` counts the words into a `Dict` with `bump`, the set of three words has two members, and the hash and the base64 text are fixed values. `io.random` is the one import that carries `io.`: drawing a coin reads entropy from outside the process, and the import line says so. The program prints `2`, `2`, the SHA-256 of `abc`, `aGk=` and `true`. Within std the line is a check the compiler makes: a root module that imported anything from `io/` would be refused. Outside std, `io.` on an import is how a reader sees what a module touches.

Cells in this repository that also bear on it: `modules/decisions-taken/content_hash_folds_codepoints-260/cases/std_hash_on_every_target`, `modules/decisions-taken/seeded_random_std_wasm-451/cases/std_random_on_every_target`, `modules/decisions-taken/package_imports_itself_by_path-309/cases/std_module_imports_std_module`.

[draft/main.bp](draft/main.bp)
