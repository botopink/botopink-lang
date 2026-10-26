{module, compiler_same_compares_declaration_handles_666@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {'__bp_loaded', 2}, {'__bp_load_module', 3}, {'__bp_run', 1}, {'__bp_run_async', 1}, {'__bp_run_none', 0}, {'__bp_run_async_none', 0}, {accepted, 0}, {answers, 0}, {'__bp_comptime_0_at', 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_executor_2', 0}, {'__bp_init_2', 0}, {'__bp_executor_3', 0}, {'__bp_init_3', 0}, {'__bp_executor_4', 0}, {'__bp_init_4', 0}, {'__bp_executor_5', 0}, {'__bp_init_5', 0}, {main, 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_answers', 1}, {'__bp_priv____bp_swap_answers', 1}, {'__bp_priv____bp_tab_answers', 0}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 212}.

{function, '__bp_loaded', 2, 3}.
  {label, 2}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 1}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_loaded'}, 2}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 2}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_load_module'}, 3}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 3}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_run'}, 1}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 4}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_run_async'}, 1}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 5}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_run_none'}, 0}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 6}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_run_async_none'}, 0}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 7}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, accepted}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 2\n== decorator_argument_decorator_alias\nout email\nout lowercased\nout 2\n== decorator_argument_decorator_name\nout email\nout lowercased\nout 2\n== decorator_same_not_decorator\nrefused error: type mismatch: expected Decorator, got string\nat src/main.bp:16:34\n== typeinfo_all_with_number\nrefused error: type mismatch: expected Decorator | Decorator[], got i32\nat src/main.bp:8:31\n== typeinfo_all_with_ordinary_fn\nrefused error: type mismatch: expected Decorator | Decorator[], got function\nat src/main.bp:12:31\n== typeinfo_all_decorator_argument\nout 1\nout sweep\nout home,sweep\n">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% What each case answered, in the order the cases ran.

    %% var answers — beamMemory(.Ets)
{function, answers, 0, 17}.
  {label, 16}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 8}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, answers}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 63}}.
    {move, {atom, compiler_same_compares_declaration_handles_666@main@@answers}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_answers', 0, 63}.
  {label, 62}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 9}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_tab_answers'}, 0}.
  {label, 63}.
    {allocate, 0, 0}.
    {move, {atom, compiler_same_compares_declaration_handles_666@main@@answers}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, compiler_same_compares_declaration_handles_666@main@@answers}, {x, 0}}.
    {call_last, 2, {f, 57}, 0}.
  {label, 101}.
    {move, {atom, compiler_same_compares_declaration_handles_666@main@@answers}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_answers', 1, 65}.
  {label, 64}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 10}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_set_answers'}, 1}.
  {label, 65}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 63}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, compiler_same_compares_declaration_handles_666@main@@answers}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_answers', 1, 67}.
  {label, 66}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 11}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_swap_answers'}, 1}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 12}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_comptime_0_at'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 21}.
  {label, 20}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 13}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 21}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_decorator_argument_decorator_alias@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 103}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_0', 0, 23}.
  {label, 22}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 14}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_init_0'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 104}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 104}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_1', 0, 25}.
  {label, 24}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 15}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 25}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_decorator_argument_decorator_name@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 106}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_1', 0, 27}.
  {label, 26}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 16}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_init_1'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 107}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 107}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_2', 0, 29}.
  {label, 28}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 17}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_executor_2'}, 0}.
  {label, 29}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"decorator_same_not_decorator">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/decorator_same_not_decorator">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected Decorator, got string">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 16}, {integer, 34}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 116}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 116}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 109}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 118}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_2', 0, 31}.
  {label, 30}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 18}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_init_2'}, 0}.
  {label, 31}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_2'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 29}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 120}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_3', 0, 33}.
  {label, 32}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 19}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_executor_3'}, 0}.
  {label, 33}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"typeinfo_all_with_number">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/typeinfo_all_with_number">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected Decorator | Decorator[], got i32">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 31}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 129}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 129}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 122}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 131}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_3', 0, 35}.
  {label, 34}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 20}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_init_3'}, 0}.
  {label, 35}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_3'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 33}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 133}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_4', 0, 37}.
  {label, 36}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 21}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_executor_4'}, 0}.
  {label, 37}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"typeinfo_all_with_ordinary_fn">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/typeinfo_all_with_ordinary_fn">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected Decorator | Decorator[], got function">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 12}, {integer, 31}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 142}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 142}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 135}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 144}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_4', 0, 39}.
  {label, 38}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 22}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_init_4'}, 0}.
  {label, 39}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_4'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 146}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 37}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_4'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 146}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_5', 0, 41}.
  {label, 40}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 23}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_executor_5'}, 0}.
  {label, 41}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_typeinfo_all_decorator_argument@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 148}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 67}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_5', 0, 43}.
  {label, 42}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 24}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_init_5'}, 0}.
  {label, 43}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_5'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 149}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 41}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {compiler_same_compares_declaration_handles_666@main, '__bp_init_5'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 149}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, main, 0, 45}.
  {label, 44}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 25}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, main}, 0}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 26}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '_botopink_main'}, 0}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 27}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, main}, 1}.
  {label, 49}.
    {call_only, 0, {f, 47}}.

