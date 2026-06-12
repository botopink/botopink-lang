----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
*fn risky() -> @Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record RiskError: level

risky() ->
    {error, #{level => 5}}.

safe() ->
    case risky() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end.
```

----- RUN LOG -----
```logs
```
