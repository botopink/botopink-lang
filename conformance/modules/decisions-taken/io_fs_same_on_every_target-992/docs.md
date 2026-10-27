# Decision 992 — std's `io.fs` gains a wasm binding that behaves exactly as on commonJS, erlang and beam — the same functions, the same paths (relative to the working directory, absolute ones too), the same answers and the same errors — so a module reaching `io.fs` compiles and runs on all four targets; it is built now, as a piece of 990 before piece 6 on wasm; amends 989 (6), 990.

`io.fs` answers the same on commonJS, erlang, beam and wasm: the case below writes a file, reads it back, meets a missing file's error and reaches a file by a relative and by an absolute path, in a directory it makes and removes.

[cases/io_fs_same_on_every_target/src/main.bp](cases/io_fs_same_on_every_target/src/main.bp)
