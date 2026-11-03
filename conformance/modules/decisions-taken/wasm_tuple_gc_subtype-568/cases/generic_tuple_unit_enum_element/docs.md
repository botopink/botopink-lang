# generic_tuple_unit_enum_element

A tuple holding an all-unit enum's variant, bound to a type parameter, compares the variant by value
(decision 568): on wasm the ordinal is in its enum's box, a subtype of `$box_i32`.
