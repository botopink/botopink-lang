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
        element(2, Pair)
    end)(V) end end)(array_find(Pairs, fun(Pair) ->
        (element(1, Pair) =:= Key)
    end)).

main() ->
    Pairs = [{<<"a">>, 1}, {<<"b">>, 2}],
    '__bp_print'([lookup(Pairs, <<"b">>)]),
    '__bp_print'([(lookup(Pairs, <<"z">>) =:= undefined)]).

array_find(Self, Pred) ->
    (fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(lists:filter(Pred, Self), 0).

'__bp_print'(Values) ->
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
true
```
