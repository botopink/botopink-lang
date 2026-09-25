----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element> { }
fn cleanup() {
    0;
}
fn effect() -> @Component<Element, i32> {
    0;
}
fn Widget() -> @Component<Element, Element> {
    use effect { -> cleanup(); };
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

cleanup() ->
    0.

effect() ->
    0.

'Widget'() ->
    effect(fun() ->
        cleanup()
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
