----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3];
    val assert [first, ..] = items catch throw "not a list";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    Items = [1, 2, 3],
    BpAssert3_9 = Items,
    [First | _] = case BpAssert3_9 of [_ | _] -> BpAssert3_9; _ -> erlang:throw(<<"not a list">>) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
