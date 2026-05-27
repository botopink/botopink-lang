----- SOURCE CODE -- main.bp
```botopink
record FetchError { url: string }
fn fetch() -> @Result(i32, FetchError) {
    throw FetchError(url: "/api");
}
fn safe() -> i32 {
    val r = try fetch() catch fn(e) { return 0; };
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(FetchError, {url}).

fetch() ->
    erlang:throw(FetchError(<<"/api">>)).

safe() ->
    R = try
        fetch()
catch
        _Err ->
            fun(E) ->
                0
            end(_Err)
end,
    R.
```

----- RUN LOG -----
```logs
```
