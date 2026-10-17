----- SOURCE CODE -- main.bp
```botopink
val x = 42;
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__x'/0]).

x() ->
    42.

'__bp_priv__x'() -> x().
```

----- RUN LOG -----
```logs
```
