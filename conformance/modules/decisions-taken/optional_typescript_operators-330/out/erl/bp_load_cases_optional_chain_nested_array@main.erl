-module(bp_load_cases_optional_chain_nested_array@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__make'/1]).

%%% Decision 330 — `?.` along a chain whose middle link is an optional array:

%%% `f?.fields?.[0]?.name` is absent at the first absent link (no `f`, no

%%% `fields`, no element) and the element's own field otherwise, on every target.

%% type Field: name

%% type Form: fields

make(K) ->
    case (K =:= 0) of
        true ->
            undefined;
        _ ->
            {bp_load_cases_optional_chain_nested_array@main@@Form, [{bp_load_cases_optional_chain_nested_array@main@@Field, <<"email">>}]}
    end.

main() ->
    F = make(1),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)(case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(2, _Opt1) end)(F) of
        undefined ->
            undefined;
        __bp_opt_18_20 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_18_20, 0)
    end) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    First = case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(2, _Opt2) end)(F) of
        undefined ->
            undefined;
        __bp_opt_19_26 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_19_26, 0)
    end,
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt3) -> erlang:element(2, _Opt3) end)(First) of
        undefined ->
            <<"none">>;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    Fields = (fun(undefined) -> undefined; (_Opt4) -> erlang:element(2, _Opt4) end)(F),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt5) -> erlang:element(2, _Opt5) end)(case Fields of
        undefined ->
            undefined;
        __bp_opt_22_17 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_22_17, 0)
    end) of
        undefined ->
            <<"none">>;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt6) -> erlang:element(2, _Opt6) end)(case (fun(undefined) -> undefined; (_Opt7) -> erlang:element(2, _Opt7) end)(make(0)) of
        undefined ->
            undefined;
        __bp_opt_23_26 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_23_26, 0)
    end) of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    Empty = {bp_load_cases_optional_chain_nested_array@main@@Form, undefined},
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt8) -> erlang:element(2, _Opt8) end)(case (fun(undefined) -> undefined; (_Opt9) -> erlang:element(2, _Opt9) end)(Empty) of
        undefined ->
            undefined;
        __bp_opt_25_24 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_25_24, 0)
    end) of
        undefined ->
            <<"none">>;
        __bp_nullish@4 ->
            __bp_nullish@4
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_chain_nested_array|*">>.

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

'__bp_priv__make'(A0) -> make(A0).
