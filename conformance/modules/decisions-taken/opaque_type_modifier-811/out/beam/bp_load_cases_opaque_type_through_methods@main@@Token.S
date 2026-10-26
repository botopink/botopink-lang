{module, bp_load_cases_opaque_type_through_methods@main@@Token}.
{exports, [{'of', 1}, {bumped, 1}, {used, 1}, {value, 1}, {uses, 1}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 24}.

{function, 'of', 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_opaque_type_through_methods@main@@Token.erl", 1}]}.
    {func_info, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {atom, 'of'}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {y, 0}, {integer, 0}]}}.
    {deallocate, 1}.
    return.

{function, bumped, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_opaque_type_through_methods@main@@Token.erl", 2}]}.
    {func_info, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {atom, bumped}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 12}, [{x, 0}, 3, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 12}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 13}, [{x, 0}, 3, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 13}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 14}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 14}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 15}}.
  {label, 14}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:15:51">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 15}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {x, 1}, {x, 0}]}}.
    {deallocate, 1}.
    return.

{function, used, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_opaque_type_through_methods@main@@Token.erl", 3}]}.
    {func_info, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {atom, used}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 5}, 1}.

{function, value, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_opaque_type_through_methods@main@@Token.erl", 4}]}.
    {func_info, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {atom, value}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 3, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 16}.
    {deallocate, 1}.
    return.

{function, uses, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_opaque_type_through_methods@main@@Token.erl", 5}]}.
    {func_info, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {atom, uses}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 17}, [{x, 0}, 3, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 17}.
    {deallocate, 1}.
    return.

{function, '__bp_get', 2, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_opaque_type_through_methods@main@@Token.erl", 6}]}.
    {func_info, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {atom, '__bp_get'}, 2}.
  {label, 19}.
    {test, is_eq_exact, {f, 20}, [{x, 1}, {atom, value}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 20}.
    {test, is_eq_exact, {f, 21}, [{x, 1}, {atom, uses}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 21}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_opaque_type_through_methods@main@@Token.erl", 6}]}.
    {func_info, {atom, bp_load_cases_opaque_type_through_methods@main@@Token}, {atom, '__bp_format'}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"uses">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"value">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Token">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
