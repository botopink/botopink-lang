{module, bp_load_cases_decorator_member_reaches_decorator_imports@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}]}.
{attributes, []}.
{labels, 14}.
%%% Decision 669 — names in code a decorator writes resolve in the module that
%%% wrote it, that module's imports included. `#[counted]`'s member calls
%%% `panic` and `print`, which `checks` imports from std; this module imports
%%% neither, and calls the member.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_decorator_member_reaches_decorator_imports@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_decorator_member_reaches_decorator_imports@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 2, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket}, {integer, 3}]}}.
    {call_ext, 1, {extfunc, bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket, report, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket}, {integer, 0}]}}.
    {call_ext, 1, {extfunc, bp_load_cases_decorator_member_reaches_decorator_imports@main@@Basket, report, 1}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_loaded_main', 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_decorator_member_reaches_decorator_imports@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_decorator_member_reaches_decorator_imports@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_decorator_member_reaches_decorator_imports@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_decorator_member_reaches_decorator_imports@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_decorator_member_reaches_decorator_imports@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_decorator_member_reaches_decorator_imports@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/decorator_member_reaches_decorator_imports|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_decorator_member_reaches_decorator_imports@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_decorator_member_reaches_decorator_imports@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 3}, 0}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_decorator_member_reaches_decorator_imports@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_member_reaches_decorator_imports@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.
