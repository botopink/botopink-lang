----- SOURCE CODE -- main.bp
```botopink
type CalcError(msg: string)
#[@result]
fn getA() -> @Result<i32, CalcError> {
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

%% type CalcError: msg

getA() ->
    {error, {main__t__calcerror, <<"overflow">>}}.

compute() ->
    R = case try
        getA()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    R.
```

----- ERLANG -- main__t__calcerror.erl
```erlang
-module(main__t__calcerror).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, msg) -> element(2, V).

'__bp_format'(V) -> {record, "CalcError", [{"msg", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
