{module, std@io@process@@Child}.
{exports, [{wait, 1}, {kill, 2}, {forwardSignals, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 145}.

{function, wait, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@process@@Child.erl", 10}]}.
    {func_info, {atom, std@io@process@@Child}, {atom, wait}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 36}, [{x, 0}, 3, {atom, std@io@process@@Child}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 36}.
    {call, 1, {f, 9}}.
    {deallocate, 1}.
    return.

{function, kill, 2, 5}.
  {label, 4}.
    {line, [{location, "std@io@process@@Child.erl", 11}]}.
    {func_info, {atom, std@io@process@@Child}, {atom, kill}, 2}.
  {label, 5}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 56}, [{x, 0}, 3, {atom, std@io@process@@Child}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 56}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@process, signalName, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 38}}.
    {test, is_tagged_tuple, {f, 58}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
    {jump, {f, 57}}.
  {label, 58}.
    {test, is_tagged_tuple, {f, 59}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 60}, [{x, 0}, 3, {atom, std@io@process@@Child}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 60}.
    {move, {y, 3}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, std@io@process, processError, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
    {jump, {f, 57}}.
  {label, 59}.
    {case_end, {x, 0}}.
  {label, 57}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, forwardSignals, 1, 7}.
  {label, 6}.
    {line, [{location, "std@io@process@@Child.erl", 12}]}.
    {func_info, {atom, std@io@process@@Child}, {atom, forwardSignals}, 1}.
  {label, 7}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 61}, [{x, 0}, 3, {atom, std@io@process@@Child}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 61}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, std@io@process@@Signal__v__winch}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, std@io@process@@Signal__v__hup}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, std@io@process@@Signal__v__term}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {atom, std@io@process@@Signal__v__int}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 0}]}}.
    {'try', {y, 3}, {f, 135}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {try_end, {y, 3}}.
    {jump, {f, 138}}.
  {label, 135}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 137}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 136}, [{x, 1}, 2, {atom, '__bp_try'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 136}.
    {test, is_tagged_tuple, {f, 137}, [{x, 1}, 2, {atom, '__bp_return'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 137}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 138}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, '__bp_get', 2, 140}.
  {label, 139}.
    {line, [{location, "std@io@process@@Child.erl", 13}]}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_get'}, 2}.
  {label, 140}.
    {test, is_eq_exact, {f, 141}, [{x, 1}, {atom, pid}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 141}.
    {test, is_eq_exact, {f, 142}, [{x, 1}, {atom, handle}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 142}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 144}.
  {label, 143}.
    {line, [{location, "std@io@process@@Child.erl", 13}]}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_format'}, 1}.
  {label, 144}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"handle">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"pid">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Child">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0--t/1-fun-0--fun-1-', 1, 19}.
  {label, 18}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_0--t/1-fun-0--fun-1-'}, 1}.
  {label, 19}.
    {allocate, 13, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
  {label, 22}.
    {loop_rec, {f, 23}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 26}, [{x, 0}]}.
    {test, test_arity, {f, 26}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 26}, [{x, 0}]}.
    {test, test_arity, {f, 26}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, data}]}.
    {move, {y, 9}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {x, 1}]}.
    {jump, {f, 27}}.
  {label, 27}.
    remove_message.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_binary, {f, 29}, [{x, 0}]}.
    {jump, {f, 30}}.
  {label, 30}.
    {move, {y, 4}, {x, 0}}.
    {call_ext, 1, {extfunc, io, put_chars, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 11}}.
    {jump, {f, 28}}.
  {label, 29}.
    {move, {y, 3}, {x, 0}}.
    {move, {atom, latin1}, {x, 1}}.
    {call_ext, 2, {extfunc, unicode, characters_to_binary, 2}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, io, put_chars, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {y, 11}}.
    {jump, {f, 28}}.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 19}, 13}.
  {label, 26}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tuple, {f, 32}, [{x, 0}]}.
    {test, test_arity, {f, 32}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {y, 1}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tuple, {f, 32}, [{x, 0}]}.
    {test, test_arity, {f, 32}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, exit_status}]}.
    {move, {y, 9}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {x, 1}]}.
    {jump, {f, 33}}.
  {label, 33}.
    remove_message.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_child_status}, {y, 0}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, put, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 13}.
    return.
  {label, 32}.
    {move, nil, {y, 5}}.
    {move, nil, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 9}}.
    {move, nil, {y, 10}}.
    {move, nil, {y, 11}}.
    {move, nil, {y, 12}}.
    {loop_rec_end, {f, 22}}.
  {label, 23}.
    {wait, {f, 22}}.

