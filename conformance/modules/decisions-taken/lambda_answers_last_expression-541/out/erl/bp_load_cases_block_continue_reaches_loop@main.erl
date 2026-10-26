-module(bp_load_cases_block_continue_reaches_loop@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__sumSkippingFives'/1, '__bp_priv__countOdd'/1]).

%%% Decision 541 (2) — a bare `continue` inside a block or a `case` arm of a

%%% loop's body reaches the enclosing loop: the loop's next round starts, and

%%% nothing after the `continue` in that round runs.

sumSkippingFives(Xs) ->
    S = 0,
    S@3 = (fun __BpLoop(__BpIter1, S@1) ->
        case __BpIter1 of
            [X | __BpRest1] ->
                __BpLoop(__BpRest1, try
                    case X of
                        5 ->
                            erlang:throw({'__bp_cond_continue', S@1});
                        _ ->
                            undefined
                    end,
                    S@2 = '__bp_int'((S@1 + X), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:16:15">>),
                    S@2
                catch
                    throw:{'__bp_cond_continue', __BpGroup1} -> __BpGroup1
                end);
            _ -> S@1
        end
    end)(Xs, S),
    S@3.

countOdd(Xs) ->
    N = 0,
    N@3 = (fun __BpLoop(__BpIter2, N@1) ->
        case __BpIter2 of
            [X | __BpRest2] ->
                __BpLoop(__BpRest2, try
                    case true of
                        _ ->
                            case ((X rem 2) =:= 0) of
                                true ->
                                    erlang:throw({'__bp_cond_continue', N@1});
                                _ -> ok
                            end
                    end,
                    N@2 = '__bp_int'((N@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:25:15">>),
                    N@2
                catch
                    throw:{'__bp_cond_continue', __BpGroup2} -> __BpGroup2
                end);
            _ -> N@1
        end
    end)(Xs, N),
    N@3.

main() ->
    '__bp_print'([sumSkippingFives([1, 5, 2, 5, 3])]),
    '__bp_print'([countOdd([1, 2, 3, 4, 5])]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/block_continue_reaches_loop|*">>.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).

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

'__bp_priv__sumSkippingFives'(A0) -> sumSkippingFives(A0).

'__bp_priv__countOdd'(A0) -> countOdd(A0).
