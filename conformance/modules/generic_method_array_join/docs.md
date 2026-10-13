# generic_method_array_join

A generic method of a library type answers an array of the type argument it was bound with, and the array's own methods read
its elements by that type: `toArray()` of a `Seq<string>` joins strings, `select<U>` binds `U` from its lambda's answer (a
record's `string` field, a number), and a chain through `where` keeps the element. The cell holds a `path` library so the
generic type is declared in another module, as a library's is.
