----- SOURCE CODE -- main.bp
```botopink
val rest = [3, 4];
val list = [1, 2, ..rest];
```

----- ERLANG -- main.erl
```erlang
-module(main).

rest() ->
    [3, 4].

list() ->
    [1, 2, rest].
```
