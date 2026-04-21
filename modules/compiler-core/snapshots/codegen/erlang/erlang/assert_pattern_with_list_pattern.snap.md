----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [first, ..] = items catch throw Error("not a list");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Items of [First | _] -> Items; _ -> erlang:throw(Error(<<"not a list">>)) end.
```
