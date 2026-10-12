----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() {
    @todo("implement this function");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__notImplemented'/0]).

notImplemented() ->
    erlang:error({todo, <<"implement this function">>}).

'__bp_priv__notImplemented'() -> notImplemented().
```

----- RUN LOG -----
```logs
```
