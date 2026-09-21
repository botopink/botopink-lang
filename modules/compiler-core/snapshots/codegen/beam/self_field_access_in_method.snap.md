----- SOURCE CODE -- main.bp
```botopink
val Point = type(
    x: i32,
    y: i32) {
    fn sum() -> i32 {
        return self.x + self.y;
    }
};
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- main__t__point.S
```erlang
{module, main__t__point}.
{exports, [{sum, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 15}.

{function, sum, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__point.erl", 1}]}.
    {func_info, {atom, main__t__point}, {atom, sum}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 3, {atom, main__t__point}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 3, {atom, main__t__point}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 5}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 7}}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 10}.
  {label, 9}.
    {line, [{location, "main__t__point.erl", 2}]}.
    {func_info, {atom, main__t__point}, {atom, '__bp_get'}, 2}.
  {label, 10}.
    {test, is_eq_exact, {f, 11}, [{x, 1}, {atom, x}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 11}.
    {test, is_eq_exact, {f, 12}, [{x, 1}, {atom, y}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 12}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 14}.
  {label, 13}.
    {line, [{location, "main__t__point.erl", 2}]}.
    {func_info, {atom, main__t__point}, {atom, '__bp_format'}, 1}.
  {label, 14}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"y">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"x">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Point">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_add', 2, 7}.
  {label, 6}.
    {line, [{location, "main__t__point.erl", 2}]}.
    {func_info, {atom, main__t__point}, {atom, '__bp_add'}, 2}.
  {label, 7}.
    {test, is_binary, {f, 8}, [{x, 0}]}.
    {test, is_binary, {f, 8}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 8}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
```
