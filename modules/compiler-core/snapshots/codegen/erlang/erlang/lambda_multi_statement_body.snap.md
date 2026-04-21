----- SOURCE CODE -- main.bp
```botopink
fn process(f: syntax fn(x: i32) -> i32) -> i32 {
    return f(5);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

process(F) ->
    f(5).
```
