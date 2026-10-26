{module, variadic_last_parameter_267@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {'__bp_loaded', 2}, {'__bp_load_module', 3}, {'__bp_run', 1}, {'__bp_run_async', 1}, {'__bp_run_none', 0}, {'__bp_run_async_none', 0}, {accepted, 0}, {answers, 0}, {'__bp_comptime_0_at', 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_executor_2', 0}, {'__bp_init_2', 0}, {'__bp_executor_3', 0}, {'__bp_init_3', 0}, {'__bp_executor_4', 0}, {'__bp_init_4', 0}, {'__bp_executor_5', 0}, {'__bp_init_5', 0}, {main, 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_answers', 1}, {'__bp_priv____bp_swap_answers', 1}, {'__bp_priv____bp_tab_answers', 0}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 242}.

{function, '__bp_loaded', 2, 3}.
  {label, 2}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 1}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_loaded'}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 68}, [{integer, 0}, {x, 0}]}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 68}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_load_module', 3, 5}.
  {label, 4}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 2}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_load_module'}, 3}.
  {label, 5}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 3, {extfunc, std@compiler@@Module, 'of', 3}, 3}.

{function, '__bp_run', 1, 7}.
  {label, 6}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 3}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_run'}, 1}.
  {label, 7}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, std@compiler@@Module, captureOpen, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@compiler@@Module, captureClose, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 70}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 72}, [{x, 0}, 2, {atom, ok}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 71}}.
  {label, 72}.
    {test, is_tagged_tuple, {f, 73}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {literal, <<"\0bp-off:X">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 75}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 76}}.
  {label, 75}.
    {move, {atom, true}, {x, 0}}.
  {label, 76}.
    {test, is_eq, {f, 74}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__excluded}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 78}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 6}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 74}.
    {move, {literal, <<"\0bp-off:R">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 80}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {atom, true}, {x, 0}}.
  {label, 81}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 78}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 79}.
    {move, {atom, std@compiler@@RunFailureKind__v__failed}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {x, 0}, {y, 5}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 73}.
    {case_end, {x, 0}}.
  {label, 71}.
    {jump, {f, 69}}.
  {label, 70}.
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 84}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 69}}.
  {label, 82}.
    {case_end, {x, 0}}.
  {label, 69}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

%% @Async — eager lowering
{function, '__bp_run_async', 1, 9}.
  {label, 8}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 4}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_run_async'}, 1}.
  {label, 9}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 0}}.
    {call_ext, 0, {extfunc, std@compiler@@Module, captureOpen, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@failure, attemptTask, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@compiler@@Module, captureClose, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_tagged_tuple, {f, 90}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 92}, [{x, 0}, 2, {atom, ok}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 91}}.
  {label, 92}.
    {test, is_tagged_tuple, {f, 93}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {literal, <<"\0bp-off:X">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 95}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {atom, true}, {x, 0}}.
  {label, 96}.
    {test, is_eq, {f, 94}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__excluded}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 78}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 6}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 94}.
    {move, {literal, <<"\0bp-off:R">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 98}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 99}}.
  {label, 98}.
    {move, {atom, true}, {x, 0}}.
  {label, 99}.
    {test, is_eq, {f, 97}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 78}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 97}.
    {move, {atom, std@compiler@@RunFailureKind__v__failed}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {x, 0}, {y, 5}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 93}.
    {case_end, {x, 0}}.
  {label, 91}.
    {jump, {f, 89}}.
  {label, 90}.
    {test, is_tagged_tuple, {f, 100}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 84}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 89}}.
  {label, 100}.
    {case_end, {x, 0}}.
  {label, 89}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_run_none', 0, 11}.
  {label, 10}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 5}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_run_none'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

%% @Async — eager lowering
{function, '__bp_run_async_none', 0, 13}.
  {label, 12}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 6}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_run_async_none'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.
%%% A module checking itself (decision 989): each case is a package under `cases/`, loaded at build,
%%% run in this program and compared with its section of `snapshot/main.snap`; a difference writes
%%% `snapshot/main.snap.new` and `main` answers `Error`. Nothing here accepts a candidate.
%% The snapshot, read as a build input (decision 989 (5)).

