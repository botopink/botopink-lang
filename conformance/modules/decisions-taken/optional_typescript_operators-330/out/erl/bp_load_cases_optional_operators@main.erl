-module(bp_load_cases_optional_operators@main).
-compile({no_auto_import,[node/1]}).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__node'/1, '__bp_priv__numbers'/1]).

%%% Decision 330 — `?T` is read with TypeScript's operators: `??`, `?.`,

%%% `?.[i]` and the postfix `!` (`?.(args)` is `run/optional_call_operator`).

%%% `?.` flattens: a link answering `?U` through `?.` is `?U`, so one `??`

%%% defaults it. On all four targets.

%% type Node: name, tags, next

node(Present) ->
    case Present of
        true ->
            {bp_load_cases_optional_operators@main@@Node, <<"a">>, [<<"t0">>, <<"t1">>], undefined};
        false ->
            undefined
    end.

numbers(Present) ->
    case Present of
        true ->
            [10, 20];
        false ->
            undefined
    end.

main() ->
    % `?.[i]`: the index read through the optional, absent when it is.
    '__bp_print'([case case numbers(true) of
        undefined ->
            undefined;
        __bp_opt_23_24 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_23_24, 1)
    end of
        undefined ->
            0;
        __bp_nullish ->
            __bp_nullish
    end]),
    '__bp_print'([case case numbers(true) of
        undefined ->
            undefined;
        __bp_opt_24_24 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_24_24, 5)
    end of
        undefined ->
            (-1);
        __bp_nullish@1 ->
            __bp_nullish@1
    end]),
    '__bp_print'([case case numbers(false) of
        undefined ->
            undefined;
        __bp_opt_25_25 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_25_25, 0)
    end of
        undefined ->
            (-2);
        __bp_nullish@2 ->
            __bp_nullish@2
    end]),
    % `?.` flattens: `next?.name` is `?string`, not `??string`.
    '__bp_print'([case (fun(undefined) -> undefined; (_Opt0) -> erlang:element(2, _Opt0) end)((fun(undefined) -> undefined; (_Opt1) -> erlang:element(4, _Opt1) end)(node(true))) of
        undefined ->
            <<"none">>;
        __bp_nullish@3 ->
            __bp_nullish@3
    end]),
    '__bp_print'([case case (fun(undefined) -> undefined; (_Opt2) -> erlang:element(3, _Opt2) end)(node(true)) of
        undefined ->
            undefined;
        __bp_opt_28_27 ->
            (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(__bp_opt_28_27, 0)
    end of
        undefined ->
            <<"none">>;
        __bp_nullish@4 ->
            __bp_nullish@4
    end]),
    % The postfix `!`: the value, when it is there.
    '__bp_print'([erlang:element(2, case node(true) of
        undefined ->
            erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} node(true)! at src/main.bp:30:11">>});
        __bp_opt_30_21 ->
            __bp_opt_30_21
    end)]),
    '__bp_print'([case (fun(__L, __I) -> __N = length(__L), __J = case __I < 0 of true -> __I + __N; false -> __I end, case ((__J >= 0) andalso (__J < __N)) of true -> lists:nth(__J + 1, __L); false -> undefined end end)(case numbers(true) of
        undefined ->
            erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} numbers(true)! at src/main.bp:31:11">>});
        __bp_opt_31_24 ->
            __bp_opt_31_24
    end, 0) of
        undefined ->
            0;
        __bp_nullish@5 ->
            __bp_nullish@5
    end]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/optional_operators|*">>.

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

'__bp_priv__node'(A0) -> node(A0).

'__bp_priv__numbers'(A0) -> numbers(A0).
