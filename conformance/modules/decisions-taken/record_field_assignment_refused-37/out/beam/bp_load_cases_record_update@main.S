{module, bp_load_cases_record_update@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}]}.
{attributes, []}.
{labels, 57}.
%%% Decision 37's update form: `Name(..base, field: value)` is a new record
%%% with the fields it names replaced and every other field read from `base`.
%%% The checker matched each label to its field, but no backend lowered the
%%% `..` argument: each dropped it and zipped what was left, so
%%% `Cfg(..base, revalidate: 60)` built `Cfg(base, 60)` — the base record in
%%% the first field and the third one missing, on all four targets.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 7, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Cfg}, {integer, 1}, {integer, 0}, {x, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 4, {atom, bp_load_cases_record_update@main@@Cfg}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 14}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 15}, [{x, 0}, 4, {atom, bp_load_cases_record_update@main@@Cfg}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 15}.
    {test_heap, 5, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Cfg}, {x, 1}, {integer, 60}, {x, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 4, {atom, bp_load_cases_record_update@main@@Cfg}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 16}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 45}, [{x, 0}, 4, {atom, bp_load_cases_record_update@main@@Cfg}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 45}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 46}, [{x, 0}, 4, {atom, bp_load_cases_record_update@main@@Cfg}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 46}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 47}, [{x, 0}, 4, {atom, bp_load_cases_record_update@main@@Cfg}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 47}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {literal, <<"q">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Inner}, {integer, 5}, {x, 0}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Outer}, {x, 0}, {integer, 2}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 48}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Outer}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 48}.
    {test, is_tagged_tuple, {f, 49}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Inner}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 49}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"z">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Inner}, {x, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Inner}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 50}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 51}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Inner}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 51}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {literal, <<"y">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Inner}, {integer, 9}, {x, 0}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Inner}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 52}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Inner}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 53}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {literal, <<"t">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Box}, {integer, 3}, {x, 0}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_tagged_tuple, {f, 54}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Box}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 54}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_update@main@@Box}, {integer, 4}, {x, 0}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 55}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 56}, [{x, 0}, 3, {atom, bp_load_cases_record_update@main@@Box}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 56}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 18}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 7}.
    return.

{function, '__bp_loaded_main', 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/record_update|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 3}, 0}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '__bp_print', 1, 18}.
  {label, 17}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '__bp_print'}, 1}.
  {label, 18}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 22}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 22}.
  {label, 21}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 22}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 20}}.

{function, '-bp_show_elem-', 1, 24}.
  {label, 23}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 24}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 20}}.

{function, '__bp_show', 2, 20}.
  {label, 19}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '__bp_show'}, 2}.
  {label, 20}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 32}, [{x, 0}]}.
    {test, is_eq, {f, 31}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 31}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 33}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 35}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 34}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 34}, [{x, 0}]}.
    {test, is_ne_exact, {f, 34}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 34}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 34}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 40}}.
  {label, 39}.
    {test, is_eq_exact, {f, 36}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 40}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 20}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 37}, [{x, 0}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, undefined}]}.
  {label, 36}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 26}, 2}.
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 38}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '__bp_tagged'}, 2}.
  {label, 26}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 41}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 41}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 41}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 28}, 3}.
  {label, 42}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '__bp_render'}, 1}.
  {label, 28}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 43}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 44}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_record_update@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_update@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 30}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 20}}.
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
