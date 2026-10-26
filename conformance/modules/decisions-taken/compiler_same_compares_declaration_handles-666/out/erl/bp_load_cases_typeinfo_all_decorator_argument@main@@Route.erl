-module(bp_load_cases_typeinfo_all_decorator_argument@main@@Route).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, path) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Route", [{"path", erlang:element(2, V)}]}.
