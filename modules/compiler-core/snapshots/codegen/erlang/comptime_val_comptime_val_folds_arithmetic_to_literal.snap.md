----- SOURCE CODE -- main.bp
```botopink
val result = comptime 10 + 20;
fn main() {
    @print(result);
}
```

----- COMPTIME VALUES -- main
```text
ct_0: val result = comptime 10 + 20 → 30
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

result() ->
    30.

main() ->
    '__bp_print'([result()]).

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
