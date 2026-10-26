# Decision 989 — The conformance suite checks itself in-process: each module is a botopink package whose `main` loads its cases with `compiler.load`, runs them, compares each answer with its snapshot and writes `.new` — no spawning program, no CLI `cell check`; the language gains what that needs; replaces 790, amends 475 (3), 786, 789 (4), 806 (1), 833 (3).

`run()` answers what the loaded package printed: `Ok` the text its body and its `main` wrote to standard output, byte
for byte, nothing of it reaching the program's own output; `Async` of that answer, awaited, when the loaded `main` is
`async`; and on a failure `RunFailure.output`, the text written before the package crashed (`.Abort`) or before its
`main` returned `Error` (`.Failed`) (`module_run_answers_output`), on commonJS, erlang, beam and wasm.

[cells/module_run_answers_output/src/main.bp](cells/module_run_answers_output/src/main.bp)

What a loaded package's answer carries for a suite that reads it (989 (4)): the build's prints on its `Module`, the calls a build raise crossed on its `Diagnostic`, and a refused manifest as a `Diagnostic` of `botopink.json`.

[cells/module_build_output_and_from/src/main.bp](cells/module_build_output_and_from/src/main.bp)
