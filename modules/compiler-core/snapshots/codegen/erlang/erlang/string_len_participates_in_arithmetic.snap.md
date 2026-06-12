----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "hello";
    @print(s.len + 1);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    S = <<"hello">>,
    io:format("~p~n", [(string:length(S) + 1)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
6
```
