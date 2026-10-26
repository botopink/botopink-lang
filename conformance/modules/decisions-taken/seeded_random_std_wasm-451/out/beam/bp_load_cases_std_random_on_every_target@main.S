{module, bp_load_cases_std_random_on_every_target@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_all', 2}, {'__bp_priv__array_fold', 3}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}, {'__bp_priv__string_slice', 3}]}.
{attributes, []}.
{labels, 220}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 22}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 23}}.
  {label, 22}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 24}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 4}}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 3}, {integer, 2}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call, 2, {f, 27}}.
  {label, 25}.
  {label, 23}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 28}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 29}}.
  {label, 28}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 27}}.
    {jump, {f, 31}}.
  {label, 30}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 27}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 27}}.
  {label, 31}.
  {label, 29}.
    {deallocate, 6}.
    return.
%%% `std/io/random` on all four targets (decision 238, `01-compiler/05-wasm`
%%% step 5): on wasm `float` is `std: "random.float"`, `seed` / `seededFloat`
%%% std-wasm's seeded stream, bound by `std:` cells (decision 451: the
%%% commonJS sidecar's Mulberry32 — the same draws after the same `seed`;
%%% erlang's `exsplus` draws others), and `shuffle`, `secureToken`, `uuidV4` and `randomBytes`
%%% private `fn:` bodies — a selection shuffle over one-element slices, bytes
%%% drawn from `random_get`. Each line prints what every target agrees on.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 45, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}]}}.
    {call_ext, 0, {extfunc, std@io@random, float, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_ge, {f, 32}, [{y, 0}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, false}, {x, 0}}.
  {label, 33}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 34}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 36}, [{y, 0}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 37}}.
  {label, 36}.
    {move, {atom, false}, {x, 0}}.
  {label, 37}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {atom, false}, {x, 0}}.
  {label, 35}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {call_ext, 0, {extfunc, std@io@random, seededFloat, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_ge, {f, 66}, [{y, 1}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {atom, false}, {x, 0}}.
  {label, 67}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 68}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 70}, [{y, 1}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, false}, {x, 0}}.
  {label, 71}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {atom, false}, {x, 0}}.
  {label, 69}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {integer, 42}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, seed, 1}}.
    {call_ext, 0, {extfunc, std@io@random, seededFloat, 0}}.
    {move, {x, 0}, {y, 2}}.
    {call_ext, 0, {extfunc, std@io@random, seededFloat, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 42}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, seed, 1}}.
    {call_ext, 0, {extfunc, std@io@random, seededFloat, 0}}.
    {test, is_eq_exact, {f, 72}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, false}, {x, 0}}.
  {label, 73}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_ne_exact, {f, 74}, [{y, 2}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, false}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {test, is_ge, {f, 76}, [{y, 2}, {float, 0.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, false}, {x, 0}}.
  {label, 77}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 78}, [{x, 1}, {atom, true}]}.
    {test, is_lt, {f, 80}, [{y, 2}, {float, 1.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {atom, false}, {x, 0}}.
  {label, 81}.
    {jump, {f, 79}}.
  {label, 78}.
    {move, {atom, false}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, shuffle, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 85}, 0, 0, {x, 0}, {list, []}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {move, {y, 5}, {x, 0}}.
    {call, 3, {f, 83}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 5}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 92}, 0, 0, {x, 0}, {list, [{y, 5}]}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 90}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, shuffle, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"c">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, shuffle, 1}}.
    {move, {x, 0}, {y, 9}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 93}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {jump, {f, 94}}.
  {label, 93}.
    {move, {atom, false}, {x, 0}}.
  {label, 94}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 95}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"c">>}, {x, 0}}.
    {move, {y, 9}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {atom, false}, {x, 0}}.
  {label, 96}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {integer, 32}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, secureToken, 1}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 97}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 98}}.
  {label, 97}.
    {move, {atom, true}, {x, 0}}.
  {label, 98}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 99}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"/">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 101}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {atom, true}, {x, 0}}.
  {label, 102}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {atom, true}, {x, 0}}.
  {label, 100}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 103}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"=">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 105}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 106}}.
  {label, 105}.
    {move, {atom, true}, {x, 0}}.
  {label, 106}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {atom, true}, {x, 0}}.
  {label, 104}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, secureToken, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 107}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 108}}.
  {label, 107}.
    {move, {atom, false}, {x, 0}}.
  {label, 108}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {integer, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, secureToken, 1}}.
    {move, {x, 0}, {y, 11}}.
    {move, {integer, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, secureToken, 1}}.
    {test, is_ne_exact, {f, 109}, [{y, 11}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 110}}.
  {label, 109}.
    {move, {atom, false}, {x, 0}}.
  {label, 110}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {call_ext, 0, {extfunc, std@io@random, uuidV4, 0}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 12}, {x, 0}}.
    {call, 2, {f, 112}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 129}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 12}, {x, 0}}.
    {call, 2, {f, 112}}.
    {move, {integer, 2}, {x, 1}}.
    {call, 2, {f, 132}}.
    {test, is_ne_exact, {f, 130}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 135}}.
  {label, 130}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 135}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"4">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 136}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 137}}.
  {label, 136}.
    {move, {atom, true}, {x, 0}}.
  {label, 137}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {literal, <<"89ab">>}, {x, 0}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 12}, {x, 0}}.
    {call, 2, {f, 112}}.
    {move, {integer, 3}, {x, 1}}.
    {call, 2, {f, 132}}.
    {test, is_ne_exact, {f, 140}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 141}}.
  {label, 140}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 141}.
    {move, {integer, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call, 3, {f, 139}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 142}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 143}}.
  {label, 142}.
    {move, {atom, true}, {x, 0}}.
  {label, 143}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 12}, {x, 0}}.
    {call, 2, {f, 112}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 145}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 90}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {integer, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, randomBytes, 1}}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 16}, {x, 0}}.
    {call, 2, {f, 112}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 149}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 90}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {integer, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@io@random, randomBytes, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {test, is_eq_exact, {f, 152}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 153}}.
  {label, 152}.
    {move, {atom, false}, {x, 0}}.
  {label, 153}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, std@io@random, intInRange, 2}}.
    {move, {x, 0}, {y, 17}}.
    {test, is_ge, {f, 154}, [{y, 17}, {integer, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 155}}.
  {label, 154}.
    {move, {atom, false}, {x, 0}}.
  {label, 155}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 156}, [{x, 1}, {atom, true}]}.
    {test, is_ge, {f, 158}, [{integer, 6}, {y, 17}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 159}}.
  {label, 158}.
    {move, {atom, false}, {x, 0}}.
  {label, 159}.
    {jump, {f, 157}}.
  {label, 156}.
    {move, {atom, false}, {x, 0}}.
  {label, 157}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 39}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 45}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {call, 0, {f, 7}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/std_random_on_every_target|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 19}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, '__bp_load_siblings', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_std_random_on_every_target@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 160}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 21}, 0}.
  {label, 160}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 21}.
    {test, is_nonempty_list, {f, 161}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 162}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 164}}.
  {label, 162}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 163}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 164}}.
  {label, 163}.
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
  {label, 164}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 21}, 2}.
  {label, 161}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, 'array_fold', 3, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, 'array_fold'}, 3}.
  {label, 83}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {move, {x, 0}, {x, 2}}.
    {test_heap, {alloc, [{words, 1}, {floats, 0}, {funs, 1}]}, 3}.
    {make_fun3, {f, 166}, 0, 0, {x, 0}, {list, [{y, 2}]}}.
    {call_ext, 3, {extfunc, lists, foldl, 3}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, 'array_all', 2, 90}.
  {label, 89}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, 'array_all'}, 2}.
  {label, 90}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, filter, 2}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {gc_bif, length, {f, 0}, 2, [{x, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 167}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 168}}.
  {label, 167}.
    {move, {atom, false}, {x, 0}}.
  {label, 168}.
    {deallocate, 2}.
    return.

