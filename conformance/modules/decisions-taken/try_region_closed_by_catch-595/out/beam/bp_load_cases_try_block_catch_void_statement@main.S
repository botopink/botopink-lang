{module, bp_load_cases_try_block_catch_void_statement@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__save', 1}, {'__bp_priv__saveBoth', 2}]}.
{attributes, []}.
{labels, 64}.
%%% Decision 595 (4) — a region whose value is `void` is a statement; its
%%% handler is a block with at least one statement. The first failing `try`
%%% ends the region: the second `save` does not run.

{function, save, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, save}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 18}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 18}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"saved ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, saveBoth, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, saveBoth}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {'try', {y, 2}, {f, 51}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 55}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 56}}.
  {label, 55}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 56}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 58}.
    {jump, {f, 54}}.
  {label, 54}.
    {try_end, {y, 2}}.
    {jump, {f, 53}}.
  {label, 51}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 52}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {literal, <<"not saved">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {jump, {f, 59}}.
  {label, 59}.
    {jump, {f, 53}}.
  {label, 52}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 53}.
    {move, {literal, <<"done">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 20}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 5}}.
    {move, {integer, -1}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 5}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/try_block_catch_void_statement|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_priv__save', 1, 61}.
  {label, 60}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_priv__save'}, 1}.
  {label, 61}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__saveBoth', 2, 63}.
  {label, 62}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_priv__saveBoth'}, 2}.
  {label, 63}.
    {call_only, 2, {f, 5}}.

{function, '__bp_print', 1, 20}.
  {label, 19}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_print'}, 1}.
  {label, 20}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 24}.
  {label, 23}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 24}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 22}}.

{function, '-bp_show_elem-', 1, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 26}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 22}}.

{function, '__bp_show', 2, 22}.
  {label, 21}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_show'}, 2}.
  {label, 22}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 34}, [{x, 0}]}.
    {test, is_eq, {f, 33}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 35}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 26}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 37}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 36}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 36}, [{x, 0}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 42}}.
  {label, 41}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 42}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 22}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 26}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 39}, [{x, 0}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, undefined}]}.
  {label, 38}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 28}, 2}.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 40}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_tagged'}, 2}.
  {label, 28}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 43}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 43}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 43}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 30}, 3}.
  {label, 44}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '__bp_render'}, 1}.
  {label, 30}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 45}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 46}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 32}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 22}}.
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

{function, '-bp_stringify-', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_try_block_catch_void_statement@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_void_statement@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 48}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 49}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 49}.
    {test, is_integer, {f, 50}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 50}.
    {call, 1, {f, 24}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
