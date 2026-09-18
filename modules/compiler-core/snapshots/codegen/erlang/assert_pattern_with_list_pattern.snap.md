----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val items = [1, 2, 3];
    val assert [first, ..] = items catch throw "not a list";
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    Items = [1, 2, 3],
    case Items of [First | _] -> Items; _ -> erlang:throw(<<"not a list">>) end.
```

----- RUN LOG -----
```logs
```
