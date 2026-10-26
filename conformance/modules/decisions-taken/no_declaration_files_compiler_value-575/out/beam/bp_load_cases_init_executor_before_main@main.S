{module, bp_load_cases_init_executor_before_main@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {'_botopink_init', 0}, {hello, 0}, {greet, 0}, {home, 0}, {'__bp_executor_0', 0}, {'__bp_init_0', 0}, {'__bp_executor_1', 0}, {'__bp_init_1', 0}, {'__bp_executor_2', 0}, {'__bp_init_2', 0}, {'__bp_executor_3', 0}, {'__bp_init_3', 0}, {'__bp_executor_4', 0}, {'__bp_init_4', 0}, {'__bp_executor_5', 0}, {'__bp_init_5', 0}, {banner, 0}, {'__bp_executor_6', 0}, {'__bp_init_6', 0}, {'__bp_executor_7', 0}, {'__bp_init_7', 0}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}]}.
{attributes, []}.
{labels, 97}.
%%% Decision 575 (3) — `compiler.init(executor)`: run-time code a decorator
%%% compiles beside the annotated declaration, run once before `main` in the
%%% program's init list — declarations in source order, the calls of one body
%%% in order, any number per declaration. The executor is a tree (575 (4)):
%%% the `comptime` parameter `label` and the body's `val name` are spliced as
%%% literals. An executor may be named instead of written at the call: a
%%% function of the decorator's module (`hello`), or a `syntax` parameter
%%% (`run`), spliced as the annotation wrote it.

{function, hello, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, hello}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, greet, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, greet}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {literal, <<"greet">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, home, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, home}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {move, {literal, <<"home">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_0', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_0'}, 0}.
  {label, 9}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"home">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"page">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_0', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_0'}, 0}.
  {label, 11}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_0'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 9}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 88}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_1', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_1'}, 0}.
  {label, 13}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"home">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"again ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_1', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_1'}, 0}.
  {label, 15}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_1'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 89}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 13}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 89}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_2', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_2'}, 0}.
  {label, 17}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Shell">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"layout">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_2', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_2'}, 0}.
  {label, 19}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_2'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 90}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 17}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 90}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_3', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_3'}, 0}.
  {label, 21}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Shell">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"again ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_3', 0, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_3'}, 0}.
  {label, 23}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_3'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 21}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 91}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_4', 0, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_4'}, 0}.
  {label, 25}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Shell">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"view">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_4', 0, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_4'}, 0}.
  {label, 27}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_4'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 25}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_4'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 92}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_5', 0, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_5'}, 0}.
  {label, 29}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"Shell">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"again ">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_init_5', 0, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_5'}, 0}.
  {label, 31}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_5'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 29}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_5'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 93}.
    {deallocate, 1}.
    return.

{function, banner, 0, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, banner}, 0}.
  {label, 33}.
    {allocate, 0, 0}.
    {move, {literal, <<"banner">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_executor_6', 0, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_6'}, 0}.
  {label, 35}.
    {allocate, 0, 0}.
    {call, 0, {f, 3}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_init_6', 0, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_6'}, 0}.
  {label, 37}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_6'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 35}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_6'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 94}.
    {deallocate, 1}.
    return.

{function, '__bp_executor_7', 0, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_executor_7'}, 0}.
  {label, 39}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_init_7', 0, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 20}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_init_7'}, 0}.
  {label, 41}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_7'}}, {x, 0}}.
    {move, {atom, '$bp_unset'}, {x, 1}}.
    {call_ext, 2, {extfunc, persistent_term, get, 2}}.
    {test, is_eq_exact, {f, 95}, [{x, 0}, {atom, '$bp_unset'}]}.
    {call, 0, {f, 39}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_7'}}, {x, 0}}.
    {call_ext, 2, {extfunc, persistent_term, put, 2}}.
    {move, {y, 0}, {x, 0}}.
  {label, 95}.
    {deallocate, 1}.
    return.

{function, main, 0, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 21}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, main}, 0}.
  {label, 43}.
    {allocate, 0, 0}.
    {move, {literal, <<"main">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {call, 0, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {literal, <<"t">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_init_executor_before_main@main@@Shell}, {x, 0}]}}.
    {test, is_tagged_tuple, {f, 96}, [{x, 0}, 2, {atom, bp_load_cases_init_executor_before_main@main@@Shell}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 96}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {call, 0, {f, 33}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 57}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 22}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 45}.
    {allocate, 0, 0}.
    {call, 0, {f, 55}}.
    {call, 0, {f, 43}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 23}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 47}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 24}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 49}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/init_executor_before_main|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 25}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '_botopink_main'}, 0}.
  {label, 51}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 11}}.
    {call, 0, {f, 15}}.
    {call, 0, {f, 19}}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 37}}.
    {call, 0, {f, 41}}.
    {call_last, 0, {f, 43}, 0}.

{function, main, 1, 53}.
  {label, 52}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 26}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, main}, 1}.
  {label, 53}.
    {call_only, 0, {f, 51}}.

{function, '_botopink_init', 0, 55}.
  {label, 54}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 27}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '_botopink_init'}, 0}.
  {label, 55}.
    {allocate, 0, 0}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_0'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_1'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_2'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_3'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_4'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_5'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_6'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {move, {literal, {bp_load_cases_init_executor_before_main@main, '__bp_init_7'}}, {x, 0}}.
    {call_ext, 1, {extfunc, persistent_term, erase, 1}}.
    {call, 0, {f, 11}}.
    {call, 0, {f, 15}}.
    {call, 0, {f, 19}}.
    {call, 0, {f, 23}}.
    {call, 0, {f, 27}}.
    {call, 0, {f, 31}}.
    {call, 0, {f, 37}}.
    {call, 0, {f, 41}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_print', 1, 57}.
  {label, 56}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_print'}, 1}.
  {label, 57}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 61}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 61}.
  {label, 60}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 61}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 59}}.

{function, '-bp_show_elem-', 1, 63}.
  {label, 62}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 63}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 59}}.

{function, '__bp_show', 2, 59}.
  {label, 58}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_show'}, 2}.
  {label, 59}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 71}, [{x, 0}]}.
    {test, is_eq, {f, 70}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 70}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 71}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 72}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 72}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 74}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 73}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 73}, [{x, 0}]}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 79}}.
  {label, 78}.
    {test, is_eq_exact, {f, 75}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 79}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 59}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 74}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 76}, [{x, 0}]}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 77}, [{x, 0}, {atom, undefined}]}.
  {label, 75}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 65}, 2}.
  {label, 76}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 77}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 65}.
  {label, 64}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_tagged'}, 2}.
  {label, 65}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 80}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 80}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 80}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 81}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 67}, 3}.
  {label, 81}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 67}.
  {label, 66}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '__bp_render'}, 1}.
  {label, 67}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 82}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 82}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 83}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 83}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 69}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 69}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 59}}.
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

{function, '-bp_stringify-', 1, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_init_executor_before_main@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_init_executor_before_main@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 85}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 86}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 86}.
    {test, is_integer, {f, 87}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 87}.
    {call, 1, {f, 61}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
