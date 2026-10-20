----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val answer = 42;
    val assert 42 = answer catch throw "not 42";
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    Answer = 42,
    case Answer of 42 -> Answer; _ -> {error, <<"not 42">>} end,
    {ok, undefined}.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
