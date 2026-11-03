# bool_array_ops_into_slot

A `bool[]` an array operation answers — `filter`, `slice`, `append`, `map` (a lambda answering a
bool), `reverse`, `unique` — is an array of bools when a type parameter's slot takes it, and `join`
writes its elements as `true` / `false` (decisions 568, 1031 (2)). On wasm every one of these
operations answers an `$arr_bool` over one, never the word array a cast would trap on.
