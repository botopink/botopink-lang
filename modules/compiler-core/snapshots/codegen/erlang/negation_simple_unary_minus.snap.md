----- SOURCE CODE -- main.bp
```botopink
fn negate(x: i32) -> i32 {
    return -x;
}
fn main() {
    @print(negate(42));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

negate(X) ->
    (-X).

main() ->
    '__bp_print'([negate(42)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
-42
```
