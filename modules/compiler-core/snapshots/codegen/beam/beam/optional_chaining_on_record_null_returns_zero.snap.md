----- SOURCE CODE -- main.bp
```botopink
record R { a: i32, b: i32 }
fn pick(maybe: ?R) -> i32 {
    return maybe?.b;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 7}.

{function, pick, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, pick}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_eq, {f, 4}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 6}}.
  {label, 4}.
    {test, is_map, {f, 5}, [{x, 0}]}.
    {get_map_elements, {f, 5}, {x, 0}, {list, [{atom, b}, {x, 0}]}}.
    {jump, {f, 6}}.
  {label, 5}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 6}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
