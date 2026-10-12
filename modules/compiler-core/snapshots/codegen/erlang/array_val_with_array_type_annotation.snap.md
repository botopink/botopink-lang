----- SOURCE CODE -- main.bp
```botopink
val array: string[] = ["65454"];
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__array'/0]).

array() ->
    [<<"65454">>].

'__bp_priv__array'() -> array().
```

----- RUN LOG -----
```logs
```
