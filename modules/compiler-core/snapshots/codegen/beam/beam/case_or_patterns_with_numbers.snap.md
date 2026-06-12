----- SOURCE CODE -- main.bp
```botopink
fn classify(day: i32) -> string {
    val kind = case day {
        6 | 7 -> "weekend";
        _ -> "weekday";
    };
    @print(kind);
    return kind;
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
    {test, is_ne_exact, {f, 5}, [{x, 0}, {integer, 6}]}.
    {test, is_ne_exact, {f, 5}, [{x, 0}, {integer, 7}]}.
    {jump, {f, 6}}.
  {label, 5}.
    {move, {literal, <<"weekend">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {move, {literal, <<"weekday">>}, {x, 0}}.
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
