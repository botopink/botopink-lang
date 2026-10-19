# Decision 495 — Every std binding is audited: one whose host call can fail gains `result: true` and its module's error enum; one that cannot is listed as promising no failure.

The example calls two std functions that differ in whether their host call can fail. `fs.readText` reads a file through a host call that can fail, so its binding answers a `Result` (`result: true`), and the module maps the host's failure into its own error enum, `fs.FsError`. Reading a file that does not exist answers `Error(NotFound(path))`, which `show` matches like any other `Result` and prints as `not found no-such-file.txt`. `process.pid()` reads the process id, which cannot fail, so its binding answers a plain `i32`, and `libs/std/AGENTS.md` lists it as promising no failure. The program needs no `attempt` and no `try`: every failure std can have is in a signature, as a variant of the module's enum. A std binding is never wrapped to mark a raise as `host`, since the audit already put each failure in the signature.

The program prints `not found no-such-file.txt` and `true`.

Cells in this repository that bear on it: `modules/decisions-taken/fs_walk_dangling_link_not_found-711/cases/fs_error_variants`, `modules/decisions-taken/fs_error_message_text-563/cases/fs_error_message`.

[draft/main.bp](draft/main.bp)
