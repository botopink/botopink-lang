----- SOURCE CODE -- main.bp
```botopink
enum Token {
    Color {
        Red { 100, 500 }
    }
}
fn red500() -> Token {
    return .Color.Red.500;
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, red500, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, red500}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {atom, '__500'}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, 'Red'}, {x, 0}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, 'Color'}, {x, 0}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
