----- SOURCE CODE -- main.bp
```botopink
val nested = #(#(1, 2), #(3, 4));
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

nested() ->
    {{1, 2}, {3, 4}}.
```

----- RUN LOG -----
```logs
```
