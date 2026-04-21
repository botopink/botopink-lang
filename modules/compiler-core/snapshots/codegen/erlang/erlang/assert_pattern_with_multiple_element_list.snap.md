----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert [1, 2, 3] = numbers catch throw Error("not matching");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Numbers of [1, 2, 3] -> Numbers; _ -> erlang:throw(Error(<<"not matching">>)) end.
```
