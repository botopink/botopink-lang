----- SOURCE CODE -- main.bp
```botopink
fn process(f: fn(x: i32) -> i32) -> i32 {
    return f(5);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__process'/1]).

process(F) ->
    F(5).

'__bp_priv__process'(A0) -> process(A0).
```

----- RUN LOG -----
```logs
```
