----- SOURCE CODE -- main.bp
```botopink
fn describe() -> string {
    val items = ["a", "b", "c"];
    return case items {
        [] -> "empty";
        [x] -> "one";
        [first, ..rest] -> "many";
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, describe, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, describe}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 1}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"c">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_nil, {f, 5}, [{x, 0}]}.
    {move, {literal, <<"empty">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_nonempty_list, {f, 6}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {literal, <<"one">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_nonempty_list, {f, 7}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"many">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
  {label, 4}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
