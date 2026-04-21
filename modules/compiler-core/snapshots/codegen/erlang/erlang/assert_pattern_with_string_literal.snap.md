----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert "hello" = greeting catch throw Error("not hello");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case Greeting of <<"hello">> -> Greeting; _ -> erlang:throw(Error(<<"not hello">>)) end.
```
