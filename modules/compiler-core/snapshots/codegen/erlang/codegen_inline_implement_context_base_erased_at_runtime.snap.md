----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement Renderable
fn render() -> Element {
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).
-export(['__bp_priv__render'/0]).

%% type Element: 

render() ->
    {test@main@@Element}.

'__bp_priv__render'() -> render().
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
