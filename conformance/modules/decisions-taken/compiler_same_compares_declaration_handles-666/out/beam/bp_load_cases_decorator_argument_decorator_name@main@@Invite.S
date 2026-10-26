{module, bp_load_cases_decorator_argument_decorator_name@main@@Invite}.
{exports, [{guestsEach, 0}, {hostsEach, 0}, {hostsAll, 0}, {'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 14}.

{function, guestsEach, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_decorator_argument_decorator_name@main@@Invite.erl", 1}]}.
    {func_info, {atom, bp_load_cases_decorator_argument_decorator_name@main@@Invite}, {atom, guestsEach}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"email">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hostsEach, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_decorator_argument_decorator_name@main@@Invite.erl", 2}]}.
    {func_info, {atom, bp_load_cases_decorator_argument_decorator_name@main@@Invite}, {atom, hostsEach}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"lowercased">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, hostsAll, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_decorator_argument_decorator_name@main@@Invite.erl", 3}]}.
    {func_info, {atom, bp_load_cases_decorator_argument_decorator_name@main@@Invite}, {atom, hostsAll}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {integer, 2}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_get', 2, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_decorator_argument_decorator_name@main@@Invite.erl", 4}]}.
    {func_info, {atom, bp_load_cases_decorator_argument_decorator_name@main@@Invite}, {atom, '__bp_get'}, 2}.
  {label, 9}.
    {test, is_eq_exact, {f, 10}, [{x, 1}, {atom, guests}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 10}.
    {test, is_eq_exact, {f, 11}, [{x, 1}, {atom, hosts}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 11}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_decorator_argument_decorator_name@main@@Invite.erl", 4}]}.
    {func_info, {atom, bp_load_cases_decorator_argument_decorator_name@main@@Invite}, {atom, '__bp_format'}, 1}.
  {label, 13}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"hosts">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"guests">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"Invite">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
