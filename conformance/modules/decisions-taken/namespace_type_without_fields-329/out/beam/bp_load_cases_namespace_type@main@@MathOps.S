{module, bp_load_cases_namespace_type@main@@MathOps}.
{exports, [{double, 1}, {first, 2}, {quadruple, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 18}.

{function, double, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_namespace_type@main@@MathOps.erl", 1}]}.
    {func_info, {atom, bp_load_cases_namespace_type@main@@MathOps}, {atom, double}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 8}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 8}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 9}}.
  {label, 8}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:9:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 9}.
    {deallocate, 1}.
    return.

{function, first, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_namespace_type@main@@MathOps.erl", 2}]}.
    {func_info, {atom, bp_load_cases_namespace_type@main@@MathOps}, {atom, first}, 2}.
  {label, 5}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 12}}.
    {test, is_ne_exact, {f, 10}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 15}}.
  {label, 10}.
    {move, {y, 1}, {x, 0}}.
  {label, 15}.
    {deallocate, 3}.
    return.

{function, quadruple, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_namespace_type@main@@MathOps.erl", 3}]}.
    {func_info, {atom, bp_load_cases_namespace_type@main@@MathOps}, {atom, quadruple}, 1}.
  {label, 7}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {call_last, 1, {f, 3}, 3}.

{function, '__bp_format', 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_namespace_type@main@@MathOps.erl", 4}]}.
    {func_info, {atom, bp_load_cases_namespace_type@main@@MathOps}, {atom, '__bp_format'}, 1}.
  {label, 17}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"MathOps">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 12}.
  {label, 11}.
    {line, [{location, "bp_load_cases_namespace_type@main@@MathOps.erl", 3}]}.
    {func_info, {atom, bp_load_cases_namespace_type@main@@MathOps}, {atom, '-bp_at-'}, 2}.
  {label, 12}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 14}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 13}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 14}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 13}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 13}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.
