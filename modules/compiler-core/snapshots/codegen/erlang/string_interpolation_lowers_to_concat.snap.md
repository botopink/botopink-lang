----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val name = "world";
    @print("hi ${name}!");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Name = <<"world">>,
    '__bp_print'([<<"hi ", Name/binary, "!">>]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
hi world!
```
