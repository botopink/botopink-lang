{module, bp_load_cases_string_parse_int_i64_range@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_loaded_main', 0}, {'__bp_loaded_main_off', 0}, {'__bp_loaded_info', 0}, {'__bp_priv__string_parseInt', 1}, {'__bp_priv__parsed', 1}]}.
{attributes, []}.
{labels, 130}.
%%% 02-std-and-packaging/97-std-dedupe step 13, decisions 176 and 319 — `string.parseInt()` reads
%%% every `i64`: −2^63 … 2^63 − 1 is `Ok` on every target, one past either end is `Error` naming the
%%% numeral. The parent bounded it at ±(2^53 − 1), so `"9007199254740992"` was out of range.

{function, parsed, 1, 3}.
  {label, 2}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 1}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, parsed}, 1}.
  {label, 3}.
    {allocate, 3, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 17}}.
    {test, is_tagged_tuple, {f, 19}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, integer_to_binary, 1}}.
    {jump, {f, 18}}.
  {label, 19}.
    {test, is_tagged_tuple, {f, 20}, [{x, 0}, 2, {atom, error}]}.
    {get_tuple_element, {x, 0}, 1, {x, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 18}}.
  {label, 20}.
    {case_end, {x, 0}}.
  {label, 18}.
    {deallocate, 3}.
    return.

{function, main, 0, 5}.
  {label, 4}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 2}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, main}, 0}.
  {label, 5}.
    {allocate, 1, 0}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {literal, <<"9007199254740991">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"9007199254740992">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"-9007199254740993">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"9223372036854775807">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"-9223372036854775808">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"+0009223372036854775807">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"9223372036854775808">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"-9223372036854775809">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"99999999999999999999999999">>}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {literal, <<"9007199254740993">>}, {x, 0}}.
    {call, 1, {f, 17}}.
    {test, is_tagged_tuple, {f, 49}, [{x, 0}, 2, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 50}}.
  {label, 49}.
    {move, {integer, 0}, {x, 0}}.
  {label, 50}.
    {move, {x, 0}, {y, 0}}.
    {gc_bif, '+', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 51}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 51}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 52}}.
  {label, 51}.
    {move, {literal, {integer_overflow, <<"integer overflow: + on i64 at src/main.bp:25:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 52}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {gc_bif, '-', {f, 0}, 0, [{y, 0}, {integer, 2}], {x, 0}}.
    {test, is_ge, {f, 53}, [{x, 0}, {integer, -9223372036854775808}]}.
    {test, is_ge, {f, 53}, [{integer, 9223372036854775807}, {x, 0}]}.
    {jump, {f, 54}}.
  {label, 53}.
    {move, {literal, {integer_overflow, <<"integer overflow: - on i64 at src/main.bp:26:13">>}}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 54}.
    {test, is_eq_exact, {f, 55}, [{x, 0}, {integer, 9007199254740991}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 56}}.
  {label, 55}.
    {move, {atom, false}, {x, 0}}.
  {label, 56}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 22}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_loaded_main', 0, 7}.
  {label, 6}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_loaded_main'}, 0}.
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
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 4}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_loaded_main_off'}, 0}.
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
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 5}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_loaded_info'}, 0}.
  {label, 11}.
    {allocate, 0, 0}.
    {move, {literal, <<"cases/string_parse_int_i64_range|*">>}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 13}.
  {label, 12}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 6}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '_botopink_main'}, 0}.
  {label, 13}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 5}, 0}.

{function, main, 1, 15}.
  {label, 14}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 7}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, main}, 1}.
  {label, 15}.
    {call_only, 0, {f, 13}}.

{function, 'string_parseInt', 1, 17}.
  {label, 16}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 8}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, 'string_parseInt'}, 1}.
  {label, 17}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"-">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 57}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {atom, true}, {x, 0}}.
  {label, 58}.
    {move, {x, 0}, {x, 1}}.
    {test, is_ne_exact, {f, 59}, [{x, 1}, {atom, true}]}.
    {move, {literal, <<"+">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 2, {extfunc, string, prefix, 2}}.
    {test, is_eq, {f, 61}, [{x, 0}, {atom, nomatch}]}.
    {move, {atom, false}, {x, 0}}.
    {jump, {f, 62}}.
  {label, 61}.
    {move, {atom, true}, {x, 0}}.
  {label, 62}.
    {jump, {f, 60}}.
  {label, 59}.
    {move, {atom, true}, {x, 0}}.
  {label, 60}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_eq, {f, 63}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 66}}.
    {jump, {f, 64}}.
  {label, 63}.
    {move, {y, 0}, {x, 0}}.
  {label, 64}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {call, 1, {f, 84}}.
    {test, is_eq, {f, 82}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 103}}.
    {jump, {f, 101}}.
  {label, 82}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 121}}.
  {label, 101}.
    {deallocate, 5}.
    return.

