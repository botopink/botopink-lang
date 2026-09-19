----- SOURCE CODE -- main.bp
```botopink
type FetchError(url: string)
#[@result]
fn fetch() -> @Result<i32, FetchError> {
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

%% type FetchError: url

fetch() ->
    {error, #{url => <<"/api">>}}.

safe() ->
    R = case try
        fetch()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
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
