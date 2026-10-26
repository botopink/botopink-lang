{module, bp_load_cases_try_block_catch_value@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__half', 1}, {'__bp_priv__halves', 2}, {'__bp_priv__quarter', 1}]}.
{attributes, []}.
{labels, 77}.
%%% Decision 595 (2), (3), (4) — `try { … } catch …` is a region: every `try`
%%% written in the block hands its failure to the one `catch`, so a function
%%% with no `Result` in its return runs fallible calls. The block's value is its
%%% last expression written without `;`; the handler is the fallback — an
%%% expression, or a block whose value is its last expression.

{function, half, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, half}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ne_exact, {f, 20}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"odd">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 20}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 21}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 21}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 22}}.
  {label, 21}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/main.bp:11:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 22}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, quarter, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, quarter}, 1}.
  {label, 5}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {'try', {y, 2}, {f, 23}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 27}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 28}}.
  {label, 27}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 28}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 29}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 30}}.
  {label, 29}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 30}.
    {jump, {f, 26}}.
  {label, 26}.
    {try_end, {y, 2}}.
    {jump, {f, 25}}.
  {label, 23}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 24}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 25}.
    {deallocate, 3}.
    return.

{function, halves, 2, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, halves}, 2}.
  {label, 7}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {'try', {y, 5}, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 36}}.
  {label, 35}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 36}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 37}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 38}}.
  {label, 37}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 38}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 40}}.
    {jump, {f, 34}}.
  {label, 34}.
    {try_end, {y, 5}}.
    {jump, {f, 33}}.
  {label, 31}.
    {try_case, {y, 5}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 32}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {atom, true}, {x, 0}}.
    {move, {literal, <<"not even">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 42}}.
  {label, 42}.
    {jump, {f, 33}}.
  {label, 32}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 33}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {integer, 8}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {integer, 6}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/try_block_catch_value|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__half', 1, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_priv__half'}, 1}.
  {label, 72}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__halves', 2, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_priv__halves'}, 2}.
  {label, 74}.
    {call_only, 2, {f, 7}}.

{function, '__bp_priv__quarter', 1, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_priv__quarter'}, 1}.
  {label, 76}.
    {call_only, 1, {f, 5}}.

{function, '__bp_add', 2, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_add'}, 2}.
  {label, 40}.
    {test, is_binary, {f, 41}, [{x, 0}]}.
    {test, is_binary, {f, 41}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 41}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '__bp_print', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_print'}, 1}.
  {label, 44}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 48}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 46}}.

{function, '-bp_show_elem-', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 50}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 46}}.

{function, '__bp_show', 2, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_show'}, 2}.
  {label, 46}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 58}, [{x, 0}]}.
    {test, is_eq, {f, 57}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 59}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 61}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 60}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 60}, [{x, 0}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 66}}.
  {label, 65}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 66}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 46}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 63}, [{x, 0}]}.
    {test, is_ne_exact, {f, 63}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 63}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, undefined}]}.
  {label, 62}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 52}, 2}.
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 64}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_tagged'}, 2}.
  {label, 52}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 67}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 67}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 67}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 54}, 3}.
  {label, 68}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '__bp_render'}, 1}.
  {label, 54}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 69}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 70}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_try_block_catch_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_value@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 56}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 46}}.
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
