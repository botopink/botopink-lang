----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch throw "is not person";
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Person: name, age

f() ->
    R = {test@main@@Person, <<"ann">>, 30},
    BpAssert4_9 = R,
    {test@main@@Person, Name, Age} = case BpAssert4_9 of {test@main@@Person, _, _} -> BpAssert4_9; _ -> erlang:throw(<<"is not person">>) end.
```

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V);
'__bp_get'(V, age) -> element(3, V).

'__bp_format'(V) -> {record, "Person", [{"name", element(2, V)}, {"age", element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
