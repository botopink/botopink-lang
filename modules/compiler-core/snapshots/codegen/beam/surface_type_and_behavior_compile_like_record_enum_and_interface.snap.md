----- SOURCE CODE -- main.bp
```botopink
behavior Shape {
    fn area(self: Self) -> i32;
}

type Square(side: i32) implement Shape {
    fn area(self: Self) -> i32 {
        return self.side * self.side;
    }
}

type Size { Small, Large(n: i32) }

fn weight(s: Size) -> i32 {
    return case s {
        Small -> 1;
        Large(n) -> n;
    };
}

fn main() {
    val sq = Square(side: 3);
    @print(sq.area());
    @print(weight(Size.Large(n: 5)) + weight(Size.Small));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 26}.

{function, weight, 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, weight}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 11}, [{x, 0}, {atom, 'Small'}]}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 10}}.
  {label, 11}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 2, {atom, 'Large'}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 10}}.
  {label, 12}.
  {label, 10}.
    {deallocate, 3}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 0, {list, [{atom, side}, {integer, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, main__t__square, area, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 14}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, 'Large'}, {integer, 5}]}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, 'Small'}, {x, 0}}.
    {call, 1, {f, 3}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 14}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '_botopink_main', 0, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, main, 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 9}.
    {call_only, 0, {f, 7}}.

{function, '__bp_print', 1, 14}.
  {label, 13}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 14}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 18}.
  {label, 17}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-bp_show_top-'}, 1}.
  {label, 18}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 16}}.

{function, '-bp_show_elem-', 1, 20}.
  {label, 19}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 20}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 16}}.

{function, '__bp_show', 2, 16}.
  {label, 15}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '__bp_show'}, 2}.
  {label, 16}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 22}, [{x, 0}]}.
    {test, is_eq, {f, 21}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 23}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 25}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 24}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 24}, [{x, 0}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
```

----- BEAM ASSEMBLY -- main__t__square.S
```erlang
{module, main__t__square}.
{exports, [{area, 1}]}.
{attributes, []}.
{labels, 6}.

{function, area, 1, 3}.
  {label, 2}.
    {line, [{location, "main__t__square.erl", 1}]}.
    {func_info, {atom, main__t__square}, {atom, area}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 4}, [{x, 0}]}.
    {get_map_elements, {f, 4}, {x, 0}, {list, [{atom, side}, {x, 0}]}}.
  {label, 4}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 5}, [{x, 0}]}.
    {get_map_elements, {f, 5}, {x, 0}, {list, [{atom, side}, {x, 0}]}}.
  {label, 5}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.
```

----- RUN LOG -----
```logs
9
6
```
