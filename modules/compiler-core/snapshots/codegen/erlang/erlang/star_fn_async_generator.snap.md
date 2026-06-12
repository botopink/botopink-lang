----- SOURCE CODE -- main.bp
```botopink
*fn stream() -> @AsyncIterator<i32, string> {
    yield 1;
    yield 2;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% *fn (async/generator) — eager lowering
stream() ->
    [1, 2].
```

----- RUN LOG -----
```logs
```
