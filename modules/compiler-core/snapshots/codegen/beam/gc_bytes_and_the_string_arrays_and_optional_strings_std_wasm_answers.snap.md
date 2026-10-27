----- SOURCE CODE -- main.bp
```botopink
pub fn main() -> void {
    val b = bytes.fromUtf8("hello");
    print(b.length());
    print(b.slice(1, 3).length());
    val c = b.concat(bytes.fromUtf8("!"));
    print(c.length());
    print(b == bytes.fromUtf8("hello"));
    val r = b.toUtf8();
    print(r);
    val parts = "a,b,c".split(",");
    print(parts);
    print("hello".at(1));
    print("hello".at(9));
}

import {io.terminal.print} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__bytes_slice', 3}]}.
{attributes, []}.
{labels, 140}.

{function, main, 0, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 3}.
    {allocate, 9, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}, {y, 8}]}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {y, 0}, {x, 0}}.
    {move, {integer, 3}, {x, 2}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 3, {f, 42}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {literal, <<"!">>}, {x, 0}}.
    {call, 1, {f, 9}}.
    {move, {x, 0}, {x, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 2, {f, 44}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 11}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {call, 1, {f, 9}}.
    {test, is_eq_exact, {f, 49}, [{y, 0}, {x, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 50}}.
  {label, 49}.
    {move, {atom, false}, {x, 0}}.
  {label, 50}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 52}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {literal, <<"a,b,c">>}, {x, 0}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<",">>}, {x, 0}}.
    {move, {x, 1}, {x, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {x, 2}, {x, 0}}.
    {call, 2, {f, 63}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {literal, <<"hello">>}, {x, 0}}.
    {move, {integer, 9}, {x, 1}}.
    {call, 2, {f, 80}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 13}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 9}.
    return.

{function, '_botopink_main', 0, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 5}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 3}, 0}.

{function, main, 1, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 7}.
    {call_only, 0, {f, 5}}.

{function, 'bytes_slice', 3, 42}.
  {label, 41}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, 'bytes_slice'}, 3}.
  {label, 42}.
    {allocate, 3, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test, is_ne_exact, {f, 102}, [{y, 2}, {atom, undefined}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 3, {f, 104}, 3}.
  {label, 102}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_last, 2, {f, 124}, 3}.

{function, '__bp_priv__bytes_slice', 3, 139}.
  {label, 138}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__bytes_slice'}, 3}.
  {label, 139}.
    {call_only, 3, {f, 42}}.

{function, '__bp_tpl_0', 1, 9}.
  {label, 8}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_0'}, 1}.
  {label, 9}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 1}.
    return.

{function, '__bp_tpl_1', 1, 11}.
  {label, 10}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_1'}, 1}.
  {label, 11}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {call_ext_last, 1, {extfunc, erlang, byte_size, 1}, 1}.

{function, '__bp_print', 1, 13}.
  {label, 12}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 13}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 17}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 17}.
  {label, 16}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 17}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 15}}.

{function, '-bp_show_elem-', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 19}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 15}}.

{function, '__bp_show', 2, 15}.
  {label, 14}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 15}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 27}, [{x, 0}]}.
    {test, is_eq, {f, 26}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 26}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 27}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 28}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 28}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 30}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 29}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 29}, [{x, 0}]}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 29}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 35}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 36}}.
  {label, 35}.
    {test, is_eq_exact, {f, 31}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 36}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 15}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 29}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 19}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 30}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 32}, [{x, 0}]}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 32}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 34}, [{x, 0}, {atom, undefined}]}.
  {label, 31}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 21}, 2}.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {test, is_function, {f, 33}, [{x, 0}]}.
    {move, {atom, arity}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, fun_info, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {call_ext, 1, {extfunc, erlang, integer_to_list, 1}}.
    {test_heap, 4, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {put_list, {literal, <<"fn/">>}, {x, 1}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 34}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 21}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 37}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 37}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 37}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 23}, 3}.
  {label, 38}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 23}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 39}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 39}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 40}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 25}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 15}}.
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

{function, '__bp_tpl_2', 2, 44}.
  {label, 43}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_2'}, 2}.
  {label, 44}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 47}, [{x, 0}]}.
    {move, {y, 1}, {x, 0}}.
    {test, is_binary, {f, 47}, [{x, 0}]}.
    {test_heap, 4, 0}.
    {put_list, {y, 1}, nil, {x, 0}}.
    {put_list, {y, 0}, {x, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 48}}.
  {label, 47}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 48}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_3-t/1-fun-0-', 1, 56}.
  {label, 55}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_3-t/1-fun-0-'}, 1}.
  {label, 56}.
    {allocate, 4, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 60}, [{x, 0}]}.
    {jump, {f, 61}}.
  {label, 61}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, ok}, {y, 0}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 3}, {x, 0}}.
    {deallocate, 4}.
    return.
  {label, 60}.
    {move, {literal, {error, <<"bytes.toUtf8: not valid UTF-8">>}}, {x, 0}}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_3', 1, 52}.
  {label, 51}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_3'}, 1}.
  {label, 52}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 56}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_fun, 1}.
    {deallocate, 2}.
    return.

{function, '__bp_tpl_4-t/2-fun-0-', 2, 67}.
  {label, 66}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_4-t/2-fun-0-'}, 2}.
  {label, 67}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {x, 1}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {test, is_eq_exact, {f, 69}, [{x, 0}, {literal, <<"">>}]}.
    {move, nil, {y, 3}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {test, is_list, {f, 71}, [{x, 0}]}.
    {jump, {f, 72}}.
  {label, 71}.
    {test, is_tuple, {f, 73}, [{x, 0}]}.
    {test, test_arity, {f, 73}, [{x, 0}, 3]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 72}}.
  {label, 73}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 1}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 72}.
    {move, {x, 0}, {y, 4}}.
  {label, 74}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nonempty_list, {f, 75}, [{x, 0}]}.
    {get_list, {x, 0}, {y, 5}, {y, 4}}.
    {move, {y, 5}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_integer, {f, 77}, [{x, 0}]}.
    {test_heap, 2, 0}.
    {put_list, {y, 0}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_binary, 1}}.
    {test, is_binary, {f, 77}, [{x, 0}]}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, iolist_to_binary, 1}}.
    {jump, {f, 78}}.
  {label, 77}.
    {move, {atom, badarg}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 78}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, {y, 3}, {x, 0}}.
    {move, {x, 0}, {y, 3}}.
    {jump, {f, 74}}.
  {label, 75}.
    {move, {y, 4}, {x, 0}}.
    {test, is_nil, {f, 76}, [{x, 0}]}.
    {jump, {f, 70}}.
  {label, 76}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, bad_generator}, {y, 4}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 70}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, lists, reverse, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {deallocate, 7}.
    return.
  {label, 69}.
    {move, {y, 1}, {x, 0}}.
    {move, {y, 2}, {x, 1}}.
    {move, {atom, all}, {x, 2}}.
    {call_ext_last, 3, {extfunc, string, split, 3}, 7}.

{function, '__bp_tpl_4', 2, 63}.
  {label, 62}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_4'}, 2}.
  {label, 63}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 67}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_5-t/2-fun-0-', 2, 84}.
  {label, 83}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_5-t/2-fun-0-'}, 2}.
  {label, 84}.
    {allocate, 8, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 3}}.
    {move, {x, 1}, {y, 4}}.
    {move, {y, 3}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 88}}.
  {label, 88}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, length, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 90}}.
  {label, 90}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 92}, [{x, 0}, {atom, true}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 91}}.
  {label, 92}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 93}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {y, 6}}.
    {jump, {f, 91}}.
  {label, 93}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 91}.
    {move, {y, 6}, {y, 2}}.
    {jump, {f, 95}}.
  {label, 95}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '>=', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 96}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 5}}.
    {jump, {f, 98}}.
  {label, 96}.
    {move, {y, 6}, {x, 0}}.
    {test, is_eq_exact, {f, 97}, [{x, 0}, {atom, false}]}.
    {move, {atom, false}, {y, 5}}.
    {jump, {f, 98}}.
  {label, 97}.
    {test_heap, 3, 0}.
    {put_tuple2, {x, 0}, {list, [{atom, badarg}, {y, 6}]}}.
    {call_ext, 1, {extfunc, erlang, error, 1}}.
  {label, 98}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 100}, [{x, 0}, {atom, true}]}.
    {move, {y, 2}, {x, 0}}.
    {move, {integer, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, nth, 2}}.
    {move, {x, 0}, {y, 6}}.
    {test_heap, 2, 0}.
    {put_list, {y, 6}, nil, {x, 0}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {call_ext_last, 1, {extfunc, unicode, characters_to_binary, 1}, 8}.
  {label, 100}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 101}, [{x, 0}, {atom, false}]}.
    {move, {atom, undefined}, {x, 0}}.
    {deallocate, 8}.
    return.
  {label, 101}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.

{function, '__bp_tpl_5', 2, 80}.
  {label, 79}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_5'}, 2}.
  {label, 80}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 84}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.

{function, '__bp_tpl_6-t/3-fun-0-', 3, 108}.
  {label, 107}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_6-t/3-fun-0-'}, 3}.
  {label, 108}.
    {allocate, 8, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}, {y, 7}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {x, 2}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {y, 0}}.
    {jump, {f, 112}}.
  {label, 112}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 114}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 113}}.
  {label, 114}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 115}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 113}}.
  {label, 115}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 113}.
    {move, {y, 6}, {y, 1}}.
    {jump, {f, 117}}.
  {label, 117}.
    {move, {y, 4}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 119}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 4}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 118}}.
  {label, 119}.
    {move, {y, 5}, {x, 0}}.
    {test, is_eq_exact, {f, 120}, [{x, 0}, {atom, false}]}.
    {move, {y, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 7}}.
    {move, {y, 7}, {y, 6}}.
    {jump, {f, 118}}.
  {label, 120}.
    {move, {y, 5}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 118}.
    {move, {y, 6}, {y, 0}}.
    {jump, {f, 122}}.
  {label, 122}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 5}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 5}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 5}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 8}.

{function, '__bp_tpl_6', 3, 104}.
  {label, 103}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_6'}, 3}.
  {label, 104}.
    {allocate, 4, 3}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {x, 2}, {y, 2}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 108}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 3}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {move, {y, 3}, {x, 3}}.
    {call_fun, 3}.
    {deallocate, 4}.
    return.

{function, '__bp_tpl_7-t/2-fun-0-', 2, 128}.
  {label, 127}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_7-t/2-fun-0-'}, 2}.
  {label, 128}.
    {allocate, 7, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}, {y, 3}, {y, 4}, {y, 5}, {y, 6}]}}.
    {move, {x, 0}, {y, 2}}.
    {move, {x, 1}, {y, 3}}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, byte_size, 1}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {y, 0}}.
    {jump, {f, 132}}.
  {label, 132}.
    {move, {y, 3}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '<', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 134}, [{x, 0}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 3}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '+', 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {x, 0}}.
    {move, {integer, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, max, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 133}}.
  {label, 134}.
    {move, {y, 4}, {x, 0}}.
    {test, is_eq_exact, {f, 135}, [{x, 0}, {atom, false}]}.
    {move, {y, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, min, 2}}.
    {move, {x, 0}, {y, 6}}.
    {move, {y, 6}, {y, 5}}.
    {jump, {f, 133}}.
  {label, 135}.
    {move, {y, 4}, {x, 0}}.
    {case_end, {x, 0}}.
  {label, 133}.
    {move, {y, 5}, {y, 1}}.
    {jump, {f, 137}}.
  {label, 137}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, '-', 2}}.
    {move, {x, 0}, {y, 4}}.
    {move, {y, 2}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 4}, {x, 2}}.
    {call_ext_last, 3, {extfunc, binary, part, 3}, 7}.

{function, '__bp_tpl_7', 2, 124}.
  {label, 123}.
    {func_info, {atom, test@main}, {atom, '__bp_tpl_7'}, 2}.
  {label, 124}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 128}, 0, 0, {x, 0}, {list, []}}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 0}, {x, 0}}.
    {move, {y, 1}, {x, 1}}.
    {move, {y, 2}, {x, 2}}.
    {call_fun, 2}.
    {deallocate, 3}.
    return.
```

----- RUN LOG -----
```logs
5
2
6
true
Ok("hello")
["a", "b", "c"]
e
null
```
