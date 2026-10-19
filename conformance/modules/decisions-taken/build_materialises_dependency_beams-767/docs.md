# Decision 767 — `botopink build` materialises the dependencies' cached `.beam` into the output (509 (4)'s materialisation, for `build` as for `run`), and rakun-ssr's `compileBeam` runs `erlc` only over the `.erl` with no `.beam` beside them — the app's own modules.

The program's own code is one small module; everything else it runs — `Set`, `path`, `hash` — is std, a dependency. It prints `2`, `page.bp` and the length of a content hash. `botopink build --target erlang` of it writes the program's own `.beam` beside every dependency's: the dependencies' modules are not compiled again, they are materialised from the code cache — hard-linked, else copied — byte for byte what `run` and `test` link, so the output directory is a complete program. A tool that post-processes such a build compiles only the `.erl` that has no `.beam` beside it, the program's own modules.

[draft/main.bp](draft/main.bp)
