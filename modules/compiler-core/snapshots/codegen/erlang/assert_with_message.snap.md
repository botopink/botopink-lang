----- SOURCE CODE -- main.bp
```botopink
fn f() {
    assert false, "error message";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case (false) of true -> ok; _ -> erlang:error({bp_assert, <<"error message">>, <<"main.bp:2">>}) end.
```

----- RUN LOG -----
```logs
```
