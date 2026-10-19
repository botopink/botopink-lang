# Decision 177 — † `fs.glob`, one rule on both targets: `*` and `**` do not match a name that starts with `.` unless the pattern writes t

The program builds a small tree — `a.txt`, `.hidden.txt`, `sub/b.txt` and `.cache/c.txt` — and globs it four ways. `*.txt` answers `a.txt` alone: `*` does not match a name that starts with `.`. `.*.txt` writes the dot, so it answers `.hidden.txt`. `**/*.txt` answers `a.txt,sub/b.txt`: `**` does not descend into `.cache`, a directory whose name starts with a dot. `.cache/*.txt` names that directory with its dot and answers `.cache/c.txt`. The answers are the same on every target the program runs on, whatever the host's own glob would say, and the walk never descends through a link to a directory.

Cells in this repository that also bear on it: `modules/decisions-taken/fs_typed_error_shape-540/cells/fs_whole_file_shortcuts`.

[draft/main.bp](draft/main.bp)
