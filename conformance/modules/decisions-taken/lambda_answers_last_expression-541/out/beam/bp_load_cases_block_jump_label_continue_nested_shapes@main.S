{module, bp_load_cases_block_jump_label_continue_nested_shapes@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__twoLabels', 3}, {'__bp_priv__whileUnderLabel', 1}]}.
{attributes, []}.
{labels, 96}.
%%% Decision 541 (2) — a labelled `continue` under an in-frame `while` inside
%%% the named loop, and one inner loop continuing two enclosing labels.

{function, whileUnderLabel, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, whileUnderLabel}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
    {'try', {y, 2}, {f, 33}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 2}}.
    {jump, {f, 35}}.
  {label, 33}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 34}, [{x, 1}, 3, {atom, '__bp_label_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {atom, outer}]}.
    {get_tuple_element, {x, 1}, 2, {x, 0}}.
    {jump, {f, 35}}.
  {label, 34}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 35}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, twoLabels, 3, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, twoLabels}, 3}.
  {label, 5}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 2}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, [{y, 1}, {y, 2}]}}.
    {'try', {y, 4}, {f, 61}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 4}}.
    {jump, {f, 63}}.
  {label, 61}.
    {try_case, {y, 4}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 62}, [{x, 1}, 3, {atom, '__bp_label_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, a}]}.
    {get_tuple_element, {x, 1}, 2, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 63}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 4, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 65}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 3}, {x, 3}}.
    {test_heap, 2, 4}.
    {put_list, {x, 0}, {x, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 3}, {x, 3}}.
    {test_heap, 2, 4}.
    {put_list, {x, 0}, {x, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 3}, {x, 3}}.
    {test_heap, 2, 4}.
    {put_list, {x, 0}, {x, 3}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 65}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/block_jump_label_continue_nested_shapes|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_priv__twoLabels', 3, 93}.
  {label, 92}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_priv__twoLabels'}, 3}.
  {label, 93}.
    {call_only, 3, {f, 5}}.

{function, '__bp_priv__whileUnderLabel', 1, 95}.
  {label, 94}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_priv__whileUnderLabel'}, 1}.
  {label, 95}.
    {call_only, 1, {f, 3}}.

{function, '-whileUnderLabel/1-fun-0-', 2, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '-whileUnderLabel/1-fun-0-'}, 2}.
  {label, 19}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 2}]}.
  {label, 20}.
    {test, is_lt, {f, 21}, [{y, 2}, {integer, 3}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 22}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 22}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 23}}.
  {label, 22}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:11:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 23}.
    {move, {x, 0}, {y, 2}}.
    {test, is_eq_exact, {f, 24}, [{y, 2}, {integer, 2}]}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 24}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 10}], {x, 0}}.
    {test, is_ge, {f, 25}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 25}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:13:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 26}.
    {gc_bif, '+', {f, 0}, 1, [{y, 1}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 27}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 27}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:13:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 28}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {test, is_ge, {f, 29}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 29}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 30}}.
  {label, 29}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:13:28">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 30}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 20}}.
  {label, 21}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1000}], {x, 0}}.
    {test, is_ge, {f, 31}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 31}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 32}}.
  {label, 31}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:15:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 32}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-twoLabels/3-fun-3-', 3, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '-twoLabels/3-fun-3-'}, 3}.
  {label, 41}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_eq_exact, {f, 42}, [{y, 0}, {integer, 2}]}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_label_continue'}, {atom, b}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 43}}.
  {label, 42}.
  {label, 43}.
    {test, is_eq_exact, {f, 44}, [{y, 2}, {integer, 2}]}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_label_continue'}, {atom, a}, {x, 0}]}}.
    {call_ext_only, 1, {extfunc, erlang, throw, 1}}.
    {jump, {f, 45}}.
  {label, 44}.
  {label, 45}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 46}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 46}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 47}}.
  {label, 46}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:27:23">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 47}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-twoLabels/4-fun-2-', 3, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '-twoLabels/4-fun-2-'}, 3}.
  {label, 39}.
    {allocate, 5, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {'try', {y, 3}, {f, 48}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 3}}.
    {jump, {f, 50}}.
  {label, 48}.
    {try_case, {y, 3}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 49}, [{x, 1}, 3, {atom, '__bp_label_continue'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, b}]}.
    {get_tuple_element, {x, 1}, 2, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 49}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 50}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 100}], {x, 0}}.
    {test, is_ge, {f, 51}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 51}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 52}}.
  {label, 51}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:29:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 52}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-twoLabels/3-fun-1-', 4, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '-twoLabels/3-fun-1-'}, 4}.
  {label, 37}.
    {allocate, 6, 4}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {x, 3}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 39}, 0, 0, {x, 0}, {list, [{y, 3}]}}.
    {'try', {y, 5}, {f, 53}}.
    {'try', {y, 4}, {f, 56}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {try_end, {y, 4}}.
    {jump, {f, 58}}.
  {label, 56}.
    {try_case, {y, 4}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 57}, [{x, 1}, 3, {atom, '__bp_label_break'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, b}]}.
    {get_tuple_element, {x, 1}, 2, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 58}.
    {try_end, {y, 5}}.
    {jump, {f, 55}}.
  {label, 53}.
    {try_case, {y, 5}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, throw}]}.
    {test, is_tagged_tuple, {f, 54}, [{x, 1}, 3, {atom, '__bp_label_continue'}]}.
    {get_tuple_element, {x, 1}, 1, {x, 0}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, a}]}.
    {get_tuple_element, {x, 1}, 2, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 54}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.
  {label, 55}.
    {move, {x, 0}, {y, 1}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 1}, {integer, 10000}], {x, 0}}.
    {test, is_ge, {f, 59}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 59}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 60}}.
  {label, 59}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:31:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 60}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '__bp_print', 1, 65}.
  {label, 64}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_print'}, 1}.
  {label, 65}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 69}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 67}}.

{function, '-bp_show_elem-', 1, 71}.
  {label, 70}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 71}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 67}}.

{function, '__bp_show', 2, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_show'}, 2}.
  {label, 67}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 79}, [{x, 0}]}.
    {test, is_eq, {f, 78}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 78}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 79}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 80}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 71}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 80}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 82}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 81}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 81}, [{x, 0}]}.
    {test, is_ne_exact, {f, 81}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 81}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 86}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 87}}.
  {label, 86}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 87}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 67}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 81}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 71}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 84}, [{x, 0}]}.
    {test, is_ne_exact, {f, 84}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 84}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 85}, [{x, 0}, {atom, undefined}]}.
  {label, 83}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 73}, 2}.
  {label, 84}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 85}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 73}.
  {label, 72}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_tagged'}, 2}.
  {label, 73}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 88}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 88}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 88}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 89}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 75}, 3}.
  {label, 89}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 75}.
  {label, 74}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '__bp_render'}, 1}.
  {label, 75}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 90}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 90}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 91}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 77}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_block_jump_label_continue_nested_shapes@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_block_jump_label_continue_nested_shapes@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 77}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 67}}.
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
