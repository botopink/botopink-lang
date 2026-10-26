# Decision 982 — `compiler.load(path)` loads a package, never a file: `path` names a directory holding its own `botopink.json` and `src/main.bp`, compiled with its own manifest and checked for its own targets; a conformance case is such a package under `cases/<case>/`; amends 780 (1), 786 (1), 833 (1)–(2), 789 (4).

[cells/package_answers_module/src/main.bp](cells/package_answers_module/src/main.bp)
[cells/file_path_refused/src/main.bp](cells/file_path_refused/src/main.bp)
[cells/no_main_refused/src/main.bp](cells/no_main_refused/src/main.bp)
[cells/loaded_targets_checked/src/main.bp](cells/loaded_targets_checked/src/main.bp)
