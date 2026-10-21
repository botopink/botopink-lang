----- SOURCE CODE -- main.bp
```botopink
val items: string[] = ["65454"];
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__items'/0]).

items() ->
    [<<"65454">>].

'__bp_priv__items'() -> items().
```

----- RUN LOG -----
```logs
```
