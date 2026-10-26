-module(bp_load_cases_use_conditional_argument@main@@Element).
-export(['__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

'__bp_get'(V, text) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Element", [{"text", erlang:element(2, V)}]}.

'__bp_behaviors'() -> ['Renderable'].
