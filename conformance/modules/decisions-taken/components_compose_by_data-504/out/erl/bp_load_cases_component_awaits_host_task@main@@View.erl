-module(bp_load_cases_component_awaits_host_task@main@@View).
-export(['__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

'__bp_get'(V, text) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "View", [{"text", erlang:element(2, V)}]}.

'__bp_behaviors'() -> ['Renderable'].
