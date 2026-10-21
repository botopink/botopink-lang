----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    assert 1.0 + 2.0 == 3.0;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    case (((1.0 + 2.0) =:= 3.0)) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:2">>, <<"assertion failed: 1.0 + 2.0 == 3.0 at main.bp:2:5">>}) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
