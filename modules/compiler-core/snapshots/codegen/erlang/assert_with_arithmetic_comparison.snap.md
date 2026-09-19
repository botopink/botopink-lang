----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert 1.0 + 2.0 == 3.0;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case (((1.0 + 2.0) =:= 3.0)) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:2">>}) end.
```

----- RUN LOG -----
```logs
```
