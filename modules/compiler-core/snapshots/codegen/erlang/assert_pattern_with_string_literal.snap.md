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
-export(['__bp_priv__f'/0]).

f() ->
    Greeting = <<"hello">>,
    case Greeting of <<"hello">> -> Greeting; _ -> erlang:throw(<<"not hello">>) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
