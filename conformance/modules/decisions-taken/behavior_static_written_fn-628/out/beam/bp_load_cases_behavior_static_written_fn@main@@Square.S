{module, bp_load_cases_behavior_static_written_fn@main@@Square}.
{exports, [{make, 0}, {area, 1}, {describe, 1}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 61}.

{function, make, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 3}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, make}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {integer, 3}]}}.
    {deallocate, 0}.
    return.

{function, area, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 4}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, area}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 2, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 8}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 2, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 9}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 10}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 10}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:32:26">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 11}.
    {deallocate, 1}.
    return.

{function, describe, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 5}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, describe}, 1}.
  {label, 7}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {call, 1, {f, 13}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"area ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_get'}, 2}.
  {label, 47}.
    {test, is_eq_exact, {f, 48}, [{x, 1}, {atom, side}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 48}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_format'}, 1}.
  {label, 50}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"side">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Square">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_behaviors'}, 0}.
  {label, 52}.
    {move, {literal, [bp_load_cases_behavior_static_written_fn@main@@Shape]}, {x, 0}}.
    return.

{function, 'string_toString', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 7}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, 'string_toString'}, 1}.
  {label, 54}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_print'}, 1}.
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
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '-bp_show_top-'}, 1}.
  {label, 19}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 17}}.

{function, '-bp_show_elem-', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '-bp_show_elem-'}, 1}.
  {label, 21}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 17}}.

{function, '__bp_show', 2, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_show'}, 2}.
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
    {test, is_eq_exact, {f, 36}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 37}}.
  {label, 36}.
    {test, is_eq_exact, {f, 33}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 37}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 17}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
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
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_tagged'}, 2}.
  {label, 23}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 38}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 38}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 38}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 25}, 3}.
  {label, 39}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_render'}, 1}.
  {label, 25}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 40}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 41}.
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
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '-bp_render_pair-'}, 1}.
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

{function, '-bp_stringify-', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '-bp_stringify-'}, 1}.
  {label, 43}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 44}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 44}.
    {test, is_integer, {f, 45}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 45}.
    {call, 1, {f, 19}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_0', 1, 59}.
  {label, 58}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_tpl_0'}, 1}.
  {label, 59}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [short]}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, float_to_binary, 2}, 1}.

{function, '__bp_prim_toString', 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_behavior_static_written_fn@main@@Square.erl", 6}]}.
    {func_info, {atom, bp_load_cases_behavior_static_written_fn@main@@Square}, {atom, '__bp_prim_toString'}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 55}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 54}, 1}.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test, is_boolean, {f, 56}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, atom_to_binary, 1}, 1}.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 57}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 1}.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test, is_float, {f, 60}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 59}, 1}.
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 43}, 1}.
