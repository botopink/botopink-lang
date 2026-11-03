# generic_tuple_bool_element

A tuple holding a `bool`, bound to a type parameter, prints the element as a bool and compares it
by value (decisions 568, 1031 (2)): handed to a generic record's field, to a generic `fn`, nested in
a generic record. On wasm the element is in `$box_bool`.
