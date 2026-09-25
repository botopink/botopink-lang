----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Use<Element, i32> {
    initial;
}
#[@use]
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

state(Initial) ->
    Initial.

'Counter'() ->
    #{count := Count, setCount := SetCount} = state(0),
    {test@main@@Element}.
```

----- ERLANG -- test@main@@Element.erl
```erlang
-module(test@main@@Element).
-export(['__bp_format'/1]).

'__bp_format'(_) -> {record, "Element", []}.
```

----- RUN LOG -----
```logs
```
