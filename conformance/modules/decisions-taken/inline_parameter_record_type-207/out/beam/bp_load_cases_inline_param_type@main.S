{module, bp_load_cases_inline_param_type@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {link, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__again', 1}, {'__bp_priv__scaled', 2}]}.
{attributes, []}.
{labels, 70}.
%%% Decision 207 — a parameter's type written inline: `props: type(href:
%%% string, label: string, external: bool = false)`, the field grammar of
%%% `type Name(…)` with no name. The call builds the value from its own
%%% labelled arguments, each naming a field of the inline type (in any order,
%%% a defaulted field left out); a value already of the type is passed as the
%%% parameter itself; another parameter of the function stays an ordinary one.

{function, link, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, link}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 21}, [{x, 0}, 4, {atom, bp_load_cases_inline_param_type@main@@BpInline__link__props}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 21}.
    {test, is_eq, {f, 20}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<" (external)">>}, {x, 0}}.
    {jump, {f, 22}}.
  {label, 20}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 22}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<">">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 23}, [{x, 0}, 4, {atom, bp_load_cases_inline_param_type@main@@BpInline__link__props}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 23}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" <">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 4, {atom, bp_load_cases_inline_param_type@main@@BpInline__link__props}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 24}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 3}.
    return.

{function, again, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, again}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 4, {atom, bp_load_cases_inline_param_type@main@@BpInline__again__props}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 57}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 58}, [{x, 0}, 4, {atom, bp_load_cases_inline_param_type@main@@BpInline__again__props}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 58}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_inline_param_type@main@@BpInline__link__props}, {x, 1}, {x, 2}, {x, 0}]}}.
    {call_last, 1, {f, 3}, 1}.

{function, scaled, 2, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, scaled}, 2}.
  {label, 7}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 59}, [{x, 0}, 3, {atom, bp_load_cases_inline_param_type@main@@BpInline__scaled__props}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 59}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 60}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 60}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:24:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 61}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 3, {atom, bp_load_cases_inline_param_type@main@@BpInline__scaled__props}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 62}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 64}}.
    {deallocate, 2}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"/a">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"A">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, false}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_inline_param_type@main@@BpInline__link__props}, {x, 1}, {x, 2}, {x, 0}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {literal, <<"/b">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"B">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_inline_param_type@main@@BpInline__link__props}, {x, 1}, {x, 2}, {x, 0}]}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {literal, <<"/c">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"C">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {atom, true}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_inline_param_type@main@@BpInline__again__props}, {x, 1}, {x, 2}, {x, 0}]}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {literal, <<"px">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_inline_param_type@main@@BpInline__scaled__props}, {integer, 4}, {x, 0}]}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {literal, <<"em">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_inline_param_type@main@@BpInline__scaled__props}, {integer, 5}, {x, 0}]}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/inline_param_type|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_priv__again', 1, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_priv__again'}, 1}.
  {label, 67}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__scaled', 2, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_priv__scaled'}, 2}.
  {label, 69}.
    {call_only, 2, {f, 7}}.

{function, '__bp_print', 1, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_print'}, 1}.
  {label, 26}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 30}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 28}}.

{function, '-bp_show_elem-', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 32}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 28}}.

{function, '__bp_show', 2, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_show'}, 2}.
  {label, 28}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 40}, [{x, 0}]}.
    {test, is_eq, {f, 39}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 41}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 43}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 42}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 42}, [{x, 0}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 48}}.
  {label, 47}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 48}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 28}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 45}, [{x, 0}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, undefined}]}.
  {label, 44}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 34}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 46}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_tagged'}, 2}.
  {label, 34}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 49}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 49}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 49}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 36}, 3}.
  {label, 50}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_render'}, 1}.
  {label, 36}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 51}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 52}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 38}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 28}}.
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

{function, '-bp_stringify-', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 54}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 55}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 55}.
    {test, is_integer, {f, 56}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 56}.
    {call, 1, {f, 30}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_add', 2, 64}.
  {label, 63}.
    {line, [{location, "bp_load_cases_inline_param_type@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_inline_param_type@main}, {atom, '__bp_add'}, 2}.
  {label, 64}.
    {test, is_binary, {f, 65}, [{x, 0}]}.
    {test, is_binary, {f, 65}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 65}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.
