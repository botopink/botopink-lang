----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print("Hello", 42, true);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    io:format("~p~n", [<<"Hello">>, 42, true]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
