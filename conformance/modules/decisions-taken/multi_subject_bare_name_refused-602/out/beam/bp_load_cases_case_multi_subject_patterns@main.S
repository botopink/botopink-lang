{module, bp_load_cases_case_multi_subject_patterns@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__area', 2}, {'__bp_priv__classify', 2}, {'__bp_priv__flags', 2}, {'__bp_priv__guarded', 2}, {'__bp_priv__kind', 2}]}.
{attributes, []}.
{labels, 125}.
%%% A multi-subject `case a, n { … }` matches every subject against its own
%%% pattern: a literal, a string, a primitive type over a union, a variant that
%%% binds its payload, a guard reading the subjects, `true` / `false`. wasm lowered
%%% the first subject alone and tested no `.multi` pattern, so the first arm
%%% answered every call; beam tested the numbers alone, so a string pattern and
%%% a type arm matched every value (`i32, 0` took `"s"`); commonJS tested a
%%% variant's tag and never bound its payload (`r is not defined`).

{function, classify, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, classify}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {test, is_tuple, {f, 25}, [{x, 0}]}.
    {test, test_arity, {f, 25}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_eq, {f, 25}, [{x, 1}, {integer, 0}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {literal, <<"x">>}, {x, 2}}.
    {test, is_eq, {f, 25}, [{x, 1}, {x, 2}]}.
    {move, {literal, <<"zero-x">>}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 25}.
    {test, is_tuple, {f, 26}, [{x, 0}]}.
    {test, test_arity, {f, 26}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_eq, {f, 26}, [{x, 1}, {integer, 0}]}.
    {move, {literal, <<"zero">>}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 26}.
    {test, is_tuple, {f, 27}, [{x, 0}]}.
    {test, test_arity, {f, 27}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {literal, <<"x">>}, {x, 2}}.
    {test, is_eq, {f, 27}, [{x, 1}, {x, 2}]}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 27}.
    {test, is_tuple, {f, 28}, [{x, 0}]}.
    {test, test_arity, {f, 28}, [{x, 0}, 2]}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {jump, {f, 24}}.
  {label, 28}.
    {case_end, {x, 0}}.
  {label, 24}.
    {deallocate, 2}.
    return.

{function, kind, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, kind}, 2}.
  {label, 5}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_integer, {f, 32}, [{x, 1}]}.
    {jump, {f, 31}}.
  {label, 32}.
    {test, is_float, {f, 30}, [{x, 1}]}.
    {gc_bif, trunc, {f, 0}, 2, [{x, 1}], {x, 2}}.
    {test, is_eq, {f, 30}, [{x, 1}, {x, 2}]}.
  {label, 31}.
    {test, is_ge, {f, 30}, [{x, 1}, {integer, -2147483648}]}.
    {test, is_ge, {f, 30}, [{integer, 2147483647}, {x, 1}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {test, is_eq, {f, 30}, [{x, 1}, {integer, 0}]}.
    {move, {literal, <<"int0">>}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 30}.
    {test, is_tuple, {f, 33}, [{x, 0}]}.
    {test, test_arity, {f, 33}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_binary, {f, 33}, [{x, 1}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {test, is_eq, {f, 33}, [{x, 1}, {integer, 0}]}.
    {move, {literal, <<"str0">>}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 33}.
    {test, is_tuple, {f, 34}, [{x, 0}]}.
    {test, test_arity, {f, 34}, [{x, 0}, 2]}.
    {move, {literal, <<"any">>}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 34}.
    {case_end, {x, 0}}.
  {label, 29}.
    {deallocate, 4}.
    return.

{function, area, 2, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, area}, 2}.
  {label, 7}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {test, is_tuple, {f, 36}, [{x, 0}]}.
    {test, test_arity, {f, 36}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_tagged_tuple, {f, 36}, [{x, 1}, 2, {atom, bp_load_cases_case_multi_subject_patterns@main@@Shape__v__circle}]}.
    {get_tuple_element, {x, 1}, 1, {x, 2}}.
    {move, {x, 2}, {y, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {test, is_eq, {f, 36}, [{x, 1}, {integer, 1}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {integer, 100}], {x, 0}}.
    {test, is_ge, {f, 37}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 37}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 38}}.
  {label, 37}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:36:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 38}.
    {jump, {f, 35}}.
  {label, 36}.
    {test, is_tuple, {f, 39}, [{x, 0}]}.
    {test, test_arity, {f, 39}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_tagged_tuple, {f, 39}, [{x, 1}, 2, {atom, bp_load_cases_case_multi_subject_patterns@main@@Shape__v__square}]}.
    {get_tuple_element, {x, 1}, 1, {x, 2}}.
    {move, {x, 2}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 3}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 40}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 40}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 41}}.
  {label, 40}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:37:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 41}.
    {jump, {f, 35}}.
  {label, 39}.
    {test, is_tuple, {f, 42}, [{x, 0}]}.
    {test, test_arity, {f, 42}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {test, is_eq, {f, 42}, [{x, 1}, {atom, bp_load_cases_case_multi_subject_patterns@main@@Shape__v__empty}]}.
    {move, {integer, -1}, {x, 0}}.
    {jump, {f, 35}}.
  {label, 42}.
    {test, is_tuple, {f, 43}, [{x, 0}]}.
    {test, test_arity, {f, 43}, [{x, 0}, 2]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 35}}.
  {label, 43}.
    {case_end, {x, 0}}.
  {label, 35}.
    {deallocate, 5}.
    return.

