----- SOURCE CODE -- main.bp
```botopink
fn isPositive(n: i32) -> bool {
    return n > 0;
}
fn main() {
    @print(isPositive(5));
    @print(isPositive(-1));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

isPositive(N) ->
    (N > 0).

main() ->
    '__bp_print'([isPositive(5)]),
    '__bp_print'([isPositive((-1))]).

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
false
```
