----- SOURCE CODE -- main.bp
```botopink
fn notImplemented() {
    @todo("implement this function");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

notImplemented() ->
    erlang:error({todo, <<"implement this function">>}).
```
