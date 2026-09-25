----- SOURCE CODE -- main.bp
```botopink
type State<T>(value: T, set: fn(next: T))
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type State: value, set

make() ->
    {test@main@@State, 0, fun(N) ->
        undefined
    end}.

apply(S) ->
    (element(3, S))(element(2, S)),
    element(2, S).
```

----- ERLANG -- test@main@@State.erl
```erlang
-module(test@main@@State).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> element(2, V);
'__bp_get'(V, set) -> element(3, V).

'__bp_format'(V) -> {record, "State", [{"value", element(2, V)}, {"set", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
