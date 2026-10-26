{module, bp_load_cases_result_wide_payloads@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__described', 1}, {'__bp_priv__half', 1}, {'__bp_priv__halfOr', 1}, {'__bp_priv__quarter', 1}, {'__bp_priv__triple', 1}, {'__bp_priv__tripleOrZero', 1}]}.
{attributes, []}.
{labels, 96}.
%%% 144 B-22 — a `Result` whose `Ok` is an `f64` or an `i64` keeps the whole value through every
%%% reader, on every target: `unwrapOr`, a `case` arm's binder, `try`, `try … catch` and `map`.

{function, half, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, half}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 26}, [{y, 0}, {float, 0.0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 26}.
    {gc_bif, '/', {f, 0}, 0, [{y, 0}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, triple, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, triple}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 27}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 27}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 28}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 28}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/main.bp:13:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 29}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, halfOr, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, halfOr}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 31}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 31}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, error}]}.
    {move, {float, -1.0}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 32}.
    {case_end, {x, 0}}.
  {label, 30}.
    {deallocate, 2}.
    return.

{function, described, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, described}, 1}.
  {label, 9}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {jump, {f, 33}}.
  {label, 34}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 35}.
    {case_end, {x, 0}}.
  {label, 33}.
    {deallocate, 3}.
    return.

{function, quarter, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, quarter}, 1}.
  {label, 11}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 36}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 37}}.
  {label, 36}.
    {deallocate, 2}.
    return.
  {label, 37}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '/', {f, 0}, 0, [{y, 1}, {float, 2.0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, tripleOrZero, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, tripleOrZero}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 39}}.
  {label, 38}.
    {move, {integer, 0}, {x, 0}}.
  {label, 39}.
    {deallocate, 1}.
    return.

{function, main, 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, main}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {float, 3.0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 40}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 41}}.
  {label, 40}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 41}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {float, -3.0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 70}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {float, 0.5}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {float, 5.0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {float, -5.0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {integer, 3002399751580331}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {integer, -1}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {integer, 3002399751580331}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_tagged_tuple, {f, 72}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {integer, 0}, {x, 0}}.
  {label, 73}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {float, 10.0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_tagged_tuple, {f, 74}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {float, -10.0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test, is_tagged_tuple, {f, 76}, [{x, 0}, 2, {atom, error}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, false}, {x, 0}}.
  {label, 77}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {integer, -7}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {float, 8.0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 80}, [{x, 0}, 2, {atom, ok}]}.
    {move, {x, 0}, {x, 1}}.
    {get_tuple_element, {x, 0}, 1, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 83}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_fun, 1}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {jump, {f, 81}}.
  {label, 80}.
  {label, 81}.
    {test, is_tagged_tuple, {f, 78}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 79}}.
  {label, 78}.
    {move, {float, 0.0}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 43}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 15}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/result_wide_payloads|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '_botopink_main'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 15}, 0}.

{function, main, 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, main}, 1}.
  {label, 25}.
    {call_only, 0, {f, 23}}.

{function, '__bp_priv__described', 1, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_priv__described'}, 1}.
  {label, 85}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__half', 1, 87}.
  {label, 86}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_priv__half'}, 1}.
  {label, 87}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__halfOr', 1, 89}.
  {label, 88}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_priv__halfOr'}, 1}.
  {label, 89}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__quarter', 1, 91}.
  {label, 90}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_priv__quarter'}, 1}.
  {label, 91}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__triple', 1, 93}.
  {label, 92}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_priv__triple'}, 1}.
  {label, 93}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__tripleOrZero', 1, 95}.
  {label, 94}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_priv__tripleOrZero'}, 1}.
  {label, 95}.
    {call_only, 1, {f, 13}}.

{function, '__bp_print', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_print'}, 1}.
  {label, 43}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 47}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 45}}.

{function, '-bp_show_elem-', 1, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 49}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 45}}.

{function, '__bp_show', 2, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_show'}, 2}.
  {label, 45}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 57}, [{x, 0}]}.
    {test, is_eq, {f, 56}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 58}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 60}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 59}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 59}, [{x, 0}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 65}}.
  {label, 64}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 65}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 45}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 62}, [{x, 0}]}.
    {test, is_ne_exact, {f, 62}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 62}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 63}, [{x, 0}, {atom, undefined}]}.
  {label, 61}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 51}, 2}.
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 63}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_tagged'}, 2}.
  {label, 51}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 66}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 66}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 66}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 53}, 3}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 53}.
  {label, 52}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '__bp_render'}, 1}.
  {label, 53}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 68}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 69}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 55}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 55}.
  {label, 54}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 55}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 45}}.
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

{function, '-main/0-fun-0-', 1, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_result_wide_payloads@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_result_wide_payloads@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 83}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {float, 0.25}], {x, 0}}.
    {deallocate, 1}.
    return.
