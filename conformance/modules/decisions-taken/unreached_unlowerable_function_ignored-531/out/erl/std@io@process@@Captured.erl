-module(std@io@process@@Captured).
-export([wait/1, kill/2, '__bp_get'/2, '__bp_format'/1]).

%% @Async — eager lowering
wait(Self) ->
    erlang:error(unreachable).

kill(Self, S) ->
    case erlang:error(unreachable) of
        {ok, _} ->
            {ok, undefined};
        {error, M} ->
            {error, std@io@process:processError(<<"">>, erlang:element(2, Self), M)}
    end.

'__bp_get'(V, pid) -> erlang:element(2, V);
'__bp_get'(V, handle) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Captured", [{"pid", erlang:element(2, V)}, {"handle", erlang:element(3, V)}]}.
