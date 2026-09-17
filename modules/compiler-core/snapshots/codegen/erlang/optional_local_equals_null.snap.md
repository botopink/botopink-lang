----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val x: ?i32 = null;
    if (x == null) {
        @print(1);
    } else {
        @print(0);
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    X = undefined,
    case (X =:= undefined) of
        true ->
            '__bp_print'([1]);
        false ->
            '__bp_print'([0])
    end.

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
1
```
