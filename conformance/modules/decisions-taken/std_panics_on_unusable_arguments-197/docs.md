# Decision 197 — † (1) erlang's `indexOf` / `lastIndexOf` count codepoints (320).

Four std answers that used to be each host's own, now one on every target. Text positions count code points, so the
`x` after `👍` is at `1`, and in `x👍x` the last `x` is at `2`, on erlang as elsewhere. A retry policy that cannot be
used — here `maxAttempts` of `0` — has no next delay: `async.nextDelay` answers `null` (and `async.retry` with it panics,
as `race([])` does). `hash.pbkdf2Sha256` with `0` iterations panics with std's own text, never the host's raise, and
`attempt` shows it: `panic: hash.pbkdf2Sha256: iterations and length must be at least 1`. Then `fs.glob` over a small
tree: a final `**` lists every entry at every depth, the root excluded — `a.txt`, `sub`, `sub/b.txt`; a trailing `/`
keeps the real directories only — `sub`; a `{a,b}` alternative holding a `/` matches nothing; and a `..` segment is no
pattern but a literal name, matched as written, so `../tree/a.txt` answers that one path.

Cells that also bear on it: `modules/decisions-taken/string_index_counts_codepoints-320/run/src/cases/string_index_of_codepoints`, `modules/array/run/src/cases/array_last_index_of`,
`modules/decisions-taken/task_result_rejects_with_error-432/cells/async_retry_policy`, `modules/decisions-taken/fs_walk_dangling_link_not_found-711/cells/std_fs_walk_root_spellings`.

[draft/main.bp](draft/main.bp)
