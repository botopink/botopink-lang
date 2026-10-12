----- SOURCE CODE -- main.bp
```botopink
val greeting = "hello";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__greeting'/0]).

greeting() ->
    <<"hello">>.

'__bp_priv__greeting'() -> greeting().
```

----- RUN LOG -----
```logs
```
