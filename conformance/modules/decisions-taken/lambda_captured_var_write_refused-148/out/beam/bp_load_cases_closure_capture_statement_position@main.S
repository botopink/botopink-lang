{module, bp_load_cases_closure_capture_statement_position@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_hits', 1}, {'__bp_priv____bp_swap_hits', 1}, {'__bp_priv____bp_tab_hits', 0}, {'__bp_priv__hits', 0}, {'__bp_priv__run', 2}]}.
{attributes, []}.
{labels, 100}.
%%% Decision 148 (lg-b) — the two shapes that may write a captured `var`: a
%%% `forEach` body, and a local closure called only at statement position
%%% (here also from inside a loop and a `forEach` body). A counter shared
%%% across calls is a module-level `var`, which any lambda may write.

    %% var hits — beamMemory(.Ets)
{function, hits, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, hits}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {call, 0, {f, 27}}.
    {move, {atom, bp_load_cases_closure_capture_statement_position@main@@hits}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_hits', 0, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_tab_hits'}, 0}.
  {label, 27}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_closure_capture_statement_position@main@@hits}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, undefined}]}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, bp_load_cases_closure_capture_statement_position@main@@hits}, {x, 0}}.
    {call_last, 2, {f, 21}, 0}.
  {label, 32}.
    {move, {atom, bp_load_cases_closure_capture_statement_position@main@@hits}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_hits', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_set_hits'}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 27}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, bp_load_cases_closure_capture_statement_position@main@@hits}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_hits', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_swap_hits'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 27}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@beam, etsSwap, 2}, 1}.

{function, run, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, run}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_fun, 0}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 33}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 33}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 34}}.
  {label, 33}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:11:16">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 34}.
    {deallocate, 2}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 5, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
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
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 40}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {call, 0, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/closure_capture_statement_position|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '_botopink_init', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '_botopink_init'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_ets', 2, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_ets'}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 23}, 2}.
  {label, 81}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 23}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 82}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 83}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 85}}.
  {label, 83}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, bp_load_cases_closure_capture_statement_position@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {y, 2}, {y, 3}}.
  {label, 85}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 23}, 4}.
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 25}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 86}}.
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
  {label, 86}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 87}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 87}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 87}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, '__bp_priv____bp_ets', 2, 89}.
  {label, 88}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 89}.
    {call_only, 2, {f, 21}}.

{function, '__bp_priv____bp_set_hits', 1, 91}.
  {label, 90}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_priv____bp_set_hits'}, 1}.
  {label, 91}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv____bp_swap_hits', 1, 93}.
  {label, 92}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_priv____bp_swap_hits'}, 1}.
  {label, 93}.
    {call_only, 1, {f, 31}}.

{function, '__bp_priv____bp_tab_hits', 0, 95}.
  {label, 94}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_priv____bp_tab_hits'}, 0}.
  {label, 95}.
    {call_only, 0, {f, 27}}.

{function, '__bp_priv__hits', 0, 97}.
  {label, 96}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 20}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_priv__hits'}, 0}.
  {label, 97}.
    {call_only, 0, {f, 3}}.

{function, '__bp_priv__run', 2, 99}.
  {label, 98}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 21}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_priv__run'}, 2}.
  {label, 99}.
    {call_only, 2, {f, 5}}.

{function, '-main/0-fun-0-', 2, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-main/0-fun-0-'}, 2}.
  {label, 36}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 37}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 37}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 38}}.
  {label, 37}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:17:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 38}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-1-', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-main/0-fun-1-'}, 1}.
  {label, 40}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 10}], {x, 0}}.
    {test, is_ge, {f, 41}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 41}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 42}}.
  {label, 41}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:20:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 42}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-2-', 3, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-main/0-fun-2-'}, 3}.
  {label, 44}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-main/0-fun-3-', 3, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-main/0-fun-3-'}, 3}.
  {label, 46}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_fun, 1}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_print', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_print'}, 1}.
  {label, 48}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 52}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 52}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 50}}.

{function, '-bp_show_elem-', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 54}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 50}}.

{function, '__bp_show', 2, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_show'}, 2}.
  {label, 50}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 62}, [{x, 0}]}.
    {test, is_eq, {f, 61}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 63}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 65}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 64}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 64}, [{x, 0}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 70}}.
  {label, 69}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 70}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 50}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 67}, [{x, 0}]}.
    {test, is_ne_exact, {f, 67}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 67}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
  {label, 66}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 56}, 2}.
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 68}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_tagged'}, 2}.
  {label, 56}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 71}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 71}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 71}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 58}, 3}.
  {label, 72}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 58}.
  {label, 57}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '__bp_render'}, 1}.
  {label, 58}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 73}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 74}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 60}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 50}}.
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

{function, '-main/0-fun-5-', 1, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-main/0-fun-5-'}, 1}.
  {label, 78}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 79}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 79}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 80}}.
  {label, 79}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:30:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 80}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-4-', 0, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_closure_capture_statement_position@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_closure_capture_statement_position@main}, {atom, '-main/0-fun-4-'}, 0}.
  {label, 76}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call, 1, {f, 31}}.
    {move, {integer, 1}, {x, 0}}.
    {deallocate, 0}.
    return.
