{module, bp_load_cases_record_structural_equality@main@@Loose}.
{exports, [{equals, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, equals, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_record_structural_equality@main@@Loose.erl", 1}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main@@Loose}, {atom, equals}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, true}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_get', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_record_structural_equality@main@@Loose.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main@@Loose}, {atom, '__bp_get'}, 2}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, n}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_record_structural_equality@main@@Loose.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main@@Loose}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"n">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Loose">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
