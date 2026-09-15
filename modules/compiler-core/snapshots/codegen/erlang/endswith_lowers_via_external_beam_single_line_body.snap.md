----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "foobar";
    @print(s.endsWith("bar"));
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    S = <<"foobar">>,
    io:format("~p~n", [string:suffix(S, <<"bar">>)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
