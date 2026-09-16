----- SOURCE CODE -- main.bp
```botopink
val sum = 1 + 2;
fn main() {
    @print(sum);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

sum() ->
    (1 + 2).

main() ->
    io:format("~p~n", [sum()]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
3
```
