{module, bigint_decimal_strict_json_332@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {'__bp_loaded', 2}, {'__bp_load_module', 3}, {'__bp_run', 1}, {'__bp_run_async', 1}, {'__bp_run_none', 0}, {'__bp_run_async_none', 0}, {accepted, 0}, {answers, 0}, {'__bp_comptime_0_at', 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_executor_2', 0}, {'__bp_init_2', 0}, {'__bp_executor_3', 0}, {'__bp_init_3', 0}, {'__bp_executor_4', 0}, {'__bp_init_4', 0}, {'__bp_executor_5', 0}, {'__bp_init_5', 0}, {'__bp_executor_6', 0}, {'__bp_init_6', 0}, {'__bp_executor_7', 0}, {'__bp_init_7', 0}, {'__bp_executor_8', 0}, {'__bp_init_8', 0}, {main, 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_answers', 1}, {'__bp_priv____bp_swap_answers', 1}, {'__bp_priv____bp_tab_answers', 0}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 273}.

{function, '__bp_loaded', 2, 3}.
  {label, 2}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 1}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_loaded'}, 2}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 2}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_load_module'}, 3}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 3}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_run'}, 1}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 4}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_run_async'}, 1}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 5}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_run_none'}, 0}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 6}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_run_async_none'}, 0}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 7}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, accepted}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 2\n== bigint_arithmetic\nout 2535301200456458802993406410752\nout 12193263113702179522618503273386678859448712086533622923332237463801111263526900\nout 90000000009000000000900000000090\nout 11111111101111111110111111111011111111100\nout -3\nout -3\nout -1\nout 1\nout -8\nout -90000000009000000000900000000090\nout true\nout 7\nout 2535301182709350524027\nout 952742563\nout true\nout false\nout true\nout true\nout true\nout 2535301200456458802993406410752\nout 2^101 = 2535301200456458802993406410752\nout 11111111101111111110111111111011111111100\nout -11111111101111111110111111111011111111100\nout 0\nout 9223372036854775808\nout -9223372036854775809\nout -15\nout 12\nout -123456789012345678901234567890\nout 42\nout -1\nout -2\nout -3\nout 4611686018427387905\nout -9223372036854775808\nout 1024.0\nout true\nout 65280\nout 1000000000000\n== bigint_in_containers\nout Ledger(total: 1234567890123456789012345678900, last: null)\nout 1234567890123456789012345678901\nout true\nout false\nout #(3000000000000000000000, \"big\")\nout true\nout [3, 40000000000000000000000]\nout true\nout 40000000000000000000000\nout null\nout 40000000000000000000003\nout 120000000000000000000000\nout 40000000000000000000003\nout true\nout three\nout large\n== bigint_comptime\nrefused error: comptime-bigint: a `bigint` is not computed at compile time yet\nat src/main.bp:6:15\n== bigint_into_i64\nrefused error: type mismatch: expected i64, got bigint\nat src/main.bp:6:18\n== bigint_into_unknown\nrefused error: bigint-widened: a `bigint` does not widen to `unknown`\nat src/main.bp:8:22\n== bigint_literal_fraction\nrefused error[number-suffix-integer-on-float]: a literal with a fraction or an exponent is floating and takes `f` or `d` only\nat src/main.bp:6:16\nlabel an integer suffix\n== bigint_plus_int_literal\nrefused error: the integer literal `1` is not a `bigint` \x{E2}\x{80}\x{94} write `1n`\nat src/main.bp:7:18\n== bigint_type_test\nrefused error: bigint-type-test: `is` does not test a `bigint`\nat src/main.bp:8:13\n== bigint_unsuffixed_literal\nrefused error: the integer literal `2` is not a `bigint` \x{E2}\x{80}\x{94} write `2n`\nat src/main.bp:7:21\n">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% What each case answered, in the order the cases ran.

    %% var answers — beamMemory(.Ets)
{function, answers, 0, 17}.
  {label, 16}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 8}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, answers}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 75}}.
    {move, {atom, bigint_decimal_strict_json_332@main@@answers}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_answers', 0, 75}.
  {label, 74}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 9}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_tab_answers'}, 0}.
  {label, 75}.
    {allocate, 0, 0}.
    {move, {atom, bigint_decimal_strict_json_332@main@@answers}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, bigint_decimal_strict_json_332@main@@answers}, {x, 0}}.
    {call_last, 2, {f, 69}, 0}.
  {label, 113}.
    {move, {atom, bigint_decimal_strict_json_332@main@@answers}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_answers', 1, 77}.
  {label, 76}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 10}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_set_answers'}, 1}.
  {label, 77}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 75}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, bigint_decimal_strict_json_332@main@@answers}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_answers', 1, 79}.
  {label, 78}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 11}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_swap_answers'}, 1}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 12}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_comptime_0_at'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 21}.
  {label, 20}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 13}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 21}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_bigint_arithmetic@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 115}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_0', 0, 23}.
  {label, 22}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 14}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_0'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 116}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 116}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_1', 0, 25}.
  {label, 24}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 15}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 25}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_bigint_in_containers@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 118}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_1', 0, 27}.
  {label, 26}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 16}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_1'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 119}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_2', 0, 29}.
  {label, 28}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 17}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_2'}, 0}.
  {label, 29}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bigint_comptime">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_comptime">>}, {x, 0}}.
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
    {move, {literal, <<"comptime-bigint">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"comptime-bigint: a `bigint` is not computed at compile time yet">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 15}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 128}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 128}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 121}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 130}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_2', 0, 31}.
  {label, 30}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 18}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_2'}, 0}.
  {label, 31}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_2'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 132}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 29}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 132}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_3', 0, 33}.
  {label, 32}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 19}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_3'}, 0}.
  {label, 33}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bigint_into_i64">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_into_i64">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected i64, got bigint">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 18}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 141}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 141}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 134}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 143}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_3', 0, 35}.
  {label, 34}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 20}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_3'}, 0}.
  {label, 35}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_3'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 145}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 33}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 145}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_4', 0, 37}.
  {label, 36}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 21}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_4'}, 0}.
  {label, 37}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bigint_into_unknown">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_into_unknown">>}, {x, 0}}.
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
    {move, {literal, <<"bigint-widened">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bigint-widened: a `bigint` does not widen to `unknown`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 154}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 154}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 147}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 156}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_4', 0, 39}.
  {label, 38}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 22}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_4'}, 0}.
  {label, 39}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_4'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 158}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 37}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_4'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 158}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_5', 0, 41}.
  {label, 40}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 23}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_5'}, 0}.
  {label, 41}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bigint_literal_fraction">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_literal_fraction">>}, {x, 0}}.
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
    {move, {literal, <<"number-suffix-integer-on-float">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a literal with a fraction or an exponent is floating and takes `f` or `d` only">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"an integer suffix">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 16}, {x, 4}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 167}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 167}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 160}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 169}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_5', 0, 43}.
  {label, 42}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 24}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_5'}, 0}.
  {label, 43}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_5'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 171}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 41}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_5'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 171}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_6', 0, 45}.
  {label, 44}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 25}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_6'}, 0}.
  {label, 45}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bigint_plus_int_literal">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_plus_int_literal">>}, {x, 0}}.
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
    {move, {literal, <<"the integer literal `1` is not a `bigint` \x{E2}\x{80}\x{94} write `1n`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 18}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 180}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 180}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 173}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 182}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_6', 0, 47}.
  {label, 46}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 26}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_6'}, 0}.
  {label, 47}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_6'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 184}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 45}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_6'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 184}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_7', 0, 49}.
  {label, 48}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 27}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_7'}, 0}.
  {label, 49}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bigint_type_test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_type_test">>}, {x, 0}}.
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
    {move, {literal, <<"bigint-type-test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bigint-type-test: `is` does not test a `bigint`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 13}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 193}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 193}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 186}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 195}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_7', 0, 51}.
  {label, 50}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 28}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_7'}, 0}.
  {label, 51}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_7'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 197}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 49}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_7'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 197}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_8', 0, 53}.
  {label, 52}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 29}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_executor_8'}, 0}.
  {label, 53}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bigint_unsuffixed_literal">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_unsuffixed_literal">>}, {x, 0}}.
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
    {move, {literal, <<"the integer literal `2` is not a `bigint` \x{E2}\x{80}\x{94} write `2n`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 21}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 206}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 206}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 199}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 208}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 79}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_8', 0, 55}.
  {label, 54}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 30}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_init_8'}, 0}.
  {label, 55}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_8'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 210}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 53}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bigint_decimal_strict_json_332@main, '__bp_init_8'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 210}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, main, 0, 57}.
  {label, 56}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 31}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, main}, 0}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 32}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '_botopink_main'}, 0}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 33}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, main}, 1}.
  {label, 61}.
    {call_only, 0, {f, 59}}.

