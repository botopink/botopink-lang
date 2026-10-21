----- SOURCE CODE -- main.bp
```botopink
val list3 = [1, 2, ..[3, 4]];
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__list3'/0]).

list3() ->
    [1, 2] ++ [3, 4].

'__bp_priv__list3'() -> list3().
```

----- RUN LOG -----
```logs
```
