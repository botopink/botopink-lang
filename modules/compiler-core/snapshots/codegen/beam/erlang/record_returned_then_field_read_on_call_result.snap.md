----- SOURCE CODE -- main.bp
```botopink
type Span(start: i32, end: i32, line: i32)
fn span() -> Span {
    return Span(start: 4, end: 9, line: 2);
}
fn lineNo() -> i32 {
    return span().line;
}
```

----- ERLANG -- main.erl
```erlang
-module(test@main).

%% type Span: start, end, line

span() ->
    {test@main@@Span, 4, 9, 2}.

lineNo() ->
    erlang:element(4, span()).
```

----- ERLANG -- test@main@@Span.erl
```erlang
-module(test@main@@Span).
-export(['__bp_get'/2, '__bp_format'/1]).

'__bp_get'(V, start) -> erlang:element(2, V);
'__bp_get'(V, 'end') -> erlang:element(3, V);
'__bp_get'(V, line) -> erlang:element(4, V).

'__bp_format'(V) -> {record, "Span", [{"start", erlang:element(2, V)}, {"end", erlang:element(3, V)}, {"line", erlang:element(4, V)}]}.
```

----- RUN LOG -----
```logs
```
