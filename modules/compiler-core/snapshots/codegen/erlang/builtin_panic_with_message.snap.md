----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    @panic("something went wrong");
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

fail() ->
    erlang:error({panic, <<"something went wrong">>}).
```

----- RUN LOG -----
```logs
```
