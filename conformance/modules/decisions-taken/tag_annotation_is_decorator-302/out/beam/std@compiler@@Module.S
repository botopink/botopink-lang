{module, std@compiler@@Module}.
{exports, [{'of', 3}, {name, 1}, {path, 1}, {buildOutput, 1}, {run, 1}, {captureOpen, 0}, {captureClose, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 84}.

{function, 'of', 3, 3}.
  {label, 2}.
    {line, [{location, "std@compiler@@Module.erl", 1}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, 'of'}, 3}.
  {label, 3}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Module}, {y, 0}, {y, 1}, {y, 2}]}}.
    {deallocate, 3}.
    return.

{function, name, 1, 5}.
  {label, 4}.
    {line, [{location, "std@compiler@@Module.erl", 2}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, name}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 4, {atom, std@compiler@@Module}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 16}.
    {deallocate, 1}.
    return.

{function, path, 1, 7}.
  {label, 6}.
    {line, [{location, "std@compiler@@Module.erl", 3}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, path}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 17}, [{x, 0}, 4, {atom, std@compiler@@Module}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 17}.
    {deallocate, 1}.
    return.

{function, buildOutput, 1, 9}.
  {label, 8}.
    {line, [{location, "std@compiler@@Module.erl", 4}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, buildOutput}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 4, {atom, std@compiler@@Module}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 18}.
    {deallocate, 1}.
    return.

{function, run, 1, 11}.
  {label, 10}.
    {line, [{location, "std@compiler@@Module.erl", 5}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, run}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"Module.run: every call is lowered to the loaded main">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, captureOpen, 0, 13}.
  {label, 12}.
    {line, [{location, "std@compiler@@Module.erl", 6}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, captureOpen}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call_last, 0, {f, 20}, 0}.

{function, captureClose, 1, 15}.
  {label, 14}.
    {line, [{location, "std@compiler@@Module.erl", 7}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, captureClose}, 1}.
  {label, 15}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 63}, 1}.

{function, '__bp_get', 2, 78}.
  {label, 77}.
    {line, [{location, "std@compiler@@Module.erl", 8}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_get'}, 2}.
  {label, 78}.
    {test, is_eq_exact, {f, 79}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 79}.
    {test, is_eq_exact, {f, 80}, [{x, 1}, {atom, path}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 80}.
    {test, is_eq_exact, {f, 81}, [{x, 1}, {atom, buildOutput}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 81}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 83}.
  {label, 82}.
    {line, [{location, "std@compiler@@Module.erl", 8}]}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_format'}, 1}.
  {label, 83}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"buildOutput">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"path">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Module">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0-----t/0-fun-0--fun-1--fun-2--fun-3--fun-4-', 3, 53}.
  {label, 52}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_0-----t/0-fun-0--fun-1--fun-2--fun-3--fun-4-'}, 3}.
  {label, 53}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 0}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tuple, {f, 55}, [{x, 0}]}.
    {test, test_arity, {f, 55}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 5}.
    return.
  {label, 55}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 0}, {x, 2}}.
    {deallocate, 5}.
    {jump, {f, 52}}.

