-module(bp_load_cases_val_decorator_catalogue@main@@Setting).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, key) -> erlang:element(2, V);
'__bp_get'(V, declared) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Setting", [{"key", erlang:element(2, V)}, {"declared", erlang:element(3, V)}]}.
