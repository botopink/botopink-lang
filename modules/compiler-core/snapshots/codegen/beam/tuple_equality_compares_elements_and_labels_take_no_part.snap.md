----- SOURCE CODE -- main.bp
```botopink
fn main() {
    val a = #(1, "a");
    val b = #(1, "a");
    @print(a == b);
    @print(a != b);
    val c = #(1, "b");
    @print(a == c);
    val name = "SP";
    val pop = 12;
    val labeled = #(name, pop);
    val plain = #("SP", 12);
    @print(labeled == plain);
    val n1 = #(#(1, 2), "x");
    val n2 = #(#(1, 2), "x");
    val n3 = #(#(1, 3), "x");
    @print(n1 == n2);
    @print(n1 == n3);
    val f1 = #(1.5, true);
    val f2 = #(1.5, true);
    val f3 = #(1.5, false);
    @print(f1 == f2);
    @print(f1 == f3);
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 33}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 13, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq, {f, 8}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
    {move, {atom, false}, {x, 0}}.
  {label, 9}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_ne_exact, {f, 19}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 20}}.
  {label, 19}.
    {move, {atom, false}, {x, 0}}.
  {label, 20}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {test, is_eq, {f, 21}, [{y, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 22}}.
  {label, 21}.
    {move, {atom, false}, {x, 0}}.
  {label, 22}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {literal, <<"SP">>}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 12}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"SP">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{x, 0}, {integer, 12}]}}.
    {move, {x, 0}, {y, 6}}.
    {test, is_eq, {f, 23}, [{y, 5}, {y, 6}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 23}.
    {move, {atom, false}, {x, 0}}.
  {label, 24}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {integer, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 9}}.
    {test, is_eq, {f, 25}, [{y, 7}, {y, 8}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {atom, false}, {x, 0}}.
  {label, 26}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_eq, {f, 27}, [{y, 7}, {y, 9}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {atom, false}, {x, 0}}.
  {label, 28}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{float, 1.5}, {x, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{float, 1.5}, {x, 0}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{float, 1.5}, {x, 0}]}}.
    {move, {x, 0}, {y, 12}}.
    {test, is_eq, {f, 29}, [{y, 10}, {y, 11}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {atom, false}, {x, 0}}.
  {label, 30}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_eq, {f, 31}, [{y, 10}, {y, 12}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 32}}.
  {label, 31}.
    {move, {atom, false}, {x, 0}}.
  {label, 32}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 11}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {call_only, 0, {f, 3}}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "main.erl", 3}]}.
    {func_info, {atom, main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, '__bp_print', 1, 11}.
  {label, 10}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 13}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 13}.
  {label, 12}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 13}.
    {test, is_nonempty_list, {f, 16}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 15}}.
    {test, is_binary, {f, 17}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 17}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 16}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 15}.
  {label, 14}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 15}.
    {test, is_nonempty_list, {f, 18}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 18}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
true
false
false
true
true
false
true
false
```
