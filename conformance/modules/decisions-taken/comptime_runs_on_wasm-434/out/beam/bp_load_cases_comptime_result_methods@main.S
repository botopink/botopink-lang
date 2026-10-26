{module, bp_load_cases_comptime_result_methods@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__half', 1}, {'__bp_priv__measure', 1}, {'__bp_priv__summary', 1}]}.
{attributes, []}.
{labels, 86}.
%%% Decisions 331, 434 (5) — a `Result`'s methods run at build as they do
%%% when the program runs: `unwrapOr`, `isOk`, `isError`, `map` and
%%% `flatMap`, under a `comptime` and in a function it reaches — whose own
%%% `return` / `throw` make its `Result` — each compared with the run time.

{function, measure, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, measure}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"nope">>}, {x, 0}}.
    {test, is_eq_exact, {f, 20}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"no text">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, half, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, half}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"odd">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 23}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 24}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 24}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/main.bp:15:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 25}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, summary, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, summary}, 1}.
  {label, 7}.
    {allocate, 7, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, ok}]}.
    {move, {x, 0}, {x, 1}}.
    {get_tuple_element, {x, 0}, 1, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {jump, {f, 29}}.
  {label, 28}.
  {label, 29}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {integer, 0}, {x, 0}}.
  {label, 27}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 36}, [{x, 0}, 2, {atom, ok}]}.
    {move, {x, 0}, {x, 1}}.
    {get_tuple_element, {x, 0}, 1, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {jump, {f, 37}}.
  {label, 36}.
  {label, 37}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {integer, -1}, {x, 0}}.
  {label, 35}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 40}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 41}}.
  {label, 40}.
    {move, {atom, false}, {x, 0}}.
  {label, 41}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 43}}.
  {label, 42}.
    {move, {atom, false}, {x, 0}}.
  {label, 43}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 73}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 7}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 6, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {integer, 7}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {integer, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {literal, <<"true false 8 2">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {literal, <<"abcd">>}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_eq_exact, {f, 76}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, false}, {x, 0}}.
  {label, 77}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {literal, <<"false true 0 -1">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {literal, <<"nope">>}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_eq_exact, {f, 78}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 78}.
    {move, {atom, false}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 45}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/comptime_result_methods|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__half', 1, 81}.
  {label, 80}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_priv__half'}, 1}.
  {label, 81}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__measure', 1, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_priv__measure'}, 1}.
  {label, 83}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__summary', 1, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_priv__summary'}, 1}.
  {label, 85}.
    {call_only, 1, {f, 7}}.

{function, '__bp_tpl_0', 1, 22}.
  {label, 21}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 22}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '-summary/1-fun-0-', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '-summary/1-fun-0-'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 32}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 32}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:20:34">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 33}.
    {deallocate, 1}.
    return.

{function, '-summary/1-fun-1-', 1, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '-summary/1-fun-1-'}, 1}.
  {label, 39}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_print'}, 1}.
  {label, 45}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 49}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 47}}.

{function, '-bp_show_elem-', 1, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 51}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 47}}.

{function, '__bp_show', 2, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_show'}, 2}.
  {label, 47}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 59}, [{x, 0}]}.
    {test, is_eq, {f, 58}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 60}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 51}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 62}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 61}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 61}, [{x, 0}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 67}}.
  {label, 66}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 67}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 47}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 51}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 64}, [{x, 0}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 65}, [{x, 0}, {atom, undefined}]}.
  {label, 63}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 53}, 2}.
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 65}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 53}.
  {label, 52}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_tagged'}, 2}.
  {label, 53}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 68}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 68}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 68}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 55}, 3}.
  {label, 69}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 55}.
  {label, 54}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '__bp_render'}, 1}.
  {label, 55}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 70}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 71}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 57}.
  {label, 56}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 57}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 47}}.
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

{function, '-bp_stringify-', 1, 73}.
  {label, 72}.
    {line, [{location, "bp_load_cases_comptime_result_methods@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_result_methods@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 73}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 74}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 74}.
    {test, is_integer, {f, 75}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 75}.
    {call, 1, {f, 49}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
