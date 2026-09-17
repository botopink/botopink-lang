----- SOURCE CODE -- main.bp
```botopink
fn isZero(n: i32) -> bool {
    return n == 0;
}
fn main() {
    @print(isZero(0));
    @print(isZero(42));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

isZero(N) ->
    (N =:= 0).

main() ->
    '__bp_print'([isZero(0)]),
    '__bp_print'([isZero(42)]).

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