{function, guarded, 2, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, guarded}, 2}.
  {label, 9}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {test, is_tuple, {f, 45}, [{x, 0}]}.
    {test, test_arity, {f, 45}, [{x, 0}, 2]}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 46}, [{y, 1}, {y, 0}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"gt ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 44}}.
  {label, 46}.
    {move, {x, 1}, {x, 0}}.
  {label, 45}.
    {test, is_tuple, {f, 79}, [{x, 0}]}.
    {test, test_arity, {f, 79}, [{x, 0}, 2]}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 80}, [{y, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"eq ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 44}}.
  {label, 80}.
    {move, {x, 1}, {x, 0}}.
  {label, 79}.
    {test, is_tuple, {f, 81}, [{x, 0}]}.
    {test, test_arity, {f, 81}, [{x, 0}, 2]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"lt ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 44}}.
  {label, 81}.
    {case_end, {x, 0}}.
  {label, 44}.
    {deallocate, 5}.
    return.

{function, flags, 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, flags}, 2}.
  {label, 11}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {test, is_tuple, {f, 83}, [{x, 0}]}.
    {test, test_arity, {f, 83}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 85}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {atom, false}, {x, 0}}.
  {label, 86}.
    {move, {x, 0}, {x, 2}}.
    {test, is_eq, {f, 87}, [{x, 2}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 89}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {atom, false}, {x, 0}}.
  {label, 90}.
    {jump, {f, 88}}.
  {label, 87}.
    {move, {atom, false}, {x, 0}}.
  {label, 88}.
    {test, is_eq, {f, 84}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"both">>}, {x, 0}}.
    {jump, {f, 82}}.
  {label, 84}.
    {move, {x, 1}, {x, 0}}.
  {label, 83}.
    {test, is_tuple, {f, 91}, [{x, 0}]}.
    {test, test_arity, {f, 91}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 93}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 94}}.
  {label, 93}.
    {move, {atom, false}, {x, 0}}.
  {label, 94}.
    {move, {x, 0}, {x, 2}}.
    {test, is_eq, {f, 95}, [{x, 2}, {atom, true}]}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 97}, [{y, 4}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 98}}.
  {label, 97}.
    {move, {atom, false}, {x, 0}}.
  {label, 98}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {atom, false}, {x, 0}}.
  {label, 96}.
    {test, is_eq, {f, 92}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"first">>}, {x, 0}}.
    {jump, {f, 82}}.
  {label, 92}.
    {move, {x, 1}, {x, 0}}.
  {label, 91}.
    {test, is_tuple, {f, 99}, [{x, 0}]}.
    {test, test_arity, {f, 99}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {move, {x, 1}, {y, 6}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 7}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {test, is_eq_exact, {f, 101}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {atom, false}, {x, 0}}.
  {label, 102}.
    {move, {x, 0}, {x, 2}}.
    {test, is_eq, {f, 103}, [{x, 2}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 105}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 106}}.
  {label, 105}.
    {move, {atom, false}, {x, 0}}.
  {label, 106}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {atom, false}, {x, 0}}.
  {label, 104}.
    {test, is_eq, {f, 100}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"second">>}, {x, 0}}.
    {jump, {f, 82}}.
  {label, 100}.
    {move, {x, 1}, {x, 0}}.
  {label, 99}.
    {test, is_tuple, {f, 107}, [{x, 0}]}.
    {test, test_arity, {f, 107}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 9}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 109}, [{y, 9}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 110}}.
  {label, 109}.
    {move, {atom, false}, {x, 0}}.
  {label, 110}.
    {move, {x, 0}, {x, 2}}.
    {test, is_eq, {f, 111}, [{x, 2}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{y, 8}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {atom, false}, {x, 0}}.
  {label, 114}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {atom, false}, {x, 0}}.
  {label, 112}.
    {test, is_eq, {f, 108}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"none">>}, {x, 0}}.
    {jump, {f, 82}}.
  {label, 108}.
    {move, {x, 1}, {x, 0}}.
  {label, 107}.
    {case_end, {x, 0}}.
  {label, 82}.
    {deallocate, 10}.
    return.

