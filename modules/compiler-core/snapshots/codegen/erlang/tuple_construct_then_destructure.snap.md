----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val t = #(10, 20);
    val #(a, b) = t;
    @print(a + b);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    T = {10, 20},
    {A, B} = T,
    '__bp_print'([(A + B)]).

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
