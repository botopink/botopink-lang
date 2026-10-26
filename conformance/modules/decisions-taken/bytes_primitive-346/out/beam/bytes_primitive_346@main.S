{module, bytes_primitive_346@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {'__bp_loaded', 2}, {'__bp_load_module', 3}, {'__bp_run', 1}, {'__bp_run_async', 1}, {'__bp_run_none', 0}, {'__bp_run_async_none', 0}, {accepted, 0}, {answers, 0}, {'__bp_comptime_0_at', 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_executor_2', 0}, {'__bp_init_2', 0}, {'__bp_executor_3', 0}, {'__bp_init_3', 0}, {'__bp_executor_4', 0}, {'__bp_init_4', 0}, {'__bp_executor_5', 0}, {'__bp_init_5', 0}, {'__bp_executor_6', 0}, {'__bp_init_6', 0}, {'__bp_executor_7', 0}, {'__bp_init_7', 0}, {'__bp_executor_8', 0}, {'__bp_init_8', 0}, {main, 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_answers', 1}, {'__bp_priv____bp_swap_answers', 1}, {'__bp_priv____bp_tab_answers', 0}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 283}.

{function, '__bp_loaded', 2, 3}.
  {label, 2}.
    {line, [{location, "bytes_primitive_346@main.erl", 1}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_loaded'}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 80}, [{integer, 0}, {x, 0}]}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 80}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_load_module', 3, 5}.
  {label, 4}.
    {line, [{location, "bytes_primitive_346@main.erl", 2}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_load_module'}, 3}.
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
    {line, [{location, "bytes_primitive_346@main.erl", 3}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_run'}, 1}.
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
    {call, 3, {f, 90}}.
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
    {test, is_eq, {f, 92}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {atom, true}, {x, 0}}.
  {label, 93}.
    {test, is_eq, {f, 91}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 90}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 91}.
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
    {test, is_tagged_tuple, {f, 94}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 96}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 81}}.
  {label, 94}.
    {case_end, {x, 0}}.
  {label, 81}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

%% @Async — eager lowering
{function, '__bp_run_async', 1, 9}.
  {label, 8}.
    {line, [{location, "bytes_primitive_346@main.erl", 4}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_run_async'}, 1}.
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
    {test, is_tagged_tuple, {f, 102}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 104}, [{x, 0}, 2, {atom, ok}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 103}}.
  {label, 104}.
    {test, is_tagged_tuple, {f, 105}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {literal, <<"\0bp-off:X">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 107}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 108}}.
  {label, 107}.
    {move, {atom, true}, {x, 0}}.
  {label, 108}.
    {test, is_eq, {f, 106}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__excluded}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 90}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 6}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 106}.
    {move, {literal, <<"\0bp-off:R">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 110}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {atom, true}, {x, 0}}.
  {label, 111}.
    {test, is_eq, {f, 109}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 90}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 109}.
    {move, {atom, std@compiler@@RunFailureKind__v__failed}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {x, 0}, {y, 5}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 105}.
    {case_end, {x, 0}}.
  {label, 103}.
    {jump, {f, 101}}.
  {label, 102}.
    {test, is_tagged_tuple, {f, 112}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 96}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 101}}.
  {label, 112}.
    {case_end, {x, 0}}.
  {label, 101}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_run_none', 0, 11}.
  {label, 10}.
    {line, [{location, "bytes_primitive_346@main.erl", 5}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_run_none'}, 0}.
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
    {line, [{location, "bytes_primitive_346@main.erl", 6}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_run_async_none'}, 0}.
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
    {line, [{location, "bytes_primitive_346@main.erl", 7}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, accepted}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 2\n== bytes_interpolated\nrefused error: `bytes` is no text to join with `+` or a string template\nat src/main.bp:8:18\n== bytes_ordering\nrefused error: `bytes` takes no `<`\nat src/main.bp:9:11\n== bytes_plus_string\nrefused error: `bytes` is no text to join with `+` or a string template\nat src/main.bp:8:19\n== bytes_string_literal\nrefused error: type mismatch: expected bytes, got string\nat src/main.bp:9:20\n== bytes_type_test\nrefused error: bytes-type-test: `is` does not test `bytes`\nat src/main.bp:7:14\n== bytes_unknown_associated_fn\nrefused error: `bytes` has no associated function `fromText`\nat src/main.bp:7:19\n== bytes_where_string_expected\nrefused error: type mismatch: expected string, got bytes\nat src/main.bp:12:17\n== bytes_widened_to_unknown\nrefused error: bytes-widened: `bytes` does not widen to `unknown`\nat src/main.bp:8:11\n== bytes_encoding_bridges\nout aGk=\nout 6869\nout 4\nout AP+Aww==\nout bytes 00ff80c3\nout bytes 00ff80c3\nout bytes 6869\nout error NotBase64\nout error NotBase64\nout bytes \nout bytes 00ffab\nout error NotHex\nout error NotHex\nout true\nout true\n">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% What each case answered, in the order the cases ran.

    %% var answers — beamMemory(.Ets)
{function, answers, 0, 17}.
  {label, 16}.
    {line, [{location, "bytes_primitive_346@main.erl", 8}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, answers}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 75}}.
    {move, {atom, bytes_primitive_346@main@@answers}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_answers', 0, 75}.
  {label, 74}.
    {line, [{location, "bytes_primitive_346@main.erl", 9}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_tab_answers'}, 0}.
  {label, 75}.
    {allocate, 0, 0}.
    {move, {atom, bytes_primitive_346@main@@answers}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, bytes_primitive_346@main@@answers}, {x, 0}}.
    {call_last, 2, {f, 69}, 0}.
  {label, 113}.
    {move, {atom, bytes_primitive_346@main@@answers}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_answers', 1, 77}.
  {label, 76}.
    {line, [{location, "bytes_primitive_346@main.erl", 10}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_set_answers'}, 1}.
  {label, 77}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 75}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, bytes_primitive_346@main@@answers}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_answers', 1, 79}.
  {label, 78}.
    {line, [{location, "bytes_primitive_346@main.erl", 11}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_swap_answers'}, 1}.
  {label, 79}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 75}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@beam, etsSwap, 2}, 1}.
%% One case, expanded where it is called (decision 808 (2)): a refused load answers its
%% diagnostics, a loaded one runs and answers its output.

{function, '__bp_comptime_0_at', 0, 19}.
  {label, 18}.
    {line, [{location, "bytes_primitive_346@main.erl", 12}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_comptime_0_at'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 21}.
  {label, 20}.
    {line, [{location, "bytes_primitive_346@main.erl", 13}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 21}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_interpolated">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_interpolated">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` is no text to join with `+` or a string template">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 18}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 122}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 122}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 115}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 124}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_0', 0, 23}.
  {label, 22}.
    {line, [{location, "bytes_primitive_346@main.erl", 14}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_0'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 126}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 126}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_1', 0, 25}.
  {label, 24}.
    {line, [{location, "bytes_primitive_346@main.erl", 15}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 25}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_ordering">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_ordering">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` takes no `<`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 9}, {integer, 11}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 135}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 135}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 128}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 137}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_1', 0, 27}.
  {label, 26}.
    {line, [{location, "bytes_primitive_346@main.erl", 16}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_1'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 139}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 139}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_2', 0, 29}.
  {label, 28}.
    {line, [{location, "bytes_primitive_346@main.erl", 17}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_2'}, 0}.
  {label, 29}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_plus_string">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_plus_string">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` is no text to join with `+` or a string template">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 19}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 148}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 148}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 141}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 150}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_2', 0, 31}.
  {label, 30}.
    {line, [{location, "bytes_primitive_346@main.erl", 18}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_2'}, 0}.
  {label, 31}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_2'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 152}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 29}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 152}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_3', 0, 33}.
  {label, 32}.
    {line, [{location, "bytes_primitive_346@main.erl", 19}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_3'}, 0}.
  {label, 33}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_string_literal">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_string_literal">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"type mismatch: expected bytes, got string">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 9}, {integer, 20}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 161}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 161}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 154}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 163}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_3', 0, 35}.
  {label, 34}.
    {line, [{location, "bytes_primitive_346@main.erl", 20}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_3'}, 0}.
  {label, 35}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_3'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 165}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 33}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 165}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_4', 0, 37}.
  {label, 36}.
    {line, [{location, "bytes_primitive_346@main.erl", 21}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_4'}, 0}.
  {label, 37}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_type_test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_type_test">>}, {x, 0}}.
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
    {move, {literal, <<"bytes-type-test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bytes-type-test: `is` does not test `bytes`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 14}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 174}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 174}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 167}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 176}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_4', 0, 39}.
  {label, 38}.
    {line, [{location, "bytes_primitive_346@main.erl", 22}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_4'}, 0}.
  {label, 39}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_4'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 178}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 37}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_4'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 178}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_5', 0, 41}.
  {label, 40}.
    {line, [{location, "bytes_primitive_346@main.erl", 23}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_5'}, 0}.
  {label, 41}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_unknown_associated_fn">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_unknown_associated_fn">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` has no associated function `fromText`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 19}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 187}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 187}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 180}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 189}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_5', 0, 43}.
  {label, 42}.
    {line, [{location, "bytes_primitive_346@main.erl", 24}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_5'}, 0}.
  {label, 43}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_5'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 191}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 41}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_5'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 191}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_6', 0, 45}.
  {label, 44}.
    {line, [{location, "bytes_primitive_346@main.erl", 25}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_6'}, 0}.
  {label, 45}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_where_string_expected">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_where_string_expected">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"type mismatch: expected string, got bytes">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 12}, {integer, 17}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 200}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 200}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 193}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 202}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_6', 0, 47}.
  {label, 46}.
    {line, [{location, "bytes_primitive_346@main.erl", 26}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_6'}, 0}.
  {label, 47}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_6'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 204}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 45}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_6'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 204}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_7', 0, 49}.
  {label, 48}.
    {line, [{location, "bytes_primitive_346@main.erl", 27}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_7'}, 0}.
  {label, 49}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bytes_widened_to_unknown">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_widened_to_unknown">>}, {x, 0}}.
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
    {move, {literal, <<"bytes-widened">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bytes-widened: `bytes` does not widen to `unknown`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 11}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 213}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 213}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 206}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 215}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_7', 0, 51}.
  {label, 50}.
    {line, [{location, "bytes_primitive_346@main.erl", 28}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_7'}, 0}.
  {label, 51}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_7'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 217}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 49}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_7'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 217}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_8', 0, 53}.
  {label, 52}.
    {line, [{location, "bytes_primitive_346@main.erl", 29}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_executor_8'}, 0}.
  {label, 53}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_bytes_encoding_bridges@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 219}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_8', 0, 55}.
  {label, 54}.
    {line, [{location, "bytes_primitive_346@main.erl", 30}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_init_8'}, 0}.
  {label, 55}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_8'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 220}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 53}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bytes_primitive_346@main, '__bp_init_8'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 220}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, main, 0, 57}.
  {label, 56}.
    {line, [{location, "bytes_primitive_346@main.erl", 31}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, main}, 0}.
  {label, 57}.
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

{function, '_botopink_main', 0, 59}.
  {label, 58}.
    {line, [{location, "bytes_primitive_346@main.erl", 32}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '_botopink_main'}, 0}.
  {label, 59}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 63}}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 35}}.
    {call, 0, {f, 39}}.
    {call, 0, {f, 43}}.
    {call, 0, {f, 47}}.
    {call, 0, {f, 51}}.
    {call, 0, {f, 55}}.
    {call_last, 0, {f, 57}, 0}.

