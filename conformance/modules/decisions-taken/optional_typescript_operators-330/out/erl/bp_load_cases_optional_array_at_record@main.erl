-module(bp_load_cases_optional_array_at_record@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__holder'/1]).

%%% Decision 330 — a `?.` call over an optional array answers the element

%%% as the `?T` it is: an array of records answers the record itself, so a

%%% `?.` read of its field, and a default, work on every target.

%% type Post: title

%% type Holder: posts

holder(K) ->
    case (K =:= 0) of
        true ->
            {bp_load_cases_optional_array_at_record@main@@Holder, undefined};
        _ ->
            {bp_load_cases_optional_array_at_record@main@@Holder, [{bp_load_cases_optional_array_at_record@main@@Post, <<"tick">>}]}
    end.

main() ->
    Ps = erlang:element(2, holder(1)),
    P = (fun(undefined) -> undefined; (Bp__chain0) -> (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bp__chain0, 0) end)(Ps),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(2, _Opt1) end)(P) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    Absent = erlang:element(2, holder(0)),
    Q = (fun(undefined) -> undefined; (Bp__chain2) -> (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bp__chain2, 0) end)(Absent),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt3) -> erlang:element(2, _Opt3) end)(Q) of
        undefined ->
            <<"none">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt4) -> erlang:element(2, _Opt4) end)((fun(undefined) -> undefined; (Bp__chain5) -> (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bp__chain5, 0) end)(Ps)) of
        undefined ->
            <<"none">>;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt6) -> erlang:element(2, _Opt6) end)((fun(undefined) -> undefined; (Bp__chain7) -> (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Bp__chain7, 5) end)(Ps)) of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_array_at_record|*">>.

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

'__bp_priv__holder'(A0) -> holder(A0).
