----- SOURCE CODE -- main.bp
```botopink
fn f() -> void {
    assert false, "error message";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    case (false) of true -> ok; _ -> _AssertMsg0 = <<"error message">>, erlang:error({bp_assert, _AssertMsg0, <<"main.bp:2">>, [<<"assertion failed: false: ">>, _AssertMsg0, <<" at main.bp:2:5">>]}) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
