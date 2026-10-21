----- SOURCE CODE -- main.bp
```botopink
type CalcError(msg: string)
fn getA() -> Result<i32, CalcError> {
    throw CalcError(msg: "overflow");
}
fn compute() -> i32 {
    val r = try getA() catch 0;
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__getA'/0, '__bp_priv__compute'/0]).

%% type CalcError: msg

getA() ->
    {error, {test@main@@CalcError, <<"overflow">>}}.

compute() ->
    R = case getA() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    R.

'__bp_priv__getA'() -> getA().

'__bp_priv__compute'() -> compute().
```

----- ERLANG -- test@main@@CalcError.erl
```erlang
-module(test@main@@CalcError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, msg) -> erlang:element(2, V).

'__bp_format'(V) -> {record, "CalcError", [{"msg", erlang:element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
