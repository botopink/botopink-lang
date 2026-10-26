{module, bp_load_cases_module_var@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {bump, 0}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_hits', 1}, {'__bp_priv____bp_swap_hits', 1}, {'__bp_priv____bp_tab_hits', 0}, {'__bp_priv__hits', 0}]}.
{attributes, []}.
{labels, 82}.
%%% Decision 28's last half, front 17 step 2 — a module-level `var` is one value
%%% per execution context: the program on commonJS and wasm, the process on
%%% the BEAM. Two writes through a `fn`, one read: `2`.
%%% 
%%% erlang and beam are C-10's (`beamMemory` steps 4–5): today erlang emits
%%% `hits() -> 0.` and `Hits = (Hits + 1).` (unbound, the module does not
%%% compile) and beam drops the write (`%% assign to unknown variable: hits`)
%%% and prints `0` at exit 0.

    %% var hits — beamMemory(.Ets)
{function, hits, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, hits}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {call, 0, {f, 27}}.
    {move, {atom, bp_load_cases_module_var@main@@hits}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_hits', 0, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_tab_hits'}, 0}.
  {label, 27}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_module_var@main@@hits}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, undefined}]}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, bp_load_cases_module_var@main@@hits}, {x, 0}}.
    {call_last, 2, {f, 21}, 0}.
  {label, 32}.
    {move, {atom, bp_load_cases_module_var@main@@hits}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_hits', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_set_hits'}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 27}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, bp_load_cases_module_var@main@@hits}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_hits', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_swap_hits'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 27}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@beam, etsSwap, 2}, 1}.

{function, bump, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, bump}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 31}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {call, 0, {f, 5}}.
    {call, 0, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_module_var@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_module_var@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/module_var|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '_botopink_init', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '_botopink_init'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_ets', 2, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_ets'}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 23}, 2}.
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 23}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 67}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 69}}.
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, bp_load_cases_module_var@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {y, 2}, {y, 3}}.
  {label, 69}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 23}, 4}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 25}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 70}}.
    {move, {literal, [named_table, public, set]}, {x, 1}}.
    {call_ext, 2, {extfunc, std@beam, etsNew, 2}}.
    {try_end, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 1}, {list, [{y, 1}, {y, 0}]}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@beam, etsPut, 2}}.
    {bif, self, {f, 0}, [], {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, register, 2}}.
    {move, {atom, infinity}, {x, 0}}.
    {call_ext_last, 1, {extfunc, timer, sleep, 1}, 3}.
  {label, 70}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 71}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 71}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, '__bp_priv____bp_ets', 2, 73}.
  {label, 72}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 73}.
    {call_only, 2, {f, 21}}.

{function, '__bp_priv____bp_set_hits', 1, 75}.
  {label, 74}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_priv____bp_set_hits'}, 1}.
  {label, 75}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv____bp_swap_hits', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_priv____bp_swap_hits'}, 1}.
  {label, 77}.
    {call_only, 1, {f, 31}}.

{function, '__bp_priv____bp_tab_hits', 0, 79}.
  {label, 78}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_priv____bp_tab_hits'}, 0}.
  {label, 79}.
    {call_only, 0, {f, 27}}.

{function, '__bp_priv__hits', 0, 81}.
  {label, 80}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 20}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_priv__hits'}, 0}.
  {label, 81}.
    {call_only, 0, {f, 3}}.

{function, '-bump/0-fun-0-', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '-bump/0-fun-0-'}, 1}.
  {label, 34}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 35}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 35}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 36}}.
  {label, 35}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:15:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 36}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_print'}, 1}.
  {label, 38}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 42}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 40}}.

{function, '-bp_show_elem-', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 44}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 40}}.

{function, '__bp_show', 2, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_show'}, 2}.
  {label, 40}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 52}, [{x, 0}]}.
    {test, is_eq, {f, 51}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 53}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 55}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 54}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 54}, [{x, 0}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 60}}.
  {label, 59}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 60}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 40}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 57}, [{x, 0}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, undefined}]}.
  {label, 56}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 46}, 2}.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 58}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_tagged'}, 2}.
  {label, 46}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 61}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 61}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 61}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 48}, 3}.
  {label, 62}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '__bp_render'}, 1}.
  {label, 48}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 63}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 64}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_module_var@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_var@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 50}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 40}}.
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
