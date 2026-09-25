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
-module(test@main).

%% type FetchError: url

fetch() ->
    {error, {test@main@@FetchError, <<"/api">>}}.

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

----- ERLANG -- test@main@@FetchError.erl
```erlang
-module(test@main@@FetchError).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, url) -> element(2, V).

'__bp_format'(V) -> {record, "FetchError", [{"url", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
