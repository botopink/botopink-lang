-module(bp_load_cases_src_location@main@@SourceLocation).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, file) -> erlang:element(2, V);
'__bp_get'(V, line) -> erlang:element(3, V);
'__bp_get'(V, column) -> erlang:element(4, V);
'__bp_get'(V, fnName) -> erlang:element(5, V).

'__bp_format'(V) -> {record, "SourceLocation", [{"file", erlang:element(2, V)}, {"line", erlang:element(3, V)}, {"column", erlang:element(4, V)}, {"fnName", erlang:element(5, V)}]}.
