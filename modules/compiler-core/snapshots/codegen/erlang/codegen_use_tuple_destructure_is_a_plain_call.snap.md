----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
#[@context]
fn Counter() -> Element {
    val #(count, setCount) = use state(0);
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
    {Count, SetCount} = state(0),
    #{}.
```

----- RUN LOG -----
```logs
```