{function, main, 1, 61}.
  {label, 60}.
    {line, [{location, "bytes_primitive_346@main.erl", 33}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, main}, 1}.
  {label, 61}.
    {call_only, 0, {f, 59}}.

{function, '__bp_load_siblings', 0, 63}.
  {label, 62}.
    {line, [{location, "bytes_primitive_346@main.erl", 34}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 63}.
    {allocate, 0, 0}.
    {move, {atom, bytes_primitive_346@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 221}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 65}, 0}.
  {label, 221}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 65}.
  {label, 64}.
    {line, [{location, "bytes_primitive_346@main.erl", 35}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 65}.
    {test, is_nonempty_list, {f, 222}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 223}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 225}}.
  {label, 223}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 224}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 225}}.
  {label, 224}.
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
  {label, 225}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 65}, 2}.
  {label, 222}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '_botopink_init', 0, 67}.
  {label, 66}.
    {line, [{location, "bytes_primitive_346@main.erl", 36}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '_botopink_init'}, 0}.
  {label, 67}.
    {allocate, 0, 0}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 35}}.
    {call, 0, {f, 39}}.
    {call, 0, {f, 43}}.
    {call, 0, {f, 47}}.
    {call, 0, {f, 51}}.
    {call, 0, {f, 55}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_ets', 2, 69}.
  {label, 68}.
    {line, [{location, "bytes_primitive_346@main.erl", 37}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_ets'}, 2}.
  {label, 69}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 226}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 71}, 2}.
  {label, 226}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 71}.
  {label, 70}.
    {line, [{location, "bytes_primitive_346@main.erl", 38}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 71}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 227}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 228}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 228}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 230}}.
  {label, 228}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 229}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, bytes_primitive_346@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 230}}.
  {label, 229}.
    {move, {y, 2}, {y, 3}}.
  {label, 230}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 71}, 4}.
  {label, 227}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 73}.
  {label, 72}.
    {line, [{location, "bytes_primitive_346@main.erl", 39}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 73}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 231}}.
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
  {label, 231}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 232}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 232}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 232}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, 'string_slice', 3, 90}.
  {label, 89}.
    {line, [{location, "bytes_primitive_346@main.erl", 40}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, 'string_slice'}, 3}.
  {label, 90}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 233}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 235}, 3}.
  {label, 233}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 257}, 3}.