{function, 'string_slice', 3, 139}.
  {label, 138}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, 'string_slice'}, 3}.
  {label, 139}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 169}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 171}, 3}.
  {label, 169}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 193}, 3}.

{function, '__bp_priv__array_all', 2, 211}.
  {label, 210}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_priv__array_all'}, 2}.
  {label, 211}.
    {call_only, 2, {f, 90}}.

{function, '__bp_priv__array_fold', 3, 213}.
  {label, 212}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_priv__array_fold'}, 3}.
  {label, 213}.
    {call_only, 3, {f, 83}}.

{function, '__bp_priv__array_range', 2, 215}.
  {label, 214}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 215}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 217}.
  {label, 216}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 217}.
    {call_only, 2, {f, 5}}.

{function, '__bp_priv__string_slice', 3, 219}.
  {label, 218}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_priv__string_slice'}, 3}.
  {label, 219}.
    {call_only, 3, {f, 139}}.

{function, '__bp_print', 1, 39}.
  {label, 38}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_print'}, 1}.
  {label, 39}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 43}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 43}.
  {label, 42}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 43}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 41}}.

{function, '-bp_show_elem-', 1, 45}.
  {label, 44}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 45}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 41}}.

{function, '__bp_show', 2, 41}.
  {label, 40}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_show'}, 2}.
  {label, 41}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 53}, [{x, 0}]}.
    {test, is_eq, {f, 52}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 54}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 54}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 56}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 55}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 55}, [{x, 0}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 61}}.
  {label, 60}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 61}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 41}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 45}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 58}, [{x, 0}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, undefined}]}.
  {label, 57}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 47}, 2}.
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 59}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 47}.
  {label, 46}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_tagged'}, 2}.
  {label, 47}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 62}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 62}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 62}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 49}, 3}.
  {label, 63}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 49}.
  {label, 48}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_render'}, 1}.
  {label, 49}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 64}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 64}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 65}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 51}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 51}.
  {label, 50}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 51}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 41}}.
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

