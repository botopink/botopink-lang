-module(std@testing@mocks@@UserService).
-export([list/1, name/2, '__bp_get'/2, '__bp_format'/1]).

list(Self) ->
    '__bp_method'(all, erlang:element(2, Self), []).

name(Self, Id) ->
    '__bp_method'(find, erlang:element(2, Self), [Id]).

'__bp_get'(V, repo) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "UserService", [{"repo", erlang:element(2, V)}]}.

'__bp_method'(M, V, Args) when erlang:is_map(V) -> erlang:apply(maps:get(M, V), [V | Args]);
'__bp_method'(M, V, Args) ->
    T = case erlang:is_tuple(V) of true -> erlang:element(1, V); false -> V end,
    O = case string:split(erlang:atom_to_list(T), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> T end,
    erlang:apply(O, M, [V | Args]).
