-module(bp_load_cases_behavior_static_written_fn@main@@Dot).
-export([make/0, area/1, describe/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

make() ->
    {bp_load_cases_behavior_static_written_fn@main@@Dot, 0}.

area(Self) ->
    0.

describe(Self) ->
    <<"a dot">>.

'__bp_get'(V, n) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Dot", [{"n", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [bp_load_cases_behavior_static_written_fn@main@@Shape].
