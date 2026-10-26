{module, std@io@clock@@ClockError}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 5}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@clock@@ClockError.erl", 8}]}.
    {func_info, {atom, std@io@clock@@ClockError}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@io@clock@@ClockError__v__notrfc3339}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"ClockError.NotRfc3339">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"ClockError">>}, nil]}}.
    {deallocate, 2}.
    return.