{function, '__bp_load_siblings', 0, 63}.
  {label, 62}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 34}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 63}.
    {allocate, 0, 0}.
    {move, {atom, bigint_decimal_strict_json_332@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 211}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 65}, 0}.
  {label, 211}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 65}.
  {label, 64}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 35}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 65}.
    {test, is_nonempty_list, {f, 212}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 213}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 215}}.
  {label, 213}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 214}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 215}}.
  {label, 214}.
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
  {label, 215}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 65}, 2}.
  {label, 212}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '_botopink_init', 0, 67}.
  {label, 66}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 36}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '_botopink_init'}, 0}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 37}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_ets'}, 2}.
  {label, 69}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 216}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 71}, 2}.
  {label, 216}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 71}.
  {label, 70}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 38}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 71}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 217}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 218}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 218}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 220}}.
  {label, 218}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 219}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, bigint_decimal_strict_json_332@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 220}}.
  {label, 219}.
    {move, {y, 2}, {y, 3}}.
  {label, 220}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 71}, 4}.
  {label, 217}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 73}.
  {label, 72}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 39}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 73}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 221}}.
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
  {label, 221}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 222}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 222}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 222}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, 'string_slice', 3, 90}.
  {label, 89}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 40}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, 'string_slice'}, 3}.
  {label, 90}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 223}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 225}, 3}.
  {label, 223}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 247}, 3}.