{function, accepted, 0, 15}.
  {label, 14}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 7}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, accepted}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 2\n== variadic_default\nrefused error[variadic-default]: a variadic parameter takes no default\nat src/main.bp:6:24\nlabel default on a variadic\n== variadic_label\nrefused error: variadic-label: `values` of `sum` is variadic and takes no label\nat src/main.bp:11:23\n== variadic_not_array\nrefused error[variadic-not-array]: a variadic parameter's type is written as an array `T[]`\nat src/main.bp:7:17\nlabel not `T[]`\n== variadic_not_last\nrefused error[variadic-not-last]: a variadic parameter must be the last parameter\nat src/main.bp:6:10\nlabel variadic before another parameter\n== variadic_spread_at_call\nrefused error: variadic-spread: `sum` is variadic, and a call passes its arguments one by one \x{E2}\x{80}\x{94} there is no spread at a call\nat src/main.bp:13:17\n== variadic_twice\nrefused error[variadic-twice]: a function has at most one variadic parameter\nat src/main.bp:6:21\nlabel a second variadic\n">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% What each case answered, in the order the cases ran.

    %% var answers — beamMemory(.Ets)
{function, answers, 0, 17}.
  {label, 16}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 8}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, answers}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 63}}.
    {move, {atom, variadic_last_parameter_267@main@@answers}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_answers', 0, 63}.
  {label, 62}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 9}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_tab_answers'}, 0}.
  {label, 63}.
    {allocate, 0, 0}.
    {move, {atom, variadic_last_parameter_267@main@@answers}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, variadic_last_parameter_267@main@@answers}, {x, 0}}.
    {call_last, 2, {f, 57}, 0}.
  {label, 101}.
    {move, {atom, variadic_last_parameter_267@main@@answers}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_answers', 1, 65}.
  {label, 64}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 10}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_set_answers'}, 1}.
  {label, 65}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 63}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, variadic_last_parameter_267@main@@answers}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_answers', 1, 67}.
  {label, 66}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 11}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_swap_answers'}, 1}.
  {label, 67}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 63}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@beam, etsSwap, 2}, 1}.
%% One case, expanded where it is called (decision 808 (2)): a refused load answers its
%% diagnostics, a loaded one runs and answers its output.

{function, '__bp_comptime_0_at', 0, 19}.
  {label, 18}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 12}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_comptime_0_at'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 21}.
  {label, 20}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 13}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 21}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"variadic_default">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_default">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic-default">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a variadic parameter takes no default">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"default on a variadic">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 24}, {x, 4}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 110}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 110}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 103}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 112}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_0', 0, 23}.
  {label, 22}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 14}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_init_0'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 114}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 114}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_1', 0, 25}.
  {label, 24}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 15}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 25}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"variadic_label">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_label">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic-label">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"variadic-label: `values` of `sum` is variadic and takes no label">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 23}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 123}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 123}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 116}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 125}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_1', 0, 27}.
  {label, 26}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 16}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_init_1'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 127}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 127}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_2', 0, 29}.
  {label, 28}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 17}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_executor_2'}, 0}.
  {label, 29}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"variadic_not_array">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_not_array">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic-not-array">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a variadic parameter's type is written as an array `T[]`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"not `T[]`">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 17}, {x, 4}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 136}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 136}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 129}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 138}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_2', 0, 31}.
  {label, 30}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 18}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_init_2'}, 0}.
  {label, 31}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_2'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 140}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 29}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 140}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_3', 0, 33}.
  {label, 32}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 19}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_executor_3'}, 0}.
  {label, 33}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"variadic_not_last">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_not_last">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic-not-last">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a variadic parameter must be the last parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"variadic before another parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 10}, {x, 4}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 149}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 149}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 142}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 151}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_3', 0, 35}.
  {label, 34}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 20}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_init_3'}, 0}.
  {label, 35}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_3'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 153}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 33}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 153}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_4', 0, 37}.
  {label, 36}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 21}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_executor_4'}, 0}.
  {label, 37}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"variadic_spread_at_call">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_spread_at_call">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic-spread">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"variadic-spread: `sum` is variadic, and a call passes its arguments one by one \x{E2}\x{80}\x{94} there is no spread at a call">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 13}, {integer, 17}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 162}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 162}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 155}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 164}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_4', 0, 39}.
  {label, 38}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 22}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_init_4'}, 0}.
  {label, 39}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_4'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 166}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 37}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_4'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 166}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_5', 0, 41}.
  {label, 40}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 23}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_executor_5'}, 0}.
  {label, 41}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"variadic_twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic-twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a function has at most one variadic parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"a second variadic">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 21}, {x, 4}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 175}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 175}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 168}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 177}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_5', 0, 43}.
  {label, 42}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 24}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_init_5'}, 0}.
  {label, 43}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_5'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 179}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 41}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {variadic_last_parameter_267@main, '__bp_init_5'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 179}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, main, 0, 45}.
  {label, 44}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 25}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, main}, 0}.
  {label, 45}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {call, 0, {f, 15}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 17}}.
    {move, {x, 0}, {y, 1}}.
    {call_ext, 0, {extfunc, conformance_lib@adapter, target, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 3, {extfunc, conformance_lib@candidate, finish, 3}, 3}.

{function, '_botopink_main', 0, 47}.
  {label, 46}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 26}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '_botopink_main'}, 0}.
  {label, 47}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 51}}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 35}}.
    {call, 0, {f, 39}}.
    {call, 0, {f, 43}}.
    {call_last, 0, {f, 45}, 0}.

