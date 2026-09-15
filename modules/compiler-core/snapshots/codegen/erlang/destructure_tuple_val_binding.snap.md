----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val #(a, b) = #(12, "hello");
    @print(a, b);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    {A, B} = {12, <<"hello">>},
    io:format("~p~n", [A, B]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
