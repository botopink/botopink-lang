----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    val result = case n {
        0 -> "zero";
        1 -> "one";
        _ -> "many";
    };
    @print(result);
    return result;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 7}.

{function, classify, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, classify}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {test, is_eq, {f, 5}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_eq, {f, 6}, [{x, 0}, {integer, 1}]}.
    {move, {literal, <<"one">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {move, {literal, <<"many">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"~p~n">>}, {x, 0}}.
    {test_heap, 2, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
