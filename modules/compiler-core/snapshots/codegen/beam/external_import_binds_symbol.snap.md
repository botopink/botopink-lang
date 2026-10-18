----- SOURCE CODE -- main.bp
```botopink
#[@external(.Erlang("filename:extension($0)"), .JavaScript("""require("node:path").extname($0)"""))]
pub declare fn extname(p: string) -> string;

fn main() {
    @print(extname("docs/readme.md"));
}
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {extname, 1}, {'__bp_priv__main', 0}]}.
{attributes, []}.
{labels, 76}.

{function, extname, 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, extname}, 1}.
  {label, 13}.
    {call_ext_only, 1, {extfunc, filename, extension, 1}}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 0, 0}.
    {move, {literal, <<"docs/readme.md">>}, {x, 0}}.
    {call, 1, {f, 15}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 42}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call, 0, {f, 9}}.
    {call_last, 0, {f, 3}, 0}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, '__bp_load_siblings', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_load_siblings'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {atom, test@main}, {x, 0}}.
    {call_ext, 1, {extfunc, code, which, 1}}.
    {test, is_list, {f, 69}, [{x, 0}]}.
    {call_ext, 1, {extfunc, filename, dirname, 1}}.
    {move, {literal, [42, 46, 101, 114, 108]}, {x, 1}}.
    {call_ext, 2, {extfunc, filename, join, 2}}.
    {call_ext, 1, {extfunc, filelib, wildcard, 1}}.
    {call_last, 1, {f, 11}, 0}.
  {label, 69}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 0}.
    return.

{function, '-bp_load_sibling-', 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '-bp_load_sibling-'}, 1}.
  {label, 11}.
    {test, is_nonempty_list, {f, 70}, [{x, 0}]}.
    {allocate, 2, 1}.
    {get_list, {x, 0}, {y, 1}, {y, 0}}.
    {move, {literal, [46, 101, 114, 108]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, filename, basename, 2}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {test, is_tagged_tuple, {f, 71}, [{x, 0}, 2, {atom, module}]}.
    {jump, {f, 73}}.
  {label, 71}.
    {move, {literal, [binary, return_errors]}, {x, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 2, {extfunc, compile, file, 2}}.
    {test, is_tagged_tuple, {f, 72}, [{x, 0}, 3, {atom, ok}]}.
    {get_tuple_element, {x, 0}, 2, {x, 2}}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 3, {extfunc, code, load_binary, 3}}.
    {jump, {f, 73}}.
  {label, 72}.
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
  {label, 73}.
    {move, {y, 0}, {x, 0}}.
    {call_last, 1, {f, 11}, 2}.
  {label, 70}.
    {move, {atom, ok}, {x, 0}}.
    return.

{function, '__bp_priv__main', 0, 75}.
  {label, 74}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__main'}, 0}.
  {label, 75}.
    {call_only, 0, {f, 3}}.

{function, '__bp_tpl_0', 1, 15}.
  {label, 14}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 15}.
    {allocate, 16, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}, {y, 9}, {y, 10}, {y, 11}, {y, 12}, {y, 13}, {y, 14}, {y, 15}]}}.
    {move, {x, 0}, {y, 5}}.
    {'try', {y, 15}, {f, 18}}.
    {move, {y, 5}, {x, 0}}.
    {call_ext, 1, {extfunc, filename, extension, 1}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {try_end, {y, 15}}.
    {jump, {f, 19}}.
  {label, 18}.
    {try_case, {y, 15}}.
    {move, {x, 0}, {y, 7}}.
    {move, {x, 1}, {y, 8}}.
    {move, {x, 2}, {y, 9}}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 21}, [{x, 0}]}.
    {test, test_arity, {f, 21}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, panic}, {x, 1}}.
    {test, is_eq_exact, {f, 23}, [{x, 0}, {x, 1}]}.
    {jump, {f, 24}}.
  {label, 23}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, todo}, {x, 1}}.
    {test, is_eq_exact, {f, 25}, [{x, 0}, {x, 1}]}.
    {jump, {f, 26}}.
  {label, 25}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, integer_overflow}, {x, 1}}.
    {test, is_eq_exact, {f, 27}, [{x, 0}, {x, 1}]}.
    {jump, {f, 28}}.
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, bp_host}, {x, 1}}.
    {test, is_eq_exact, {f, 21}, [{x, 0}, {x, 1}]}.
  {label, 28}.
  {label, 26}.
  {label, 24}.
    {jump, {f, 22}}.
  {label, 22}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 21}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 29}, [{x, 0}]}.
    {test, test_arity, {f, 29}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {y, 12}}.
    {get_tuple_element, {x, 0}, 3, {y, 13}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 29}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 3}}.
    {move, {y, 13}, {y, 4}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 29}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, error}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {test, test_arity, {f, 30}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {y, 12}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 30}, [{x, 0}, {atom, bp_assert}]}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 3}}.
    {test_heap, 4, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_assert}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 13}}.
    {move, {y, 13}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 30}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, throw}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, '__bp_break'}]}.
    {move, {atom, '__bp_break'}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 31}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {atom, throw}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 32}, [{x, 0}]}.
    {test, test_arity, {f, 32}, [{x, 0}, 2]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {move, {y, 10}, {y, 0}}.
    {move, {y, 11}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_cond_break'}, {x, 1}}.
    {test, is_eq_exact, {f, 34}, [{x, 0}, {x, 1}]}.
    {jump, {f, 35}}.
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_cond_continue'}, {x, 1}}.
    {test, is_eq_exact, {f, 36}, [{x, 0}, {x, 1}]}.
    {jump, {f, 37}}.
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_try'}, {x, 1}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {x, 1}]}.
    {jump, {f, 39}}.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {move, {atom, '__bp_gen_stop'}, {x, 1}}.
    {test, is_eq_exact, {f, 32}, [{x, 0}, {x, 1}]}.
  {label, 39}.
  {label, 37}.
  {label, 35}.
    {jump, {f, 33}}.
  {label, 33}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 12}}.
    {move, {y, 12}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 32}.
    {move, {y, 7}, {x, 0}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, throw}]}.
    {move, {y, 8}, {x, 0}}.
    {test, is_tuple, {f, 40}, [{x, 0}]}.
    {test, test_arity, {f, 40}, [{x, 0}, 4]}.
    {get_tuple_element, {x, 0}, 0, {y, 10}}.
    {get_tuple_element, {x, 0}, 1, {y, 11}}.
    {get_tuple_element, {x, 0}, 2, {y, 12}}.
    {get_tuple_element, {x, 0}, 3, {y, 13}}.
    {move, {y, 10}, {x, 0}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, '__bp_gen_end'}]}.
    {move, {y, 11}, {y, 2}}.
    {move, {y, 12}, {y, 3}}.
    {move, {y, 13}, {y, 4}}.
    {test_heap, 5, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, '__bp_gen_end'}, {y, 2}, {y, 3}, {y, 4}]}}.
    {move, {x, 0}, {y, 14}}.
    {move, {y, 14}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, throw, 1}}.
  {label, 40}.
    {move, {y, 7}, {y, 0}}.
    {move, {y, 8}, {y, 0}}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {move, {x, 0}, {y, 10}}.
    {move, {literal, [126, 116, 112]}, {x, 0}}.
    {move, {y, 10}, {x, 1}}.
    {call_ext, 2, {extfunc, io_lib, format, 2}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 10}}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bp_host}, {y, 10}]}}.
    {move, {x, 0}, {y, 10}}.
    {move, {y, 10}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 19}.
    {move, {y, 6}, {x, 0}}.
    {deallocate, 16}.
    return.

{function, '__bp_print', 1, 42}.
  {label, 41}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 42}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 46}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 46}.
  {label, 45}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 46}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 44}}.

{function, '-bp_show_elem-', 1, 48}.
  {label, 47}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 48}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 44}}.

{function, '__bp_show', 2, 44}.
  {label, 43}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 44}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 56}, [{x, 0}]}.
    {test, is_eq, {f, 55}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 55}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 56}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 57}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 57}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 59}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 58}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 58}, [{x, 0}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 58}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 64}}.
  {label, 63}.
    {test, is_eq_exact, {f, 60}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 64}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 44}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 58}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 48}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 59}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 61}, [{x, 0}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 61}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 62}, [{x, 0}, {atom, undefined}]}.
  {label, 60}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 50}, 2}.
  {label, 61}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 62}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 50}.
  {label, 49}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 50}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 65}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 65}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 65}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 66}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 52}, 3}.
  {label, 66}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 52}.
  {label, 51}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 52}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 67}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 67}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 68}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 68}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 54}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 54}.
  {label, 53}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 54}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 44}}.
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
```

----- RUN LOG -----
```logs
.md
```
