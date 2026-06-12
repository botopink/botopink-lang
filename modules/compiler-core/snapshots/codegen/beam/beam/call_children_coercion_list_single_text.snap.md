----- SOURCE CODE -- main.bp
```botopink
fn node() -> string { return "n"; }
fn box(children: Children) -> string { return "x"; }
val many = box([node(), node()]);
val one = box(node());
val txt = box("hi");
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 12}.

{function, node, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, node}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"n">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, box, 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, box}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, many, 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, many}, 0}.
  {label, 7}.
    {move, nil, {x, 0}}.
    {test_heap, 4, 1}.
    {move, {x, 0}, {x, 1}}.
    {call, 0, {f, 3}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {call, 0, {f, 3}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 0}.
    return.

{function, one, 0, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, one}, 0}.
  {label, 9}.
    {call, 0, {f, 3}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 0}.
    return.

{function, txt, 0, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, txt}, 0}.
  {label, 11}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
