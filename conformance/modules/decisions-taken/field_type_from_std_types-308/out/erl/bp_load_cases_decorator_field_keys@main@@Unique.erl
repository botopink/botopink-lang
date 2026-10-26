-module(bp_load_cases_decorator_field_keys@main@@Unique).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, column) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Unique", [{"column", erlang:element(2, V)}]}.
