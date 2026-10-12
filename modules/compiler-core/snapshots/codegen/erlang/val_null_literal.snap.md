----- SOURCE CODE -- main.bp
```botopink
val nothing = null;
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__nothing'/0]).

nothing() ->
    undefined.

'__bp_priv__nothing'() -> nothing().
```

----- RUN LOG -----
```logs
```
