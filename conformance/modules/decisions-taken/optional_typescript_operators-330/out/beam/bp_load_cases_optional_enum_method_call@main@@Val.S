{module, bp_load_cases_optional_enum_method_call@main@@Val}.
{exports, [{str, 1}, {plus, 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 16}.

{function, str, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_enum_method_call@main@@Val.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_enum_method_call@main@@Val}, {atom, str}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 2, {atom, bp_load_cases_optional_enum_method_call@main@@Val__v__text}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 6}}.
  {label, 7}.
    {move, {literal, <<"">>}, {x, 0}}.
    {jump, {f, 6}}.
  {label, 6}.
    {deallocate, 2}.
    return.

{function, plus, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_enum_method_call@main@@Val.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_enum_method_call@main@@Val}, {atom, plus}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 2, {atom, bp_load_cases_optional_enum_method_call@main@@Val__v__num}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 10}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 10}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:23:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 11}.
    {jump, {f, 8}}.
  {label, 9}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 8}}.
  {label, 8}.
    {deallocate, 3}.
    return.

{function, '__bp_format', 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_enum_method_call@main@@Val.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_enum_method_call@main@@Val}, {atom, '__bp_format'}, 1}.
  {label, 13}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 14}, [{x, 0}, 2, {atom, bp_load_cases_optional_enum_method_call@main@@Val__v__num}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"n">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Val.Num">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 14}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 15}, [{x, 0}, 2, {atom, bp_load_cases_optional_enum_method_call@main@@Val__v__text}]}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"s">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Val.Text">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 15}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Val">>}, nil]}}.
    {deallocate, 2}.
    return.
