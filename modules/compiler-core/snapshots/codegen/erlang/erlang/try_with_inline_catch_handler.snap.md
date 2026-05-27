----- SOURCE CODE -- main.bp
```botopink
fn fetch() -> i32 {
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
    R = try
        fetch()
catch
        _Err ->
            0(_Err)
end,
    io:format("~p~n", [R]),
    R.
```

----- RUN LOG -----
```logs
```
