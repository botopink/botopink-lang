{module, std@collections@@Set}.
{exports, [{contains, 2}, {size, 1}, {isEmpty, 1}, {toList, 1}, {insert, 2}, {delete, 2}, {union, 2}, {intersection, 2}, {difference, 2}, {empty, 0}, {fromList, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 68}.

{function, contains, 2, 3}.
  {label, 2}.
    {line, [{location, "std@collections@@Set.erl", 19}]}.
    {func_info, {atom, std@collections@@Set}, {atom, contains}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 26}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_last, 2, {f, 25}, 2}.

{function, size, 1, 5}.
  {label, 4}.
    {line, [{location, "std@collections@@Set.erl", 20}]}.
    {func_info, {atom, std@collections@@Set}, {atom, size}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 31}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 31}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, isEmpty, 1, 7}.
  {label, 6}.
    {line, [{location, "std@collections@@Set.erl", 21}]}.
    {func_info, {atom, std@collections@@Set}, {atom, isEmpty}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 32}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 34}}.
  {label, 33}.
    {move, {atom, false}, {x, 0}}.
  {label, 34}.
    {deallocate, 1}.
    return.

{function, toList, 1, 9}.
  {label, 8}.
    {line, [{location, "std@collections@@Set.erl", 22}]}.
    {func_info, {atom, std@collections@@Set}, {atom, toList}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 35}.
    {deallocate, 1}.
    return.

{function, insert, 2, 11}.
  {label, 10}.
    {line, [{location, "std@collections@@Set.erl", 23}]}.
    {func_info, {atom, std@collections@@Set}, {atom, insert}, 2}.
  {label, 11}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 37}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 37}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
    {test, is_eq, {f, 36}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 42}}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 43}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 43}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
  {label, 42}.
    {deallocate, 3}.
    return.

{function, delete, 2, 13}.
  {label, 12}.
    {line, [{location, "std@collections@@Set.erl", 24}]}.
    {func_info, {atom, std@collections@@Set}, {atom, delete}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 44}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 44}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, union, 2, 15}.
  {label, 14}.
    {line, [{location, "std@collections@@Set.erl", 25}]}.
    {func_info, {atom, std@collections@@Set}, {atom, union}, 2}.
  {label, 15}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 49}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 49}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 19}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 50}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 4}.
    return.

{function, intersection, 2, 17}.
  {label, 16}.
    {line, [{location, "std@collections@@Set.erl", 26}]}.
    {func_info, {atom, std@collections@@Set}, {atom, intersection}, 2}.
  {label, 17}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 51}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 53}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, difference, 2, 19}.
  {label, 18}.
    {line, [{location, "std@collections@@Set.erl", 27}]}.
    {func_info, {atom, std@collections@@Set}, {atom, difference}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, std@collections@@Set}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 54}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, empty, 0, 21}.
  {label, 20}.
    {line, [{location, "std@collections@@Set.erl", 28}]}.
    {func_info, {atom, std@collections@@Set}, {atom, empty}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, fromList, 1, 23}.
  {label, 22}.
    {line, [{location, "std@collections@@Set.erl", 29}]}.
    {func_info, {atom, std@collections@@Set}, {atom, fromList}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Set}, {x, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 62}.
  {label, 61}.
    {line, [{location, "std@collections@@Set.erl", 30}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '__bp_get'}, 2}.
  {label, 62}.
    {test, is_eq_exact, {f, 63}, [{x, 1}, {atom, items}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 63}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 65}.
  {label, 64}.
    {line, [{location, "std@collections@@Set.erl", 30}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '__bp_format'}, 1}.
  {label, 65}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"items">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Set">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, 'array_any', 2, 25}.
  {label, 24}.
    {line, [{location, "std@collections@@Set.erl", 30}]}.
    {func_info, {atom, std@collections@@Set}, {atom, 'array_any'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {atom, false}, {x, 0}}.
  {label, 67}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-0-', 2, 28}.
  {label, 27}.
    {line, [{location, "std@collections@@Set.erl", 20}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-0-'}, 2}.
  {label, 28}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq_exact, {f, 29}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {atom, false}, {x, 0}}.
  {label, 30}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-1-', 2, 39}.
  {label, 38}.
    {line, [{location, "std@collections@@Set.erl", 24}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-1-'}, 2}.
  {label, 39}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq_exact, {f, 40}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 41}}.
  {label, 40}.
    {move, {atom, false}, {x, 0}}.
  {label, 41}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-2-', 2, 46}.
  {label, 45}.
    {line, [{location, "std@collections@@Set.erl", 25}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-2-'}, 2}.
  {label, 46}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ne_exact, {f, 47}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 48}}.
  {label, 47}.
    {move, {atom, false}, {x, 0}}.
  {label, 48}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-3-', 2, 53}.
  {label, 52}.
    {line, [{location, "std@collections@@Set.erl", 27}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-3-'}, 2}.
  {label, 53}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 3}}.
    {deallocate, 2}.
    return.

{function, '-shown/2-fun-4-', 2, 56}.
  {label, 55}.
    {line, [{location, "std@collections@@Set.erl", 28}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/2-fun-4-'}, 2}.
  {label, 56}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 3}}.
    {test, is_eq, {f, 57}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {atom, true}, {x, 0}}.
  {label, 58}.
    {deallocate, 2}.
    return.

{function, '-shown/1-fun-5-', 2, 60}.
  {label, 59}.
    {line, [{location, "std@collections@@Set.erl", 30}]}.
    {func_info, {atom, std@collections@@Set}, {atom, '-shown/1-fun-5-'}, 2}.
  {label, 60}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 11}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
