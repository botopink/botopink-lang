{module, std@io@process@@Captured}.
{exports, [{wait, 1}, {kill, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 16}.

{function, wait, 1, 3}.
  {label, 2}.
    {line, [{location, "std@io@process@@Captured.erl", 14}]}.
    {func_info, {atom, std@io@process@@Captured}, {atom, wait}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {atom, unreachable}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 1}.
    return.

{function, kill, 2, 5}.
  {label, 4}.
    {line, [{location, "std@io@process@@Captured.erl", 15}]}.
    {func_info, {atom, std@io@process@@Captured}, {atom, kill}, 2}.
  {label, 5}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {atom, unreachable}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {test, is_tagged_tuple, {f, 7}, [{x, 0}, 2, {atom, ok}]}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 5}.
    return.
    {jump, {f, 6}}.
  {label, 7}.
    {test, is_tagged_tuple, {f, 8}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 9}, [{x, 0}, 3, {atom, std@io@process@@Captured}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 9}.
    {move, {y, 2}, {x, 2}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 3}, {x, 0}}.
    {call_ext, 3, {extfunc, std@io@process, processError, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 5}.
    return.
    {jump, {f, 6}}.
  {label, 8}.
    {case_end, {x, 0}}.
  {label, 6}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_get', 2, 11}.
  {label, 10}.
    {line, [{location, "std@io@process@@Captured.erl", 16}]}.
    {func_info, {atom, std@io@process@@Captured}, {atom, '__bp_get'}, 2}.
  {label, 11}.
    {test, is_eq_exact, {f, 12}, [{x, 1}, {atom, pid}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 12}.
    {test, is_eq_exact, {f, 13}, [{x, 1}, {atom, handle}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 13}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 15}.
  {label, 14}.
    {line, [{location, "std@io@process@@Captured.erl", 16}]}.
    {func_info, {atom, std@io@process@@Captured}, {atom, '__bp_format'}, 1}.
  {label, 15}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"handle">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"pid">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Captured">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
