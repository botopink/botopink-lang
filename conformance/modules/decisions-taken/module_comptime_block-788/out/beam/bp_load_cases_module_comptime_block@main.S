{module, bp_load_cases_module_comptime_block@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {'__bp_comptime_0_at', 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {main, 0}, {'__bp_comptime_1_at', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}]}.
{attributes, []}.
{labels, 62}.
%%% Decision 788 — two top-level `comptime` blocks run at build in the order
%%% written; `f`, whose every parameter is `comptime`, is expanded at each
%%% call, and the `compiler.init` it writes runs at program start, in the
%%% order the blocks registered it, before `main`.
% Expanded where a block calls it: its `print` is the build's output.

{function, '__bp_comptime_0_at', 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_comptime_0_at'}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"init ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_0', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_init_0'}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_module_comptime_block@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 5}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_module_comptime_block@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 60}.
    {deallocate, 1}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"main">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_comptime_1_at', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_comptime_1_at'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_1', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 13}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"init ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_1', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_init_1'}, 0}.
  {label, 15}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_module_comptime_block@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 13}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_module_comptime_block@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 61}.
    {deallocate, 1}.
    return.

{function, '__bp_loaded_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 9}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/module_comptime_block|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '_botopink_main'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 7}}.
    {call, 0, {f, 15}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, main}, 1}.
  {label, 25}.
    {call_only, 0, {f, 23}}.

{function, '_botopink_init', 0, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '_botopink_init'}, 0}.
  {label, 27}.
    {allocate, 0, 0}.
    {move, {literal, {bp_load_cases_module_comptime_block@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_module_comptime_block@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {call, 0, {f, 7}}.
    {call, 0, {f, 15}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_print', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_print'}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 33}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 31}}.

{function, '-bp_show_elem-', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 35}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 31}}.

{function, '__bp_show', 2, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_show'}, 2}.
  {label, 31}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 43}, [{x, 0}]}.
    {test, is_eq, {f, 42}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 44}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 46}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 45}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 45}, [{x, 0}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 51}}.
  {label, 50}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 51}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 48}, [{x, 0}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 49}, [{x, 0}, {atom, undefined}]}.
  {label, 47}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 37}, 2}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 49}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_tagged'}, 2}.
  {label, 37}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 52}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 52}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 52}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 39}, 3}.
  {label, 53}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '__bp_render'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 54}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 55}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 31}}.
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

{function, '-bp_stringify-', 1, 57}.
  {label, 56}.
    {line, [{location, "bp_load_cases_module_comptime_block@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_module_comptime_block@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 57}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 58}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 58}.
    {test, is_integer, {f, 59}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 59}.
    {call, 1, {f, 33}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
