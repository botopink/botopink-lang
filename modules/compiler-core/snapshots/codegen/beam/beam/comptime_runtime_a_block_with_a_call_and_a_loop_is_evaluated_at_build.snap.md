----- SOURCE CODE -- main.bp
```botopink
fn add(a: i32, b: i32) -> i32 {
    return a + b;
}

fn two() -> i32 {
    return 2;
}

fn main() {
    val a = comptime two();
    @print(a);
    val d = comptime {
        var d = 0;
        for ([1, 2, 3]) { b -> d = add(d, b); }
        break d;
    };
    @print(d);
}
```

----- COMPTIME BEAM ASSEMBLY -- comptime block
```erlang
{module, comptime_module}.
{exports, [{main, 1}]}.
{attributes, []}.
{labels, 67}.

{function, '__bp_ct_value', 0, 2}.
  {label, 1}.
    {func_info, {atom, comptime_module}, {atom, '__bp_ct_value'}, 0}.
  {label, 2}.
    {allocate, 0, 0}.
    {call_last, 0, {f, 4}, 0}.

{function, two, 0, 4}.
  {label, 3}.
    {func_info, {atom, comptime_module}, {atom, two}, 0}.
  {label, 4}.
    {allocate, 0, 0}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 1, 6}.
  {label, 5}.
    {func_info, {atom, comptime_module}, {atom, main}, 1}.
  {label, 6}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {'try', {y, 8}, {f, 19}}.
    {call, 0, {f, 2}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 8}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"value">>}, {atom, value}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {try_end, {y, 8}}.
    {jump, {f, 20}}.
  {label, 19}.
    {try_case, {y, 8}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 21}}.
  {label, 21}.
  {label, 20}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_fns', 0, 8}.
  {label, 7}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fns'}, 0}.
  {label, 8}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-__bp_lift/2-fun-0-', 3, 54}.
  {label, 53}.
    {func_info, {atom, comptime_module}, {atom, '-__bp_lift/2-fun-0-'}, 3}.
  {label, 54}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {x, 2}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 10}, 3}.

{function, '__bp_lift', 2, 10}.
  {label, 9}.
    {func_info, {atom, comptime_module}, {atom, '__bp_lift'}, 2}.
  {label, 10}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 28}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 30}.
    {move, {y, 1}, {x, 0}}.
    {test, is_integer, {f, 31}, [{x, 0}]}.
    {jump, {f, 32}}.
  {label, 32}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 31}.
    {move, {y, 1}, {x, 0}}.
    {test, is_float, {f, 33}, [{x, 0}]}.
    {jump, {f, 34}}.
  {label, 34}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"float">>}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 33}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 35}, [{x, 0}]}.
    {jump, {f, 36}}.
  {label, 36}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 35}.
    {move, {y, 1}, {x, 0}}.
    {test, is_atom, {f, 37}, [{x, 0}]}.
    {jump, {f, 38}}.
  {label, 38}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"atom">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 37}.
    {move, {y, 1}, {x, 0}}.
    {test, is_list, {f, 39}, [{x, 0}]}.
    {jump, {f, 40}}.
  {label, 40}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {y, 4}}.
  {label, 42}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 43}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 42}}.
  {label, 43}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 44}, [{x, 0}]}.
    {jump, {f, 41}}.
  {label, 44}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 41}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 39}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 45}, [{x, 0}]}.
    {jump, {f, 46}}.
  {label, 46}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 4}}.
  {label, 48}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 49}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 4}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 48}}.
  {label, 49}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 50}, [{x, 0}]}.
    {jump, {f, 47}}.
  {label, 50}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 47}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"tuple">>}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 45}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 51}, [{x, 0}]}.
    {jump, {f, 52}}.
  {label, 52}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, map, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"record">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 51}.
    {move, {y, 1}, {x, 0}}.
    {test, is_function, {f, 57}, [{x, 0}]}.
    {jump, {f, 58}}.
  {label, 58}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 12}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"fn">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 57}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"resource">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_fn_index', 2, 12}.
  {label, 11}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fn_index'}, 2}.
  {label, 12}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, nil]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 63}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 64}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 64}, [{x, 0}]}.
    {test, test_arity, {f, 64}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {x, 1}]}.
    {jump, {f, 65}}.
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 64}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 66}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 12}, 8}.
  {label, 66}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.
```

----- COMPTIME REPLY -- comptime block
```json
{
  "kind": "value",
  "value": 2
}
```

