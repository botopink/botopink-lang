----- SOURCE CODE -- main.bp
```botopink
type User(name: string, age: i32, next: ?User)

fn nameOf(u: ?User) -> ?string {
    return u?.name;
}

fn ageOf(u: ?User) -> ?i32 {
    return u?.age;
}

pub fn main() -> void {
    val a = User(name: "ann", age: 3, next: null);
    val b = User(name: "bob", age: 4, next: a);
    print(nameOf(a));
    print(nameOf(null));
    print(ageOf(b));
    print(b.next?.name);
    print(a.next?.name);
    print(b.next?.age ?? 0);
    print(a == b);
    print(b.next == a);
}

import {io.terminal.print} from "std";
```

----- BEAM ASSEMBLY -- main.S
```erlang
{module, test@main}.
{exports, [{'_botopink_main', 0}, {main, 1}, {main, 0}, {'__bp_priv__ageOf', 1}, {'__bp_priv__nameOf', 1}]}.
{attributes, []}.
{labels, 69}.

{function, nameOf, 1, 3}.
  {label, 2}.
    {line, [{location, "test@main.erl", 1}]}.
    {func_info, {atom, test@main}, {atom, nameOf}, 1}.
  {label, 3}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 12}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 14}}.
  {label, 12}.
    {test, is_tagged_tuple, {f, 13}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 14}}.
  {label, 13}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 14}.
    {deallocate, 1}.
    return.

{function, ageOf, 1, 5}.
  {label, 4}.
    {line, [{location, "test@main.erl", 2}]}.
    {func_info, {atom, test@main}, {atom, ageOf}, 1}.
  {label, 5}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_eq, {f, 15}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 17}}.
  {label, 15}.
    {test, is_tagged_tuple, {f, 16}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 17}}.
  {label, 16}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 17}.
    {deallocate, 1}.
    return.

{function, main, 0, 7}.
  {label, 6}.
    {line, [{location, "test@main.erl", 3}]}.
    {func_info, {atom, test@main}, {atom, main}, 0}.
  {label, 7}.
    {allocate, 3, 0}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {literal, <<"ann">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@User}, {x, 0}, {integer, 3}, {atom, undefined}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {literal, <<"bob">>}, {x, 0}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, test@main@@User}, {x, 0}, {integer, 4}, {y, 0}]}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {atom, undefined}, {x, 0}}.
    {call, 1, {f, 3}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {y, 1}, {x, 0}}.
    {call, 1, {f, 5}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 46}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 46}.
    {test, is_eq, {f, 47}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 49}}.
  {label, 47}.
    {test, is_tagged_tuple, {f, 48}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 49}}.
  {label, 48}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 49}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tagged_tuple, {f, 50}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 50}.
    {test, is_eq, {f, 51}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 53}}.
  {label, 51}.
    {test, is_tagged_tuple, {f, 52}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 1, {x, 0}}.
    {jump, {f, 53}}.
  {label, 52}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 53}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 55}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 55}.
    {test, is_eq, {f, 56}, [{x, 0}, {atom, undefined}]}.
    {move, {atom, undefined}, {x, 0}}.
    {jump, {f, 58}}.
  {label, 56}.
    {test, is_tagged_tuple, {f, 57}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 2, {x, 0}}.
    {jump, {f, 58}}.
  {label, 57}.
    {move, {atom, undefined}, {x, 0}}.
  {label, 58}.
    {test, is_ne_exact, {f, 54}, [{x, 0}, {atom, undefined}]}.
    {move, {x, 0}, {y, 2}}.
    {move, {y, 2}, {x, 0}}.
    {jump, {f, 59}}.
  {label, 54}.
    {move, {integer, 0}, {x, 0}}.
  {label, 59}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {test, is_eq_exact, {f, 60}, [{y, 0}, {y, 1}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 61}}.
  {label, 60}.
    {move, {atom, false}, {x, 0}}.
  {label, 61}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {y, 1}, {x, 0}}.
    {test, is_tagged_tuple, {f, 62}, [{x, 0}, 4, {atom, test@main@@User}]}.
    {get_tuple_element, {x, 0}, 3, {x, 0}}.
  {label, 62}.
    {test, is_eq_exact, {f, 63}, [{x, 0}, {y, 0}]}.
    {move, {atom, true}, {x, 0}}.
    {jump, {f, 64}}.
  {label, 63}.
    {move, {atom, false}, {x, 0}}.
  {label, 64}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 0}}.
    {call, 1, {f, 19}}.
    {move, {atom, ok}, {x, 0}}.
    {deallocate, 3}.
    return.

{function, '_botopink_main', 0, 9}.
  {label, 8}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '_botopink_main'}, 0}.
  {label, 9}.
    {allocate, 0, 0}.
    {move, {atom, standard_io}, {x, 0}}.
    {move, {literal, [{encoding, unicode}]}, {x, 1}}.
    {call_ext, 2, {extfunc, io, setopts, 2}}.
    {call_last, 0, {f, 7}, 0}.

{function, main, 1, 11}.
  {label, 10}.
    {line, [{location, "test@main.erl", 5}]}.
    {func_info, {atom, test@main}, {atom, main}, 1}.
  {label, 11}.
    {call_only, 0, {f, 9}}.

{function, '__bp_priv__ageOf', 1, 66}.
  {label, 65}.
    {line, [{location, "test@main.erl", 6}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__ageOf'}, 1}.
  {label, 66}.
    {call_only, 1, {f, 5}}.

{function, '__bp_priv__nameOf', 1, 68}.
  {label, 67}.
    {line, [{location, "test@main.erl", 7}]}.
    {func_info, {atom, test@main}, {atom, '__bp_priv__nameOf'}, 1}.
  {label, 68}.
    {call_only, 1, {f, 3}}.

{function, '__bp_print', 1, 19}.
  {label, 18}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_print'}, 1}.
  {label, 19}.
    {allocate, 1, 1}.
    {init_yregs, {list, [{y, 0}]}}.
    {move, {x, 0}, {y, 0}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 23}, 0, 0, {x, 0}, {list, []}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, lists, map, 2}}.
    {move, {x, 0}, {x, 1}}.
    {move, {literal, <<" ">>}, {x, 0}}.
    {call_ext, 2, {extfunc, lists, join, 2}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~ts~n">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io, format, 2}, 1}.

{function, '-bp_show_top-', 1, 23}.
  {label, 22}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_top-'}, 1}.
  {label, 23}.
    {move, {atom, true}, {x, 1}}.
    {call_only, 2, {f, 21}}.

{function, '-bp_show_elem-', 1, 25}.
  {label, 24}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_show_elem-'}, 1}.
  {label, 25}.
    {move, {atom, false}, {x, 1}}.
    {call_only, 2, {f, 21}}.

{function, '__bp_show', 2, 21}.
  {label, 20}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_show'}, 2}.
  {label, 21}.
    {allocate, 2, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {x, 1}, {y, 1}}.
    {move, {y, 0}, {x, 0}}.
    {test, is_binary, {f, 33}, [{x, 0}]}.
    {test, is_eq, {f, 32}, [{y, 1}, {atom, true}]}.
    {move, {y, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 32}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, unicode, characters_to_list, 1}}.
    {call_ext_last, 1, {extfunc, io_lib, write_string, 1}, 2}.
  {label, 33}.
    {move, {y, 0}, {x, 0}}.
    {test, is_list, {f, 34}, [{x, 0}]}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 34}.
    {move, {y, 0}, {x, 0}}.
    {test, is_tuple, {f, 36}, [{x, 0}]}.
    {call_ext, 1, {extfunc, erlang, tuple_size, 1}}.
    {test, is_lt, {f, 35}, [{integer, 0}, {x, 0}]}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_atom, {f, 35}, [{x, 0}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 35}, [{x, 0}, {atom, undefined}]}.
    {test, is_eq_exact, {f, 40}, [{x, 0}, {atom, ok}]}.
    {move, {literal, <<"Ok(">>}, {y, 1}}.
    {jump, {f, 41}}.
  {label, 40}.
    {test, is_eq_exact, {f, 37}, [{x, 0}, {atom, error}]}.
    {move, {literal, <<"Error(">>}, {y, 1}}.
  {label, 41}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 21}}.
    {test_heap, 6, 1}.
    {put_list, {integer, 41}, nil, {x, 1}}.
    {put_list, {x, 0}, {x, 1}, {x, 0}}.
    {put_list, {y, 1}, {x, 0}, {x, 0}}.
    {deallocate, 2}.
    return.
  {label, 35}.
    {move, {y, 0}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, tuple_to_list, 1}}.
    {move, {x, 0}, {y, 1}}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 25}, 0, 0, {x, 0}, {list, []}}.
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
  {label, 36}.
    {move, {y, 0}, {x, 0}}.
    {test, is_atom, {f, 38}, [{x, 0}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, true}]}.
    {test, is_ne_exact, {f, 38}, [{x, 0}, {atom, false}]}.
    {test, is_ne_exact, {f, 39}, [{x, 0}, {atom, undefined}]}.
  {label, 37}.
    {move, {y, 0}, {x, 1}}.
    {call_last, 2, {f, 27}, 2}.
  {label, 38}.
    {move, {y, 0}, {x, 0}}.
    {test_heap, 2, 1}.
    {put_list, {x, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 2}.
  {label, 39}.
    {move, {literal, <<"null">>}, {x, 0}}.
    {deallocate, 2}.
    return.

{function, '__bp_tagged', 2, 27}.
  {label, 26}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_tagged'}, 2}.
  {label, 27}.
    {allocate, 3, 2}.
    {init_yregs, {list, [{y, 0}, {y, 1}, {y, 2}]}}.
    {move, {x, 1}, {y, 0}}.
    {move, {x, 0}, {y, 1}}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, atom_to_list, 1}}.
    {move, {literal, <<"__v__">>}, {x, 1}}.
    {call_ext, 2, {extfunc, string, split, 2}}.
    {test, is_nonempty_list, {f, 42}, [{x, 0}]}.
    {get_list, {x, 0}, {x, 1}, {x, 2}}.
    {move, {x, 1}, {y, 2}}.
    {test, is_nonempty_list, {f, 42}, [{x, 2}]}.
    {move, {y, 2}, {x, 0}}.
    {call_ext, 1, {extfunc, erlang, list_to_atom, 1}}.
    {move, {x, 0}, {y, 1}}.
  {label, 42}.
    {move, {y, 1}, {x, 0}}.
    {call_ext, 1, {extfunc, code, ensure_loaded, 1}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {move, {integer, 1}, {x, 2}}.
    {call_ext, 3, {extfunc, erlang, function_exported, 3}}.
    {test, is_eq_exact, {f, 43}, [{x, 0}, {atom, true}]}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 2}}.
    {move, {y, 1}, {x, 0}}.
    {move, {atom, '__bp_format'}, {x, 1}}.
    {call_ext, 3, {extfunc, erlang, apply, 3}}.
    {call_last, 1, {f, 29}, 3}.
  {label, 43}.
    {test_heap, 2, 1}.
    {put_list, {y, 0}, nil, {x, 1}}.
    {move, {literal, <<"~p">>}, {x, 0}}.
    {call_ext_last, 2, {extfunc, io_lib, format, 2}, 3}.

{function, '__bp_render', 1, 29}.
  {label, 28}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '__bp_render'}, 1}.
  {label, 29}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 1}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test, is_eq_exact, {f, 44}, [{x, 0}, {atom, text}]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 44}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {x, 0}, {y, 1}}.
    {test, is_eq_exact, {f, 45}, [{x, 0}, nil]}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext_last, 2, {extfunc, erlang, element, 2}, 2}.
  {label, 45}.
    {test_heap, {alloc, [{words, 0}, {floats, 0}, {funs, 1}]}, 0}.
    {make_fun3, {f, 31}, 0, 0, {x, 0}, {list, []}}.
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

{function, '-bp_render_pair-', 1, 31}.
  {label, 30}.
    {line, [{location, "test@main.erl", 4}]}.
    {func_info, {atom, test@main}, {atom, '-bp_render_pair-'}, 1}.
  {label, 31}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {move, {atom, false}, {x, 1}}.
    {call, 2, {f, 21}}.
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

----- BEAM ASSEMBLY -- test@main@@User.S
```erlang
{module, test@main@@User}.
{exports, [{'__bp_get', 2}, {'__bp_format', 1}]}.
{attributes, []}.
{labels, 9}.

