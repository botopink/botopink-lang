----- SOURCE CODE -- main.bp
```botopink
fn firstAndRest(xs: Array<i32>) -> #(Array<i32>, ?i32) {
    val head = xs.at(0);
    val rest = xs.slice(1, xs.length);
    return #(rest, head);
}

fn main() {
    val result = firstAndRest([1, 2, 3]);
    val head = result._1;
    @print(head.unwrapOr(-1));
    val empty = firstAndRest([]);
    @print(empty._1 == null);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

firstAndRest(Xs) ->
    Head = (fun(__L, __I) -> case ((__I >= 0) andalso (__I < length(__L))) of true -> lists:nth(__I + 1, __L); false -> undefined end end)(Xs, 0),
    Rest = lists:sublist(Xs, (1) + 1, ((length(Xs)) - (1))),
    {Rest, Head}.

main() ->
    Result = firstAndRest([1, 2, 3]),
    Head = element(2, Result),
    io:format("~p~n", [(fun(O) -> case O of undefined -> ((-1)); V -> V end end)(Head)]),
    Empty = firstAndRest([]),
    io:format("~p~n", [(element(2, Empty) =:= undefined)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
1
true
```
