-module(bp_load_cases_optional_array_at_record@main@@Post).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, title) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Post", [{"title", erlang:element(2, V)}]}.
