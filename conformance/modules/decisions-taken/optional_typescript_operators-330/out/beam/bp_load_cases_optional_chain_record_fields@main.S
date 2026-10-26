{module, bp_load_cases_optional_chain_record_fields@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__user', 1}]}.
{attributes, []}.
{labels, 174}.
%%% Decision 330 — `?.` along a chain of record fields, each one optional:
%%% the chain is absent at the first absent link, whichever it is, and a
%%% member or a method after a `?.` link runs only on a present value, on
%%% every target.

{function, user, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, user}, 1}.
  {label, 3}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_eq_exact, {f, 16}, [{y, 0}, {integer, 0}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 16}.
    {test, is_eq_exact, {f, 17}, [{y, 0}, {integer, 1}]}.
    {move, {literal, <<"ann">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_record_fields@main@@User}, {x, 0}, {atom, undefined}]}}.
    {deallocate, 5}.
    return.
  {label, 17}.
    {test, is_eq_exact, {f, 18}, [{y, 0}, {integer, 2}]}.
    {move, {literal, <<"bo">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {literal, <<"01">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_record_fields@main@@Address}, {atom, undefined}, {x, 0}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_record_fields@main@@User}, {y, 1}, {x, 0}]}}.
    {deallocate, 5}.
    return.
  {label, 18}.
    {move, {literal, <<"cy">>}, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {literal, <<"Main">>}, {x, 0}}.
    {test_heap, 3, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_record_fields@main@@Street}, {x, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"002">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_record_fields@main@@Address}, {x, 1}, {x, 0}]}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_record_fields@main@@User}, {y, 2}, {x, 0}]}}.
    {deallocate, 5}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 25, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}, {y, 21}, {y, 22}, {y, 23}, {y, 24}]}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 20}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 22}}.
  {label, 20}.
    {test, is_tagged_tuple, {f, 21}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 22}}.
  {label, 21}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 22}.
    {test, is_eq, {f, 23}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 25}}.
  {label, 23}.
    {test, is_tagged_tuple, {f, 24}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 25}.
    {test, is_eq, {f, 26}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 28}}.
  {label, 26}.
    {test, is_tagged_tuple, {f, 27}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_record_fields@main@@Street}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 28}.
    {test, is_ne_exact, {f, 19}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {jump, {f, 29}}.
  {label, 19}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 29}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 59}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 61}}.
  {label, 59}.
    {test, is_tagged_tuple, {f, 60}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 61}.
    {test, is_eq, {f, 62}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 64}}.
  {label, 62}.
    {test, is_tagged_tuple, {f, 63}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 64}}.
  {label, 63}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 64}.
    {test, is_eq, {f, 65}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 65}.
    {test, is_tagged_tuple, {f, 66}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_record_fields@main@@Street}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 67}}.
  {label, 66}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 67}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {jump, {f, 68}}.
  {label, 58}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 68}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 70}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 72}}.
  {label, 70}.
    {test, is_tagged_tuple, {f, 71}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 72}}.
  {label, 71}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 72}.
    {test, is_eq, {f, 73}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 75}}.
  {label, 73}.
    {test, is_tagged_tuple, {f, 74}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 75}}.
  {label, 74}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 75}.
    {test, is_eq, {f, 76}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 78}}.
  {label, 76}.
    {test, is_tagged_tuple, {f, 77}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_record_fields@main@@Street}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 78}.
    {test, is_ne_exact, {f, 69}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 79}}.
  {label, 69}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 81}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 81}.
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 83}}.
  {label, 82}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 83}.
    {test, is_eq, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 86}}.
  {label, 84}.
    {test, is_tagged_tuple, {f, 85}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 86}}.
  {label, 85}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 86}.
    {test, is_eq, {f, 87}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 89}}.
  {label, 87}.
    {test, is_tagged_tuple, {f, 88}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_record_fields@main@@Street}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 89}}.
  {label, 88}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 89}.
    {test, is_ne_exact, {f, 80}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 90}}.
  {label, 80}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 90}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 94}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 96}}.
  {label, 94}.
    {test, is_tagged_tuple, {f, 95}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 96}}.
  {label, 95}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 96}.
    {test, is_eq, {f, 97}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 99}}.
  {label, 97}.
    {test, is_tagged_tuple, {f, 98}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 99}}.
  {label, 98}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 99}.
    {test, is_eq, {f, 100}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 102}}.
  {label, 100}.
    {test, is_tagged_tuple, {f, 101}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_record_fields@main@@Street}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 102}}.
  {label, 101}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 102}.
    {test, is_eq, {f, 92}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 93}}.
  {label, 92}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call, 1, {f, 104}}.
  {label, 93}.
    {test, is_ne_exact, {f, 91}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 105}}.
  {label, 91}.
    {move, {integer, -1}, {x, 0}}.
  {label, 105}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 109}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 111}}.
  {label, 109}.
    {test, is_tagged_tuple, {f, 110}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 111}}.
  {label, 110}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 111}.
    {test, is_eq, {f, 112}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 114}}.
  {label, 112}.
    {test, is_tagged_tuple, {f, 113}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 114}}.
  {label, 113}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 114}.
    {test, is_eq, {f, 115}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 117}}.
  {label, 115}.
    {test, is_tagged_tuple, {f, 116}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_record_fields@main@@Street}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 117}}.
  {label, 116}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 117}.
    {test, is_eq, {f, 107}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 108}}.
  {label, 107}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call, 1, {f, 104}}.
  {label, 108}.
    {test, is_ne_exact, {f, 106}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 118}}.
  {label, 106}.
    {move, {integer, -1}, {x, 0}}.
  {label, 118}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 122}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 124}}.
  {label, 122}.
    {test, is_tagged_tuple, {f, 123}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 124}}.
  {label, 123}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 124}.
    {test, is_eq, {f, 125}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 127}}.
  {label, 125}.
    {test, is_tagged_tuple, {f, 126}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 127}}.
  {label, 126}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 127}.
    {test, is_eq, {f, 128}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 130}}.
  {label, 128}.
    {test, is_tagged_tuple, {f, 129}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_record_fields@main@@Street}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 130}}.
  {label, 129}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 130}.
    {test, is_eq, {f, 120}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 121}}.
  {label, 120}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {call, 1, {f, 104}}.
  {label, 121}.
    {test, is_ne_exact, {f, 119}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 131}}.
  {label, 119}.
    {move, {integer, -1}, {x, 0}}.
  {label, 131}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 2}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 135}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 137}}.
  {label, 135}.
    {test, is_tagged_tuple, {f, 136}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 137}}.
  {label, 136}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 137}.
    {test, is_eq, {f, 138}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 140}}.
  {label, 138}.
    {test, is_tagged_tuple, {f, 139}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 140}}.
  {label, 139}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 140}.
    {test, is_eq, {f, 133}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 134}}.
  {label, 133}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call, 1, {f, 104}}.
  {label, 134}.
    {test, is_ne_exact, {f, 132}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {jump, {f, 141}}.
  {label, 132}.
    {move, {integer, -1}, {x, 0}}.
  {label, 141}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 1}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 145}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 147}}.
  {label, 145}.
    {test, is_tagged_tuple, {f, 146}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 147}}.
  {label, 146}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 147}.
    {test, is_eq, {f, 148}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 150}}.
  {label, 148}.
    {test, is_tagged_tuple, {f, 149}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@Address}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 150}}.
  {label, 149}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 150}.
    {test, is_eq, {f, 143}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 144}}.
  {label, 143}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call, 1, {f, 104}}.
  {label, 144}.
    {test, is_ne_exact, {f, 142}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {jump, {f, 151}}.
  {label, 142}.
    {move, {integer, -1}, {x, 0}}.
  {label, 151}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 3}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 155}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 157}}.
  {label, 155}.
    {test, is_tagged_tuple, {f, 156}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 157}}.
  {label, 156}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 157}.
    {test, is_eq, {f, 153}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 154}}.
  {label, 153}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call, 1, {f, 159}}.
  {label, 154}.
    {test, is_ne_exact, {f, 152}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 160}}.
  {label, 152}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 160}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {integer, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 164}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 166}}.
  {label, 164}.
    {test, is_tagged_tuple, {f, 165}, [{x, 0}, 3, {atom, bp_load_cases_optional_chain_record_fields@main@@User}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 166}}.
  {label, 165}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 166}.
    {test, is_eq, {f, 162}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 163}}.
  {label, 162}.
    {move, {x, 0}, {y, 16}}.
    {move, {y, 16}, {x, 0}}.
    {call, 1, {f, 159}}.
  {label, 163}.
    {test, is_ne_exact, {f, 161}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 17}}.
    {move, {y, 17}, {x, 0}}.
    {jump, {f, 167}}.
  {label, 161}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 167}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 31}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 25}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_chain_record_fields|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__user', 1, 173}.
  {label, 172}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_priv__user'}, 1}.
  {label, 173}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 31}.
  {label, 30}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_print'}, 1}.
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
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 35}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '-bp_show_elem-', 1, 37}.
  {label, 36}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 37}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 33}}.

{function, '__bp_show', 2, 33}.
  {label, 32}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_show'}, 2}.
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
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_tagged'}, 2}.
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
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_render'}, 1}.
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
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '-bp_render_pair-'}, 1}.
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

{function, '__bp_tpl_0', 1, 169}.
  {label, 168}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 169}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_prim_length', 1, 104}.
  {label, 103}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_prim_length'}, 1}.
  {label, 104}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 170}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 169}, 1}.
  {label, 170}.
    %% unresolved_method: length/1
    {move, {literal, {unresolved_method, length, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 1}.
    return.

{function, '__bp_prim_toUpper', 1, 159}.
  {label, 158}.
    {line, [{location, "bp_load_cases_optional_chain_record_fields@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_chain_record_fields@main}, {atom, '__bp_prim_toUpper'}, 1}.
  {label, 159}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 171}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, string, uppercase, 1}, 1}.
  {label, 171}.
    %% unresolved_method: toUpper/1
    {move, {literal, {unresolved_method, toUpper, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 1}.
    return.
