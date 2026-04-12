----- SOURCE CODE -- main.bp
```botopink
val ids = [10, 20, 30];
val dobrados = loop (ids) { id ->
    break id * 2;
};
```

----- ERLANG -- main.erl
```erlang
-module(main).

ids() ->
    [10, 20, 30].

dobrados() ->
    lists:foreach(fun(Id) ->
        (Id * 2)
    end, Ids).
```
