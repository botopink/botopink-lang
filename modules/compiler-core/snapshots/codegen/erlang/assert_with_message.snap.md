----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert false, "error message";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    case (false) of true -> ok; _ -> erlang:error({bp_assert, <<"error message">>, <<"main.bp:2">>}) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
