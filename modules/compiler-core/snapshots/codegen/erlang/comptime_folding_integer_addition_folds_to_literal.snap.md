----- SOURCE CODE -- main.bp
```botopink
val v1 = comptime 1 + 1;
fn main() {
    @print(v1);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val v1 = comptime 1 + 1 → 2
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

v1() ->
    2.

main() ->
    '__bp_print'([v1()]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
2
```
