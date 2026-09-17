----- SOURCE CODE -- main.bp
```botopink
val add = { x, y ->
    x + y;
};
val result = add(10, 20);
fn main() {
    @print(result);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

add() ->
    fun(X, Y) ->
        '__bp_add'(X, Y)
    end.

result() ->
    (add())(10, 20).

main() ->
    '__bp_print'([result()]).

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
30
```
