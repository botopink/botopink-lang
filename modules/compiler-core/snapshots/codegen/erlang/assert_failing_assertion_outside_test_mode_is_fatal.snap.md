----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("before");
    assert 1 == 2, "boom";
    @print("after");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    '__bp_print'([<<"before">>]),
    case ((1 =:= 2)) of true -> ok; _ -> erlang:error({bp_assert, <<"boom">>, <<"main.bp:3">>}) end,
    '__bp_print'([<<"after">>]).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
