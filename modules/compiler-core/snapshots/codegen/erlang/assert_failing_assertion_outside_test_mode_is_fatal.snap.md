----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("before");
    assert 1 == 2, "boom";
    @print("after");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    io:format("~p~n", [<<"before">>]),
    true = ((1 =:= 2)),
    io:format("~p~n", [<<"after">>]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
