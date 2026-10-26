-module(bp_load_cases_template_method_call@main@@Report).
-export([title/1, '__bp_get'/2, '__bp_format'/1]).

title(Self) ->
    bp_load_cases_template_method_call@main@@Memory:fetch(erlang:element(2, Self), <<"title">>).

'__bp_get'(V, db) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Report", [{"db", erlang:element(2, V)}]}.
