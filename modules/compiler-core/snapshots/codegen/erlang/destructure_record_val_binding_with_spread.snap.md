----- SOURCE CODE -- main.bp
```botopink
record Point { x: i32, y: i32, z: i32 }
fn describe(p: Point) -> i32 {
    val { x, .. } = p;
    return x;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Point: x, y, z

describe(P) ->
    #{x := X} = P,
    X.
```

----- RUN LOG -----
```logs
```
