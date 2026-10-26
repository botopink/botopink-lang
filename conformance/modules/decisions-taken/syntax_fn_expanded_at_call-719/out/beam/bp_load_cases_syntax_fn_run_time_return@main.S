{module, bp_load_cases_syntax_fn_run_time_return@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {show, 3}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}]}.
{attributes, []}.
{labels, 65}.
%%% Decisions 719, 841 — a function with a `syntax` expression parameter
%%% returns any written type: `-> T` is code of type `T`, checked where it is
%%% spliced, as a template's is (578 (2)); `-> void` included. `twice` answers
%%% an `i32` at its call, `log` a statement that prints its label and the
%%% expression as written beside its value.

{function, show, 3, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, show}, 3}.
  {label, 3}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<" = ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 49}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 52}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 52}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:24:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 53}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '*', {f, 0}, 2, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 54}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 54}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:24:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 55}.
    {gc_bif, '+', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 56}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 56}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 57}}.
  {label, 56}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:24:32">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 57}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {literal, <<"sum">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"n + 4">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {gc_bif, '+', {f, 0}, 3, [{y, 0}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 58}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 58}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:26:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 59}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 3}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/syntax_fn_run_time_return|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 17}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_load_siblings', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 60}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 19}, 0}.
  {label, 60}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 19}.
    {test, is_nonempty_list, {f, 61}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 64}}.
  {label, 62}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 63}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 64}}.
  {label, 63}.
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
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 19}, 2}.
  {label, 61}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_print', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_print'}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 25}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 23}}.

{function, '-bp_show_elem-', 1, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 27}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 23}}.

{function, '__bp_show', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_show'}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 35}, [{x, 0}]}.
    {test, is_eq, {f, 34}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 36}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 38}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 37}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 37}, [{x, 0}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 43}}.
  {label, 42}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 43}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 23}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 40}, [{x, 0}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, undefined}]}.
  {label, 39}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 29}, 2}.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 41}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_tagged'}, 2}.
  {label, 29}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 44}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 44}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 44}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 31}, 3}.
  {label, 45}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '__bp_render'}, 1}.
  {label, 31}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 46}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 47}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 33}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 23}}.
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

{function, '-bp_stringify-', 1, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_syntax_fn_run_time_return@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_syntax_fn_run_time_return@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 49}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 50}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 50}.
    {test, is_integer, {f, 51}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 51}.
    {call, 1, {f, 25}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