{function, '__bp_tpl_0-t/1-fun-0-', 1, 13}.
  {label, 12}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_0-t/1-fun-0-'}, 1}.
  {label, 13}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_child_status}, {y, 1}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, get, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 17}, [{x, 0}, {atom, undefined}]}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 35}}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 4}.
    return.
  {label, 17}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_0', 1, 9}.
  {label, 8}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_0'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 13}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 42}.
  {label, 41}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 42}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, os_pid}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, port_info, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 46}, [{x, 0}]}.
    {test, test_arity, {f, 46}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, os_pid}]}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {move, {y, 6}, {x, 2}}.
    {call_ext, 3, {extfunc, binary, part, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_list, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {literal, [32, 50, 62, 38, 49]}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, [32]}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, [107, 105, 108, 108, 32, 45]}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext, 1, {extfunc, os, cmd, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 48}}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [78, 111, 32, 115, 117, 99, 104, 32, 112, 114, 111, 99, 101, 115, 115]}, {x, 1}}.
    {call_ext, 2, {extfunc, string, find, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, nomatch}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, nil]}.
    {move, {literal, {ok, 0}}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 52}.
    {test_heap, 4, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {put_list, {literal, <<"other|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 7}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 50}.
    {move, {literal, {error, <<"gone|">>}}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 46}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, undefined}]}.
    {move, {literal, {error, <<"gone|">>}}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 55}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_1', 2, 38}.
  {label, 37}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_1'}, 2}.
  {label, 38}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_2--t/2-fun-0--fun-1-', 2, 95}.
  {label, 94}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_2--t/2-fun-0--fun-1-'}, 2}.
  {label, 95}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 97}, [{x, 0}, nil]}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 97}, [{x, 0}, nil]}.
    {move, nil, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 97}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 98}, [{x, 0}, nil]}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 2, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 98}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nonempty_list, {f, 99}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 99}, [{x, 0}]}.
    {test, test_arity, {f, 99}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {atom, dot}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 1}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call, 2, {f, 95}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 2, 0}.
    {put_list, {y, 7}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 99}.
    {move, {y, 2}, {x, 0}}.
    {test, is_nonempty_list, {f, 100}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 4}, {y, 5}}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_last, 2, {f, 95}, 9}.
  {label, 100}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {deallocate, 9}.
    {jump, {f, 94}}.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 69}.
  {label, 68}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 69}.
    {allocate, 17, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"SIGTERM">>}, {x, 1}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {x, 1}]}.
    {jump, {f, 74}}.
  {label, 74}.
    {move, {atom, sigterm}, {y, 5}}.
    {jump, {f, 72}}.
  {label, 73}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"SIGHUP">>}, {x, 1}}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {x, 1}]}.
    {jump, {f, 76}}.
  {label, 76}.
    {move, {atom, sighup}, {y, 5}}.
    {jump, {f, 72}}.
  {label, 75}.
    {move, {y, 3}, {x, 0}}.
    {move, {literal, <<"SIGWINCH">>}, {x, 1}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {x, 1}]}.
    {jump, {f, 78}}.
  {label, 78}.
    {move, {atom, sigwinch}, {y, 5}}.
    {jump, {f, 72}}.
  {label, 77}.
    {jump, {f, 80}}.
  {label, 80}.
    {move, {atom, unsupported}, {y, 5}}.
    {jump, {f, 72}}.
  {label, 72}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 82}}.
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {atom, unsupported}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" cannot be caught on the Erlang VM">>}, nil, {x, 0}}.
    {put_list, {y, 3}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"unsupported|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 5}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 17}.
    return.
  {label, 84}.
    {'try', {y, 16}, {f, 86}}.
    {move, {atom, bp_signal_handler}, {x, 0}}.
    {call_ext, 1, {extfunc, code, is_loaded, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 89}, [{x, 0}, {atom, false}]}.
    {move, {literal, [45, 109, 111, 100, 117, 108, 101, 40, 98, 112, 95, 115, 105, 103, 110, 97, 108, 95, 104, 97, 110, 100, 108, 101, 114, 41, 46, 32, 45, 98, 101, 104, 97, 118, 105, 111, 117, 114, 40, 103, 101, 110, 95, 101, 118, 101, 110, 116, 41, 46, 32, 45, 101, 120, 112, 111, 114, 116, 40, 91, 105, 110, 105, 116, 47, 49, 44, 32, 104, 97, 110, 100, 108, 101, 95, 101, 118, 101, 110, 116, 47, 50, 44, 32, 104, 97, 110, 100, 108, 101, 95, 99, 97, 108, 108, 47, 50, 93, 41, 46, 32, 105, 110, 105, 116, 40, 83, 41, 32, 45, 62, 32, 123, 111, 107, 44, 32, 83, 125, 46, 32, 104, 97, 110, 100, 108, 101, 95, 101, 118, 101, 110, 116, 40, 69, 44, 32, 83, 41, 32, 45, 62, 32, 91, 70, 40, 41, 32, 124, 124, 32, 70, 32, 60, 45, 32, 112, 101, 114, 115, 105, 115, 116, 101, 110, 116, 95, 116, 101, 114, 109, 58, 103, 101, 116, 40, 123, 98, 112, 95, 115, 105, 103, 110, 97, 108, 44, 32, 69, 125, 44, 32, 91, 93, 41, 93, 44, 32, 123, 111, 107, 44, 32, 83, 125, 46, 32, 104, 97, 110, 100, 108, 101, 95, 99, 97, 108, 108, 40, 95, 44, 32, 83, 41, 32, 45, 62, 32, 123, 111, 107, 44, 32, 111, 107, 44, 32, 83, 125, 46]}, {y, 1}}.
    {jump, {f, 91}}.
  {label, 91}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erl_scan, string, 1}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 92}, [{x, 0}]}.
    {test, test_arity, {f, 92}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 1}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 93}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 2}}.
    {jump, {f, 102}}.
  {label, 102}.
    {move, nil, {y, 8}}.
    {move, {y, 1}, {x, 0}}.
    {move, nil, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {y, 9}}.
  {label, 104}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nonempty_list, {f, 105}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 11}, {y, 9}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erl_parse, parse_form, 1}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {test, is_tuple, {f, 107}, [{x, 0}]}.
    {test, test_arity, {f, 107}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 13}}.
    {get_tuple_element, {x, 0}, 1, {y, 14}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_eq_exact, {f, 107}, [{x, 0}, {atom, ok}]}.
    {move, {y, 14}, {y, 2}}.
    {jump, {f, 108}}.
  {label, 107}.
    {move, {y, 12}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 108}.
    {test_heap, 2, 0}.
    {put_list, {y, 2}, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 104}}.
  {label, 105}.
    {move, {y, 9}, {x, 0}}.
    {test, is_nil, {f, 106}, [{x, 0}]}.
    {jump, {f, 103}}.
  {label, 106}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 9}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 103}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 1}}.
    {jump, {f, 110}}.
  {label, 110}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [binary]}, {x, 1}}.
    {call_ext, 2, {extfunc, compile, forms, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 111}, [{x, 0}]}.
    {test, test_arity, {f, 111}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 111}, [{x, 0}, {atom, ok}]}.
    {move, {y, 10}, {y, 1}}.
    {move, {y, 11}, {y, 2}}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 112}.
    {move, {y, 1}, {x, 0}}.
    {move, {literal, [98, 112, 95, 115, 105, 103, 110, 97, 108, 95, 104, 97, 110, 100, 108, 101, 114, 46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 113}, [{x, 0}]}.
    {test, test_arity, {f, 113}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, module}]}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 114}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 88}}.
  {label, 89}.
    {move, {atom, ok}, {y, 7}}.
    {jump, {f, 88}}.
  {label, 88}.
    {move, {atom, erl_signal_server}, {x, 0}}.
    {call_ext, 1, {extfunc, gen_event, which_handlers, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {atom, bp_signal_handler}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, true}]}.
    {move, {atom, ok}, {y, 7}}.
    {jump, {f, 116}}.
  {label, 117}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {atom, false}]}.
    {'catch', {y, 15}, {f, 119}}.
    {move, {atom, erl_signal_server}, {x, 0}}.
    {move, {atom, erl_signal_handler}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext, 3, {extfunc, gen_event, delete_handler, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
  {label, 119}.
    {catch_end, {y, 15}}.
    {move, {x, 0}, {y, 8}}.
    {jump, {f, 121}}.
  {label, 121}.
    {move, {atom, erl_signal_server}, {x, 0}}.
    {move, {atom, bp_signal_handler}, {x, 1}}.
    {move, nil, {x, 2}}.
    {call_ext, 3, {extfunc, gen_event, add_handler, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 122}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 123}}.
  {label, 122}.
    {move, {y, 8}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 123}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 116}}.
  {label, 118}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 116}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_signal}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_signal}, {y, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, nil, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, 2, 0}.
    {put_list, {y, 4}, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '++', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, handle}, {x, 1}}.
    {call_ext, 2, {extfunc, os, set_signal, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {atom, ok}]}.
    {jump, {f, 125}}.
  {label, 124}.
    {move, {y, 6}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 125}.
    {move, {literal, {ok, 0}}, {y, 5}}.
    {try_end, {y, 16}}.
    {jump, {f, 87}}.
  {label, 86}.
    {try_case, {y, 16}}.
    {move, {x, 0}, {y, 6}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 2}, {y, 8}}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, 2, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_list, {y, 9}, nil, {x, 0}}.
    {put_list, {literal, <<"other|">>}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 9}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {y, 5}}.
    {jump, {f, 126}}.
  {label, 126}.
  {label, 87}.
    {move, {y, 5}, {x, 0}}.
    {deallocate, 17}.
    return.

