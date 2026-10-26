{module, derived_type_static_methods_307@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {'__bp_loaded', 2}, {'__bp_load_module', 3}, {'__bp_run', 1}, {'__bp_run_async', 1}, {'__bp_run_none', 0}, {'__bp_run_async_none', 0}, {accepted, 0}, {answers, 0}, {'__bp_comptime_0_at', 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_executor_2', 0}, {'__bp_init_2', 0}, {'__bp_executor_3', 0}, {'__bp_init_3', 0}, {'__bp_executor_4', 0}, {'__bp_init_4', 0}, {'__bp_executor_5', 0}, {'__bp_init_5', 0}, {'__bp_executor_6', 0}, {'__bp_init_6', 0}, {'__bp_executor_7', 0}, {'__bp_init_7', 0}, {'__bp_executor_8', 0}, {'__bp_init_8', 0}, {'__bp_executor_9', 0}, {'__bp_init_9', 0}, {'__bp_executor_10', 0}, {'__bp_init_10', 0}, {'__bp_executor_11', 0}, {'__bp_init_11', 0}, {'__bp_executor_12', 0}, {'__bp_init_12', 0}, {'__bp_executor_13', 0}, {'__bp_init_13', 0}, {main, 0}, {'__bp_ets_owner', 2}, {'__bp_priv____bp_ets', 2}, {'__bp_priv____bp_set_answers', 1}, {'__bp_priv____bp_swap_answers', 1}, {'__bp_priv____bp_tab_answers', 0}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 348}.

{function, '__bp_loaded', 2, 3}.
  {label, 2}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 1}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_loaded'}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_lt, {f, 100}, [{integer, 0}, {x, 0}]}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 0}, {y, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 2}.
    return.
  {label, 100}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 2}.
    return.

{function, '__bp_load_module', 3, 5}.
  {label, 4}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 2}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_load_module'}, 3}.
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
    {line, [{location, "derived_type_static_methods_307@main.erl", 3}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_run'}, 1}.
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
    {call, 3, {f, 110}}.
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
    {test, is_eq, {f, 112}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 113}}.
  {label, 112}.
    {move, {atom, true}, {x, 0}}.
  {label, 113}.
    {test, is_eq, {f, 111}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 110}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 111}.
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
    {test, is_tagged_tuple, {f, 114}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 116}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 101}}.
  {label, 114}.
    {case_end, {x, 0}}.
  {label, 101}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

