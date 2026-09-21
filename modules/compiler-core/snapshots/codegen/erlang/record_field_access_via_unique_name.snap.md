----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
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

%% type Point: x, y

first(P) ->
    element(2, P).

second(P) ->
    element(3, P).
```

----- ERLANG -- main__t__point.erl
```erlang
-module(main__t__point).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V).

'__bp_format'(V) -> {record, "Point", [{"x", element(2, V)}, {"y", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
