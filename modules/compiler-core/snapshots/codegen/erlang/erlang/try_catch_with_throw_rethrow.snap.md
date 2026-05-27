----- SOURCE CODE -- main.bp
```botopink
record ApiError { msg: string }
fn fetch() -> @Result(i32, ApiError) {
    throw ApiError(msg: "not found");
}
fn strict() -> @Result(i32, string) {
    val r = try fetch() catch throw "fetch failed";
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(ApiError, {msg}).

fetch() ->
    erlang:throw(ApiError(<<"not found">>)).

strict() ->
    R = try
        fetch()
catch
        _Err ->
            erlang:throw(<<"fetch failed">>)
end,
    R.
```

----- RUN LOG -----
```logs
```
