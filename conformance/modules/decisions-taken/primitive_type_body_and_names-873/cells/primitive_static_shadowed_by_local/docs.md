# primitive_static_shadowed_by_local

Decision 873 (2): a parameter or a local named like a primitive type (`array`, `string`, `bytes`) is the
binding in its body — `array.length`, `string.length()` and `bytes.length()` read the value. The program
runs.
