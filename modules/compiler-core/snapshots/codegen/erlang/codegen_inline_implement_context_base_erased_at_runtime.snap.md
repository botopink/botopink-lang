----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn render() -> Element {
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Element: 

render() ->
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
