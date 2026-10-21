----- SOURCE CODE -- main.bp
```botopink
val greeting = "Hello, World!";
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__greeting'/0]).

greeting() ->
    <<"Hello, World!">>.

'__bp_priv__greeting'() -> greeting().
```

----- RUN LOG -----
```logs
```