%% @Async — eager lowering
{function, '__bp_run_async', 1, 9}.
  {label, 8}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 4}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_run_async'}, 1}.
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
    {test, is_tagged_tuple, {f, 122}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 124}, [{x, 0}, 2, {atom, ok}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 123}}.
  {label, 124}.
    {test, is_tagged_tuple, {f, 125}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 5}}.
    {move, {literal, <<"\0bp-off:X">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 127}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 128}}.
  {label, 127}.
    {move, {atom, true}, {x, 0}}.
  {label, 128}.
    {test, is_eq, {f, 126}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__excluded}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 110}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 6}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 126}.
    {move, {literal, <<"\0bp-off:R">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 130}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 131}}.
  {label, 130}.
    {move, {atom, true}, {x, 0}}.
  {label, 131}.
    {test, is_eq, {f, 129}, [{x, 0}, {atom, true}]}.
    {move, {atom, std@compiler@@RunFailureKind__v__refused}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 5}, {x, 0}}.
    {move, {atom, undefined}, {x, 2}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 3, {f, 110}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 7}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 129}.
    {move, {atom, std@compiler@@RunFailureKind__v__failed}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {x, 0}, {y, 5}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
  {label, 125}.
    {case_end, {x, 0}}.
  {label, 123}.
    {jump, {f, 121}}.
  {label, 122}.
    {test, is_tagged_tuple, {f, 132}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 8}}.
    {move, {atom, std@compiler@@RunFailureKind__v__abort}, {x, 0}}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 8}, {x, 0}}.
    {move, {atom, message}, {x, 1}}.
    {call, 2, {f, 116}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@RunFailure}, {y, 9}, {x, 0}, {y, 3}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 16}.
    return.
    {jump, {f, 121}}.
  {label, 132}.
    {case_end, {x, 0}}.
  {label, 121}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_run_none', 0, 11}.
  {label, 10}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 5}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_run_none'}, 0}.
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
    {line, [{location, "derived_type_static_methods_307@main.erl", 6}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_run_async_none'}, 0}.
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
    {line, [{location, "derived_type_static_methods_307@main.erl", 7}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, accepted}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"botopink-cell 2\n== derived_type_decorated\nout RecipePatch true (title: ?string #label, description: ?string, servings: ?i32)\nout RecipeTitle true (title: string #label)\nout Feijoada\n== derived_type_functions\nout Feijoada\nout 2\nout Feijoada\nout black beans\nout 6\nout fried\nout DogWithBreed\nout Dog\nout Lua (beagle)\nout calm\nout Vatap\x{C3}\x{A1}\nout RecipeTitle(title: \"Bob\x{C3}\x{B3}\")\n== std_types_module\nout types\n== derived_type_bare_name\nrefused error: unbound variable 'partial'\nat src/main.bp:6:17\n== derived_type_field_repeated\nrefused error: derived-type-fields: field `.title` is named twice\nat src/main.bp:10:49\n== derived_type_field_string\nrefused error: derived-type-field-string: a field is named `.title`, not the string \"title\"\nat src/main.bp:11:41\n== derived_type_merge_duplicate\nrefused error: derived-type-merge-duplicate: field `name` is on both sides of `Type.merge(Dog, Pet)`\nat src/main.bp:10:34\n== derived_type_no_field\nrefused error: derived-type-fields: `Type.pick` takes at least one field after the type\nat src/main.bp:10:24\n== derived_type_not_record\nrefused error: derived-type-source-not-record: `Type.partial` takes a record type; `Fish` is an enum\nat src/main.bp:11:34\n== derived_type_omit_empty\nrefused error: derived-type-fields: `Type.omit` leaves `Recipe` with no field\nat src/main.bp:10:22\n== derived_type_outside_val\nrefused error: derived-type-outside-val: a derived type is the whole initializer of a module-level `val`\nat src/main.bp:12:22\n== derived_type_primitive\nrefused error: derived-type-source-not-record: `Type.partial` takes a record type; `i32` is a primitive type\nat src/main.bp:5:33\n== derived_type_unknown_field\nrefused error: unknown field 'titel' on type 'Recipe'\nat src/main.bp:11:41\n== derived_type_var\nrefused error: derived-type-outside-val: a derived type is bound by a module-level `val` with no type annotation \x{E2}\x{80}\x{94} `Patch` is a `var`\nat src/main.bp:10:22\n">>}, {x, 0}}.
    {deallocate, 0}.
    return.
%% What each case answered, in the order the cases ran.

    %% var answers — beamMemory(.Ets)
{function, answers, 0, 17}.
  {label, 16}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 8}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, answers}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {call, 0, {f, 95}}.
    {move, {atom, derived_type_static_methods_307@main@@answers}, {x, 1}}.
    {move, {integer, 2}, {x, 2}}.
    {call_ext_last, 3, {extfunc, std@beam, etsGet, 3}, 0}.

{function, '__bp_tab_answers', 0, 95}.
  {label, 94}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 9}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_tab_answers'}, 0}.
  {label, 95}.
    {allocate, 0, 0}.
    {move, {atom, derived_type_static_methods_307@main@@answers}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 133}, [{x, 0}, {atom, undefined}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, derived_type_static_methods_307@main@@answers}, {x, 0}}.
    {call_last, 2, {f, 89}, 0}.
  {label, 133}.
    {move, {atom, derived_type_static_methods_307@main@@answers}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_set_answers', 1, 97}.
  {label, 96}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 10}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_set_answers'}, 1}.
  {label, 97}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 95}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 1}, {list, [{atom, derived_type_static_methods_307@main@@answers}, {y, 0}]}}.
    {call_ext_last, 2, {extfunc, std@beam, etsPut, 2}, 1}.

