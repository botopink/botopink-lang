----- SOURCE CODE -- main.bp
```botopink
fn f() -> Result<void, string> {
    val list: i32[] = [];
    val assert [] = list catch throw "not empty";
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    List = [],
    case List of [] -> List; _ -> {error, <<"not empty">>} end,
    {ok, undefined}.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
