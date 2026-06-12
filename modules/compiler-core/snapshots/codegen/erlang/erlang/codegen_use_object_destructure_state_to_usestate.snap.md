----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn Counter() -> Element {
    val {count, setCount} = use state(0);
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% struct Element: 

state(Initial) ->
    Initial.

Counter() ->
    {Count, SetCount} = state(0),
    #{}.
```

----- RUN LOG -----
```logs
```
