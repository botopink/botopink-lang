# pattern_range_exclusive

The reference text this cell shows (from `conformance/docs.md`, § Case (pattern matching)):

> A range in a pattern is `...`, inclusive at both ends — Zig's split: `...` in a
> pattern, `..` (exclusive) in a `for` and a slice. `1..9` in an arm is
> `error[pattern-range-exclusive]`, naming `...`; an open end is a guard.
