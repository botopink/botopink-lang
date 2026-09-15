----- SOURCE CODE -- main.bp
```botopink
val Element = record implement @Context<Element, Element> { }
fn render() -> Element {
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Element: 

render() ->
    #{}.
```

----- RUN LOG -----
```logs
```
