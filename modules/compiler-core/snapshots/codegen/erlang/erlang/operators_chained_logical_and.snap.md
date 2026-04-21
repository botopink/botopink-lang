----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

allThree(A, B, C) ->
    ((A and B) and C).
```
