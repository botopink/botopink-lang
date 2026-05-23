----- SOURCE CODE -- main.bp
```botopink
val add = { x, y ->
    x + y;
};
val result = add(10, 20);
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, add, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, add}, 0}.
  {label, 3}.
    {make_fun2, {f, 7}, 0, 0, 0}.
    {deallocate, 0}.
    return.

{function, result, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, result}, 0}.
  {label, 5}.
    {move, {integer, 10}, {x, 0}}.
    {move, {integer, 20}, {x, 1}}.
    %% unresolved local call: add/2
    {deallocate, 0}.
    return.

{function, '-/0-fun-0-', 2, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-/0-fun-0-'}, 2}.
  {label, 7}.
    {allocate, 0, 2}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