{function, main, 1, 49}.
  {label, 48}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 27}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, main}, 1}.
  {label, 49}.
    {call_only, 0, {f, 47}}.

{function, '__bp_load_siblings', 0, 51}.
  {label, 50}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 28}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 51}.
    {allocate, 0, 0}.
    {move, {atom, variadic_last_parameter_267@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 180}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 53}, 0}.
  {label, 180}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 53}.
  {label, 52}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 29}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 53}.
    {test, is_nonempty_list, {f, 181}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 182}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 184}}.
  {label, 182}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 183}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 184}}.
  {label, 183}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 1}}.
    {move, {literal, <<"error: ~ts does not compile - refusing to run~n  ~p~n">>}, {x, 0}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, standard_error}, {x, 0}}.
    {call_ext, 2, {extfunc, file, write, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, halt, 1}}.
  {label, 184}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 53}, 2}.
  {label, 181}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '_botopink_init', 0, 55}.
  {label, 54}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 30}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '_botopink_init'}, 0}.
  {label, 55}.
    {allocate, 0, 0}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 35}}.
    {call, 0, {f, 39}}.
    {call, 0, {f, 43}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_ets', 2, 57}.
  {label, 56}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 31}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_ets'}, 2}.
  {label, 57}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 185}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 59}, 2}.
  {label, 185}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 59}.
  {label, 58}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 32}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 59}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 186}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 187}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 187}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 189}}.
  {label, 187}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 188}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, variadic_last_parameter_267@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 189}}.
  {label, 188}.
    {move, {y, 2}, {y, 3}}.
  {label, 189}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 59}, 4}.
  {label, 186}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 61}.
  {label, 60}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 33}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 61}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 190}}.
    {move, {literal, [named_table, public, set]}, {x, 1}}.
    {call_ext, 2, {extfunc, std@beam, etsNew, 2}}.
    {try_end, {y, 2}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 1}, {list, [{y, 1}, {y, 0}]}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, std@beam, etsPut, 2}}.
    {bif, self, {f, 0}, [], {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, register, 2}}.
    {move, {atom, infinity}, {x, 0}}.
    {call_ext_last, 1, {extfunc, timer, sleep, 1}, 3}.
  {label, 190}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 191}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 191}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, 'string_slice', 3, 78}.
  {label, 77}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 34}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, 'string_slice'}, 3}.
  {label, 78}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 192}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 194}, 3}.
  {label, 192}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 216}, 3}.

