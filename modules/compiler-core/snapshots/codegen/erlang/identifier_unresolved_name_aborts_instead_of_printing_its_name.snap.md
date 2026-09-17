----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val assert 42 = answer catch 0;
    @print("unreachable");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    case Answer of 42 -> Answer; _ -> 0 end,
    '__bp_print'([<<"unreachable">>]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
COMPILE ERROR (erlc):
main.erl:5:10: variable 'Answer' is unbound
```
