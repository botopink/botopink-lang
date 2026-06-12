----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val xs: i32[] = [];
    @print(xs.len);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Xs = [],
    io:format("~p~n", [length(Xs)]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
0
```