{function, '__bp_priv____bp_ets', 2, 233}.
  {label, 232}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 35}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 233}.
    {call_only, 2, {f, 57}}.

{function, '__bp_priv____bp_set_answers', 1, 235}.
  {label, 234}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 36}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_priv____bp_set_answers'}, 1}.
  {label, 235}.
    {call_only, 1, {f, 65}}.

{function, '__bp_priv____bp_swap_answers', 1, 237}.
  {label, 236}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 37}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_priv____bp_swap_answers'}, 1}.
  {label, 237}.
    {call_only, 1, {f, 67}}.

{function, '__bp_priv____bp_tab_answers', 0, 239}.
  {label, 238}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 38}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_priv____bp_tab_answers'}, 0}.
  {label, 239}.
    {call_only, 0, {f, 63}}.

{function, '__bp_priv__string_slice', 3, 241}.
  {label, 240}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 39}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 241}.
    {call_only, 3, {f, 78}}.

{function, '-bp_field-', 2, 84}.
  {label, 83}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 4}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-bp_field-'}, 2}.
  {label, 84}.
    {test, is_map, {f, 85}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 85}.
    {test, is_tuple, {f, 86}, [{x, 0}]}.
    {bif, element, {f, 88}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 88}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 86}.
    {test, is_eq_exact, {f, 88}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 87}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 87}.
    {test, is_binary, {f, 88}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 88}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '-__bp_executor_0/0-fun-0-', 2, 103}.
  {label, 102}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 14}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_0/0-fun-0-'}, 2}.
  {label, 103}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 104}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 104}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 105}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 105}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 106}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 106}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 107}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 107}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 108}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 108}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 109}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 109}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, frames, 1}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 6}}.
    {move, {y, 7}, {x, 5}}.
    {move, {y, 6}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 7, {extfunc, conformance_lib@observe, refusalOf, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '-__bp_executor_0/0-fun-1-', 2, 112}.
  {label, 111}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 14}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_0/0-fun-1-'}, 2}.
  {label, 112}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"variadic_default">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic_default">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_default">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"variadic-default">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a variadic parameter takes no default">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"default on a variadic">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 24}, {x, 4}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 113}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 113}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@observe, refusedAnswer, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 10}.
    return.

{function, '-__bp_executor_1/0-fun-2-', 2, 116}.
  {label, 115}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 16}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_1/0-fun-2-'}, 2}.
  {label, 116}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 117}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 117}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 118}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 118}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 119}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 119}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 120}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 120}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 121}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 121}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 122}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 122}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, frames, 1}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 6}}.
    {move, {y, 7}, {x, 5}}.
    {move, {y, 6}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 7, {extfunc, conformance_lib@observe, refusalOf, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '-__bp_executor_1/0-fun-3-', 2, 125}.
  {label, 124}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 16}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_1/0-fun-3-'}, 2}.
  {label, 125}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"variadic_label">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic_label">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_label">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"variadic-label">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"variadic-label: `values` of `sum` is variadic and takes no label">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 23}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 126}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 126}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@observe, refusedAnswer, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 10}.
    return.

{function, '-__bp_executor_2/0-fun-4-', 2, 129}.
  {label, 128}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 18}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_2/0-fun-4-'}, 2}.
  {label, 129}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 130}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 130}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 131}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 131}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 132}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 133}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 133}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 134}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 134}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 135}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 135}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, frames, 1}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 6}}.
    {move, {y, 7}, {x, 5}}.
    {move, {y, 6}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 7, {extfunc, conformance_lib@observe, refusalOf, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '-__bp_executor_2/0-fun-5-', 2, 138}.
  {label, 137}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 18}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_2/0-fun-5-'}, 2}.
  {label, 138}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"variadic_not_array">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic_not_array">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_not_array">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"variadic-not-array">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a variadic parameter's type is written as an array `T[]`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"not `T[]`">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 17}, {x, 4}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 139}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@observe, refusedAnswer, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 10}.
    return.

