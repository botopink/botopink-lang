----- SOURCE CODE -- main.bp
```botopink
*fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
    yield 3;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% *fn (async/generator) — eager lowering
counter() ->
    [1, 2, 3].
```

----- RUN LOG -----
```logs
```
