----- SOURCE CODE -- main.bp
```botopink
fn negate(x: i32) -> i32 {
    return -x;
}
fn main() {
    @print(negate(42));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

negate(X) ->
    (-X).

main() ->
    io:format("~p~n", [negate(42)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
-42
```
