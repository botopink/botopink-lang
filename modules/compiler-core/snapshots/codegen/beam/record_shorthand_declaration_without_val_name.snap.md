----- SOURCE CODE -- main.bp
```botopink
type Vec2(
    x: f64,
    y: f64) {
    fn dot(self: Self, other: Vec2) -> f64 {
        return self.x * other.x + self.y * other.y;
    }
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, []}.
{attributes, []}.
{labels, 2}.
```

----- BEAM ASSEMBLY -- test@main@@Vec2.S
```erlang
{module, test@main@@Vec2}.
{exports, [{dot, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 14}.

{function, dot, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Vec2.erl", 1}]}.
    {func_info, {atom, test@main@@Vec2}, {atom, dot}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 5}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 6}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 7}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 9}.
  {label, 8}.
    {line, [{location, "test@main@@Vec2.erl", 2}]}.
    {func_info, {atom, test@main@@Vec2}, {atom, '__bp_get'}, 2}.
  {label, 9}.
    {test, is_eq_exact, {f, 10}, [{x, 1}, {atom, x}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 10}.
    {test, is_eq_exact, {f, 11}, [{x, 1}, {atom, y}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 11}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main@@Vec2.erl", 2}]}.
    {func_info, {atom, test@main@@Vec2}, {atom, '__bp_format'}, 1}.
  {label, 13}.
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
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Vec2">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
