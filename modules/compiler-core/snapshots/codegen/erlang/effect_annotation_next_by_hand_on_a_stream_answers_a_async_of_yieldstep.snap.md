----- SOURCE CODE -- main.bp
```botopink
async iter fn countdown(n: i32) -> AsyncIter<i32> {
    var i = n;
    while (i > 0) {
        yield i;
        i = i - 1;
    };
}
fn stepText(s: YieldStep<i32>) -> string {
    val t = case s {
        Yield(v) -> "yield " + v.toString();
        Done -> "done";
    };
    return t;
}
async fn run() -> Async<void> {
    val s = countdown(1);
    print(stepText(await s.next()));
    print(stepText(await s.next()));
}
pub fn main() {
    run();
}

import {io.terminal.print} from "std";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['_botopink_main'/0, main/1]).
-export([main/0, '__bp_priv__countdown'/1, '__bp_priv__stepText'/1, '__bp_priv__run'/0]).

%% type YieldStep
%%   Yield(value)
%%   Done

%% @AsyncIter — lazy lowering
countdown(N) ->
    '__bp_gen_new'(fun() ->
        __BpGen1 = erlang:make_ref(),
        try
            I = N,
            I@3 = (fun __BpLoop(I@1) ->
                case (I@1 > 0) of
                    true ->
                        '__bp_gen_yield'(I@1),
                        I@2 = '__bp_int'((I@1 - 1), -2147483648, 2147483647, <<"integer overflow: - on i32 at main.bp:5:15">>),
                        __BpLoop(I@2);
                    _ -> I@1
                end
            end)(I)
        catch
            throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> '__bp_gen_yield'(__BpGenV1), ok
        end
    end).

stepText(S) ->
    T = case S of
        {test@main@@YieldStep__v__yield, V} ->
            <<"yield ", ('__bp_text'(erlang:integer_to_binary(V)))/binary>>;
        test@main@@YieldStep__v__done ->
            <<"done">>
    end,
    T.

%% @Async — eager lowering
run() ->
    S = countdown(1),
    {BpStep1, S@1} = case '__bp_iter_step'(S) of [BpStepHead1 | BpStepRest1] -> {{test@main@@YieldStep__v__yield, BpStepHead1}, BpStepRest1}; BpStepRest1 -> {test@main@@YieldStep__v__done, BpStepRest1} end,
    '__bp_print'([stepText(BpStep1)]),
    {BpStep2, S@2} = case '__bp_iter_step'(S@1) of [BpStepHead2 | BpStepRest2] -> {{test@main@@YieldStep__v__yield, BpStepHead2}, BpStepRest2}; BpStepRest2 -> {test@main@@YieldStep__v__done, BpStepRest2} end,
    '__bp_print'([stepText(BpStep2)]).

main() ->
    run().

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

'_botopink_main'() ->
    io:setopts(standard_io, [{encoding, unicode}]),
    main().

main(_Args) ->
    '_botopink_main'().

'__bp_priv__countdown'(A0) -> countdown(A0).

'__bp_priv__stepText'(A0) -> stepText(A0).

'__bp_priv__run'() -> run().
```

----- ERLANG -- test@main@@YieldStep.erl
```erlang
-module(test@main@@YieldStep).
-export(['__bp_format'/1]).

'__bp_format'({test@main@@YieldStep__v__yield, F0}) -> {variant, "YieldStep.Yield", [{"value", F0}]};
'__bp_format'(test@main@@YieldStep__v__done) -> {variant, "YieldStep.Done", []}.
```

----- RUN LOG -----
```logs
yield 1
done
```
