----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    @print(x, y);
    return x;
}
fn main() {
    describe(Point(x: 3, y: 4));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% record Point: x, y

describe(P) ->
    {X, Y} = P,
    io:format("~p~n", [X, Y]),
    X.

main() ->
    describe(#{x => 3, y => 4}).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
