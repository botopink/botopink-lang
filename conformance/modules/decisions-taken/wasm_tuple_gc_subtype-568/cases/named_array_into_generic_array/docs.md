# named_array_into_generic_array

A named array of words, floats or bools, passed to a field typed by a type parameter's array
(`Q<T>(items: array<T>)`), holds the elements a literal would, and the named array is left as it
was (decisions 568, 1031 (2)). On wasm the field holds a boxed copy of the array.
