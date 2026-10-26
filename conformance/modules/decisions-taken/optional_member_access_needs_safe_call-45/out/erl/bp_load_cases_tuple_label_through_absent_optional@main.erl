-module(bp_load_cases_tuple_label_through_absent_optional@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__rows'/0, '__bp_priv__flags'/0]).

%%% Decision 45 — `xs.at(i)?.b` on an ABSENT element answers absent: the label

%%% is read only when the tuple is there, so `?? d` answers `d`, and a present

%%% element whose label holds `0`, `false` or `""` is that value, not absence

%%% (the present half is `tuple_label_through_optional`). One function holds

%%% `??` over an integer, a float and a bool, each its own width.

rows() ->
    [{1, <<"x">>}, {0, <<"">>}].

flags() ->
    [{1.5, false}].

main() ->
    Es = [],
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Es, 0)) of
        undefined ->
            <<"none">>;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt1) -> erlang:element(1, _Opt1) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Es, 3)) of
        undefined ->
            0;
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    Rs = rows(),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(1, _Opt2) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Rs, 5)) of
        undefined ->
            (-1);
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt3) -> erlang:element(1, _Opt3) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Rs, 1)) of
        undefined ->
            7;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt4) -> erlang:element(2, _Opt4) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Rs, 1)) of
        undefined ->
            <<"none">>;
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([(fun(undefined) -> undefined; (_Opt5) -> erlang:element(1, _Opt5) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Rs, 1))]),
    '__bp_print'([(fun(undefined) -> undefined; (_Opt6) -> erlang:element(1, _Opt6) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Rs, 9))]),
    Fs = flags(),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt7) -> erlang:element(1, _Opt7) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Fs, 0)) of
        undefined ->
            0.0;
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt8) -> erlang:element(1, _Opt8) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Fs, 4)) of
        undefined ->
            9.5;
        __bp_nullish@6 ->
            __bp_nullish@6
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt9) -> erlang:element(2, _Opt9) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Fs, 0)) of
        undefined ->
            true;
        __bp_nullish@7 ->
            __bp_nullish@7
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt10) -> erlang:element(2, _Opt10) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Fs, 4)) of
        undefined ->
            true;
        __bp_nullish@8 ->
            __bp_nullish@8
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/tuple_label_through_absent_optional|*">>.

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

'__bp_priv__rows'() -> rows().

'__bp_priv__flags'() -> flags().
