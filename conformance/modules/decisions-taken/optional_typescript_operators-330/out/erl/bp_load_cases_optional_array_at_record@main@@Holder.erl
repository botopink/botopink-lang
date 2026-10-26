-module(bp_load_cases_optional_array_at_record@main@@Holder).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, posts) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Holder", [{"posts", erlang:element(2, V)}]}.
