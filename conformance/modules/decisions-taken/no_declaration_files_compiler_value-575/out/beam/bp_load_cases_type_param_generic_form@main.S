{module, bp_load_cases_type_param_generic_form@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_first', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv____bp_orDefault__type', 1}, {'__bp_priv__greeting', 0}, {'__bp_priv__orDefault', 2}]}.
{attributes, []}.
{labels, 87}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 24}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 29}}.
  {label, 27}.
  {label, 25}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 30}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 31}}.
  {label, 30}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 29}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 29}}.
  {label, 33}.
  {label, 31}.
    {deallocate, 6}.
    return.
%%% Decision 575 (5) — `type<T>` is the type of the type `T`: a `comptime`
%%% parameter written `comptime t: type<T>` takes a type, and the type
%%% argument binds `T` for the rest of the signature — here the decorator's
%%% declaration pattern `fn() -> T`, and in `orDefault` the fallback.

{function, greeting, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, greeting}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, orDefault, 2, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, orDefault}, 2}.
  {label, 9}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 2, {atom, bp_load_cases_type_param_generic_form@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 34}.
    {deallocate, 2}.
    return.

{function, '__bp_orDefault__type', 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_orDefault__type'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, main}, 0}.
  {label, 13}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"greeting">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_type_param_generic_form@main@@Provides}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 37}}.
    {test, is_eq, {f, 38}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 40}}.
  {label, 38}.
    {test, is_tagged_tuple, {f, 39}, [{x, 0}, 2, {atom, bp_load_cases_type_param_generic_form@main@@Provides}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 40}}.
  {label, 39}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 40}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 41}}.
  {label, 35}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 41}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {call, 0, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_type_param_generic_form@main@@Box}, {integer, 9}]}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_loaded_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {call, 0, {f, 13}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/type_param_generic_form|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '_botopink_main'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 13}, 0}.

{function, main, 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, main}, 1}.
  {label, 23}.
    {call_only, 0, {f, 21}}.

{function, 'array_first', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, 'array_first'}, 1}.
  {label, 37}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 71}, 1}.

{function, '__bp_priv__array_first', 1, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_priv__array_first'}, 1}.
  {label, 76}.
    {call_only, 1, {f, 37}}.

{function, '__bp_priv__array_range', 2, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 78}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 80}.
  {label, 79}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 80}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv____bp_orDefault__type', 1, 82}.
  {label, 81}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_priv____bp_orDefault__type'}, 1}.
  {label, 82}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__greeting', 0, 84}.
  {label, 83}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_priv__greeting'}, 0}.
  {label, 84}.
    {call_only, 0, {f, 7}}.

{function, '__bp_priv__orDefault', 2, 86}.
  {label, 85}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_priv__orDefault'}, 2}.
  {label, 86}.
    {call_only, 2, {f, 9}}.

{function, '__bp_print', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_print'}, 1}.
  {label, 43}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 47}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 45}}.

{function, '-bp_show_elem-', 1, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 49}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 45}}.

{function, '__bp_show', 2, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_show'}, 2}.
  {label, 45}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 57}, [{x, 0}]}.
    {test, is_eq, {f, 56}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 58}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 60}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 59}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 59}, [{x, 0}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 65}}.
  {label, 64}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 65}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 45}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 62}, [{x, 0}]}.
    {test, is_ne_exact, {f, 62}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 62}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 63}, [{x, 0}, {atom, undefined}]}.
  {label, 61}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 51}, 2}.
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 63}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_tagged'}, 2}.
  {label, 51}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 66}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 66}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 66}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 53}, 3}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 53}.
  {label, 52}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_render'}, 1}.
  {label, 53}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 68}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 69}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 55}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 55}.
  {label, 54}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 55}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 45}}.
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

{function, '-bp_at-', 2, 71}.
  {label, 70}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '-bp_at-'}, 2}.
  {label, 71}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 73}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 72}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 73}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 72}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 72}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_type_param_generic_form@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_type_param_generic_form@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 29}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 74}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 74}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
