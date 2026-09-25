----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

f() ->
    Greeting = <<"hello">>,
    case Greeting of <<"hello">> -> Greeting; _ -> erlang:throw(<<"not hello">>) end.
```

----- RUN LOG -----
```logs
```
