----- SOURCE CODE -- main.bp
```botopink
val Element = type() implement @Renderable
fn state(initial: i32) -> @Component<i32> {
    return initial;
}
fn memo() -> @Component<i32> {
    return 0;
}
fn Counter() -> @Component<Element> {
    val {count, setCount} = use state(0);
    val doubled = use memo { -> return count * 2; };
    return Element();
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Element: 

state(BpContextMap__, Initial) ->
    Initial.

memo(BpContextMap__) ->
    0.

'Counter'(BpContextMap__) ->
    #{count := Count, setCount := SetCount} = state(BpContextMap__, 0),
    Doubled = memo(BpContextMap__, fun() ->
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
