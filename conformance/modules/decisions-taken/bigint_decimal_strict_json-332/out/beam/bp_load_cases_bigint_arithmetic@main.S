{module, bp_load_cases_bigint_arithmetic@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__power', 2}]}.
{attributes, []}.
{labels, 165}.
%%% Decision 332 — `bigint` is an integer of any size, one value on the four targets: erlang and
%%% beam hold the VM's integer, commonJS a `BigInt`, wasm its runtime library. `+ - * / %`, unary
%%% `-`, `+=`, the comparisons and `==` over two `bigint`s never overflow; `/` truncates toward
%%% zero and `%` takes the dividend's sign; `bigint.of` / `bigint.parse` cross in, `toString`,
%%% `toI64` and `toF64` out. The parent binary refused the `n` suffix.

{function, power, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, power}, 2}.
  {label, 3}.
    {allocate, 4, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 2}]}.
  {label, 16}.
    {test, is_lt, {f, 17}, [{y, 3}, {y, 1}]}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 0}], {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 3}, {x, 1}], {x, 0}}.
    {test, is_ge, {f, 18}, [{x, 0}, {integer, -2147483648}]}.
    {test, is_ge, {f, 18}, [{integer, 2147483647}, {x, 0}]}.
    {jump, {f, 19}}.
  {label, 18}.
    {move, {literal, {integer_overflow, <<"integer overflow: += on i32 at src/main.bp:14:9">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 19}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 16}}.
  {label, 17}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 8, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 101}, {x, 1}}.
    {call, 2, {f, 3}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {integer, 1234567890123456789012345678901234567890}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 9876543210987654321098765432109876543210}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {integer, 8}], {x, 0}}.
    {gc_bif, '-', {f, 0}, 1, [{y, 3}, {x, 0}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ne_exact, {f, 48}, [{integer, 2}, {integer, 0}]}.
    {jump, {f, 49}}.
  {label, 48}.
    {move, {literal, {panic, <<"integer division by zero: / on bigint at src/main.bp:28:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 49}.
    {gc_bif, 'div', {f, 0}, 0, [{integer, -7}, {integer, 2}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ne_exact, {f, 50}, [{integer, -2}, {integer, 0}]}.
    {jump, {f, 51}}.
  {label, 50}.
    {move, {literal, {panic, <<"integer division by zero: / on bigint at src/main.bp:29:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 51}.
    {gc_bif, 'div', {f, 0}, 0, [{integer, 7}, {integer, -2}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ne_exact, {f, 52}, [{integer, 2}, {integer, 0}]}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {literal, {panic, <<"integer division by zero: % on bigint at src/main.bp:30:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 53}.
    {gc_bif, 'rem', {f, 0}, 0, [{integer, -7}, {integer, 2}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ne_exact, {f, 54}, [{integer, -2}, {integer, 0}]}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {literal, {panic, <<"integer division by zero: % on bigint at src/main.bp:31:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 55}.
    {gc_bif, 'rem', {f, 0}, 0, [{integer, 7}, {integer, -2}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}], {x, 0}}.
    {test, is_ne_exact, {f, 56}, [{y, 2}, {integer, 0}]}.
    {jump, {f, 57}}.
  {label, 56}.
    {move, {literal, {panic, <<"integer division by zero: / on bigint at src/main.bp:32:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 57}.
    {gc_bif, 'div', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}], {x, 0}}.
    {test, is_ne_exact, {f, 58}, [{y, 2}, {integer, 0}]}.
    {jump, {f, 59}}.
  {label, 58}.
    {move, {literal, {panic, <<"integer division by zero: % on bigint at src/main.bp:33:14">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 59}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {y, 2}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {test, is_ne_exact, {f, 60}, [{y, 3}, {integer, 0}]}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {literal, {panic, <<"integer division by zero: / on bigint at src/main.bp:34:17">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 61}.
    {gc_bif, 'div', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, false}, {x, 0}}.
  {label, 63}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 2}, {y, 3}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 7}], {x, 0}}.
    {test, is_ne_exact, {f, 64}, [{y, 3}, {integer, 0}]}.
    {jump, {f, 65}}.
  {label, 64}.
    {move, {literal, {panic, <<"integer division by zero: % on bigint at src/main.bp:35:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 65}.
    {gc_bif, 'rem', {f, 0}, 1, [{x, 0}, {y, 3}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ne_exact, {f, 66}, [{integer, 1000000007}, {integer, 0}]}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {literal, {panic, <<"integer division by zero: / on bigint at src/main.bp:36:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 67}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 1000000007}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ne_exact, {f, 68}, [{integer, 1000000007}, {integer, 0}]}.
    {jump, {f, 69}}.
  {label, 68}.
    {move, {literal, {panic, <<"integer division by zero: % on bigint at src/main.bp:37:15">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 69}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 1000000007}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_lt, {f, 70}, [{y, 2}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, false}, {x, 0}}.
  {label, 71}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ge, {f, 72}, [{y, 2}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 73}}.
  {label, 72}.
    {move, {atom, false}, {x, 0}}.
  {label, 73}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 3}], {x, 0}}.
    {test, is_lt, {f, 74}, [{x, 0}, {y, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, false}, {x, 0}}.
  {label, 75}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_eq_exact, {f, 76}, [{y, 2}, {integer, 1234567890123456789012345678901234567890}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, false}, {x, 0}}.
  {label, 77}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {test, is_ne_exact, {f, 78}, [{y, 2}, {y, 3}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 78}.
    {move, {atom, false}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"2^101 = ">>}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 81}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {integer, 0}, {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 5}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 3}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {gc_bif, '+', {f, 0}, 2, [{y, 5}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 5}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{integer, 0}, {y, 5}], {x, 0}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {y, 5}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {call, 1, {f, 85}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{integer, -9223372036854775807}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 86}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 86}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 87}}.
  {label, 86}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i64 at src/main.bp:52:43">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 87}.
    {call, 1, {f, 85}}.
    {gc_bif, '-', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {integer, -5}, {x, 0}}.
    {call, 1, {f, 85}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 3}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {integer, 12}, {x, 0}}.
    {call, 1, {f, 85}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {literal, <<"-123456789012345678901234567890">>}, {x, 0}}.
    {call, 1, {f, 91}}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 89}}.
  {label, 88}.
    {move, {integer, 0}, {x, 0}}.
  {label, 89}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {literal, <<"+42">>}, {x, 0}}.
    {call, 1, {f, 91}}.
    {test, is_tagged_tuple, {f, 119}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 120}}.
  {label, 119}.
    {move, {integer, 0}, {x, 0}}.
  {label, 120}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {literal, <<"12x">>}, {x, 0}}.
    {call, 1, {f, 91}}.
    {test, is_tagged_tuple, {f, 121}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 122}}.
  {label, 121}.
    {move, {integer, -1}, {x, 0}}.
  {label, 122}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {call, 1, {f, 91}}.
    {test, is_tagged_tuple, {f, 123}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {integer, -2}, {x, 0}}.
  {label, 124}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {call, 1, {f, 91}}.
    {test, is_tagged_tuple, {f, 125}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 126}}.
  {label, 125}.
    {move, {integer, -3}, {x, 0}}.
  {label, 126}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {integer, 4611686018427387904}, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 128}}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 139}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 139}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 140}}.
  {label, 139}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:61:24">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 140}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 6}], {x, 0}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 2}], {x, 0}}.
    {call, 1, {f, 128}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {integer, 1024}, {x, 0}}.
    {call, 1, {f, 142}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 80}, {x, 1}}.
    {call, 2, {f, 3}}.
    {gc_bif, '*', {f, 0}, 1, [{x, 0}, {integer, 3}], {x, 0}}.
    {call, 1, {f, 142}}.
    {test, is_eq_exact, {f, 161}, [{x, 0}, {float, 3626777458843887524118528.0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 162}}.
  {label, 161}.
    {move, {atom, false}, {x, 0}}.
  {label, 162}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 16#FF}, {integer, 16#100}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {gc_bif, '*', {f, 0}, 0, [{integer, 1_000_000}, {integer, 1_000_000}], {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 21}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 8}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 7}.
    {allocate, 0, 0}.
    {call, 0, {f, 5}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/bigint_arithmetic|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__power', 2, 164}.
  {label, 163}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_priv__power'}, 2}.
  {label, 164}.
    {call_only, 2, {f, 3}}.

{function, '__bp_print', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_print'}, 1}.
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
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 25}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 23}}.

