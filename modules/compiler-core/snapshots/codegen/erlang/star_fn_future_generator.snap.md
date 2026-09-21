----- SOURCE CODE -- main.bp
```botopink
#[@futureGenerator]
fn stream() -> @FutureGenerator<i32, string> {
    yield 1;
    yield 2;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% #[@future] / #[@futureGenerator] — eager lowering
stream() ->
    [1, 2].
```

----- RUN LOG -----
```logs
```
