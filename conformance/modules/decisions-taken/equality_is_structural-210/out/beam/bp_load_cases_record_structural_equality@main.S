{module, bp_load_cases_record_structural_equality@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__same', 2}]}.
{attributes, []}.
{labels, 121}.
%%% Decision 210 — `==` compares by value on every target. Two records of the
%%% same type with equal fields are equal, recursively through a nested
%%% record, a tuple, an `Array` and an enum variant's payload; two values of
%%% different types are never equal, however alike their fields (decision 21:
%%% a value carries its declaring type); `!=` is the negation. erlang and beam
%%% compare one term (`=:=`); commonJS and wasm answered `false` for two equal
%%% records — a reference and a pointer — and now call an equality generated
%%% per compared type. A generic body (`same<T>`) answers by value too.
%%% Decision 211: `==` is always field by field — a method named `equals`
%%% has no special role and `==` never calls user code.

{function, same, 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, same}, 2}.
  {label, 3}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_eq_exact, {f, 16}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {atom, false}, {x, 0}}.
  {label, 17}.
    {deallocate, 2}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 59, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}, {y, 25}, {y, 26}, {y, 27}, {y, 28}, {y, 29}, {y, 30}, {y, 31}, {y, 32}, {y, 33}, {y, 34}, {y, 35}, {y, 36}, {y, 37}, {y, 38}, {y, 39}, {y, 40}, {y, 41}, {y, 42}, {y, 43}, {y, 44}, {y, 45}, {y, 46}, {y, 47}, {y, 48}, {y, 49}, {y, 50}, {y, 51}, {y, 52}, {y, 53}, {y, 54}, {y, 55}, {y, 56}, {y, 57}, {y, 58}]}}.
    {move, {literal, <<"Ana,x">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 20}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 37}}.
    {test, is_ne_exact, {f, 18}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 40}}.
  {label, 18}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 40}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {test, is_eq_exact, {f, 41}, [{y, 2}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 42}}.
  {label, 41}.
    {move, {atom, false}, {x, 0}}.
  {label, 42}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {y, 1}, {integer, 30}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {test, is_eq_exact, {f, 71}, [{y, 3}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 72}}.
  {label, 71}.
    {move, {atom, false}, {x, 0}}.
  {label, 72}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 4}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 31}]}}.
    {test, is_eq_exact, {f, 73}, [{y, 4}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, false}, {x, 0}}.
  {label, 74}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 5}}.
    {move, {literal, <<"Bia">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {test, is_eq_exact, {f, 75}, [{y, 5}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 76}}.
  {label, 75}.
    {move, {atom, false}, {x, 0}}.
  {label, 76}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {test, is_ne_exact, {f, 77}, [{y, 6}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, false}, {x, 0}}.
  {label, 78}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 31}]}}.
    {test, is_ne_exact, {f, 79}, [{y, 7}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 80}}.
  {label, 79}.
    {move, {atom, false}, {x, 0}}.
  {label, 80}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 8}}.
    {test, is_eq_exact, {f, 81}, [{y, 8}, {y, 8}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 82}}.
  {label, 81}.
    {move, {atom, false}, {x, 0}}.
  {label, 82}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Team}, {x, 0}, {integer, 3}]}}.
    {move, {x, 0}, {y, 9}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {y, 1}, {integer, 30}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Team}, {x, 0}, {integer, 3}]}}.
    {test, is_eq_exact, {f, 83}, [{y, 9}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 84}}.
  {label, 83}.
    {move, {atom, false}, {x, 0}}.
  {label, 84}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Team}, {x, 0}, {integer, 3}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 29}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Team}, {x, 0}, {integer, 3}]}}.
    {test, is_eq_exact, {f, 85}, [{y, 10}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {atom, false}, {x, 0}}.
  {label, 86}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 11}}.
    {move, {literal, <<"a;y">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<";">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 20}}.
    {move, {integer, 0}, {x, 1}}.
    {call, 2, {f, 37}}.
    {test, is_ne_exact, {f, 87}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 88}}.
  {label, 87}.
    {move, {literal, <<"">>}, {x, 0}}.
  {label, 88}.
    {move, {x, 0}, {y, 13}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {y, 13}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {x, 0}]}}.
    {move, {x, 0}, {y, 15}}.
    {move, {literal, <<"a">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{integer, 2}, {x, 0}]}}.
    {move, {x, 0}, {y, 16}}.
    {test, is_eq_exact, {f, 89}, [{y, 11}, {y, 14}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 90}}.
  {label, 89}.
    {move, {atom, false}, {x, 0}}.
  {label, 90}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test, is_eq_exact, {f, 91}, [{y, 11}, {y, 15}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 92}}.
  {label, 91}.
    {move, {atom, false}, {x, 0}}.
  {label, 92}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test, is_ne_exact, {f, 93}, [{y, 11}, {y, 16}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 94}}.
  {label, 93}.
    {move, {atom, false}, {x, 0}}.
  {label, 94}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, <<"Bia">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 25}]}}.
    {move, {y, 17}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 17}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {y, 17}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 18}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {move, {literal, <<"Bia">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 25}]}}.
    {move, {y, 19}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 19}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {y, 1}, {integer, 30}]}}.
    {move, {y, 19}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 20}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 21}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {y, 21}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 22}}.
    {test, is_eq_exact, {f, 95}, [{y, 18}, {y, 20}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {atom, false}, {x, 0}}.
  {label, 96}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test, is_eq_exact, {f, 97}, [{y, 18}, {y, 22}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 98}}.
  {label, 97}.
    {move, {atom, false}, {x, 0}}.
  {label, 98}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test, is_ne_exact, {f, 99}, [{y, 18}, {y, 22}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 100}}.
  {label, 99}.
    {move, {atom, false}, {x, 0}}.
  {label, 100}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__circle}, {integer, 2}]}}.
    {move, {x, 0}, {y, 23}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__circle}, {integer, 2}]}}.
    {test, is_eq_exact, {f, 101}, [{y, 23}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {atom, false}, {x, 0}}.
  {label, 102}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__circle}, {integer, 2}]}}.
    {move, {x, 0}, {y, 24}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__circle}, {integer, 3}]}}.
    {test, is_eq_exact, {f, 103}, [{y, 24}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 104}}.
  {label, 103}.
    {move, {atom, false}, {x, 0}}.
  {label, 104}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__rect}, {integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {y, 25}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__rect}, {integer, 1}, {integer, 2}]}}.
    {test, is_eq_exact, {f, 105}, [{y, 25}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 106}}.
  {label, 105}.
    {move, {atom, false}, {x, 0}}.
  {label, 106}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__rect}, {integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {y, 26}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__circle}, {integer, 1}]}}.
    {test, is_eq_exact, {f, 107}, [{y, 26}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 108}}.
  {label, 107}.
    {move, {atom, false}, {x, 0}}.
  {label, 108}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {atom, bp_load_cases_record_structural_equality@main@@Shape__v__dot}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {atom, bp_load_cases_record_structural_equality@main@@Shape__v__dot}, {x, 0}}.
    {test, is_eq_exact, {f, 109}, [{x, 1}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 110}}.
  {label, 109}.
    {move, {atom, false}, {x, 0}}.
  {label, 110}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {atom, bp_load_cases_record_structural_equality@main@@Shape__v__dot}, {x, 0}}.
    {move, {x, 0}, {y, 27}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__circle}, {integer, 0}]}}.
    {test, is_ne_exact, {f, 111}, [{y, 27}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 112}}.
  {label, 111}.
    {move, {atom, false}, {x, 0}}.
  {label, 112}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 28}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Vec}, {x, 0}, {integer, 30}]}}.
    {test, is_eq_exact, {f, 113}, [{y, 28}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {atom, false}, {x, 0}}.
  {label, 114}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 29}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Vec}, {x, 0}, {integer, 30}]}}.
    {test, is_ne_exact, {f, 115}, [{y, 29}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 116}}.
  {label, 115}.
    {move, {atom, false}, {x, 0}}.
  {label, 116}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {y, 1}, {integer, 30}]}}.
    {move, {x, 0}, {y, 30}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 30}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 30}]}}.
    {move, {x, 0}, {y, 31}}.
    {move, {literal, <<"Ana">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Person}, {x, 0}, {integer, 1}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 31}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {y, 11}, {x, 0}}.
    {move, {y, 14}, {x, 1}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 32}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 32}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 32}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 32}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 33}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 33}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 0}, {y, 33}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 33}, {x, 2}}.
    {test_heap, 2, 3}.
    {put_list, {x, 0}, {x, 2}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__rect}, {integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {y, 34}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Shape__v__rect}, {integer, 1}, {integer, 2}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 34}, {x, 0}}.
    {call, 2, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Loose}, {integer, 1}]}}.
    {move, {x, 0}, {y, 35}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_record_structural_equality@main@@Loose}, {integer, 2}]}}.
    {test, is_eq_exact, {f, 117}, [{y, 35}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 118}}.
  {label, 117}.
    {move, {atom, false}, {x, 0}}.
  {label, 118}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 44}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 59}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/record_structural_equality|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__same', 2, 120}.
  {label, 119}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_priv__same'}, 2}.
  {label, 120}.
    {call_only, 2, {f, 3}}.

