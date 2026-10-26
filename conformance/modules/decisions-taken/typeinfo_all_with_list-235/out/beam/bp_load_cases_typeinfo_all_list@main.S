{module, bp_load_cases_typeinfo_all_list@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {declared__metaAll__Service, 2}, {declared__metaAll__Store, 2}, {declared__metaAll__Audited, 2}]}.
{attributes, []}.
{labels, 127}.
%%% Decision 235 — `@TypeInfo.all(with: [a, b])` answers every declaration
%%% carrying any decorator of the list, in the one order (module path, then
%%% declaration order), a declaration carrying two of them once, with the
%%% meta every listed decorator set. Each `value` is `unknown` (decision 254);
%%% calling it through `is fn() -> T` is front 130's. A type's entry has no
%%% return type: `returnTypeName` is `""` (decision 256).

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 16, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Billing">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list/main">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 66}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Audited">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 68}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Service">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 8, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Declared}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Orders">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list/main">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Store">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 74}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 8, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Declared}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Mailer">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list/main">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 5}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Service">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 78}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 8, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Declared}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"Billing">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list/main">>}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Audited">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 90}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Service">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 92}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 8, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Declared}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"Mailer">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list/main">>}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 94}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 6}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Service">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 96}, 0, 0, {x, 0}, {list, []}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}, {x, 1}, {x, 0}]}}.
    {move, {y, 7}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 8, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Declared}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {x, 0}]}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 80}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, foreach, 2}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.
% What `#[service]` records.
% What `#[repository]` records.
% What `#[audited]` records.

{function, '__bp_loaded_main', 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/typeinfo_all_list|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, declared__metaAll__Service, 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, declared__metaAll__Service}, 2}.
  {label, 11}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 98}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, declared__metaAll__Store, 2, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, declared__metaAll__Store}, 2}.
  {label, 13}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 108}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, declared__metaAll__Audited, 2, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, declared__metaAll__Audited}, 2}.
  {label, 15}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 118}, 0, 0, {x, 0}, {list, [{y, 1}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 3}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_print', 1, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '__bp_print'}, 1}.
  {label, 26}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 30}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 30}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 28}}.

{function, '-bp_show_elem-', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 32}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 28}}.

{function, '__bp_show', 2, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '__bp_show'}, 2}.
  {label, 28}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 40}, [{x, 0}]}.
    {test, is_eq, {f, 39}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 41}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 43}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 42}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 42}, [{x, 0}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 48}}.
  {label, 47}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 48}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 28}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 32}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 45}, [{x, 0}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, undefined}]}.
  {label, 44}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 34}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 46}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '__bp_tagged'}, 2}.
  {label, 34}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 49}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 49}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 49}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 36}, 3}.
  {label, 50}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '__bp_render'}, 1}.
  {label, 36}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 51}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 51}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 52}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 38}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 28}}.
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

{function, '-bp_stringify-', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 54}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 55}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 55}.
    {test, is_integer, {f, 56}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 56}.
    {call, 1, {f, 30}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-main/1-fun-1-', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/1-fun-1-'}, 2}.
  {label, 23}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 2, {atom, bp_load_cases_typeinfo_all_list@main@@Service}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 24}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"role=">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-main/1-fun-2-', 2, 59}.
  {label, 58}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/1-fun-2-'}, 2}.
  {label, 59}.
    {allocate, 5, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 60}, [{x, 0}, 2, {atom, bp_load_cases_typeinfo_all_list@main@@Store}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 60}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"store=">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-bp_join-', 2, 63}.
  {label, 62}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-bp_join-'}, 2}.
  {label, 63}.
    {allocate, 1, 2}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {call_ext_last, 1, {extfunc, erlang, iolist_to_binary, 1}, 1}.

