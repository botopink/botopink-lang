----- SOURCE CODE -- main.bp
```botopink
val nested = #(#(1, 2), #(3, 4));
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__nested'/0]).

nested() ->
    {{1, 2}, {3, 4}}.

'__bp_priv__nested'() -> nested().
```

----- RUN LOG -----
```logs
```
