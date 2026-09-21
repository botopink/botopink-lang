----- SOURCE CODE -- main.bp
```botopink
type ApiError(msg: string)
#[@result]
fn fetch() -> @Result<i32, ApiError> {
    throw ApiError(msg: "not found");
}
#[@result]
fn strict() -> @Result<i32, string> {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type ApiError: msg

fetch() ->
    {error, {main__t__apierror, <<"not found">>}}.

strict() ->
    R = case try
        fetch()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            {error, <<"fetch failed">>}
    end,
    {ok, R}.
```

----- ERLANG -- main__t__apierror.erl
```erlang
-module(main__t__apierror).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, msg) -> element(2, V).

'__bp_format'(V) -> {record, "ApiError", [{"msg", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
