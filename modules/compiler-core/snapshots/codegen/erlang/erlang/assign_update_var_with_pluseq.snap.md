----- SOURCE CODE -- main.bp
```botopink
fn increment() {
    var count = 0;
    count += 1;
    @print(count);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

increment() ->
    Count = 0,
    Count = Count + 1,
    io:format("~p~n", [Count]).
```

----- RUN LOG -----
```logs
```
