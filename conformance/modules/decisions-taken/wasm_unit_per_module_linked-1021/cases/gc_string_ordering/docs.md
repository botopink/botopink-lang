# gc_string_ordering

Strings order by their bytes, a prefix before a longer string; on wasm the GC lowering compares them with `$__str_cmp` (decision 1021 (10)). The linear fallback compared addresses.
