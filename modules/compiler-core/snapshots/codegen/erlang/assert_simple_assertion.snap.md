----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert true;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case (true) of true -> ok; _ -> erlang:error({bp_assert, <<"assertion failed">>, <<"main.bp:2">>}) end.
```

----- RUN LOG -----
```logs
```