{function, '__bp_get', 2, 3}.
  {label, 2}.
    {line, [{location, "test@main@@User.erl", 1}]}.
    {func_info, {atom, test@main@@User}, {atom, '__bp_get'}, 2}.
  {label, 3}.
    {test, is_eq_exact, {f, 4}, [{x, 1}, {atom, name}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 4}.
    {test, is_eq_exact, {f, 5}, [{x, 1}, {atom, age}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 5}.
    {test, is_eq_exact, {f, 6}, [{x, 1}, {atom, next}]}.
    {move, {x, 0}, {x, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {call_ext_only, 2, {extfunc, erlang, element, 2}}.
  {label, 6}.
    {move, {atom, undefined}, {x, 0}}.
    return.

{function, '__bp_format', 1, 8}.
  {label, 7}.
    {line, [{location, "test@main@@User.erl", 1}]}.
    {func_info, {atom, test@main@@User}, {atom, '__bp_format'}, 1}.
  {label, 8}.
    {allocate, 2, 1}.
    {init_yregs, {list, [{y, 0}, {y, 1}]}}.
    {move, {x, 0}, {y, 0}}.
    {move, nil, {y, 1}}.
    {move, {integer, 4}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"next">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 3}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"age">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {move, {integer, 2}, {x, 0}}.
    {move, {y, 0}, {x, 1}}.
    {call_ext, 2, {extfunc, erlang, element, 2}}.
    {test_heap, 5, 1}.
    {put_tuple2, {x, 0}, {list, [{literal, <<"name">>}, {x, 0}]}}.
    {put_list, {x, 0}, {y, 1}, {y, 1}}.
    {test_heap, 4, 1}.
    {put_tuple2, {x, 0}, {list, [{atom, record}, {literal, <<"User">>}, {y, 1}]}}.
    {deallocate, 2}.
    return.
```

----- RUN LOG -----
```logs
ann
null
4
ann
null
3
false
true
```
