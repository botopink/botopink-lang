----- SOURCE CODE -- main.bp
```botopink
#[@future]
pub fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
#[@resultGenerator]
pub fn count() -> @ResultGenerator<i32> {
    yield 1;
}
#[@futureGenerator]
pub fn pulses() -> @FutureGenerator<i32, string> {
    yield 1;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([loadOne/1, count/0, pulses/0]).

%% #[@future] / #[@futureGenerator] — eager lowering
loadOne(X) ->
    X.

%% #[@future] / #[@futureGenerator] — eager lowering
count() ->
    [1].

%% #[@future] / #[@futureGenerator] — eager lowering
pulses() ->
    [1].
```

----- RUN LOG -----
```logs
```
