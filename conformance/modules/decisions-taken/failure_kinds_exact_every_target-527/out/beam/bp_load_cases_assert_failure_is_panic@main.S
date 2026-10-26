{module, bp_load_cases_assert_failure_is_panic@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__named', 2}, {'__bp_priv__positive', 1}, {'__bp_priv__show', 1}]}.
{attributes, []}.
{labels, 88}.
%%% Decision 527 (2) — a failing `assert` is a `panic` whose message names the
%%% asserted condition as written and where it failed, the same on every
%%% target: `assertion failed: <condition> at <file>:<line>:<col>`, the
%%% program's message after the condition when it wrote one. `attempt`
%%% contains it like any panic; the program goes on.

{function, positive, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, positive}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 24}, [{integer, 0}, {y, 0}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {literal, <<"assertion failed">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"src/main.bp:10">>}, {x, 2}}.
    {move, {literal, <<"assertion failed: x > 0 at src/main.bp:10:5">>}, {x, 3}}.
    {test_heap, 5, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {x, 1}, {x, 2}, {x, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 25}.
    {move, {atom, ok}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, named, 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, named}, 2}.
  {label, 5}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_lt, {f, 28}, [{integer, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {move, {atom, false}, {x, 0}}.
  {label, 29}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 30}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"a\"b">>}, {x, 0}}.
    {test, is_ne_exact, {f, 32}, [{y, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, false}, {x, 0}}.
  {label, 33}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {atom, false}, {x, 0}}.
  {label, 31}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {atom, true}]}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {literal, <<"x must be positive">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"src/main.bp:15">>}, {x, 2}}.
    {test_heap, 9, 3}.
    {put_list, {x, 1}, {literal, [<<" at src/main.bp:15:5">>]}, {x, 3}}.
    {put_list, {literal, <<"assertion failed: x > 0 && s != \"a\\\"b\": ">>}, {x, 3}, {x, 3}}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {x, 1}, {x, 2}, {x, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 27}.
    {move, {atom, ok}, {x, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, show, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, show}, 1}.
  {label, 7}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 35}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"Ok ">>}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 37}}.
    {jump, {f, 34}}.
  {label, 35}.
    {test, is_tagged_tuple, {f, 68}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 3}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 69}, [{x, 0}, 3, {atom, std@failure@@Failure}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 69}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<": ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_tagged_tuple, {f, 70}, [{x, 0}, 3, {atom, std@failure@@Failure}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 70}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"Error ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 37}}.
    {jump, {f, 34}}.
  {label, 68}.
    {case_end, {x, 0}}.
  {label, 34}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, main, 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, main}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 72}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 7}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 74}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 7}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 1, {extfunc, std@failure, attempt, 1}}.
    {call, 1, {f, 7}}.
    {move, {literal, <<"after">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 37}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {call, 0, {f, 9}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/assert_failure_is_panic|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '_botopink_main'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 21}}.
    {call_last, 0, {f, 9}, 0}.

{function, main, 1, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, main}, 1}.
  {label, 19}.
    {call_only, 0, {f, 17}}.

{function, '__bp_load_siblings', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_assert_failure_is_panic@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 77}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 23}, 0}.
  {label, 77}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 23}.
    {test, is_nonempty_list, {f, 78}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 79}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 81}}.
  {label, 79}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 80}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 81}}.
  {label, 80}.
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
  {label, 81}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 23}, 2}.
  {label, 78}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_priv__named', 2, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_priv__named'}, 2}.
  {label, 83}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__positive', 1, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_priv__positive'}, 1}.
  {label, 85}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__show', 1, 87}.
  {label, 86}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_priv__show'}, 1}.
  {label, 87}.
    {call_only, 1, {f, 7}}.

{function, '__bp_print', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_print'}, 1}.
  {label, 37}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 41}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 39}}.

{function, '-bp_show_elem-', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 43}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 39}}.

{function, '__bp_show', 2, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_show'}, 2}.
  {label, 39}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 51}, [{x, 0}]}.
    {test, is_eq, {f, 50}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 52}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 54}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 53}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 53}, [{x, 0}]}.
    {test, is_ne_exact, {f, 53}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 53}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 53}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 59}}.
  {label, 58}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 59}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 39}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 56}, [{x, 0}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 57}, [{x, 0}, {atom, undefined}]}.
  {label, 55}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 45}, 2}.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 57}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_tagged'}, 2}.
  {label, 45}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 60}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 60}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 60}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 47}, 3}.
  {label, 61}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '__bp_render'}, 1}.
  {label, 47}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 62}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 63}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 49}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 49}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 39}}.
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

{function, '-bp_stringify-', 1, 65}.
  {label, 64}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 65}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 66}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 66}.
    {test, is_integer, {f, 67}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 67}.
    {call, 1, {f, 41}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-main/0-fun-0-', 0, 72}.
  {label, 71}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-main/0-fun-0-'}, 0}.
  {label, 72}.
    {allocate, 0, 0}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-1-', 0, 74}.
  {label, 73}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-main/0-fun-1-'}, 0}.
  {label, 74}.
    {allocate, 0, 0}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {deallocate, 0}.
    return.

{function, '-main/0-fun-2-', 0, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_assert_failure_is_panic@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_assert_failure_is_panic@main}, {atom, '-main/0-fun-2-'}, 0}.
  {label, 76}.
    {allocate, 0, 0}.
    {move, {literal, <<"z">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {deallocate, 0}.
    return.
