-module(bp_load_cases_block_jump_label_continue_reaches_loop@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__sumSkippingRows'/2, '__bp_priv__countUntilFive'/2]).

%%% Decision 541 (2) — a labelled `continue :outer` from a nested loop's body,

%%% or from a `case` arm's block, starts the named outer loop's next round.

sumSkippingRows(Xs, Ys) ->
    S = 0,
    S@6 = (fun __BpLoop(__BpIter1, S@1) ->
        case __BpIter1 of
            [X | __BpRest1] ->
                __BpLoop(__BpRest1, try
                    S@4 = (fun __BpLoop1(__BpIter2, S@2) ->
                        case __BpIter2 of
                            [Y | __BpRest2] ->
                                __BpLoop1(__BpRest2, try
                                    case (Y =:= '__bp_int'((X + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:10:24">>)) of
                                        true ->
                                            erlang:throw({'__bp_label_continue', outer, S@2});
                                        _ -> ok
                                    end,
                                    S@3 = '__bp_int'(('__bp_int'((S@2 + '__bp_int'((X * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:11:23">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:11:19">>) + Y), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:11:28">>),
                                    S@3
                                catch
                                    throw:{'__bp_cond_continue', __BpGroup2} -> __BpGroup2
                                end);
                            _ -> S@2
                        end
                    end)(Ys, S@1),
                    S@5 = '__bp_int'((S@4 + 1000), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:13:15">>),
                    S@5
                catch
                    throw:{'__bp_cond_continue', __BpGroup1} -> __BpGroup1;
                    throw:{'__bp_label_continue', outer, __BpGroup1} -> __BpGroup1
                end);
            _ -> S@1
        end
    end)(Xs, S),
    S@6.

countUntilFive(Xs, Ys) ->
    N = 0,
    N@5 = (fun __BpLoop(__BpIter3, N@1) ->
        case __BpIter3 of
            [X | __BpRest3] ->
                __BpLoop(__BpRest3, try
                    N@4 = (fun __BpLoop1(__BpIter4, N@2) ->
                        case __BpIter4 of
                            [Y | __BpRest4] ->
                                __BpLoop1(__BpRest4, try
                                    case '__bp_add'(X, Y) of
                                        5 ->
                                            erlang:throw({'__bp_label_continue', outer, N@2});
                                        _ ->
                                            undefined
                                    end,
                                    N@3 = '__bp_int'((N@2 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:28:19">>),
                                    N@3
                                catch
                                    throw:{'__bp_cond_continue', __BpGroup4} -> __BpGroup4
                                end);
                            _ -> N@2
                        end
                    end)(Ys, N@1),
                    N@4
                catch
                    throw:{'__bp_cond_continue', __BpGroup3} -> __BpGroup3;
                    throw:{'__bp_label_continue', outer, __BpGroup3} -> __BpGroup3
                end);
            _ -> N@1
        end
    end)(Xs, N),
    N@5.

main() ->
    '__bp_print'([sumSkippingRows([1, 2, 3], [1, 2, 3])]),
    '__bp_print'([countUntilFive([1, 2, 3], [1, 2, 3])]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/block_jump_label_continue_reaches_loop|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_priv__sumSkippingRows'(A0, A1) -> sumSkippingRows(A0, A1).

'__bp_priv__countUntilFive'(A0, A1) -> countUntilFive(A0, A1).
