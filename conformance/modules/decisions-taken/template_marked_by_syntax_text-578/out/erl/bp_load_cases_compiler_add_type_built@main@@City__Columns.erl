-module(bp_load_cases_compiler_add_type_built@main@@City__Columns).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, code) -> erlang:element(2, V);
'__bp_get'(V, size) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "City.Columns", [{"code", erlang:element(2, V)}, {"size", erlang:element(3, V)}]}.
