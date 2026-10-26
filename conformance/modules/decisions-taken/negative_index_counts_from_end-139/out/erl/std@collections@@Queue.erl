-module(std@collections@@Queue).
-compile({no_auto_import,[size/1]}).
-export([size/1, isEmpty/1, enqueue/2, dequeue/1, peek/1, toList/1, empty/0, fromList/1, '__bp_get'/2, '__bp_format'/1]).

size(Self) ->
    erlang:length(erlang:element(2, Self)).

isEmpty(Self) ->
    (erlang:length(erlang:element(2, Self)) =:= 0).

enqueue(Self, Item) ->
    {std@collections@@Queue, (erlang:element(2, Self) ++ [Item])}.

dequeue(Self) ->
    Head = (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(erlang:element(2, Self), 0),
    Rest = array_slice(erlang:element(2, Self), 1, erlang:length(erlang:element(2, Self))),
    {{std@collections@@Queue, Rest}, Head}.

peek(Self) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(erlang:element(2, Self), 0).

toList(Self) ->
    erlang:element(2, Self).

empty() ->
    {std@collections@@Queue, []}.

fromList(Xs) ->
    {std@collections@@Queue, Xs}.

'__bp_get'(V, items) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Queue", [{"items", erlang:element(2, V)}]}.

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.
