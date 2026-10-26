-module(bp_load_cases_prefixed_loop_forms@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__line'/1, '__bp_priv__sum'/1]).

%%% Decision 125 of 1.0.10-beta (front 24, § Cells "Prefixed loops", first line;

%%% guide.md § 6.1 and § 9, row `#[@generator] loop { … }`) — `iter` in front of

%%% any of the three loops makes it an expression worth `Iter<T>`: `iter

%%% loop` and `iter while` over captured `var`s (the iterator's state) and `iter

%%% for` over a literal, each bound to a `val` — one of them annotated — and an

%%% `iter for` passed straight as an argument. A bare `break` in the prefixed

%%% loop ends the sequence.

line(It) ->
    Acc = <<"">>,
    Acc@5 = '__bp_iter_foldl'(fun(X, Acc@1) ->
        Acc@4 = case (Acc@1 =:= <<"">>) of
            true ->
                Acc@2 = erlang:integer_to_binary(X),
                Acc@2;
            _ ->
                Acc@3 = <<Acc@1/binary, " ", ('__bp_text'(erlang:integer_to_binary(X)))/binary>>,
                Acc@3
        end,
        Acc@4
    end, Acc, It),
    Acc@5.

sum(It) ->
    Total = 0,
    Total@3 = '__bp_iter_foldl'(fun(X, Total@1) ->
        Total@2 = '__bp_int'((Total@1 + X), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:22:23">>),
        Total@2
    end, Total, It),
    Total@3.

main() ->
    N = 0,
    Doubled = case erlang:make_ref() of
        __BpGenC1 ->
            erlang:put(__BpGenC1, N),
            '__bp_gen_new'(fun() ->
                __BpGen1 = erlang:make_ref(),
                try
                    try
                        (fun __BpLoop() ->
                            erlang:put(__BpGenC1, '__bp_int'((erlang:get(__BpGenC1) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:30:15">>)),
                            case (erlang:get(__BpGenC1) > 3) of
                                true ->
                                    erlang:throw({'__bp_cond_break', ok});
                                _ -> ok
                            end,
                            '__bp_gen_yield'('__bp_int'((erlang:get(__BpGenC1) * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:32:17">>)),
                            __BpLoop()
                        end)()
                    catch
                        throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
                    end
                catch
                    throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> '__bp_gen_yield'(__BpGenV1), ok
                end,
                ok
            end)
    end,
    '__bp_print'([line(Doubled)]),
    I = 3,
    Countdown = case erlang:make_ref() of
        __BpGenC2 ->
            erlang:put(__BpGenC2, I),
            '__bp_gen_new'(fun() ->
                __BpGen2 = erlang:make_ref(),
                try
                    try
                        (fun __BpLoop() ->
                            (fun __BpLoop1() ->
                                case (erlang:get(__BpGenC2) > 0) of
                                    true ->
                                        '__bp_gen_yield'(erlang:get(__BpGenC2)),
                                        erlang:put(__BpGenC2, '__bp_int'((erlang:get(__BpGenC2) - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at src/main.bp:39:15">>)),
                                        __BpLoop1();
                                    _ -> ok
                                end
                            end)(),
                            erlang:throw({'__bp_cond_break', ok}),
                            __BpLoop()
                        end)()
                    catch
                        throw:{'__bp_cond_break', __BpGroup2} -> __BpGroup2
                    end
                catch
                    throw:{'__bp_gen_end', __BpGenK2, _, __BpGenV2} when (__BpGenK2 =:= __BpGen2) -> '__bp_gen_yield'(__BpGenV2), ok
                end,
                ok
            end)
    end,
    '__bp_print'([line(Countdown)]),
    Evens = '__bp_gen_new'(fun() ->
        __BpGen3 = erlang:make_ref(),
        try
            try
                (fun __BpLoop() ->
                    lists:foreach(fun(X) ->
                        case ((X rem 2) =:= 0) of
                            true ->
                                '__bp_gen_yield'(X);
                            _ -> ok
                        end
                    end, [1, 2, 3, 4]),
                    erlang:throw({'__bp_cond_break', ok}),
                    __BpLoop()
                end)()
            catch
                throw:{'__bp_cond_break', __BpGroup4} -> __BpGroup4
            end
        catch
            throw:{'__bp_gen_end', __BpGenK3, _, __BpGenV3} when (__BpGenK3 =:= __BpGen3) -> '__bp_gen_yield'(__BpGenV3), ok
        end,
        ok
    end),
    '__bp_print'([line(Evens)]),
    '__bp_print'([sum('__bp_gen_new'(fun() ->
        __BpGen4 = erlang:make_ref(),
        try
            try
                (fun __BpLoop() ->
                    lists:foreach(fun(X) ->
                        '__bp_gen_yield'('__bp_int'((X * X), -2147483648, 2147483647, <<"integer overflow: * on i32 at src/main.bp:51:25">>))
                    end, [1, 2, 3]),
                    erlang:throw({'__bp_cond_break', ok}),
                    __BpLoop()
                end)()
            catch
                throw:{'__bp_cond_break', __BpGroup5} -> __BpGroup5
            end
        catch
            throw:{'__bp_gen_end', __BpGenK4, _, __BpGenV4} when (__BpGenK4 =:= __BpGen4) -> '__bp_gen_yield'(__BpGenV4), ok
        end,
        ok
    end))]).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/prefixed_loop_forms|*">>.

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

'__bp_priv__line'(A0) -> line(A0).

'__bp_priv__sum'(A0) -> sum(A0).
