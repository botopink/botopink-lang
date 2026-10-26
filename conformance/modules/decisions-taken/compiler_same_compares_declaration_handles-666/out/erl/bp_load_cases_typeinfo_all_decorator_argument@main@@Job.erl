-module(bp_load_cases_typeinfo_all_decorator_argument@main@@Job).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, kind) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Job", [{"kind", erlang:element(2, V)}]}.
