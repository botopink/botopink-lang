{module, std@testing@mocks@@Stub}.
{exports, [{thenReturn, 2}, {thenThrow, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 37}.

{function, thenReturn, 2, 3}.
  {label, 2}.
    {line, [{location, "std@testing@mocks@@Stub.erl", 15}]}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, thenReturn}, 2}.
  {label, 3}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 7}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, thenThrow, 2, 5}.
  {label, 4}.
    {line, [{location, "std@testing@mocks@@Stub.erl", 16}]}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, thenThrow}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 33}.
  {label, 32}.
    {line, [{location, "std@testing@mocks@@Stub.erl", 17}]}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, '__bp_get'}, 2}.
  {label, 33}.
    {test, is_eq_exact, {f, 34}, [{x, 1}, {atom, tag}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 34}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 36}.
  {label, 35}.
    {line, [{location, "std@testing@mocks@@Stub.erl", 17}]}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, '__bp_format'}, 1}.
  {label, 36}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"tag">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Stub">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 11}.
  {label, 10}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 11}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 15}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 6}}.
    {jump, {f, 14}}.
  {label, 15}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 16}, [{x, 0}]}.
    {test, test_arity, {f, 16}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {get_tuple_element, {x, 0}, 2, {y, 9}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 9}, {y, 2}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 18}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 11}}.
    {jump, {f, 17}}.
  {label, 18}.
    {move, {y, 10}, {y, 3}}.
    {move, {y, 3}, {y, 11}}.
    {jump, {f, 17}}.
  {label, 17}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}, {atom, return}, {y, 4}]}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 2, 0}.
    {put_list, {y, 12}, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 14}}.
  {label, 16}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 14}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_0', 1, 7}.
  {label, 6}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, '__bp_tpl_0'}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 11}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 24}.
  {label, 23}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 24}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, ok}, {y, 6}}.
    {jump, {f, 27}}.
  {label, 28}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 29}, [{x, 0}]}.
    {test, test_arity, {f, 29}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {get_tuple_element, {x, 0}, 2, {y, 9}}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 1}}.
    {move, {y, 9}, {y, 2}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {y, 11}}.
    {jump, {f, 30}}.
  {label, 31}.
    {move, {y, 10}, {y, 3}}.
    {move, {y, 3}, {y, 11}}.
    {jump, {f, 30}}.
  {label, 30}.
    {test_heap, 6, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}, {y, 2}, {atom, throw}, {y, 4}]}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 2, 0}.
    {put_list, {y, 12}, nil, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {atom, '__bp_mocks_stubs'}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 6}}.
    {jump, {f, 27}}.
  {label, 29}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 27}.
    {move, {atom, '__bp_mocks_pending_stub'}, {x, 0}}.
    {move, {atom, undefined}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 13}.
    return.

{function, '__bp_tpl_1', 1, 20}.
  {label, 19}.
    {func_info, {atom, std@testing@mocks@@Stub}, {atom, '__bp_tpl_1'}, 1}.
  {label, 20}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
