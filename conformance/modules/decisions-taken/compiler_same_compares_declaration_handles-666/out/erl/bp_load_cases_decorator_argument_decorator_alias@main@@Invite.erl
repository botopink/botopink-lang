-module(bp_load_cases_decorator_argument_decorator_alias@main@@Invite).
-export([guestsEach/0, hostsEach/0, hostsAll/0, '__bp_get'/2, '__bp_format'/1]).

guestsEach() ->
    (<<"email">>).

hostsEach() ->
    (<<"lowercased">>).

hostsAll() ->
    (2).

'__bp_get'(V, guests) -> erlang:element(2, V);
'__bp_get'(V, hosts) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Invite", [{"guests", erlang:element(2, V)}, {"hosts", erlang:element(3, V)}]}.
