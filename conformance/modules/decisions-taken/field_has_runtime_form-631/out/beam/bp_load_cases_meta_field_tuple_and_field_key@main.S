{module, bp_load_cases_meta_field_tuple_and_field_key@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__array_first', 1}, {'__bp_priv__array_range', 2}, {'__bp_priv__array_repeat', 2}]}.
{attributes, []}.
{labels, 95}.

{function, 'array_range', 2, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, 'array_range'}, 2}.
  {label, 3}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_ge, {f, 18}, [{integer, 0}, {x, 0}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 19}}.
  {label, 18}.
    {gc_bif, '-', {f, 0}, 0, [{y, 1}, {y, 0}], {x, 0}}.
    {test, is_eq_exact, {f, 20}, [{x, 0}, {integer, 1}]}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {jump, {f, 21}}.
  {label, 20}.
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
    {call, 2, {f, 23}}.
  {label, 21}.
  {label, 19}.
    {deallocate, 6}.
    return.

{function, 'array_repeat', 2, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, 'array_repeat'}, 2}.
  {label, 5}.
    {allocate, 6, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test, is_ge, {f, 24}, [{integer, 0}, {y, 1}]}.
    {move, nil, {x, 0}}.
    {jump, {f, 25}}.
  {label, 24}.
    {gc_bif, 'div', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 5}}.
    {move, {x, 0}, {y, 2}}.
    {gc_bif, 'rem', {f, 0}, 0, [{y, 1}, {integer, 2}], {x, 0}}.
    {test, is_eq_exact, {f, 26}, [{x, 0}, {integer, 0}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 23}}.
    {jump, {f, 27}}.
  {label, 26}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {call, 2, {f, 23}}.
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
    {call, 2, {f, 23}}.
  {label, 27}.
  {label, 25}.
    {deallocate, 6}.
    return.
%%% Decision 298 — a meta record's field may hold a tuple of data and a
%%% `Type.Field<T>`: each is rebuilt where the meta is read, the tuple as
%%% written (`#(1, 9)`) and the field as its run-time form, `Field(Book,
%%% "pages")` (decision 631). Read back here on every target (144 B-19).

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 16, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 1}, {integer, 9}]}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"Book">>}, {x, 0}}.
    {test_heap, 4, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_meta_field_tuple_and_field_key@main@@Span}, {x, 1}, {x, 0}]}}.
    {move, {y, 0}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 31}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 33}}.
  {label, 31}.
    {test, is_tagged_tuple, {f, 32}, [{x, 0}, 3, {atom, bp_load_cases_meta_field_tuple_and_field_key@main@@Span}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 33}}.
  {label, 32}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 33}.
    {test, is_ne_exact, {f, 30}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 34}}.
  {label, 30}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 34}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 64}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 66}}.
  {label, 64}.
    {test, is_tagged_tuple, {f, 65}, [{x, 0}, 3, {atom, bp_load_cases_meta_field_tuple_and_field_key@main@@Span}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 66}.
    {test, is_ne_exact, {f, 63}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {jump, {f, 67}}.
  {label, 63}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{integer, 0}, {integer, 0}]}}.
  {label, 67}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 4}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 5}, {x, 0}}.
    {call, 2, {f, 69}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {literal, {'__bp_type', bp_load_cases_meta_field_tuple_and_field_key@main@@Book, [{bp_load_cases_meta_field_tuple_and_field_key@main@@Book, 3}]}}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"pages">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@types@@Type__Field}, {x, 1}, {x, 2}, {x, 3}, {x, 0}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, {'__bp_type', bp_load_cases_meta_field_tuple_and_field_key@main@@Book, [{bp_load_cases_meta_field_tuple_and_field_key@main@@Book, 3}]}}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<"pages">>}, {x, 0}}.
    {move, {x, 0}, {x, 2}}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 3}}.
    {move, nil, {x, 0}}.
    {test_heap, 6, 4}.
    {put_tuple2, {x, 0}, {list, [{atom, std@types@@Type__Field}, {x, 1}, {x, 2}, {x, 3}, {x, 0}]}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_meta_field_tuple_and_field_key@main@@Sort}, {y, 7}, {x, 0}]}}.
    {move, {y, 6}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call, 1, {f, 29}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq, {f, 72}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 74}}.
  {label, 72}.
    {test, is_tagged_tuple, {f, 73}, [{x, 0}, 3, {atom, bp_load_cases_meta_field_tuple_and_field_key@main@@Sort}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 74}.
    {test, is_eq, {f, 75}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 77}}.
  {label, 75}.
    {test, is_tagged_tuple, {f, 76}, [{x, 0}, 5, {atom, std@types@@Type__Field}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 77}}.
  {label, 76}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 77}.
    {test, is_ne_exact, {f, 71}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 8}}.
    {move, {y, 8}, {x, 0}}.
    {jump, {f, 78}}.
  {label, 71}.
    {move, {literal, <<"none">>}, {x, 0}}.
  {label, 78}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq, {f, 80}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 82}}.
  {label, 80}.
    {test, is_tagged_tuple, {f, 81}, [{x, 0}, 3, {atom, bp_load_cases_meta_field_tuple_and_field_key@main@@Sort}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 82}}.
  {label, 81}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 82}.
    {gc_bif, length, {f, 0}, 1, [{x, 0}], {x, 0}}.
    {test, is_ne_exact, {f, 79}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 9}}.
    {move, {y, 9}, {x, 0}}.
    {jump, {f, 83}}.
  {label, 79}.
    {move, {integer, 0}, {x, 0}}.
  {label, 83}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 36}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_loaded_main', 0, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/meta_field_tuple_and_field_key|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '_botopink_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, main}, 1}.
  {label, 17}.
    {call_only, 0, {f, 15}}.

