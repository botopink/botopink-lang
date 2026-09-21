----- SOURCE CODE -- main.bp
```botopink
type NetError(code: i32)
#[@result]
fn fetch() -> @Result<i32, NetError> {
    throw NetError(code: 500);
}
fn safe() -> i32 {
    val r = try fetch() catch return -1;
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type NetError: code

fetch() ->
    {error, {main__t__neterror, 500}}.

safe() ->
    R = case try
        fetch()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            (-1)
    end,
    R.
```

----- ERLANG -- main__t__neterror.erl
```erlang
-module(main__t__neterror).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, code) -> element(2, V).

'__bp_format'(V) -> {record, "NetError", [{"code", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
