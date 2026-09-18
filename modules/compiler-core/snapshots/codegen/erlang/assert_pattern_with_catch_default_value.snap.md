----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch Person(name: "bob", age: 12);
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Person: name, age

f() ->
    R = #{name => <<"ann">>, age => 30},
    case R of {'Person', Name, Age} -> R; _ -> #{name => <<"bob">>, age => 12} end.
```

----- RUN LOG -----
```logs
```
