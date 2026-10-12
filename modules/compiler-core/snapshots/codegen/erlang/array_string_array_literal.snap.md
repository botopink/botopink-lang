----- SOURCE CODE -- main.bp
```botopink
val xs = ["hello", "world"];
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__xs'/0]).

xs() ->
    [<<"hello">>, <<"world">>].

'__bp_priv__xs'() -> xs().
```

----- RUN LOG -----
```logs
```
