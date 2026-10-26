{module, bp_load_cases_try_block_catch_rethrow@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__lookup', 1}, {'__bp_priv__port', 1}, {'__bp_priv__show', 1}, {'__bp_priv__sum', 2}]}.
{attributes, []}.
{labels, 90}.
%%% Decision 595 (3), (5) — the handler converts the region's failure into the
%%% function's: `catch throw …`, or a block with a binder whose `throw` is the
%%% enclosing function's (the block is no lambda). Each region fails with one
%%% error type (`string` here); the function answers its own (`ConfigError`).

{function, lookup, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, lookup}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{y, 0}, {x, 0}]}.
    {move, {integer, 80}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 22}.
    {move, {literal, <<"offset">>}, {x, 0}}.
    {test, is_eq_exact, {f, 23}, [{y, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, sum, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, sum}, 2}.
  {label, 5}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {'try', {y, 4}, {f, 24}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 29}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 30}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 31}}.
  {label, 30}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 31}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 2}, {x, 0}}.
    {call, 2, {f, 33}}.
    {jump, {f, 27}}.
  {label, 27}.
    {try_end, {y, 4}}.
    {jump, {f, 26}}.
  {label, 24}.
    {try_case, {y, 4}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 25}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {atom, bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__invalid}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
    {jump, {f, 26}}.
  {label, 25}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 26}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.

{function, port, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, port}, 1}.
  {label, 7}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {'try', {y, 3}, {f, 35}}.
    {move, {atom, true}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 39}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 40}}.
  {label, 39}.
    {bif, element, {f, 0}, [{integer, 2}, {x, 0}], {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_region'}, {x, 0}]}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 40}.
    {jump, {f, 38}}.
  {label, 38}.
    {try_end, {y, 3}}.
    {jump, {f, 37}}.
  {label, 35}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 36}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 36}, [{x, 1}, 2, {atom, '__bp_region'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__missing}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 4}.
    return.
  {label, 41}.
    {jump, {f, 37}}.
  {label, 36}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 37}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 42}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 42}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 43}}.
  {label, 42}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:24:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 43}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 4}.
    return.

{function, show, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, show}, 1}.
  {label, 9}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 45}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {jump, {f, 44}}.
  {label, 45}.
    {test, is_tagged_tuple, {f, 46}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 48}, [{x, 0}, 2, {atom, bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__missing}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"missing ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 47}}.
  {label, 48}.
    {test, is_eq, {f, 81}, [{x, 0}, {atom, bp_load_cases_try_block_catch_rethrow@main@@ConfigError__v__invalid}]}.
    {move, {literal, <<"invalid">>}, {x, 0}}.
    {jump, {f, 47}}.
  {label, 81}.
    {case_end, {x, 0}}.
  {label, 47}.
    {jump, {f, 44}}.
  {label, 46}.
    {case_end, {x, 0}}.
  {label, 44}.
    {deallocate, 6}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"offset">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 5}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"host">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 5}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, {literal, <<"port">>}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, {literal, <<"host">>}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call, 0, {f, 11}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/try_block_catch_rethrow|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__lookup', 1, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_priv__lookup'}, 1}.
  {label, 83}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__port', 1, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_priv__port'}, 1}.
  {label, 85}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__show', 1, 87}.
  {label, 86}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_priv__show'}, 1}.
  {label, 87}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__sum', 2, 89}.
  {label, 88}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_priv__sum'}, 2}.
  {label, 89}.
    {call_only, 2, {f, 5}}.

{function, '__bp_add', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_add'}, 2}.
  {label, 33}.
    {test, is_binary, {f, 34}, [{x, 0}]}.
    {test, is_binary, {f, 34}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 34}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '__bp_print', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_print'}, 1}.
  {label, 50}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 54}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 52}}.

{function, '-bp_show_elem-', 1, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 56}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 52}}.

{function, '__bp_show', 2, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_show'}, 2}.
  {label, 52}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 64}, [{x, 0}]}.
    {test, is_eq, {f, 63}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 65}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 67}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 66}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 66}, [{x, 0}]}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 72}}.
  {label, 71}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 72}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 52}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 69}, [{x, 0}]}.
    {test, is_ne_exact, {f, 69}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 69}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 70}, [{x, 0}, {atom, undefined}]}.
  {label, 68}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 58}, 2}.
  {label, 69}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 70}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 58}.
  {label, 57}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_tagged'}, 2}.
  {label, 58}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 73}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 73}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 73}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 60}, 3}.
  {label, 74}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '__bp_render'}, 1}.
  {label, 60}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 75}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 76}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 62}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 62}.
  {label, 61}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 62}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 52}}.
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

{function, '-bp_stringify-', 1, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_try_block_catch_rethrow@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_try_block_catch_rethrow@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 78}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 79}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 79}.
    {test, is_integer, {f, 80}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 80}.
    {call, 1, {f, 54}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
