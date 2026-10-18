----- SOURCE CODE -- main.bp
```botopink
type RiskError(level: i32)
fn risky() -> Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__risky'/0, '__bp_priv__safe'/0]).

%% type RiskError: level

risky() ->
    {error, {test@main@@RiskError, 5}}.

safe() ->
    case risky() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end.

'__bp_priv__risky'() -> risky().

'__bp_priv__safe'() -> safe().
```

----- ERLANG -- test@main@@RiskError.erl
```erlang
-module(test@main@@RiskError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, level) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "RiskError", [{"level", erlang:element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
