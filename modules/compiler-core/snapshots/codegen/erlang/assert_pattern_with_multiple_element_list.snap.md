----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val numbers = [1, 2, 3];
    val assert [1, 2, 3] = numbers catch throw "not matching";
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    Numbers = [1, 2, 3],
    case Numbers of [1, 2, 3] -> Numbers; _ -> {error, <<"not matching">>} end,
    {ok, undefined}.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
