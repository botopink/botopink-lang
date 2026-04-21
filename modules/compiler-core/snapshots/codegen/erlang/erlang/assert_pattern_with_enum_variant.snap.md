----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Ok(value) = result catch throw Error("not ok");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Result of {tag, Ok, Value} -> Result; _ -> erlang:throw(Error(<<"not ok">>)) end.
```
