# case_value_union_binding

A `case` whose arms have different types is the union of the arm types, with no error; a `val` bound to it holds the union, and each value is read back member by member through `case` narrowing.
