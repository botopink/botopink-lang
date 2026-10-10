----- SOURCE CODE -- main.bp
```botopink
fn fetch(x: i32) -> @Task<i32> {
    return x;
}
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
fn stream() -> @Stream<@Result<i32, string>> {
    yield 1;
}
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% @Task — eager lowering
fetch(X) ->
    X.

%% @Iterator — eager lowering
counter() ->
    [1, 2].

%% @Stream — eager lowering
stream() ->
    [{ok, 1}].

parse(N) ->
    case (N < 0) of
        true ->
            {error, <<"negative">>};
        _ ->
            {ok, N}
    end.
```

----- RUN LOG -----
```logs
```
