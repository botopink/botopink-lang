----- SOURCE CODE -- main.bp
```botopink
fn extract() {
    val #(a, b) = #(12, "hello");
    @print(a, b);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

extract() ->
    {A, B} = {12, <<"hello">>},
    io:format("~p~n", [A, B]).
```

----- RUN LOG -----
```logs
```
