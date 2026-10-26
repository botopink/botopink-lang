{module, bp_load_cases_nullish_optional_call_default@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__backup', 1}, {'__bp_priv__greeter', 1}, {'__bp_priv__nickname', 1}, {'__bp_priv__primary', 1}]}.
{attributes, []}.
{labels, 130}.
%%% Decision 330 — the default of `??` may itself be a `?.()` call, defaulted
%%% again by a further `??`: `a ?? f?.(x) ?? d` takes the first present value,
%%% and a default is evaluated only when everything before it is absent, on
%%% every target.

{function, primary, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, primary}, 1}.
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

{function, backup, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, backup}, 1}.
  {label, 5}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"backup">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 57}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 60}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 61}.
    {deallocate, 2}.
    return.

{function, greeter, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, greeter}, 1}.
  {label, 7}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 63}, 0, 0, {x, 0}, {list, []}}.
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

{function, nickname, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, nickname}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 70}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 71}.
    {deallocate, 1}.
    return.

{function, main, 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, main}, 0}.
  {label, 11}.
    {allocate, 35, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}]}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 74}.
    {test, is_ne_exact, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 72}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 77}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 78}.
    {test, is_ne_exact, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 76}.
    {move, {integer, -1}, {x, 0}}.
  {label, 79}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 7}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 82}}.
  {label, 81}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 82}.
    {test, is_ne_exact, {f, 80}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 80}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 85}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 86}.
    {test, is_ne_exact, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 87}}.
  {label, 84}.
    {move, {integer, -1}, {x, 0}}.
  {label, 87}.
  {label, 83}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_ne_exact, {f, 89}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {move, {x, 0}, {y, 13}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 13}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 90}.
    {test, is_ne_exact, {f, 88}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {jump, {f, 91}}.
  {label, 88}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test, is_ne_exact, {f, 93}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {move, {x, 0}, {y, 16}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 16}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 94}}.
  {label, 93}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 94}.
    {test, is_ne_exact, {f, 92}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {jump, {f, 95}}.
  {label, 92}.
    {move, {integer, -1}, {x, 0}}.
  {label, 95}.
  {label, 91}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 96}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 18}}.
    {move, {y, 18}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 96}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 99}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 19}}.
    {move, {y, 19}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, {literal, <<"you">>}, {x, 0}}.
    {move, {y, 20}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 100}.
    {test, is_ne_exact, {f, 98}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 21}}.
    {move, {y, 21}, {x, 0}}.
    {jump, {f, 101}}.
  {label, 98}.
    {move, {literal, <<"nobody">>}, {x, 0}}.
  {label, 101}.
  {label, 97}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 102}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 22}}.
    {move, {y, 22}, {x, 0}}.
    {jump, {f, 103}}.
  {label, 102}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 105}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 23}}.
    {move, {y, 23}, {x, 0}}.
    {move, {x, 0}, {y, 24}}.
    {move, {literal, <<"you">>}, {x, 0}}.
    {move, {y, 24}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 106}}.
  {label, 105}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 106}.
    {test, is_ne_exact, {f, 104}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 25}}.
    {move, {y, 25}, {x, 0}}.
    {jump, {f, 107}}.
  {label, 104}.
    {move, {literal, <<"nobody">>}, {x, 0}}.
  {label, 107}.
  {label, 103}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 108}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 26}}.
    {move, {y, 26}, {x, 0}}.
    {jump, {f, 109}}.
  {label, 108}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 111}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 27}}.
    {move, {y, 27}, {x, 0}}.
    {move, {x, 0}, {y, 28}}.
    {move, {literal, <<"you">>}, {x, 0}}.
    {move, {y, 28}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 112}.
    {test, is_ne_exact, {f, 110}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 29}}.
    {move, {y, 29}, {x, 0}}.
    {jump, {f, 113}}.
  {label, 110}.
    {move, {literal, <<"nobody">>}, {x, 0}}.
  {label, 113}.
  {label, 109}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_ne_exact, {f, 114}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 30}}.
    {move, {y, 30}, {x, 0}}.
    {jump, {f, 115}}.
  {label, 114}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 7}}.
    {test, is_ne_exact, {f, 117}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 31}}.
    {move, {y, 31}, {x, 0}}.
    {move, {x, 0}, {y, 32}}.
    {move, {literal, <<"all">>}, {x, 0}}.
    {move, {y, 32}, {x, 1}}.
    {call_fun, 1}.
    {jump, {f, 118}}.
  {label, 117}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 118}.
    {test, is_ne_exact, {f, 116}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 33}}.
    {move, {y, 33}, {x, 0}}.
    {jump, {f, 119}}.
  {label, 116}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 119}.
  {label, 115}.
    {move, {x, 0}, {y, 34}}.
    {move, {y, 34}, {x, 0}}.
    {call, 1, {f, 121}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 35}.
    return.

{function, '__bp_loaded_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/nullish_optional_call_default|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '_botopink_main'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 11}, 0}.

{function, main, 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, main}, 1}.
  {label, 21}.
    {call_only, 0, {f, 19}}.

{function, '__bp_priv__backup', 1, 123}.
  {label, 122}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_priv__backup'}, 1}.
  {label, 123}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__greeter', 1, 125}.
  {label, 124}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_priv__greeter'}, 1}.
  {label, 125}.
    {call_only, 1, {f, 7}}.

{function, '__bp_priv__nickname', 1, 127}.
  {label, 126}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_priv__nickname'}, 1}.
  {label, 127}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__primary', 1, 129}.
  {label, 128}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_priv__primary'}, 1}.
  {label, 129}.
    {call_only, 1, {f, 3}}.

{function, '-primary/1-fun-0-', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '-primary/1-fun-0-'}, 1}.
  {label, 23}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 10}], {x, 0}}.
    {test, is_ge, {f, 24}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 24}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:9:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 25}.
    {deallocate, 1}.
    return.

{function, '__bp_print', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_print'}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 33}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 31}}.

{function, '-bp_show_elem-', 1, 35}.
  {label, 34}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 35}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 31}}.

{function, '__bp_show', 2, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_show'}, 2}.
  {label, 31}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 43}, [{x, 0}]}.
    {test, is_eq, {f, 42}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 42}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 43}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 44}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 44}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 46}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 45}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 45}, [{x, 0}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 51}}.
  {label, 50}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 51}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 31}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 35}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 48}, [{x, 0}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 49}, [{x, 0}, {atom, undefined}]}.
  {label, 47}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 37}, 2}.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 49}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_tagged'}, 2}.
  {label, 37}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 52}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 52}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 52}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 39}, 3}.
  {label, 53}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_render'}, 1}.
  {label, 39}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 54}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 55}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 41}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 41}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 31}}.
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

{function, '-backup/1-fun-1-', 1, 57}.
  {label, 56}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '-backup/1-fun-1-'}, 1}.
  {label, 57}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 100}], {x, 0}}.
    {test, is_ge, {f, 58}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 58}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i32 at src/main.bp:15:38">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 59}.
    {deallocate, 1}.
    return.

{function, '-bp_stringify-', 1, 65}.
  {label, 64}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 65}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 66}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 66}.
    {test, is_integer, {f, 67}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 67}.
    {call, 1, {f, 33}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '-greeter/1-fun-2-', 1, 63}.
  {label, 62}.
    {line, [{location, "bp_load_cases_nullish_optional_call_default@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '-greeter/1-fun-2-'}, 1}.
  {label, 63}.
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
    {make_fun3, {f, 65}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0', 1, 121}.
  {label, 120}.
    {func_info, {atom, bp_load_cases_nullish_optional_call_default@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 121}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.
