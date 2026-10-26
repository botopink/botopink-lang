-module(bp_load_cases_decl_behavior_member_typed@main@@Db).
-export([make/0, start/1, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

make() ->
    {bp_load_cases_decl_behavior_member_typed@main@@Db, <<"mem">>}.

start(Self) ->
    <<"db up">>.

'__bp_get'(V, url) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Db", [{"url", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [bp_load_cases_decl_behavior_member_typed@main@@Module].
