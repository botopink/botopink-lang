----- SOURCE CODE -- main.bp
```botopink
fn f() {
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

f() ->
    case R of {tag, Person, Name, Age} -> R; _ -> Person(<<"bob">>, 12) end.
```
