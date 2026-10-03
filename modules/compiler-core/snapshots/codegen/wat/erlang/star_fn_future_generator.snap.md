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

%% @Stream — eager lowering
stream() ->
    [{ok, 1}, {ok, 2}].
```

----- RUN LOG -----
```logs
```
