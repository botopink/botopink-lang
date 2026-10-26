-module(bp_load_cases_numeric_suffix_positions@main@@Stamp).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, mtime) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Stamp", [{"mtime", erlang:element(2, V)}]}.
