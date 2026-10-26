{module, bp_load_cases_lambda_result_return_try@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__apply', 2}, {'__bp_priv__half', 1}]}.
{attributes, []}.
{labels, 74}.
%%% Decision 147 (lg-a) — a lambda that can fail is written under an expected
%%% `fn(x: T) -> Result<U, E>`: its `try` propagates, its `return v` is
%%% `Ok(v)` and its `throw e` is `Error(e)`.

{function, half, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, half}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ne_exact, {f, 18}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"odd">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 18}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 19}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 19}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 20}}.
  {label, 19}.
    {move, {literal, {integer_overflow, <<"integer overflow: / on i32 at src/main.bp:9:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 20}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, apply, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, apply}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 8}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {test, is_tagged_tuple, {f, 25}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {integer, -1}, {x, 0}}.
  {label, 26}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {integer, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_fun, 1}.
    {test, is_tagged_tuple, {f, 55}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 56}}.
  {label, 55}.
    {move, {atom, false}, {x, 0}}.
  {label, 56}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
    {move, {integer, -3}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {atom, false}, {x, 0}}.
  {label, 58}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, []}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test, is_tagged_tuple, {f, 64}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {integer, 0}, {x, 0}}.
  {label, 65}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 28}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/lambda_result_return_try|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_priv__apply', 2, 71}.
  {label, 70}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_priv__apply'}, 2}.
  {label, 71}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__half', 1, 73}.
  {label, 72}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_priv__half'}, 1}.
  {label, 73}.
    {call_only, 1, {f, 3}}.

{function, '-main/0-fun-0-', 1, 22}.
  {label, 21}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 22}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 24}}.
  {label, 23}.
    {deallocate, 2}.
    return.
  {label, 24}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_last, 1, {f, 3}, 2}.

{function, '__bp_print', 1, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_print'}, 1}.
  {label, 28}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 32}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 30}}.

{function, '-bp_show_elem-', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 34}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 30}}.

{function, '__bp_show', 2, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_show'}, 2}.
  {label, 30}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 42}, [{x, 0}]}.
    {test, is_eq, {f, 41}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 43}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 45}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 44}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 44}, [{x, 0}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 50}}.
  {label, 49}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 50}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 30}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 47}, [{x, 0}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
  {label, 46}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 36}, 2}.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 48}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_tagged'}, 2}.
  {label, 36}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 51}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 51}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 38}, 3}.
  {label, 52}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '__bp_render'}, 1}.
  {label, 38}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 53}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 54}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 40}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 40}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 30}}.
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

{function, '-main/0-fun-1-', 1, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '-main/0-fun-1-'}, 1}.
  {label, 60}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 61}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 61}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 62}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 62}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:29:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 63}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-2-', 1, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_lambda_result_return_try@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_lambda_result_return_try@main}, {atom, '-main/0-fun-2-'}, 1}.
  {label, 67}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 68}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 68}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:34:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 69}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.
