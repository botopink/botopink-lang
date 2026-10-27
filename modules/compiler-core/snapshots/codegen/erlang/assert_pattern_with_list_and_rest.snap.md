----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    val items = [1, 2, 3, 4];
    val assert [first, second, ..rest] = items catch [];
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    Items = [1, 2, 3, 4],
    BpAssert3_9 = Items,
    [First, Second | Rest] = case BpAssert3_9 of [_, _ | _] -> BpAssert3_9; _ -> BpAssert3_9_h = [], case BpAssert3_9_h of [_, _ | _] -> BpAssert3_9_h; _ -> erlang:error({panic, <<"assert pattern did not match">>}) end end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