{function, '__bp_priv____bp_ets', 2, 264}.
  {label, 263}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 41}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 264}.
    {call_only, 2, {f, 69}}.

{function, '__bp_priv____bp_set_answers', 1, 266}.
  {label, 265}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 42}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_priv____bp_set_answers'}, 1}.
  {label, 266}.
    {call_only, 1, {f, 77}}.

{function, '__bp_priv____bp_swap_answers', 1, 268}.
  {label, 267}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 43}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_priv____bp_swap_answers'}, 1}.
  {label, 268}.
    {call_only, 1, {f, 79}}.

{function, '__bp_priv____bp_tab_answers', 0, 270}.
  {label, 269}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 44}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_priv____bp_tab_answers'}, 0}.
  {label, 270}.
    {call_only, 0, {f, 75}}.

{function, '__bp_priv__string_slice', 3, 272}.
  {label, 271}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 45}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 272}.
    {call_only, 3, {f, 90}}.

{function, '-bp_field-', 2, 96}.
  {label, 95}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 4}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-bp_field-'}, 2}.
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
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 14}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_0/0-fun-0-'}, 2}.
  {label, 115}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_arithmetic">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_arithmetic">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_arithmetic">>}, {x, 0}}.
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

{function, '-__bp_executor_1/0-fun-1-', 2, 118}.
  {label, 117}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 16}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_1/0-fun-1-'}, 2}.
  {label, 118}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_in_containers">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_in_containers">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_in_containers">>}, {x, 0}}.
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

{function, '-__bp_executor_2/0-fun-2-', 2, 121}.
  {label, 120}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 18}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_2/0-fun-2-'}, 2}.
  {label, 121}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 122}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 122}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 123}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 123}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 124}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 124}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 125}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 125}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 126}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 126}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 127}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 127}.
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

{function, '-__bp_executor_2/0-fun-3-', 2, 130}.
  {label, 129}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 18}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_2/0-fun-3-'}, 2}.
  {label, 130}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_comptime">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_comptime">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_comptime">>}, {x, 0}}.
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
    {move, {literal, <<"comptime-bigint">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"comptime-bigint: a `bigint` is not computed at compile time yet">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 15}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 131}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 131}.
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

{function, '-__bp_executor_3/0-fun-4-', 2, 134}.
  {label, 133}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 20}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_3/0-fun-4-'}, 2}.
  {label, 134}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 135}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 135}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 136}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 136}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 137}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 137}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 138}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 138}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 139}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 140}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 140}.
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

{function, '-__bp_executor_3/0-fun-5-', 2, 143}.
  {label, 142}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 20}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_3/0-fun-5-'}, 2}.
  {label, 143}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_into_i64">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_into_i64">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_into_i64">>}, {x, 0}}.
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
    {move, {literal, <<"type mismatch: expected i64, got bigint">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 18}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 144}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 144}.
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

{function, '-__bp_executor_4/0-fun-6-', 2, 147}.
  {label, 146}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 22}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_4/0-fun-6-'}, 2}.
  {label, 147}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 148}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 148}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 149}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 149}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 150}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 150}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 151}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 151}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 152}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 152}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 153}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 153}.
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

