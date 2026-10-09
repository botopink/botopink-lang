----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

state(BpContextMap__, Initial) ->
    Initial.

'Counter'(BpContextMap__) ->
    #{count := Count, setCount := SetCount} = state(BpContextMap__, 0),
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
