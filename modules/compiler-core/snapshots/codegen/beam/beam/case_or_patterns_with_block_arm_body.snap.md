----- SOURCE CODE -- main.bp
```botopink
val parity = case 5 {
    0 | 2 | 4 -> "even";
    _      -> {
        val value = "odd";
        break value;
    };
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 9}.

{function, parity, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, parity}, 0}.
  {label, 3}.
    {move, {integer, 5}, {x, 0}}.
    {test, is_ne_exact, {f, 5}, [{x, 0}, {integer, 0}]}.
    {test, is_ne_exact, {f, 5}, [{x, 0}, {integer, 2}]}.
    {test, is_ne_exact, {f, 5}, [{x, 0}, {integer, 4}]}.
    {jump, {f, 6}}.
  {label, 5}.
    {move, {literal, <<"even">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 8}, 0, 0, {x, 0}, {list, []}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 0}.
    return.

{function, '-/0-fun-0-', 0, 8}.
  {label, 7}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-/0-fun-0-'}, 0}.
  {label, 8}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, <<"odd">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
