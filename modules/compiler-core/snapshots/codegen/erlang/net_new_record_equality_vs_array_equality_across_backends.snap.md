----- SOURCE CODE -- main.bp
```botopink
type Point(x: i32, y: i32)
fn recordEq() -> bool {
    val a = Point(x: 1, y: 2);
    val b = Point(x: 1, y: 2);
    return a == b;
}
fn arrayEq() -> bool {
    val xs = [1, 2];
    val ys = [1, 2];
    return xs == ys;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Point: x, y

recordEq() ->
    A = {main__t__point, 1, 2},
    B = {main__t__point, 1, 2},
    (A =:= B).

arrayEq() ->
    Xs = [1, 2],
    Ys = [1, 2],
    (Xs =:= Ys).
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
