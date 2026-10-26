{module, bp_load_cases_std_math_on_every_target@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}]}.
{attributes, []}.
{labels, 131}.
%%% `std/math` on all four targets (decision 238, `01-compiler/05-wasm` step 5):
%%% wasm binds `abs`, `floor`, `trunc`, `sqrt`, `minF` and `maxF` to one
%%% instruction each (`op:`) and every other host cell to a private botopink
%%% body (`fn:`) — `round` too, because `f64.nearest` rounds a half to even.
%%% erlang and beam run the same bodies (decision 263) and every target runs
%%% std's port of glibc's `pow` (decision 259), so no answer depends on the
%%% platform libm. Each line compares with the value `Math.*` answers on Linux,
%%% so the one `.out` is every target's on every OS: the targets print a float
%%% differently (`3` / `3.0`), and a truth value the same way.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 20, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}]}}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {float, 5.5}], {x, 0}}.
    {call_ext, 1, {extfunc, std@math, abs, 1}}.
    {test, is_eq_exact, {f, 18}, [{x, 0}, {float, 5.5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {atom, false}, {x, 0}}.
  {label, 19}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 3.7}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, floor, 1}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, {float, 3.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 49}}.
  {label, 48}.
    {move, {atom, false}, {x, 0}}.
  {label, 49}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 50}, [{x, 1}, {atom, true}]}.
    {move, {float, 3.2}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, ceil, 1}}.
    {test, is_eq_exact, {f, 52}, [{x, 0}, {float, 4.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {atom, false}, {x, 0}}.
  {label, 53}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {atom, false}, {x, 0}}.
  {label, 51}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {float, 2.9}], {x, 0}}.
    {call_ext, 1, {extfunc, std@math, trunc, 1}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{float, 0.0}, {float, 1.5}], {x, 0}}.
    {test, is_lt, {f, 54}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {atom, false}, {x, 0}}.
  {label, 55}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 56}, [{x, 1}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {float, 2.9}], {x, 0}}.
    {call_ext, 1, {extfunc, std@math, trunc, 1}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '-', {f, 0}, 2, [{float, 0.0}, {float, 2.5}], {x, 0}}.
    {test, is_lt, {f, 58}, [{x, 0}, {x, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {atom, false}, {x, 0}}.
  {label, 59}.
    {jump, {f, 57}}.
  {label, 56}.
    {move, {atom, false}, {x, 0}}.
  {label, 57}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 2.5}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, round, 1}}.
    {test, is_lt, {f, 60}, [{float, 2.5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {atom, false}, {x, 0}}.
  {label, 61}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 62}, [{x, 1}, {atom, true}]}.
    {move, {float, 2.5}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, round, 1}}.
    {test, is_lt, {f, 64}, [{x, 0}, {float, 3.5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {atom, false}, {x, 0}}.
  {label, 65}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, false}, {x, 0}}.
  {label, 63}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 0.49999999999999994}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, round, 1}}.
    {test, is_lt, {f, 66}, [{x, 0}, {float, 0.5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {atom, false}, {x, 0}}.
  {label, 67}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {float, 2.5}, {x, 1}}.
    {call_ext, 2, {extfunc, std@math, minF, 2}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {float, 1.5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {atom, false}, {x, 0}}.
  {label, 69}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 70}, [{x, 1}, {atom, true}]}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {float, 2.5}, {x, 1}}.
    {call_ext, 2, {extfunc, std@math, maxF, 2}}.
    {test, is_eq_exact, {f, 72}, [{x, 0}, {float, 2.5}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, false}, {x, 0}}.
  {label, 73}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, false}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 2.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, sqrt, 1}}.
    {test, is_eq_exact, {f, 74}, [{x, 0}, {float, 1.4142135623730951}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, false}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 3.0}, {x, 0}}.
    {move, {float, 4.0}, {x, 1}}.
    {call_ext, 2, {extfunc, std@math, hypot, 2}}.
    {test, is_eq_exact, {f, 76}, [{x, 0}, {float, 5.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, false}, {x, 0}}.
  {label, 77}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, exp, 1}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {float, 2.718281828459045}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 78}.
    {move, {atom, false}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 10.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, ln, 1}}.
    {test, is_eq_exact, {f, 80}, [{x, 0}, {float, 2.302585092994046}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {atom, false}, {x, 0}}.
  {label, 81}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 8.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, log2, 1}}.
    {test, is_eq_exact, {f, 82}, [{x, 0}, {float, 3.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, false}, {x, 0}}.
  {label, 83}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 84}, [{x, 1}, {atom, true}]}.
    {move, {float, 1000.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, log10, 1}}.
    {test, is_eq_exact, {f, 86}, [{x, 0}, {float, 3.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 87}}.
  {label, 86}.
    {move, {atom, false}, {x, 0}}.
  {label, 87}.
    {jump, {f, 85}}.
  {label, 84}.
    {move, {atom, false}, {x, 0}}.
  {label, 85}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 2.0}, {x, 0}}.
    {move, {float, 10.0}, {x, 1}}.
    {call_ext, 2, {extfunc, std@math, pow, 2}}.
    {test, is_eq_exact, {f, 88}, [{x, 0}, {float, 1024.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 89}}.
  {label, 88}.
    {move, {atom, false}, {x, 0}}.
  {label, 89}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 90}, [{x, 1}, {atom, true}]}.
    {move, {float, 2.0}, {x, 0}}.
    {move, {float, 0.5}, {x, 1}}.
    {call_ext, 2, {extfunc, std@math, pow, 2}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {float, 1.4142135623730951}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {atom, false}, {x, 0}}.
  {label, 93}.
    {jump, {f, 91}}.
  {label, 90}.
    {move, {atom, false}, {x, 0}}.
  {label, 91}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 1.5}, {x, 0}}.
    {move, {float, 7.3}, {x, 1}}.
    {call_ext, 2, {extfunc, std@math, pow, 2}}.
    {test, is_eq_exact, {f, 94}, [{x, 0}, {float, 19.295951155032366}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 95}}.
  {label, 94}.
    {move, {atom, false}, {x, 0}}.
  {label, 95}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 158.42161580281933}, {x, 0}}.
    {move, {float, 2.853827476501465}, {x, 1}}.
    {call_ext, 2, {extfunc, std@math, pow, 2}}.
    {test, is_eq_exact, {f, 96}, [{x, 0}, {float, 1896229.4525711867}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 97}}.
  {label, 96}.
    {move, {atom, false}, {x, 0}}.
  {label, 97}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, sin, 1}}.
    {test, is_eq_exact, {f, 98}, [{x, 0}, {float, 0.8414709848078965}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 99}}.
  {label, 98}.
    {move, {atom, false}, {x, 0}}.
  {label, 99}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 100}, [{x, 1}, {atom, true}]}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, cos, 1}}.
    {test, is_eq_exact, {f, 102}, [{x, 0}, {float, 0.5403023058681398}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 103}}.
  {label, 102}.
    {move, {atom, false}, {x, 0}}.
  {label, 103}.
    {jump, {f, 101}}.
  {label, 100}.
    {move, {atom, false}, {x, 0}}.
  {label, 101}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, tan, 1}}.
    {test, is_eq_exact, {f, 104}, [{x, 0}, {float, 1.5574077246549023}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 105}}.
  {label, 104}.
    {move, {atom, false}, {x, 0}}.
  {label, 105}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 0.5}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, asin, 1}}.
    {test, is_eq_exact, {f, 106}, [{x, 0}, {float, 0.5235987755982989}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 107}}.
  {label, 106}.
    {move, {atom, false}, {x, 0}}.
  {label, 107}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 108}, [{x, 1}, {atom, true}]}.
    {move, {float, 0.5}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, acos, 1}}.
    {test, is_eq_exact, {f, 110}, [{x, 0}, {float, 1.0471975511965979}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {atom, false}, {x, 0}}.
  {label, 111}.
    {jump, {f, 109}}.
  {label, 108}.
    {move, {atom, false}, {x, 0}}.
  {label, 109}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, atan, 1}}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {float, 0.7853981633974483}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 113}}.
  {label, 112}.
    {move, {atom, false}, {x, 0}}.
  {label, 113}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 114}, [{x, 1}, {atom, true}]}.
    {gc_bif, '-', {f, 0}, 0, [{float, 0.0}, {float, 1.0}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 2, {extfunc, std@math, atan2, 2}}.
    {test, is_eq_exact, {f, 116}, [{x, 0}, {float, 2.356194490192345}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 117}}.
  {label, 116}.
    {move, {atom, false}, {x, 0}}.
  {label, 117}.
    {jump, {f, 115}}.
  {label, 114}.
    {move, {atom, false}, {x, 0}}.
  {label, 115}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, sinh, 1}}.
    {test, is_eq_exact, {f, 118}, [{x, 0}, {float, 1.1752011936438014}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 119}}.
  {label, 118}.
    {move, {atom, false}, {x, 0}}.
  {label, 119}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq, {f, 120}, [{x, 1}, {atom, true}]}.
    {move, {float, 1.0}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, cosh, 1}}.
    {test, is_eq_exact, {f, 122}, [{x, 0}, {float, 1.5430806348152437}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 123}}.
  {label, 122}.
    {move, {atom, false}, {x, 0}}.
  {label, 123}.
    {jump, {f, 121}}.
  {label, 120}.
    {move, {atom, false}, {x, 0}}.
  {label, 121}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {float, 0.5}, {x, 0}}.
    {call_ext, 1, {extfunc, std@math, tanh, 1}}.
    {test, is_eq_exact, {f, 124}, [{x, 0}, {float, 0.46211715726000974}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 125}}.
  {label, 124}.
    {move, {atom, false}, {x, 0}}.
  {label, 125}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 20}.
    return.

