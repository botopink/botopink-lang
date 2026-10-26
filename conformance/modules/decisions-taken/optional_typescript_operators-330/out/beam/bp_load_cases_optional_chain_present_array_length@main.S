{module, bp_load_cases_optional_chain_present_array_length@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}]}.
{attributes, []}.
{labels, 69}.
%%% Decision 330 — `?.length()` over an optional array that is present: a
%%% chain through an optional record's optional array answers the array's
%%% length, and so does a parameter typed `?Holder[]` given a present array;
%%% absent, the chain is absent and `?? 0` answers `0`, on every target.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_present_array_length@main@@Field}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_present_array_length@main@@Field}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_present_array_length@main@@Form}, {x, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 17}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 19}}.
  {label, 17}.
    {test, is_tagged_tuple, {f, 18}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_present_array_length@main@@Form}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 19}.
    {test, is_eq, {f, 15}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 16}}.
  {label, 15}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
  {label, 16}.
    {test, is_ne_exact, {f, 14}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 20}}.
  {label, 14}.
    {move, {integer, 0}, {x, 0}}.
  {label, 20}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_present_array_length@main@@Form}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 54}}.
  {label, 52}.
    {test, is_tagged_tuple, {f, 53}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_present_array_length@main@@Form}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 54}}.
  {label, 53}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 54}.
    {test, is_eq, {f, 50}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
  {label, 51}.
    {test, is_ne_exact, {f, 49}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 55}}.
  {label, 49}.
    {move, {integer, 0}, {x, 0}}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq, {f, 59}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 61}}.
  {label, 59}.
    {test, is_tagged_tuple, {f, 60}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_present_array_length@main@@Form}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 61}.
    {test, is_eq, {f, 57}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
  {label, 58}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 62}}.
  {label, 56}.
    {move, {integer, 0}, {x, 0}}.
  {label, 62}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 10}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<"z">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_present_array_length@main@@Holder}, {x, 0}]}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<"y">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_present_array_length@main@@Holder}, {x, 0}]}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_present_array_length@main@@Holder}, {x, 0}]}}.
    {move, {y, 11}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_fun, 1}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_loaded_main', 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_chain_present_array_length|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 3}, 0}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '__bp_print', 1, 22}.
  {label, 21}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '__bp_print'}, 1}.
  {label, 22}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 26}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 26}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 24}}.

{function, '-bp_show_elem-', 1, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 28}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 24}}.

{function, '__bp_show', 2, 24}.
  {label, 23}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '__bp_show'}, 2}.
  {label, 24}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 36}, [{x, 0}]}.
    {test, is_eq, {f, 35}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 37}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 39}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 38}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 38}, [{x, 0}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 44}}.
  {label, 43}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 44}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 24}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 41}, [{x, 0}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, undefined}]}.
  {label, 40}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 30}, 2}.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 42}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '__bp_tagged'}, 2}.
  {label, 30}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 45}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 45}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 45}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 32}, 3}.
  {label, 46}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '__bp_render'}, 1}.
  {label, 32}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 47}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 48}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 34}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 24}}.
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

{function, '-main/0-fun-0-', 1, 64}.
  {label, 63}.
    {line, [{location, "bp_load_cases_optional_chain_present_array_length@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_present_array_length@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 64}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 66}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
  {label, 67}.
    {test, is_ne_exact, {f, 65}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 68}}.
  {label, 65}.
    {move, {integer, 0}, {x, 0}}.
  {label, 68}.
    {deallocate, 3}.
    return.
