----- SOURCE CODE -- main.bp
```botopink
val ErrorKind = enum { NotFound, Timeout }
fn fetch() -> @Result(i32, ErrorKind) {
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
    erlang:throw(ErrorKind_NotFound).

handle() ->
    R = try
        fetch()
catch
        _Err ->
            0(_Err)
end,
    R.
```

----- RUN LOG -----
```logs
```
