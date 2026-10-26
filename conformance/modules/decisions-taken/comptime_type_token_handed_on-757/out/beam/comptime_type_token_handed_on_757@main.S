{module, comptime_type_token_handed_on_757@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {'__bp_loaded', 2}, {'__bp_load_module', 3}, {'__bp_run', 1}, {'__bp_run_async', 1}, {'__bp_run_none', 0}, {'__bp_run_async_none', 0}, {accepted, 0}, {answers, 0}, {'__bp_comptime_0_at', 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_executor_2', 0}, {'__bp_init_2', 0}, {'__bp_executor_3', 0}, {'__bp_init_3', 0}, {main, 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_answers', 1}, {'__bp_priv____bp_swap_answers', 1}, {'__bp_priv____bp_tab_answers', 0}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 168}.

{function, '__bp_loaded', 2, 3}.
  {label, 2}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 1}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_loaded'}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 60}, [{integer, 0}, {x, 0}]}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_load_module', 3, 5}.
  {label, 4}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 2}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_load_module'}, 3}.
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
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 3}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_run'}, 1}.
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
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 64}, [{x, 0}, 2, {atom, ok}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 63}}.
  {label, 64}.
    {test, is_tagged_tuple, {f, 65}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {literal, <<"\0bp-off:X">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 67}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 68}}.
  {label, 67}.
    {move, {atom, true}, {x, 0}}.
  {label, 68}.
    {test, is_eq, {f, 66}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__excluded}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 70}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 6}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 66}.
    {move, {literal, <<"\0bp-off:R">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 72}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, true}, {x, 0}}.
  {label, 73}.
    {test, is_eq, {f, 71}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 70}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 71}.
    {move, {atom, std@compiler@@RunFailureKind__v__failed}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {x, 0}, {y, 5}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 65}.
    {case_end, {x, 0}}.
  {label, 63}.
    {jump, {f, 61}}.
  {label, 62}.
    {test, is_tagged_tuple, {f, 74}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 76}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 61}}.
  {label, 74}.
    {case_end, {x, 0}}.
  {label, 61}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

%% @Async — eager lowering
{function, '__bp_run_async', 1, 9}.
  {label, 8}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 4}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_run_async'}, 1}.
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
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 84}, [{x, 0}, 2, {atom, ok}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 83}}.
  {label, 84}.
    {test, is_tagged_tuple, {f, 85}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {literal, <<"\0bp-off:X">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 87}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 88}}.
  {label, 87}.
    {move, {atom, true}, {x, 0}}.
  {label, 88}.
    {test, is_eq, {f, 86}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__excluded}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 70}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 6}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 86}.
    {move, {literal, <<"\0bp-off:R">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 90}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 91}}.
  {label, 90}.
    {move, {atom, true}, {x, 0}}.
  {label, 91}.
    {test, is_eq, {f, 89}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 70}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 89}.
    {move, {atom, std@compiler@@RunFailureKind__v__failed}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {x, 0}, {y, 5}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 85}.
    {case_end, {x, 0}}.
  {label, 83}.
    {jump, {f, 81}}.
  {label, 82}.
    {test, is_tagged_tuple, {f, 92}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 76}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 81}}.
  {label, 92}.
    {case_end, {x, 0}}.
  {label, 81}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_run_none', 0, 11}.
  {label, 10}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 5}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_run_none'}, 0}.
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
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 6}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_run_async_none'}, 0}.
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
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 7}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, accepted}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 2\n== is_comptime_type_parameter\nout 2\nout 1\nout false\nout true\n== type_parameter_bound_by_token\nout 42\nout true\nout 8\n== comptime_type_param_of_method\nout 30\nout 10\nout 7\n== comptime_type_token_handed_on\nout 2\nout 9\nout -1\n">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% What each case answered, in the order the cases ran.

    %% var answers — beamMemory(.Ets)
{function, answers, 0, 17}.
  {label, 16}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 8}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, answers}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 55}}.
    {move, {atom, comptime_type_token_handed_on_757@main@@answers}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_answers', 0, 55}.
  {label, 54}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 9}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_tab_answers'}, 0}.
  {label, 55}.
    {allocate, 0, 0}.
    {move, {atom, comptime_type_token_handed_on_757@main@@answers}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, comptime_type_token_handed_on_757@main@@answers}, {x, 0}}.
    {call_last, 2, {f, 49}, 0}.
  {label, 93}.
    {move, {atom, comptime_type_token_handed_on_757@main@@answers}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_answers', 1, 57}.
  {label, 56}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 10}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_set_answers'}, 1}.
  {label, 57}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 55}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, comptime_type_token_handed_on_757@main@@answers}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_answers', 1, 59}.
  {label, 58}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 11}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_swap_answers'}, 1}.
  {label, 59}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 55}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@beam, etsSwap, 2}, 1}.
