{module, std@testing@mocks@@UserService}.
{exports, [{list, 1}, {name, 2}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 21}.

{function, list, 1, 3}.
  {label, 2}.
    {line, [{location, "std@testing@mocks@@UserService.erl", 21}]}.
    {func_info, {atom, std@testing@mocks@@UserService}, {atom, list}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 6}, [{x, 0}, 2, {atom, std@testing@mocks@@UserService}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 6}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, all}, {x, 0}}.
    {call_last, 3, {f, 8}, 1}.

{function, name, 2, 5}.
  {label, 4}.
    {line, [{location, "std@testing@mocks@@UserService.erl", 22}]}.
    {func_info, {atom, std@testing@mocks@@UserService}, {atom, name}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 15}, [{x, 0}, 2, {atom, std@testing@mocks@@UserService}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 15}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 2}}.
    {put_list, {x, 0}, {x, 2}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, find}, {x, 0}}.
    {call_last, 3, {f, 8}, 2}.

{function, '__bp_get', 2, 17}.
  {label, 16}.
    {line, [{location, "std@testing@mocks@@UserService.erl", 23}]}.
    {func_info, {atom, std@testing@mocks@@UserService}, {atom, '__bp_get'}, 2}.
  {label, 17}.
    {test, is_eq_exact, {f, 18}, [{x, 1}, {atom, repo}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 18}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 20}.
  {label, 19}.
    {line, [{location, "std@testing@mocks@@UserService.erl", 23}]}.
    {func_info, {atom, std@testing@mocks@@UserService}, {atom, '__bp_format'}, 1}.
  {label, 20}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"repo">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"UserService">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-bp_method-', 3, 8}.
  {label, 7}.
    {line, [{location, "std@testing@mocks@@UserService.erl", 22}]}.
    {func_info, {atom, std@testing@mocks@@UserService}, {atom, '-bp_method-'}, 3}.
  {label, 8}.
    {test, is_map, {f, 9}, [{x, 1}]}.
    {bif, map_get, {f, 0}, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {call_ext_only, 2, {extfunc, erlang, apply, 2}}.
  {label, 9}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 2}, {y, 1}}.
    {test, is_tuple, {f, 10}, [{x, 1}]}.
    {bif, element, {f, 0}, [{integer, 1}, {x, 1}], {x, 0}}.
    {jump, {f, 11}}.
  {label, 10}.
    {move, {x, 1}, {x, 0}}.
  {label, 11}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, atom_to_binary, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, split, 2}}.
    {test, is_nonempty_list, {f, 12}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {test, is_nil, {f, 13}, [{x, 2}]}.
    {jump, {f, 12}}.
  {label, 13}.
    {move, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_atom, 1}}.
    {jump, {f, 14}}.
  {label, 12}.
    {move, {y, 2}, {x, 0}}.
  {label, 14}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {call_ext_last, 3, {extfunc, erlang, apply, 3}, 3}.
