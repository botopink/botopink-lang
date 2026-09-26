----- SOURCE CODE -- main.bp
```botopink
pub fn loadOne(x: i32) -> @Task<i32> {
    return x;
}
pub fn count() -> @Iterator<i32> {
    yield 1;
}
pub fn pulses() -> @Stream<@Result<i32, string>> {
    yield 1;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export([loadOne/1, count/0, pulses/0]).

%% @Task — eager lowering
loadOne(X) ->
    X.

%% @Iterator — eager lowering
count() ->
    [1].

%% @Stream — eager lowering
pulses() ->
    [{ok, 1}].
```

----- RUN LOG -----
```logs
```
