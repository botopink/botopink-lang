----- SOURCE CODE -- main.bp
```botopink
record CalcError { msg: string }
*fn getA() -> @Result<i32, CalcError> {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = getA() catch 0;
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record CalcError: msg

getA() ->
    {error, #{msg => <<"overflow">>}}.

compute() ->
    R = case getA() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    R.
```

----- RUN LOG -----
```logs
```
