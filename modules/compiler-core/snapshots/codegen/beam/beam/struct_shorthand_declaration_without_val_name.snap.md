----- SOURCE CODE -- main.bp
```botopink
struct Counter {
    _count: i32 = 0,
    fn increment(self: Self) {
        self._count += 1;
    }
    get count(self: Self) -> i32 {
        return self._count;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'Counter_count', 1}]}.
{attributes, []}.
{labels, 7}.

{function, 'Counter_increment', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Counter_increment'}, 1}.
  {label, 3}.
    {allocate, 0, 1}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {put_map_exact, {f, 0}, {x, 0}, {x, 0}, 2, {list, [{atom, _count}, {x, 1}]}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, 'Counter_count', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Counter_count'}, 1}.
  {label, 5}.
    {allocate, 0, 1}.
    {test, is_map, {f, 6}, [{x, 0}]}.
    {get_map_elements, {f, 6}, {x, 0}, {list, [{atom, '_count'}, {x, 0}]}}.
  {label, 6}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
