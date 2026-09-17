----- SOURCE CODE -- main.bp
```botopink
fn mag(n: i32) -> i32 {
    return n.abs();
}
fn main() {
    @print(mag(-7));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface Signed

mag(N) ->
    erlang:abs(N).

main() ->
    '__bp_print'([mag((-7))]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
7
```
