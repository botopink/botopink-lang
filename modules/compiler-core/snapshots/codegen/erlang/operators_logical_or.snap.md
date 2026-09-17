----- SOURCE CODE -- main.bp
```botopink
fn either(a: bool, b: bool) -> bool {
    return a || b;
}
fn main() {
    @print(either(false, true));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

either(A, B) ->
    (A orelse B).

main() ->
    '__bp_print'([either(false, true)]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
true
```