{function, '__bp_priv__string_parseInt', 1, 127}.
  {label, 126}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 9}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_priv__string_parseInt'}, 1}.
  {label, 127}.
    {call_only, 1, {f, 17}}.

{function, '__bp_priv__parsed', 1, 129}.
  {label, 128}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 10}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_priv__parsed'}, 1}.
  {label, 129}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 22}.
  {label, 21}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_print'}, 1}.
  {label, 22}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 26}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 26}.
  {label, 25}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 26}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 24}}.

{function, '-bp_show_elem-', 1, 28}.
  {label, 27}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 28}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 24}}.

{function, '__bp_show', 2, 24}.
  {label, 23}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_show'}, 2}.
  {label, 24}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 36}, [{x, 0}]}.
    {test, is_eq, {f, 35}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 37}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 37}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 39}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 38}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 38}, [{x, 0}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 44}}.
  {label, 43}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 44}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 24}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 28}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 39}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 41}, [{x, 0}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 41}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 42}, [{x, 0}, {atom, undefined}]}.
  {label, 40}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 30}, 2}.
  {label, 41}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 42}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 30}.
  {label, 29}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tagged'}, 2}.
  {label, 30}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 45}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 45}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 45}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 46}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 32}, 3}.
  {label, 46}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 32}.
  {label, 31}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_render'}, 1}.
  {label, 32}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 47}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 47}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 48}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 48}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 34}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 34}.
  {label, 33}.
    {line, [{location, "bp_load_cases_string_parse_int_i64_range@main.erl", 3}]}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 34}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 24}}.
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

{function, '__bp_tpl_0-t/2-fun-0-', 2, 70}.
  {label, 69}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_0-t/2-fun-0-'}, 2}.
  {label, 70}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 74}}.
  {label, 74}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 1}}.
    {jump, {f, 76}}.
  {label, 76}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 78}, [{x, 0}, {atom, true}]}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 77}}.
  {label, 78}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 79}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 77}}.
  {label, 79}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 77}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 81}}.
  {label, 81}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nthtail, 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 7}.

{function, '__bp_tpl_0', 2, 66}.
  {label, 65}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_0'}, 2}.
  {label, 66}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 70}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_1--t/1-fun-0--fun-1-', 1, 95}.
  {label, 94}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_1--t/1-fun-0--fun-1-'}, 1}.
  {label, 95}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 48}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 98}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 57}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 100}}.
  {label, 98}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 99}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 100}}.
  {label, 99}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 100}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_1-t/1-fun-0-', 1, 88}.
  {label, 87}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_1-t/1-fun-0-'}, 1}.
  {label, 88}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {move, {literal, <<"">>}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=/=', 2}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 91}, [{x, 0}, {atom, true}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 95}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_list, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, all, 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {y, 1}}.
    {jump, {f, 93}}.
  {label, 91}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 1}}.
    {jump, {f, 93}}.
  {label, 92}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 2}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 93}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 5}.
    return.

{function, '__bp_tpl_1', 1, 84}.
  {label, 83}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 84}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 88}, 1, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_2-t/1-fun-0-', 1, 107}.
  {label, 106}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_2-t/1-fun-0-'}, 1}.
  {label, 107}.
    {allocate, 5, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, binary_to_integer, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {jump, {f, 111}}.
  {label, 111}.
    {move, {integer, -9223372036854775807}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 112}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 9223372036854775807}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '=<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 2}}.
    {jump, {f, 114}}.
  {label, 112}.
    {move, {y, 3}, {x, 0}}.
    {test, is_eq_exact, {f, 113}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 2}}.
    {jump, {f, 114}}.
  {label, 113}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 3}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 114}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 116}, [{x, 0}, {atom, true}]}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 116}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 117}, [{x, 0}, {atom, false}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 118}, [{x, 0}]}.
    {test_heap, 10, 0}.
    {put_list, {literal, <<" is out of range">>}, nil, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"parseInt: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 119}}.
  {label, 118}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 119}.
    {move, {x, 0}, {y, 3}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 3}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 5}.
    return.
  {label, 117}.
    {move, {y, 2}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_2', 1, 103}.
  {label, 102}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_2'}, 1}.
  {label, 103}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 107}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_3', 1, 121}.
  {label, 120}.
    {func_info, {atom, bp_load_cases_string_parse_int_i64_range@main}, {atom, '__bp_tpl_3'}, 1}.
  {label, 121}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 124}, [{x, 0}]}.
    {test_heap, 10, 0}.
    {put_list, {literal, <<" is not an integer">>}, nil, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"\"">>}, {x, 0}, {x, 0}}.
    {put_list, {literal, <<"parseInt: ">>}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 125}}.
  {label, 124}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 125}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, error}, {y, 1}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
