----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
*fn fetch() -> @Result<i32, ApiError> {
    throw ApiError(msg: "not found");
}
*fn strict() -> @Result<i32, string> {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record ApiError: msg

fetch() ->
    {error, #{msg => <<"not found">>}}.

strict() ->
    R = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            {error, <<"fetch failed">>}
    end,
    {ok, R}.
```

----- RUN LOG -----
```logs
```