{function, '__bp_swap_answers', 1, 99}.
  {label, 98}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 11}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_swap_answers'}, 1}.
  {label, 99}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {call, 0, {f, 95}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, std@beam, etsSwap, 2}, 1}.
%% One case, expanded where it is called (decision 808 (2)): a refused load answers its
%% diagnostics, a loaded one runs and answers its output.

{function, '__bp_comptime_0_at', 0, 19}.
  {label, 18}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 12}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_comptime_0_at'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 21}.
  {label, 20}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 13}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 21}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_derived_type_decorated@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 135}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_0', 0, 23}.
  {label, 22}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 14}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_0'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 136}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 136}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_1', 0, 25}.
  {label, 24}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 15}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 25}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_derived_type_functions@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 138}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_1', 0, 27}.
  {label, 26}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 16}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_1'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 139}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 139}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_2', 0, 29}.
  {label, 28}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 17}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_2'}, 0}.
  {label, 29}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {literal, fun bp_load_cases_std_types_module@main:'__bp_loaded_main'/0}, {x, 0}}.
    {call, 1, {f, 7}}.
    {call_ext, 1, {extfunc, conformance_lib@adapter, ranOf, 1}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 141}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_init_2', 0, 31}.
  {label, 30}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 18}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_2'}, 0}.
  {label, 31}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_2'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 142}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 29}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 142}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_3', 0, 33}.
  {label, 32}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 19}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_3'}, 0}.
  {label, 33}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_bare_name">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_bare_name">>}, {x, 0}}.
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
    {move, {literal, <<"unbound variable 'partial'">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 17}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 151}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 151}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 144}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 153}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_3', 0, 35}.
  {label, 34}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 20}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_3'}, 0}.
  {label, 35}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_3'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 155}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 33}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 155}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_4', 0, 37}.
  {label, 36}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 21}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_4'}, 0}.
  {label, 37}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_field_repeated">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_field_repeated">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-fields">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-fields: field `.title` is named twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 49}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 164}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 164}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 157}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 166}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_4', 0, 39}.
  {label, 38}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 22}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_4'}, 0}.
  {label, 39}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_4'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 168}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 37}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_4'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 168}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_5', 0, 41}.
  {label, 40}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 23}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_5'}, 0}.
  {label, 41}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_field_string">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_field_string">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-field-string">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-field-string: a field is named `.title`, not the string \"title\"">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 41}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 177}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 177}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 170}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 179}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_5', 0, 43}.
  {label, 42}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 24}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_5'}, 0}.
  {label, 43}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_5'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 181}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 41}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_5'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 181}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_6', 0, 45}.
  {label, 44}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 25}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_6'}, 0}.
  {label, 45}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_merge_duplicate">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_merge_duplicate">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-merge-duplicate">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-merge-duplicate: field `name` is on both sides of `Type.merge(Dog, Pet)`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 34}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 190}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 190}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 183}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 192}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_6', 0, 47}.
  {label, 46}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 26}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_6'}, 0}.
  {label, 47}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_6'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 194}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 45}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_6'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 194}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_7', 0, 49}.
  {label, 48}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 27}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_7'}, 0}.
  {label, 49}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_no_field">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_no_field">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-fields">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-fields: `Type.pick` takes at least one field after the type">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 24}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 203}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 203}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 196}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 205}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_7', 0, 51}.
  {label, 50}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 28}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_7'}, 0}.
  {label, 51}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_7'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 207}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 49}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_7'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 207}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_8', 0, 53}.
  {label, 52}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 29}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_8'}, 0}.
  {label, 53}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_not_record">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_not_record">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-source-not-record">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-source-not-record: `Type.partial` takes a record type; `Fish` is an enum">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 34}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 216}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 216}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 209}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 218}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_8', 0, 55}.
  {label, 54}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 30}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_8'}, 0}.
  {label, 55}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_8'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 220}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 53}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_8'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 220}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_9', 0, 57}.
  {label, 56}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 31}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_9'}, 0}.
  {label, 57}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_omit_empty">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_omit_empty">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-fields">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-fields: `Type.omit` leaves `Recipe` with no field">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 229}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 229}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 222}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 231}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_9', 0, 59}.
  {label, 58}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 32}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_9'}, 0}.
  {label, 59}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_9'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 233}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 57}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_9'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 233}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_10', 0, 61}.
  {label, 60}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 33}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_10'}, 0}.
  {label, 61}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_outside_val">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_outside_val">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-outside-val">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-outside-val: a derived type is the whole initializer of a module-level `val`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 12}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 242}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 242}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 235}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 244}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_10', 0, 63}.
  {label, 62}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 34}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_10'}, 0}.
  {label, 63}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_10'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 246}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 61}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_10'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 246}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_11', 0, 65}.
  {label, 64}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 35}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_11'}, 0}.
  {label, 65}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_primitive">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_primitive">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-source-not-record">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-source-not-record: `Type.partial` takes a record type; `i32` is a primitive type">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 5}, {integer, 33}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 255}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 255}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 248}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 257}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_11', 0, 67}.
  {label, 66}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 36}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_11'}, 0}.
  {label, 67}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_11'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 259}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 65}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_11'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 259}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_12', 0, 69}.
  {label, 68}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 37}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_12'}, 0}.
  {label, 69}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_unknown_field">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_unknown_field">>}, {x, 0}}.
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
    {move, {literal, <<"unknown field 'titel' on type 'Recipe'">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 41}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 268}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 268}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 261}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 270}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_12', 0, 71}.
  {label, 70}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 38}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_12'}, 0}.
  {label, 71}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_12'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 272}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 69}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_12'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 272}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_13', 0, 73}.
  {label, 72}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 39}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_executor_13'}, 0}.
  {label, 73}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"derived_type_var">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_var">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-outside-val">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-outside-val: a derived type is bound by a module-level `val` with no type annotation \x{E2}\x{80}\x{94} `Patch` is a `var`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 1}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 281}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 281}.
    {move, {y, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 274}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 283}, 0, 0, {x, 0}, {list, [{y, 0}]}}.
    {call, 1, {f, 99}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_init_13', 0, 75}.
  {label, 74}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 40}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_init_13'}, 0}.
  {label, 75}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_13'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 285}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 73}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {derived_type_static_methods_307@main, '__bp_init_13'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 285}.
    {deallocate, 1}.
    return.

