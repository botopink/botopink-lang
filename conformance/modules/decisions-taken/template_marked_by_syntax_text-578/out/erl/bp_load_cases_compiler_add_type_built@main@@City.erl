-module(bp_load_cases_compiler_add_type_built@main@@City).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "City", [{"name", erlang:element(2, V)}]}.
