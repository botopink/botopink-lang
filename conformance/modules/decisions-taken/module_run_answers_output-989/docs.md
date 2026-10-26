# Decision 989 — The conformance suite checks itself in-process: each module is a botopink package whose `main` loads its cases with `compiler.load`, runs them, compares each answer with its snapshot and writes `.new` — no spawning program, no CLI `cell check`; the language gains what that needs; replaces 790, amends 475 (3), 786, 789 (4), 806 (1), 833 (3).

What a loaded package's answer carries for a suite that reads it (989 (4)): the build's prints on its `Module`, the calls a build raise crossed on its `Diagnostic`, and a refused manifest as a `Diagnostic` of `botopink.json`.

[cells/module_build_output_and_from/src/main.bp](cells/module_build_output_and_from/src/main.bp)
