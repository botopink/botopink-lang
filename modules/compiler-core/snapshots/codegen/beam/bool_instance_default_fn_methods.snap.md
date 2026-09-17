----- SOURCE CODE -- main.bp
```botopink
fn main() {
    @print(true.negate());
    @print(false.nor(false));
    @print(true.nand(true));
    @print(true.exclusiveOr(false));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 36}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "main.erl", 1}]}.
    {func_info, {atom, main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {atom, true}, {x, 0}}.
    {put_map_assoc, {f, 0}, {literal, #{}}, {x, 1}, 1, {list, [{atom, '__BpSelf'}, {x, 0}]}}.
    {move, {literal, <<"(not __BpSelf).">>}, {x, 0}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 12}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 21}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 12}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 23}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 12}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 12}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
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

{function, 'Bool_nor', 2, 21}.
  {label, 20}.
    {line, [{location, "main.erl", 4}]}.
    {func_info, {atom, main}, {atom, 'Bool_nor'}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 26}, [{y, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {atom, true}, {x, 0}}.
  {label, 27}.
    {test, is_eq, {f, 28}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {atom, true}, {x, 0}}.
  {label, 29}.
    {deallocate, 2}.
    return.

{function, 'Bool_nand', 2, 23}.
  {label, 22}.
    {line, [{location, "main.erl", 5}]}.
    {func_info, {atom, main}, {atom, 'Bool_nand'}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq, {f, 30}, [{y, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {atom, false}, {x, 0}}.
  {label, 31}.
    {test, is_eq, {f, 32}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, true}, {x, 0}}.
  {label, 33}.
    {deallocate, 2}.
    return.

{function, 'Bool_exclusiveOr', 2, 25}.
  {label, 24}.
    {line, [{location, "main.erl", 6}]}.
    {func_info, {atom, main}, {atom, 'Bool_exclusiveOr'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 34}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {atom, false}, {x, 0}}.
  {label, 35}.
    {deallocate, 2}.
    return.

{function, '__bp_erl_eval', 2, 9}.
  {label, 8}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_erl_eval'}, 2}.
  {label, 9}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {call_ext, 1, {extfunc, erl_scan, string, 1}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {call_ext, 1, {extfunc, erl_parse, parse_exprs, 1}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erl_eval, exprs, 2}}.
    {test, is_tagged_tuple, {f, 10}, [{x, 0}, 3, {atom, value}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 10}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 1}.

{function, '__bp_print', 1, 12}.
  {label, 11}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print'}, 1}.
  {label, 12}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 1, {f, 14}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '__bp_print_fmt', 1, 14}.
  {label, 13}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_fmt'}, 1}.
  {label, 14}.
    {test, is_nonempty_list, {f, 17}, [{x, 0}]}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {get_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 1}, {y, 0}}.
    {call, 1, {f, 16}}.
    {test, is_binary, {f, 18}, [{y, 0}]}.
    {test_heap, 6, 1}.
    {put_list, {integer, 115}, {x, 0}, {x, 0}}.
    {put_list, {integer, 116}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 18}.
    {test_heap, 4, 1}.
    {put_list, {integer, 112}, {x, 0}, {x, 0}}.
    {put_list, {integer, 126}, {x, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 17}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.

{function, '__bp_print_sep', 1, 16}.
  {label, 15}.
    {line, [{location, "main.erl", 2}]}.
    {func_info, {atom, main}, {atom, '__bp_print_sep'}, 1}.
  {label, 16}.
    {test, is_nonempty_list, {f, 19}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call, 1, {f, 14}}.
    {test_heap, 2, 1}.
    {put_list, {integer, 32}, {x, 0}, {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 19}.
    {move, {literal, [126, 110]}, {x, 0}}.
    return.
```

----- RUN LOG -----
```logs
false
true
false
true
```
