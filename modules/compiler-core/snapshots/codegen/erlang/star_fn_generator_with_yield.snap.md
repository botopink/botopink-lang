----- SOURCE CODE -- main.bp
```botopink
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
    yield 3;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__counter'/0]).

%% @Iterator — eager lowering
counter() ->
    [1, 2, 3].

'__bp_priv__counter'() -> counter().
```

----- RUN LOG -----
```logs
```
