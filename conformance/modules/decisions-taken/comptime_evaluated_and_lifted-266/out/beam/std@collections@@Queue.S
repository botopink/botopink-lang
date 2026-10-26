{module, std@collections@@Queue}.
{exports, [{size, 1}, {isEmpty, 1}, {enqueue, 2}, {dequeue, 1}, {peek, 1}, {toList, 1}, {empty, 0}, {fromList, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 39}.

{function, size, 1, 3}.
  {label, 2}.
    {line, [{location, "std@collections@@Queue.erl", 31}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, size}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 18}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, isEmpty, 1, 5}.
  {label, 4}.
    {line, [{location, "std@collections@@Queue.erl", 32}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, isEmpty}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 19}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 19}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 20}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, false}, {x, 0}}.
  {label, 21}.
    {deallocate, 1}.
    return.

{function, enqueue, 2, 7}.
  {label, 6}.
    {line, [{location, "std@collections@@Queue.erl", 33}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, enqueue}, 2}.
  {label, 7}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 22}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 22}.
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
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {x, 0}]}}.
    {deallocate, 3}.
    return.

{function, dequeue, 1, 9}.
  {label, 8}.
    {line, [{location, "std@collections@@Queue.erl", 34}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, dequeue}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 23}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 25}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 28}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 29}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 29}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 30}, [{x, 0}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 2, [{integer, 1}, {integer, 1}], {x, 2}}.
    {gc_bif, '-', {f, 0}, 3, [{x, 0}, {integer, 1}], {x, 3}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 31}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {y, 2}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{x, 0}, {y, 1}]}}.
    {deallocate, 3}.
    return.

{function, peek, 1, 11}.
  {label, 10}.
    {line, [{location, "std@collections@@Queue.erl", 35}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, peek}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 32}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 25}, 1}.

{function, toList, 1, 13}.
  {label, 12}.
    {line, [{location, "std@collections@@Queue.erl", 36}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, toList}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 33}, [{x, 0}, 2, {atom, std@collections@@Queue}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 33}.
    {deallocate, 1}.
    return.

{function, empty, 0, 15}.
  {label, 14}.
    {line, [{location, "std@collections@@Queue.erl", 37}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, empty}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, nil, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, fromList, 1, 17}.
  {label, 16}.
    {line, [{location, "std@collections@@Queue.erl", 38}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, fromList}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@collections@@Queue}, {y, 0}]}}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 35}.
  {label, 34}.
    {line, [{location, "std@collections@@Queue.erl", 39}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, '__bp_get'}, 2}.
  {label, 35}.
    {test, is_eq_exact, {f, 36}, [{x, 1}, {atom, items}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 36}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 38}.
  {label, 37}.
    {line, [{location, "std@collections@@Queue.erl", 39}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, '__bp_format'}, 1}.
  {label, 38}.
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
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Queue">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 25}.
  {label, 24}.
    {line, [{location, "std@collections@@Queue.erl", 35}]}.
    {func_info, {atom, std@collections@@Queue}, {atom, '-bp_at-'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 27}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 26}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 27}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 26}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 26}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
