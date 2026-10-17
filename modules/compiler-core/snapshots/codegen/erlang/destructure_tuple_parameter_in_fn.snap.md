----- SOURCE CODE -- main.bp
```botopink
fn process(#(x, y): #(i32, i32)) -> i32 {
    return x;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__process'/1]).

process({X, Y}) ->
    X.

'__bp_priv__process'(A0) -> process(A0).
```

----- RUN LOG -----
```logs
```
