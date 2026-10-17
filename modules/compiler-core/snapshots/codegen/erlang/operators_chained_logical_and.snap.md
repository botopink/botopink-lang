----- SOURCE CODE -- main.bp
```botopink
fn allThree(a: bool, b: bool, c: bool) -> bool {
    return a && b && c;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__allThree'/3]).

allThree(A, B, C) ->
    ((A andalso B) andalso C).

'__bp_priv__allThree'(A0, A1, A2) -> allThree(A0, A1, A2).
```

----- RUN LOG -----
```logs
```
