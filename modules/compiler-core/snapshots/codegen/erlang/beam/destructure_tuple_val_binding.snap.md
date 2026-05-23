----- SOURCE CODE -- main.bp
```botopink
fn extract() {
    val #(a, b) = #(12, "hello");
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, extract, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, extract}, 0}.
  {label, 3}.
    {allocate, 1, 0}.
    {move, {integer, 12}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 0}, {x, 1}]}}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {move, {x, 1}, {y, 0}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
```
