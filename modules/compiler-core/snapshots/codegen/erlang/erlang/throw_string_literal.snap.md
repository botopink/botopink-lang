----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    throw "something went wrong";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

fail() ->
    erlang:throw(<<"something went wrong">>).
```

----- RUN LOG -----
```logs
```
