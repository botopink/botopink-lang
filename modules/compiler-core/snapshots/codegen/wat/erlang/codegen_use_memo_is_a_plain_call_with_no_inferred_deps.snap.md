----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Context<Element>
fn state(initial: i32) -> @Component<Element, i32> {
    return initial;
}
fn memo() -> @Component<Element, i32> {
    return 0;
}
fn Counter() -> @Component<Element, Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

state(Initial) ->
    Initial.

memo() ->
    0.

'Counter'() ->
    #{count := Count, setCount := SetCount} = state(0),
    Doubled = memo(fun() ->
        '__bp_int'((Count * 2), -2147483648, 2147483647, <<"integer overflow: * on i32 at main.bp:10:46">>)
    end),
    {test@main@@Element}.

-compile({inline,['__bp_int'/4]}).
'__bp_int'(V, Lo, Hi, _) when V >= Lo, V =< Hi -> V;
'__bp_int'(_, _, _, What) -> erlang:error({integer_overflow, What}).
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
