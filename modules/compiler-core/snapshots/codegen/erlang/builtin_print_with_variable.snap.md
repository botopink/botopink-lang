----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val name = "world";
    @print("Hello, " + name);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Name = <<"world">>,
    io:format("~p~n", [(<<"Hello, ">> + Name)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
