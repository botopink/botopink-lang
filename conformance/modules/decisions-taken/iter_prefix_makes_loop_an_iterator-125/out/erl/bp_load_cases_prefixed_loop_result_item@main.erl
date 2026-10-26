-module(bp_load_cases_prefixed_loop_result_item@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_loaded_main'/0, '__bp_loaded_main_off'/0, '__bp_loaded_info'/0, '__bp_priv__check'/1, '__bp_priv__walk'/2]).

%%% Decisions 122 and 125 of 1.0.10-beta (front 24, § Cells "Prefixed loops";

%%% guide.md § 6.1 and § 9, row `#[@resultGenerator] loop { … }`) — the item of an

%%% `iter` loop becomes `Result<U, E>` on its own when the body has `throw` /

%%% `try`: `checked` (a `try` per item) and `limited` (a `throw`) are

%%% unannotated and passed where `Iter<Result<i32, string>>` is expected.

%%% A failing `try` or a `throw` emits `Error(e)` and ends the sequence.

check(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative ", ('__bp_text'(erlang:integer_to_binary(N)))/binary>>};
        _ ->
            {ok, N}
    end.

walk(Name, It) ->
    '__bp_iter_foreach'(fun(R) ->
        case R of
            {ok, V} ->
                '__bp_print'([<<Name/binary, " ok ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>]);
            {error, E} ->
                '__bp_print'([<<Name/binary, " error ", ('__bp_text'(E))/binary>>])
        end
    end, It),
    '__bp_print'([<<Name/binary, " done">>]).

main() ->
    Checked = '__bp_gen_new'(fun() ->
        __BpGen1 = erlang:make_ref(),
        try
            try
                (fun __BpLoop() ->
                    lists:foreach(fun(X) ->
                        '__bp_gen_yield'({ok, case check(X) of
                            {ok, _TryV0} -> _TryV0;
                            {error, _TryE0} -> erlang:throw({'__bp_gen_end', __BpGen1, ok, {error, _TryE0}})
                        end})
                    end, [1, (-2), 3]),
                    erlang:throw({'__bp_cond_break', ok}),
                    __BpLoop()
                end)()
            catch
                throw:{'__bp_cond_break', __BpGroup1} -> __BpGroup1
            end
        catch
            throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> '__bp_gen_yield'(__BpGenV1), ok
        end,
        ok
    end),
    walk(<<"try">>, Checked),
    K = 0,
    Limited = case erlang:make_ref() of
        __BpGenC2 ->
            erlang:put(__BpGenC2, K),
            '__bp_gen_new'(fun() ->
                __BpGen2 = erlang:make_ref(),
                try
                    (fun __BpLoop() ->
                        erlang:put(__BpGenC2, '__bp_int'((erlang:get(__BpGenC2) + 1), -2147483648, 2147483647, <<"integer overflow: + on i32 at src/main.bp:33:15">>)),
                        case (erlang:get(__BpGenC2) > 2) of
                            true ->
                                erlang:throw({'__bp_gen_end', __BpGen2, ok, {error, <<"stop at ", ('__bp_text'(erlang:integer_to_binary(erlang:get(__BpGenC2))))/binary>>}});
                            _ -> ok
                        end,
                        '__bp_gen_yield'({ok, erlang:get(__BpGenC2)}),
                        __BpLoop()
                    end)()
                catch
                    throw:{'__bp_gen_end', __BpGenK2, _, __BpGenV2} when (__BpGenK2 =:= __BpGen2) -> '__bp_gen_yield'(__BpGenV2), ok
                end,
                ok
            end)
    end,
    walk(<<"throw">>, Limited).

'__bp_loaded_main'() ->
    main(),
    {ok, undefined}.

'__bp_loaded_main_off'() ->
    {error, <<"">>}.

'__bp_loaded_info'() ->
    <<"cases/prefixed_loop_result_item|*">>.

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

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__check'(A0) -> check(A0).

'__bp_priv__walk'(A0, A1) -> walk(A0, A1).
