----- SOURCE CODE -- main.bp
```botopink
fn main() {
    var count = 0;
    count += 1;
    @print(count);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).
-export(['_botopink_main'/0, main/1]).

main() ->
    Count = 0,
    Count = Count + 1,
    io:format("~p~n", [Count]).

'_botopink_main'() ->
    main().

main(_Args) ->
    '_botopink_main'().
```

----- RUN LOG -----
```logs
```
