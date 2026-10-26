-module(bp_load_cases_typeinfo_all_behavior_shared@main@@Orders).
-export([make/0, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

make() ->
    {bp_load_cases_typeinfo_all_behavior_shared@main@@Orders, <<"orders">>}.

'__bp_get'(V, table) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Orders", [{"table", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [bp_load_cases_typeinfo_all_behavior_shared@main@@Bean].
