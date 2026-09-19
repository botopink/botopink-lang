----- SOURCE CODE -- main.bp
```botopink
type DbError(msg: string)
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

%% type DbError: msg

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
    io:format("~ts~n", [lists:join(" ", ['__bp_show'(V, true) || V <- Values])]).

'__bp_show'(V, true) when is_binary(V) -> V;
'__bp_show'(V, _) when is_binary(V) -> [$", [case C of $" -> "\\\""; $\\ -> "\\\\"; $\n -> "\\n"; $\r -> "\\r"; $\t -> "\\t"; _ -> C end || C <- unicode:characters_to_list(V)], $"];
'__bp_show'(V, _) when is_list(V) -> [$[, lists:join(",", ['__bp_show'(E, false) || E <- V]), $]];
'__bp_show'(V, _) when is_tuple(V), tuple_size(V) > 0, is_atom(element(1, V)), element(1, V) =/= true, element(1, V) =/= false, element(1, V) =/= undefined -> io_lib:format("~p", [V]);
'__bp_show'(V, _) when is_tuple(V) -> ["#(", lists:join(",", ['__bp_show'(E, false) || E <- tuple_to_list(V)]), $)];
'__bp_show'(V, _) -> io_lib:format("~p", [V]).

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
