----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
fn render() -> Element {
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

render() ->
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
