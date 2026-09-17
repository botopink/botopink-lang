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
    #{x := X} = P,
    X.
```

----- RUN LOG -----
```logs
```
