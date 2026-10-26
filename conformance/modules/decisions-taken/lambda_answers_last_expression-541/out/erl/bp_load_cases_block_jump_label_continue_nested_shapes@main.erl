-module(bp_load_cases_block_jump_label_continue_nested_shapes@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__whileUnderLabel'/1, '__bp_priv__twoLabels'/3]).

%%% Decision 541 (2) — a labelled `continue` under an in-frame `while` inside

%%% the named loop, and one inner loop continuing two enclosing labels.

whileUnderLabel(Xs) ->
    S = 0,
    S@6 = (fun __BpLoop(__BpIter1, S@1) ->
        case __BpIter1 of
            [X | __BpRest1] ->
                __BpLoop(__BpRest1, try
                    J = 0,
                    {J@3, S@4} = (fun __BpLoop1({J@1, S@2}) ->
                        case (J@1 < 3) of
                            true ->
                                __BpLoop1(try
                                    J@2 = '__bp_int'((J@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:11:19">>),
                                    case (J@2 =:= 2) of
                                        true ->
                                            erlang:throw({'__bp_label_continue', outer, S@2});
                                        _ -> ok
                                    end,
                                    S@3 = '__bp_int'(('__bp_int'((S@2 + '__bp_int'((X * 10), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:13:23">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:13:19">>) + J@2), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:13:28">>),
                                    {J@2, S@3}
                                catch
                                    throw:{'__bp_cond_continue', __BpGroup2} -> __BpGroup2
                                end);
                            _ -> {J@1, S@2}
                        end
                    end)({J, S@1}),
                    S@5 = '__bp_int'((S@4 + 1000), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:15:15">>),
                    S@5
                catch
                    throw:{'__bp_cond_continue', __BpGroup1} -> __BpGroup1;
                    throw:{'__bp_label_continue', outer, __BpGroup1} -> __BpGroup1
                end);
            _ -> S@1
        end
    end)(Xs, S),
    S@6.

twoLabels(Xs, Ys, Zs) ->
    N = 0,
    N@9 = (fun __BpLoop(__BpIter3, N@1) ->
        case __BpIter3 of
            [X | __BpRest3] ->
                __BpLoop(__BpRest3, try
                    N@7 = (fun __BpLoop1(__BpIter4, N@2) ->
                        case __BpIter4 of
                            [Y | __BpRest4] ->
                                __BpLoop1(__BpRest4, try
                                    N@5 = (fun __BpLoop2(__BpIter5, N@3) ->
                                        case __BpIter5 of
                                            [Z | __BpRest5] ->
                                                __BpLoop2(__BpRest5, try
                                                    case (Z =:= 2) of
                                                        true ->
                                                            erlang:throw({'__bp_label_continue', b, N@3});
                                                        _ -> ok
                                                    end,
                                                    case (Y =:= 2) of
                                                        true ->
                                                            erlang:throw({'__bp_label_continue', a, N@3});
                                                        _ -> ok
                                                    end,
                                                    N@4 = '__bp_int'((N@3 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:27:23">>),
                                                    N@4
                                                catch
                                                    throw:{'__bp_cond_continue', __BpGroup5} -> __BpGroup5
                                                end);
                                            _ -> N@3
                                        end
                                    end)(Zs, N@2),
                                    N@6 = '__bp_int'((N@5 + 100), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:29:19">>),
                                    N@6
                                catch
                                    throw:{'__bp_cond_continue', __BpGroup4} -> __BpGroup4;
                                    throw:{'__bp_label_continue', b, __BpGroup4} -> __BpGroup4
                                end);
                            _ -> N@2
                        end
                    end)(Ys, N@1),
                    N@8 = '__bp_int'((N@7 + 10000), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:31:15">>),
                    N@8
                catch
                    throw:{'__bp_cond_continue', __BpGroup3} -> __BpGroup3;
                    throw:{'__bp_label_continue', a, __BpGroup3} -> __BpGroup3
                end);
            _ -> N@1
        end
    end)(Xs, N),
    N@9.

main() ->
    '__bp_print'([whileUnderLabel([1, 2, 3])]),
    '__bp_print'([twoLabels([1, 2], [1, 2], [1, 2, 3])]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/block_jump_label_continue_nested_shapes|*">>.

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

'__bp_priv__whileUnderLabel'(A0) -> whileUnderLabel(A0).

'__bp_priv__twoLabels'(A0, A1, A2) -> twoLabels(A0, A1, A2).