{function, '__bp_priv____bp_ets', 2, 274}.
  {label, 273}.
    {line, [{location, "bytes_primitive_346@main.erl", 41}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 274}.
    {call_only, 2, {f, 69}}.

{function, '__bp_priv____bp_set_answers', 1, 276}.
  {label, 275}.
    {line, [{location, "bytes_primitive_346@main.erl", 42}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_priv____bp_set_answers'}, 1}.
  {label, 276}.
    {call_only, 1, {f, 77}}.

{function, '__bp_priv____bp_swap_answers', 1, 278}.
  {label, 277}.
    {line, [{location, "bytes_primitive_346@main.erl", 43}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_priv____bp_swap_answers'}, 1}.
  {label, 278}.
    {call_only, 1, {f, 79}}.

{function, '__bp_priv____bp_tab_answers', 0, 280}.
  {label, 279}.
    {line, [{location, "bytes_primitive_346@main.erl", 44}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_priv____bp_tab_answers'}, 0}.
  {label, 280}.
    {call_only, 0, {f, 75}}.

{function, '__bp_priv__string_slice', 3, 282}.
  {label, 281}.
    {line, [{location, "bytes_primitive_346@main.erl", 45}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 282}.
    {call_only, 3, {f, 90}}.

{function, '-bp_field-', 2, 96}.
  {label, 95}.
    {line, [{location, "bytes_primitive_346@main.erl", 4}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-bp_field-'}, 2}.
  {label, 96}.
    {test, is_map, {f, 97}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 97}.
    {test, is_tuple, {f, 98}, [{x, 0}]}.
    {bif, element, {f, 100}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 100}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 98}.
    {test, is_eq_exact, {f, 100}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 99}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 99}.
    {test, is_binary, {f, 100}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 100}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '-__bp_executor_0/0-fun-0-', 2, 115}.
  {label, 114}.
    {line, [{location, "bytes_primitive_346@main.erl", 14}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_0/0-fun-0-'}, 2}.
  {label, 115}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 116}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 116}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 117}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 117}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 118}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 118}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 119}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 119}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 120}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 120}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 121}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 121}.
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

