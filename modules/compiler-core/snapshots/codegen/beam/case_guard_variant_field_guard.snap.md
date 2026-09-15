----- SOURCE CODE -- main.bp
```botopink
val Shape = enum {
    Circle(r: i32),
    Square(s: i32),
}
fn big(sh: Shape) -> string {
    return case sh {
        Circle(r) if r > 10 -> "big circle";
        _ -> "other";
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 7}.

{function, big, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, big}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, 'Circle'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 6}, [{integer, 10}, {y, 0}]}.
    {move, {literal, <<"big circle">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {move, {x, 1}, {x, 0}}.
  {label, 5}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
