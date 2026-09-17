----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x: ?i32 = 42;
    if (x) { n -> @print(n); };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    X = 42,
    case X of
        undefined -> undefined;
        N ->
            '__bp_print'([N])
    end.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
42
```
