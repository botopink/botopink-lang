----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Person(name, age) = r catch throw Error("is not person");
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case R of {tag, Person, Name, Age} -> R; _ -> erlang:throw(Error(<<"is not person">>)) end.
```
