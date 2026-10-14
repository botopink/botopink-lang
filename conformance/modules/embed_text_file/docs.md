# embed_text_file

The reference text this cell shows (from `conformance/docs.md`, § `@embed` and `Asset`):

> `@embed(path)` is the file `path` names, read while the program is built
> (decision 519), as an `Asset` — a builtin record like `SourceLocation`, with no
> import: `path` (the path as written), `bytes` (the file's bytes), `size` (the
> number of bytes) and `hash` (the SHA-256 of the bytes, 64 lowercase hex digits).
>
> `a.text()` is the bytes as UTF-8 text, computed at build.
>
> `@embed` is a `Build` builtin (decision 376): a call whose path is known at
> build — a literal, a constant `val`, a `comptime`, an `Any` call of those — is
> computed where it is written, in a body or in a module-level `val`, with no
> `comptime` (decision 380 (1) extended to `Build` calls; a `comptime` written
> stays legal).
