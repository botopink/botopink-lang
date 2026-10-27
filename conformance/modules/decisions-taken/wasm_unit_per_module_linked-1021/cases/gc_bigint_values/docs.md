# gc_bigint_values

A `bigint` on wasm is, in the GC lowering, its block's bytes (`[L][limbs…]`) in a byte array, copied into and out of the linear memory std-wasm's `bigint.*` functions read (decisions 332, 1021 (8), (10)); every target prints the same digits.
