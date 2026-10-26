{module, bp_load_cases_numeric_suffix_positions@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__Scale_by', 2}, {'__bp_priv__narrow', 1}, {'__bp_priv__offset', 1}, {'__bp_priv__stat', 1}, {'__bp_priv__sum', 1}]}.
{attributes, []}.
{labels, 96}.
%%% Decision 247 — a suffixed literal is the same literal wherever it stands:
%%% in a `case` guard, in a `case` arm body, in a parameter's default, in a
%%% default made of an expression and inside a lambda. The suffix is the
%%% checker's and never reaches a backend (`1577836800000l` in a guard was a
%%% `SyntaxError` in JS and an `erlc` syntax error on Erlang and BEAM). The
%%% same holds in a method's parameter default (`type`, associated, `implement`,
%%% a `behavior` default fn, a `type` variant's method), a record field default
%%% and a `case` guard inside a method body.

{function, stat, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, stat}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test, is_lt, {f, 24}, [{y, 0}, {integer, 0}]}.
    {move, {literal, <<"negative">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 1}.
    return.
  {label, 24}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_numeric_suffix_positions@main@@Stamp}, {y, 0}]}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 1}.
    return.

{function, offset, 1, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, offset}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, sum, 1, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, sum}, 1}.
  {label, 7}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, narrow, 1, 9}.
  {label, 8}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, narrow}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, 'Scale_by', 2, 11}.
  {label, 10}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, 'Scale_by'}, 2}.
  {label, 11}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {gc_bif, '*', {f, 0}, 0, [{y, 0}, {y, 1}], {x, 0}}.
    {test, is_ge, {f, 25}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 25}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {literal, {integer_overflow, <<"integer overflow: * on i64 at src/main.bp:43:18">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 26}.
    {deallocate, 2}.
    return.

{function, main, 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 11}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, main}, 0}.
  {label, 13}.
    {allocate, 12, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}]}}.
    {move, {integer, 1577836900000}, {x, 0}}.
    {call, 1, {f, 3}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 28}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 30}, [{x, 0}, 2, {atom, bp_load_cases_numeric_suffix_positions@main@@Stamp}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
  {label, 30}.
    {test, is_lt, {f, 29}, [{integer, 1577836800000}, {x, 0}]}.
    {move, {literal, <<"after">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {jump, {f, 27}}.
  {label, 29}.
    {move, {x, 1}, {x, 0}}.
  {label, 28}.
    {test, is_tagged_tuple, {f, 59}, [{x, 0}, 2, {atom, ok}]}.
    {move, {literal, <<"before">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {jump, {f, 27}}.
  {label, 59}.
    {test, is_tagged_tuple, {f, 60}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {jump, {f, 27}}.
  {label, 60}.
    {case_end, {x, 0}}.
  {label, 27}.
    {move, {integer, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_lt, {f, 62}, [{integer, 2}, {y, 3}]}.
    {move, {literal, <<"big">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {jump, {f, 61}}.
  {label, 62}.
    {move, {x, 1}, {x, 0}}.
    {move, {literal, <<"small">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {jump, {f, 61}}.
  {label, 61}.
    {move, {integer, 2}, {x, 0}}.
    {move, {x, 0}, {y, 4}}.
    {move, {x, 0}, {x, 1}}.
    {test, is_eq_exact, {f, 65}, [{y, 4}, {integer, 2}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 66}}.
  {label, 65}.
    {move, {atom, false}, {x, 0}}.
  {label, 66}.
    {move, {x, 0}, {x, 2}}.
    {test, is_eq, {f, 67}, [{x, 2}, {atom, true}]}.
    {test, is_lt, {f, 69}, [{y, 4}, {integer, 9}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 70}}.
  {label, 69}.
    {move, {atom, false}, {x, 0}}.
  {label, 70}.
    {jump, {f, 68}}.
  {label, 67}.
    {move, {atom, false}, {x, 0}}.
  {label, 68}.
    {test, is_eq, {f, 64}, [{x, 0}, {atom, true}]}.
    {move, {literal, <<"two">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {jump, {f, 63}}.
  {label, 64}.
    {move, {x, 1}, {x, 0}}.
    {move, {literal, <<"other">>}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {jump, {f, 63}}.
  {label, 63}.
    {move, {integer, 1}, {x, 0}}.
    {test, is_eq, {f, 72}, [{x, 0}, {integer, 1}]}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 10}, {integer, 1}], {x, 0}}.
    {test, is_ge, {f, 73}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 73}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 74}}.
  {label, 73}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:91:19">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 74}.
    {jump, {f, 71}}.
  {label, 72}.
    {move, {integer, 0}, {x, 0}}.
    {jump, {f, 71}}.
  {label, 71}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {integer, 7}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 2}, {integer, 3}], {x, 0}}.
    {call, 1, {f, 7}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {integer, 9}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, nil, {x, 0}}.
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
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 76}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {literal, <<"b">>}, {x, 0}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_numeric_suffix_positions@main@@Box}, {x, 0}, {integer, 4}]}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_tagged_tuple, {f, 79}, [{x, 0}, 3, {atom, bp_load_cases_numeric_suffix_positions@main@@Box}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
  {label, 79}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 6}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_load_cases_numeric_suffix_positions@main@@Box, grow, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {integer, 8}, {x, 0}}.
    {call_ext, 1, {extfunc, bp_load_cases_numeric_suffix_positions@main@@Box, make, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {integer, 10}, {x, 1}}.
    {call, 2, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_numeric_suffix_positions@main@@Item}, {integer, 1}]}}.
    {move, {integer, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_load_cases_numeric_suffix_positions@main@@Item, tag, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_load_cases_numeric_suffix_positions@main@@Pick}, {integer, 9}]}}.
    {call_ext, 1, {extfunc, bp_load_cases_numeric_suffix_positions@main@@Pick, 'band', 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {atom, bp_load_cases_numeric_suffix_positions@main@@Level__v__low}, {x, 0}}.
    {move, {integer, 5}, {x, 1}}.
    {call_ext, 2, {extfunc, bp_load_cases_numeric_suffix_positions@main@@Level, weight, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, nil, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {gc_bif, '+', {f, 0}, 0, [{integer, 3}, {integer, 4}], {x, 0}}.
    {test, is_ge, {f, 80}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 80}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 81}}.
  {label, 80}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:107:21">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 81}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {y, 8}}.
    {move, {literal, <<"sum=">>}, {x, 0}}.
    {move, {y, 8}, {x, 1}}.
    {test_heap, 2, 2}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 2}.
    {make_fun3, {f, 83}, 0, 0, {x, 0}, {list, []}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 32}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 12}.
    return.

