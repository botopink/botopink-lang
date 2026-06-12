----- SOURCE CODE -- main.bp
```botopink
record Span { start: i32, end: i32, line: i32 }
fn span() -> Span {
    return Span(start: 4, end: 9, line: 2);
}
fn lineNo() -> i32 {
    return span().line;
}
```

----- ERLANG -- main.erl
```erlang
-module(main).

%% record Span: start, end, line

span() ->
    #{start => 4, 'end' => 9, line => 2}.

lineNo() ->
    maps:get(line, span()).
```

----- RUN LOG -----
```logs
```