{function, 'array_first', 1, 29}.
  {label, 28}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, 'array_first'}, 1}.
  {label, 29}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_last, 2, {f, 85}, 1}.

{function, '__bp_priv__array_first', 1, 90}.
  {label, 89}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_priv__array_first'}, 1}.
  {label, 90}.
    {call_only, 1, {f, 29}}.

{function, '__bp_priv__array_range', 2, 92}.
  {label, 91}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_priv__array_range'}, 2}.
  {label, 92}.
    {call_only, 2, {f, 3}}.

{function, '__bp_priv__array_repeat', 2, 94}.
  {label, 93}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_priv__array_repeat'}, 2}.
  {label, 94}.
    {call_only, 2, {f, 5}}.

{function, '__bp_print', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_print'}, 1}.
  {label, 36}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 40}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 40}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 38}}.

{function, '-bp_show_elem-', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 42}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 38}}.

{function, '__bp_show', 2, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_show'}, 2}.
  {label, 38}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 50}, [{x, 0}]}.
    {test, is_eq, {f, 49}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 50}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 51}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 53}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 52}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 52}, [{x, 0}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 58}}.
  {label, 57}.
    {test, is_eq_exact, {f, 54}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 58}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 38}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 52}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 42}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 53}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 55}, [{x, 0}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 55}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 56}, [{x, 0}, {atom, undefined}]}.
  {label, 54}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 44}, 2}.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 56}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_tagged'}, 2}.
  {label, 44}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 59}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 59}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 59}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 46}, 3}.
  {label, 60}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 46}.
  {label, 45}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_render'}, 1}.
  {label, 46}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 61}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 61}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 62}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 62}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 48}.
  {label, 47}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 48}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 38}}.
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

{function, '__bp_add', 2, 69}.
  {label, 68}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_add'}, 2}.
  {label, 69}.
    {test, is_binary, {f, 70}, [{x, 0}]}.
    {test, is_binary, {f, 70}, [{x, 1}]}.
    {test_heap, 4, 2}.
    {put_list, {x, 1}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {call_ext_only, 1, {extfunc, erlang, iolist_to_binary, 1}}.
  {label, 70}.
    {gc_bif, '+', {f, 0}, 2, [{x, 0}, {x, 1}], {x, 0}}.
    return.

{function, '-bp_at-', 2, 85}.
  {label, 84}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '-bp_at-'}, 2}.
  {label, 85}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 0}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {test, is_ge, {f, 87}, [{y, 0}, {integer, 0}]}.
    {test, is_lt, {f, 86}, [{y, 0}, {x, 0}]}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 87}.
    {gc_bif, '+', {f, 0}, 1, [{y, 0}, {x, 0}], {x, 0}}.
    {test, is_ge, {f, 86}, [{x, 0}, {integer, 0}]}.
    {gc_bif, '+', {f, 0}, 1, [{x, 0}, {integer, 1}], {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, nth, 2}, 2}.
  {label, 86}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_prim_append', 2, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_meta_field_tuple_and_field_key@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_meta_field_tuple_and_field_key@main}, {atom, '__bp_prim_append'}, 2}.
  {label, 23}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 88}, [{x, 0}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext_last, 2, {extfunc, lists, append, 2}, 2}.
  {label, 88}.
    %% unresolved_method: append/2
    {move, {literal, {unresolved_method, append, 2}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
    {deallocate, 2}.
    return.
