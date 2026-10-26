-module(bp_load_cases_std_failure_attempt_abort_kinds@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__notReady'/0, '__bp_priv__bump'/1, '__bp_priv__find'/1, '__bp_priv__show'/1]).

%%% Decision 492 — every abort the program raises itself is `panic`: a

%%% `@todo` and `x!` over `null` as a `panic` is (`modules/std_failure_attempt`).

%%% `attempt` contains each, and the program goes on, an integer overflow

%%% (decision 264) too. The cell claims the kind alone; the message of each is

%%% its abort's text.

%% import failure, Failure

notReady() ->
    erlang:error({panic, <<"not ready">>}).

bump(A) ->
    '__bp_int'((A + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:14:14">>).

find(Key) ->
    case (Key =:= <<"a">>) of
        true ->
            1;
        false ->
            undefined
    end.

show(R) ->
    case R of
        {ok, V} ->
            '__bp_print'([<<"Ok ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>]);
        {error, F} ->
            '__bp_print'([<<"Error ", ('__bp_text'(erlang:element(3, F)))/binary>>])
    end.

main() ->
    show(std@failure:attempt(fun() ->
        notReady()
    end)),
    show(std@failure:attempt(fun() ->
        case find(<<"a">>) of
            undefined ->
                erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} find(\"a\")! at src/main.bp:30:31">>});
            __bp_opt_30_40 ->
                __bp_opt_30_40
        end
    end)),
    show(std@failure:attempt(fun() ->
        case find(<<"b">>) of
            undefined ->
                erlang:error({panic, <<"value is null \x{E2}\x{80}\x{94} find(\"b\")! at src/main.bp:31:31">>});
            __bp_opt_31_40 ->
                __bp_opt_31_40
        end
    end)),
    show(std@failure:attempt(fun() ->
        bump(2147483647)
    end)),
    show(std@failure:attempt(fun() ->
        bump(1)
    end)),
    '__bp_print'([<<"after">>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/std_failure_attempt_abort_kinds|*">>.

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

'__bp_priv__notReady'() -> notReady().

'__bp_priv__bump'(A0) -> bump(A0).

'__bp_priv__find'(A0) -> find(A0).

'__bp_priv__show'(A0) -> show(A0).
