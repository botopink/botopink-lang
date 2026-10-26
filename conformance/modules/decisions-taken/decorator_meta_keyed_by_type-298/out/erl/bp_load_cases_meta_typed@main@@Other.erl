-module(bp_load_cases_meta_typed@main@@Other).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, note) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Other", [{"note", erlang:element(2, V)}]}.
