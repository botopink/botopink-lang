-module(bp_load_cases_decorator_arguments_check@main@@Account).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, handle) -> erlang:element(2, V);
'__bp_get'(V, password) -> erlang:element(3, V);
'__bp_get'(V, confirm) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Account", [{"handle", erlang:element(2, V)}, {"password", erlang:element(3, V)}, {"confirm", erlang:element(4, V)}]}.
