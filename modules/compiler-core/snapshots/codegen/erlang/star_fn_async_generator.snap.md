----- SOURCE CODE -- main.bp
```botopink
#[@asyncGenerator]
fn stream() -> @AsyncIterator<i32, string> {
    yield 1;
    yield 2;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% #[@future] / #[@asyncGenerator] — eager lowering
stream() ->
    [1, 2].
```

----- RUN LOG -----
```logs
```
