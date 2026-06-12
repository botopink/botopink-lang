----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32 }
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

%% record Point: x, y

recordEq() ->
    A = #{x => 1, y => 2},
    B = #{x => 1, y => 2},
    (A =:= B).

arrayEq() ->
    Xs = [1, 2],
    Ys = [1, 2],
    (Xs =:= Ys).
```

----- RUN LOG -----
```logs
```
