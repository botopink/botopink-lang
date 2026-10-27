# fs_file_defer_close

The reference text this cell shows (from `conformance/docs.md`, § The file system, `io.fs`):

> **The handle.** `open(path)` (reading) and `create(path)` (writing, creating or truncating) answer a
> `File`, a `Closeable` the writer closes — `val f = try fs.open(p); defer f.close();` — and nothing checks
> that it is.
