----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = enum { NotFound, Timeout }
*fn fetch() -> @Result<i32, ErrorKind> {
    throw ErrorKind.NotFound;
}
fn handle() -> i32 {
    val r = try fetch() catch 0;
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% enum ErrorKind
%%   NotFound
%%   Timeout

fetch() ->
    {error, 'NotFound'}.

handle() ->
    R = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    R.
```

----- RUN LOG -----
```logs
```
