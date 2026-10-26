-module(bp_load_cases_index_user_type@main@@Registry).
-export([at/2, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

at(Self, Key) ->
    Found = (fun(__L, __X) -> __Find = fun __F(__I, [__H | __T]) -> case (__H =:= __X) of true -> __I; false -> __F(__I + 1, __T) end; __F(_, []) -> -1 end, __Find(0, __L) end)(erlang:element(2, Self), Key),
    case (Found < 0) of
        true ->
            undefined;
        _ ->
            Found
    end.

'__bp_get'(V, names) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Registry", [{"names", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [std@primitives@@Index].
