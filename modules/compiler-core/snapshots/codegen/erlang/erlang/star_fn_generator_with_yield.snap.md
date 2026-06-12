----- SOURCE CODE -- main.bp
```botopink
#[@iterator]
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
    yield 3;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% #[@future] / #[@asyncGenerator] — eager lowering
counter() ->
    [1, 2, 3].
```

----- RUN LOG -----
```logs
```