{function, '__bp_tpl_2', 2, 65}.
  {label, 64}.
    {func_info, {atom, std@io@process@@Child}, {atom, '__bp_tpl_2'}, 2}.
  {label, 65}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-onSignal/3-fun-1-', 2, 128}.
  {label, 127}.
    {line, [{location, "std@io@process@@Child.erl", 13}]}.
    {func_info, {atom, std@io@process@@Child}, {atom, '-onSignal/3-fun-1-'}, 2}.
  {label, 128}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 38}}.
    {deallocate, 2}.
    return.

{function, '-onSignal/1-fun-0-', 3, 63}.
  {label, 62}.
    {line, [{location, "std@io@process@@Child.erl", 13}]}.
    {func_info, {atom, std@io@process@@Child}, {atom, '-onSignal/1-fun-0-'}, 3}.
  {label, 63}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@process, signalName, 1}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 128}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 3}, {x, 0}}.
    {call, 2, {f, 65}}.
    {test, is_tagged_tuple, {f, 130}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, ok}, {x, 0}}.
    {jump, {f, 129}}.
  {label, 130}.
    {test, is_tagged_tuple, {f, 131}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 3, {atom, std@io@process@@Child}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 132}.
    {move, {y, 4}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, std@io@process, processError, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 134}, [{x, 0}, 2, {atom, std@io@process@@ProcessError__v__unsupported}]}.
    {move, {atom, ok}, {x, 0}}.
    {jump, {f, 133}}.
  {label, 134}.
    {move, {y, 5}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_return'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 133}}.
  {label, 133}.
    {jump, {f, 129}}.
  {label, 131}.
    {case_end, {x, 0}}.
  {label, 129}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
    return.