----- COMPTIME BEAM ASSEMBLY -- comptime block
```erlang
{module, comptime_module}.
{exports, [{main, 1}]}.
{attributes, []}.
{labels, 77}.

{function, '-__bp_ct_value/0-fun-0-', 2, 18}.
  {label, 17}.
    {func_info, {atom, comptime_module}, {atom, '-__bp_ct_value/0-fun-0-'}, 2}.
  {label, 18}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 4}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 22}}.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ct_value', 0, 2}.
  {label, 1}.
    {func_info, {atom, comptime_module}, {atom, '__bp_ct_value'}, 0}.
  {label, 2}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 0}, {y, 0}}.
    {jump, {f, 16}}.
  {label, 16}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 18}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {literal, [1, 2, 3]}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {y, 0}}.
    {jump, {f, 24}}.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, add, 2, 4}.
  {label, 3}.
    {func_info, {atom, comptime_module}, {atom, add}, 2}.
  {label, 4}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, bp_comptime_decorator, '__bp_add', 2}, 2}.

{function, main, 1, 6}.
  {label, 5}.
    {func_info, {atom, comptime_module}, {atom, main}, 1}.
  {label, 6}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {'try', {y, 8}, {f, 29}}.
    {call, 0, {f, 2}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 8}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"value">>}, {atom, value}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {try_end, {y, 8}}.
    {jump, {f, 30}}.
  {label, 29}.
    {try_case, {y, 8}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 2}, {y, 6}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"error">>}, {atom, message}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 3}}.
    {jump, {f, 31}}.
  {label, 31}.
  {label, 30}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_fns', 0, 8}.
  {label, 7}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fns'}, 0}.
  {label, 8}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-__bp_lift/2-fun-1-', 3, 64}.
  {label, 63}.
    {func_info, {atom, comptime_module}, {atom, '-__bp_lift/2-fun-1-'}, 3}.
  {label, 64}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {x, 2}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 10}, 3}.

{function, '__bp_lift', 2, 10}.
  {label, 9}.
    {func_info, {atom, comptime_module}, {atom, '__bp_lift'}, 2}.
  {label, 10}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 38}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 39}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 40}.
    {move, {y, 1}, {x, 0}}.
    {test, is_integer, {f, 41}, [{x, 0}]}.
    {jump, {f, 42}}.
  {label, 42}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 41}.
    {move, {y, 1}, {x, 0}}.
    {test, is_float, {f, 43}, [{x, 0}]}.
    {jump, {f, 44}}.
  {label, 44}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"float">>}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 43}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 45}, [{x, 0}]}.
    {jump, {f, 46}}.
  {label, 46}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 45}.
    {move, {y, 1}, {x, 0}}.
    {test, is_atom, {f, 47}, [{x, 0}]}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"atom">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 47}.
    {move, {y, 1}, {x, 0}}.
    {test, is_list, {f, 49}, [{x, 0}]}.
    {jump, {f, 50}}.
  {label, 50}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {y, 4}}.
  {label, 52}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 53}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 52}}.
  {label, 53}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 54}, [{x, 0}]}.
    {jump, {f, 51}}.
  {label, 54}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 51}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 49}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 55}, [{x, 0}]}.
    {jump, {f, 56}}.
  {label, 56}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 4}}.
  {label, 58}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 59}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 4}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 58}}.
  {label, 59}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 60}, [{x, 0}]}.
    {jump, {f, 57}}.
  {label, 60}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 57}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"tuple">>}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 55}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 61}, [{x, 0}]}.
    {jump, {f, 62}}.
  {label, 62}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 64}, 1, 0, {x, 0}, {list, [{y, 2}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, maps, map, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"record">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 61}.
    {move, {y, 1}, {x, 0}}.
    {test, is_function, {f, 67}, [{x, 0}]}.
    {jump, {f, 68}}.
  {label, 68}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 12}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"fn">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 67}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"resource">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_fn_index', 2, 12}.
  {label, 11}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fn_index'}, 2}.
  {label, 12}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, nil]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 73}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 74}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 74}, [{x, 0}]}.
    {test, test_arity, {f, 74}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {x, 1}]}.
    {jump, {f, 75}}.
  {label, 75}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 74}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 76}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 12}, 8}.
  {label, 76}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.
```

----- COMPTIME REPLY -- comptime block
```json
{
  "kind": "value",
  "value": 6
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}]}.
{attributes, []}.
{labels, 40}.

{function, add, 2, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, add}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 12}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 12}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at test@main.bp:2:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 13}.
    {deallocate, 2}.
    return.

{function, two, 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, two}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 15}}.
    {move, {integer, 6}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 15}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '__bp_print', 1, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 19}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 17}}.

{function, '-bp_show_elem-', 1, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 21}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 17}}.

{function, '__bp_show', 2, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 29}, [{x, 0}]}.
    {test, is_eq, {f, 28}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 29}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 30}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 30}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 32}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 31}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 31}, [{x, 0}]}.
    {test, is_ne_exact, {f, 31}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 31}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 31}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 33}}.
  {label, 31}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 34}, [{x, 0}]}.
    {test, is_ne_exact, {f, 34}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 34}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, undefined}]}.
  {label, 33}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 23}, 2}.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 35}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 23}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 36}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 36}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 36}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 25}, 3}.
  {label, 37}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 25}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 38}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 39}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 27}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
2
6
```
