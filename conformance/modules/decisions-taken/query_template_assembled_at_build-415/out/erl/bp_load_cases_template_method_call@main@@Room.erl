-module(bp_load_cases_template_method_call@main@@Room).
-export([open/1, '__bp_get'/2, '__bp_format'/1]).

open(Self) ->
    bp_load_cases_template_method_call@main@@Greeter:greet(erlang:element(2, Self), <<"WELCOME">>).

'__bp_get'(V, host) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Room", [{"host", erlang:element(2, V)}]}.
