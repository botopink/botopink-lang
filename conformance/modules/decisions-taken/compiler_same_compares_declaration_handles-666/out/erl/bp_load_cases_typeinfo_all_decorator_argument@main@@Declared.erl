-module(bp_load_cases_typeinfo_all_decorator_argument@main@@Declared).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, module) -> erlang:element(3, V);
'__bp_get'(V, meta) -> erlang:element(4, V);
'__bp_get'(V, returnTypeName) -> erlang:element(5, V);
'__bp_get'(V, value) -> erlang:element(6, V);
'__bp_get'(V, typedMeta) -> erlang:element(7, V).

'__bp_format'(V) -> {record, "Declared", [{"name", erlang:element(2, V)}, {"module", erlang:element(3, V)}, {"meta", erlang:element(4, V)}, {"returnTypeName", erlang:element(5, V)}, {"value", erlang:element(6, V)}, {"typedMeta", erlang:element(7, V)}]}.
