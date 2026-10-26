{module, bp_load_cases_decorator_arguments_check@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_first', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__handleFree', 1}, {'__bp_priv__passwordNotHandle', 1}, {'__bp_priv__passwordsMatch', 1}]}.
{attributes, []}.
{labels, 107}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 24}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 29}}.
  {label, 27}.
  {label, 25}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 30}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 31}}.
  {label, 30}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 29}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 29}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 29}}.
  {label, 33}.
  {label, 31}.
    {deallocate, 6}.
    return.
%%% Decision 280, example 1 (`01-checker/examples/decorator-arguments-280.md`)
%%% — `#[check]` on a type and on a function. Every parameter is `comptime`;
%%% `@Decl<T>` binds `T` to the annotated declaration, so `rule` is checked
%%% as an `fn(v: Account) -> bool` and `at` as a field of `Account` (`.confirm`,
%%% `Type.Field<T>` of decision 308); `code` takes a variant written as
%%% declared. The body reads the field key's `name` and the variant as values,
%%% each `x.value` of its `comptime x: @Expr<T>` (decision 364); `rule` is an
%%% `@Expr` of a function, which has no `.value` — the function form is told
%%% apart by the declaration's kind (question `s35-b`).

{function, passwordsMatch, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, passwordsMatch}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 34}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Account}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 34}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Account}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 35}.
    {test, is_eq_exact, {f, 36}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 37}}.
  {label, 36}.
    {move, {atom, false}, {x, 0}}.
  {label, 37}.
    {deallocate, 1}.
    return.

{function, handleFree, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, handleFree}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 38}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Account}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 38}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"admin">>}, {x, 0}}.
    {test, is_ne_exact, {f, 39}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 40}}.
  {label, 39}.
    {move, {atom, false}, {x, 0}}.
  {label, 40}.
    {deallocate, 1}.
    return.

{function, passwordNotHandle, 1, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, passwordNotHandle}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 41}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Account}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 41}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 42}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Account}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 42}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 43}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 44}}.
  {label, 43}.
    {move, {atom, true}, {x, 0}}.
  {label, 44}.
    {test, is_eq, {f, 45}, [{x, 0}, {atom, true}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 46}}.
  {label, 45}.
    {move, {atom, true}, {x, 0}}.
  {label, 46}.
    {deallocate, 1}.
    return.

{function, main, 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, main}, 0}.
  {label, 13}.
    {allocate, 5, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"handle">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"handle taken">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"mismatch">>}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_decorator_arguments_check@main@@Check}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"confirm">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"passwords differ">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"custom">>}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_decorator_arguments_check@main@@Check}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"rule">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"the password holds the handle">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"rule">>}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_decorator_arguments_check@main@@Check}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 85}}.
    {test, is_eq, {f, 86}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 88}}.
  {label, 86}.
    {test, is_tagged_tuple, {f, 87}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Check}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 88}}.
  {label, 87}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 88}.
    {test, is_ne_exact, {f, 83}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 89}}.
  {label, 83}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 89}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {literal, <<"ana">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"abc">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"abd">>}, {x, 0}}.
    {test_heap, 5, 3}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_decorator_arguments_check@main@@Account}, {x, 1}, {x, 2}, {x, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {y, 3}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.
% What `#[check]` records, once per annotation: the field it is `at` (`"type"`
% for none, `"rule"` on a function), the message and the code's kind.

{function, '__bp_loaded_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {call, 0, {f, 13}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/decorator_arguments_check|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '_botopink_main'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 13}, 0}.

{function, main, 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, main}, 1}.
  {label, 23}.
    {call_only, 0, {f, 21}}.

{function, 'array_first', 1, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, 'array_first'}, 1}.
  {label, 85}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 91}, 1}.

{function, '__bp_priv__array_first', 1, 96}.
  {label, 95}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_priv__array_first'}, 1}.
  {label, 96}.
    {call_only, 1, {f, 85}}.

{function, '__bp_priv__array_range', 2, 98}.
  {label, 97}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 98}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 100}.
  {label, 99}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 100}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__handleFree', 1, 102}.
  {label, 101}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_priv__handleFree'}, 1}.
  {label, 102}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__passwordNotHandle', 1, 104}.
  {label, 103}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_priv__passwordNotHandle'}, 1}.
  {label, 104}.
    {call_only, 1, {f, 11}}.

{function, '__bp_priv__passwordsMatch', 1, 106}.
  {label, 105}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_priv__passwordsMatch'}, 1}.
  {label, 106}.
    {call_only, 1, {f, 7}}.

{function, '__bp_print', 1, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_print'}, 1}.
  {label, 52}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 56}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 54}}.

{function, '-bp_show_elem-', 1, 58}.
  {label, 57}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 58}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 54}}.

{function, '__bp_show', 2, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_show'}, 2}.
  {label, 54}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 66}, [{x, 0}]}.
    {test, is_eq, {f, 65}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 65}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 66}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 67}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 93}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 91}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 67}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 69}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 68}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 68}, [{x, 0}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 73}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 74}}.
  {label, 73}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 74}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 54}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 68}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 58}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {integer, 40}, {x, 0}, {x, 0}}.
    {put_list, {integer, 35}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 69}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 71}, [{x, 0}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
  {label, 70}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 60}, 2}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 72}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 60}.
  {label, 59}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_tagged'}, 2}.
  {label, 60}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 75}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 75}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 75}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 62}, 3}.
  {label, 76}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 62}.
  {label, 61}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_render'}, 1}.
  {label, 62}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 77}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 77}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 78}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 64}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<", ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 8, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {y, 1}, {x, 1}, {x, 1}}.
    {put_list, {integer, 40}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_render_pair-', 1, 64}.
  {label, 63}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 64}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 54}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 6, 1}.
    {put_list, {y, 1}, nil, {x, 1}}.
    {put_list, {literal, <<": ">>}, {x, 1}, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_stringify-', 1, 80}.
  {label, 79}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 80}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 81}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 81}.
    {test, is_integer, {f, 82}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 82}.
    {call, 1, {f, 56}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-main/0-fun-0-', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 48}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<")">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 49}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Check}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 49}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" (">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 4, {atom, bp_load_cases_decorator_arguments_check@main@@Check}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 50}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-bp_at-', 2, 91}.
  {label, 90}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '-bp_at-'}, 2}.
  {label, 91}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 93}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 92}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 93}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 92}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 92}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_decorator_arguments_check@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_decorator_arguments_check@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 29}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 94}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 94}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
