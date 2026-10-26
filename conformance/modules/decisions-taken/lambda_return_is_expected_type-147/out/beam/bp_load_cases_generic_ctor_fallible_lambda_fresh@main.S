{module, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {optionalOf, 2}, {arrayOf, 2}, {'__bp_priv__present', 1}, {'__bp_priv__shout', 1}]}.
{attributes, []}.
{labels, 75}.
%%% Decision 147 (lg-a) beside a generic constructor: a lambda argument of a
%%% fallible field takes the expectation of a FRESH instance of the
%%% constructor, so `Box(…)` answering `Box<?T>` in one method leaves the next
%%% `Box(…)`, answering `Box<Array<T>>`, free.

{function, present, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, present}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 23}, 2}.

{function, optionalOf, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, optionalOf}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {deallocate, 3}.
    return.
  {label, 27}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, arrayOf, 2, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, arrayOf}, 2}.
  {label, 7}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {deallocate, 4}.
    return.
  {label, 29}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, shout, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, shout}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"empty">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 30}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"!">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}, {x, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box, array, 1}}.
    {test, is_tagged_tuple, {f, 63}, [{x, 0}, 2, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 63}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"hi">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {test, is_tagged_tuple, {f, 64}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, nil, {x, 0}}.
  {label, 65}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {test, is_tagged_tuple, {f, 66}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {atom, false}, {x, 0}}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box, optional, 1}}.
    {test, is_tagged_tuple, {f, 68}, [{x, 0}, 2, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 68}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"yo">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {test, is_tagged_tuple, {f, 69}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 70}}.
  {label, 69}.
    {move, {atom, false}, {x, 0}}.
  {label, 70}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/generic_ctor_fallible_lambda_fresh|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__present', 1, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_priv__present'}, 1}.
  {label, 72}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__shout', 1, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_priv__shout'}, 1}.
  {label, 74}.
    {call_only, 1, {f, 9}}.

{function, '-bp_at-', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '-bp_at-'}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 25}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 24}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 25}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 24}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 24}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_print'}, 1}.
  {label, 32}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 36}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 34}}.

{function, '-bp_show_elem-', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 38}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 34}}.

{function, '__bp_show', 2, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_show'}, 2}.
  {label, 34}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 46}, [{x, 0}]}.
    {test, is_eq, {f, 45}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 47}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 49}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 48}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 48}, [{x, 0}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 54}}.
  {label, 53}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 54}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 34}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 51}, [{x, 0}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
  {label, 50}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 40}, 2}.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 52}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_tagged'}, 2}.
  {label, 40}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 55}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 55}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 55}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 42}, 3}.
  {label, 56}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '__bp_render'}, 1}.
  {label, 42}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 57}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 58}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 44}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 34}}.
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

{function, '-bp_stringify-', 1, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_generic_ctor_fallible_lambda_fresh@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_generic_ctor_fallible_lambda_fresh@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 60}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 61}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 61}.
    {test, is_integer, {f, 62}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 62}.
    {call, 1, {f, 36}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