{function, '__bp_load_siblings', 0, 51}.
  {label, 50}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 28}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 51}.
    {allocate, 0, 0}.
    {move, {atom, compiler_same_compares_declaration_handles_666@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 150}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 53}, 0}.
  {label, 150}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 53}.
  {label, 52}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 29}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 53}.
    {test, is_nonempty_list, {f, 151}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 152}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 154}}.
  {label, 152}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 153}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 154}}.
  {label, 153}.
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
  {label, 154}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 53}, 2}.
  {label, 151}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '_botopink_init', 0, 55}.
  {label, 54}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 30}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '_botopink_init'}, 0}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 31}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_ets'}, 2}.
  {label, 57}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 155}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 59}, 2}.
  {label, 155}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 59}.
  {label, 58}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 32}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 59}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 156}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 157}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 157}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 159}}.
  {label, 157}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 158}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, compiler_same_compares_declaration_handles_666@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 159}}.
  {label, 158}.
    {move, {y, 2}, {y, 3}}.
  {label, 159}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 59}, 4}.
  {label, 156}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 61}.
  {label, 60}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 33}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 61}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 160}}.
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
  {label, 160}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 161}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 161}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 161}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, 'string_slice', 3, 78}.
  {label, 77}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 34}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, 'string_slice'}, 3}.
  {label, 78}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 162}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 164}, 3}.
  {label, 162}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 186}, 3}.

{function, '__bp_priv____bp_ets', 2, 203}.
  {label, 202}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 35}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 203}.
    {call_only, 2, {f, 57}}.

{function, '__bp_priv____bp_set_answers', 1, 205}.
  {label, 204}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 36}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_priv____bp_set_answers'}, 1}.
  {label, 205}.
    {call_only, 1, {f, 65}}.

{function, '__bp_priv____bp_swap_answers', 1, 207}.
  {label, 206}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 37}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_priv____bp_swap_answers'}, 1}.
  {label, 207}.
    {call_only, 1, {f, 67}}.

{function, '__bp_priv____bp_tab_answers', 0, 209}.
  {label, 208}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 38}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_priv____bp_tab_answers'}, 0}.
  {label, 209}.
    {call_only, 0, {f, 63}}.

{function, '__bp_priv__string_slice', 3, 211}.
  {label, 210}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 39}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 211}.
    {call_only, 3, {f, 78}}.

{function, '-bp_field-', 2, 84}.
  {label, 83}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 4}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-bp_field-'}, 2}.
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
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 14}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_0/0-fun-0-'}, 2}.
  {label, 103}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"decorator_argument_decorator_alias">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"decorator_argument_decorator_alias">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/decorator_argument_decorator_alias">>}, {x, 0}}.
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
    {call, 2, {f, 84}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 84}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 84}}.
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