{function, '__bp_tpl_0----t/0-fun-0--fun-1--fun-2--fun-3-', 2, 43}.
  {label, 42}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_0----t/0-fun-0--fun-1--fun-2--fun-3-'}, 2}.
  {label, 43}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 1}, {y, 5}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 47}, [{x, 0}]}.
    {test, test_arity, {f, 47}, [{x, 0}, 5]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 2, {y, 7}}.
    {get_tuple_element, {x, 0}, 3, {y, 8}}.
    {get_tuple_element, {x, 0}, 4, {y, 9}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, put_chars}]}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {y, 2}}.
    {move, {y, 9}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 4, 0}.
    {put_list, {y, 10}, nil, {x, 0}}.
    {put_list, {y, 5}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 47}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 48}, [{x, 0}]}.
    {test, test_arity, {f, 48}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {get_tuple_element, {x, 0}, 2, {y, 8}}.
    {get_tuple_element, {x, 0}, 3, {y, 9}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, put_chars}]}.
    {move, {y, 7}, {y, 1}}.
    {move, {y, 8}, {y, 2}}.
    {move, {y, 9}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 4, 0}.
    {put_list, {y, 10}, nil, {x, 0}}.
    {put_list, {y, 5}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 48}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 49}, [{x, 0}]}.
    {test, test_arity, {f, 49}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 2, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, put_chars}]}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {put_list, {y, 5}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 49}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 50}, [{x, 0}]}.
    {test, test_arity, {f, 50}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, put_chars}]}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {put_list, {y, 5}, {x, 0}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 8}]}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {deallocate, 11}.
    return.
  {label, 50}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tuple, {f, 51}, [{x, 0}]}.
    {test, test_arity, {f, 51}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {y, 7}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, requests}]}.
    {move, {y, 7}, {y, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 53}, 1, 0, {x, 0}, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 8}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 5}]}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, lists, foldl, 3}, 11}.
  {label, 51}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{literal, {error, enotsup}}, {y, 5}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '__bp_tpl_0---t/0-fun-0--fun-1--fun-2-', 1, 34}.
  {label, 33}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_0---t/0-fun-0--fun-1--fun-2-'}, 1}.
  {label, 34}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 7}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
  {label, 37}.
    {loop_rec, {f, 38}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 41}, [{x, 0}]}.
    {test, test_arity, {f, 41}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {get_tuple_element, {x, 0}, 3, {y, 12}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, io_request}]}.
    {move, {y, 10}, {y, 3}}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 0}}.
    remove_message.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {move, {y, 13}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_tuple, {f, 57}, [{x, 0}]}.
    {test, test_arity, {f, 57}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 14}}.
    {get_tuple_element, {x, 0}, 1, {y, 15}}.
    {move, {y, 14}, {y, 5}}.
    {move, {y, 15}, {y, 6}}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {y, 13}, {x, 0}}.
    {badmatch, {x, 0}}.
  {label, 58}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, io_reply}, {y, 2}, {y, 5}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 6}, {x, 0}}.
    {call_last, 1, {f, 34}, 16}.
  {label, 41}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 59}, [{x, 0}]}.
    {test, test_arity, {f, 59}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 9}}.
    {get_tuple_element, {x, 0}, 1, {y, 10}}.
    {get_tuple_element, {x, 0}, 2, {y, 11}}.
    {move, {y, 9}, {x, 0}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, bp_capture_take}]}.
    {move, {y, 10}, {y, 1}}.
    {move, {y, 11}, {y, 4}}.
    remove_message.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 12}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 4}, {y, 12}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {deallocate, 16}.
    return.
  {label, 59}.
    {move, nil, {y, 8}}.
    {move, nil, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, nil, {y, 2}}.
    {move, nil, {y, 3}}.
    {move, nil, {y, 4}}.
    {move, nil, {y, 9}}.
    {move, nil, {y, 10}}.
    {move, nil, {y, 11}}.
    {move, nil, {y, 12}}.
    {move, nil, {y, 13}}.
    {move, nil, {y, 14}}.
    {move, nil, {y, 15}}.
    {loop_rec_end, {f, 37}}.
  {label, 38}.
    {wait, {f, 37}}.

{function, '__bp_tpl_0--t/0-fun-0--fun-1-', 0, 30}.
  {label, 29}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_0--t/0-fun-0--fun-1-'}, 0}.
  {label, 30}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 2, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_0-t/0-fun-0-', 0, 24}.
  {label, 23}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_0-t/0-fun-0-'}, 0}.
  {label, 24}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {call_ext, 0, {extfunc, erlang, group_leader, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 28}}.
  {label, 28}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 3, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, spawn, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 1}}.
    {jump, {f, 61}}.
  {label, 61}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, group_leader, 2}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_capture}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_0', 0, 20}.
  {label, 19}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_0'}, 0}.
  {label, 20}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 4, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 67}.
  {label, 66}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 67}.
    {allocate, 9, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {test, test_arity, {f, 69}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 3}}.
    {get_tuple_element, {x, 0}, 1, {y, 4}}.
    {get_tuple_element, {x, 0}, 2, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, bp_capture}]}.
    {move, {y, 4}, {y, 0}}.
    {move, {y, 5}, {y, 1}}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, group_leader, 2}}.
    {move, {x, 0}, {y, 6}}.
    {call_ext, 0, {extfunc, erlang, make_ref, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 71}}.
  {label, 71}.
    {call_ext, 0, {extfunc, erlang, self, 0}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_capture_take}, {y, 6}, {y, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    send.
    {move, {x, 0}, {y, 6}}.
  {label, 72}.
    {loop_rec, {f, 73}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tuple, {f, 76}, [{x, 0}]}.
    {test, test_arity, {f, 76}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 7}}.
    {get_tuple_element, {x, 0}, 1, {y, 8}}.
    {move, {y, 7}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {x, 1}]}.
    {move, {y, 8}, {y, 1}}.
    remove_message.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 9}.
    return.
  {label, 76}.
    {move, nil, {y, 6}}.
    {move, nil, {y, 1}}.
    {move, nil, {y, 7}}.
    {move, nil, {y, 8}}.
    {loop_rec_end, {f, 72}}.
  {label, 73}.
    {wait, {f, 72}}.
  {label, 69}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 9}.
    {jump, {f, 66}}.

{function, '__bp_tpl_1', 1, 63}.
  {label, 62}.
    {func_info, {atom, std@compiler@@Module}, {atom, '__bp_tpl_1'}, 1}.
  {label, 63}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
