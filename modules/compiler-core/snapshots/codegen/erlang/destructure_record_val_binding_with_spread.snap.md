----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32, z: i32)
fn describe(p: Point) -> i32 {
    val { x, .. } = p;
    return x;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Point: x, y, z

describe(P) ->
    {main__t__point, X, _, _} = P,
    X.
```

----- ERLANG -- main__t__point.erl
```erlang
-module(main__t__point).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V);
'__bp_get'(V, z) -> element(4, V).

'__bp_format'(V) -> {record, "Point", [{"x", element(2, V)}, {"y", element(3, V)}, {"z", element(4, V)}]}.
```

----- RUN LOG -----
```logs
```
