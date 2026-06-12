----- SOURCE CODE -- main.bp
```botopink
fn diff(x: i32, y: i32) -> i32 {
    return x + -y;
}
fn main() {
    @print(diff(10, 3));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

diff(X, Y) ->
    (X + (-Y)).

main() ->
    io:format("~p~n", [diff(10, 3)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
7
```
