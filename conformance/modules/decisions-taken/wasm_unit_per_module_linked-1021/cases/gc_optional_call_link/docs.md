# gc_optional_call_link

`f?.(x)` over an optional function field answers the optional of what the function answers — a string, a word, a float —, absent where the field is; on wasm the GC lowering holds it as the payload's reference or box (decision 1021 (10)).
