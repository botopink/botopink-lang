-module(bp_load_cases_optional_method_absent_receiver@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__find'/1]).

%% behavior string

%%% Decision 330 — `recv?.m(args)` calls the method only on a present

%%% receiver: an absent one makes the whole call absent, on every target. The

%%% receiver is the optional itself here (a local, a call, an array element),

%%% not a link continuing a chain (`modules/optional_chain_method`).

find(Key) ->
    case (Key =:= <<"a">>) of
        true ->
            <<"found">>;
        false ->
            undefined
    end.

main() ->
    Absent = find(<<"b">>),
    Present = find(<<"a">>),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain0) -> '__bp_prim_length'(Bp__chain0) end)(Absent) of
        undefined ->
            (-1);
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain1) -> '__bp_prim_length'(Bp__chain1) end)(Present) of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([(fun(undefined) -> undefined; (Bp__chain2) -> '__bp_prim_length'(Bp__chain2) end)(find(<<"b">>))]),
    '__bp_print'([(fun(undefined) -> undefined; (Bp__chain3) -> '__bp_prim_length'(Bp__chain3) end)(find(<<"a">>))]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain4) -> '__bp_prim_toUpper'(Bp__chain4) end)(find(<<"b">>)) of
        undefined ->
            <<"none">>;
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain5) -> '__bp_prim_toUpper'(Bp__chain5) end)(find(<<"a">>)) of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain6) -> '__bp_prim_contains'(Bp__chain6, <<"ou">>) end)(find(<<"b">>)) of
        undefined ->
            false;
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain7) -> '__bp_prim_contains'(Bp__chain7, <<"ou">>) end)(find(<<"a">>)) of
        undefined ->
            false;
        __bp_nullish@5 ->
            __bp_nullish@5
    end]),
    Words = [<<"alpha">>, <<"be">>],
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain8) -> '__bp_prim_length'(Bp__chain8) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Words, 5)) of
        undefined ->
            (-7);
        __bp_nullish@6 ->
            __bp_nullish@6
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain9) -> '__bp_prim_slice'(Bp__chain9, 1, 3) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Words, 0)) of
        undefined ->
            <<"none">>;
        __bp_nullish@7 ->
            __bp_nullish@7
    end]),
    '__bp_print'([case (fun(undefined) -> undefined; (Bp__chain10) -> '__bp_prim_slice'(Bp__chain10, 1, 3) end)((fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(Words, 5)) of
        undefined ->
            <<"none">>;
        __bp_nullish@8 ->
            __bp_nullish@8
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_method_absent_receiver|*">>.

'__bp_prim_length'(Recv) when erlang:is_list(Recv) ->
    erlang:length(Recv);
'__bp_prim_length'(Recv) when erlang:is_binary(Recv) ->
    erlang:length(unicode:characters_to_list(Recv));
'__bp_prim_length'(Recv) ->
    erlang:error({bp_unsupported_method, <<"length">>, 0, Recv}).

'__bp_prim_toUpper'(Recv) when erlang:is_binary(Recv) ->
    string:uppercase(Recv);
'__bp_prim_toUpper'(Recv) ->
    erlang:error({bp_unsupported_method, <<"toUpper">>, 0, Recv}).

'__bp_prim_contains'(Recv, Arg0) when erlang:is_list(Recv) ->
    lists:member(Arg0, Recv);
'__bp_prim_contains'(Recv, Arg0) when erlang:is_binary(Recv) ->
    (string:find(Recv, Arg0) =/= nomatch);
'__bp_prim_contains'(Recv, _) ->
    erlang:error({bp_unsupported_method, <<"contains">>, 1, Recv}).

'__bp_prim_slice'(Recv, Arg0, Arg1) when erlang:is_list(Recv) ->
    array_slice(Recv, Arg0, Arg1);
'__bp_prim_slice'(Recv, Arg0, Arg1) when erlang:is_binary(Recv) ->
    string_slice(Recv, Arg0, Arg1);
'__bp_prim_slice'(Recv, _, _) ->
    erlang:error({bp_unsupported_method, <<"slice">>, 2, Recv}).

array_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            lists:sublist(Self, (Start) + 1, ((End) - (Start)));
        false ->
            lists:nthtail(Start, Self)
    end.

string_slice(Self, Start, End) ->
    case (End =/= undefined) of
        true ->
            (fun(__S, __A, __E) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, __F = case __E < 0 of true -> erlang:max(__N + __E, 0); false -> erlang:min(__E, __N) end, unicode:characters_to_binary(lists:sublist(__L, __B + 1, erlang:max(__F - __B, 0))) end)(Self, Start, End);
        false ->
            (fun(__S, __A) -> __L = unicode:characters_to_list(__S), __N = erlang:length(__L), __B = case __A < 0 of true -> erlang:max(__N + __A, 0); false -> erlang:min(__A, __N) end, unicode:characters_to_binary(lists:nthtail(__B, __L)) end)(Self, Start)
    end.

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

'__bp_priv__find'(A0) -> find(A0).
