-module(std@collections@@Set).
-compile({no_auto_import,[size/1]}).
-export([contains/2, size/1, isEmpty/1, toList/1, insert/2, delete/2, union/2, intersection/2, difference/2, empty/0, fromList/1, '__bp_get'/2, '__bp_format'/1]).

contains(Self, X) ->
    array_any(erlang:element(2, Self), fun(Y) ->
        (Y =:= X)
    end).

size(Self) ->
    erlang:length(erlang:element(2, Self)).

isEmpty(Self) ->
    (erlang:length(erlang:element(2, Self)) =:= 0).

toList(Self) ->
    erlang:element(2, Self).

insert(Self, X) ->
    case array_any(erlang:element(2, Self), fun(Y) ->
        (Y =:= X)
    end) of
        true ->
            Self;
        false ->
            {std@collections@@Set, (erlang:element(2, Self) ++ [X])}
    end.

delete(Self, X) ->
    {std@collections@@Set, lists:filter(fun(Item) ->
        (Item =/= X)
    end, erlang:element(2, Self))}.

union(Self, Other) ->
    {std@collections@@Set, (erlang:element(2, Self) ++ erlang:element(2, difference(Other, Self)))}.

intersection(Self, Other) ->
    {std@collections@@Set, lists:filter(fun(X) ->
        contains(Other, X)
    end, erlang:element(2, Self))}.

difference(Self, Other) ->
    {std@collections@@Set, lists:filter(fun(X) ->
        (not contains(Other, X))
    end, erlang:element(2, Self))}.

empty() ->
    {std@collections@@Set, []}.

fromList(Xs) ->
    Out = lists:foldl(fun(X, Out) ->
        insert(Out, X)
    end, {std@collections@@Set, []}, Xs),
    Out.

'__bp_get'(V, items) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Set", [{"items", erlang:element(2, V)}]}.

array_any(Self, Pred) ->
    (erlang:length(lists:filter(Pred, Self)) =/= 0).
