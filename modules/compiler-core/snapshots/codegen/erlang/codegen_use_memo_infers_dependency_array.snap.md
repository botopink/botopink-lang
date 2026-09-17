----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn state(initial: i32) -> @Context<Element, i32> {
    initial;
}
fn memo() -> @Context<Element, i32> {
    0;
}
fn Counter() -> Element {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Element: 

state(Initial) ->
    Initial.

memo() ->
    0.

'Counter'() ->
    #{count := Count, setCount := SetCount} = state(0),
    Doubled = memo(fun() ->
        (Count * 2)
    end),
    #{}.
```

----- RUN LOG -----
```logs
```
