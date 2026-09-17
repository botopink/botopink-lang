----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val left = "fo" + "o";
    val same = left == "foo";
    val diff = "foo" == "bar";
    if (same) {
        @print(1);
    } else {
        @print(0);
    };
    if (diff) {
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
    Left = <<"fo", "o">>,
    Same = (Left =:= <<"foo">>),
    Diff = (<<"foo">> =:= <<"bar">>),
    case Same of
        true ->
            '__bp_print'([1]);
        false ->
            '__bp_print'([0])
    end,
    case Diff of
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
0
```
