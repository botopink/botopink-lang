----- SOURCE CODE -- main.bp
```botopink
val Vec2 = type(
    x: f64,
    y: f64) {
    fn lengthSq(self: Self) -> f64 {
        return self.x * self.x + self.y * self.y;
    }
    fn scale(self: Self, factor: f64) -> f64 {
        return self.x * factor;
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
{exports, [{lengthSq, 1}, {scale, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 17}.

{function, lengthSq, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Vec2.erl", 1}]}.
    {func_info, {atom, test@main@@Vec2}, {atom, lengthSq}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 6}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 7}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 8}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 9}.
    {gc_bif, '*', {f, 0}, 3, [{x, 2}, {x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, scale, 2, 5}.
  {label, 4}.
    {line, [{location, "test@main@@Vec2.erl", 2}]}.
    {func_info, {atom, test@main@@Vec2}, {atom, scale}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 3, {atom, test@main@@Vec2}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 10}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 12}.
  {label, 11}.
    {line, [{location, "test@main@@Vec2.erl", 3}]}.
    {func_info, {atom, test@main@@Vec2}, {atom, '__bp_get'}, 2}.
  {label, 12}.
    {test, is_eq_exact, {f, 13}, [{x, 1}, {atom, x}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 13}.
    {test, is_eq_exact, {f, 14}, [{x, 1}, {atom, y}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 14}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 16}.
  {label, 15}.
    {line, [{location, "test@main@@Vec2.erl", 3}]}.
    {func_info, {atom, test@main@@Vec2}, {atom, '__bp_format'}, 1}.
  {label, 16}.
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
