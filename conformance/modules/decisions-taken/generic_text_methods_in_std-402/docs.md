# Decision 402 — The three generic text methods are `String` methods named `normalizeNewlines()`, `trimTrailingNewlines()` and `firstDifferingLine(other)`, and `io/fs` gains `mkdirRecursive(path)`.

The three text methods are methods of `string`, and `io.fs` makes a directory and its parents. `normalizeNewlines` turns
each `\r\n` into `\n` and leaves the lone `\r` of `lone\rcr` alone. `trimTrailingNewlines` drops the `\n` characters at
the end and nothing else — the spaces of `"  text "` stay. `firstDifferingLine` answers the 1-based line where two texts
first differ: `0` for equal texts, `2` when the second line differs, and `3` when one text is the other plus a line,
the difference being the line after the shorter text's last. `mkdirRecursive("made/one/two")` makes all three
directories, and a second call on the same path is `Ok` too, the directories being there; with the file `made/file` in
the way, `made/file/below` is an `Error`. So the program prints `true`, `true`, `true`, `0`, `2`, `3`, `true`, `true`,
`true`, `false`, `true`.

Cells that also bear on it: `modules/decisions-taken/fs_typed_error_shape-540/cells/fs_whole_file_shortcuts`.

[draft/main.bp](draft/main.bp)