{function, '-main/0-fun-0-', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 21}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 7, {atom, bp_load_cases_typeinfo_all_list@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 57}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Service">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 11}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 61}, [{x, 0}, 7, {atom, bp_load_cases_typeinfo_all_list@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 61}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Store">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 13}}.
    {move, {y, 1}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 59}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 2, {f, 63}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 64}, [{x, 0}, 7, {atom, bp_load_cases_typeinfo_all_list@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 64}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '-main/0-fun-3-', 0, 66}.
  {label, 65}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-3-'}, 0}.
  {label, 66}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, bp_load_cases_typeinfo_all_list@main@@Billing, make, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-4-', 0, 68}.
  {label, 67}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-4-'}, 0}.
  {label, 68}.
    {allocate, 0, 0}.
    {move, {literal, <<"yes">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Audited}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-5-', 0, 70}.
  {label, 69}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-5-'}, 0}.
  {label, 70}.
    {allocate, 0, 0}.
    {move, {literal, <<"service">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Service}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-6-', 0, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-6-'}, 0}.
  {label, 72}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, bp_load_cases_typeinfo_all_list@main@@Orders, make, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-7-', 0, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-7-'}, 0}.
  {label, 74}.
    {allocate, 0, 0}.
    {move, {literal, <<"sql">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Store}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-8-', 0, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-8-'}, 0}.
  {label, 76}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, bp_load_cases_typeinfo_all_list@main@@Mailer, make, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-9-', 0, 78}.
  {label, 77}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-9-'}, 0}.
  {label, 78}.
    {allocate, 0, 0}.
    {move, {literal, <<"service">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Service}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-10-', 1, 80}.
  {label, 79}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-10-'}, 1}.
  {label, 80}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"]">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 81}, [{x, 0}, 7, {atom, bp_load_cases_typeinfo_all_list@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 4, {x, 0}}.
  {label, 81}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" [">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 7, {atom, bp_load_cases_typeinfo_all_list@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 82}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Service">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 11}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 83}, [{x, 0}, 7, {atom, bp_load_cases_typeinfo_all_list@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 6, {x, 0}}.
  {label, 83}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"bp_load__cases__typeinfo_all_list@main@@Audited">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 15}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 2}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 84}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 84}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:54:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 85}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 86}, [{x, 0}, 7, {atom, bp_load_cases_typeinfo_all_list@main@@Declared}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 86}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 26}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '-main/0-fun-11-', 0, 88}.
  {label, 87}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-11-'}, 0}.
  {label, 88}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, bp_load_cases_typeinfo_all_list@main@@Billing, make, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-12-', 0, 90}.
  {label, 89}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-12-'}, 0}.
  {label, 90}.
    {allocate, 0, 0}.
    {move, {literal, <<"yes">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Audited}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-13-', 0, 92}.
  {label, 91}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-13-'}, 0}.
  {label, 92}.
    {allocate, 0, 0}.
    {move, {literal, <<"service">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Service}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-14-', 0, 94}.
  {label, 93}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-14-'}, 0}.
  {label, 94}.
    {allocate, 0, 0}.
    {call_ext, 0, {extfunc, bp_load_cases_typeinfo_all_list@main@@Mailer, make, 0}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-15-', 0, 96}.
  {label, 95}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-main/0-fun-15-'}, 0}.
  {label, 96}.
    {allocate, 0, 0}.
    {move, {literal, <<"service">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_typeinfo_all_list@main@@Service}, {x, 0}]}}.
    {deallocate, 0}.
    return.

{function, '-declared__metaAll__Service/2-fun-16-', 3, 98}.
  {label, 97}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-declared__metaAll__Service/2-fun-16-'}, 3}.
  {label, 98}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 100}, [{x, 0}, 3, {atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 100}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 101}, [{x, 0}, 3, {atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 101}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_function2, {f, 103}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {atom, false}, {x, 0}}.
  {label, 104}.
    {test, is_eq, {f, 102}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 105}}.
  {label, 102}.
  {label, 105}.
    {jump, {f, 106}}.
  {label, 99}.
  {label, 106}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '-declared__metaAll__Store/2-fun-17-', 3, 108}.
  {label, 107}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-declared__metaAll__Store/2-fun-17-'}, 3}.
  {label, 108}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 110}, [{x, 0}, 3, {atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 110}.
    {test, is_eq_exact, {f, 109}, [{x, 0}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 111}, [{x, 0}, 3, {atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 111}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_function2, {f, 113}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {atom, false}, {x, 0}}.
  {label, 114}.
    {test, is_eq, {f, 112}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 115}}.
  {label, 112}.
  {label, 115}.
    {jump, {f, 116}}.
  {label, 109}.
  {label, 116}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.

{function, '-declared__metaAll__Audited/2-fun-18-', 3, 118}.
  {label, 117}.
    {line, [{location, "bp_load_cases_typeinfo_all_list@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_typeinfo_all_list@main}, {atom, '-declared__metaAll__Audited/2-fun-18-'}, 3}.
  {label, 118}.
    {allocate, 6, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 120}, [{x, 0}, 3, {atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 120}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {y, 2}]}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 121}, [{x, 0}, 3, {atom, bp_load_cases_typeinfo_all_list@main@@DeclaredTypedMeta}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 121}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_function2, {f, 123}, [{x, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {atom, false}, {x, 0}}.
  {label, 124}.
    {test, is_eq, {f, 122}, [{x, 0}, {atom, true}]}.
    {move, {y, 3}, {x, 0}}.
    {call_fun, 0}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, append, 2}}.
    {move, {x, 0}, {y, 1}}.
    {jump, {f, 125}}.
  {label, 122}.
  {label, 125}.
    {jump, {f, 126}}.
  {label, 119}.
  {label, 126}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 6}.
    return.
