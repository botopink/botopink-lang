{module, bp_load_cases_try_in_catch_body_propagates@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__backup', 1}, {'__bp_priv__either', 1}, {'__bp_priv__load', 1}, {'__bp_priv__primary', 1}, {'__bp_priv__show', 1}]}.
{attributes, []}.
{labels, 93}.
%%% Decision 595 (6) — a `try` in the handler's body belongs to the enclosing
%%% region or the function, never to its own `catch`: `backup`'s failure leaves
%%% `load` as its `Error`, and in `either` it reaches the outer region's
%%% `catch`.

{function, primary, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, primary}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 24}, [{integer, 10}, {y, 0}]}.
    {move, {literal, <<"primary down">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 24}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, backup, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, backup}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 25}, [{integer, 20}, {y, 0}]}.
    {move, {literal, <<"backup down">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 25}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 100}], {x, 0}}.
    {test, is_ge, {f, 26}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 26}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:15:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 27}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, load, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, load}, 1}.
  {label, 7}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {'try', {y, 2}, {f, 28}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 33}.
    {jump, {f, 31}}.
  {label, 31}.
    {try_end, {y, 2}}.
    {jump, {f, 30}}.
  {label, 28}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 29}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 36}}.
  {label, 35}.
    {deallocate, 3}.
    return.
  {label, 36}.
    {jump, {f, 34}}.
  {label, 34}.
    {jump, {f, 30}}.
  {label, 29}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 30}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 37}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 37}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 38}}.
  {label, 37}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:20:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 38}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 3}.
    return.

{function, either, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, either}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {'try', {y, 2}, {f, 39}}.
    {move, {atom, true}, {x, 0}}.
    {'try', {y, 1}, {f, 43}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 47}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 48}}.
  {label, 47}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 48}.
    {jump, {f, 46}}.
  {label, 46}.
    {try_end, {y, 1}}.
    {jump, {f, 45}}.
  {label, 43}.
    {try_case, {y, 1}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 44}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 51}}.
  {label, 50}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 51}.
    {jump, {f, 49}}.
  {label, 49}.
    {jump, {f, 45}}.
  {label, 44}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 45}.
    {jump, {f, 42}}.
  {label, 42}.
    {try_end, {y, 2}}.
    {jump, {f, 41}}.
  {label, 39}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 40}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 41}}.
  {label, 40}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 41}.
    {deallocate, 3}.
    return.

{function, show, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, show}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {jump, {f, 52}}.
  {label, 53}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 52}}.
  {label, 54}.
    {case_end, {x, 0}}.
  {label, 52}.
    {deallocate, 3}.
    return.

{function, main, 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, main}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {integer, 5}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {integer, 15}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {integer, 25}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {integer, 5}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {integer, 15}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {integer, 25}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 56}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/try_in_catch_body_propagates|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '_botopink_main'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 13}, 0}.

{function, main, 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, main}, 1}.
  {label, 23}.
    {call_only, 0, {f, 21}}.

{function, '__bp_priv__backup', 1, 84}.
  {label, 83}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_priv__backup'}, 1}.
  {label, 84}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__either', 1, 86}.
  {label, 85}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_priv__either'}, 1}.
  {label, 86}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__load', 1, 88}.
  {label, 87}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_priv__load'}, 1}.
  {label, 88}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__primary', 1, 90}.
  {label, 89}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_priv__primary'}, 1}.
  {label, 90}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__show', 1, 92}.
  {label, 91}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_priv__show'}, 1}.
  {label, 92}.
    {call_only, 1, {f, 11}}.

{function, '__bp_print', 1, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_print'}, 1}.
  {label, 56}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 60}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 58}}.

{function, '-bp_show_elem-', 1, 62}.
  {label, 61}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 62}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 58}}.

{function, '__bp_show', 2, 58}.
  {label, 57}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_show'}, 2}.
  {label, 58}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 70}, [{x, 0}]}.
    {test, is_eq, {f, 69}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 69}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 70}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 71}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 62}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 73}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 72}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 72}, [{x, 0}]}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 78}}.
  {label, 77}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 78}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 58}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 72}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 62}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 75}, [{x, 0}]}.
    {test, is_ne_exact, {f, 75}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 75}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
  {label, 74}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 64}, 2}.
  {label, 75}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 76}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 64}.
  {label, 63}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_tagged'}, 2}.
  {label, 64}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 79}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 79}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 79}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 66}, 3}.
  {label, 80}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 66}.
  {label, 65}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '__bp_render'}, 1}.
  {label, 66}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 81}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 82}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 82}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 68}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 68}.
  {label, 67}.
    {line, [{location, "bp_load_cases_try_in_catch_body_propagates@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_in_catch_body_propagates@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 68}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 58}}.
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
