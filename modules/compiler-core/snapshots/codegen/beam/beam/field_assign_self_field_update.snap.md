----- SOURCE CODE -- main.bp
```botopink
val Counter = struct {
    count: i32 = 0,
    fn inc() {
        self.count += 1;
    }
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 4}.

{function, 'Counter_inc', 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Counter_inc'}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 0}}.
    {move, {atom, self}, {x, 0}}.
    {put_map_exact, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, count}, {x, 0}]}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
