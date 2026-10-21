----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val greeting = "hello";
    val assert "hello" = greeting catch throw "not hello";
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    Greeting = <<"hello">>,
    case Greeting of <<"hello">> -> Greeting; _ -> {error, <<"not hello">>} end,
    {ok, undefined}.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
