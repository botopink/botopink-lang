{module, bp_load_cases_optional_record_method_absent_receiver@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__col', 1}, {'__bp_priv__p', 1}]}.
{attributes, []}.
{labels, 110}.
%%% Decision 330 — `recv?.m()` over a method of a record or of an all-unit
%%% enum: the receiver is evaluated once, the method runs only on a present
%%% one, and the call is the optional of its answer — a present `0`, `false`
%%% stays present, a float answer too, an answer that is itself optional is
%%% not nested — on every target (`modules/optional_method_absent_receiver`
%%% is a primitive receiver, `modules/optional_enum_method_absent_receiver`
%%% an enum with payloads).

{function, p, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, p}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 18}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {integer, 0}]}}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 19}.
    {deallocate, 1}.
    return.

{function, col, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, col}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 20}, [{y, 0}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 20}.
    {test, is_eq_exact, {f, 21}, [{y, 0}, {integer, 1}]}.
    {move, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C__v__red}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 21}.
    {move, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C__v__green}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 38, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}]}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 22}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, twice, 1}}.
  {label, 23}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 53}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 54}}.
  {label, 53}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, half, 1}}.
  {label, 54}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 55}}.
  {label, 52}.
    {move, {float, -1.0}, {x, 0}}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 57}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, half, 1}}.
  {label, 58}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {jump, {f, 59}}.
  {label, 56}.
    {move, {float, -1.0}, {x, 0}}.
  {label, 59}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 61}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 62}}.
  {label, 61}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, zero, 1}}.
  {label, 62}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 60}.
    {move, {atom, false}, {x, 0}}.
  {label, 63}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 65}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, zero, 1}}.
  {label, 66}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 64}.
    {move, {atom, false}, {x, 0}}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 69}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 70}}.
  {label, 69}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, 'maybe', 1}}.
  {label, 70}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 68}.
    {move, {integer, -1}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, 'maybe', 1}}.
  {label, 74}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 72}.
    {move, {integer, -1}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 77}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, me, 1}}.
  {label, 78}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 79}.
    {test, is_tagged_tuple, {f, 80}, [{x, 0}, 2, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 81}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 82}}.
  {label, 76}.
    {move, {integer, -1}, {x, 0}}.
  {label, 82}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, me, 1}}.
  {label, 85}.
    {test, is_eq, {f, 86}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 88}}.
  {label, 86}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 2, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 88}}.
  {label, 87}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 88}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {jump, {f, 89}}.
  {label, 83}.
    {move, {integer, -1}, {x, 0}}.
  {label, 89}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_eq, {f, 91}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 92}}.
  {label, 91}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@C, n, 1}}.
  {label, 92}.
    {test, is_ne_exact, {f, 90}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 90}.
    {move, {integer, -1}, {x, 0}}.
  {label, 93}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_eq, {f, 95}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@C, n, 1}}.
  {label, 96}.
    {test, is_ne_exact, {f, 94}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 20}}.
    {move, {y, 20}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 94}.
    {move, {integer, -1}, {x, 0}}.
  {label, 97}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_eq, {f, 99}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@C, n, 1}}.
  {label, 100}.
    {test, is_ne_exact, {f, 98}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {jump, {f, 101}}.
  {label, 98}.
    {move, {integer, -1}, {x, 0}}.
  {label, 101}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 23}, {x, 0}}.
    {test, is_eq, {f, 103}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_record_method_absent_receiver@main@@P, twice, 1}}.
  {label, 104}.
    {test, is_ne_exact, {f, 102}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 25}, {x, 0}}.
    {jump, {f, 105}}.
  {label, 102}.
    {move, {integer, 7}, {x, 0}}.
  {label, 105}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 25}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 38}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_record_method_absent_receiver|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_priv__col', 1, 107}.
  {label, 106}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_priv__col'}, 1}.
  {label, 107}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__p', 1, 109}.
  {label, 108}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_priv__p'}, 1}.
  {label, 109}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_print'}, 1}.
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
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 29}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '-bp_show_elem-', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 31}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 27}}.

{function, '__bp_show', 2, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_show'}, 2}.
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
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_tagged'}, 2}.
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
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '__bp_render'}, 1}.
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
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main}, {atom, '-bp_render_pair-'}, 1}.
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
