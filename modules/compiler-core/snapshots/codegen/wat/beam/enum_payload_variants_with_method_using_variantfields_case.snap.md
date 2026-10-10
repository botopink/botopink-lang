----- SOURCE CODE -- main.bp
```botopink
val Shape = type {
    Circle(radius: f64),
    Square(side: f64),
    Triangle(base: f64, height: f64),
    fn area(shape: Self) -> f64 {
        return case shape {
            Circle(radius) -> radius * radius * 3.14;
            Square(side) -> side * side;
            Triangle(base, height) -> base * height * 0.5;
            _ -> 0.0;
        };
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

----- BEAM ASSEMBLY -- test@main@@Shape.S
```erlang
{module, test@main@@Shape}.
{exports, [{area, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 13}.

{function, area, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main@@Shape.erl", 1}]}.
    {func_info, {atom, test@main@@Shape}, {atom, area}, 1}.
  {label, 3}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 5}, [{x, 0}, 2, {atom, test@main@@Shape__v__circle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 1}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 3.14}], {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, test@main@@Shape__v__square}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 2}], {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 3, {atom, test@main@@Shape__v__triangle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {y, 4}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {float, 0.5}], {x, 0}}.
    {jump, {f, 4}}.
  {label, 7}.
    {move, {float, 0.0}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 4}.
    {deallocate, 5}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "test@main@@Shape.erl", 2}]}.
    {func_info, {atom, test@main@@Shape}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 2, {atom, test@main@@Shape__v__circle}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"radius">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Shape.Circle">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 10}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 11}, [{x, 0}, 2, {atom, test@main@@Shape__v__square}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"side">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Shape.Square">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 11}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 3, {atom, test@main@@Shape__v__triangle}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"height">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"base">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Shape.Triangle">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 12}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Shape">>}, nil]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
```
