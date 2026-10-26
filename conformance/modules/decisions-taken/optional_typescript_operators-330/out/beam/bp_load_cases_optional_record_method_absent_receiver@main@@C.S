{module, bp_load_cases_optional_record_method_absent_receiver@main@@C}.
{exports, [{n, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 11}.

{function, n, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@C.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C}, {atom, n}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 5}, [{x, 0}, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C__v__red}]}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 5}.
    {test, is_eq, {f, 6}, [{x, 0}, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C__v__green}]}.
    {move, {integer, 1}, {x, 0}}.
    {jump, {f, 4}}.
  {label, 6}.
    {case_end, {x, 0}}.
  {label, 4}.
    {deallocate, 3}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_optional_record_method_absent_receiver@main@@C.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 9}, [{x, 0}, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C__v__red}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"C.Red">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 9}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 10}, [{x, 0}, {atom, bp_load_cases_optional_record_method_absent_receiver@main@@C__v__green}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"C.Green">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 10}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"C">>}, nil]}}.
    {deallocate, 2}.
    return.
