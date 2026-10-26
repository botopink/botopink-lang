{module, bp_load_cases_type_empty_record@main@@MathOps}.
{exports, [{double, 2}, {name, 1}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 10}.

{function, double, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_type_empty_record@main@@MathOps.erl", 1}]}.
    {func_info, {atom, bp_load_cases_type_empty_record@main@@MathOps}, {atom, double}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 6}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 6}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 7}}.
  {label, 6}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:11:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 7}.
    {deallocate, 2}.
    return.

{function, name, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_type_empty_record@main@@MathOps.erl", 2}]}.
    {func_info, {atom, bp_load_cases_type_empty_record@main@@MathOps}, {atom, name}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"ops">>}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_format', 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_type_empty_record@main@@MathOps.erl", 3}]}.
    {func_info, {atom, bp_load_cases_type_empty_record@main@@MathOps}, {atom, '__bp_format'}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"MathOps">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
