----- SOURCE CODE -- main.bp
```botopink
fn negate(v: bool) -> bool {
    return !v;
}
fn main() {
    @print(negate(true));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

negate(V) ->
    (not V).

main() ->
    '__bp_print'([negate(true)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
false
```
