----- SOURCE CODE -- main.bp
```botopink
record NetError { code: i32 }
fn fetch() -> @Result(i32, NetError) {
    throw NetError(code: 500);
}
fn safe() -> i32 {
    val r = try fetch() catch return -1;
    return r;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(NetError, {code}).

fetch() ->
    erlang:throw(NetError(500)).

safe() ->
    R = try
        fetch()
catch
        _Err ->
            (-1)
end,
    R.
```

----- RUN LOG -----
```logs
```
