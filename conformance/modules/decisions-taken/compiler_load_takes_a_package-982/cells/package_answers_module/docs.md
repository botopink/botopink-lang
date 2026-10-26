# package_answers_module

Decision 982: `compiler.load("packages/fine")` loads a package directory from its `src/main.bp` with its `mod` tree; the `Module` carries the loaded manifest's name and the directory as written, and a refusal's `file` is relative to the loaded package.

[src/main.bp](src/main.bp)
