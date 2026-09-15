----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
fn first(p: Point) -> i32 {
    return p.x;
}
fn second(p: Point) -> i32 {
    return p.y;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Point: x, y

first(P) ->
    maps:get(x, P).

second(P) ->
    maps:get(y, P).
```

----- RUN LOG -----
```logs
```
