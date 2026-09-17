----- SOURCE CODE -- main.bp
```botopink
type RiskError(level: i32)
#[@result]
fn risky() -> @Result<i32, RiskError> {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type RiskError: level

risky() ->
    {error, #{level => 5}}.

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

----- RUN LOG -----
```logs
```
