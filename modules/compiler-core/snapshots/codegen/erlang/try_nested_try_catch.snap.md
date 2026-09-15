----- SOURCE CODE -- main.bp
```botopink
record DbError { msg: string }
#[@result]
fn inner() -> @Result<i32, DbError> {
    throw DbError(msg: "conn refused");
}
#[@result]
fn outer() -> @Result<i32, DbError> {
    throw DbError(msg: "timeout");
}
fn process() -> i32 {
    val a = try inner() catch 0;
    val b = try outer() catch a;
    @print(a, b);
    return a + b;
}
fn main() {
    @print(process());
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

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

main() ->
    io:format("~p~n", [process()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
