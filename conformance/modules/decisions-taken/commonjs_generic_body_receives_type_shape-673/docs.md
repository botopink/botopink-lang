# Decision 673 — (a), as B-114 and B-115 build it: on commonJS a generic body that writes a `T` as text receives the print shape of each type parameter at the call, one JS body per function.

A generic body that writes a `T` as text answers on commonJS what erlang, beam and wasm answer, though JavaScript keeps
no difference between `3.0` and `3`. `show(3.0)` writes `3.0` and `show(3)` writes `3`; `both(1.5, 2.0)` writes
`1.5 and 2.0`, each parameter with its own shape; a generic record prints its `f64` field as `2.0`, `Box(value: 2.0)`;
and the same holds when `show` is called through a function value. On commonJS the call site knows each `T` and hands
the body a hidden trailing argument with that type's print shape, one JavaScript body per function; the values, the
`.d.ts` and every other target are unchanged, and the cost lands only where a generic writes a `T` as text.

[cells/commonjs_generic_body_receives_type_shape/src/main.bp](cells/commonjs_generic_body_receives_type_shape/src/main.bp)
