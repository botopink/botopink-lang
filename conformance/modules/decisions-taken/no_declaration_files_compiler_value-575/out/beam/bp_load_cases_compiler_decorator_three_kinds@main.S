{module, bp_load_cases_compiler_decorator_three_kinds@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {positive, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_first', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}]}.
{attributes, []}.
{labels, 82}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 20}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 25}}.
  {label, 23}.
  {label, 21}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 26}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 25}}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
  {label, 29}.
  {label, 27}.
    {deallocate, 6}.
    return.
%%% Decisions 575 (3), (4) — a decorator's parameters arrive three ways. Its
%%% first `syntax` is the annotated declaration (`decl`, read through
%%% `compiler.name`); `comptime label: string` holds the value at build
%%% (`label.toUpper()`); `syntax rule: fn(v: T) -> bool` holds the expression
%%% written, read at build as the annotation wrote it (`compiler.text(rule)`)
%%% and spliced into the member the program runs. In the member, `label` and
%%% the body's `val shown` are spliced as literals (the tree rule).

{function, positive, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, positive}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 30}, [{x, 0}, 2, {atom, bp_load_cases_compiler_decorator_three_kinds@main@@Account}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 30}.
    {test, is_ge, {f, 31}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 32}}.
  {label, 31}.
    {move, {atom, false}, {x, 0}}.
  {label, 32}.
    {deallocate, 1}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 7, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"NEGATIVE BALANCE Account positive">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_decorator_three_kinds@main@@Mark}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 35}}.
    {test, is_eq, {f, 36}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 38}}.
  {label, 36}.
    {test, is_tagged_tuple, {f, 37}, [{x, 0}, 2, {atom, bp_load_cases_compiler_decorator_three_kinds@main@@Mark}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 38}}.
  {label, 37}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 38}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 39}}.
  {label, 33}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 39}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 41}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_decorator_three_kinds@main@@Account}, {integer, 5}]}}.
    {call_ext, 1, {extfunc, bp_load_cases_compiler_decorator_three_kinds@main@@Account, validate, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 41}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_compiler_decorator_three_kinds@main@@Account}, {integer, -1}]}}.
    {call_ext, 1, {extfunc, bp_load_cases_compiler_decorator_three_kinds@main@@Account, validate, 1}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/compiler_decorator_three_kinds|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, 'array_first', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, 'array_first'}, 1}.
  {label, 35}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 72}, 1}.

{function, '__bp_priv__array_first', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_priv__array_first'}, 1}.
  {label, 77}.
    {call_only, 1, {f, 35}}.

{function, '__bp_priv__array_range', 2, 79}.
  {label, 78}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 79}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 81}.
  {label, 80}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 81}.
    {call_only, 2, {f, 5}}.

{function, '__bp_print', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_print'}, 1}.
  {label, 41}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 45}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 43}}.

{function, '-bp_show_elem-', 1, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 47}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 43}}.

{function, '__bp_show', 2, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_show'}, 2}.
  {label, 43}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 55}, [{x, 0}]}.
    {test, is_eq, {f, 54}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 56}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 58}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 57}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 57}, [{x, 0}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 63}}.
  {label, 62}.
    {test, is_eq_exact, {f, 59}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 63}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 43}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 47}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 60}, [{x, 0}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, undefined}]}.
  {label, 59}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 49}, 2}.
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 61}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_tagged'}, 2}.
  {label, 49}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 64}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 64}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 64}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 51}, 3}.
  {label, 65}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_render'}, 1}.
  {label, 51}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 66}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 67}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 53}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 53}.
  {label, 52}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 53}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 43}}.
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

{function, '-main/0-fun-0-', 1, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 69}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 70}, [{x, 0}, 2, {atom, bp_load_cases_compiler_decorator_three_kinds@main@@Violation}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 70}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 41}}.
    {deallocate, 1}.
    return.

{function, '-bp_at-', 2, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '-bp_at-'}, 2}.
  {label, 72}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 74}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 73}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 74}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 73}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 73}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_compiler_decorator_three_kinds@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_compiler_decorator_three_kinds@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 75}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 75}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
