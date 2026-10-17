# generic_record_equality_unwritten

`==` is structural on every target (decision 210), and a generic record or enum whose type
arguments nothing writes is no exception: each field is compared by what it holds — a number by
value, a string by content, an array, a tuple, a record or a variant part by part (decision 569).
On wasm the type parameter's slots compare through the one structural `unknown` equality.
