# primitive_property_outside_prelude_refused

Decision 873 (1): a property is a form of `primitives.bp` alone, accepted only while std's prelude is
parsed — not by the type's name. `type bytes { val size: i32; }` in a program is a parse error at `val`.
