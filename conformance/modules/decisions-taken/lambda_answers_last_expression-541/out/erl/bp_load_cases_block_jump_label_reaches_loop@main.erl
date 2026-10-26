-module(bp_load_cases_block_jump_label_reaches_loop@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__firstPair'/2, '__bp_priv__sumBeforeTwo'/2]).

%%% Decision 541 (2) — a labelled `break :outer` in a `case` arm's block, or

%%% in a plain block, reaches the named outer loop: the block is no closure.

firstPair(Xs, Ys) ->
    Found = 0,
    Found@6 = try
        (fun __BpLoop(__BpIter1, Found@1) ->
            case __BpIter1 of
                [X | __BpRest1] ->
                    Found@5 = try
                        (fun __BpLoop1(__BpIter2, Found@2) ->
                            case __BpIter2 of
                                [Y | __BpRest2] ->
                                    Found@4 = case '__bp_add'(X, Y) of
                                        5 ->
                                            Found@3 = '__bp_int'(('__bp_int'((X * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:12:31">>) + Y), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:12:36">>),
                                            erlang:throw({'__bp_label_break', outer, Found@3}),
                                            Found@3;
                                        _ ->
                                            Found@2
                                    end,
                                    __BpLoop1(__BpRest2, Found@4);
                                _ -> Found@2
                            end
                        end)(Ys, Found@1)
                    catch
                        throw:{'__bp_cond_break', __BpGroup2} -> __BpGroup2
                    end,
                    __BpLoop(__BpRest1, Found@5);
                _ -> Found@1
            end
        end)(Xs, Found)
    catch
        throw:{'__bp_label_break', outer, __BpLabelG1} -> __BpLabelG1
    end,
    Found@6.

sumBeforeTwo(Xs, Ys) ->
    S = 0,
    S@5 = try
        (fun __BpLoop(__BpIter3, S@1) ->
            case __BpIter3 of
                [X | __BpRest3] ->
                    S@4 = try
                        (fun __BpLoop1(__BpIter4, S@2) ->
                            case __BpIter4 of
                                [Y | __BpRest4] ->
                                    case true of
                                        _ ->
                                            case (Y =:= 2) of
                                                true ->
                                                    erlang:throw({'__bp_label_break', outer, S@2});
                                                _ -> ok
                                            end
                                    end,
                                    S@3 = '__bp_int'((S@2 + '__bp_int'((X * Y), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:27:23">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:27:19">>),
                                    __BpLoop1(__BpRest4, S@3);
                                _ -> S@2
                            end
                        end)(Ys, S@1)
                    catch
                        throw:{'__bp_cond_break', __BpGroup4} -> __BpGroup4
                    end,
                    __BpLoop(__BpRest3, S@4);
                _ -> S@1
            end
        end)(Xs, S)
    catch
        throw:{'__bp_label_break', outer, __BpLabelG2} -> __BpLabelG2
    end,
    S@5.

main() ->
    '__bp_print'([firstPair([1, 2, 3], [1, 2, 3])]),
    '__bp_print'([sumBeforeTwo([1, 2], [1, 2, 3])]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/block_jump_label_reaches_loop|*">>.

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

'__bp_priv__firstPair'(A0, A1) -> firstPair(A0, A1).

'__bp_priv__sumBeforeTwo'(A0, A1) -> sumBeforeTwo(A0, A1).
