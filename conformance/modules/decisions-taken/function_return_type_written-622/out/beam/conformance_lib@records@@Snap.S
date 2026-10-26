{module, conformance_lib@records@@Snap}.
{exports, [{isEmpty, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 36}.

{function, isEmpty, 1, 3}.
  {label, 2}.
    {line, [{location, "conformance_lib@records@@Snap.erl", 5}]}.
    {func_info, {atom, conformance_lib@records@@Snap}, {atom, isEmpty}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 4}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 4}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 6}}.
  {label, 5}.
    {move, {atom, false}, {x, 0}}.
  {label, 6}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 7}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 9}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {atom, false}, {x, 0}}.
  {label, 11}.
    {jump, {f, 8}}.
  {label, 7}.
    {move, {atom, false}, {x, 0}}.
  {label, 8}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 12}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 14}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 15}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 16}}.
  {label, 15}.
    {move, {atom, false}, {x, 0}}.
  {label, 16}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {atom, false}, {x, 0}}.
  {label, 13}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 17}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 19}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 19}.
    {test, is_eq, {f, 20}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
    {move, {atom, true}, {x, 0}}.
  {label, 21}.
    {jump, {f, 18}}.
  {label, 17}.
    {move, {atom, false}, {x, 0}}.
  {label, 18}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 22}, [{x, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 6, {atom, conformance_lib@records@@Snap}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 24}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {atom, false}, {x, 0}}.
  {label, 26}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {atom, false}, {x, 0}}.
  {label, 23}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 28}.
  {label, 27}.
    {line, [{location, "conformance_lib@records@@Snap.erl", 6}]}.
    {func_info, {atom, conformance_lib@records@@Snap}, {atom, '__bp_get'}, 2}.
  {label, 28}.
    {test, is_eq_exact, {f, 29}, [{x, 1}, {atom, refusals}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 29}.
    {test, is_eq_exact, {f, 30}, [{x, 1}, {atom, build}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 30}.
    {test, is_eq_exact, {f, 31}, [{x, 1}, {atom, stdout}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 31}.
    {test, is_eq_exact, {f, 32}, [{x, 1}, {atom, abort}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 32}.
    {test, is_eq_exact, {f, 33}, [{x, 1}, {atom, stderr}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 33}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 35}.
  {label, 34}.
    {line, [{location, "conformance_lib@records@@Snap.erl", 6}]}.
    {func_info, {atom, conformance_lib@records@@Snap}, {atom, '__bp_format'}, 1}.
  {label, 35}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"stderr">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"abort">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"stdout">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"build">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"refusals">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Snap">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
