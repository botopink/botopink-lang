----- SOURCE CODE -- main.bp
```botopink
#[@future]
pub fn loadOne(x: i32) -> @Future<i32> {
    return x;
}
#[@iterator]
pub fn count() -> @Iterator<i32> {
    yield 1;
}
#[@asyncGenerator]
pub fn pulses() -> @AsyncIterator<i32, string> {
    yield 1;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export([loadOne/1, count/0, pulses/0]).

%% #[@future] / #[@asyncGenerator] — eager lowering
loadOne(X) ->
    X.

%% #[@future] / #[@asyncGenerator] — eager lowering
count() ->
    [1].

%% #[@future] / #[@asyncGenerator] — eager lowering
pulses() ->
    [1].
```

----- RUN LOG -----
```logs
```
