----- SOURCE CODE -- main.bp
```botopink
record RiskError { level: i32 }
fn risky() -> @Result(i32, RiskError) {
    throw RiskError(level: 5);
}
fn safe() -> i32 {
    return risky() catch -1;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(RiskError, {level}).

risky() ->
    erlang:throw(RiskError(5)).

safe() ->
    try
        risky()
catch
        _Err ->
            (-1)(_Err)
end.
```

----- RUN LOG -----
```logs
```
