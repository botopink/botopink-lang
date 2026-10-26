-module(bp_load_cases_prelude_name_bare@main@@Badge).
-export(['__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

'__bp_get'(V, label) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Badge", [{"label", erlang:element(2, V)}]}.

'__bp_behaviors'() -> ['Renderable'].
