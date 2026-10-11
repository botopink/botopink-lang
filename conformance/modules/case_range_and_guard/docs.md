# case_range_and_guard

The reference text this cell shows (from `conformance/docs.md`, § Case (pattern matching)):

> `.Rect(width: w)` without the `..` is `error: missing required field 'height' on
> type 'Rect'`, at the arm — the fields a pattern does not name are dropped, and
> `..` is how you say so.
>
> A range in a pattern is `...`, inclusive at both ends — Zig's split: `...` in a
> pattern, `..` (exclusive) in a `for` and a slice. `1..9` in an arm is
> `error[pattern-range-exclusive]`, naming `...`; an open end is a guard.
