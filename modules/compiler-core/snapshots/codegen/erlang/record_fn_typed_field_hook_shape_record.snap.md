----- SOURCE CODE -- main.bp
```botopink
type State<T>(value: T, set: fn(next: T))
fn make() -> State<i32> { return State(value: 0, set: { n -> }); }
fn apply(s: State<i32>) -> i32 { s.set(s.value); return s.value; }
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__make'/0, '__bp_priv__apply'/1]).

%% type State: value, set

make() ->
    {test@main@@State, 0, fun(N) ->
        undefined
    end}.

apply(S) ->
    (erlang:element(3, S))(erlang:element(2, S)),
    erlang:element(2, S).

'__bp_priv__make'() -> make().

'__bp_priv__apply'(A0) -> apply(A0).
```

----- ERLANG -- test@main@@State.erl
```erlang
-module(test@main@@State).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, value) -> erlang:element(2, V);
'__bp_get'(V, set) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "State", [{"value", erlang:element(2, V)}, {"set", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