%% @Async — eager lowering
{function, main, 0, 77}.
  {label, 76}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 41}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, main}, 0}.
  {label, 77}.
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

{function, '_botopink_main', 0, 79}.
  {label, 78}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 42}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '_botopink_main'}, 0}.
  {label, 79}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 83}}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 35}}.
    {call, 0, {f, 39}}.
    {call, 0, {f, 43}}.
    {call, 0, {f, 47}}.
    {call, 0, {f, 51}}.
    {call, 0, {f, 55}}.
    {call, 0, {f, 59}}.
    {call, 0, {f, 63}}.
    {call, 0, {f, 67}}.
    {call, 0, {f, 71}}.
    {call, 0, {f, 75}}.
    {call_last, 0, {f, 77}, 0}.

{function, main, 1, 81}.
  {label, 80}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 43}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, main}, 1}.
  {label, 81}.
    {call_only, 0, {f, 79}}.

{function, '__bp_load_siblings', 0, 83}.
  {label, 82}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 44}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 83}.
    {allocate, 0, 0}.
    {move, {atom, derived_type_static_methods_307@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 286}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 85}, 0}.
  {label, 286}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 85}.
  {label, 84}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 45}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 85}.
    {test, is_nonempty_list, {f, 287}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 288}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 290}}.
  {label, 288}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 289}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 290}}.
  {label, 289}.
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
  {label, 290}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 85}, 2}.
  {label, 287}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '_botopink_init', 0, 87}.
  {label, 86}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 46}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '_botopink_init'}, 0}.
  {label, 87}.
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
    {call, 0, {f, 59}}.
    {call, 0, {f, 63}}.
    {call, 0, {f, 67}}.
    {call, 0, {f, 71}}.
    {call, 0, {f, 75}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_ets', 2, 89}.
  {label, 88}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 47}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_ets'}, 2}.
  {label, 89}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 291}, [{x, 0}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_last, 3, {f, 91}, 2}.
  {label, 291}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_ets_wait', 3, 91}.
  {label, 90}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 48}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_ets_wait'}, 3}.
  {label, 91}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {call_ext, 1, {extfunc, erlang, whereis, 1}}.
    {test, is_eq_exact, {f, 292}, [{x, 0}, {atom, undefined}]}.
    {test, is_pid, {f, 293}, [{y, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, is_process_alive, 1}}.
    {test, is_eq_exact, {f, 293}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {y, 3}}.
    {jump, {f, 295}}.
  {label, 293}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@beam, etsWhereis, 1}}.
    {test, is_eq_exact, {f, 294}, [{x, 0}, {atom, undefined}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 2}}.
    {put_list, {y, 0}, {x, 2}, {x, 2}}.
    {move, {atom, '__bp_ets_owner'}, {x, 1}}.
    {move, {atom, derived_type_static_methods_307@main}, {x, 0}}.
    {call_ext, 3, {extfunc, erlang, spawn, 3}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 295}}.
  {label, 294}.
    {move, {y, 2}, {y, 3}}.
  {label, 295}.
    {call_ext, 0, {extfunc, erlang, yield, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 3}, {x, 2}}.
    {call_last, 3, {f, 91}, 4}.
  {label, 292}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_ets_owner', 2, 93}.
  {label, 92}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 49}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_ets_owner'}, 2}.
  {label, 93}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {'try', {y, 2}, {f, 296}}.
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
  {label, 296}.
    {try_case, {y, 2}}.
    {test, is_eq_exact, {f, 297}, [{x, 0}, {atom, error}]}.
    {test, is_eq_exact, {f, 297}, [{x, 1}, {atom, badarg}]}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.
  {label, 297}.
    {bif, raise, {f, 0}, [{x, 2}, {x, 1}], {x, 0}}.

