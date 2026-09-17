----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert [] == [];
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case (([] =:= [])) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:2">>}) end.
```

----- RUN LOG -----
```logs
```