{function, '-__bp_executor_1/0-fun-1-', 2, 106}.
  {label, 105}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 16}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_1/0-fun-1-'}, 2}.
  {label, 106}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"decorator_argument_decorator_name">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"decorator_argument_decorator_name">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/decorator_argument_decorator_name">>}, {x, 0}}.
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
    {call, 2, {f, 84}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 84}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 84}}.
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

{function, '-__bp_executor_2/0-fun-2-', 2, 109}.
  {label, 108}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 18}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_2/0-fun-2-'}, 2}.
  {label, 109}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 110}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 110}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 111}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 111}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 112}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 112}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 113}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 113}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 114}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 114}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 115}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 115}.
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

{function, '-__bp_executor_2/0-fun-3-', 2, 118}.
  {label, 117}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 18}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_2/0-fun-3-'}, 2}.
  {label, 118}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"decorator_same_not_decorator">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"decorator_same_not_decorator">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/decorator_same_not_decorator">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected Decorator, got string">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 16}, {integer, 34}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 119}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 119}.
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

{function, '-__bp_executor_3/0-fun-4-', 2, 122}.
  {label, 121}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 20}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_3/0-fun-4-'}, 2}.
  {label, 122}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 123}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 123}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 124}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 124}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 125}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 125}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 126}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 126}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 127}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 127}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 128}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 128}.
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

{function, '-__bp_executor_3/0-fun-5-', 2, 131}.
  {label, 130}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 20}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_3/0-fun-5-'}, 2}.
  {label, 131}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"typeinfo_all_with_number">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"typeinfo_all_with_number">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/typeinfo_all_with_number">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected Decorator | Decorator[], got i32">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 31}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 132}.
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

{function, '-__bp_executor_4/0-fun-6-', 2, 135}.
  {label, 134}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 22}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_4/0-fun-6-'}, 2}.
  {label, 135}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 136}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 136}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 137}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 137}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 138}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 138}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 139}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 140}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 140}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 141}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 141}.
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

{function, '-__bp_executor_4/0-fun-7-', 2, 144}.
  {label, 143}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 22}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_4/0-fun-7-'}, 2}.
  {label, 144}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"typeinfo_all_with_ordinary_fn">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"typeinfo_all_with_ordinary_fn">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/typeinfo_all_with_ordinary_fn">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected Decorator | Decorator[], got function">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 12}, {integer, 31}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 145}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 145}.
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

{function, '-__bp_executor_5/0-fun-8-', 2, 148}.
  {label, 147}.
    {line, [{location, "compiler_same_compares_declaration_handles_666@main.erl", 24}]}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '-__bp_executor_5/0-fun-8-'}, 2}.
  {label, 148}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"typeinfo_all_decorator_argument">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"typeinfo_all_decorator_argument">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/typeinfo_all_decorator_argument">>}, {x, 0}}.
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
    {call, 2, {f, 84}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 84}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 84}}.
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

{function, '__bp_tpl_0-t/3-fun-0-', 3, 168}.
  {label, 167}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_tpl_0-t/3-fun-0-'}, 3}.
  {label, 168}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 172}}.
  {label, 172}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 174}}.
  {label, 174}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 176}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 175}}.
  {label, 176}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 177}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 175}}.
  {label, 177}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 175}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 179}}.
  {label, 179}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 181}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 180}}.
  {label, 181}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 182}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 180}}.
  {label, 182}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 180}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 184}}.
  {label, 184}.
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

{function, '__bp_tpl_0', 3, 164}.
  {label, 163}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_tpl_0'}, 3}.
  {label, 164}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 168}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 190}.
  {label, 189}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 190}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 194}}.
  {label, 194}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 196}}.
  {label, 196}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 198}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 197}}.
  {label, 198}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 199}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 197}}.
  {label, 199}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 197}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 201}}.
  {label, 201}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_1', 2, 186}.
  {label, 185}.
    {func_info, {atom, compiler_same_compares_declaration_handles_666@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 186}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 190}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
