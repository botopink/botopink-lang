----- SOURCE CODE -- main.bp
```botopink
behavior Printable {
    fn print(self: Self);
}
type Person(name: string)
val PersonPrintable = implement Printable for Person {
    fn print(self: Self) {
        return self.name;
    }
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% behavior Printable

%% type Person: name

%% implement Printable for Person

print(Self) ->
    element(2, Self).
```

----- ERLANG -- test@main@@Person.erl
```erlang
-module(test@main@@Person).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, name) -> element(2, V).

'__bp_format'(V) -> {record, "Person", [{"name", element(2, V)}]}.
```

----- RUN LOG -----
```logs
```
