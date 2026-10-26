-module(bp_load_cases_for_loop_sources@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__tens'/0, '__bp_priv__countdown'/1, '__bp_priv__items'/1, '__bp_priv__sum'/1, '__bp_priv__firstOver'/2, '__bp_priv__run'/0]).

%% type YieldStep
%%   Yield(value)
%%   Done

%%% Decision 956 — the collection loop is 105's: the sources after `for`, the

%%% body a block opening with one parameter per source. One source is written

%%% bare or in parentheses, one loop either way; `for await` walks an

%%% `AsyncIter`; a source may be `try r`, the `Ok` value walked and an `Error`

%%% propagated. Several sources, in parentheses, walk together, one item of each

%%% per round, ending with the shortest; an open range `0...` never ends the

%%% loop and serves as the index. The body is a loop body: `break`, `continue`,

%%% a label after the keyword, a `return` leaving the enclosing function.

%% @Iter — lazy lowering
tens() ->
    '__bp_gen_new'(fun() ->
        __BpGen1 = erlang:make_ref(),
        try
            '__bp_gen_yield'(10),
            '__bp_gen_yield'(20),
            '__bp_gen_yield'(30)
        catch
            throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> '__bp_gen_yield'(__BpGenV1), ok
        end
    end).

%% @AsyncIter — lazy lowering
countdown(N) ->
    '__bp_gen_new'(fun() ->
        __BpGen2 = erlang:make_ref(),
        try
            I = N,
            I@3 = (fun __BpLoop(I@1) ->
                case (I@1 > 0) of
                    true ->
                        '__bp_gen_yield'(I@1),
                        I@2 = '__bp_int'((I@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:22:15">>),
                        __BpLoop(I@2);
                    _ -> I@1
                end
            end)(I)
        catch
            throw:{'__bp_gen_end', __BpGenK2, _, __BpGenV2} when (__BpGenK2 =:= __BpGen2) -> '__bp_gen_yield'(__BpGenV2), ok
        end
    end).

%% type Grid: cells

items(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, [N, '__bp_int'((N + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:36:18">>)]}
    end.

sum(N) ->
    try
        Total = 0,
        Total@3 = lists:foldl(fun(X, Total@1) ->
            Total@2 = '__bp_int'((Total@1 + X), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:42:23">>),
            Total@2
        end, Total, case items(N) of
            {ok, _TryV0} -> _TryV0;
            {error, _TryE0} -> erlang:throw({'__bp_try', {error, _TryE0}})
        end),
        {ok, Total@3}
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

% `return` from the walk of three sources leaves the function.

firstOver(Names, Limit) ->
    try
        try
            (fun __BpLoop() ->
                __for49_5_v0 = Names,
                __for49_5_v1 = tens(),
                __for49_5_s1 = '__bp_gen_new'(fun() ->
                    __BpGen4 = erlang:make_ref(),
                    try
                        try
                            (fun __BpLoop1() ->
                                '__bp_iter_foreach'(fun(__for49_5_i1) ->
                                    '__bp_gen_yield'(__for49_5_i1)
                                end, __for49_5_v1),
                                erlang:throw({'__bp_cond_break', ok}),
                                __BpLoop1()
                            end)()
                        catch
                            throw:{'__bp_cond_break', __BpGroup4} -> __BpGroup4
                        end
                    catch
                        throw:{'__bp_gen_end', __BpGenK4, _, __BpGenV4} when (__BpGenK4 =:= __BpGen4) -> '__bp_gen_yield'(__BpGenV4), ok
                    end,
                    ok
                end),
                __for49_5_c2 = 0,
                __for49_5_c2@4 = try
                    (fun __BpLoop1(__BpIter5, __for49_5_c2@1) ->
                        case __BpIter5 of
                            [Name | __BpRest5] ->
                                __for49_5_c2@3 = case begin {BpStep1, __for49_5_s1@1} = case '__bp_iter_step'(__for49_5_s1) of [BpStepHead1 | BpStepRest1] -> {{bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, BpStepHead1}, BpStepRest1}; BpStepRest1 -> {bp_load_cases_for_loop_sources@main@@YieldStep__v__done, BpStepRest1} end, BpStep1 end of
                                    {bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, Ten} ->
                                        I = __for49_5_c2@1,
                                        __for49_5_c2@2 = '__bp_int'((__for49_5_c2@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:49:26">>),
                                        case (Ten > Limit) of
                                            true ->
                                                erlang:throw({'__bp_try', <<('__bp_text'(Name))/binary, "@", ('__bp_text'(erlang:integer_to_binary(I)))/binary>>});
                                            _ -> ok
                                        end,
                                        __for49_5_c2@2;
                                    bp_load_cases_for_loop_sources@main@@YieldStep__v__done ->
                                        erlang:throw({'__bp_cond_break', __for49_5_c2@1}),
                                        __for49_5_c2@1
                                end,
                                __BpLoop1(__BpRest5, __for49_5_c2@3);
                            _ -> __for49_5_c2@1
                        end
                    end)(__for49_5_v0, __for49_5_c2)
                catch
                    throw:{'__bp_cond_break', __BpGroup5} -> __BpGroup5
                end,
                erlang:throw({'__bp_cond_break', ok}),
                __BpLoop()
            end)()
        catch
            throw:{'__bp_cond_break', __BpGroup3} -> __BpGroup3
        end,
        <<"none">>
    catch
        throw:{'__bp_try', __BpTryR} -> __BpTryR
    end.

%% @Async — eager lowering
run() ->
    '__bp_iter_foreach'(fun(X) ->
        '__bp_print'([<<"await bare ", ('__bp_text'(erlang:integer_to_binary(X)))/binary>>])
    end, countdown(2)),
    '__bp_iter_foreach'(fun(X) ->
        '__bp_print'([<<"await parenthesised ", ('__bp_text'(erlang:integer_to_binary(X)))/binary>>])
    end, countdown(1)).

main() ->
    Xs = [1, 2, 3],
    lists:foreach(fun(X) ->
        '__bp_print'([<<"bare ", ('__bp_text'(erlang:integer_to_binary(X)))/binary>>])
    end, Xs),
    lists:foreach(fun(X) ->
        '__bp_print'([<<"parenthesised ", ('__bp_text'(erlang:integer_to_binary(X)))/binary>>])
    end, Xs),
    lists:foreach(fun(I) ->
        '__bp_print'([<<"range ", ('__bp_text'(erlang:integer_to_binary(I)))/binary>>])
    end, lists:seq(1, 3)),
    '__bp_iter_foreach'(fun(T) ->
        '__bp_print'([<<"iter ", ('__bp_text'(erlang:integer_to_binary(T)))/binary>>])
    end, tens()),
    G = {bp_load_cases_for_loop_sources@main@@Grid, [4, 5]},
    Total = 0,
    Total@3 = '__bp_iter_foldl'(fun(C, Total@1) ->
        Total@2 = '__bp_int'((Total@1 + C), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:81:23">>),
        Total@2
    end, Total, bp_load_cases_for_loop_sources@main@@Grid:iter(G)),
    '__bp_print'([<<"grid ", ('__bp_text'(erlang:integer_to_binary(Total@3)))/binary>>]),
    '__bp_print'([<<"try ", ('__bp_text'(erlang:integer_to_binary((fun(__BpR) -> case __BpR of {ok, __BpV0} -> __BpV0; _ -> ((-1)) end end)(sum(1)))))/binary>>]),
    '__bp_print'([<<"try ", ('__bp_text'(erlang:integer_to_binary((fun(__BpR) -> case __BpR of {ok, __BpV1} -> __BpV1; _ -> ((-1)) end end)(sum((-1))))))/binary>>]),
    % Two sources, the shorter ending the loop.
    try
        (fun __BpLoop() ->
            __for88_5_v0 = [<<"a">>, <<"b">>, <<"c">>, <<"d">>],
            __for88_5_v1 = tens(),
            __for88_5_s1 = '__bp_gen_new'(fun() ->
                __BpGen5 = erlang:make_ref(),
                try
                    try
                        (fun __BpLoop1() ->
                            '__bp_iter_foreach'(fun(__for88_5_i1) ->
                                '__bp_gen_yield'(__for88_5_i1)
                            end, __for88_5_v1),
                            erlang:throw({'__bp_cond_break', ok}),
                            __BpLoop1()
                        end)()
                    catch
                        throw:{'__bp_cond_break', __BpGroup7} -> __BpGroup7
                    end
                catch
                    throw:{'__bp_gen_end', __BpGenK5, _, __BpGenV5} when (__BpGenK5 =:= __BpGen5) -> '__bp_gen_yield'(__BpGenV5), ok
                end,
                ok
            end),
            try
                lists:foreach(fun(S) ->
                    case begin {BpStep2, __for88_5_s1@1} = case '__bp_iter_step'(__for88_5_s1) of [BpStepHead2 | BpStepRest2] -> {{bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, BpStepHead2}, BpStepRest2}; BpStepRest2 -> {bp_load_cases_for_loop_sources@main@@YieldStep__v__done, BpStepRest2} end, BpStep2 end of
                        {bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, T@1} ->
                            '__bp_print'(['__bp_add'(S, erlang:integer_to_binary(T@1))]);
                        bp_load_cases_for_loop_sources@main@@YieldStep__v__done ->
                            erlang:throw('__bp_break')
                    end
                end, __for88_5_v0)
            catch
                throw:'__bp_break' -> ok
            end,
            erlang:throw({'__bp_cond_break', ok}),
            __BpLoop()
        end)()
    catch
        throw:{'__bp_cond_break', __BpGroup6} -> __BpGroup6
    end,
    try
        (fun __BpLoop() ->
            __for91_5_v0 = tens(),
            __for91_5_v1 = [<<"p">>, <<"q">>],
            __for91_5_s1 = '__bp_gen_new'(fun() ->
                __BpGen6 = erlang:make_ref(),
                try
                    try
                        (fun __BpLoop1() ->
                            lists:foreach(fun(__for91_5_i1) ->
                                '__bp_gen_yield'(__for91_5_i1)
                            end, __for91_5_v1),
                            erlang:throw({'__bp_cond_break', ok}),
                            __BpLoop1()
                        end)()
                    catch
                        throw:{'__bp_cond_break', __BpGroup9} -> __BpGroup9
                    end
                catch
                    throw:{'__bp_gen_end', __BpGenK6, _, __BpGenV6} when (__BpGenK6 =:= __BpGen6) -> '__bp_gen_yield'(__BpGenV6), ok
                end,
                ok
            end),
            try
                '__bp_iter_foreach'(fun(T) ->
                    case begin {BpStep3, __for91_5_s1@1} = case '__bp_iter_step'(__for91_5_s1) of [BpStepHead3 | BpStepRest3] -> {{bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, BpStepHead3}, BpStepRest3}; BpStepRest3 -> {bp_load_cases_for_loop_sources@main@@YieldStep__v__done, BpStepRest3} end, BpStep3 end of
                        {bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, S@1} ->
                            '__bp_print'(['__bp_add'(S@1, erlang:integer_to_binary(T))]);
                        bp_load_cases_for_loop_sources@main@@YieldStep__v__done ->
                            erlang:throw('__bp_break')
                    end
                end, __for91_5_v0)
            catch
                throw:'__bp_break' -> ok
            end,
            erlang:throw({'__bp_cond_break', ok}),
            __BpLoop()
        end)()
    catch
        throw:{'__bp_cond_break', __BpGroup8} -> __BpGroup8
    end,
    try
        (fun __BpLoop() ->
            __for94_5_v0 = Xs,
            __for94_5_c1 = 5,
            __for94_5_e1 = 7,
            __for94_5_c1@3 = try
                (fun __BpLoop1(__BpIter11, __for94_5_c1@1) ->
                    case __BpIter11 of
                        [X@1 | __BpRest11] ->
                            case (__for94_5_c1@1 >= __for94_5_e1) of
                                true ->
                                    erlang:throw({'__bp_cond_break', __for94_5_c1@1});
                                _ -> ok
                            end,
                            R = __for94_5_c1@1,
                            __for94_5_c1@2 = '__bp_int'((__for94_5_c1@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:94:15">>),
                            '__bp_print'([<<"range pair ", ('__bp_text'(erlang:integer_to_binary(X@1)))/binary, " ", ('__bp_text'(erlang:integer_to_binary(R)))/binary>>]),
                            __BpLoop1(__BpRest11, __for94_5_c1@2);
                        _ -> __for94_5_c1@1
                    end
                end)(__for94_5_v0, __for94_5_c1)
            catch
                throw:{'__bp_cond_break', __BpGroup11} -> __BpGroup11
            end,
            erlang:throw({'__bp_cond_break', ok}),
            __BpLoop()
        end)()
    catch
        throw:{'__bp_cond_break', __BpGroup10} -> __BpGroup10
    end,
    % Three sources and the open range as the index.
    try
        (fun __BpLoop() ->
            __for98_5_v0 = [<<"x">>, <<"y">>, <<"z">>],
            __for98_5_v1 = tens(),
            __for98_5_s1 = '__bp_gen_new'(fun() ->
                __BpGen7 = erlang:make_ref(),
                try
                    try
                        (fun __BpLoop1() ->
                            '__bp_iter_foreach'(fun(__for98_5_i1) ->
                                '__bp_gen_yield'(__for98_5_i1)
                            end, __for98_5_v1),
                            erlang:throw({'__bp_cond_break', ok}),
                            __BpLoop1()
                        end)()
                    catch
                        throw:{'__bp_cond_break', __BpGroup13} -> __BpGroup13
                    end
                catch
                    throw:{'__bp_gen_end', __BpGenK7, _, __BpGenV7} when (__BpGenK7 =:= __BpGen7) -> '__bp_gen_yield'(__BpGenV7), ok
                end,
                ok
            end),
            __for98_5_c2 = 0,
            __for98_5_c2@4 = try
                (fun __BpLoop1(__BpIter14, __for98_5_c2@1) ->
                    case __BpIter14 of
                        [S@2 | __BpRest14] ->
                            __for98_5_c2@3 = case begin {BpStep4, __for98_5_s1@1} = case '__bp_iter_step'(__for98_5_s1) of [BpStepHead4 | BpStepRest4] -> {{bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, BpStepHead4}, BpStepRest4}; BpStepRest4 -> {bp_load_cases_for_loop_sources@main@@YieldStep__v__done, BpStepRest4} end, BpStep4 end of
                                {bp_load_cases_for_loop_sources@main@@YieldStep__v__yield, T@2} ->
                                    I@1 = __for98_5_c2@1,
                                    __for98_5_c2@2 = '__bp_int'((__for98_5_c2@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:98:36">>),
                                    '__bp_print'([<<('__bp_text'(erlang:integer_to_binary(I@1)))/binary, ": ", ('__bp_text'(S@2))/binary, " ", ('__bp_text'(erlang:integer_to_binary(T@2)))/binary>>]),
                                    __for98_5_c2@2;
                                bp_load_cases_for_loop_sources@main@@YieldStep__v__done ->
                                    erlang:throw({'__bp_cond_break', __for98_5_c2@1}),
                                    __for98_5_c2@1
                            end,
                            __BpLoop1(__BpRest14, __for98_5_c2@3);
                        _ -> __for98_5_c2@1
                    end
                end)(__for98_5_v0, __for98_5_c2)
            catch
                throw:{'__bp_cond_break', __BpGroup14} -> __BpGroup14
            end,
            erlang:throw({'__bp_cond_break', ok}),
            __BpLoop()
        end)()
    catch
        throw:{'__bp_cond_break', __BpGroup12} -> __BpGroup12
    end,
    Total@8 = try
        (fun __BpLoop(Total@4) ->
            __for101_5_c0 = 0,
            __for101_5_v1 = bp_load_cases_for_loop_sources@main@@Grid:iter(G),
            {__for101_5_c0@3, Total@7} = '__bp_iter_foldl'(fun(Item, {__for101_5_c0@1, Total@5}) ->
                I@2 = __for101_5_c0@1,
                __for101_5_c0@2 = '__bp_int'((__for101_5_c0@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:101:11">>),
                Total@6 = '__bp_int'((Total@5 + '__bp_int'((I@2 * Item), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:102:27">>)), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:102:23">>),
                {__for101_5_c0@2, Total@6}
            end, {__for101_5_c0, Total@4}, __for101_5_v1),
            erlang:throw({'__bp_cond_break', Total@7}),
            __BpLoop(Total@7)
        end)(Total@3)
    catch
        throw:{'__bp_cond_break', __BpGroup15} -> __BpGroup15
    end,
    '__bp_print'([<<"indexed ", ('__bp_text'(erlang:integer_to_binary(Total@8)))/binary>>]),
    % The body is a loop body.
    try
        (fun __BpLoop() ->
            __for107_5_v0 = [<<"m">>, <<"n">>, <<"o">>, <<"p">>],
            __for107_5_c1 = 0,
            __for107_5_c1@3 = try
                try
                    (fun __BpLoop1(__BpIter17, __for107_5_c1@1) ->
                        case __BpIter17 of
                            [S@3 | __BpRest17] ->
                                __BpLoop1(__BpRest17, try
                                    I@3 = __for107_5_c1@1,
                                    __for107_5_c1@2 = '__bp_int'((__for107_5_c1@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:107:40">>),
                                    case (S@3 =:= <<"n">>) of
                                        true ->
                                            erlang:throw({'__bp_label_continue', outer, __for107_5_c1@2});
                                        _ -> ok
                                    end,
                                    case (S@3 =:= <<"p">>) of
                                        true ->
                                            erlang:throw({'__bp_label_break', outer, __for107_5_c1@2});
                                        _ -> ok
                                    end,
                                    '__bp_print'([<<"body ", ('__bp_text'(S@3))/binary, ('__bp_text'(erlang:integer_to_binary(I@3)))/binary>>]),
                                    __for107_5_c1@2
                                catch
                                    throw:{'__bp_cond_continue', __BpGroup17} -> __BpGroup17;
                                    throw:{'__bp_label_continue', outer, __BpGroup17} -> __BpGroup17
                                end);
                            _ -> __for107_5_c1@1
                        end
                    end)(__for107_5_v0, __for107_5_c1)
                catch
                    throw:{'__bp_cond_break', __BpGroup17} -> __BpGroup17
                end
            catch
                throw:{'__bp_label_break', outer, __BpLabelG1} -> __BpLabelG1
            end,
            erlang:throw({'__bp_cond_break', ok}),
            __BpLoop()
        end)()
    catch
        throw:{'__bp_cond_break', __BpGroup16} -> __BpGroup16
    end,
    try
        (fun __BpLoop() ->
            __for112_5_c0 = 0,
            __for112_5_c0@3 = try
                (fun __BpLoop1(__for112_5_c0@1) ->
                    I@4 = __for112_5_c0@1,
                    __for112_5_c0@2 = '__bp_int'((__for112_5_c0@1 + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:112:10">>),
                    case (I@4 =:= 2) of
                        true ->
                            erlang:throw({'__bp_cond_break', __for112_5_c0@2});
                        _ -> ok
                    end,
                    '__bp_print'([<<"open ", ('__bp_text'(erlang:integer_to_binary(I@4)))/binary>>]),
                    __BpLoop1(__for112_5_c0@2)
                end)(__for112_5_c0)
            catch
                throw:{'__bp_cond_break', __BpGroup19} -> __BpGroup19
            end,
            erlang:throw({'__bp_cond_break', ok}),
            __BpLoop()
        end)()
    catch
        throw:{'__bp_cond_break', __BpGroup18} -> __BpGroup18
    end,
    '__bp_print'([firstOver([<<"u">>, <<"v">>, <<"w">>], 15)]),
    '__bp_print'([firstOver([<<"u">>], 15)]),
    run().

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/for_loop_sources|*">>.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

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

'__bp_gen_new'(__BpA0) ->
    Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
GenNew = fun(GBody) ->
    GCreator = erlang:self(),
    {'__bp_gen', erlang:spawn(fun() ->
        GMon = erlang:monitor(process, GCreator),
        erlang:put('__bp_gen_mon', GMon),
        receive
            {'DOWN', GMon, process, _, _} -> ok;
            {'__bp_gen', GCmd, GFrom, GM, GD} ->
                Load(GD),
                erlang:put('__bp_gen_self', {GFrom, GM}),
                case GCmd of
                    close -> ok;
                    next ->
                        try GBody() catch
                            throw:'__bp_gen_closed' -> ok;
                            GC:GR:GS ->
                                case erlang:erase('__bp_gen_self') of
                                    {GF0, GM0} -> erlang:send(GF0, {GM0, raise, GC, GR, GS, Dict()});
                                    undefined -> ok
                                end,
                                erlang:exit(normal)
                        end
                end,
                case erlang:erase('__bp_gen_self') of
                    {GF, GM1} -> erlang:send(GF, {GM1, done, Dict()});
                    undefined -> ok
                end
        end
    end)}
end,
GenNew(__BpA0).

'__bp_gen_yield'(__BpA0) ->
    Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
Yield = fun(YV) ->
    {YFrom, YM} = erlang:erase('__bp_gen_self'),
    erlang:send(YFrom, {YM, item, YV, Dict()}),
    YMon = erlang:get('__bp_gen_mon'),
    receive
        {'DOWN', YMon, process, _, _} -> erlang:throw('__bp_gen_closed');
        {'__bp_gen', YCmd, YFrom2, YM2, YD} ->
            Load(YD),
            erlang:put('__bp_gen_self', {YFrom2, YM2}),
            case YCmd of next -> undefined; close -> erlang:throw('__bp_gen_closed') end
    end
end,
Yield(__BpA0).

'__bp_iter_step'(__BpA0) ->
    case __BpA0 of
{'__bp_gen', P} = G ->
Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
Call = fun(CPid, CCmd) ->
    CM = erlang:monitor(process, CPid),
    erlang:send(CPid, {'__bp_gen', CCmd, erlang:self(), CM, Dict()}),
    receive
        {CM, item, CV, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [CV];
        {CM, done, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [];
        {CM, raise, CC, CR, CS, CD} -> erlang:demonitor(CM, [flush]), Load(CD), erlang:raise(CC, CR, CS);
        {'DOWN', CM, process, _, _} -> []
    end
end,
case Call(P, next) of [V] -> [V | G]; [] -> [] end;
L -> L
end.

'__bp_iter_foreach'(__BpA0, __BpA1) ->
    case __BpA1 of
{'__bp_gen', P} ->
Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
Call = fun(CPid, CCmd) ->
    CM = erlang:monitor(process, CPid),
    erlang:send(CPid, {'__bp_gen', CCmd, erlang:self(), CM, Dict()}),
    receive
        {CM, item, CV, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [CV];
        {CM, done, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [];
        {CM, raise, CC, CR, CS, CD} -> erlang:demonitor(CM, [flush]), Load(CD), erlang:raise(CC, CR, CS);
        {'DOWN', CM, process, _, _} -> []
    end
end,
W = fun WF() -> case Call(P, next) of [V] -> __BpA0(V), WF(); [] -> ok end end,
try W() catch WC:WR:WS -> Call(P, close), erlang:raise(WC, WR, WS) end;
L -> lists:foreach(__BpA0, L)
end.

'__bp_iter_foldl'(__BpA0, __BpA1, __BpA2) ->
    case __BpA2 of
{'__bp_gen', P} ->
Dict = fun() -> lists:filter(fun({DK, _}) -> DK =/= '__bp_gen_self' andalso DK =/= '__bp_gen_mon' end, erlang:get()) end,
Load = fun(LD) ->
    LOwn = erlang:get('__bp_gen_self'),
    LMon = erlang:get('__bp_gen_mon'),
    erlang:erase(),
    lists:foreach(fun({LK, LV}) -> erlang:put(LK, LV) end, LD),
    case LOwn of undefined -> ok; _ -> erlang:put('__bp_gen_self', LOwn) end,
    case LMon of undefined -> ok; _ -> erlang:put('__bp_gen_mon', LMon) end
end,
Call = fun(CPid, CCmd) ->
    CM = erlang:monitor(process, CPid),
    erlang:send(CPid, {'__bp_gen', CCmd, erlang:self(), CM, Dict()}),
    receive
        {CM, item, CV, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [CV];
        {CM, done, CD} -> erlang:demonitor(CM, [flush]), Load(CD), [];
        {CM, raise, CC, CR, CS, CD} -> erlang:demonitor(CM, [flush]), Load(CD), erlang:raise(CC, CR, CS);
        {'DOWN', CM, process, _, _} -> []
    end
end,
W = fun WF(A) -> case Call(P, next) of [V] -> WF(__BpA0(V, A)); [] -> A end end,
try W(__BpA1) catch WC:WR:WS -> Call(P, close), erlang:raise(WC, WR, WS) end;
L -> lists:foldl(__BpA0, __BpA1, L)
end.

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__tens'() -> tens().

'__bp_priv__countdown'(A0) -> countdown(A0).

'__bp_priv__items'(A0) -> items(A0).

'__bp_priv__sum'(A0) -> sum(A0).

'__bp_priv__firstOver'(A0, A1) -> firstOver(A0, A1).

'__bp_priv__run'() -> run().