{function, '-__bp_executor_0/0-fun-1-', 2, 124}.
  {label, 123}.
    {line, [{location, "bytes_primitive_346@main.erl", 14}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_0/0-fun-1-'}, 2}.
  {label, 124}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_interpolated">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_interpolated">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_interpolated">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` is no text to join with `+` or a string template">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 18}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 125}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 125}.
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

{function, '-__bp_executor_1/0-fun-2-', 2, 128}.
  {label, 127}.
    {line, [{location, "bytes_primitive_346@main.erl", 16}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_1/0-fun-2-'}, 2}.
  {label, 128}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 129}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 129}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 130}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 130}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 131}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 131}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 132}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 133}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 133}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 134}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 134}.
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

{function, '-__bp_executor_1/0-fun-3-', 2, 137}.
  {label, 136}.
    {line, [{location, "bytes_primitive_346@main.erl", 16}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_1/0-fun-3-'}, 2}.
  {label, 137}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_ordering">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_ordering">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_ordering">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` takes no `<`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 9}, {integer, 11}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 138}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 138}.
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

{function, '-__bp_executor_2/0-fun-4-', 2, 141}.
  {label, 140}.
    {line, [{location, "bytes_primitive_346@main.erl", 18}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_2/0-fun-4-'}, 2}.
  {label, 141}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 142}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 142}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 143}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 143}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 144}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 144}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 145}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 145}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 146}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 146}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 147}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 147}.
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

