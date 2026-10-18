# comptime_primitives_at_build

The reference text this cell shows (from `conformance/docs.md`, § Compile-time evaluation):

> What a `comptime` computes is what the program computes when it runs, one
> answer for every target (decisions 331, 434 (5)): the primitives' methods —
> the integer conversions (`1000.toI64()`), strings, floats, arrays, integer
> division —, a suffixed number literal (`4500000000l` is the `i64` its suffix
> types, lifted back by its digits), a `Result`'s methods (`unwrapOr`, `isOk`,
> `map`, `flatMap`) and a `Result` function's own `return` / `throw`, and a
> function named as a value and passed as an argument (`r.flatMap(half)`,
> `xs.map(double)`).