{function, '__bp_tpl_0-t/2-fun-0-', 2, 24}.
  {label, 23}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 24}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 28}, [{x, 0}]}.
    {jump, {f, 29}}.
  {label, 28}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 29}}.
  {label, 30}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 29}.
    {move, {x, 0}, {y, 4}}.
  {label, 31}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 32}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 34}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 34}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 35}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 31}}.
  {label, 32}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 33}, [{x, 0}]}.
    {jump, {f, 27}}.
  {label, 33}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 27}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 26}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_0', 2, 20}.
  {label, 19}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_tpl_0'}, 2}.
  {label, 20}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 24}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '-bp_at-', 2, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '-bp_at-'}, 2}.
  {label, 37}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 39}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 38}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 39}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 38}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 38}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_print', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_print'}, 1}.
  {label, 44}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 48}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 46}}.

{function, '-bp_show_elem-', 1, 50}.
  {label, 49}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 50}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 46}}.

{function, '__bp_show', 2, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_show'}, 2}.
  {label, 46}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 58}, [{x, 0}]}.
    {test, is_eq, {f, 57}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 59}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 61}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 60}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 60}, [{x, 0}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 65}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 66}}.
  {label, 65}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 66}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 46}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 60}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 50}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 63}, [{x, 0}]}.
    {test, is_ne_exact, {f, 63}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 63}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 64}, [{x, 0}, {atom, undefined}]}.
  {label, 62}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 52}, 2}.
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 64}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 52}.
  {label, 51}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_tagged'}, 2}.
  {label, 52}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 67}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 67}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 67}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 54}, 3}.
  {label, 68}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 54}.
  {label, 53}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '__bp_render'}, 1}.
  {label, 54}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 69}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 70}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 70}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 56}.
  {label, 55}.
    {line, [{location, "bp_load_cases_record_structural_equality@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_record_structural_equality@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 56}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 46}}.
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
