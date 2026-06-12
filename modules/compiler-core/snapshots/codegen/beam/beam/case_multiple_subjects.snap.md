----- SOURCE CODE -- main.bp
```botopink
fn process(a: i32, b: i32) {
    case a, b {
        0, 0 -> null;
        _, _ -> null;
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 7}.

{function, process, 2, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, process}, 2}.
  {label, 3}.
    {allocate, 0, 2}.
    {test, is_eq, {f, 5}, [{x, 0}, {integer, 0}]}.
    {test, is_eq, {f, 5}, [{x, 1}, {integer, 0}]}.
    {move, {atom, nil}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {atom, nil}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
  {label, 4}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
