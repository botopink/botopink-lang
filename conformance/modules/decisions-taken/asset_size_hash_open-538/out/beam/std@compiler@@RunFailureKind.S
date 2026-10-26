{module, std@compiler@@RunFailureKind}.
{exports, [{'__bp_format', 1}]}.
{attributes, []}.
{labels, 8}.

{function, '__bp_format', 1, 3}.
  {label, 2}.
    {line, [{location, "std@compiler@@RunFailureKind.erl", 8}]}.
    {func_info, {atom, std@compiler@@RunFailureKind}, {atom, '__bp_format'}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 4}, [{x, 0}, {atom, std@compiler@@RunFailureKind__v__failed}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"RunFailureKind.Failed">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 4}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 5}, [{x, 0}, {atom, std@compiler@@RunFailureKind__v__abort}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"RunFailureKind.Abort">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 5}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 6}, [{x, 0}, {atom, std@compiler@@RunFailureKind__v__refused}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"RunFailureKind.Refused">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 6}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq_exact, {f, 7}, [{x, 0}, {atom, std@compiler@@RunFailureKind__v__excluded}]}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"RunFailureKind.Excluded">>}, nil]}}.
    {deallocate, 2}.
    return.
  {label, 7}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, variant}, {literal, <<"RunFailureKind">>}, nil]}}.
    {deallocate, 2}.
    return.
