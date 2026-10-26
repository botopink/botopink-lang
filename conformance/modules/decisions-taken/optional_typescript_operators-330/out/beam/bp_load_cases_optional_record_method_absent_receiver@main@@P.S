{module, bp_load_cases_optional_record_method_absent_receiver@main@@P}.
{exports, [{twice, 1}, {half, 1}, {zero, 1}, {'maybe', 1}, {me, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 29}.

{function, twice, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@P.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {atom, twice}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 2, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 12}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 13}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 13}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 14}}.
  {label, 13}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:13:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 14}.
    {deallocate, 1}.
    return.

{function, half, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@P.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {atom, half}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {float, 1.5}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, zero, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@P.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {atom, zero}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 15}, [{x, 0}, 2, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 15}.
    {test, is_eq_exact, {f, 16}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {atom, false}, {x, 0}}.
  {label, 17}.
    {deallocate, 1}.
    return.

{function, 'maybe', 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@P.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {atom, 'maybe'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 19}, [{x, 0}, 2, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 19}.
    {test, is_eq_exact, {f, 18}, [{x, 0}, {integer, 0}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 20}}.
  {label, 18}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 20}.
    {deallocate, 1}.
    return.

{function, me, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@P.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {atom, me}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 21}, [{x, 0}, 2, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 21}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 22}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 22}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:25:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 23}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {x, 0}]}}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@P.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {atom, '__bp_get'}, 2}.
  {label, 25}.
    {test, is_eq_exact, {f, 26}, [{x, 1}, {atom, x}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 26}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@P.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@P}, {atom, '__bp_format'}, 1}.
  {label, 28}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"x">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"P">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
