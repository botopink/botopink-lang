# float_nan_infinity_words

The reference text this cell shows (from `conformance/docs.md`, § Operators):

> At run time each target keeps its own answer (commonJS and wasm `Infinity`, erlang and beam
> the `panic` `division by zero: / on f64`).

> At run time a float division by zero prints the float's word on commonJS and
> wasm, and erlang and beam abort with the integer division's `panic` (decision 675).

And from § Host bindings (decision 444): on wasm, `NaN`, `Infinity`, `-Infinity`, which only a
wasm program's arithmetic makes, are those words.