{function, '-__bp_executor_2/0-fun-5-', 2, 150}.
  {label, 149}.
    {line, [{location, "bytes_primitive_346@main.erl", 18}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_2/0-fun-5-'}, 2}.
  {label, 150}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_plus_string">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_plus_string">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_plus_string">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` is no text to join with `+` or a string template">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 19}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 151}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 151}.
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

{function, '-__bp_executor_3/0-fun-6-', 2, 154}.
  {label, 153}.
    {line, [{location, "bytes_primitive_346@main.erl", 20}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_3/0-fun-6-'}, 2}.
  {label, 154}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 155}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 155}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 156}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 156}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 157}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 157}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 158}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 158}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 159}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 159}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 160}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 160}.
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

{function, '-__bp_executor_3/0-fun-7-', 2, 163}.
  {label, 162}.
    {line, [{location, "bytes_primitive_346@main.erl", 20}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_3/0-fun-7-'}, 2}.
  {label, 163}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_string_literal">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_string_literal">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_string_literal">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"type mismatch: expected bytes, got string">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 9}, {integer, 20}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 164}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 164}.
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

{function, '-__bp_executor_4/0-fun-8-', 2, 167}.
  {label, 166}.
    {line, [{location, "bytes_primitive_346@main.erl", 22}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_4/0-fun-8-'}, 2}.
  {label, 167}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 168}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 168}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 169}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 169}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 170}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 170}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 171}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 171}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 172}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 172}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 173}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 173}.
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

{function, '-__bp_executor_4/0-fun-9-', 2, 176}.
  {label, 175}.
    {line, [{location, "bytes_primitive_346@main.erl", 22}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_4/0-fun-9-'}, 2}.
  {label, 176}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_type_test">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_type_test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_type_test">>}, {x, 0}}.
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
    {move, {literal, <<"bytes-type-test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bytes-type-test: `is` does not test `bytes`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 14}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 177}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 177}.
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

{function, '-__bp_executor_5/0-fun-10-', 2, 180}.
  {label, 179}.
    {line, [{location, "bytes_primitive_346@main.erl", 24}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_5/0-fun-10-'}, 2}.
  {label, 180}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 181}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 181}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 182}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 182}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 183}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 183}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 184}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 184}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 185}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 185}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 186}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 186}.
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

