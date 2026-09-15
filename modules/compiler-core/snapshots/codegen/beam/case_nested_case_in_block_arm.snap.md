----- SOURCE CODE -- main.bp
```botopink
val result = case 42 {
    0 -> {
      case 1 {
          0    -> 54;
          _ -> 1;
      };
   };
   _ -> 1;
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 10}.

{function, result, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, result}, 0}.
  {label, 3}.
    {move, {integer, 42}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {integer, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 0}.
    return.

{function, '-/0-fun-0-', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-/0-fun-0-'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {test, is_eq, {f, 9}, [{x, 0}, {integer, 0}]}.
    {move, {integer, 54}, {x, 0}}.
    {jump, {f, 8}}.
  {label, 9}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
