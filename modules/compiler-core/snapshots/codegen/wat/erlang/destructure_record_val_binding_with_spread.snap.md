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
-module(test@main).

%% type Point: x, y, z

describe(P) ->
    {test@main@@Point, X, _, _} = P,
    X.
```

----- ERLANG -- test@main@@Point.erl
```erlang
-module(test@main@@Point).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, x) -> element(2, V);
'__bp_get'(V, y) -> element(3, V);
'__bp_get'(V, z) -> element(4, V).

'__bp_format'(V) -> {record, "Point", [{"x", element(2, V)}, {"y", element(3, V)}, {"z", element(4, V)}]}.
```

----- RUN LOG -----
```logs
```
