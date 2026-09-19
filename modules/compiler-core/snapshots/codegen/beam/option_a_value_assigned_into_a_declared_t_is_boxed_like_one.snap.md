----- SOURCE CODE -- main.bp
```botopink
type Box(items: Array<i32>) {
    fn total(self: Self) -> i32 {
        var sum = 0;
        self.items.forEach({ n -> sum = sum + n });
        return sum;
    }
    fn isBig(self: Self) -> bool { return self.items.length > 1; }
    fn doubled(self: Self) -> Array<i32> { return self.items.map({ n -> n * 2 }); }
    fn label(self: Self) -> string { return "box"; }
}
fn main() {
    var seen = 0;
    [1, 2].forEach({ n -> seen = n });
    @print(seen);
    val b = Box(items: [3, 4]);
    @print(b.total());
    var h: ?i32 = null;
    @print(h);
    h = 5;
    @print(h);
    var acc: ?i32 = null;
    [7, 8].forEach({ n -> acc = n });
    @print(acc);
    @print(b.isBig());
    @print(b.doubled());
    @print(b.label());
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 38}.

{function, 'Box_total', 1, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, 'Box_total'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 18}, [{x, 0}]}.
    {get_map_elements, {f, 18}, {x, 0}, {list, [{atom, items}, {x, 0}]}}.
  {label, 18}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, 'Box_isBig', 1, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, 'Box_isBig'}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 19}, [{x, 0}]}.
    {get_map_elements, {f, 19}, {x, 0}, {list, [{atom, items}, {x, 0}]}}.
  {label, 19}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 20}, [{integer, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, false}, {x, 0}}.
  {label, 21}.
    {deallocate, 1}.
    return.

{function, 'Box_doubled', 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, 'Box_doubled'}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_map, {f, 22}, [{x, 0}]}.
    {get_map_elements, {f, 22}, {x, 0}, {list, [{atom, items}, {x, 0}]}}.
  {label, 22}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
    {call_ext_last, 2, {extfunc, lists, map, 2}, 1}.

{function, 'Box_label', 1, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, 'Box_label'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"box">>}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 7, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 26}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 0}, 1, {list, [{atom, items}, {x, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 8}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 7}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 7}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '-/1-fun-0-', 2, 17}.
  {label, 16}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '-/1-fun-0-'}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-/1-fun-1-', 1, 24}.
  {label, 23}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, '-/1-fun-1-'}, 1}.
  {label, 24}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-2-', 2, 26}.
  {label, 25}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-2-'}, 2}.
  {label, 26}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 28}.
  {label, 27}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 28}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 30}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 30}.
  {label, 29}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 30}.
    {test, is_nonempty_list, {f, 33}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 32}}.
    {test, is_binary, {f, 34}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 34}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 33}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 32}.
  {label, 31}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 32}.
    {test, is_nonempty_list, {f, 35}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 30}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 35}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '-main/0-fun-3-', 2, 37}.
  {label, 36}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, '-main/0-fun-3-'}, 2}.
  {label, 37}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
2
7
undefined
5
8
true
[6,8]
box
```
