----- SOURCE CODE -- main.bp
```botopink
fn range(a: i32, b: i32) -> @Iterator<i32> {
    yield a;
    yield b;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__range'/2]).

%% @Iterator — eager lowering
range(A, B) ->
    [A, B].

'__bp_priv__range'(A0, A1) -> range(A0, A1).
```

----- RUN LOG -----
```logs
```
