# range_has_one_spelling_dot_dot

Decisions 20, 53 and 105: `a...b` includes `b` and `a..b` stops before it — in a `case` pattern, in a `for` and in a
slice alike. `digit` matches `0` and `9` and not `10`; `for (0..3)` runs `0`, `1`, `2` and `for (0...3)` adds `3`;
`xs[0..2]` is `[10, 20]` and `xs[1...2]` is `[20, 30]` — the inclusive slice used to stop before its end, `[20]`, on
every target. A string slices the same way: `"abcd"[1..3]` is `bc`, `"abcd"[1...3]` is `bcd`.
