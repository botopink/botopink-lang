-module(bp_load_cases_index_user_type@main@@Matrix).
-export([at/2, slice/3, '__bp_get'/2, '__bp_format'/1, '__bp_behaviors'/0]).

at(Self, Key) ->
    (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(erlang:element(2, Self), Key).

slice(Self, Start, End) ->
    {bp_load_cases_index_user_type@main@@Matrix, array_slice(erlang:element(2, Self), Start, End)}.

'__bp_get'(V, rows) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "Matrix", [{"rows", erlang:element(2, V)}]}.

'__bp_behaviors'() -> [std@primitives@@Index, std@primitives@@Slice].

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.
