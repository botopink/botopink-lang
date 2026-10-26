-module(bp_load_cases_decorator_arguments_check@main@@Check).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, at) -> erlang:element(2, V);
'__bp_get'(V, message) -> erlang:element(3, V);
'__bp_get'(V, kind) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Check", [{"at", erlang:element(2, V)}, {"message", erlang:element(3, V)}, {"kind", erlang:element(4, V)}]}.
