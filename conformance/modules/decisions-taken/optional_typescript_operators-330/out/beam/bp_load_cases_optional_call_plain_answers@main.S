{module, bp_load_cases_optional_call_plain_answers@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__checker', 1}, {'__bp_priv__counter', 1}, {'__bp_priv__greeter', 1}, {'__bp_priv__maker', 1}]}.
{attributes, []}.
{labels, 130}.
%%% Decision 330 — `f?.(args)` over a function answering a plain value is
%%% that value's optional: absent when the optional holding the function is,
%%% the function's answer otherwise — a present `0` included — whatever the
%%% answer's type (an integer, a string, a bool, a record).

{function, counter, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, counter}, 1}.
  {label, 3}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 26}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 27}.
    {deallocate, 2}.
    return.

{function, greeter, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, greeter}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 62}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 63}.
    {deallocate, 2}.
    return.

{function, checker, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, checker}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 68}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 69}.
    {deallocate, 2}.
    return.

{function, maker, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, maker}, 1}.
  {label, 9}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 71}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 74}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 75}.
    {deallocate, 2}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 31, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}]}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 77}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 6}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 78}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 76}.
    {move, {integer, -1}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 82}}.
  {label, 81}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 82}.
    {test, is_ne_exact, {f, 80}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 80}.
    {move, {integer, -1}, {x, 0}}.
  {label, 83}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 85}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 86}.
    {test, is_ne_exact, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 87}}.
  {label, 84}.
    {move, {integer, -1}, {x, 0}}.
  {label, 87}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 88}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 89}}.
  {label, 88}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 89}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 90}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 12}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 91}}.
  {label, 90}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 91}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 93}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 94}}.
  {label, 93}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 94}.
    {test, is_ne_exact, {f, 92}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 95}}.
  {label, 92}.
    {move, {literal, <<"nobody">>}, {x, 0}}.
  {label, 95}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 97}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {move, {y, 17}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 98}}.
  {label, 97}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 98}.
    {test, is_ne_exact, {f, 96}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {jump, {f, 99}}.
  {label, 96}.
    {move, {literal, <<"nobody">>}, {x, 0}}.
  {label, 99}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 101}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 20}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 102}.
    {test, is_ne_exact, {f, 100}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {jump, {f, 103}}.
  {label, 100}.
    {move, {atom, false}, {x, 0}}.
  {label, 103}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 105}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {move, {x, 0}, {y, 23}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {y, 23}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 106}}.
  {label, 105}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 106}.
    {test, is_ne_exact, {f, 104}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 24}}.
    {move, {y, 24}, {x, 0}}.
    {jump, {f, 107}}.
  {label, 104}.
    {move, {atom, true}, {x, 0}}.
  {label, 107}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 109}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 25}, {x, 0}}.
    {move, {x, 0}, {y, 26}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 26}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 110}}.
  {label, 109}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 110}.
    {test, is_eq, {f, 111}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 113}}.
  {label, 111}.
    {test, is_tagged_tuple, {f, 112}, [{x, 0}, 3, {atom, bp_load_cases_optional_call_plain_answers@main@@Point}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 113}}.
  {label, 112}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 113}.
    {test, is_ne_exact, {f, 108}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 108}.
    {move, {integer, -1}, {x, 0}}.
  {label, 114}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 116}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 28}}.
    {move, {y, 28}, {x, 0}}.
    {move, {x, 0}, {y, 29}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 29}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 117}}.
  {label, 116}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 117}.
    {test, is_eq, {f, 118}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 120}}.
  {label, 118}.
    {test, is_tagged_tuple, {f, 119}, [{x, 0}, 3, {atom, bp_load_cases_optional_call_plain_answers@main@@Point}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 120}}.
  {label, 119}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 120}.
    {test, is_ne_exact, {f, 115}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 30}}.
    {move, {y, 30}, {x, 0}}.
    {jump, {f, 121}}.
  {label, 115}.
    {move, {integer, -1}, {x, 0}}.
  {label, 121}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 31}.
    return.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {call, 0, {f, 11}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_call_plain_answers|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__checker', 1, 123}.
  {label, 122}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_priv__checker'}, 1}.
  {label, 123}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__counter', 1, 125}.
  {label, 124}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_priv__counter'}, 1}.
  {label, 125}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__greeter', 1, 127}.
  {label, 126}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_priv__greeter'}, 1}.
  {label, 127}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__maker', 1, 129}.
  {label, 128}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_priv__maker'}, 1}.
  {label, 129}.
    {call_only, 1, {f, 9}}.

{function, '-counter/1-fun-0-', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-counter/1-fun-0-'}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {integer, 5}], {x, 0}}.
    {test, is_ge, {f, 24}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 24}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i32 at src/main.bp:11:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 25}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_print'}, 1}.
  {label, 31}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 35}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '-bp_show_elem-', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 37}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '__bp_show', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_show'}, 2}.
  {label, 33}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 45}, [{x, 0}]}.
    {test, is_eq, {f, 44}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 46}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 48}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 47}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 47}, [{x, 0}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 47}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 53}}.
  {label, 52}.
    {test, is_eq_exact, {f, 49}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 53}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 37}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 50}, [{x, 0}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 50}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, undefined}]}.
  {label, 49}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 39}, 2}.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 51}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_tagged'}, 2}.
  {label, 39}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 54}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 54}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 41}, 3}.
  {label, 55}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '__bp_render'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 56}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 57}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 43}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 33}}.
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

{function, '-bp_stringify-', 1, 59}.
  {label, 58}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 59}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 60}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 60}.
    {test, is_integer, {f, 61}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 61}.
    {call, 1, {f, 35}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-greeter/1-fun-1-', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-greeter/1-fun-1-'}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"hi ">>}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 59}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '-checker/1-fun-2-', 1, 65}.
  {label, 64}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-checker/1-fun-2-'}, 1}.
  {label, 65}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 66}, [{y, 0}, {integer, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {atom, false}, {x, 0}}.
  {label, 67}.
    {deallocate, 1}.
    return.

{function, '-maker/1-fun-3-', 1, 71}.
  {label, 70}.
    {line, [{location, "bp_load_cases_optional_call_plain_answers@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_call_plain_answers@main}, {atom, '-maker/1-fun-3-'}, 1}.
  {label, 71}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 72}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 72}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i32 at src/main.bp:26:55">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 73}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_call_plain_answers@main@@Point}, {y, 0}, {x, 0}]}}.
    {deallocate, 1}.
    return.
