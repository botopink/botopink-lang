{module, bp_load_cases_fn_tail_value@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__first', 2}, {'__bp_priv__greet', 1}, {'__bp_priv__inc', 1}, {'__bp_priv__max', 2}, {'__bp_priv__old', 1}, {'__bp_priv__sign', 1}]}.
{attributes, []}.
{labels, 83}.
%%% Decision 409 — a function body's last expression written without `;` is
%%% its value: `fn inc(x: i32) -> i32 { x + 1 }`. An early `return` stays
%%% (`sign`); an `if` / `else` expression is a tail like any other (`max`); a
%%% tail is checked against `-> R`, generic or not (`first`); every `return
%%% x;` stays valid (`old`).

{function, inc, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, inc}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 26}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 26}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:9:27">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 27}.
    {deallocate, 1}.
    return.

{function, sign, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, sign}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 28}, [{y, 0}, {integer, 0}]}.
    {move, {integer, -1}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, max, 2, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, max}, 2}.
  {label, 7}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_lt, {f, 29}, [{y, 1}, {y, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {y, 1}, {x, 0}}.
  {label, 30}.
    {deallocate, 2}.
    return.

{function, first, 2, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, first}, 2}.
  {label, 9}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 33}}.
    {test, is_ne_exact, {f, 31}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 36}}.
  {label, 31}.
    {move, {y, 1}, {x, 0}}.
  {label, 36}.
    {deallocate, 3}.
    return.

{function, greet, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, greet}, 1}.
  {label, 11}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"hello, ">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 66}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, old, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, old}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 69}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 69}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 70}}.
  {label, 69}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:26:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 70}.
    {deallocate, 1}.
    return.

{function, main, 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, main}, 0}.
  {label, 15}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, {integer, -5}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, {integer, 5}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 8}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 7}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"none">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, {literal, <<"ana">>}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, {integer, 4}, {x, 0}}.
    {call, 1, {f, 13}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 38}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_loaded_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/fn_tail_value|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '_botopink_main'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 15}, 0}.

{function, main, 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, main}, 1}.
  {label, 25}.
    {call_only, 0, {f, 23}}.

{function, '__bp_priv__first', 2, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_priv__first'}, 2}.
  {label, 72}.
    {call_only, 2, {f, 9}}.

{function, '__bp_priv__greet', 1, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_priv__greet'}, 1}.
  {label, 74}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__inc', 1, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_priv__inc'}, 1}.
  {label, 76}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__max', 2, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_priv__max'}, 2}.
  {label, 78}.
    {call_only, 2, {f, 7}}.

{function, '__bp_priv__old', 1, 80}.
  {label, 79}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_priv__old'}, 1}.
  {label, 80}.
    {call_only, 1, {f, 13}}.

{function, '__bp_priv__sign', 1, 82}.
  {label, 81}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_priv__sign'}, 1}.
  {label, 82}.
    {call_only, 1, {f, 5}}.

{function, '-bp_at-', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '-bp_at-'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 35}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 34}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 35}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 34}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 34}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_print'}, 1}.
  {label, 38}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 42}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 40}}.

{function, '-bp_show_elem-', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 44}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 40}}.

{function, '__bp_show', 2, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_show'}, 2}.
  {label, 40}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 52}, [{x, 0}]}.
    {test, is_eq, {f, 51}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 53}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 55}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 54}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 54}, [{x, 0}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 60}}.
  {label, 59}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 60}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 40}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 57}, [{x, 0}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, undefined}]}.
  {label, 56}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 46}, 2}.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 58}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_tagged'}, 2}.
  {label, 46}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 61}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 61}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 61}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 48}, 3}.
  {label, 62}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '__bp_render'}, 1}.
  {label, 48}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 63}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 64}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 50}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 40}}.
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

{function, '-bp_stringify-', 1, 66}.
  {label, 65}.
    {line, [{location, "bp_load_cases_fn_tail_value@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_fn_tail_value@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 66}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 67}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 67}.
    {test, is_integer, {f, 68}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 68}.
    {call, 1, {f, 42}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
