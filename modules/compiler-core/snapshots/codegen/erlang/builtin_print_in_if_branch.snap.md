----- SOURCE CODE -- main.bp
```botopink
fn check(x: i32) {
    if (x > 0) {
        @print("positive");
    } else {
        @print("non-positive");
    }
}
fn main() {
    check(1);
    check(-1);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

check(X) ->
    case (X > 0) of
        true ->
            '__bp_print'([<<"positive">>]);
        false ->
            '__bp_print'([<<"non-positive">>])
    end.

main() ->
    check(1),
    check((-1)).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
positive
non-positive
```
