-module(bp_load_cases_decorator_field_keys@main@@Index).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, columns) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Index", [{"columns", erlang:element(2, V)}]}.
