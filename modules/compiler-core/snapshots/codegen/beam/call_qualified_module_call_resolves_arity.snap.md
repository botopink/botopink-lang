----- SOURCE CODE -- main.bp
```botopink
type List(tag: i32) {
    fn map(items: i32[], f: fn(item: i32) -> i32) -> i32[] {
        return items.map(f);
    }
}
type Pipeline(
    items: i32[]) {
    fn run(self: Self, f: fn(item: i32) -> i32) -> i32[] {
        return List.map(self.items, f);
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
{exports, [{map, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, map, 2, 3}.
  {label, 2}.
    {line, [{location, "main__t__list.erl", 1}]}.
    {func_info, {atom, main__t__list}, {atom, map}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 2}.

{function, '__bp_get', 2, 5}.
  {label, 4}.
    {line, [{location, "main__t__list.erl", 2}]}.
    {func_info, {atom, main__t__list}, {atom, '__bp_get'}, 2}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, tag}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "main__t__list.erl", 2}]}.
    {func_info, {atom, main__t__list}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"tag">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"List">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- BEAM ASSEMBLY -- main__t__pipeline.S
```erlang
{module, main__t__pipeline}.
{exports, [{run, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, run, 2, 3}.
  {label, 2}.
    {line, [{location, "main__t__pipeline.erl", 2}]}.
    {func_info, {atom, main__t__pipeline}, {atom, run}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 2, {atom, main__t__pipeline}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, main__t__list, map, 2}, 2}.

{function, '__bp_get', 2, 6}.
  {label, 5}.
    {line, [{location, "main__t__pipeline.erl", 3}]}.
    {func_info, {atom, main__t__pipeline}, {atom, '__bp_get'}, 2}.
  {label, 6}.
    {test, is_eq_exact, {f, 7}, [{x, 1}, {atom, items}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 7}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "main__t__pipeline.erl", 3}]}.
    {func_info, {atom, main__t__pipeline}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"items">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Pipeline">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
