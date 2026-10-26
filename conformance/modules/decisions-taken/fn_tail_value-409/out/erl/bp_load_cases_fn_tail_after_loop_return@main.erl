-module(bp_load_cases_fn_tail_after_loop_return@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__firstNegative'/1, '__bp_priv__describe'/1, '__bp_priv__countdown'/1]).

%%% Decision 409 — an early `return` from inside a loop or a `case` arm leaves

%%% the function; the body's last expression written without `;` is its value

%%% on every other path: after a `for`, a statement `case` and a `while`.

firstNegative(Xs) ->
    try
        lists:foreach(fun(X) ->
            case (X < 0) of
                true ->
                    erlang:throw({'__bp_try', X});
                _ -> ok
            end
        end, Xs),
        0
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

describe(N) ->
    try
        case N of
            0 ->
                erlang:throw({'__bp_try', <<"zero">>});
            _ ->
                undefined
        end,
        <<"n=", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

countdown(N) ->
    try
        I = N,
        I@3 = (fun __BpLoop(I@1) ->
            case (I@1 > 0) of
                true ->
                    case (I@1 =:= 2) of
                        true ->
                            erlang:throw({'__bp_try', <<"stopped at 2">>});
                        _ -> ok
                    end,
                    I@2 = '__bp_int'((I@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:28:15">>),
                    __BpLoop(I@2);
                _ -> I@1
            end
        end)(I),
        <<"reached ", ('__bp_text'(erlang:integer_to_binary(I@3)))/binary>>
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

main() ->
    '__bp_print'([firstNegative([3, (-4), (-5)])]),
    '__bp_print'([firstNegative([1, 2])]),
    '__bp_print'([describe(0)]),
    '__bp_print'([describe(7)]),
    '__bp_print'([countdown(5)]),
    '__bp_print'([countdown(1)]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/fn_tail_after_loop_return|*">>.

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
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__firstNegative'(A0) -> firstNegative(A0).

'__bp_priv__describe'(A0) -> describe(A0).

'__bp_priv__countdown'(A0) -> countdown(A0).
