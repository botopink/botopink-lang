----- SOURCE CODE -- main.bp
```botopink
val Element = struct implement @Context<Element, Element> { }
fn cleanup() {
    0;
}
fn effect() -> @Context<Element, i32> {
    0;
}
fn Widget() -> Element {
    use effect { -> cleanup(); };
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% struct Element: 

cleanup() ->
    0.

effect() ->
    0.

Widget() ->
    effect(fun() ->
        cleanup()
    end),
    #{}.
```

----- RUN LOG -----
```logs
```
