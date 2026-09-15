----- SOURCE CODE -- main.bp
```botopink
fn main() {
    loop (0..10) { i ->
        @print(i);
    };
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    lists:foreach(fun(I) ->
        io:format("~p~n", [I])
    end, lists:seq(0, (10) - 1)).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
0
1
2
3
4
5
6
7
8
9
```
