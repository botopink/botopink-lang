{module, bp_load_cases_behavior_method_result_dispatch@main@@Layered}.
{exports, [{get, 2}, {getTwice, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 54}.

{function, get, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 3}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, get}, 2}.
  {label, 3}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"secret">>}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{y, 1}, {x, 0}]}.
    {move, {literal, <<"denied">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 2, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 7}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_load_cases_behavior_method_result_dispatch@main@@Memory, get, 2}}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 9}}.
  {label, 8}.
    {deallocate, 4}.
    return.
  {label, 9}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"]">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"[">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, getTwice, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, getTwice}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 43}}.
  {label, 42}.
    {deallocate, 3}.
    return.
  {label, 43}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 45}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 5}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_get'}, 2}.
  {label, 48}.
    {test, is_eq_exact, {f, 49}, [{x, 1}, {atom, inner}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 49}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 5}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_format'}, 1}.
  {label, 51}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"inner">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Layered">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 53}.
  {label, 52}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 5}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_behaviors'}, 0}.
  {label, 53}.
    {move, {literal, [bp_load_cases_behavior_method_result_dispatch@main@@KeyValueStore]}, {x, 0}}.
    return.

{function, '__bp_print', 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_print'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '-bp_show_top-'}, 1}.
  {label, 15}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 13}}.

{function, '-bp_show_elem-', 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '-bp_show_elem-'}, 1}.
  {label, 17}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 13}}.

{function, '__bp_show', 2, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_show'}, 2}.
  {label, 13}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 25}, [{x, 0}]}.
    {test, is_eq, {f, 24}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 26}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 28}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 27}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 27}, [{x, 0}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 33}}.
  {label, 32}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 33}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 13}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 30}, [{x, 0}]}.
    {test, is_ne_exact, {f, 30}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 30}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 31}, [{x, 0}, {atom, undefined}]}.
  {label, 29}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 19}, 2}.
  {label, 30}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 31}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_tagged'}, 2}.
  {label, 19}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 34}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 34}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 34}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 21}, 3}.
  {label, 35}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_render'}, 1}.
  {label, 21}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 36}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 36}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 37}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '-bp_render_pair-'}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 13}}.
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

{function, '-bp_stringify-', 1, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '-bp_stringify-'}, 1}.
  {label, 39}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 40}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 40}.
    {test, is_integer, {f, 41}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 41}.
    {call, 1, {f, 15}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_add', 2, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_behavior_method_result_dispatch@main@@Layered.erl", 5}]}.
    {func_info, {atom, bp_load_cases_behavior_method_result_dispatch@main@@Layered}, {atom, '__bp_add'}, 2}.
  {label, 45}.
    {test, is_binary, {f, 46}, [{x, 0}]}.
    {test, is_binary, {f, 46}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 46}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.
