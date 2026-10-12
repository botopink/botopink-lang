----- SOURCE CODE -- main.bp
```botopink
fn stream() -> @Stream<@Result<i32, string>> {
    yield 1;
    yield 2;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__stream'/0]).

%% @Stream — eager lowering
stream() ->
    [{ok, 1}, {ok, 2}].

'__bp_priv__stream'() -> stream().
```

----- RUN LOG -----
```logs
```
