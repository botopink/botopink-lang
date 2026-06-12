----- SOURCE CODE -- main.bp
```botopink
record State<T> { value: T, set: fn(next: T) }
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record State: value, set

make() ->
    #{value => 0, set => fun(N) ->
        undefined
    end}.

apply(S) ->
    set(S, maps:get(value, S)),
    maps:get(value, S).
```

----- RUN LOG -----
```logs
```
