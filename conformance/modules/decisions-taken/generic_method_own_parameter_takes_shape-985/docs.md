# Decision 985 — A method with type parameters of its own takes B-114's trailing print shapes for them at the call, as a generic function does (899), and writes them into the value it answers; amends 900 (1).

A method with type parameters of its own writes its float results as floats on every target. `d.mapValues({ v -> 2.0 })`
turns the `i32` values of a `Dict<string, i32>` into `f64` and prints `Dict("a": 2.0, "b": 2.0)`; a `fold<A>` answering
an `f64` prints `4.0`. On commonJS the call hands the method the print shape of each of its own type arguments after the
arguments, as it does a generic function (899); the dict the method answers carries the shape of `W` (`__bp_s.$W`), so
`print` never guesses a shape from a value. erlang, beam and wasm are unchanged.

[cases/generic_method_own_parameter_takes_shape/src/main.bp](cases/generic_method_own_parameter_takes_shape/src/main.bp)