{function, 'string_slice', 3, 110}.
  {label, 109}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 50}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, 'string_slice'}, 3}.
  {label, 110}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 298}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 300}, 3}.
  {label, 298}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 322}, 3}.

{function, '__bp_priv____bp_ets', 2, 339}.
  {label, 338}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 51}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_priv____bp_ets'}, 2}.
  {label, 339}.
    {call_only, 2, {f, 89}}.

{function, '__bp_priv____bp_set_answers', 1, 341}.
  {label, 340}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 52}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_priv____bp_set_answers'}, 1}.
  {label, 341}.
    {call_only, 1, {f, 97}}.

{function, '__bp_priv____bp_swap_answers', 1, 343}.
  {label, 342}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 53}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_priv____bp_swap_answers'}, 1}.
  {label, 343}.
    {call_only, 1, {f, 99}}.

{function, '__bp_priv____bp_tab_answers', 0, 345}.
  {label, 344}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 54}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_priv____bp_tab_answers'}, 0}.
  {label, 345}.
    {call_only, 0, {f, 95}}.

{function, '__bp_priv__string_slice', 3, 347}.
  {label, 346}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 55}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 347}.
    {call_only, 3, {f, 110}}.

{function, '-bp_field-', 2, 116}.
  {label, 115}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 4}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-bp_field-'}, 2}.
  {label, 116}.
    {test, is_map, {f, 117}, [{x, 0}]}.
    {move, {x, 0}, {x, 2}}.
    {move, {x, 1}, {x, 0}}.
    {move, {x, 2}, {x, 1}}.
    {move, {atom, undefined}, {x, 2}}.
    {call_ext_only, 3, {extfunc, maps, get, 3}}.
  {label, 117}.
    {test, is_tuple, {f, 118}, [{x, 0}]}.
    {bif, element, {f, 120}, [{integer, 1}, {x, 0}], {x, 2}}.
    {test, is_atom, {f, 120}, [{x, 2}]}.
    {test_heap, 4, 3}.
    {put_list, {x, 1}, nil, {x, 3}}.
    {put_list, {x, 0}, {x, 3}, {x, 3}}.
    {move, {x, 2}, {x, 0}}.
    {move, {atom, '__bp_get'}, {x, 1}}.
    {move, {x, 3}, {x, 2}}.
    {call_ext_only, 3, {extfunc, erlang, apply, 3}}.
  {label, 118}.
    {test, is_eq_exact, {f, 120}, [{x, 1}, {atom, length}]}.
    {test, is_list, {f, 119}, [{x, 0}]}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    return.
  {label, 119}.
    {test, is_binary, {f, 120}, [{x, 0}]}.
    {allocate, 0, 1}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 0}.
    return.
  {label, 120}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '-__bp_executor_0/0-fun-0-', 2, 135}.
  {label, 134}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 14}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_0/0-fun-0-'}, 2}.
  {label, 135}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_decorated">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_decorated">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_decorated">>}, {x, 0}}.
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
    {call, 2, {f, 116}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 116}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 116}}.
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

