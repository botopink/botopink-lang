----- SOURCE CODE -- main.bp
```botopink
record CalcError { msg: string }
fn getA() -> @Result(i32, CalcError) {
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

-record(CalcError, {msg}).

getA() ->
    erlang:throw(CalcError(<<"overflow">>)).

compute() ->
    R = try
        getA()
catch
        _Err ->
            0(_Err)
end,
    R.
```

----- RUN LOG -----
```logs
```
