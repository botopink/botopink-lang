{module, bp_load_cases_type_empty_record@main@@Marker}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 4}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_type_empty_record@main@@Marker.erl", 1}]}.
    {func_info, {atom, bp_load_cases_type_empty_record@main@@Marker}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Marker">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
