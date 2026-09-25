----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() {
    @todo("implement this function");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

notImplemented() ->
    erlang:error({todo, <<"implement this function">>}).
```

----- RUN LOG -----
```logs
```