{function, '-__bp_executor_1/0-fun-1-', 2, 138}.
  {label, 137}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 16}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_1/0-fun-1-'}, 2}.
  {label, 138}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_functions">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_functions">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_functions">>}, {x, 0}}.
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
    {call, 2, {f, 116}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 116}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 116}}.
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

{function, '-__bp_executor_2/0-fun-2-', 2, 141}.
  {label, 140}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 18}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_2/0-fun-2-'}, 2}.
  {label, 141}.
    {allocate, 9, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"std_types_module">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"std_types_module">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/std_types_module">>}, {x, 0}}.
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
    {call, 2, {f, 116}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failed}, {x, 1}}.
    {call, 2, {f, 116}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, failure}, {x, 1}}.
    {call, 2, {f, 116}}.
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

{function, '-__bp_executor_3/0-fun-3-', 2, 144}.
  {label, 143}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 20}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_3/0-fun-3-'}, 2}.
  {label, 144}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 145}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 145}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 146}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 146}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 147}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 147}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 148}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 148}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 149}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 149}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 150}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 150}.
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

{function, '-__bp_executor_3/0-fun-4-', 2, 153}.
  {label, 152}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 20}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_3/0-fun-4-'}, 2}.
  {label, 153}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_bare_name">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_bare_name">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_bare_name">>}, {x, 0}}.
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
    {move, {literal, <<"unbound variable 'partial'">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 6}, {integer, 17}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 154}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 154}.
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

{function, '-__bp_executor_4/0-fun-5-', 2, 157}.
  {label, 156}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 22}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_4/0-fun-5-'}, 2}.
  {label, 157}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 158}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 158}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 159}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 159}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 160}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 160}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 161}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 161}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 162}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 162}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 163}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 163}.
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

{function, '-__bp_executor_4/0-fun-6-', 2, 166}.
  {label, 165}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 22}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_4/0-fun-6-'}, 2}.
  {label, 166}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_field_repeated">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_field_repeated">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_field_repeated">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-fields">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-fields: field `.title` is named twice">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 49}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 167}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 167}.
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

