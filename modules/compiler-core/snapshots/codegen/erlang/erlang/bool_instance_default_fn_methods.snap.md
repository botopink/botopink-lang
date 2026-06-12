----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print(true.negate());
    @print(false.nor(false));
    @print(true.nand(true));
    @print(true.exclusiveOr(false));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Bool

main() ->
    io:format("~p~n", [(not true)]),
    io:format("~p~n", [nor(false, false)]),
    io:format("~p~n", [nand(true, true)]),
    io:format("~p~n", [exclusiveOr(true, false)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
