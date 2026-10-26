-module(bp_load_cases_block_return_leaves_function@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__grade'/1, '__bp_priv__classify'/1, '__bp_priv__nested'/1, '__bp_priv__skipTwo'/0, '__bp_priv__early'/0]).

%%% Decision 525 — a `return` in a block leaves the enclosing function: a

%%% block is a scope, never a closure. From the block's own statements, from a

%%% `case` arm at its end, from a nested block and from a block inside a

%%% `for` body; a statement block's bare `return` ends a function answering

%%% nothing. `@block`'s `return` was the block's value

%%% (`modules/block_builtin_removed`).

grade(N) ->
    try
        Label = case true of
            _ ->
                case (N > 5) of
                    true ->
                        erlang:throw({'__bp_try', <<"high">>});
                    _ -> ok
                end,
                <<"low">>
        end,
        <<('__bp_text'(Label))/binary, "!">>
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

classify(N) ->
    try
        S = case true of
            _ ->
                case N of
                    0 ->
                        erlang:throw({'__bp_try', <<"zero">>});
                    _ ->
                        <<"other">>
                end
        end,
        <<('__bp_text'(S))/binary, "?">>
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

nested(N) ->
    try
        A = case true of
            _ ->
                B = case true of
                    _ ->
                        case (N < 0) of
                            true ->
                                erlang:throw({'__bp_try', 0});
                            _ -> ok
                        end,
                        '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:36:15">>)
                end,
                '__bp_int'((B * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:38:11">>)
        end,
        A
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

skipTwo() ->
    try
        Total = 0,
        Total@3 = lists:foldl(fun(X, Total@1) ->
            V = case true of
                _ ->
                    case (X =:= 2) of
                        true ->
                            erlang:throw({'__bp_try', '__bp_int'((100 + Total@1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:47:36">>)});
                        _ -> ok
                    end,
                    X
            end,
            Total@2 = '__bp_int'((Total@1 + V), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:50:23">>),
            Total@2
        end, Total, [1, 2, 3]),
        Total@3
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

early() ->
    try
        case true of
            _ ->
                '__bp_print'([<<"inside">>]),
                erlang:throw({'__bp_try', undefined})
        end,
        '__bp_print'([<<"never">>])
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

main() ->
    '__bp_print'([grade(9)]),
    '__bp_print'([grade(1)]),
    '__bp_print'([classify(0)]),
    '__bp_print'([classify(3)]),
    '__bp_print'([nested(4)]),
    '__bp_print'([nested((-1))]),
    '__bp_print'([skipTwo()]),
    early(),
    '__bp_print'([<<"after">>]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/block_return_leaves_function|*">>.

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

'__bp_priv__grade'(A0) -> grade(A0).

'__bp_priv__classify'(A0) -> classify(A0).

'__bp_priv__nested'(A0) -> nested(A0).

'__bp_priv__skipTwo'() -> skipTwo().

'__bp_priv__early'() -> early().