{function, '-bp_show_elem-', 1, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 27}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 23}}.

{function, '__bp_show', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_show'}, 2}.
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
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tagged'}, 2}.
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
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_render'}, 1}.
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
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '-bp_render_pair-'}, 1}.
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

{function, '-bp_stringify-', 1, 81}.
  {label, 80}.
    {line, [{location, "bp_load_cases_bigint_arithmetic@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 81}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 82}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 82}.
    {test, is_integer, {f, 83}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 83}.
    {call, 1, {f, 25}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.

{function, '__bp_tpl_0', 1, 85}.
  {label, 84}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 85}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1--t/1-fun-0--fun-1-', 1, 108}.
  {label, 107}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_1--t/1-fun-0--fun-1-'}, 1}.
  {label, 108}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 48}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 111}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 57}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 113}}.
  {label, 111}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 113}}.
  {label, 112}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 113}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 95}.
  {label, 94}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 95}.
    {allocate, 6, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 99}, [{x, 0}]}.
    {gc_bif, byte_size, {f, 99}, 1, [{x, 0}], {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_ge, {f, 99}, [{x, 0}, {integer, 1}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, binary_part, 3}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {literal, <<"-">>}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, binary_part, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {y, 2}}.
    {jump, {f, 98}}.
  {label, 99}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 100}, [{x, 0}]}.
    {gc_bif, byte_size, {f, 100}, 1, [{x, 0}], {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_ge, {f, 100}, [{x, 0}, {integer, 1}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, binary_part, 3}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {literal, <<"+">>}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 1}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, binary_part, 3}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {y, 2}}.
    {jump, {f, 98}}.
  {label, 100}.
    {move, {y, 1}, {y, 2}}.
    {jump, {f, 98}}.
  {label, 98}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 103}}.
  {label, 103}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 104}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 108}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, all, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 106}}.
  {label, 104}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 105}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 106}}.
  {label, 105}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 106}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_integer, 1}}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 115}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 116}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 117}, [{x, 0}]}.
    {test_heap, 10, 0}.
    {put_list, {literal, <<" is not an integer">>}, nil, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"bigint.parse: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 118}}.
  {label, 117}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 118}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 6}.
    return.
  {label, 116}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_1', 1, 91}.
  {label, 90}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 91}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 95}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 132}.
  {label, 131}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 132}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {gc_bif, '-', {f, 134}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {test, is_ge, {f, 134}, [{x, 0}, {x, 1}]}.
    {move, {integer, 9223372036854775807}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {test, is_ge, {f, 134}, [{x, 0}, {x, 1}]}.
    {jump, {f, 135}}.
  {label, 135}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 134}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 137}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" does not fit i64">>}, nil, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toI64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 138}}.
  {label, 137}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 138}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 2}.

{function, '__bp_tpl_2', 1, 128}.
  {label, 127}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_2'}, 1}.
  {label, 128}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 132}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 146}.
  {label, 145}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 146}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, abs, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 1024}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsl', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {integer, 971}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, 'bsl', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 150}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, float, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 0}}.
    {jump, {f, 152}}.
  {label, 152}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, trunc, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=:=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 154}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 154}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 155}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_binary, {f, 156}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" has no exact f64">>}, nil, {x, 0}}.
    {put_list, {y, 4}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toF64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 157}}.
  {label, 156}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 157}.
    {move, {x, 0}, {y, 4}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 4}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 5}.
  {label, 155}.
    {move, {y, 3}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 150}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 158}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_binary, {f, 159}, [{x, 0}]}.
    {test_heap, 6, 0}.
    {put_list, {literal, <<" has no exact f64">>}, nil, {x, 0}}.
    {put_list, {y, 3}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"toF64: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 160}}.
  {label, 159}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 160}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, integer_overflow}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, error, 1}, 5}.
  {label, 158}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_3', 1, 142}.
  {label, 141}.
    {func_info, {atom, bp_load_cases_bigint_arithmetic@main}, {atom, '__bp_tpl_3'}, 1}.
  {label, 142}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 146}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.
