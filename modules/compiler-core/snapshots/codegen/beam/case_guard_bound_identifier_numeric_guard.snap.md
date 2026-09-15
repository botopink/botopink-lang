----- SOURCE CODE -- main.bp
```botopink
fn classify(n: i32) -> string {
    return case n {
        x if x > 0 -> "positive";
        0 -> "zero";
        _ -> "negative";
    };
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
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 5}, [{integer, 0}, {y, 0}]}.
    {move, {literal, <<"positive">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {x, 1}, {x, 0}}.
    {test, is_eq, {f, 6}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