{function, '-__bp_executor_4/0-fun-7-', 2, 156}.
  {label, 155}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 22}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_4/0-fun-7-'}, 2}.
  {label, 156}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_into_unknown">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_into_unknown">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_into_unknown">>}, {x, 0}}.
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
    {move, {literal, <<"bigint-widened">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bigint-widened: a `bigint` does not widen to `unknown`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 157}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 157}.
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

{function, '-__bp_executor_5/0-fun-8-', 2, 160}.
  {label, 159}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 24}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_5/0-fun-8-'}, 2}.
  {label, 160}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 161}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 161}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 162}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 162}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 163}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 163}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 164}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 164}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 165}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 165}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 166}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 166}.
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

{function, '-__bp_executor_5/0-fun-9-', 2, 169}.
  {label, 168}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 24}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_5/0-fun-9-'}, 2}.
  {label, 169}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_literal_fraction">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_literal_fraction">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_literal_fraction">>}, {x, 0}}.
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
    {move, {literal, <<"number-suffix-integer-on-float">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"a literal with a fraction or an exponent is floating and takes `f` or `d` only">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, {literal, <<"an integer suffix">>}, {x, 0}}.
    {move, {x, 0}, {x, 4}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 5}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 16}, {x, 4}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 170}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 170}.
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

{function, '-__bp_executor_6/0-fun-10-', 2, 173}.
  {label, 172}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 26}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_6/0-fun-10-'}, 2}.
  {label, 173}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 174}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 174}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 175}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 175}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 176}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 176}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 177}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 177}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 178}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 178}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 179}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 179}.
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

{function, '-__bp_executor_6/0-fun-11-', 2, 182}.
  {label, 181}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 26}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_6/0-fun-11-'}, 2}.
  {label, 182}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_plus_int_literal">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_plus_int_literal">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_plus_int_literal">>}, {x, 0}}.
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
    {move, {literal, <<"the integer literal `1` is not a `bigint` \x{E2}\x{80}\x{94} write `1n`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 18}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 183}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 183}.
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

{function, '-__bp_executor_7/0-fun-12-', 2, 186}.
  {label, 185}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 28}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_7/0-fun-12-'}, 2}.
  {label, 186}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 187}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 187}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 188}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 188}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 189}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 189}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 190}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 190}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 191}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 191}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 192}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 192}.
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

{function, '-__bp_executor_7/0-fun-13-', 2, 195}.
  {label, 194}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 28}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_7/0-fun-13-'}, 2}.
  {label, 195}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_type_test">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_type_test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_type_test">>}, {x, 0}}.
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
    {move, {literal, <<"bigint-type-test">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bigint-type-test: `is` does not test a `bigint`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 8}, {integer, 13}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 196}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 196}.
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

{function, '-__bp_executor_8/0-fun-14-', 2, 199}.
  {label, 198}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 30}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_8/0-fun-14-'}, 2}.
  {label, 199}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 200}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 200}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 201}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 201}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 202}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 202}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 203}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 203}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 204}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 204}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 205}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 205}.
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

{function, '-__bp_executor_8/0-fun-15-', 2, 208}.
  {label, 207}.
    {line, [{location, "bigint_decimal_strict_json_332@main.erl", 30}]}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '-__bp_executor_8/0-fun-15-'}, 2}.
  {label, 208}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"bigint_unsuffixed_literal">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bigint_unsuffixed_literal">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/bigint_unsuffixed_literal">>}, {x, 0}}.
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
    {move, {literal, <<"the integer literal `2` is not a `bigint` \x{E2}\x{80}\x{94} write `2n`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 7}, {integer, 21}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 209}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 209}.
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

{function, '__bp_tpl_0-t/3-fun-0-', 3, 229}.
  {label, 228}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_tpl_0-t/3-fun-0-'}, 3}.
  {label, 229}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 233}}.
  {label, 233}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 235}}.
  {label, 235}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 237}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 236}}.
  {label, 237}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 238}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 236}}.
  {label, 238}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 236}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 240}}.
  {label, 240}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 242}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 241}}.
  {label, 242}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 243}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 241}}.
  {label, 243}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 241}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 245}}.
  {label, 245}.
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

{function, '__bp_tpl_0', 3, 225}.
  {label, 224}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_tpl_0'}, 3}.
  {label, 225}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 229}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 251}.
  {label, 250}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 251}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 255}}.
  {label, 255}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 257}}.
  {label, 257}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 258}}.
  {label, 259}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 260}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 258}}.
  {label, 260}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 258}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 262}}.
  {label, 262}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_1', 2, 247}.
  {label, 246}.
    {func_info, {atom, bigint_decimal_strict_json_332@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 247}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 251}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
