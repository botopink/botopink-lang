{module, bp_load_cases_numeric_suffix_positions@main@@Level}.
{exports, [{weight, 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, weight, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Level.erl", 10}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Level}, {atom, weight}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_format', 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main@@Level.erl", 11}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main@@Level}, {atom, '__bp_format'}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, bp_load_cases_numeric_suffix_positions@main@@Level__v__low}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Level.Low">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, bp_load_cases_numeric_suffix_positions@main@@Level__v__high}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Level.High">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Level">>}, nil]}}.
    {deallocate, 2}.
    return.
