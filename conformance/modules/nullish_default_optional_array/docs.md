# nullish_default_optional_array

`o ?? d` over an optional array (decision 330: `?T`'s `unwrapOr` is `??`) answers the array, or `d` when `o` is absent —
printed, it is the array's text, `[2, 3]`, `[]` or `["a", "b"]`, never a number. An empty `[]` default and a `[]` element of
a tuple returned against its declared `#(i32[], string)` take the declared element type, on every target alike.
