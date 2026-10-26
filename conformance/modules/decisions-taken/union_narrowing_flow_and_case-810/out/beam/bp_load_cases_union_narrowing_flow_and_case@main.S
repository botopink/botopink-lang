{module, bp_load_cases_union_narrowing_flow_and_case@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__area', 1}, {'__bp_priv__describe', 1}, {'__bp_priv__first', 1}, {'__bp_priv__firstCase', 1}, {'__bp_priv__name', 1}, {'__bp_priv__sides', 1}, {'__bp_priv__viaLocals', 1}]}.
{attributes, []}.
{labels, 129}.
%%% Decision 810 — a union narrows by the flow of an `is` and by an
%%% exhaustive `case` with type patterns, both in force. (2) Past an `if`
%%% whose branch leaves, the name is the union without the member it tested,
%%% each further test removing one more; in the `else` too; for a parameter,
%%% a `val`, a loop's binder and a `var` until it is assigned. (1) `v is
%%% Box<T>` is accepted where `Box<T>` is a member of `v`'s type, `T` bound
%%% through it. (3) A `case` over a union covers it with a type pattern per
%%% member, a generic one included (`Box<T> { b -> … }`), and needs no `_`.

{function, area, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, area}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 29}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {atom, false}, {x, 0}}.
  {label, 30}.
    {test, is_eq, {f, 28}, [{x, 0}, {atom, true}]}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 1}.
    return.
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, false}, {x, 0}}.
  {label, 33}.
    {test, is_eq, {f, 31}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 34}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 35}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 36}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 36}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 37}}.
  {label, 36}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:24:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 37}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 3}], {x, 0}}.
    {test, is_ge, {f, 38}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 38}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 39}}.
  {label, 38}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:24:39">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 39}.
    {deallocate, 1}.
    return.
  {label, 31}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 40}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 40}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 41}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 41}.
    {gc_bif, '*', {f, 0}, 2, [{x, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 42}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 42}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 43}}.
  {label, 42}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:25:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 43}.
    {deallocate, 1}.
    return.

{function, name, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, name}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 45}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 46}}.
  {label, 45}.
    {move, {atom, false}, {x, 0}}.
  {label, 46}.
    {test, is_eq, {f, 44}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 47}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 47}.
    {deallocate, 2}.
    return.
  {label, 44}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 48}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 48}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"circle ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, viaLocals, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, viaLocals}, 1}.
  {label, 7}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, false}, {x, 0}}.
  {label, 83}.
    {test, is_eq, {f, 81}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"square">>}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 81}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 85}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {atom, false}, {x, 0}}.
  {label, 86}.
    {test, is_eq, {f, 84}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 87}.
    {deallocate, 5}.
    return.
  {label, 84}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 88}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"reset">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}, {x, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"r=">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 5}.
    return.

{function, sides, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, sides}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 90}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, first, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, first}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 99}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Box}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {atom, false}, {x, 0}}.
  {label, 100}.
    {test, is_eq, {f, 98}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 101}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 101}.
    {deallocate, 1}.
    return.
  {label, 98}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 102}, [{x, 0}, 3, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Pair}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 102}.
    {deallocate, 1}.
    return.

{function, firstCase, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, firstCase}, 1}.
  {label, 13}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_tagged_tuple, {f, 104}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Box}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 105}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Box}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 105}.
    {jump, {f, 103}}.
  {label, 104}.
    {test, is_tagged_tuple, {f, 106}, [{x, 0}, 3, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Pair}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 107}, [{x, 0}, 3, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Pair}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 107}.
    {jump, {f, 103}}.
  {label, 106}.
    {case_end, {x, 0}}.
  {label, 103}.
    {deallocate, 4}.
    return.

{function, describe, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, describe}, 1}.
  {label, 15}.
    {allocate, 8, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_tagged_tuple, {f, 109}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 110}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 110}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"dot ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 108}}.
  {label, 109}.
    {test, is_tagged_tuple, {f, 111}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 112}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 112}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"circle ">>}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 108}}.
  {label, 111}.
    {test, is_tagged_tuple, {f, 113}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 114}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 114}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"square ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 108}}.
  {label, 113}.
    {case_end, {x, 0}}.
  {label, 108}.
    {deallocate, 8}.
    return.

{function, main, 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, main}, 0}.
  {label, 17}.
    {allocate, 15, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}, {integer, 4}]}}.
    {call, 1, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}, {integer, 2}]}}.
    {call, 1, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"d">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}, {x, 0}]}}.
    {call, 1, {f, 3}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, {literal, <<"dot">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}, {x, 0}]}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}, {integer, 5}]}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}, {integer, 7}]}}.
    {call, 1, {f, 7}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"kept">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}, {x, 0}]}}.
    {call, 1, {f, 7}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}, {integer, 1}]}}.
    {call, 1, {f, 7}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}, {integer, 3}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}, {integer, 2}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"left">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"right">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Pair}, {x, 1}, {x, 0}]}}.
    {call, 1, {f, 11}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"boxed">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Box}, {x, 0}]}}.
    {call, 1, {f, 11}}.
    {move, {y, 3}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Pair}, {integer, 2}, {integer, 3}]}}.
    {call, 1, {f, 13}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Box}, {integer, 1}]}}.
    {call, 1, {f, 13}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, {literal, <<"x">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}, {x, 0}]}}.
    {call, 1, {f, 15}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Circle}, {integer, 1}]}}.
    {call, 1, {f, 15}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}, {integer, 9}]}}.
    {call, 1, {f, 15}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 50}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 15}.
    return.

{function, '__bp_loaded_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {call, 0, {f, 17}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 23}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/union_narrowing_flow_and_case|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '_botopink_main'}, 0}.
  {label, 25}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 17}, 0}.

{function, main, 1, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, main}, 1}.
  {label, 27}.
    {call_only, 0, {f, 25}}.

{function, '__bp_priv__area', 1, 116}.
  {label, 115}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_priv__area'}, 1}.
  {label, 116}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__describe', 1, 118}.
  {label, 117}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_priv__describe'}, 1}.
  {label, 118}.
    {call_only, 1, {f, 15}}.

{function, '__bp_priv__first', 1, 120}.
  {label, 119}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_priv__first'}, 1}.
  {label, 120}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__firstCase', 1, 122}.
  {label, 121}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_priv__firstCase'}, 1}.
  {label, 122}.
    {call_only, 1, {f, 13}}.

{function, '__bp_priv__name', 1, 124}.
  {label, 123}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_priv__name'}, 1}.
  {label, 124}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__sides', 1, 126}.
  {label, 125}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_priv__sides'}, 1}.
  {label, 126}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__viaLocals', 1, 128}.
  {label, 127}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 20}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_priv__viaLocals'}, 1}.
  {label, 128}.
    {call_only, 1, {f, 7}}.

{function, '__bp_print', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_print'}, 1}.
  {label, 50}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 54}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 52}}.

{function, '-bp_show_elem-', 1, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 56}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 52}}.

{function, '__bp_show', 2, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_show'}, 2}.
  {label, 52}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 64}, [{x, 0}]}.
    {test, is_eq, {f, 63}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 64}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 65}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 67}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 66}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 66}, [{x, 0}]}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 66}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 71}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 72}}.
  {label, 71}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 72}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 52}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 69}, [{x, 0}]}.
    {test, is_ne_exact, {f, 69}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 69}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 70}, [{x, 0}, {atom, undefined}]}.
  {label, 68}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 58}, 2}.
  {label, 69}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 70}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 58}.
  {label, 57}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_tagged'}, 2}.
  {label, 58}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 73}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 73}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 73}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 60}, 3}.
  {label, 74}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '__bp_render'}, 1}.
  {label, 60}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 75}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 76}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 62}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 62}.
  {label, 61}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 62}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 52}}.
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

{function, '-bp_stringify-', 1, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 78}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 79}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 79}.
    {test, is_integer, {f, 80}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 80}.
    {call, 1, {f, 54}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-sides/1-fun-0-', 2, 90}.
  {label, 89}.
    {line, [{location, "bp_load_cases_union_narrowing_flow_and_case@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_union_narrowing_flow_and_case@main}, {atom, '-sides/1-fun-0-'}, 2}.
  {label, 90}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 92}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Dot}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {atom, false}, {x, 0}}.
  {label, 93}.
    {test, is_eq, {f, 91}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
    {jump, {f, 94}}.
  {label, 91}.
  {label, 94}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 95}, [{x, 0}, 2, {atom, bp_load_cases_union_narrowing_flow_and_case@main@@Square}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 95}.
    {gc_bif, '+', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 96}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 96}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 97}}.
  {label, 96}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:46:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 97}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
