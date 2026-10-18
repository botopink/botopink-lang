# float_division_by_zero_panic

The reference text this cell shows (from `conformance/docs.md`, § Operators):

> At run time a float division by zero prints the float's word on commonJS and
> wasm; erlang and beam abort with the integer division's `panic`, `panic: division by zero: / on f64
> at <file>:<line>:<col>` (decision 675).