%% One case, expanded where it is called (decision 808 (2)): a refused load answers its
%% diagnostics, a loaded one runs and answers its output.

{function, '__bp_comptime_0_at', 0, 19}.
  {label, 18}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 12}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_comptime_0_at'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 21}.
  {label, 20}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 13}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 21}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_is_comptime_type_parameter@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 59}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_0', 0, 23}.
  {label, 22}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 14}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_init_0'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 96}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 96}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_1', 0, 25}.
  {label, 24}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 15}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 25}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_type_parameter_bound_by_token@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 98}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 59}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_1', 0, 27}.
  {label, 26}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 16}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_init_1'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 99}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_2', 0, 29}.
  {label, 28}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 17}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_executor_2'}, 0}.
  {label, 29}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_comptime_type_param_of_method@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 101}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 59}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_2', 0, 31}.
  {label, 30}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 18}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_init_2'}, 0}.
  {label, 31}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_2'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 102}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 29}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 102}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_3', 0, 33}.
  {label, 32}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 19}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_executor_3'}, 0}.
  {label, 33}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_comptime_type_token_handed_on@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 104}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 59}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_3', 0, 35}.
  {label, 34}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 20}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_init_3'}, 0}.
  {label, 35}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_3'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 105}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 33}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {comptime_type_token_handed_on_757@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 105}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, main, 0, 37}.
  {label, 36}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 21}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, main}, 0}.
  {label, 37}.
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

{function, '_botopink_main', 0, 39}.
  {label, 38}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 22}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '_botopink_main'}, 0}.
  {label, 39}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 43}}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 35}}.
    {call_last, 0, {f, 37}, 0}.

{function, main, 1, 41}.
  {label, 40}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 23}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, main}, 1}.
  {label, 41}.
    {call_only, 0, {f, 39}}.

{function, '__bp_load_siblings', 0, 43}.
  {label, 42}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 24}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 43}.
    {allocate, 0, 0}.
    {move, {atom, comptime_type_token_handed_on_757@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 106}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 45}, 0}.
  {label, 106}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 45}.
  {label, 44}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 25}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 45}.
    {test, is_nonempty_list, {f, 107}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 108}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 110}}.
  {label, 108}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 109}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 110}}.
  {label, 109}.
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
  {label, 110}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 45}, 2}.
  {label, 107}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '_botopink_init', 0, 47}.
  {label, 46}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 26}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '_botopink_init'}, 0}.
  {label, 47}.
    {allocate, 0, 0}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 35}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_ets', 2, 49}.
  {label, 48}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 27}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_ets'}, 2}.
  {label, 49}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 111}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 51}, 2}.
  {label, 111}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 51}.
  {label, 50}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 28}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 51}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 113}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 115}}.
  {label, 113}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 114}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, comptime_type_token_handed_on_757@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 115}}.
  {label, 114}.
    {move, {y, 2}, {y, 3}}.
  {label, 115}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 51}, 4}.
  {label, 112}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 53}.
  {label, 52}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 29}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 53}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 116}}.
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
  {label, 116}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 117}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 117}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, 'string_slice', 3, 70}.
  {label, 69}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 30}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, 'string_slice'}, 3}.
  {label, 70}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 118}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 120}, 3}.
  {label, 118}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 142}, 3}.

{function, '__bp_priv____bp_ets', 2, 159}.
  {label, 158}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 31}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 159}.
    {call_only, 2, {f, 49}}.

