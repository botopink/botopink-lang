# generic_bool_array_equality

`==` over generic records holding `bool[]`s compares the arrays element by element, as it does an
`i32[]` (decisions 568, 1031 (2)). On wasm an `$arr_bool` is compared as one, before the word array
it is a subtype of.
