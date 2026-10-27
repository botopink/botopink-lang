----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val items = [1, 2, 3];
    val assert [first, ..] = items catch throw "not a list";
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    Items = [1, 2, 3],
    case Items of
        [First | _] ->
            {ok, undefined};
        _ ->
            {error, <<"not a list">>}
    end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
