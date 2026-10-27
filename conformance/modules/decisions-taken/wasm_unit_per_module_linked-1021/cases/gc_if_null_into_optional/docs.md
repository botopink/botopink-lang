# gc_if_null_into_optional

An `if` with a `null` arm is an optional (decision 330); on wasm the GC lowering takes the value arm's representation, the `null` arm the null reference, a scalar boxed (decision 1021 (10)).
