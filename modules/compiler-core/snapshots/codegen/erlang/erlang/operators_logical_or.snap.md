----- SOURCE CODE -- main.bp
```botopink
fn either(a: bool, b: bool) -> bool {
    return a || b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

either(A, B) ->
    (A or B).
```
