----- SOURCE CODE -- main.bp
```botopink
type Person(name: string, age: i32)
fn f() -> Result<void, string> {
    val r = Person(name: "ann", age: 30);
    val assert Person(name, age) = r catch throw "is not person";
    return;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__f'/0]).

%% type Person: name, age

f() ->
    R = {test@main@@Person, <<"ann">>, 30},
    BpAssert4_9 = R,
    {test@main@@Person, Name, Age} = case BpAssert4_9 of {test@main@@Person, _, _} -> BpAssert4_9; _ -> {error, <<"is not person">>} end,
    {ok, undefined}.

'__bp_priv__f'() -> f().
```

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> erlang:element(2, V);
'__bp_get'(V, age) -> erlang:element(3, V).

'__bp_format'(V) -> {record, "Person", [{"name", erlang:element(2, V)}, {"age", erlang:element(3, V)}]}.
```

----- RUN LOG -----
```logs
```
