{module, bp_load_cases_comptime_expand_banner@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {say, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__sayBody', 1}]}.
{attributes, []}.
{labels, 91}.
%%% Decision 562 — a `comptime` parameter that is no catalogue: `banner(3)`
%%% unrolls its loop at build, and each iteration's `say` — a host function,
%%% a run-time call — is written at the call with the row's number as a
%%% constant. `banner(1)` writes one row.

{function, say, 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, say}, 1}.
  {label, 23}.
    {call_only, 1, {f, 21}}.

{function, sayBody, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, sayBody}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {atom, true}, {x, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" of ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"row ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 81}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {call, 1, {f, 54}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" of ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"row ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 81}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {call, 1, {f, 54}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" of ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"row ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 81}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {call, 1, {f, 54}}.
    {jump, {f, 52}}.
  {label, 52}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" of ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"row ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 81}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {call, 1, {f, 54}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/comptime_expand_banner|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 17}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_load_siblings', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_comptime_expand_banner@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 84}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 19}, 0}.
  {label, 84}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 19}.
    {test, is_nonempty_list, {f, 85}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 86}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 88}}.
  {label, 86}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 88}}.
  {label, 87}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 1}}.
    {move, {literal, <<"error: ~ts does not compile - refusing to run~n  ~p~n">>}, {x, 0}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, standard_error}, {x, 0}}.
    {call_ext, 2, {extfunc, file, write, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, halt, 1}}.
  {label, 88}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 19}, 2}.
  {label, 85}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_priv__sayBody', 1, 90}.
  {label, 89}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_priv__sayBody'}, 1}.
  {label, 90}.
    {call_only, 1, {f, 3}}.

{function, '__bp_tpl_0', 1, 21}.
  {label, 20}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 21}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, [126, 116, 115, 126, 110]}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 2}.

{function, '__bp_print', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_print'}, 1}.
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
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 29}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '-bp_show_elem-', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 31}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '__bp_show', 2, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_show'}, 2}.
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
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_tagged'}, 2}.
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
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_render'}, 1}.
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
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '-bp_render_pair-'}, 1}.
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

{function, '__bp_tpl_1', 1, 54}.
  {label, 53}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 54}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 5}}.
    {'try', {y, 15}, {f, 57}}.
    {test_heap, 2, 0}.
    {put_list, {y, 5}, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, [126, 116, 115, 126, 110]}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_ext, 2, {extfunc, io, format, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {try_end, {y, 15}}.
    {jump, {f, 58}}.
  {label, 57}.
    {try_case, {y, 15}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 9}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 60}, [{x, 0}]}.
    {test, test_arity, {f, 60}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, panic}, {x, 1}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {x, 1}]}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, todo}, {x, 1}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {x, 1}]}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, integer_overflow}, {x, 1}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {x, 1}]}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, bp_host}, {x, 1}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {x, 1}]}.
  {label, 67}.
  {label, 65}.
  {label, 63}.
    {jump, {f, 61}}.
  {label, 61}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 60}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 68}, [{x, 0}]}.
    {test, test_arity, {f, 68}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {y, 12}}.
    {get_tuple_element, {x, 0}, 3, {y, 13}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 3}}.
    {move, {y, 13}, {y, 4}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 68}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {test, test_arity, {f, 69}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {y, 12}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 3}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 69}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, throw}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, '__bp_break'}]}.
    {move, {atom, '__bp_break'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 70}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {atom, throw}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 71}, [{x, 0}]}.
    {test, test_arity, {f, 71}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_cond_break'}, {x, 1}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {x, 1}]}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_cond_continue'}, {x, 1}}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {x, 1}]}.
    {jump, {f, 76}}.
  {label, 75}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_try'}, {x, 1}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {x, 1}]}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_stop'}, {x, 1}}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {x, 1}]}.
  {label, 78}.
  {label, 76}.
  {label, 74}.
    {jump, {f, 72}}.
  {label, 72}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 71}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, throw}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 79}, [{x, 0}]}.
    {test, test_arity, {f, 79}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {y, 12}}.
    {get_tuple_element, {x, 0}, 3, {y, 13}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, '__bp_gen_end'}]}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 3}}.
    {move, {y, 13}, {y, 4}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_gen_end'}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 79}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_host}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 58}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '-bp_stringify-', 1, 81}.
  {label, 80}.
    {line, [{location, "bp_load_cases_comptime_expand_banner@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_expand_banner@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 81}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 82}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 82}.
    {test, is_integer, {f, 83}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 83}.
    {call, 1, {f, 29}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
