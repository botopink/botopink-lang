{module, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 6}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All.erl", 1}]}.
    {func_info, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All__v__4}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Bp__Tok__Pad__All.__4">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, bp_load_cases_comptime_decorator_section_value@main@@Bp__Tok__Pad__All__v__8}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Bp__Tok__Pad__All.__8">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Bp__Tok__Pad__All">>}, nil]}}.
    {deallocate, 2}.
    return.
