----- SOURCE CODE -- main.bp
```botopink
type RiskError(level: i32)
fn risky() -> @Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type RiskError: level

risky() ->
    {error, {test@main@@RiskError, 5}}.

safe() ->
    case try
        risky()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end.
```

----- ERLANG -- test@main@@RiskError.erl
```erlang
-module(test@main@@RiskError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, level) -> element(2, V).

'__bp_format'(V) -> {record, "RiskError", [{"level", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
