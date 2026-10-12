----- SOURCE CODE -- main.bp
```botopink
val list2 = [1, 2, ..[3]];
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__list2'/0]).

list2() ->
    [1, 2] ++ [3].

'__bp_priv__list2'() -> list2().
```

----- RUN LOG -----
```logs
```
