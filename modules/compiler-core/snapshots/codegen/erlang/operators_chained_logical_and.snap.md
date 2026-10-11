----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

allThree(A, B, C) ->
    ((A andalso B) andalso C).
```

----- RUN LOG -----
```logs
```
