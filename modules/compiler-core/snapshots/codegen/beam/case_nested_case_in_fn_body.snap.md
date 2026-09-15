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
{labels, 10}.

{function, process, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, process}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {test, is_eq, {f, 5}, [{x, 0}, {integer, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 1}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {jump, {f, 4}}.
  {label, 5}.
    {move, {literal, <<"non-zero">>}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 0}.
    return.

{function, '-process/1-fun-0-', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-process/1-fun-0-'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {atom, x}, {x, 0}}.
    {test, is_eq, {f, 9}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {jump, {f, 8}}.
  {label, 9}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
