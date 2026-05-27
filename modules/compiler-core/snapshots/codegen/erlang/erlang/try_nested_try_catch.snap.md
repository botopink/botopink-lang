----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
fn inner() -> @Result(i32, DbError) {
    throw DbError(msg: "conn refused");
}
fn outer() -> @Result(i32, DbError) {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

-record(DbError, {msg}).

inner() ->
    erlang:throw(DbError(<<"conn refused">>)).

outer() ->
    erlang:throw(DbError(<<"timeout">>)).

process() ->
    A = try
        inner()
catch
        _Err ->
            0(_Err)
end,
    B = try
        outer()
catch
        _Err ->
            A(_Err)
end,
    io:format("~p~n", [A, B]),
    (A + B).
```

----- RUN LOG -----
```logs
```
