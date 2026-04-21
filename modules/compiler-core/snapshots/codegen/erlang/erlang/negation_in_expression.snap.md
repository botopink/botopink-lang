----- SOURCE CODE -- main.bp
```botopink
fn diff(x: i32, y: i32) -> i32 {
    return x + -y;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

diff(X, Y) ->
    (X + (-Y)).
```
