{module, bp_load_cases_index_user_type@main@@Matrix}.
{exports, [{at, 2}, {slice, 3}, {'__bp_get', 2}, {'__bp_format', 1}, {'__bp_behaviors', 0}]}.
{attributes, []}.
{labels, 21}.

{function, at, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Matrix.erl", 3}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Matrix}, {atom, at}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, bp_load_cases_index_user_type@main@@Matrix}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 6}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 8}, 2}.

{function, slice, 3, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Matrix.erl", 4}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Matrix}, {atom, slice}, 3}.
  {label, 5}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 11}, [{x, 0}, 2, {atom, bp_load_cases_index_user_type@main@@Matrix}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 11}.
    {test, is_ne_exact, {f, 12}, [{y, 2}, {atom, undefined}]}.
    {gc_bif, '+', {f, 0}, 1, [{y, 1}, {integer, 1}], {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{y, 2}, {y, 1}], {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {jump, {f, 13}}.
  {label, 12}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
  {label, 13}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_index_user_type@main@@Matrix}, {x, 0}]}}.
    {deallocate, 3}.
    return.

{function, '__bp_get', 2, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Matrix.erl", 5}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Matrix}, {atom, '__bp_get'}, 2}.
  {label, 15}.
    {test, is_eq_exact, {f, 16}, [{x, 1}, {atom, rows}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 16}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 18}.
  {label, 17}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Matrix.erl", 5}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Matrix}, {atom, '__bp_format'}, 1}.
  {label, 18}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"rows">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Matrix">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_behaviors', 0, 20}.
  {label, 19}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Matrix.erl", 5}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Matrix}, {atom, '__bp_behaviors'}, 0}.
  {label, 20}.
    {move, {literal, [std@primitives@@Index, std@primitives@@Slice]}, {x, 0}}.
    return.

{function, '-bp_at-', 2, 8}.
  {label, 7}.
    {line, [{location, "bp_load_cases_index_user_type@main@@Matrix.erl", 4}]}.
    {func_info, {atom, bp_load_cases_index_user_type@main@@Matrix}, {atom, '-bp_at-'}, 2}.
  {label, 8}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 10}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 9}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 10}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 9}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 9}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
