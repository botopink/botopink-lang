{module, bp_load_cases_decorator_arguments_check@main@@Code}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main@@Code.erl", 3}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main@@Code}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, bp_load_cases_decorator_arguments_check@main@@Code__v__custom}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Code.Custom">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, bp_load_cases_decorator_arguments_check@main@@Code__v__required}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Code.Required">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, bp_load_cases_decorator_arguments_check@main@@Code__v__tooshort}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Code.TooShort">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, bp_load_cases_decorator_arguments_check@main@@Code__v__mismatch}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Code.Mismatch">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Code">>}, nil]}}.
    {deallocate, 2}.
    return.
