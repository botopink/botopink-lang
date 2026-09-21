----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn make() -> Point {
    return Point(x: 3, y: 4);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Point: x, y

make() ->
    {main__t__point, 3, 4}.
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
