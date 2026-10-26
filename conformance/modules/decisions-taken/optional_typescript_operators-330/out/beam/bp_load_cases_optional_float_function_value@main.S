{module, bp_load_cases_optional_float_function_value@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__halver', 1}, {'__bp_priv__quarter', 1}, {'__bp_priv__shower', 1}, {'__bp_priv__wide', 1}]}.
{attributes, []}.
{labels, 106}.
%%% Decision 330 — a function taking or answering a float (or an `i64`) is
%%% a value like any other: bound out of an optional (`if (h) { g -> … }`),
%%% called through `?.()`, held by a typed local, or a top-level function
%%% named as a value. The argument reaches it and its answer comes back
%%% unchanged, on every target.

{function, halver, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, halver}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 24}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 25}.
    {deallocate, 2}.
    return.

{function, shower, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, shower}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 62}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 63}.
    {deallocate, 2}.
    return.

{function, quarter, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, quarter}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 4.0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, wide, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, wide}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 68}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 69}.
    {deallocate, 2}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 22, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}]}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_ne_exact, {f, 70}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {float, 3.0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {jump, {f, 71}}.
  {label, 70}.
  {label, 71}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {float, 3.0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 74}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 72}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 77}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {float, 3.0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 78}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 76}.
    {move, {float, -1.0}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 82}}.
  {label, 81}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 82}.
    {test, is_ne_exact, {f, 80}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 80}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 83}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 85}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 86}.
    {test, is_ne_exact, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 87}}.
  {label, 84}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 87}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 14}}.
    {move, {float, 2.0}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 89}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 15}}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {y, 15}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 91}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {integer, 5000000000}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 92}}.
  {label, 91}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 92}.
    {test, is_ne_exact, {f, 90}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 90}.
    {move, {integer, 0}, {x, 0}}.
  {label, 93}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 95}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 20}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 96}.
    {test, is_ne_exact, {f, 94}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 94}.
    {move, {integer, -1}, {x, 0}}.
  {label, 97}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 22}.
    return.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call, 0, {f, 11}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_float_function_value|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__halver', 1, 99}.
  {label, 98}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_priv__halver'}, 1}.
  {label, 99}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__quarter', 1, 101}.
  {label, 100}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_priv__quarter'}, 1}.
  {label, 101}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__shower', 1, 103}.
  {label, 102}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_priv__shower'}, 1}.
  {label, 103}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__wide', 1, 105}.
  {label, 104}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_priv__wide'}, 1}.
  {label, 105}.
    {call_only, 1, {f, 9}}.

{function, '-halver/1-fun-0-', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-halver/1-fun-0-'}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 2.0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_0', 1, 29}.
  {label, 28}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, [short]}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, float_to_binary, 2}, 1}.

{function, '__bp_print', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_print'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 35}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '-bp_show_elem-', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 37}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '__bp_show', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_show'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 45}, [{x, 0}]}.
    {test, is_eq, {f, 44}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 46}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 48}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 47}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 47}, [{x, 0}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 53}}.
  {label, 52}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 53}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 50}, [{x, 0}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, undefined}]}.
  {label, 49}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 39}, 2}.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 51}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_tagged'}, 2}.
  {label, 39}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 54}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 41}, 3}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '__bp_render'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 56}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 57}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
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

{function, '-bp_stringify-', 1, 59}.
  {label, 58}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 59}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 60}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 60}.
    {test, is_integer, {f, 61}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 61}.
    {call, 1, {f, 35}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-shower/1-fun-1-', 1, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-shower/1-fun-1-'}, 1}.
  {label, 27}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"v=">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 59}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '-wide/1-fun-2-', 1, 65}.
  {label, 64}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-wide/1-fun-2-'}, 1}.
  {label, 65}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 66}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 66}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/main.bp:24:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 67}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-3-', 1, 89}.
  {label, 88}.
    {line, [{location, "bp_load_cases_optional_float_function_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_float_function_value@main}, {atom, '-main/0-fun-3-'}, 1}.
  {label, 89}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {float, 0.25}], {x, 0}}.
    {deallocate, 1}.
    return.
