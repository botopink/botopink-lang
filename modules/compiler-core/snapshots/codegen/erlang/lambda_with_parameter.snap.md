----- SOURCE CODE -- main.bp
```botopink
fn apply(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(10);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

apply(F) ->
    F(10).
```

----- RUN LOG -----
```logs
```
