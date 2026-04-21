----- SOURCE CODE -- main.bp
```botopink
val add = { x, y ->
    x + y;
};
val result = add(10, 20);
```

----- ERLANG -- main.erl
```erlang
-module(main).

add() ->
    fun(X, Y) ->
        (X + Y)
    end.

result() ->
    add(10, 20).
```
