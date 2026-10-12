----- SOURCE CODE -- main.bp
```botopink
val msg: ?string = null;
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__msg'/0]).

msg() ->
    undefined.

'__bp_priv__msg'() -> msg().
```

----- RUN LOG -----
```logs
```
