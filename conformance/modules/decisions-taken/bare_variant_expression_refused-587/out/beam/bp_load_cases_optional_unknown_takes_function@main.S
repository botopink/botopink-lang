{module, bp_load_cases_optional_unknown_takes_function@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__has', 1}, {'__bp_priv__reverseBody', 1}]}.
{attributes, []}.
{labels, 54}.
%%% Decision 587 — a `?unknown` parameter admits a function value: the
%%% `Implementation.Wasm(body: reverseBody)` of a source annotation names the
%%% function it runs, and a function handed where `?unknown` is expected is a
%%% value like any other.

{function, reverseBody, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, reverseBody}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, lists, reverse, 1}, 1}.

{function, has, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, has}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 19}, [{x, 0}, 3, {atom, bp_load_cases_optional_unknown_takes_function@main@@Hook__v__run}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {get_tuple_element, {x, 0}, 2, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_ne_exact, {f, 20}, [{y, 1}, {atom, undefined}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, false}, {x, 0}}.
  {label, 21}.
    {jump, {f, 18}}.
  {label, 19}.
    {case_end, {x, 0}}.
  {label, 18}.
    {deallocate, 3}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 3}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_unknown_takes_function@main@@Hook__v__run}, {x, 1}, {x, 0}]}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {literal, <<"none">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_unknown_takes_function@main@@Hook__v__run}, {atom, undefined}, {x, 0}]}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 23}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_unknown_takes_function|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_priv__has', 1, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_priv__has'}, 1}.
  {label, 51}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__reverseBody', 1, 53}.
  {label, 52}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_priv__reverseBody'}, 1}.
  {label, 53}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_print'}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 27}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 25}}.

{function, '-bp_show_elem-', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 29}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 25}}.

{function, '__bp_show', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_show'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 37}, [{x, 0}]}.
    {test, is_eq, {f, 36}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 38}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 40}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 39}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 39}, [{x, 0}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 45}}.
  {label, 44}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 45}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 25}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 42}, [{x, 0}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, undefined}]}.
  {label, 41}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 31}, 2}.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 43}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_tagged'}, 2}.
  {label, 31}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 46}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 46}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 46}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 33}, 3}.
  {label, 47}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '__bp_render'}, 1}.
  {label, 33}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 48}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 49}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_optional_unknown_takes_function@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_unknown_takes_function@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 35}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 25}}.
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
