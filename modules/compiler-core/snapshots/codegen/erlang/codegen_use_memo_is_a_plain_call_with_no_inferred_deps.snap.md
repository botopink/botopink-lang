----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
#[@use]
fn state(initial: i32) -> @Use<Element, i32> {
    initial;
}
#[@use]
fn memo() -> @Use<Element, i32> {
    0;
}
#[@use]
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

state(Initial) ->
    Initial.

memo() ->
    0.

'Counter'() ->
    #{count := Count, setCount := SetCount} = state(0),
    Doubled = memo(fun() ->
        (Count * 2)
    end),
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
