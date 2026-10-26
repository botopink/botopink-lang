{module, bp_load_cases_bigint_in_containers@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_fold', 3}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__three', 0}]}.
{attributes, []}.
{labels, 96}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 20}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 22}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 25}}.
  {label, 23}.
  {label, 21}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 26}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 28}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 25}}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 25}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 25}}.
  {label, 29}.
  {label, 27}.
    {deallocate, 6}.
    return.
%%% Decision 332 — a `bigint` held by a record field, a `?bigint` field, a tuple, an array and an
%%% optional prints its digits and compares by value on the four targets: wasm's slot holds the
%%% block's address, printed by the `n` shape code and compared by std-wasm's `bigint.compare` (as an `i32` word,
%%% the address printed and two equal values built apart compared unequal).

{function, three, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, three}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 1}, {integer, 2}], {x, 0}}.
    {deallocate, 0}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 17, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}]}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 123456789012345678901234567890}, {integer, 10}], {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_bigint_in_containers@main@@Ledger}, {x, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 58}, [{x, 0}, 3, {atom, bp_load_cases_bigint_in_containers@main@@Ledger}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 58}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {call, 0, {f, 7}}.
    {move, {x, 0}, {y, 1}}.
    {call, 0, {f, 7}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_bigint_in_containers@main@@Ledger}, {y, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 2}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_bigint_in_containers@main@@Ledger}, {integer, 3}, {integer, 3}]}}.
    {test, is_eq_exact, {f, 59}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 60}}.
  {label, 59}.
    {move, {atom, false}, {x, 0}}.
  {label, 60}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {call, 0, {f, 7}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_bigint_in_containers@main@@Ledger}, {x, 0}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_bigint_in_containers@main@@Ledger}, {integer, 3}, {integer, 3}]}}.
    {test, is_eq_exact, {f, 61}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 62}}.
  {label, 61}.
    {move, {atom, false}, {x, 0}}.
  {label, 62}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {call, 0, {f, 7}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 1000000000000000000000}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"big">>}, {x, 0}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{x, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {literal, <<"big">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 3000000000000000000000}, {x, 0}]}}.
    {test, is_eq_exact, {f, 63}, [{y, 4}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 64}}.
  {label, 63}.
    {move, {atom, false}, {x, 0}}.
  {label, 64}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {integer, 40000000000000000000000}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {call, 0, {f, 7}}.
    {move, {y, 5}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {integer, 40000000000000000000000}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test, is_eq_exact, {f, 65}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {atom, false}, {x, 0}}.
  {label, 66}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 68}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call, 2, {f, 68}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 72}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 6}, {x, 0}}.
    {call, 3, {f, 74}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {test, is_lt, {f, 77}, [{integer, 0}, {y, 8}]}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 78}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {call, 0, {f, 7}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 40000000000000000000000}], {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{y, 9}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 80}}.
  {label, 79}.
    {move, {atom, false}, {x, 0}}.
  {label, 80}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {call, 0, {f, 7}}.
    {test, is_eq, {f, 82}, [{x, 0}, {integer, 3}]}.
    {move, {literal, <<"three">>}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 82}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 81}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_ge, {f, 84}, [{x, 0}, {integer, 0}]}.
    {test, is_ge, {f, 84}, [{integer, 9}, {x, 0}]}.
    {move, {literal, <<"small">>}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 84}.
    {move, {literal, <<"large">>}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 83}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 17}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/bigint_in_containers|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, 'array_fold', 3, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, 'array_fold'}, 3}.
  {label, 74}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 86}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_priv__array_fold', 3, 89}.
  {label, 88}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_priv__array_fold'}, 3}.
  {label, 89}.
    {call_only, 3, {f, 74}}.

{function, '__bp_priv__array_range', 2, 91}.
  {label, 90}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 91}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 93}.
  {label, 92}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 93}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__three', 0, 95}.
  {label, 94}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_priv__three'}, 0}.
  {label, 95}.
    {call_only, 0, {f, 7}}.

{function, '__bp_print', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_print'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 35}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '-bp_show_elem-', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 37}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '__bp_show', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_show'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 45}, [{x, 0}]}.
    {test, is_eq, {f, 44}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 46}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 48}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 47}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 47}, [{x, 0}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 53}}.
  {label, 52}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 53}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 50}, [{x, 0}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, undefined}]}.
  {label, 49}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 39}, 2}.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 51}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_tagged'}, 2}.
  {label, 39}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 54}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 41}, 3}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_render'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 56}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 57}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
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

{function, '-bp_at-', 2, 68}.
  {label, 67}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '-bp_at-'}, 2}.
  {label, 68}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 70}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 69}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 70}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 69}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 69}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-0-', 2, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '-main/0-fun-0-'}, 2}.
  {label, 72}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 1}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-1-', 2, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '-main/0-fun-1-'}, 2}.
  {label, 76}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-fold/3-fun-2-', 3, 86}.
  {label, 85}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '-fold/3-fun-2-'}, 3}.
  {label, 86}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_bigint_in_containers@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_bigint_in_containers@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 25}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 87}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 87}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
