# Decision 711 — `io.fs` details 540 left open: (1) a dangling link under `walk` answers `NotFound(<root>/<link>)` — what a read through it answers, `path` naming the link; (2) `hash()` hashes the whole file whatever the read position (as `Asset.hash`); (3) `lines()` ends at an `InvalidUtf8` line; (4) the write and directory functions (`writeBytes`, `writeText`, `appendText`, `mkdir`, `mkdirRecursive`, `rm`, `removeTree`, `copy`) answer `Result<void, FsError>` (no `i32` 0), `File.write` alone a count.

[cells/fs_error_variants/src/main.bp](cells/fs_error_variants/src/main.bp)
[cells/std_fs_walk_root_spellings/src/main.bp](cells/std_fs_walk_root_spellings/src/main.bp)
