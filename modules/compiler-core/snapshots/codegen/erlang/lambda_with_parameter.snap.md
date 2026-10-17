----- SOURCE CODE -- main.bp
```botopink
fn apply(f: fn(x: i32) -> i32) -> i32 {
    return f(10);
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__apply'/1]).

apply(F) ->
    F(10).

'__bp_priv__apply'(A0) -> apply(A0).
```

----- RUN LOG -----
```logs
```
