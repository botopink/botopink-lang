----- SOURCE CODE -- main.bp
```botopink
#[@generator]
fn range(a: i32, b: i32) -> @Generator<i32> {
    yield a;
    yield b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% *fn (async/generator) — eager lowering
range(A, B) ->
    [A, B].
```

----- RUN LOG -----
```logs
```
