# gc_optional_field_payload

`recv?.field` over a field holding an array, a tuple or an optional array answers the optional of the field's declared type, and the absent arm of `xs?.[k]` is absent; on wasm the GC lowering reads the payload off the field's type (decision 1021 (10)).
