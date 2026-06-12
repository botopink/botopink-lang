----- SOURCE CODE -- main.bp
```botopink
pub *fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
pub *fn count() -> @Iterator<i32> {
    yield 1;
}
pub *fn pulses() -> @AsyncIterator<i32, string> {
    yield 1;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([loadOne/1, count/0, pulses/0]).

%% *fn (async/generator) — eager lowering
loadOne(X) ->
    X.

%% *fn (async/generator) — eager lowering
count() ->
    [1].

%% *fn (async/generator) — eager lowering
pulses() ->
    [1].
```

----- RUN LOG -----
```logs
```
