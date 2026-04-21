----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert 42 = answer catch throw Error("not 42");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Answer of 42 -> Answer; _ -> erlang:throw(Error(<<"not 42">>)) end.
```
