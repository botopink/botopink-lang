----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn cleanup() {
    0;
}
fn effect() -> @Component<i32> {
    return 0;
}
fn Widget() -> @Component<Element> {
    use effect { -> cleanup(); };
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

cleanup() ->
    0.

effect(BpContextMap__) ->
    0.

'Widget'(BpContextMap__) ->
    effect(BpContextMap__, fun() ->
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
