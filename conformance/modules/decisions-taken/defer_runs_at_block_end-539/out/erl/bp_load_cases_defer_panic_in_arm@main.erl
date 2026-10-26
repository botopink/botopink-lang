-module(bp_load_cases_defer_panic_in_arm@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__viaArm'/1, '__bp_priv__viaIfBranch'/1, '__bp_priv__show'/1]).

%%% Decision 539 (3) — a panic `attempt` catches runs the defers of the

%%% block or `case` arm it happens in, before the panic leaves it.

%% import failure, Failure

viaArm(N) ->
    case N of
        0 ->
            try
                erlang:error({panic, <<"in arm">>})
            after
                '__bp_print'([<<"arm released">>])
            end;
        _ ->
            try
                ok
            after
                '__bp_print'([<<"other released">>])
            end
    end,
    1.

viaIfBranch(C) ->
    case C of
        true ->
            try
                erlang:error({panic, <<"in branch">>})
            after
                '__bp_print'([<<"branch released">>])
            end;
        _ -> ok
    end,
    2.

show(R) ->
    case R of
        {ok, V} ->
            '__bp_print'([<<"Ok ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>]);
        {error, F} ->
            '__bp_print'([<<"Error ", ('__bp_text'(erlang:element(3, F)))/binary, ": ", ('__bp_text'(erlang:element(2, F)))/binary>>])
    end.

main() ->
    show(std@failure:attempt(fun() ->
        viaArm(0)
    end)),
    show(std@failure:attempt(fun() ->
        viaArm(1)
    end)),
    show(std@failure:attempt(fun() ->
        viaIfBranch(true)
    end)),
    show(std@failure:attempt(fun() ->
        viaIfBranch(false)
    end)).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/defer_panic_in_arm|*">>.

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

'__bp_priv__viaArm'(A0) -> viaArm(A0).

'__bp_priv__viaIfBranch'(A0) -> viaIfBranch(A0).

'__bp_priv__show'(A0) -> show(A0).
