{module, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 34}.

{function, '__bp_format', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '__bp_format'}, 1}.
  {label, 31}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__v__all}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<".">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 33}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {test, is_nonempty_list, {f, 33}, [{x, 2}]}.
    {get_list, {x, 2}, {x, 3}, {x, 4}}.
    {move, {x, 3}, {y, 1}}.
    {test_heap, 9, 0}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<".">>}, {x, 1}, {x, 1}}.
    {put_list, {literal, <<"Bp__Tok__Pad.All">>}, {x, 1}, {x, 1}}.
    {put_tuple2, {x, 0}, {list, [{atom, text}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 33}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, text}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 32}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Bp__Tok__Pad">>}, nil]}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '__bp_print'}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 7}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '-bp_show_top-'}, 1}.
  {label, 7}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 5}}.

{function, '-bp_show_elem-', 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '-bp_show_elem-'}, 1}.
  {label, 9}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 5}}.

{function, '__bp_show', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '__bp_show'}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 17}, [{x, 0}]}.
    {test, is_eq, {f, 16}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 16}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 17}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 18}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 18}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 20}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 19}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 19}, [{x, 0}]}.
    {test, is_ne_exact, {f, 19}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 19}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 19}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 25}}.
  {label, 24}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 25}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 19}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 9}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 20}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 22}, [{x, 0}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 22}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 23}, [{x, 0}, {atom, undefined}]}.
  {label, 21}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 11}, 2}.
  {label, 22}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 23}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '__bp_tagged'}, 2}.
  {label, 11}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 26}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 26}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 26}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 13}, 3}.
  {label, 27}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '__bp_render'}, 1}.
  {label, 13}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 28}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 29}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 15}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad}, {atom, '-bp_render_pair-'}, 1}.
  {label, 15}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 5}}.
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
