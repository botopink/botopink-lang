# int_division_by_zero_is_panic

The reference text this cell shows (from `conformance/docs.md`, § Results):

> An integer `/` or `%` by zero is a `panic` too, `integer division by zero: <op>
> on <type> at <file>:<line>:<col>`, on every target (527 (3)) — on wasm the division
> is checked and raises, so `attempt` catches it:
