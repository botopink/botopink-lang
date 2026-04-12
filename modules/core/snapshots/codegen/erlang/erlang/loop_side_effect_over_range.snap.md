----- SOURCE CODE -- main.bp
```botopink
loop (0..10) { i ->
    print("item");
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

_loop() ->
    lists:foreach(fun(I) ->
        print(<<"item">>)
    end, lists:seq(0, 10)).
```
