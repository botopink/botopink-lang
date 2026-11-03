# generic_nested_array_slot

An array of arrays bound to a type parameter prints as the nested arrays it holds, of words or of
strings (decision 568): on wasm each inner array is an element of an `anyref` array, printed by what
it is.
