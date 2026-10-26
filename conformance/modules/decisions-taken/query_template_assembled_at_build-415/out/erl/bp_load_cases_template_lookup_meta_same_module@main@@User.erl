-module(bp_load_cases_template_lookup_meta_same_module@main@@User).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, id) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "User", [{"id", erlang:element(2, V)}]}.
