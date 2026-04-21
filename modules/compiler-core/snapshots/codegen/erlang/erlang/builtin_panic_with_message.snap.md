----- SOURCE CODE -- main.bp
```botopink
fn fail() {
    @panic("something went wrong");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

fail() ->
    erlang:error({panic, <<"something went wrong">>}).
```