{function, '-__bp_executor_5/0-fun-7-', 2, 170}.
  {label, 169}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 24}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_5/0-fun-7-'}, 2}.
  {label, 170}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 171}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 171}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 172}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 172}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 173}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 173}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 174}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 174}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 175}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 175}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 176}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 176}.
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

{function, '-__bp_executor_5/0-fun-8-', 2, 179}.
  {label, 178}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 24}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_5/0-fun-8-'}, 2}.
  {label, 179}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_field_string">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_field_string">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_field_string">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-field-string">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-field-string: a field is named `.title`, not the string \"title\"">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 41}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 180}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 180}.
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

{function, '-__bp_executor_6/0-fun-9-', 2, 183}.
  {label, 182}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 26}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_6/0-fun-9-'}, 2}.
  {label, 183}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 184}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 184}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 185}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 185}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 186}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 186}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 187}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 187}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 188}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 188}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 189}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 189}.
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

{function, '-__bp_executor_6/0-fun-10-', 2, 192}.
  {label, 191}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 26}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_6/0-fun-10-'}, 2}.
  {label, 192}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_merge_duplicate">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_merge_duplicate">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_merge_duplicate">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-merge-duplicate">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-merge-duplicate: field `name` is on both sides of `Type.merge(Dog, Pet)`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 34}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 193}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 193}.
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

{function, '-__bp_executor_7/0-fun-11-', 2, 196}.
  {label, 195}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 28}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_7/0-fun-11-'}, 2}.
  {label, 196}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 197}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 197}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 198}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 198}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 199}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 199}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 200}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 200}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 201}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 201}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 202}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 202}.
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

{function, '-__bp_executor_7/0-fun-12-', 2, 205}.
  {label, 204}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 28}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_7/0-fun-12-'}, 2}.
  {label, 205}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_no_field">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_no_field">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_no_field">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-fields">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-fields: `Type.pick` takes at least one field after the type">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 24}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 206}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 206}.
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

{function, '-__bp_executor_8/0-fun-13-', 2, 209}.
  {label, 208}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 30}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_8/0-fun-13-'}, 2}.
  {label, 209}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 210}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 210}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 211}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 211}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 212}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 212}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 213}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 213}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 214}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 214}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 215}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 215}.
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

{function, '-__bp_executor_8/0-fun-14-', 2, 218}.
  {label, 217}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 30}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_8/0-fun-14-'}, 2}.
  {label, 218}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_not_record">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_not_record">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_not_record">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-source-not-record">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-source-not-record: `Type.partial` takes a record type; `Fish` is an enum">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 34}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 219}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 219}.
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

{function, '-__bp_executor_9/0-fun-15-', 2, 222}.
  {label, 221}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 32}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_9/0-fun-15-'}, 2}.
  {label, 222}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 223}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 223}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 224}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 224}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 225}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 225}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 226}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 226}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 227}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 227}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 228}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 228}.
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

{function, '-__bp_executor_9/0-fun-16-', 2, 231}.
  {label, 230}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 32}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_9/0-fun-16-'}, 2}.
  {label, 231}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_omit_empty">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_omit_empty">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_omit_empty">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-fields">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-fields: `Type.omit` leaves `Recipe` with no field">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 232}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 232}.
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

{function, '-__bp_executor_10/0-fun-17-', 2, 235}.
  {label, 234}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 34}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_10/0-fun-17-'}, 2}.
  {label, 235}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 236}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 236}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 237}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 237}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 238}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 238}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 239}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 239}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 240}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 240}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 241}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 241}.
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

{function, '-__bp_executor_10/0-fun-18-', 2, 244}.
  {label, 243}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 34}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_10/0-fun-18-'}, 2}.
  {label, 244}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_outside_val">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_outside_val">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_outside_val">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-outside-val">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-outside-val: a derived type is the whole initializer of a module-level `val`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 12}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 245}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 245}.
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

