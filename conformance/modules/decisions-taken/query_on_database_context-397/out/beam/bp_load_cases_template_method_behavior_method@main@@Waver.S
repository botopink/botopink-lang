{module, bp_load_cases_template_method_behavior_method@main@@Waver}.
{exports, [{who, 1}, {greet, 2}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 46}.

{function, who, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 2}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, who}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 6}.
    {deallocate, 1}.
    return.

{function, greet, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 3}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, greet}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_template_method_behavior_method@main@@Waver, who, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"default ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '__bp_get'}, 2}.
  {label, 40}.
    {test, is_eq_exact, {f, 41}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 41}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '__bp_format'}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Waver">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '__bp_behaviors'}, 0}.
  {label, 45}.
    {move, {literal, [bp_load_cases_template_method_behavior_method@main@@Waves]}, {x, 0}}.
    return.

{function, '__bp_print', 1, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '__bp_print'}, 1}.
  {label, 8}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 12}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 12}.
  {label, 11}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '-bp_show_top-'}, 1}.
  {label, 12}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 10}}.

{function, '-bp_show_elem-', 1, 14}.
  {label, 13}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '-bp_show_elem-'}, 1}.
  {label, 14}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 10}}.

{function, '__bp_show', 2, 10}.
  {label, 9}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '__bp_show'}, 2}.
  {label, 10}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 22}, [{x, 0}]}.
    {test, is_eq, {f, 21}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 21}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 23}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 25}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 24}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 24}, [{x, 0}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 30}}.
  {label, 29}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 30}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 10}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 14}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 27}, [{x, 0}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 27}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 28}, [{x, 0}, {atom, undefined}]}.
  {label, 26}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 16}, 2}.
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 28}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 16}.
  {label, 15}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '__bp_tagged'}, 2}.
  {label, 16}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 31}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 31}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 31}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 18}, 3}.
  {label, 32}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 18}.
  {label, 17}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '__bp_render'}, 1}.
  {label, 18}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 33}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 34}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 20}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 20}.
  {label, 19}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '-bp_render_pair-'}, 1}.
  {label, 20}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 10}}.
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

{function, '-bp_stringify-', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_template_method_behavior_method@main@@Waver.erl", 4}]}.
    {func_info, {atom, bp_load_cases_template_method_behavior_method@main@@Waver}, {atom, '-bp_stringify-'}, 1}.
  {label, 36}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 37}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 37}.
    {test, is_integer, {f, 38}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 38}.
    {call, 1, {f, 12}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
