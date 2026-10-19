# Decision 607 — `compiler.embed(path)` makes the link and nothing else; `Asset`, a std module importing `compiler` and `io.fs`, takes the link, opens the `File` and reads.

`compiler.embed("src/greeting.txt")` checks the path against the package — relative to its `botopink.json`, inside the
package, an existing file — records the file as an input of the build, and answers a `Link`; it reads no byte.
`Asset(…)` takes that link, and `greeting.link.path` prints the path as written. Reading is `File`'s, opened through
`greeting.open()`, and when it happens is the `comptime` written at the read: `atBuild` opens and reads the file inside a
`comptime` block, so the text is a constant of the artifact; `main` opens it again at run time from the resolved path,
the file deployed with the program, and closes it with `defer`. Every read answers a `Result<…, FsError>`, handled here
with `catch panic(…)`. The program prints `src/greeting.txt`, `hello from the build` and `true`.

Cells that also bear on it: `modules/decisions-taken/embed_returns_asset-519/cells/embed_text_file`, `modules/decisions-taken/unicode_case_tables_embedded-559/cells/embed_binary_file`, `modules/decisions-taken/embed_returns_asset-519/refused/src/cases/embed_path_absolute`,
`modules/decisions-taken/embed_returns_asset-519/cells/embed_path_outside_package`, `modules/decisions-taken/embed_returns_asset-519/refused/src/cases/embed_file_missing`, `modules/decisions-taken/embed_returns_asset-519/refused/src/cases/embed_path_not_known`,
`modules/decisions-taken/asset_size_hash_open-538/cells/fs_asset_opens_as_file`.

[draft/main.bp](draft/main.bp)
