-module(bp_load_cases_implement_body_marker_admitted@main@@Box).
-export([value/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

%% @Async — eager lowering
value(Self) ->
    erlang:element(2, Self).

'__bp_get'(V, v) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Box", [{"v", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [bp_load_cases_implement_body_marker_admitted@main@@Fetched].
