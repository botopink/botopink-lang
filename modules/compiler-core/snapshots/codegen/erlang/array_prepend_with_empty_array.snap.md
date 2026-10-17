----- SOURCE CODE -- main.bp
```botopink
val list1 = [1, ..[]];
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__list1'/0]).

list1() ->
    [1] ++ [].

'__bp_priv__list1'() -> list1().
```

----- RUN LOG -----
```logs
```
