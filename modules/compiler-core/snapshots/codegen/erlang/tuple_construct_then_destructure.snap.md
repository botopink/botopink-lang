----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val t = #(10, 20);
    val #(a, b) = t;
    @print(a + b);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    T = {10, 20},
    {A, B} = T,
    io:format("~p~n", [(A + B)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
30
```
