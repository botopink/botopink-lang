# float_text_everywhere

The reference text this cell shows (from `conformance/docs.md`, § Host bindings):

> A float written as text keeps its decimal part on every target: `"${5.0}"` and
> `5.0.toString()` are `5.0`, `"x" + 2.0` is `x2.0`, `1e21` is `1.0e21`, `-3.0`
> is `-3.0`, `0.25` is `0.25`.
