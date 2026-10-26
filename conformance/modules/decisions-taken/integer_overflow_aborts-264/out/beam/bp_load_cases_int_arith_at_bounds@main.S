{module, bp_load_cases_int_arith_at_bounds@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__i32Of', 1}, {'__bp_priv__i64Of', 1}, {'__bp_priv__i8Of', 1}, {'__bp_priv__u32Of', 1}]}.
{attributes, []}.
{labels, 80}.
%%% Decision 264's other half: a result AT its type's bound is a value, never
%%% an abort — `i32`'s and `i8`'s two ends, `u32`'s maximum and zero, and an
%%% `i64` at commonJS's exact bound `2^53 − 1`, each reached by arithmetic.

{function, i32Of, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, i32Of}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, i8Of, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, i8Of}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, u32Of, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, u32Of}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, i64Of, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, i64Of}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 2147483646}, {x, 0}}.
    {call, 1, {f, 3}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 22}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 22}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:24:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 23}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, -2147483647}, {x, 0}}.
    {call, 1, {f, 3}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 52}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 52}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:25:30">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 53}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, -46341}, {x, 0}}.
    {call, 1, {f, 3}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 46340}], {x, 0}}.
    {test, is_ge, {f, 54}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 54}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:26:25">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, -2147483647}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}], {x, 0}}.
    {test, is_ge, {f, 56}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 56}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 57}}.
  {label, 56}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:27:11">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 57}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 126}, {x, 0}}.
    {call, 1, {f, 5}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 58}, [{x, 0}, {integer, -128}]}.
    {test, is_ge, {f, 58}, [{integer, 127}, {x, 0}]}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i8 at src/main.bp:28:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 59}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, -127}, {x, 0}}.
    {call, 1, {f, 5}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 60}, [{x, 0}, {integer, -128}]}.
    {test, is_ge, {f, 60}, [{integer, 127}, {x, 0}]}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i8 at src/main.bp:29:22">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 61}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 4294967294}, {x, 0}}.
    {call, 1, {f, 7}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 62}, [{x, 0}, {integer, 0}]}.
    {test, is_ge, {f, 62}, [{integer, 4294967295}, {x, 0}]}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on u32 at src/main.bp:30:29">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 63}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 7}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 64}, [{x, 0}, {integer, 0}]}.
    {test, is_ge, {f, 64}, [{integer, 4294967295}, {x, 0}]}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on u32 at src/main.bp:31:20">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 65}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 9007199254740990}, {x, 0}}.
    {call, 1, {f, 9}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 66}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 66}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:32:35">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 9007199254740991}, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{x, 1}], {x, 0}}.
    {test, is_ge, {f, 68}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 68}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i64 at src/main.bp:33:11">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 69}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 2147483640}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 7}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 0}, {x, 1}], {x, 0}}.
    {test, is_ge, {f, 70}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 70}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {literal, {integer_overflow, <<"integer overflow: += on i32 at src/main.bp:35:5">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 71}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/int_arith_at_bounds|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__i32Of', 1, 73}.
  {label, 72}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_priv__i32Of'}, 1}.
  {label, 73}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__i64Of', 1, 75}.
  {label, 74}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_priv__i64Of'}, 1}.
  {label, 75}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__i8Of', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_priv__i8Of'}, 1}.
  {label, 77}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__u32Of', 1, 79}.
  {label, 78}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_priv__u32Of'}, 1}.
  {label, 79}.
    {call_only, 1, {f, 7}}.

{function, '__bp_print', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_print'}, 1}.
  {label, 25}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 29}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '-bp_show_elem-', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 31}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '__bp_show', 2, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_show'}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 39}, [{x, 0}]}.
    {test, is_eq, {f, 38}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 40}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 42}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 41}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 41}, [{x, 0}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 47}}.
  {label, 46}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 47}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 27}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 44}, [{x, 0}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
  {label, 43}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 33}, 2}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 45}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_tagged'}, 2}.
  {label, 33}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 48}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 48}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 48}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 35}, 3}.
  {label, 49}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '__bp_render'}, 1}.
  {label, 35}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 50}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 51}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_int_arith_at_bounds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_int_arith_at_bounds@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 37}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 27}}.
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
