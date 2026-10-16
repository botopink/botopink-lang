# generic_tuple_slot

A tuple bound to a type parameter is a tuple wherever the parameter takes it: a generic `fn`
answers it, a generic record's field holds it, its elements read back by position, and `==`
compares it by its elements (decision 568). On wasm the tuple has a type of its own, so a slot
holding one prints `#(…)`, never an array's `[…]`.
