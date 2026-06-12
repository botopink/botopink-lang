----- SOURCE CODE -- main.bp
```botopink
record FetchError { url: string }
*fn fetch() -> @Result<i32, FetchError> {
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

%% record FetchError: url

fetch() ->
    {error, #{url => <<"/api">>}}.

safe() ->
    R = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            fun(E) ->
                0
            end(_TryE0)
    end,
    R.
```

----- RUN LOG -----
```logs
```
