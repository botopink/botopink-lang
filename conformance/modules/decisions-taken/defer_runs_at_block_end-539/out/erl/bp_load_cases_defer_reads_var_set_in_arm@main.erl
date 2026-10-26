-module(bp_load_cases_defer_reads_var_set_in_arm@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__boom'/0, '__bp_priv__viaIf'/1, '__bp_priv__viaCase'/1, '__bp_priv__viaValueCase'/1, '__bp_priv__viaValueIf'/1, '__bp_priv__show'/1]).

%%% Decision 539 (amended) — the deferred expression reads a `var` when it

%%% runs, and a reassignment inside a nested arm counts: an arm that

%%% reassigns and then panics hands the defer the new value.

%% import failure, Failure

boom() ->
    erlang:error({panic, <<"boom">>}).

viaIf(C) ->
    F = <<"a">>,
    __BpDeferRef1 = erlang:make_ref(),
    erlang:put(__BpDeferRef1, {F}),
    try
        F@3 = case C of
            true ->
                F@2 = <<"b">>,
                erlang:put(__BpDeferRef1, {F@2}),
                erlang:error({panic, <<"x">>}),
                F@2;
            _ ->
                F
        end,
        erlang:put(__BpDeferRef1, {F@3}),
        1
    after
        {F@1} = erlang:erase(__BpDeferRef1),
        '__bp_print'([<<"close ", F@1/binary>>])
    end.

viaCase(N) ->
    F = <<"a">>,
    __BpDeferRef2 = erlang:make_ref(),
    erlang:put(__BpDeferRef2, {F}),
    try
        F@4 = case N of
            0 ->
                F@2 = <<"c">>,
                erlang:put(__BpDeferRef2, {F@2}),
                erlang:error({panic, <<"y">>}),
                F@2;
            _ ->
                F@3 = <<"d">>,
                erlang:put(__BpDeferRef2, {F@3}),
                F@3
        end,
        erlang:put(__BpDeferRef2, {F@4}),
        2
    after
        {F@1} = erlang:erase(__BpDeferRef2),
        '__bp_print'([<<"close ", F@1/binary>>])
    end.

viaValueCase(N) ->
    F = <<"a">>,
    __BpDeferRef3 = erlang:make_ref(),
    erlang:put(__BpDeferRef3, {F}),
    try
        R = erlang:element(1, {_, F@4} = case N of
            0 ->
                F@2 = <<"e">>,
                erlang:put(__BpDeferRef3, {F@2}),
                __BpArmV1 = boom(),
                {__BpArmV1, F@2};
            _ ->
                F@3 = <<"g">>,
                erlang:put(__BpDeferRef3, {F@3}),
                __BpArmV2 = 3,
                {__BpArmV2, F@3}
        end),
        erlang:put(__BpDeferRef3, {F@4}),
        R
    after
        {F@1} = erlang:erase(__BpDeferRef3),
        '__bp_print'([<<"close ", F@1/binary>>])
    end.

viaValueIf(C) ->
    F = <<"a">>,
    __BpDeferRef4 = erlang:make_ref(),
    erlang:put(__BpDeferRef4, {F}),
    try
        R = erlang:element(1, {_, F@4} = case C of
            true ->
                F@2 = <<"h">>,
                erlang:put(__BpDeferRef4, {F@2}),
                __BpArmV3 = boom(),
                {__BpArmV3, F@2};
            _ ->
                F@3 = <<"i">>,
                erlang:put(__BpDeferRef4, {F@3}),
                __BpArmV4 = 4,
                {__BpArmV4, F@3}
        end),
        erlang:put(__BpDeferRef4, {F@4}),
        R
    after
        {F@1} = erlang:erase(__BpDeferRef4),
        '__bp_print'([<<"close ", F@1/binary>>])
    end.

show(R) ->
    case R of
        {ok, V} ->
            '__bp_print'([<<"Ok ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>]);
        {error, F} ->
            '__bp_print'([<<"Error ", ('__bp_text'(erlang:element(3, F)))/binary, ": ", ('__bp_text'(erlang:element(2, F)))/binary>>])
    end.

main() ->
    show(std@failure:attempt(fun() ->
        viaIf(true)
    end)),
    show(std@failure:attempt(fun() ->
        viaCase(0)
    end)),
    show(std@failure:attempt(fun() ->
        viaCase(1)
    end)),
    show(std@failure:attempt(fun() ->
        viaValueCase(0)
    end)),
    show(std@failure:attempt(fun() ->
        viaValueCase(1)
    end)),
    show(std@failure:attempt(fun() ->
        viaValueIf(true)
    end)),
    show(std@failure:attempt(fun() ->
        viaValueIf(false)
    end)).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/defer_reads_var_set_in_arm|*">>.

'__bp_text'(Value) when erlang:is_binary(Value) -> Value;
'__bp_text'(Value) -> unicode:characters_to_binary('__bp_show'(Value, true)).

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
    '__bp_load_siblings'(),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_load_siblings'() ->
    case code:which(?MODULE) of
        Path when erlang:is_list(Path) ->
            lists:foreach(fun(Src) ->
                case code:ensure_loaded(erlang:list_to_atom(filename:basename(Src, ".erl"))) of
                    {module, _} -> ok;
                    _ ->
                        case compile:file(Src, [binary, return_errors]) of
                            {ok, Mod, Bin} -> code:load_binary(Mod, Src, Bin);
                            Bad ->
                                io:format(standard_error, "error: ~ts does not compile - refusing to run~n  ~p~n", [Src, Bad]),
                                erlang:halt(1)
                        end
                end
            end, filelib:wildcard(filename:join(filename:dirname(Path), "*.erl")));
        _ -> ok
    end.

'__bp_priv__boom'() -> boom().

'__bp_priv__viaIf'(A0) -> viaIf(A0).

'__bp_priv__viaCase'(A0) -> viaCase(A0).

'__bp_priv__viaValueCase'(A0) -> viaValueCase(A0).

'__bp_priv__viaValueIf'(A0) -> viaValueIf(A0).

'__bp_priv__show'(A0) -> show(A0).
