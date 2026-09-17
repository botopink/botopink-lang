----- SOURCE CODE -- main.bp
```botopink
fn lookup(pairs: Array<#(string, i32)>, key: string) -> ?i32 {
    return pairs.find({ pair -> pair.0 == key }).map({ pair -> pair.1 });
}

fn main() {
    val pairs = [#("a", 1), #("b", 2)];
    @print(lookup(pairs, "b"));
    @print(lookup(pairs, "z") == null);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Array

array_range(Start, Stop) ->
    case (Start >= Stop) of
        true ->
            [];
        false ->
            Head = Start,
            [Head] ++ (array_range((Start + 1), Stop))
    end.

array_repeat(Value, Times) ->
    case (Times =< 0) of
        true ->
            [];
        false ->
            Head = Value,
            [Head] ++ (array_repeat(Value, (Times - 1)))
    end.

lookup(Pairs, Key) ->
    (fun(O) -> case O of undefined -> undefined; V -> (fun(Pair) ->
        maps:get('1', Pair)
    end)(V) end end)(array_find(Pairs, fun(Pair) ->
        (maps:get('0', Pair) =:= Key)
    end)).

main() ->
    Pairs = [{<<"a">>, 1}, {<<"b">>, 2}],
    '__bp_print'([lookup(Pairs, <<"b">>)]),
    '__bp_print'([(lookup(Pairs, <<"z">>) =:= undefined)]).

array_find(Self, Pred) ->
    (fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(lists:filter(Pred, Self), 0).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
