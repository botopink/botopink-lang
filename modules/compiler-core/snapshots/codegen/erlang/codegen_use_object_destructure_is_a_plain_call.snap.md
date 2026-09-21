----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
#[@context]
fn Counter() -> Element {
    val {count, setCount} = use state(0);
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Element: 

state(Initial) ->
    Initial.

'Counter'() ->
    #{count := Count, setCount := SetCount} = state(0),
    {main__t__element}.
```

----- ERLANG -- main__t__element.erl
```erlang
-module(main__t__element).
-export(['__bp_format'/1]).

'__bp_format'(_) -> {record, "Element", []}.
```

----- RUN LOG -----
```logs
```