{function, '__bp_loaded_main', 0, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_loaded_main'}, 0}.
  {label, 15}.
    {allocate, 0, 0}.
    {call, 0, {f, 13}}.
    {move, {atom, undefined}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_main_off', 0, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 13}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_loaded_main_off'}, 0}.
  {label, 17}.
    {allocate, 0, 0}.
    {move, {literal, <<"">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {test_heap, 3, 2}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {x, 1}]}}.
    {deallocate, 0}.
    return.

{function, '__bp_loaded_info', 0, 19}.
  {label, 18}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 14}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 19}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/numeric_suffix_positions|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 21}.
  {label, 20}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 15}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '_botopink_main'}, 0}.
  {label, 21}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 13}, 0}.

{function, main, 1, 23}.
  {label, 22}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 16}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, main}, 1}.
  {label, 23}.
    {call_only, 0, {f, 21}}.

{function, '__bp_priv__Scale_by', 2, 87}.
  {label, 86}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 17}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_priv__Scale_by'}, 2}.
  {label, 87}.
    {call_only, 2, {f, 11}}.

{function, '__bp_priv__narrow', 1, 89}.
  {label, 88}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 18}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_priv__narrow'}, 1}.
  {label, 89}.
    {call_only, 1, {f, 9}}.

{function, '__bp_priv__offset', 1, 91}.
  {label, 90}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 19}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_priv__offset'}, 1}.
  {label, 91}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__stat', 1, 93}.
  {label, 92}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 20}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_priv__stat'}, 1}.
  {label, 93}.
    {call_only, 1, {f, 3}}.

{function, '__bp_priv__sum', 1, 95}.
  {label, 94}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 21}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_priv__sum'}, 1}.
  {label, 95}.
    {call_only, 1, {f, 7}}.

{function, '__bp_print', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_print'}, 1}.
  {label, 32}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 36}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 36}.
  {label, 35}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 36}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 34}}.

{function, '-bp_show_elem-', 1, 38}.
  {label, 37}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 38}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 34}}.

{function, '__bp_show', 2, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_show'}, 2}.
  {label, 34}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 46}, [{x, 0}]}.
    {test, is_eq, {f, 45}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 45}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 46}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 47}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 47}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 49}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 48}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 48}, [{x, 0}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 48}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 53}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 54}}.
  {label, 53}.
    {test, is_eq_exact, {f, 50}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 54}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 34}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 48}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 38}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 49}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 51}, [{x, 0}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 51}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 52}, [{x, 0}, {atom, undefined}]}.
  {label, 50}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 40}, 2}.
  {label, 51}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 52}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 40}.
  {label, 39}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_tagged'}, 2}.
  {label, 40}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 55}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 55}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 55}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 56}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 42}, 3}.
  {label, 56}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 42}.
  {label, 41}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '__bp_render'}, 1}.
  {label, 42}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 57}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 57}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 58}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 58}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 44}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 44}.
  {label, 43}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 44}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 34}}.
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

{function, '-main/0-fun-0-', 1, 76}.
  {label, 75}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '-main/0-fun-0-'}, 1}.
  {label, 76}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 5}], {x, 0}}.
    {test, is_ge, {f, 77}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 77}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:98:33">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 78}.
    {deallocate, 1}.
    return.

{function, '-bp_stringify-', 1, 83}.
  {label, 82}.
    {line, [{location, "bp_load_cases_numeric_suffix_positions@main.erl", 12}]}.
    {func_info, {atom, bp_load_cases_numeric_suffix_positions@main}, {atom, '-bp_stringify-'}, 1}.
  {label, 83}.
    {allocate, 0, 1}.
    {test, is_binary, {f, 84}, [{x, 0}]}.
    {deallocate, 0}.
    return.
  {label, 84}.
    {test, is_integer, {f, 85}, [{x, 0}]}.
    {call_ext_last, 1, {extfunc, erlang, integer_to_binary, 1}, 0}.
  {label, 85}.
    {call, 1, {f, 36}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 0}.
