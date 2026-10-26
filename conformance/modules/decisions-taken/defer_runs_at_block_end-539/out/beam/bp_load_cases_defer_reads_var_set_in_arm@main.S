{module, bp_load_cases_defer_reads_var_set_in_arm@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__boom', 0}, {'__bp_priv__show', 1}, {'__bp_priv__viaCase', 1}, {'__bp_priv__viaIf', 1}, {'__bp_priv__viaValueCase', 1}, {'__bp_priv__viaValueIf', 1}]}.
{attributes, []}.
{labels, 116}.
%%% Decision 539 (amended) — the deferred expression reads a `var` when it
%%% runs, and a reassignment inside a nested arm counts: an arm that
%%% reassigns and then panics hands the defer the new value.

{function, boom, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, boom}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"boom">>}, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, viaIf, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, viaIf}, 1}.
  {label, 5}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 6}, {f, 32}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 33}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {call, 1, {f, 31}}.
    {jump, {f, 34}}.
  {label, 33}.
  {label, 34}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {try_end, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 32}.
    {try_case, {y, 6}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, viaCase, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, viaCase}, 1}.
  {label, 7}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 6}, {f, 68}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 70}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"c">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"y">>}, {x, 0}}.
    {call, 1, {f, 31}}.
    {jump, {f, 69}}.
  {label, 70}.
    {move, {literal, <<"d">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 69}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {try_end, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 68}.
    {try_case, {y, 6}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, viaValueCase, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, viaValueCase}, 1}.
  {label, 9}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 7}, {f, 72}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 74}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"e">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 3}}.
    {jump, {f, 73}}.
  {label, 74}.
    {move, {literal, <<"g">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 73}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {try_end, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 72}.
    {try_case, {y, 7}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, viaValueIf, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, viaValueIf}, 1}.
  {label, 11}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 7}, {f, 76}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 77}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"h">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 3}}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {literal, <<"i">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
  {label, 78}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {try_end, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 76}.
    {try_case, {y, 7}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"close ">>}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 3}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, show, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, show}, 1}.
  {label, 13}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 81}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"Ok ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {jump, {f, 80}}.
  {label, 81}.
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 83}, [{x, 0}, 3, {atom, std@failure@@Failure}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 83}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 84}, [{x, 0}, 3, {atom, std@failure@@Failure}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 84}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"Error ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {jump, {f, 80}}.
  {label, 82}.
    {case_end, {x, 0}}.
  {label, 80}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, main, 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, main}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 86}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 13}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 13}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 90}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 13}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 92}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 13}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 94}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 13}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 96}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 13}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 98}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 13}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 15}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/defer_reads_var_set_in_arm|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '_botopink_main'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 27}}.
    {call_last, 0, {f, 15}, 0}.

{function, main, 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, main}, 1}.
  {label, 25}.
    {call_only, 0, {f, 23}}.

{function, '__bp_load_siblings', 0, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 27}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 99}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 29}, 0}.
  {label, 99}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 29}.
    {test, is_nonempty_list, {f, 100}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 101}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 103}}.
  {label, 101}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 102}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 103}}.
  {label, 102}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 1}}.
    {move, {literal, <<"error: ~ts does not compile - refusing to run~n  ~p~n">>}, {x, 0}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, standard_error}, {x, 0}}.
    {call_ext, 2, {extfunc, file, write, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, halt, 1}}.
  {label, 103}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 29}, 2}.
  {label, 100}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_priv__boom', 0, 105}.
  {label, 104}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_priv__boom'}, 0}.
  {label, 105}.
    {call_only, 0, {f, 3}}.

{function, '__bp_priv__show', 1, 107}.
  {label, 106}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_priv__show'}, 1}.
  {label, 107}.
    {call_only, 1, {f, 13}}.

{function, '__bp_priv__viaCase', 1, 109}.
  {label, 108}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_priv__viaCase'}, 1}.
  {label, 109}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__viaIf', 1, 111}.
  {label, 110}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_priv__viaIf'}, 1}.
  {label, 111}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__viaValueCase', 1, 113}.
  {label, 112}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_priv__viaValueCase'}, 1}.
  {label, 113}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__viaValueIf', 1, 115}.
  {label, 114}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 20}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_priv__viaValueIf'}, 1}.
  {label, 115}.
    {call_only, 1, {f, 11}}.

{function, '__bp_tpl_0', 1, 31}.
  {label, 30}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 31}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_print', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_print'}, 1}.
  {label, 36}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 40}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 40}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 38}}.

{function, '-bp_show_elem-', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 42}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 38}}.

{function, '__bp_show', 2, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_show'}, 2}.
  {label, 38}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 50}, [{x, 0}]}.
    {test, is_eq, {f, 49}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 51}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 53}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 52}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 52}, [{x, 0}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 58}}.
  {label, 57}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 58}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 38}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 55}, [{x, 0}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, undefined}]}.
  {label, 54}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 44}, 2}.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 56}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_tagged'}, 2}.
  {label, 44}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 59}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 59}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 59}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 46}, 3}.
  {label, 60}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '__bp_render'}, 1}.
  {label, 46}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 61}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 62}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 48}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 38}}.
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

{function, '-bp_stringify-', 1, 64}.
  {label, 63}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 64}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 65}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 65}.
    {test, is_integer, {f, 66}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 66}.
    {call, 1, {f, 40}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-main/0-fun-0-', 0, 86}.
  {label, 85}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-main/0-fun-0-'}, 0}.
  {label, 86}.
    {allocate, 0, 0}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-1-', 0, 88}.
  {label, 87}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-main/0-fun-1-'}, 0}.
  {label, 88}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-2-', 0, 90}.
  {label, 89}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-main/0-fun-2-'}, 0}.
  {label, 90}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 7}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-3-', 0, 92}.
  {label, 91}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-main/0-fun-3-'}, 0}.
  {label, 92}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 9}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-4-', 0, 94}.
  {label, 93}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-main/0-fun-4-'}, 0}.
  {label, 94}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 9}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-5-', 0, 96}.
  {label, 95}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-main/0-fun-5-'}, 0}.
  {label, 96}.
    {allocate, 0, 0}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 11}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-6-', 0, 98}.
  {label, 97}.
    {line, [{location, "bp_load_cases_defer_reads_var_set_in_arm@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_reads_var_set_in_arm@main}, {atom, '-main/0-fun-6-'}, 0}.
  {label, 98}.
    {allocate, 0, 0}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 11}}.
    {deallocate, 0}.
    return.
