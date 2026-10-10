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

----- JAVASCRIPT -- main.js
```javascript
function __bp_show(v, s, top, a) {
    if ((typeof v === "string")) {
        a.push(top ? v : (("\"" + Array.from(v, (c) => ((c === "\"") || (c === "\\")) ? ("\\" + c) : (c === "\n") ? "\\n" : (c === "\r") ? "\\r" : (c === "\t") ? "\\t" : c).join("")) + "\""));
        return "%s";
    }
    if ((typeof v === "bigint")) {
        a.push(String(v));
        return "%s";
    }
    if (((typeof v === "number") && (s === "f"))) {
        a.push(Number.isInteger(v) ? v.toFixed(1) : String(v));
        return "%s";
    }
    if (Array.isArray(v)) {
        const t = ((s != null) && (s[0] === "#"));
        return (((t ? "#(" : "[") + v.map((e, i) => __bp_show(e, (s == null) ? null : t ? s[i + 1] : s[1], false, a)).join(", ")) + (t ? ")" : "]"));
    }
    if (((v != null) && (typeof v.__bp === "string"))) {
        if ((typeof v.display === "function")) {
            a.push(v.display());
            return "%s";
        }
        const k = Object.keys(v);
        return (((typeof v.tag === "string") ? ((v.__bp + ".") + v.tag) : v.__bp) + ((k.length === 0) ? "" : (("(" + k.map((n) => ((n + ": ") + __bp_show(v[n], null, false, a))).join(", ")) + ")")));
    }
    if ((v === undefined)) return "null";
    a.push(v);
    return "%O";
}

function __bp_print() {
    const a = [];
    const f = Array.from(arguments, (v, i) => __bp_show(v, null, true, a)).join(" ");
    console.log.apply(console, [f, ...a]);
}

function __bp_int(v, lo, hi, what) { if (v >= lo && v <= hi) { return v + 0; } throw new Error((Number.isFinite(v) ? "integer overflow: " : "integer division by zero: ") + what); }

function add(a, b) {
    return __bp_int((a + b), -2147483648, 2147483647, "+ on i32 at main.bp:2:14");
}

function two() {
    return 2;
}

function main() {
    const a = 2;
    __bp_print(a);
    const d = 6;
    __bp_print(d);
}

function _botopink_main() {
    main();
}
_botopink_main();
```

----- TYPESCRIPT TYPEDEF -- main.d.ts
```typescript





```

----- RUN LOG -----
```logs
2
6
```