{function, '-__bp_executor_11/0-fun-19-', 2, 248}.
  {label, 247}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 36}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_11/0-fun-19-'}, 2}.
  {label, 248}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 249}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 249}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 250}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 250}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 251}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 251}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 252}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 252}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 253}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 253}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 254}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 254}.
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

{function, '-__bp_executor_11/0-fun-20-', 2, 257}.
  {label, 256}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 36}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_11/0-fun-20-'}, 2}.
  {label, 257}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_primitive">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_primitive">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_primitive">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-source-not-record">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-source-not-record: `Type.partial` takes a record type; `i32` is a primitive type">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 5}, {integer, 33}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 258}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 258}.
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

{function, '-__bp_executor_12/0-fun-21-', 2, 261}.
  {label, 260}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 38}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_12/0-fun-21-'}, 2}.
  {label, 261}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 262}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 262}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 263}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 263}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 264}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 264}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 265}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 265}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 266}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 266}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 267}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 267}.
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

{function, '-__bp_executor_12/0-fun-22-', 2, 270}.
  {label, 269}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 38}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_12/0-fun-22-'}, 2}.
  {label, 270}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_unknown_field">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_unknown_field">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_unknown_field">>}, {x, 0}}.
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
    {move, {literal, <<"unknown field 'titel' on type 'Recipe'">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 11}, {integer, 41}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 271}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 271}.
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

{function, '-__bp_executor_13/0-fun-23-', 2, 274}.
  {label, 273}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 40}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_13/0-fun-23-'}, 2}.
  {label, 274}.
    {allocate, 11, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 275}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 275}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 276}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 276}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 277}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 277}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 278}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 278}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 279}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 5, {x, 0}}.
  {label, 279}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 280}, [{x, 0}, 8, {atom, std@compiler@@Diagnostic}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 280}.
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

{function, '-__bp_executor_13/0-fun-24-', 2, 283}.
  {label, 282}.
    {line, [{location, "derived_type_static_methods_307@main.erl", 40}]}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '-__bp_executor_13/0-fun-24-'}, 2}.
  {label, 283}.
    {allocate, 10, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {literal, <<"derived_type_var">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"derived_type_var">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"cases/derived_type_var">>}, {x, 0}}.
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
    {move, {literal, <<"derived-type-outside-val">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"derived-type-outside-val: a derived type is bound by a module-level `val` with no type annotation \x{E2}\x{80}\x{94} `Patch` is a `var`">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"src/main.bp">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 9, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Diagnostic}, {x, 1}, {x, 2}, {x, 3}, {integer, 10}, {integer, 22}, {atom, undefined}, {x, 0}]}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, std@compiler@@Refused}, {y, 3}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 284}, [{x, 0}, 3, {atom, std@compiler@@Refused}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 284}.
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

{function, '__bp_tpl_0-t/3-fun-0-', 3, 304}.
  {label, 303}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_tpl_0-t/3-fun-0-'}, 3}.
  {label, 304}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 308}}.
  {label, 308}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 310}}.
  {label, 310}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 312}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 311}}.
  {label, 312}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 313}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 311}}.
  {label, 313}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 311}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 315}}.
  {label, 315}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 317}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 316}}.
  {label, 317}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 318}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 316}}.
  {label, 318}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 316}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 320}}.
  {label, 320}.
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

{function, '__bp_tpl_0', 3, 300}.
  {label, 299}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_tpl_0'}, 3}.
  {label, 300}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 304}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/2-fun-0-', 2, 326}.
  {label, 325}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_tpl_1-t/2-fun-0-'}, 2}.
  {label, 326}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 330}}.
  {label, 330}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 332}}.
  {label, 332}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 334}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 333}}.
  {label, 334}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 335}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 333}}.
  {label, 335}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 333}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 337}}.
  {label, 337}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_1', 2, 322}.
  {label, 321}.
    {func_info, {atom, derived_type_static_methods_307@main}, {atom, '__bp_tpl_1'}, 2}.
  {label, 322}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 326}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
