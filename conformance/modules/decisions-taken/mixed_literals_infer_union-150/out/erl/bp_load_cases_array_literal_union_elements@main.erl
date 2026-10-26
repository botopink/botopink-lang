-module(bp_load_cases_array_literal_union_elements@main).
-compile({no_auto_import,[size/1]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__size'/1, '__bp_priv__mixed'/0]).

%%% Decision 150 (D5, decision 8 §3.2) — the elements of an array literal

%%% that disagree make the union of their types (`array_literal_union` reads

%%% `length` only): each element read back is the member it is — printed,

%%% iterated, read by index and by `at`, passed to a parameter of the union —

%%% whether the union is inferred (`[3, "abcd"]`) or written

%%% (`(i32 | string)[]`). wasm stored the elements as bare words: `[3, 256]`.

size(V) ->
    case V of
        I32 when erlang:is_number(I32), (I32 == erlang:trunc(I32)), (I32 >= -2147483648), (I32 =< 2147483647) ->
            N = erlang:trunc(I32),
            N;
        S = String when erlang:is_binary(String) ->
            erlang:length(unicode:characters_to_list(S))
    end.

mixed() ->
    [5, <<"xy">>].

main() ->
    Xs = [3, <<"abcd">>],
    '__bp_print'([Xs]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 0)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 1)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 1)]),
    '__bp_print'([(fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Xs, 7)]),
    Sum = 0,
    Sum@3 = lists:foldl(fun(X, Sum@1) ->
        '__bp_print'([X]),
        Sum@2 = '__bp_int'((Sum@1 + size(X)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:35:19">>),
        Sum@2
    end, Sum, Xs),
    '__bp_print'([Sum@3]),
    Ys = [2, <<"b">>, 3],
    lists:foreach(fun(Y) ->
        '__bp_print'([Y])
    end, Ys),
    '__bp_print'([Ys]),
    Bs = [true, <<"t">>],
    '__bp_print'([Bs]),
    '__bp_print'([mixed()]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/array_literal_union_elements|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when erlang:is_binary(V) -> V;
'__bp_show'(V, _) when erlang:is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when erlang:is_list(V) -> [$[, lists:join(", ", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'({ok, P}, _) -> ["Ok(", '__bp_show'(P, false), $)];
'__bp_show'({error, P}, _) -> ["Error(", '__bp_show'(P, false), $)];
'__bp_show'(V, _) when erlang:is_tuple(V), erlang:tuple_size(V) > 0, erlang:is_atom(erlang:element(1, V)), erlang:element(1, V) =/= true, erlang:element(1, V) =/= false, erlang:element(1, V) =/= undefined -> '__bp_tagged'(erlang:element(1, V), V);
'__bp_show'(V, _) when erlang:is_tuple(V) -> ["#(", lists:join(", ", ['__bp_show'(E, false) || E <- erlang:tuple_to_list(V)]), $)];
'__bp_show'(undefined, _) -> "null";
'__bp_show'(V, _) when erlang:is_atom(V), V =/= true, V =/= false, V =/= undefined -> '__bp_tagged'(V, V);
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'__bp_tagged'(A, V) ->
    M = case string:split(erlang:atom_to_list(A), "__v__") of [P, _] -> erlang:list_to_atom(P); _ -> A end,
    case code:ensure_loaded(M) =:= {module, M} andalso erlang:function_exported(M, '__bp_format', 1) of true -> '__bp_render'(erlang:apply(M, '__bp_format', [V])); false -> io_lib:format("~p", [V]) end.

'__bp_render'({text, T}) -> T;
'__bp_render'({variant, N, []}) -> N;
'__bp_render'({_, N, Fs}) -> [N, $(, lists:join(", ", [[K, ": ", '__bp_show'(Val, false)] || {K, Val} <- Fs]), $)].

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__size'(A0) -> size(A0).

'__bp_priv__mixed'() -> mixed().
