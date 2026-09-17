----- SOURCE CODE -- main.bp
```botopink
fn log(msg: string) {
    @print(msg);
}
fn main() {
    log("started");
    val x = 42;
    log("done");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

log(Msg) ->
    '__bp_print'([Msg]).

main() ->
    log(<<"started">>),
    X = 42,
    log(<<"done">>).

'__bp_print'(Values) ->
    io:format(lists:flatten([lists:join(" ", [case is_binary(V) of true -> "~ts"; false -> "~p" end || V <- Values]), "~n"]), Values).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
started
done
```
