----- SOURCE CODE -- main.bp
```botopink
fn main() {
    assert 1 + 1 == 2, "arithmetic";
    @print("after");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    case (((1 + 1) =:= 2)) of true -> ok; _ -> erlang:error({bp_assert, <<"arithmetic">>, <<"main.bp:2">>}) end,
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
after
```
