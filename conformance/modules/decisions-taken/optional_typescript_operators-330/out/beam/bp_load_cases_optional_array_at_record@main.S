{module, bp_load_cases_optional_array_at_record@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__holder', 1}]}.
{attributes, []}.
{labels, 81}.
%%% Decision 330 — a `?.` call over an optional array answers the element
%%% as the `?T` it is: an array of records answers the record itself, so a
%%% `?.` read of its field, and a default, work on every target.

{function, holder, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, holder}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 16}, [{y, 0}, {integer, 0}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_array_at_record@main@@Holder}, {atom, undefined}]}}.
    {deallocate, 2}.
    return.
  {label, 16}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"tick">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_array_at_record@main@@Post}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_array_at_record@main@@Holder}, {x, 0}]}}.
    {deallocate, 2}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 17}, [{x, 0}, 2, {atom, bp_load_cases_optional_array_at_record@main@@Holder}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 17}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 18}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 21}}.
  {label, 19}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq, {f, 25}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 25}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 2, {atom, bp_load_cases_optional_array_at_record@main@@Post}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 27}.
    {test, is_ne_exact, {f, 24}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 28}}.
  {label, 24}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 28}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 2, {atom, bp_load_cases_optional_array_at_record@main@@Holder}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 57}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq, {f, 58}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 21}}.
  {label, 59}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq, {f, 61}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 61}.
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 2, {atom, bp_load_cases_optional_array_at_record@main@@Post}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 63}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 64}}.
  {label, 60}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 64}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 66}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 21}}.
  {label, 67}.
    {test, is_eq, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 70}}.
  {label, 68}.
    {test, is_tagged_tuple, {f, 69}, [{x, 0}, 2, {atom, bp_load_cases_optional_array_at_record@main@@Post}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 70}}.
  {label, 69}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 70}.
    {test, is_ne_exact, {f, 65}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 65}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 21}}.
  {label, 74}.
    {test, is_eq, {f, 75}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 75}.
    {test, is_tagged_tuple, {f, 76}, [{x, 0}, 2, {atom, bp_load_cases_optional_array_at_record@main@@Post}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 77}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 78}}.
  {label, 72}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 78}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_array_at_record|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__holder', 1, 80}.
  {label, 79}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_priv__holder'}, 1}.
  {label, 80}.
    {call_only, 1, {f, 3}}.

{function, '-bp_at-', 2, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '-bp_at-'}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 23}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 22}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 23}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 22}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 22}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_print'}, 1}.
  {label, 30}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 34}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 32}}.

{function, '-bp_show_elem-', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 36}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 32}}.

{function, '__bp_show', 2, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_show'}, 2}.
  {label, 32}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 44}, [{x, 0}]}.
    {test, is_eq, {f, 43}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 45}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 47}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 46}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 46}, [{x, 0}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 52}}.
  {label, 51}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 52}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 32}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 49}, [{x, 0}]}.
    {test, is_ne_exact, {f, 49}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 49}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, undefined}]}.
  {label, 48}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 38}, 2}.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 50}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_tagged'}, 2}.
  {label, 38}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 53}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 53}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 53}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 40}, 3}.
  {label, 54}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '__bp_render'}, 1}.
  {label, 40}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 55}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 56}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_optional_array_at_record@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_array_at_record@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 42}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 32}}.
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
