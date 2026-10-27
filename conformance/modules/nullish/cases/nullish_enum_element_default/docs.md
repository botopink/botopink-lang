# nullish_enum_element_default

`xs.at(i) ?? v` over an array of an enum with payloads (decision 330: `?T`'s `unwrapOr` is `??`) answers the element, or
`v` when the index is out of range — a value of the enum, which a parameter of that enum takes as it is: `circle 2`,
`circle 9`, `dot`, `circle 2`, on every target alike.