{function, main, 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, main}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {literal, <<"y">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {literal, <<"y">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {literal, <<"s">>}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_case_multi_subject_patterns@main@@Shape__v__circle}, {integer, 2}]}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_case_multi_subject_patterns@main@@Shape__v__circle}, {integer, 2}]}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_case_multi_subject_patterns@main@@Shape__v__square}, {integer, 3}]}}.
    {move, {integer, 4}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {atom, bp_load_cases_case_multi_subject_patterns@main@@Shape__v__empty}, {x, 0}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 2, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 7}, {x, 1}}.
    {call, 2, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, true}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, false}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 48}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {call, 0, {f, 13}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/case_multi_subject_patterns|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '_botopink_main'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 13}, 0}.

{function, main, 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, main}, 1}.
  {label, 23}.
    {call_only, 0, {f, 21}}.

{function, '__bp_priv__area', 2, 116}.
  {label, 115}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_priv__area'}, 2}.
  {label, 116}.
    {call_only, 2, {f, 7}}.

{function, '__bp_priv__classify', 2, 118}.
  {label, 117}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_priv__classify'}, 2}.
  {label, 118}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__flags', 2, 120}.
  {label, 119}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_priv__flags'}, 2}.
  {label, 120}.
    {call_only, 2, {f, 11}}.

{function, '__bp_priv__guarded', 2, 122}.
  {label, 121}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_priv__guarded'}, 2}.
  {label, 122}.
    {call_only, 2, {f, 9}}.

{function, '__bp_priv__kind', 2, 124}.
  {label, 123}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_priv__kind'}, 2}.
  {label, 124}.
    {call_only, 2, {f, 5}}.

{function, '__bp_print', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_print'}, 1}.
  {label, 48}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 52}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 52}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 50}}.

{function, '-bp_show_elem-', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 54}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 50}}.

{function, '__bp_show', 2, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_show'}, 2}.
  {label, 50}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 62}, [{x, 0}]}.
    {test, is_eq, {f, 61}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 62}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 63}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 65}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 64}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 64}, [{x, 0}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 70}}.
  {label, 69}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 70}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 50}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 67}, [{x, 0}]}.
    {test, is_ne_exact, {f, 67}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 67}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
  {label, 66}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 56}, 2}.
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 68}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_tagged'}, 2}.
  {label, 56}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 71}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 71}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 71}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 58}, 3}.
  {label, 72}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 58}.
  {label, 57}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '__bp_render'}, 1}.
  {label, 58}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 73}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 74}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 60}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 60}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 50}}.
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

{function, '-bp_stringify-', 1, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_case_multi_subject_patterns@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_case_multi_subject_patterns@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 76}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 77}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 77}.
    {test, is_integer, {f, 78}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 78}.
    {call, 1, {f, 52}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
