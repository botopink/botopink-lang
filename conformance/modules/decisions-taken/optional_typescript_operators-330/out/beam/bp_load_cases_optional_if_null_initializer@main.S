{module, bp_load_cases_optional_if_null_initializer@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__grade', 1}, {'__bp_priv__half', 1}, {'__bp_priv__pick', 1}]}.
{attributes, []}.
{labels, 92}.
%%% Decision 330 — an `if` with a `null` arm is an optional: absent when that
%%% arm is taken, the other arm's value when it is not — a present `0` or
%%% `false` included — as a `val` / `var` initializer, an assignment and a
%%% `return`, an `else if` chain and a float payload too, on every target.

{function, pick, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, pick}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 20}, [{x, 0}, {atom, true}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 21}.
    {deallocate, 1}.
    return.

{function, grade, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, grade}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 22}, [{integer, 10}, {y, 0}]}.
    {move, {integer, 2}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {test, is_lt, {f, 24}, [{integer, 5}, {y, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 25}.
  {label, 23}.
    {deallocate, 1}.
    return.

{function, half, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, half}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 26}, [{x, 0}, {atom, true}]}.
    {move, {float, 0.5}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 27}.
    {deallocate, 1}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 17, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"be">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"alpha">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 28}, [{integer, 5}, {x, 0}]}.
    {move, {integer, 3}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 29}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 30}, [{integer, 1}, {x, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 31}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {integer, -1}, {x, 0}}.
  {label, 33}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_ne_exact, {f, 62}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {integer, -1}, {x, 0}}.
  {label, 63}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {integer, -1}, {x, 0}}.
  {label, 65}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {integer, -1}, {x, 0}}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {integer, 20}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {integer, -1}, {x, 0}}.
  {label, 69}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 70}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {integer, -1}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {integer, -1}, {x, 0}}.
  {label, 73}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 74}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {float, -1.0}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {float, -1.0}, {x, 0}}.
  {label, 77}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 78}, [{x, 0}, {atom, undefined}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 78}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 79}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {test, is_ne_exact, {f, 80}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {integer, -1}, {x, 0}}.
  {label, 81}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_lt, {f, 82}, [{integer, 5}, {x, 0}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 83}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {test, is_ne_exact, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {atom, true}, {x, 0}}.
  {label, 85}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {y, 2}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {y, 3}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 35}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 17}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {call, 0, {f, 9}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_if_null_initializer|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__grade', 1, 87}.
  {label, 86}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_priv__grade'}, 1}.
  {label, 87}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__half', 1, 89}.
  {label, 88}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_priv__half'}, 1}.
  {label, 89}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__pick', 1, 91}.
  {label, 90}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_priv__pick'}, 1}.
  {label, 91}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_print'}, 1}.
  {label, 35}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 39}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 37}}.

{function, '-bp_show_elem-', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 41}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 37}}.

{function, '__bp_show', 2, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_show'}, 2}.
  {label, 37}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 49}, [{x, 0}]}.
    {test, is_eq, {f, 48}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 50}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 52}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 51}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 51}, [{x, 0}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 57}}.
  {label, 56}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 57}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 37}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 54}, [{x, 0}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, undefined}]}.
  {label, 53}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 43}, 2}.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 55}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_tagged'}, 2}.
  {label, 43}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 58}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 58}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 58}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 45}, 3}.
  {label, 59}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '__bp_render'}, 1}.
  {label, 45}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 60}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 61}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_optional_if_null_initializer@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_if_null_initializer@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 47}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 37}}.
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