{function, '-__bp_executor_5/0-fun-11-', 2, 189}.
  {label, 188}.
    {line, [{location, "bytes_primitive_346@main.erl", 24}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_5/0-fun-11-'}, 2}.
  {label, 189}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_unknown_associated_fn">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_unknown_associated_fn">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_unknown_associated_fn">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"`bytes` has no associated function `fromText`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 19}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 190}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 190}.
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

{function, '-__bp_executor_6/0-fun-12-', 2, 193}.
  {label, 192}.
    {line, [{location, "bytes_primitive_346@main.erl", 26}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_6/0-fun-12-'}, 2}.
  {label, 193}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 194}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 194}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 195}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 195}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 196}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 196}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 197}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 197}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 198}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 198}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 199}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 199}.
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

{function, '-__bp_executor_6/0-fun-13-', 2, 202}.
  {label, 201}.
    {line, [{location, "bytes_primitive_346@main.erl", 26}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_6/0-fun-13-'}, 2}.
  {label, 202}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_where_string_expected">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_where_string_expected">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_where_string_expected">>}, {x, 0}}.
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
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"type mismatch: expected string, got bytes">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 12}, {integer, 17}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 203}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 203}.
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

{function, '-__bp_executor_7/0-fun-14-', 2, 206}.
  {label, 205}.
    {line, [{location, "bytes_primitive_346@main.erl", 28}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_7/0-fun-14-'}, 2}.
  {label, 206}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 207}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 207}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 208}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 208}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 209}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 209}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 210}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 210}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 211}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 211}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 212}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 212}.
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

{function, '-__bp_executor_7/0-fun-15-', 2, 215}.
  {label, 214}.
    {line, [{location, "bytes_primitive_346@main.erl", 28}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_7/0-fun-15-'}, 2}.
  {label, 215}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_widened_to_unknown">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_widened_to_unknown">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_widened_to_unknown">>}, {x, 0}}.
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
    {move, {literal, <<"bytes-widened">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bytes-widened: `bytes` does not widen to `unknown`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 11}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 216}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 216}.
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

{function, '-__bp_executor_8/0-fun-16-', 2, 219}.
  {label, 218}.
    {line, [{location, "bytes_primitive_346@main.erl", 30}]}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '-__bp_executor_8/0-fun-16-'}, 2}.
  {label, 219}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bytes_encoding_bridges">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bytes_encoding_bridges">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bytes_encoding_bridges">>}, {x, 0}}.
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
    {call, 2, {f, 96}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 96}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 96}}.
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

{function, '__bp_tpl_0-t/3-fun-0-', 3, 239}.
  {label, 238}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_tpl_0-t/3-fun-0-'}, 3}.
  {label, 239}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 243}}.
  {label, 243}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 245}}.
  {label, 245}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 247}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 246}}.
  {label, 247}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 248}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 246}}.
  {label, 248}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 246}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 250}}.
  {label, 250}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 252}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 251}}.
  {label, 252}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 253}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 251}}.
  {label, 253}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 251}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 255}}.
  {label, 255}.
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

{function, '__bp_tpl_0', 3, 235}.
  {label, 234}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_tpl_0'}, 3}.
  {label, 235}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 239}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 261}.
  {label, 260}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 261}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 265}}.
  {label, 265}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 267}}.
  {label, 267}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 269}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 268}}.
  {label, 269}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 270}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 268}}.
  {label, 270}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 268}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 272}}.
  {label, 272}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_1', 2, 257}.
  {label, 256}.
    {func_info, {atom, bytes_primitive_346@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 257}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 261}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
