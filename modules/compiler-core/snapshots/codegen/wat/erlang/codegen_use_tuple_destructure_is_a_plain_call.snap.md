----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn optimistic(base: i32, f: fn(current: i32, action: i32) -> i32) -> @Component<#(i32, fn(action: i32) -> i32)> {
    val push = { action -> f(base, action) };
    return #(base, push);
}
fn LikeWidget() -> @Component<Element> {
    val #(shown, push) = use optimistic(12, { c, a -> c + a });
    push(shown);
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

optimistic(BpContextMap__, Base, F) ->
    Push = fun(Action) ->
        F(Base, Action)
    end,
    {Base, Push}.

'LikeWidget'(BpContextMap__) ->
    {Shown, Push} = optimistic(BpContextMap__, 12, fun(C, A) ->
        '__bp_add'(C, A)
    end),
    Push(Shown),
    {test@main@@Element}.

'__bp_add'(A, B) when erlang:is_binary(A), erlang:is_binary(B) -> <<A/binary, B/binary>>;
'__bp_add'(A, B) -> A + B.
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
