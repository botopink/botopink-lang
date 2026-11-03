# generic_bool_array_slot

A `bool[]` bound to a type parameter is an array of bools wherever the parameter takes it: a
generic record's field holding one, a literal or a named array, prints `[true, false]` (decisions 568,
1031 (2)). On wasm the array has a GC type of its own, `$arr_bool`, a subtype of the word array's as
`$box_bool` is of `$box_i32`, so a slot holding one prints its elements as bools, never the words they
are held as.
