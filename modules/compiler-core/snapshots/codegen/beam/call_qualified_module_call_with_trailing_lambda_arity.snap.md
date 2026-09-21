----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn each(items: i32[], f: fn() -> i32) -> i32[] {
        return items;
    }
}
type Pipeline(
    items: i32[]) {
    fn doubled(self: Self) -> i32[] {
        return List.each(self.items) { ->
            return 2;
        };
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- main__t__list.S
```erlang
{module, main__t__list}.
{exports, [{each, 2}]}.
{attributes, []}.
{labels, 4}.

{function, each, 2, 3}.
  {label, 2}.
    {line, [{location, "main__t__list.erl", 1}]}.
    {func_info, {atom, main__t__list}, {atom, each}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- main__t__pipeline.S
```erlang
{module, main__t__pipeline}.
{exports, [{doubled, 1}]}.
{attributes, []}.
{labels, 7}.

{function, doubled, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__pipeline.erl", 2}]}.
    {func_info, {atom, main__t__pipeline}, {atom, doubled}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 4}, [{x, 0}]}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, items}, {x, 0}]}}.
  {label, 4}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 6}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext_last, 2, {extfunc, list, each, 2}, 1}.

{function, '-/1-fun-0-', 0, 6}.
  {label, 5}.
    {line, [{location, "main__t__pipeline.erl", 3}]}.
    {func_info, {atom, main__t__pipeline}, {atom, '-/1-fun-0-'}, 0}.
  {label, 6}.
    {allocate, 0, 0}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.
```

----- RUN LOG -----
```logs
```
