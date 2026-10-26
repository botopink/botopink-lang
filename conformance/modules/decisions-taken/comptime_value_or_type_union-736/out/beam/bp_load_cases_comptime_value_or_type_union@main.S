{module, bp_load_cases_comptime_value_or_type_union@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv____bp_atomKey__type', 0}, {'__bp_priv____bp_atomState__type', 1}, {'__bp_priv__atomKey', 1}, {'__bp_priv__atomState', 2}, {'__bp_priv__currentUser', 0}]}.
{attributes, []}.
{labels, 69}.
%%% Decision 736 — a `comptime` parameter takes a value or a type:
%%% `comptime source: Atom<T> | type<T>`, the body testing `source is type<T>`.
%%% One function, one name, two forms: an `Atom<T>` value (`T` inferred from
%%% it, or written) or a type naming its implicit atom (`T` bound to the type).

{function, atomKey, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, atomKey}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 26}, [{x, 0}, 3, {atom, bp_load_cases_comptime_value_or_type_union@main@@Atom}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 26}.
    {deallocate, 1}.
    return.

{function, '__bp_atomKey__type', 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_atomKey__type'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"implicit">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, atomState, 2, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, atomState}, 2}.
  {label, 7}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 27}, [{x, 0}, 3, {atom, bp_load_cases_comptime_value_or_type_union@main@@Atom}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 27}.
    {deallocate, 2}.
    return.

{function, '__bp_atomState__type', 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_atomState__type'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, currentUser, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, currentUser}, 0}.
  {label, 11}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {literal, {bp_load_cases_comptime_value_or_type_union@main, currentUser}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, '$bp_unset'}]}.
    {move, {literal, <<"currentUser">>}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ana">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_comptime_value_or_type_union@main@@User}, {x, 0}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_comptime_value_or_type_union@main@@Atom}, {y, 0}, {x, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_comptime_value_or_type_union@main, currentUser}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 2}, {x, 0}}.
  {label, 28}.
    {deallocate, 3}.
    return.

{function, main, 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, main}, 0}.
  {label, 13}.
    {allocate, 5, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {call, 0, {f, 11}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {call, 0, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {call, 0, {f, 11}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {call, 0, {f, 11}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"none">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_comptime_value_or_type_union@main@@User}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 7}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_comptime_value_or_type_union@main@@User}, {x, 0}]}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 2, {atom, bp_load_cases_comptime_value_or_type_union@main@@User}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 57}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 58}, [{x, 0}, 2, {atom, bp_load_cases_comptime_value_or_type_union@main@@User}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 58}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {y, 3}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 30}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_loaded_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {call, 0, {f, 25}}.
    {call, 0, {f, 13}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/comptime_value_or_type_union|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '_botopink_main'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 11}}.
    {call_last, 0, {f, 13}, 0}.

{function, main, 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, main}, 1}.
  {label, 23}.
    {call_only, 0, {f, 21}}.

{function, '_botopink_init', 0, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '_botopink_init'}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, {literal, {bp_load_cases_comptime_value_or_type_union@main, currentUser}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {call, 0, {f, 11}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_priv____bp_atomKey__type', 0, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_priv____bp_atomKey__type'}, 0}.
  {label, 60}.
    {call_only, 0, {f, 5}}.

{function, '__bp_priv____bp_atomState__type', 1, 62}.
  {label, 61}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_priv____bp_atomState__type'}, 1}.
  {label, 62}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__atomKey', 1, 64}.
  {label, 63}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_priv__atomKey'}, 1}.
  {label, 64}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__atomState', 2, 66}.
  {label, 65}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_priv__atomState'}, 2}.
  {label, 66}.
    {call_only, 2, {f, 7}}.

{function, '__bp_priv__currentUser', 0, 68}.
  {label, 67}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_priv__currentUser'}, 0}.
  {label, 68}.
    {call_only, 0, {f, 11}}.

{function, '__bp_print', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_print'}, 1}.
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
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 34}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 32}}.

{function, '-bp_show_elem-', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 36}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 32}}.

{function, '__bp_show', 2, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_show'}, 2}.
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
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_tagged'}, 2}.
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
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '__bp_render'}, 1}.
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
    {line, [{location, "bp_load_cases_comptime_value_or_type_union@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_comptime_value_or_type_union@main}, {atom, '-bp_render_pair-'}, 1}.
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
