----- SOURCE CODE -- main.bp
```botopink
#[@resultGenerator]
fn counter() -> @ResultGenerator<i32> {
    yield 1;
    yield 2;
    yield 3;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% #[@future] / #[@futureGenerator] — eager lowering
counter() ->
    [1, 2, 3].
```

----- RUN LOG -----
```logs
```
