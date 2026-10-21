----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    assert true;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    case (true) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:2">>, <<"assertion failed: true at main.bp:2:5">>}) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
