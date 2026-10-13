# int_overflow_add_i32

The reference text this cell shows (from `conformance/docs.md`, § Builtins):

> An abort writes to stderr alone — a checked integer operator's abort as `@panic`'s —, so what the
> program printed before it is its whole stdout, on every target.

And from § Numbers:

> a result outside the type's range aborts the program on every target — `2147483647 + 1` on
> `i32` […] The abort names the operator, the type and the place on stderr.
