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

%% @Iterator — eager lowering
range(A, B) ->
    [A, B].
```

----- RUN LOG -----
```logs
```
