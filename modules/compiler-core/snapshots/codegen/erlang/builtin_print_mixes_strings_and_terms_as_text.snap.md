----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val name = "ana";
    @print("hi", name, 42, [1, 2]);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Name = <<"ana">>,
    io:format("~p ~p ~p ~p~n", [<<"hi">>, Name, 42, [1, 2]]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
<<"hi">> <<"ana">> 42 [1,2]
```
