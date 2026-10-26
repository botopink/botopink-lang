{module, bp_load_cases_defer_inner_panic_runs_once@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__inner', 0}, {'__bp_priv__show', 1}]}.
{attributes, []}.
{labels, 78}.
%%% Decision 539 (3) — a deferred statement that panics, written on a way
%%% out (`return`) inside an enclosing region, runs once, and the panic it
%%% raises is the one `attempt` answers.

{function, inner, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, inner}, 0}.
  {label, 3}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {'try', {y, 7}, {f, 22}}.
    {'try', {y, 6}, {f, 23}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {try_end, {y, 6}}.
    {move, {atom, true}, {x, 0}}.
    {move, {literal, <<"inner">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {literal, <<"from defer">>}, {x, 0}}.
    {call, 1, {f, 54}}.
    {jump, {f, 24}}.
  {label, 24}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {try_end, {y, 7}}.
    {move, {literal, <<"outer">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 23}.
    {try_case, {y, 6}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {atom, true}, {x, 0}}.
    {move, {literal, <<"inner">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {literal, <<"from defer">>}, {x, 0}}.
    {call, 1, {f, 54}}.
    {jump, {f, 56}}.
  {label, 56}.
    {move, {y, 4}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 22}.
    {try_case, {y, 7}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {literal, <<"outer">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, show, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, show}, 1}.
  {label, 5}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 59}, [{x, 0}, 2, {atom, ok}]}.
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
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {jump, {f, 58}}.
  {label, 59}.
    {test, is_tagged_tuple, {f, 64}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 65}, [{x, 0}, 3, {atom, std@failure@@Failure}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 65}.
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
    {test, is_tagged_tuple, {f, 66}, [{x, 0}, 3, {atom, std@failure@@Failure}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 66}.
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
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {jump, {f, 58}}.
  {label, 64}.
    {case_end, {x, 0}}.
  {label, 58}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 68}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 5}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/defer_inner_panic_runs_once|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 19}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_load_siblings', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 69}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 21}, 0}.
  {label, 69}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 21}.
    {test, is_nonempty_list, {f, 70}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 71}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 73}}.
  {label, 71}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 72}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 73}}.
  {label, 72}.
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
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 21}, 2}.
  {label, 70}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_priv__inner', 0, 75}.
  {label, 74}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_priv__inner'}, 0}.
  {label, 75}.
    {call_only, 0, {f, 3}}.

{function, '__bp_priv__show', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_priv__show'}, 1}.
  {label, 77}.
    {call_only, 1, {f, 5}}.

{function, '__bp_print', 1, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_print'}, 1}.
  {label, 26}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 30}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 28}}.

{function, '-bp_show_elem-', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 32}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 28}}.

{function, '__bp_show', 2, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_show'}, 2}.
  {label, 28}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 40}, [{x, 0}]}.
    {test, is_eq, {f, 39}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 41}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 43}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 42}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 42}, [{x, 0}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 48}}.
  {label, 47}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 48}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 28}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 45}, [{x, 0}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, undefined}]}.
  {label, 44}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 34}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 46}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_tagged'}, 2}.
  {label, 34}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 49}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 49}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 49}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 36}, 3}.
  {label, 50}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_render'}, 1}.
  {label, 36}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 51}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 52}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 38}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 28}}.
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

{function, '__bp_tpl_0', 1, 54}.
  {label, 53}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 54}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, panic}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '-bp_stringify-', 1, 61}.
  {label, 60}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 61}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 62}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 62}.
    {test, is_integer, {f, 63}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 63}.
    {call, 1, {f, 30}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-main/0-fun-0-', 0, 68}.
  {label, 67}.
    {line, [{location, "bp_load_cases_defer_inner_panic_runs_once@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_defer_inner_panic_runs_once@main}, {atom, '-main/0-fun-0-'}, 0}.
  {label, 68}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {deallocate, 0}.
    return.
