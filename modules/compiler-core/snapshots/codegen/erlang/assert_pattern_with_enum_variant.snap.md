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
    case Result of {ok, Value} -> Result; _ -> erlang:throw({error, <<"not ok">>}) end.
```

----- RUN LOG -----
```logs
```
