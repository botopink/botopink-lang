----- SOURCE CODE -- main.bp
```botopink
val t: #(string, string) = #("56454", "85484");
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__t'/0]).

t() ->
    {<<"56454">>, <<"85484">>}.

'__bp_priv__t'() -> t().
```

----- RUN LOG -----
```logs
```
