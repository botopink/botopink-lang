-module(bp_load_cases_is_behavior_identity_run_time@main@@Tag).
-export([shown/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

shown(Self) ->
    erlang:element(2, Self).

'__bp_get'(V, value) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Tag", [{"value", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [bp_load_cases_is_behavior_identity_run_time@main@@Shown].
