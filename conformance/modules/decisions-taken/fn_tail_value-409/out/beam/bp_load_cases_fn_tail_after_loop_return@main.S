{module, bp_load_cases_fn_tail_after_loop_return@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__countdown', 1}, {'__bp_priv__describe', 1}, {'__bp_priv__firstNegative', 1}]}.
{attributes, []}.
{labels, 72}.
%%% Decision 409 — an early `return` from inside a loop or a `case` arm leaves
%%% the function; the body's last expression written without `;` is its value
%%% on every other path: after a `for`, a statement `case` and a `while`.

{function, firstNegative, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, firstNegative}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {'try', {y, 1}, {f, 23}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {try_end, {y, 1}}.
    {jump, {f, 26}}.
  {label, 23}.
    {try_case, {y, 1}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 24}, [{x, 1}, 2, {atom, '__bp_try'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {test, is_tagged_tuple, {f, 25}, [{x, 1}, 2, {atom, '__bp_return'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 25}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 26}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, describe, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, describe}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 28}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 28}.
    {move, {atom, ok}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 27}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"n=">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, countdown, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, countdown}, 1}.
  {label, 7}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 4}]}.
  {label, 61}.
    {test, is_lt, {f, 62}, [{integer, 0}, {y, 1}]}.
    {test, is_eq_exact, {f, 63}, [{y, 1}, {integer, 2}]}.
    {move, {literal, <<"stopped at 2">>}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 63}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 64}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 64}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:28:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 65}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 61}}.
  {label, 62}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"reached ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {integer, 5}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/fn_tail_after_loop_return|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__countdown', 1, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_priv__countdown'}, 1}.
  {label, 67}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__describe', 1, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_priv__describe'}, 1}.
  {label, 69}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__firstNegative', 1, 71}.
  {label, 70}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_priv__firstNegative'}, 1}.
  {label, 71}.
    {call_only, 1, {f, 3}}.

{function, '-firstNegative/1-fun-0-', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '-firstNegative/1-fun-0-'}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 22}, [{y, 0}, {integer, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_return'}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 22}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_print'}, 1}.
  {label, 30}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 34}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 32}}.

{function, '-bp_show_elem-', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 36}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 32}}.

{function, '__bp_show', 2, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_show'}, 2}.
  {label, 32}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 44}, [{x, 0}]}.
    {test, is_eq, {f, 43}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 45}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 47}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 46}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 46}, [{x, 0}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 52}}.
  {label, 51}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 52}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 32}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 49}, [{x, 0}]}.
    {test, is_ne_exact, {f, 49}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 49}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, undefined}]}.
  {label, 48}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 38}, 2}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 50}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_tagged'}, 2}.
  {label, 38}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 53}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 53}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 53}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 40}, 3}.
  {label, 54}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '__bp_render'}, 1}.
  {label, 40}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 55}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 56}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 42}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 32}}.
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

{function, '-bp_stringify-', 1, 58}.
  {label, 57}.
    {line, [{location, "bp_load_cases_fn_tail_after_loop_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_after_loop_return@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 58}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 59}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 59}.
    {test, is_integer, {f, 60}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 60}.
    {call, 1, {f, 34}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
