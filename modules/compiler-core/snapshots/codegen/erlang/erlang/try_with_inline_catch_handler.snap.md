----- SOURCE CODE -- main.bp
```botopink
*fn fetch() -> @Result<i32, string> {
    @todo();
}
fn safe() -> i32 {
    val r = try fetch() catch 0;
    @print(r);
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

fetch() ->
    erlang:error({todo, "not implemented"}).

safe() ->
    R = case fetch() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    io:format("~p~n", [R]),
    R.
```

----- RUN LOG -----
```logs
```
