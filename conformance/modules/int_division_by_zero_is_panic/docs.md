# int_division_by_zero_is_panic

The reference text this cell shows (from `conformance/docs.md`, § Results):

> An integer `/` or `%` by zero is a `panic` too, `integer division by zero: <op>
> on <type> at <file>:<line>:<col>`, on commonJS, erlang and beam (527 (3)); on
> wasm the division traps, and a trap is no exception, so `attempt` does not
> catch it:
