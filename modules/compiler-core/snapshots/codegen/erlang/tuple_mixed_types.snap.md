----- SOURCE CODE -- main.bp
```botopink
val t = #(12, "5452");
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__t'/0]).

t() ->
    {12, <<"5452">>}.

'__bp_priv__t'() -> t().
```

----- RUN LOG -----
```logs
```
