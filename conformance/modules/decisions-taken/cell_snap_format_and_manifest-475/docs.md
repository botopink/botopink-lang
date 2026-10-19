# Decision 475 — A cell's snapshot format and its manifest.

Once promoted, this directory is a cell like any other: its own `botopink.json` (a project, no implicit package), `src/main.bp`, and one target-independent answer in `snapshot/output/main.snap`. The program writes the records that answer holds, in their fixed order: `out first line`, a bare `out` for the empty line, `out last line before the abort`, then `abort` — the program ends in `panic`, and the exit status is never pinned — and `stderr panic: the cell ends here` after it, a containment claim. A refusal would instead be a `refused` and an `at` record, never in the same file as output. A target that answered otherwise would get a `snapshot/targets/<target>/main.snap` replacing the whole `output/` answer for that target, and the shared answer is the one strictly more than half the targets give.

Cells in this repository that also bear on it: `modules/abort_text_panic`.

[draft/main.bp](draft/main.bp)
