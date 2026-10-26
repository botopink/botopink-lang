{module, bp_load_cases_numeric_literal_suffixes@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__kind', 1}, {'__bp_priv__small', 1}, {'__bp_priv__wide', 1}]}.
{attributes, []}.
{labels, 57}.
%%% Decision 247 — Kotlin's suffixes, lower case, for every numeric type:
%%% `1.5f` is an `f32`, `1d` an `f64`, `42l` an `i64`, `42u` a `u32`, `42ul` a
%%% `u64`, `7u8` / `7i8` / `7u16` / `7i16` / `7isize` / `7usize` their types;
%%% an unsuffixed integer still takes the integer type its position asks for
%%% (`val k: i64 = 1`); a suffix types a number pattern, and the suffix is
%%% stripped before any backend sees the literal. Each line was refused by the
%%% parent binary (`1.5f` was the number `1.5` and the identifier `f`).

{function, small, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, small}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, wide, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, wide}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, kind, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, kind}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 21}, [{x, 0}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {jump, {f, 20}}.
  {label, 21}.
    {test, is_eq, {f, 22}, [{x, 0}, {integer, 1}]}.
    {move, {literal, <<"one">>}, {x, 0}}.
    {jump, {f, 20}}.
  {label, 22}.
    {move, {literal, <<"many">>}, {x, 0}}.
    {jump, {f, 20}}.
  {label, 20}.
    {deallocate, 1}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {float, 1.0}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {float, 1.5}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 42}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 42}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 42}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 7}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 7}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 7}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 7}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 7}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 7}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 9}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 255}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {integer, 1_000}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {float, 2.5e1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 24}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/numeric_literal_suffixes|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__kind', 1, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_priv__kind'}, 1}.
  {label, 52}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__small', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_priv__small'}, 1}.
  {label, 54}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__wide', 1, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_priv__wide'}, 1}.
  {label, 56}.
    {call_only, 1, {f, 5}}.

{function, '__bp_print', 1, 24}.
  {label, 23}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_print'}, 1}.
  {label, 24}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 28}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 26}}.

{function, '-bp_show_elem-', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 30}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 26}}.

{function, '__bp_show', 2, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_show'}, 2}.
  {label, 26}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 38}, [{x, 0}]}.
    {test, is_eq, {f, 37}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 39}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 41}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 40}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 40}, [{x, 0}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 46}}.
  {label, 45}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 46}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 26}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 43}, [{x, 0}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 43}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 44}, [{x, 0}, {atom, undefined}]}.
  {label, 42}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 32}, 2}.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 44}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_tagged'}, 2}.
  {label, 32}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 47}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 47}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 47}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 34}, 3}.
  {label, 48}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '__bp_render'}, 1}.
  {label, 34}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 49}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 50}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_numeric_literal_suffixes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_numeric_literal_suffixes@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 36}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 26}}.
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
