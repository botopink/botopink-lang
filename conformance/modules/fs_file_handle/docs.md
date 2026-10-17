# fs_file_handle

The reference text this cell shows (from `conformance/docs.md`, § The file system, `io.fs`):

> **The handle.** `open(path)` (reading) and `create(path)` (writing, creating or truncating) answer a
> `File`, a `Closeable` the writer closes, and nothing checks that it is. Its calls are `path()`, `size()`,
> `read(n)` (up to `n` bytes, empty at the end), `bytes()` and `text()` (the rest from the position), `hash()`
> (the SHA-256 of the whole file, lowercase hex), `write(b)` and `close()`; each that can fail answers
> `@Result<…, FsError>`.
