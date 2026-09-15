----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val s = "hello";
    val mid = s.slice(1, 4);
    @print(mid.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

%% interface String

main() ->
    S = <<"hello">>,
    Mid = slice(S, 1, 4),
    io:format("~p~n", [string:length(Mid)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