{function, '__bp_priv____bp_set_answers', 1, 161}.
  {label, 160}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 32}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_priv____bp_set_answers'}, 1}.
  {label, 161}.
    {call_only, 1, {f, 57}}.

{function, '__bp_priv____bp_swap_answers', 1, 163}.
  {label, 162}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 33}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_priv____bp_swap_answers'}, 1}.
  {label, 163}.
    {call_only, 1, {f, 59}}.

{function, '__bp_priv____bp_tab_answers', 0, 165}.
  {label, 164}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 34}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_priv____bp_tab_answers'}, 0}.
  {label, 165}.
    {call_only, 0, {f, 55}}.

{function, '__bp_priv__string_slice', 3, 167}.
  {label, 166}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 35}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 167}.
    {call_only, 3, {f, 70}}.

{function, '-bp_field-', 2, 76}.
  {label, 75}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 4}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '-bp_field-'}, 2}.
  {label, 76}.
    {test, is_map, {f, 77}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 77}.
    {test, is_tuple, {f, 78}, [{x, 0}]}.
    {bif, element, {f, 80}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 80}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 78}.
    {test, is_eq_exact, {f, 80}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 79}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 79}.
    {test, is_binary, {f, 80}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 80}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '-__bp_executor_0/0-fun-0-', 2, 95}.
  {label, 94}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 14}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '-__bp_executor_0/0-fun-0-'}, 2}.
  {label, 95}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"is_comptime_type_parameter">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"is_comptime_type_parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/is_comptime_type_parameter">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, printed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 5, {extfunc, conformance_lib@observe, ranAnswer, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 9}.
    return.

{function, '-__bp_executor_1/0-fun-1-', 2, 98}.
  {label, 97}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 16}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '-__bp_executor_1/0-fun-1-'}, 2}.
  {label, 98}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"type_parameter_bound_by_token">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"type_parameter_bound_by_token">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/type_parameter_bound_by_token">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, printed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 5, {extfunc, conformance_lib@observe, ranAnswer, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 9}.
    return.

{function, '-__bp_executor_2/0-fun-2-', 2, 101}.
  {label, 100}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 18}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '-__bp_executor_2/0-fun-2-'}, 2}.
  {label, 101}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"comptime_type_param_of_method">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"comptime_type_param_of_method">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/comptime_type_param_of_method">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, printed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 5, {extfunc, conformance_lib@observe, ranAnswer, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 9}.
    return.

{function, '-__bp_executor_3/0-fun-3-', 2, 104}.
  {label, 103}.
    {line, [{location, "comptime_type_token_handed_on_757@main.erl", 20}]}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '-__bp_executor_3/0-fun-3-'}, 2}.
  {label, 104}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"comptime_type_token_handed_on">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"comptime_type_token_handed_on">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/comptime_type_token_handed_on">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 1}, {x, 3}}.
    {move, {x, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 3}, {x, 0}}.
    {call, 3, {f, 5}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, buildOutput, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, printed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 76}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 4}}.
    {move, {y, 5}, {x, 3}}.
    {move, {y, 4}, {x, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 5, {extfunc, conformance_lib@observe, ranAnswer, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {deallocate, 9}.
    return.

{function, '__bp_tpl_0-t/3-fun-0-', 3, 124}.
  {label, 123}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_tpl_0-t/3-fun-0-'}, 3}.
  {label, 124}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 128}}.
  {label, 128}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 130}}.
  {label, 130}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 132}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 131}}.
  {label, 132}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 131}}.
  {label, 133}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 131}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 135}}.
  {label, 135}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 137}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 136}}.
  {label, 137}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 138}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 136}}.
  {label, 138}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 136}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 140}}.
  {label, 140}.
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

{function, '__bp_tpl_0', 3, 120}.
  {label, 119}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_tpl_0'}, 3}.
  {label, 120}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 124}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 146}.
  {label, 145}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 146}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 150}}.
  {label, 150}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 152}}.
  {label, 152}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 153}}.
  {label, 154}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 155}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 153}}.
  {label, 155}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 153}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 157}}.
  {label, 157}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_1', 2, 142}.
  {label, 141}.
    {func_info, {atom, comptime_type_token_handed_on_757@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 142}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 146}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
