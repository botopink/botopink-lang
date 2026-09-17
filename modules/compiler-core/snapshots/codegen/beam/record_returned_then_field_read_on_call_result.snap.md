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

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 7}.

{function, span, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, span}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, start}, {integer, 4}, {atom, 'end'}, {integer, 9}, {atom, line}, {integer, 2}]}}.
    {deallocate, 0}.
    return.

{function, lineNo, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, lineNo}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, line}, {x, 0}]}}.
  {label, 6}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
