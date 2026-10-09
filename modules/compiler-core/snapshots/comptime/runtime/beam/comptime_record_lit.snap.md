----- SOURCE CODE -- main.bp
```botopink
type RecordField(name: string, typeName: string)
val f = comptime RecordField(name: "x", typeName: "i32");
```

----- COMPTIME BEAM ASSEMBLY -- comptime block
```erlang
{module, comptime_module}.
{exports, [{main, 1}]}.
{attributes, []}.
{labels, 63}.

{function, '__bp_ct_value', 0, 2}.
  {label, 1}.
    {func_info, {atom, comptime_module}, {atom, '__bp_ct_value'}, 0}.
  {label, 2}.
    {allocate, 0, 0}.
    {move, {literal, #{name => <<"x">>, typeName => <<"i32">>}}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 1, 4}.
  {label, 3}.
    {func_info, {atom, comptime_module}, {atom, main}, 1}.
  {label, 4}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {'try', {y, 8}, {f, 15}}.
    {call, 0, {f, 2}}.
    {move, {x, 0}, {y, 4}}.
    {call, 0, {f, 6}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 8}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{atom, kind}, {literal, <<"value">>}, {atom, value}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, json, encode, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 3}}.
    {try_end, {y, 8}}.
    {jump, {f, 16}}.
  {label, 15}.
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
    {jump, {f, 17}}.
  {label, 17}.
  {label, 16}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '__bp_fns', 0, 6}.
  {label, 5}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fns'}, 0}.
  {label, 6}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-__bp_lift/2-fun-0-', 3, 50}.
  {label, 49}.
    {func_info, {atom, comptime_module}, {atom, '-__bp_lift/2-fun-0-'}, 3}.
  {label, 50}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {x, 2}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 8}, 3}.

{function, '__bp_lift', 2, 8}.
  {label, 7}.
    {func_info, {atom, comptime_module}, {atom, '__bp_lift'}, 2}.
  {label, 8}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 24}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 25}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 26}.
    {move, {y, 1}, {x, 0}}.
    {test, is_integer, {f, 27}, [{x, 0}]}.
    {jump, {f, 28}}.
  {label, 28}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 27}.
    {move, {y, 1}, {x, 0}}.
    {test, is_float, {f, 29}, [{x, 0}]}.
    {jump, {f, 30}}.
  {label, 30}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"float">>}, {y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 31}, [{x, 0}]}.
    {jump, {f, 32}}.
  {label, 32}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 31}.
    {move, {y, 1}, {x, 0}}.
    {test, is_atom, {f, 33}, [{x, 0}]}.
    {jump, {f, 34}}.
  {label, 34}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"atom">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 33}.
    {move, {y, 1}, {x, 0}}.
    {test, is_list, {f, 35}, [{x, 0}]}.
    {jump, {f, 36}}.
  {label, 36}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {y, 4}}.
  {label, 38}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 39}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 8}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 38}}.
  {label, 39}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 40}, [{x, 0}]}.
    {jump, {f, 37}}.
  {label, 40}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 37}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 35}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tuple, {f, 41}, [{x, 0}]}.
    {jump, {f, 42}}.
  {label, 42}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 4}}.
  {label, 44}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 45}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 6}, {y, 4}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 8}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 44}}.
  {label, 45}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 46}, [{x, 0}]}.
    {jump, {f, 43}}.
  {label, 46}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 43}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"tuple">>}, {y, 4}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 41}.
    {move, {y, 1}, {x, 0}}.
    {test, is_map, {f, 47}, [{x, 0}]}.
    {jump, {f, 48}}.
  {label, 48}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
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
  {label, 47}.
    {move, {y, 1}, {x, 0}}.
    {test, is_function, {f, 53}, [{x, 0}]}.
    {jump, {f, 54}}.
  {label, 54}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 10}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"fn">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 53}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_comptime_decorator, '__bp_text', 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, #{}}, {x, 0}}.
    {put_map_assoc, {f, 0}, {x, 0}, {x, 0}, 1, {list, [{literal, <<"resource">>}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_fn_index', 2, 10}.
  {label, 9}.
    {func_info, {atom, comptime_module}, {atom, '__bp_fn_index'}, 2}.
  {label, 10}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, nil]}.
    {move, {atom, null}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 59}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 60}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 60}, [{x, 0}]}.
    {test, test_arity, {f, 60}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 0}}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {x, 1}]}.
    {jump, {f, 61}}.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 60}.
    {move, {y, 3}, {x, 0}}.
    {test, is_nonempty_list, {f, 62}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 10}, 8}.
  {label, 62}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.
```

----- COMPTIME REPLY -- comptime block
```json
{
  "kind": "value",
  "value": {
    "record": {
      "name": "x",
      "typeName": "i32"
    }
  }
}
```

