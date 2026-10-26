-module(bp_load_cases_decorator_marker_empty_body@main@@DeclaredTypedMeta).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, key) -> erlang:element(2, V);
'__bp_get'(V, value) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "DeclaredTypedMeta", [{"key", erlang:element(2, V)}, {"value", erlang:element(3, V)}]}.
