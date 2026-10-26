# tuple_element_array_read

Decision 738: a pair is the tuple `#(A, B)`. `t._1` read off a tuple local that holds an array is that array: it prints
`[4, 8]`, its length is `2`, a float array prints `[1.5, 2.5]`, and the same holds beside a read of another tuple's array
element through `.first()` (`a`, then `["a"]`).
