----- SOURCE CODE -- main.bp
```botopink
val pair = #(1, "hello");
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__pair'/0]).

pair() ->
    {1, <<"hello">>}.

'__bp_priv__pair'() -> pair().
```

----- RUN LOG -----
```logs
```
