----- SOURCE CODE -- main.bp
```botopink
val rest = [3, 4];
val list = [1, 2, ..rest];
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__rest'/0, '__bp_priv__list'/0]).

rest() ->
    [3, 4].

list() ->
    [1, 2] ++ rest().

'__bp_priv__rest'() -> rest().

'__bp_priv__list'() -> list().
```

----- RUN LOG -----
```logs
```
