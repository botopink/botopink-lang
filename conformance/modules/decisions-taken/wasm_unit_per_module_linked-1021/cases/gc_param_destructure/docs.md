# gc_param_destructure

A parameter written as a tuple pattern (`#(_, s): #(i32, string)`) binds each element at its type; on wasm the GC lowering destructures it as a `val` is (decision 1021 (10)).
