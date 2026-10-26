{module, bp_load_cases_block_jump_label_reaches_loop@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__firstPair', 2}, {'__bp_priv__sumBeforeTwo', 2}]}.
{attributes, []}.
{labels, 86}.
%%% Decision 541 (2) — a labelled `break :outer` in a `case` arm's block, or
%%% in a plain block, reaches the named outer loop: the block is no closure.

{function, firstPair, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, firstPair}, 2}.
  {label, 3}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {'try', {y, 3}, {f, 34}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 3}}.
    {jump, {f, 36}}.
  {label, 34}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 35}, [{x, 1}, 3, {atom, '__bp_label_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, outer}]}.
    {get_tuple_element, {x, 1}, 2, {x, 0}}.
    {jump, {f, 36}}.
  {label, 35}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 36}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, sumBeforeTwo, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, sumBeforeTwo}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {'try', {y, 3}, {f, 51}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 3}}.
    {jump, {f, 53}}.
  {label, 51}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 52}, [{x, 1}, 3, {atom, '__bp_label_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, outer}]}.
    {get_tuple_element, {x, 1}, 2, {x, 0}}.
    {jump, {f, 53}}.
  {label, 52}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 53}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 1}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 1}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 55}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 55}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/block_jump_label_reaches_loop|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_priv__firstPair', 2, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_priv__firstPair'}, 2}.
  {label, 83}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__sumBeforeTwo', 2, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_priv__sumBeforeTwo'}, 2}.
  {label, 85}.
    {call_only, 2, {f, 5}}.

{function, '__bp_add', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_add'}, 2}.
  {label, 23}.
    {test, is_binary, {f, 24}, [{x, 0}]}.
    {test, is_binary, {f, 24}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 24}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '-firstPair/3-fun-1-', 3, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '-firstPair/3-fun-1-'}, 3}.
  {label, 21}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call, 2, {f, 23}}.
    {test, is_eq, {f, 26}, [{x, 0}, {integer, 5}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {integer, 10}], {x, 0}}.
    {test, is_ge, {f, 27}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 27}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:12:31">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 28}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 29}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 29}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:12:36">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 30}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_label_break'}, {atom, outer}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 26}.
    {move, {atom, ok}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 25}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-firstPair/2-fun-0-', 3, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '-firstPair/2-fun-0-'}, 3}.
  {label, 19}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {'try', {y, 3}, {f, 31}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 3}}.
    {jump, {f, 33}}.
  {label, 31}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 32}, [{x, 1}, 2, {atom, '__bp_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 33}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '-sumBeforeTwo/3-fun-3-', 3, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '-sumBeforeTwo/3-fun-3-'}, 3}.
  {label, 40}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 42}, [{y, 0}, {integer, 2}]}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_label_break'}, {atom, outer}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
  {label, 42}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 43}.
    {jump, {f, 41}}.
  {label, 41}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 44}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 44}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 45}}.
  {label, 44}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:27:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 45}.
    {gc_bif, '+', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 46}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 46}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 47}}.
  {label, 46}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:27:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 47}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-sumBeforeTwo/2-fun-2-', 3, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '-sumBeforeTwo/2-fun-2-'}, 3}.
  {label, 38}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 40}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {'try', {y, 3}, {f, 48}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 3}}.
    {jump, {f, 50}}.
  {label, 48}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 49}, [{x, 1}, 2, {atom, '__bp_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {jump, {f, 50}}.
  {label, 49}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 50}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_print', 1, 55}.
  {label, 54}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_print'}, 1}.
  {label, 55}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 59}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 59}.
  {label, 58}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 59}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 57}}.

{function, '-bp_show_elem-', 1, 61}.
  {label, 60}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 61}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 57}}.

{function, '__bp_show', 2, 57}.
  {label, 56}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_show'}, 2}.
  {label, 57}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 69}, [{x, 0}]}.
    {test, is_eq, {f, 68}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 68}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 69}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 70}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 70}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 72}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 71}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 71}, [{x, 0}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 77}}.
  {label, 76}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 77}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 57}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 72}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 74}, [{x, 0}]}.
    {test, is_ne_exact, {f, 74}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 74}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 75}, [{x, 0}, {atom, undefined}]}.
  {label, 73}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 63}, 2}.
  {label, 74}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 75}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 63}.
  {label, 62}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_tagged'}, 2}.
  {label, 63}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 78}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 78}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 78}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 65}, 3}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 65}.
  {label, 64}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '__bp_render'}, 1}.
  {label, 65}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 80}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 81}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_block_jump_label_reaches_loop@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_reaches_loop@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 67}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 57}}.
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
