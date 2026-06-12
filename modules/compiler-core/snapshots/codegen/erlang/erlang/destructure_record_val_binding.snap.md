----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn describe(p: Point) -> i32 {
    val { x, y } = p;
    @print(x, y);
    return x;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Point: x, y

describe(P) ->
    {X, Y} = P,
    io:format("~p~n", [X, Y]),
    X.
```

----- RUN LOG -----
```logs
```
