{module, bp_load_cases_optional_method_absent_receiver@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__string_slice', 3}, {'__bp_priv__find', 1}]}.
{attributes, []}.
{labels, 156}.
%%% Decision 330 — `recv?.m(args)` calls the method only on a present
%%% receiver: an absent one makes the whole call absent, on every target. The
%%% receiver is the optional itself here (a local, a call, an array element),
%%% not a link continuing a chain (`modules/optional_chain_method`).

{function, find, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, find}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test, is_eq_exact, {f, 16}, [{y, 0}, {x, 0}]}.
    {move, {literal, <<"found">>}, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 17}.
    {deallocate, 1}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 39, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}]}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 19}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 20}}.
  {label, 19}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 22}}.
  {label, 20}.
    {test, is_ne_exact, {f, 18}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 18}.
    {move, {integer, -1}, {x, 0}}.
  {label, 23}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 53}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 54}}.
  {label, 53}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 22}}.
  {label, 54}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 55}}.
  {label, 52}.
    {move, {integer, -1}, {x, 0}}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 56}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 57}}.
  {label, 56}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 22}}.
  {label, 57}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 58}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call, 1, {f, 22}}.
  {label, 59}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 61}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 62}}.
  {label, 61}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 64}}.
  {label, 62}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 65}}.
  {label, 60}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 65}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 67}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 68}}.
  {label, 67}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call, 1, {f, 64}}.
  {label, 68}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 66}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 69}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 71}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 72}}.
  {label, 71}.
    {move, {x, 0}, {y, 12}}.
    {move, {literal, <<"ou">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 12}, {x, 0}}.
    {call, 2, {f, 74}}.
  {label, 72}.
    {test, is_ne_exact, {f, 70}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 70}.
    {move, {atom, false}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 77}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, <<"ou">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 14}, {x, 0}}.
    {call, 2, {f, 74}}.
  {label, 78}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 76}.
    {move, {atom, false}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {literal, <<"be">>}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {literal, <<"alpha">>}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 84}}.
    {test, is_eq, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 82}}.
  {label, 81}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {call, 1, {f, 22}}.
  {label, 82}.
    {test, is_ne_exact, {f, 80}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {jump, {f, 87}}.
  {label, 80}.
    {move, {integer, -7}, {x, 0}}.
  {label, 87}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 17}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 84}}.
    {test, is_eq, {f, 89}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 20}, {x, 0}}.
    {move, {integer, 3}, {x, 2}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 3, {f, 92}}.
  {label, 90}.
    {test, is_ne_exact, {f, 88}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 88}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 93}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {y, 17}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 84}}.
    {test, is_eq, {f, 95}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {move, {integer, 3}, {x, 2}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 3, {f, 92}}.
  {label, 96}.
    {test, is_ne_exact, {f, 94}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 23}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 94}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 97}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 39}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_method_absent_receiver|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, 'string_slice', 3, 110}.
  {label, 109}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, 'string_slice'}, 3}.
  {label, 110}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 112}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 114}, 3}.
  {label, 112}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 136}, 3}.

{function, '__bp_priv__string_slice', 3, 153}.
  {label, 152}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 153}.
    {call_only, 3, {f, 110}}.

{function, '__bp_priv__find', 1, 155}.
  {label, 154}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_priv__find'}, 1}.
  {label, 155}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_print'}, 1}.
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
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 29}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '-bp_show_elem-', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 31}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '__bp_show', 2, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_show'}, 2}.
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
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_tagged'}, 2}.
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
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_render'}, 1}.
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
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '-bp_render_pair-'}, 1}.
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

{function, '-bp_at-', 2, 84}.
  {label, 83}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '-bp_at-'}, 2}.
  {label, 84}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 86}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 85}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 86}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 85}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 85}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0', 1, 99}.
  {label, 98}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 99}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_prim_length', 1, 22}.
  {label, 21}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_prim_length'}, 1}.
  {label, 22}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 100}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 99}, 1}.
  {label, 100}.
    %% unresolved_method: length/1
    {move, {literal, {unresolved_method, length, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 1}.
    return.

{function, '__bp_prim_toUpper', 1, 64}.
  {label, 63}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_prim_toUpper'}, 1}.
  {label, 64}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 101}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, string, uppercase, 1}, 1}.
  {label, 101}.
    %% unresolved_method: toUpper/1
    {move, {literal, {unresolved_method, toUpper, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 1}.
    return.

{function, '__bp_prim_contains', 2, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_prim_contains'}, 2}.
  {label, 74}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 102}, [{x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, member, 2}, 2}.
  {label, 102}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 105}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 103}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {atom, true}, {x, 0}}.
  {label, 104}.
    {deallocate, 2}.
    return.
  {label, 105}.
    %% unresolved_method: contains/2
    {move, {literal, {unresolved_method, contains, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_slice', 3, 92}.
  {label, 91}.
    {line, [{location, "bp_load_cases_optional_method_absent_receiver@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_prim_slice'}, 3}.
  {label, 92}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 108}, [{x, 0}]}.
    {test, is_ne_exact, {f, 106}, [{y, 2}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 2}, {y, 1}], {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 3, {extfunc, lists, sublist, 3}, 3}.
  {label, 106}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nthtail, 2}, 3}.
  {label, 108}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 111}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 110}, 3}.
  {label, 111}.
    %% unresolved_method: slice/3
    {move, {literal, {unresolved_method, slice, 3}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/3-fun-0-', 3, 118}.
  {label, 117}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_tpl_1-t/3-fun-0-'}, 3}.
  {label, 118}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 122}}.
  {label, 122}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 124}}.
  {label, 124}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 126}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 125}}.
  {label, 126}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 127}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 125}}.
  {label, 127}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 125}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 129}}.
  {label, 129}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 131}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 130}}.
  {label, 131}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 132}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 130}}.
  {label, 132}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 130}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 134}}.
  {label, 134}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_1', 3, 114}.
  {label, 113}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_tpl_1'}, 3}.
  {label, 114}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 118}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 140}.
  {label, 139}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 140}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 144}}.
  {label, 144}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 146}}.
  {label, 146}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 148}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 147}}.
  {label, 148}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 149}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 147}}.
  {label, 149}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 147}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 151}}.
  {label, 151}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_2', 2, 136}.
  {label, 135}.
    {func_info, {atom, bp_load_cases_optional_method_absent_receiver@main}, {atom, '__bp_tpl_2'}, 2}.
  {label, 136}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 140}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
