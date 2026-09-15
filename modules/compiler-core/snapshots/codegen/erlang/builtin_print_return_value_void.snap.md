----- SOURCE CODE -- main.bp
```botopink
fn log(msg: string) {
    @print(msg);
}
fn main() {
    log("started");
    val x = 42;
    log("done");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

log(Msg) ->
    io:format("~p~n", [Msg]).

main() ->
    log(<<"started">>),
    X = 42,
    log(<<"done">>).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"started">>
<<"done">>
```
