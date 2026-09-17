----- SOURCE CODE -- main.bp
```botopink
pub type Shape {
    Circle(radius: i32),
    Square(side: i32),

    pub fn area(self: Self) -> i32 {
        return case self {
            Circle(r) -> r * r * 3;
            Square(s) -> s * s;
        };
    }
}

pub fn main() {
    @print(Shape.Square(side: 4).area());
    @print(Shape.Circle(radius: 2).area());
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'Shape_area', 1}, {main, 0}]}.
{attributes, []}.
{labels, 22}.

{function, 'Shape_area', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Shape_area'}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 11}, [{x, 0}, 2, {atom, 'Circle'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {y, 1}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 3}], {x, 0}}.
    {jump, {f, 10}}.
  {label, 11}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 2, {atom, 'Square'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 2}], {x, 0}}.
    {jump, {f, 10}}.
  {label, 12}.
  {label, 10}.
    {deallocate, 3}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, 'Square'}, {integer, 4}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 14}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, 'Circle'}, {integer, 2}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 14}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '__bp_print', 1, 14}.
  {label, 13}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 14}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 16}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 16}.
  {label, 15}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 16}.
    {test, is_nonempty_list, {f, 19}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 18}}.
    {test, is_binary, {f, 20}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 20}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 19}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 18}.
  {label, 17}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 18}.
    {test, is_nonempty_list, {f, 21}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 16}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 21}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
16
12
```
