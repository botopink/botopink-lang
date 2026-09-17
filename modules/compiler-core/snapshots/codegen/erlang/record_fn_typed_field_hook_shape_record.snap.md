----- SOURCE CODE -- main.bp
```botopink
type State<T>(value: T, set: fn(next: T))
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type State: value, set

make() ->
    #{value => 0, set => fun(N) ->
        undefined
    end}.

apply(S) ->
    (maps:get(set, S))(maps:get(value, S)),
    maps:get(value, S).
```

----- RUN LOG -----
```logs
```
