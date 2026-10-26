-module(bp_load_cases_std_failure_attempt_task@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__doubled'/1, '__bp_priv__lookup'/1, '__bp_priv__show'/1, '__bp_priv__run'/0]).

%%% Decision 494 — `failure.attemptTask` is `attempt`'s `Async` form: it

%%% awaits the task its thunk answers and is `Ok` of its value, or

%%% `Error(Failure)` when the task crashed (decision 492's kinds). A task that

%%% fails with its own `E` (decision 432) did not crash: its `Result` is the

%%% value, so `attemptTask` answers `Ok(Error(e))`.

%%% 

%%% On wasm (decision 518) the thunk runs under wasm exception handling: an

%%% abort before the task's first `await` is contained.

%% import failure, Failure

%% @Async — eager lowering
doubled(N) ->
    case (N < 0) of
        true ->
            erlang:error({panic, <<"a negative input">>});
        _ -> ok
    end,
    '__bp_int'((N * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:14:14">>).

%% @Async — eager lowering
lookup(N) ->
    case (N < 0) of
        true ->
            {error, <<"not found">>};
        _ ->
            {ok, N}
    end.

show(R) ->
    case R of
        {ok, V} ->
            '__bp_print'([<<"Ok ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>]);
        {error, F} ->
            '__bp_print'([<<"Error ", ('__bp_text'(erlang:element(3, F)))/binary, ": ", ('__bp_text'(erlang:element(2, F)))/binary>>])
    end.

%% @Async — eager lowering
run() ->
    show(std@failure:attemptTask(fun() ->
        doubled(21)
    end)),
    show(std@failure:attemptTask(fun() ->
        doubled((-1))
    end)),
    Found = std@failure:attemptTask(fun() ->
        lookup((-1))
    end),
    case Found of
        {ok, Inner} ->
            case Inner of
                {ok, V} ->
                    '__bp_print'([<<"Ok Ok ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>]);
                {error, E} ->
                    '__bp_print'([<<"Ok Error ", ('__bp_text'(E))/binary>>])
            end;
        {error, F} ->
            '__bp_print'([<<"Error ", ('__bp_text'(erlang:element(3, F)))/binary, ": ", ('__bp_text'(erlang:element(2, F)))/binary>>])
    end,
    '__bp_print'([<<"after">>]).

main() ->
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/std_failure_attempt_task|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__doubled'(A0) -> doubled(A0).

'__bp_priv__lookup'(A0) -> lookup(A0).

'__bp_priv__show'(A0) -> show(A0).

'__bp_priv__run'() -> run().
