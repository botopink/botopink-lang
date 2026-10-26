-module(bp_load_cases_typeinfo_all_list@main@@Store).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, store) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Store", [{"store", erlang:element(2, V)}]}.