{function, '__bp_loaded_main', 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/std_math_on_every_target|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '_botopink_main'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 15}}.
    {call_last, 0, {f, 3}, 0}.

{function, main, 1, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, main}, 1}.
  {label, 13}.
    {call_only, 0, {f, 11}}.

{function, '__bp_load_siblings', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, bp_load_cases_std_math_on_every_target@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 126}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 17}, 0}.
  {label, 126}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 17}.
    {test, is_nonempty_list, {f, 127}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 128}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 130}}.
  {label, 128}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 129}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 130}}.
  {label, 129}.
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
  {label, 130}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 17}, 2}.
  {label, 127}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_print', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_print'}, 1}.
  {label, 21}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 25}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 23}}.

{function, '-bp_show_elem-', 1, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 27}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 23}}.

{function, '__bp_show', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_show'}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 35}, [{x, 0}]}.
    {test, is_eq, {f, 34}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 36}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 38}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 37}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 37}, [{x, 0}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 43}}.
  {label, 42}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 43}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 23}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 27}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 40}, [{x, 0}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 40}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, undefined}]}.
  {label, 39}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 29}, 2}.
  {label, 40}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 41}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_tagged'}, 2}.
  {label, 29}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 44}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 44}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 44}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 31}, 3}.
  {label, 45}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '__bp_render'}, 1}.
  {label, 31}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 46}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 47}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 33}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_std_math_on_every_target@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_std_math_on_every_target@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 33}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 23}}.
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
