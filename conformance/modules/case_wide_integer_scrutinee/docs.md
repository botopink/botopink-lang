# case_wide_integer_scrutinee

The reference text this cell shows (from `conformance/docs.md`, § Numeric literals):

> A `case` over a 64-bit integer (`i64`, `u64`) or a float compares it as its own type: a number pattern, a
> range, an `|` of patterns and a guard see the value whole, on every target.

A `u64` range orders unsigned (a value above `i64`'s maximum falls in the arm that holds it), and in a
multi-subject `case a, b { … }` each subject is compared as its own type.
