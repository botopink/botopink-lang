----- SOURCE CODE -- main.bp
```botopink
fn both(a: bool, b: bool) -> bool {
    return a && b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

both(A, B) ->
    (A and B).
```
