{module, std@io@process@@Signal}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@process@@Signal.erl", 7}]}.
    {func_info, {atom, std@io@process@@Signal}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@io@process@@Signal__v__int}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Signal.Int">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@io@process@@Signal__v__term}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Signal.Term">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@io@process@@Signal__v__hup}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Signal.Hup">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, std@io@process@@Signal__v__winch}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Signal.Winch">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"Signal">>}, nil]}}.
    {deallocate, 2}.
    return.
