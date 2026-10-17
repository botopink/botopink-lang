----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert [] == [];
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

f() ->
    case (([] =:= [])) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:2">>, <<"assertion failed: [] == [] at main.bp:2:5">>}) end.

'__bp_priv__f'() -> f().
```

----- RUN LOG -----
```logs
```
