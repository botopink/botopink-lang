{module, bp_load_cases_optional_chain_field_after_call@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__p', 1}]}.
{attributes, []}.
{labels, 96}.
%%% Decision 330 — a field read written after a `?.` link continues the
%%% chain, as a method there does (`find(0)?.str().length()`) and as
%%% TypeScript's does: `p(true)?.me().x` reads `x` off the record `me()`
%%% answers when `p(true)` is present, and is absent when it is not, so `??`
%%% takes its default; the receiver is evaluated once, on every target. A
%%% field after a field link (`p(true)?.inner.x`) and a method after the read
%%% (`p(true)?.me().name.length()`) continue it alike.

{function, p, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, p}, 1}.
  {label, 3}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"p">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 44}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"seven">>}, {x, 0}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_field_after_call@main@@Inner}, {integer, 3}]}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_optional_chain_field_after_call@main@@Point}, {integer, 7}, {y, 1}, {x, 0}]}}.
    {deallocate, 4}.
    return.
  {label, 44}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 21, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}, {y, 16}, {y, 17}, {y, 18}, {y, 19}, {y, 20}]}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 47}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 48}}.
  {label, 47}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_chain_field_after_call@main@@Point, me, 1}}.
  {label, 48}.
    {test, is_ne_exact, {f, 46}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 4, {atom, bp_load_cases_optional_chain_field_after_call@main@@Point}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 50}.
    {jump, {f, 49}}.
  {label, 46}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 49}.
    {test, is_ne_exact, {f, 45}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 51}}.
  {label, 45}.
    {move, {integer, -1}, {x, 0}}.
  {label, 51}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 54}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 55}}.
  {label, 54}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_chain_field_after_call@main@@Point, me, 1}}.
  {label, 55}.
    {test, is_ne_exact, {f, 53}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 4, {atom, bp_load_cases_optional_chain_field_after_call@main@@Point}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 57}.
    {jump, {f, 56}}.
  {label, 53}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 56}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {jump, {f, 58}}.
  {label, 52}.
    {move, {integer, -1}, {x, 0}}.
  {label, 58}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 61}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 63}}.
  {label, 61}.
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 4, {atom, bp_load_cases_optional_chain_field_after_call@main@@Point}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
    {jump, {f, 63}}.
  {label, 62}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 63}.
    {test, is_ne_exact, {f, 60}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_tagged_tuple, {f, 65}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_field_after_call@main@@Inner}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 65}.
    {jump, {f, 64}}.
  {label, 60}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 64}.
    {test, is_ne_exact, {f, 59}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {jump, {f, 66}}.
  {label, 59}.
    {move, {integer, -1}, {x, 0}}.
  {label, 66}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 69}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 69}.
    {test, is_tagged_tuple, {f, 70}, [{x, 0}, 4, {atom, bp_load_cases_optional_chain_field_after_call@main@@Point}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
    {jump, {f, 71}}.
  {label, 70}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 71}.
    {test, is_ne_exact, {f, 68}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tagged_tuple, {f, 73}, [{x, 0}, 2, {atom, bp_load_cases_optional_chain_field_after_call@main@@Inner}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 73}.
    {jump, {f, 72}}.
  {label, 68}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 72}.
    {test, is_ne_exact, {f, 67}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 74}}.
  {label, 67}.
    {move, {integer, -1}, {x, 0}}.
  {label, 74}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, true}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 79}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 80}}.
  {label, 79}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_chain_field_after_call@main@@Point, me, 1}}.
  {label, 80}.
    {test, is_ne_exact, {f, 78}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 11}}.
    {move, {y, 11}, {x, 0}}.
    {test, is_tagged_tuple, {f, 82}, [{x, 0}, 4, {atom, bp_load_cases_optional_chain_field_after_call@main@@Point}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 82}.
    {jump, {f, 81}}.
  {label, 78}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 81}.
    {call, 1, {f, 77}}.
    {test, is_ne_exact, {f, 75}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 75}.
    {move, {integer, -1}, {x, 0}}.
  {label, 83}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, false}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test, is_eq, {f, 86}, [{x, 0}, {atom, undefined}]}.
    {jump, {f, 87}}.
  {label, 86}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_optional_chain_field_after_call@main@@Point, me, 1}}.
  {label, 87}.
    {test, is_ne_exact, {f, 85}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {test, is_tagged_tuple, {f, 89}, [{x, 0}, 4, {atom, bp_load_cases_optional_chain_field_after_call@main@@Point}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 89}.
    {jump, {f, 88}}.
  {label, 85}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 88}.
    {test, is_ne_exact, {f, 84}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 15}}.
    {move, {y, 15}, {x, 0}}.
    {jump, {f, 90}}.
  {label, 84}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 90}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 17}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 21}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/optional_chain_field_after_call|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, '__bp_priv__p', 1, 95}.
  {label, 94}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_priv__p'}, 1}.
  {label, 95}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_print'}, 1}.
  {label, 17}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 21}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 21}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 19}}.

{function, '-bp_show_elem-', 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 23}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 19}}.

{function, '__bp_show', 2, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_show'}, 2}.
  {label, 19}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 31}, [{x, 0}]}.
    {test, is_eq, {f, 30}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 30}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 31}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 32}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 34}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 33}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 33}, [{x, 0}]}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 33}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 39}}.
  {label, 38}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 39}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 19}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 36}, [{x, 0}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 36}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 37}, [{x, 0}, {atom, undefined}]}.
  {label, 35}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 25}, 2}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 37}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 25}.
  {label, 24}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_tagged'}, 2}.
  {label, 25}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 40}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 40}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 40}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 27}, 3}.
  {label, 41}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 27}.
  {label, 26}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_render'}, 1}.
  {label, 27}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 42}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 42}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 43}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 29}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 19}}.
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

{function, '__bp_tpl_0', 1, 92}.
  {label, 91}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 92}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, length, 1}, 2}.

{function, '__bp_prim_length', 1, 77}.
  {label, 76}.
    {line, [{location, "bp_load_cases_optional_chain_field_after_call@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_optional_chain_field_after_call@main}, {atom, '__bp_prim_length'}, 1}.
  {label, 77}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 93}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 92}, 1}.
  {label, 93}.
    %% unresolved_method: length/1
    {move, {literal, {unresolved_method, length, 1}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 1}.
    return.
