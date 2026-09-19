----- SOURCE CODE -- main.bp
```botopink
fn process(x: i32) -> string {
    return case (x) {
        0 -> {
            break case (x) {
                0 -> "zero";
                _ -> "other";
            };
        };
        _ -> "non-zero";
    };
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 8}.

{function, process, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, process}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 7}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {jump, {f, 6}}.
  {label, 7}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {jump, {f, 6}}.
  {label, 6}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {literal, <<"non-zero">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