{function, '-__bp_executor_3/0-fun-6-', 2, 142}.
  {label, 141}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 20}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_3/0-fun-6-'}, 2}.
  {label, 142}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 143}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 143}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 144}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 144}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 145}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 145}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 146}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 146}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 147}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 147}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 148}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 148}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, frames, 1}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 6}}.
    {move, {y, 7}, {x, 5}}.
    {move, {y, 6}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 7, {extfunc, conformance_lib@observe, refusalOf, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '-__bp_executor_3/0-fun-7-', 2, 151}.
  {label, 150}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 20}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_3/0-fun-7-'}, 2}.
  {label, 151}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"variadic_not_last">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic_not_last">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_not_last">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"variadic-not-last">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a variadic parameter must be the last parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"variadic before another parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 10}, {x, 4}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 152}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 152}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@observe, refusedAnswer, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 10}.
    return.

{function, '-__bp_executor_4/0-fun-8-', 2, 155}.
  {label, 154}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 22}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_4/0-fun-8-'}, 2}.
  {label, 155}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 156}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 156}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 157}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 157}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 158}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 158}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 159}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 159}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 160}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 160}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 161}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 161}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, frames, 1}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 6}}.
    {move, {y, 7}, {x, 5}}.
    {move, {y, 6}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 7, {extfunc, conformance_lib@observe, refusalOf, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '-__bp_executor_4/0-fun-9-', 2, 164}.
  {label, 163}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 22}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_4/0-fun-9-'}, 2}.
  {label, 164}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"variadic_spread_at_call">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic_spread_at_call">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_spread_at_call">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"variadic-spread">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"variadic-spread: `sum` is variadic, and a call passes its arguments one by one \x{E2}\x{80}\x{94} there is no spread at a call">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 13}, {integer, 17}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 165}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 165}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@observe, refusedAnswer, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 10}.
    return.

{function, '-__bp_executor_5/0-fun-10-', 2, 168}.
  {label, 167}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 24}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_5/0-fun-10-'}, 2}.
  {label, 168}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 169}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 169}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 170}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 170}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 171}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 171}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 172}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 172}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 173}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 173}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 174}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 174}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, frames, 1}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 6}}.
    {move, {y, 7}, {x, 5}}.
    {move, {y, 6}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 7, {extfunc, conformance_lib@observe, refusalOf, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 11}.
    return.

{function, '-__bp_executor_5/0-fun-11-', 2, 177}.
  {label, 176}.
    {line, [{location, "variadic_last_parameter_267@main.erl", 24}]}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '-__bp_executor_5/0-fun-11-'}, 2}.
  {label, 177}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"variadic_twice">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"variadic_twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/variadic_twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"variadic-twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a function has at most one variadic parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"a second variadic">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 21}, {x, 4}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 178}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 178}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 3, {extfunc, conformance_lib@observe, refusedAnswer, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 10}.
    return.

{function, '__bp_tpl_0-t/3-fun-0-', 3, 198}.
  {label, 197}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_tpl_0-t/3-fun-0-'}, 3}.
  {label, 198}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 202}}.
  {label, 202}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 204}}.
  {label, 204}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 206}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 205}}.
  {label, 206}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 207}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 205}}.
  {label, 207}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 205}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 209}}.
  {label, 209}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 211}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 210}}.
  {label, 211}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 212}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 210}}.
  {label, 212}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 210}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 214}}.
  {label, 214}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {move, {y, 7}, {x, 2}}.
    {call_ext, 3, {extfunc, lists, sublist, 3}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 9}.

{function, '__bp_tpl_0', 3, 194}.
  {label, 193}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_tpl_0'}, 3}.
  {label, 194}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 198}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 220}.
  {label, 219}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 220}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 224}}.
  {label, 224}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 226}}.
  {label, 226}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 227}}.
  {label, 228}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 227}}.
  {label, 229}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 227}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 231}}.
  {label, 231}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_1', 2, 216}.
  {label, 215}.
    {func_info, {atom, variadic_last_parameter_267@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 216}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 220}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
