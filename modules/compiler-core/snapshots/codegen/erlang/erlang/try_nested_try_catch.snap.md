----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
*fn inner() -> @Result<i32, DbError> {
    throw DbError(msg: "conn refused");
}
*fn outer() -> @Result<i32, DbError> {
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

%% record DbError: msg

inner() ->
    {error, #{msg => <<"conn refused">>}}.

outer() ->
    {error, #{msg => <<"timeout">>}}.

process() ->
    A = case inner() of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    B = case outer() of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            A
    end,
    io:format("~p~n", [A, B]),
    (A + B).
```

----- RUN LOG -----
```logs
```
