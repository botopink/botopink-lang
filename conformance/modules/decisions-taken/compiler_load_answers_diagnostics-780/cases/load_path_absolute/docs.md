# load_path_absolute

The reference text this case shows (from `conformance/docs.md`, § `compiler.load`):

> The path follows `@embed`'s rules: relative to the caller's `botopink.json`, no
> absolute path, no `..` segment. An absolute path is `load-path-absolute`, a `..`
> segment `load-path-outside-package` and a path that names no package
> `load-not-a-package`, each a refusal of the program that loads, at the argument; a
> compiler handed no reader refuses every load, `load-no-reader`.
