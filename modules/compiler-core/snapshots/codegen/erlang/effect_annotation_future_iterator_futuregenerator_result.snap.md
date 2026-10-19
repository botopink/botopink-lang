----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> Async<i32> {
    return x;
}
fn counter() -> Iter<i32> {
    yield 1;
    yield 2;
}
fn stream() -> AsyncIter<Result<i32, string>> {
    yield 1;
}
fn parse(n: i32) -> Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__fetch'/1, '__bp_priv__counter'/0, '__bp_priv__stream'/0, '__bp_priv__parse'/1]).

%% @Async — eager lowering
fetch(X) ->
    X.

%% @Iter — lazy lowering
counter() ->
    '__bp_gen_new'(fun() ->
        __BpGen1 = erlang:make_ref(),
        try
            '__bp_gen_yield'(1),
            '__bp_gen_yield'(2)
        catch
            throw:{'__bp_gen_end', __BpGenK1, _, __BpGenV1} when (__BpGenK1 =:= __BpGen1) -> '__bp_gen_yield'(__BpGenV1), ok
        end
    end).

%% @AsyncIter — lazy lowering
stream() ->
    '__bp_gen_new'(fun() ->
        __BpGen2 = erlang:make_ref(),
        try
            '__bp_gen_yield'({ok, 1})
        catch
            throw:{'__bp_gen_end', __BpGenK2, _, __BpGenV2} when (__BpGenK2 =:= __BpGen2) -> '__bp_gen_yield'(__BpGenV2), ok
        end
    end).

parse(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, N}
    end.

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

'__bp_priv__fetch'(A0) -> fetch(A0).

'__bp_priv__counter'() -> counter().

'__bp_priv__stream'() -> stream().

'__bp_priv__parse'(A0) -> parse(A0).
```

----- RUN LOG -----
```logs
```
