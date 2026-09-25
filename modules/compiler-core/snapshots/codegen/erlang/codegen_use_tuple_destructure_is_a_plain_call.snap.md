----- SOURCE CODE -- main.bp
```botopink
val Element = type implement @Context<Element, Element> { }
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Context<Element, #(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    #(base, push);
}
#[@context]
fn LikeWidget() -> Element {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% type Element: 

optimistic(Base, F) ->
    Push = fun(Action) ->
        F(Base, Action)
    end,
    {Base, Push}.

'LikeWidget'() ->
    {Shown, Push} = optimistic(12, fun(C, A) ->
        '__bp_add'(C, A)
    end),
    Push(Shown),
    {main__t__element}.

'__bp_add'(A, B) when is_binary(A), is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
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
