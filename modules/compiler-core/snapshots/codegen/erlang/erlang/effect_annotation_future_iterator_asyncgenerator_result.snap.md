----- SOURCE CODE -- main.bp
```botopink
#[@future]
fn fetch(x: i32) -> @Future<i32> {
    return x;
}
#[@iterator]
fn counter() -> @Iterator<i32> {
    yield 1;
    yield 2;
}
#[@asyncGenerator]
fn stream() -> @AsyncIterator<i32, string> {
    yield 1;
}
#[@result]
fn parse(n: i32) -> @Result<i32, string> {
    if (n < 0) { throw "negative"; };
    return n;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% *fn (async/generator) — eager lowering
fetch(X) ->
    X.

%% *fn (async/generator) — eager lowering
counter() ->
    [1, 2].

%% *fn (async/generator) — eager lowering
stream() ->
    [1].

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