{function, '__bp_add', 2, 87}.
  {label, 86}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_add'}, 2}.
  {label, 87}.
    {test, is_binary, {f, 88}, [{x, 0}]}.
    {test, is_binary, {f, 88}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 88}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '-main/0-fun-0-', 2, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-main/0-fun-0-'}, 2}.
  {label, 85}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call, 2, {f, 87}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-1-', 2, 92}.
  {label, 91}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-main/0-fun-1-'}, 2}.
  {label, 92}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, member, 2}}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 116}.
  {label, 115}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 116}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 120}, [{x, 0}]}.
    {jump, {f, 121}}.
  {label, 120}.
    {test, is_tuple, {f, 122}, [{x, 0}]}.
    {test, test_arity, {f, 122}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 121}}.
  {label, 122}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 121}.
    {move, {x, 0}, {y, 4}}.
  {label, 123}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 124}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 126}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 126}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 127}}.
  {label, 126}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 127}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 123}}.
  {label, 124}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 125}, [{x, 0}]}.
    {jump, {f, 119}}.
  {label, 125}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 119}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 118}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_0', 2, 112}.
  {label, 111}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_tpl_0'}, 2}.
  {label, 112}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 116}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-main/0-fun-2-', 1, 129}.
  {label, 128}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-main/0-fun-2-'}, 1}.
  {label, 129}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {deallocate, 1}.
    return.

{function, '-bp_at-', 2, 132}.
  {label, 131}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-bp_at-'}, 2}.
  {label, 132}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 134}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 133}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 134}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 133}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 133}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '-main/0-fun-3-', 1, 145}.
  {label, 144}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-main/0-fun-3-'}, 1}.
  {label, 145}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0123456789abcdef-">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 146}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 147}}.
  {label, 146}.
    {move, {atom, true}, {x, 0}}.
  {label, 147}.
    {deallocate, 1}.
    return.

{function, '-main/0-fun-4-', 1, 149}.
  {label, 148}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-main/0-fun-4-'}, 1}.
  {label, 149}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"0123456789abcdef">>}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, binary, match, 2}}.
    {test, is_eq, {f, 150}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 151}}.
  {label, 150}.
    {move, {atom, true}, {x, 0}}.
  {label, 151}.
    {deallocate, 1}.
    return.

{function, '-fold/3-fun-5-', 3, 166}.
  {label, 165}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '-fold/3-fun-5-'}, 3}.
  {label, 166}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1-t/3-fun-0-', 3, 175}.
  {label, 174}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_tpl_1-t/3-fun-0-'}, 3}.
  {label, 175}.
    {allocate, 9, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {x, 2}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 179}}.
  {label, 179}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 181}}.
  {label, 181}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 183}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 182}}.
  {label, 183}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 184}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 182}}.
  {label, 184}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 182}.
    {move, {y, 7}, {y, 2}}.
    {jump, {f, 186}}.
  {label, 186}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 188}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 187}}.
  {label, 188}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 189}, [{x, 0}, {atom, false}]}.
    {move, {y, 5}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {y, 7}}.
    {jump, {f, 187}}.
  {label, 189}.
    {move, {y, 6}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 187}.
    {move, {y, 7}, {y, 1}}.
    {jump, {f, 191}}.
  {label, 191}.
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

{function, '__bp_tpl_1', 3, 171}.
  {label, 170}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_tpl_1'}, 3}.
  {label, 171}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 175}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_2-t/2-fun-0-', 2, 197}.
  {label, 196}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_tpl_2-t/2-fun-0-'}, 2}.
  {label, 197}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 201}}.
  {label, 201}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 203}}.
  {label, 203}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 205}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 204}}.
  {label, 205}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 206}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 204}}.
  {label, 206}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 204}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 208}}.
  {label, 208}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_2', 2, 193}.
  {label, 192}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_tpl_2'}, 2}.
  {label, 193}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 197}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_prim_append', 2, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_std_random_on_every_target@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_std_random_on_every_target@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 27}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 209}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 209}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
