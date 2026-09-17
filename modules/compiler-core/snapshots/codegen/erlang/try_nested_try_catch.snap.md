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
    A = case try
        inner()
    catch
        error:_TryR0 -> {error, _TryR0}
    end of
        {ok, TryV0} -> TryV0;
        {error, _TryE0} ->
            0
    end,
    B = case try
        outer()
    catch
        error:_TryR1 -> {error, _TryR1}
    end of
        {ok, TryV1} -> TryV1;
        {error, _TryE1} ->
            A
    end,
    '__bp_print'([A, B]),
    '__bp_add'(A, B).

main() ->
    '__bp_print'([process()]).

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
0 0
0
```
